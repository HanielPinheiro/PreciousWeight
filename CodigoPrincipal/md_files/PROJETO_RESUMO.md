# PreciousWeight (ESP32) — Arquitetura Atual do Firmware

Single source of truth da arquitetura do firmware, **fiel ao código em HEAD** (revisado e corrigido contra o source, sem comportamento presumido). Descreve: inicialização por fases, pipeline de medição de alta precisão (4 células de carga HX711), provisioning Wi-Fi por BLE, comunicção MQTT/TLS, persistência local + outbox offline, e bloqueio de segurança.

> **Nota de fidelidade:** este documento corrige versões anteriores que afirmavam que a pesagem agendada funcionava **antes** do WiFi. No código real, o scheduler de horários só é armado **após** WiFi + SNTP estarem OK, dentro da `wifi_manager_task`. O que opera de fato antes do WiFi (desde a Fase 2) é a **aquisição/agregação contínua de sensores** e a **tara automática de boot**.

---

## 1. Propósito

Firmware para balança pediátrica de UTI neonatal, meta de precisão **< 5 g de erro máximo** num sistema de 4 células de carga:

- 4 células de carga + 4 amplificadores HX711 (Canal A, ganho 128, 24 bits).
- Leitura contínua e peso global agregado (soma das 4 células).
- Provisionamento Wi-Fi por BLE (esp-wifi-prov).
- MQTT/TLS mútuo para comandos, estados e pesagens.
- Cartão SD como auditoria local + fallback offline (outbox).

**Premissa central de segurança:** nenhuma pesagem pode ser "anônima" (perdida sem rastro). Se ambos os meios de persistência (SD + MQTT online) estiverem indisponíveis por tempo crítico, a balança se bloqueia em modo CRITICAL para não gerar risco de perda de dado com implicação clínica/jurídica.

---

## 2. Sequência de Boot (`app_main`)

Em [main.c](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/Esp32_Codigo/CodigoPrincipal/main/main.c#L103-L174), a inicialização é por fases com política de trava/degradê própria:

| Fase | Nome | Trava em falha? | Ação (real, verificado no source) |
|------|------|-----------------|-----------------------------------|
| 0 | Infra | **SIM** | LED task; NVS flash (com `nvs_flash_erase` em caso de versão/páginas cheias); `pw_save_reset_reason_nvs`. |
| 1 | SD Card | **NÃO** (degrada) | `initialize_sdcard()` (3 tentativas, SPI 4 MHz). OK → `g_sys.sd_ok=true`; FAIL → `g_sys.sd_ok=false`, segue sem persistência local. Depois `sdcard_persistence_init()` (carrega sequence_id do SD; se SD down, sequence em RAM a partir de 0). Loga BOOT em audit.log e salva `state.txt`. |
| 2 | **Aquisição de sensores** | **SIM** | `hx711_initialize_sensors()` (configura GPIO, tara de cada célula com 40 amostras, espera 2 s de estabilização térmica); `init_sdcard_task()` (só se SD OK); `init_sensors_task()` (4 leitores + 1 processador). **NÃO cria timer de agendamento aqui.** |
| 3 | WiFi / SNTP / MQTT | **NÃO** (assíncrono) | `start_wifi_manager_async()` cria `wifi_manager_task` (8 KB). **Dentro dela**, após obter IP e sincronizar SNTP, chama `init_weight_sensors_timer()` (scheduler) e `init_mqtt_task()`. |
| 4 | Sanity check | — | Timer one-shot 120 s após boot. |

**Só quando `AT_CALIBRATION = 0`** (padrão) a Fase 3 roda e o `sensor_processor_task` é criado. Em modo calibração (`AT_CALIBRATION = 1`), WiFi/MQTT/scheduler e o processador de agregação ficam desativados (apenas leitores brutos + logging em `[AT_CALIBRATION]`).

> **Implicação real (importante para a dissertação):** o **agendamento horário e a pesagem manual dependem do WiFi/MQTT estarem operacionais**. A etapa que roda independentemente de rede desde o boot é a **leitura/agregação contínua** de sensores. Não existe cenário em que uma pesagem agendada dispare "às 08:00" sem WiFi — o scheduler consome `time()` do SNTP e só é armado após conexão.

---

## 3. Estado Global `g_sys` (source truth em sdcard_persistence.c)

Em [config.h](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/Esp32_Codigo/CodigoPrincipal/config/config.h#L77-L87):

```c
typedef struct {
    bool sd_ok;                // SD montou? (fase 1)
    bool wifi_provisioned;     // Credenciais WiFi existem em NVS?
    bool wifi_connecting;      // STA tentando conectar agora
    bool wifi_up;              // STA tem IP?
    bool mqtt_up;              // MQTT conectou no broker?
    bool datetime_synced;      // SNTP sincronizou (senão, usa tempo desde boot)
    uint8_t wifi_fail_count;   // (reservado)
    TickType_t boot_tick;      // xTaskGetTickCount em app_main() → pw_safe_epoch
} system_state_t;
```

Toda decisão de degradação (SD down, WiFi pending, etc) consulta esta struct.

---

## 4. Módulos e Responsabilidades

| Módulo | Responsabilidade |
|--------|------------------|
| [main/main.c](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/Esp32_Codigo/CodigoPrincipal/main/main.c) | Orquestrador de boot por fases + sanity check 120 s. Declara `hx711_t sensors[4]` (offsets e calib_factors das 4 células). |
| [comm/wifi_prov_ble/wifi_prov_ble.c](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/Esp32_Codigo/CodigoPrincipal/comm/wifi_prov_ble/wifi_prov_ble.c) | `wifi_manager_task` assíncrona (8 KB). Provisionado → STA 3×15 s; sem IP → BLE provisioning (polling 500 ms). Após IP → SNTP → `init_weight_sensors_timer()` + `init_mqtt_task()`. `reset_wifi()` para MQTT→reseta WiFi→`esp_restart()`. `reset_wifi()` também é acionado após 15 desconexões `WIFI_EVENT_STA_DISCONNECTED`. |
| [comm/mqtt_config/mqtt3.c](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/Esp32_Codigo/CodigoPrincipal/comm/mqtt_config/mqtt3.c) | Lifecycle MQTT/TLS mútuo (CA + cert do cliente + chave embutidos). `mqtt_publish()` com mutex e warn-se-desconectado. Seta `g_sys.mqtt_up` em CONNECTED/DISCONNECTED/ERROR. Inscrição em `/scales/<service>` QoS 1. LWT `DISCONNECTED` (retain, QoS 1) em `/status/`. |
| [mqtt_events/parser/process_mqtt_data.c](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/Esp32_Codigo/CodigoPrincipal/mqtt_events/parser/process_mqtt_data.c) | Parsing de comandos `[BAB] [TIM] [RUN] [CLE] [MEA] [WFS] [TAR] [WIF]` via tabela `CommandHandler`. Pesagem manual [MEA] gera seq → `pw_log_measurement("manual")` → publica `[MEA]{xx.xx}` em `/weights/` → se falhar `pw_outbox_add`. `tare_routine` [TAR] implementado (não é mais stub). |
| [mqtt_events/scheduler/weight_timer_scheduler.c](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/Esp32_Codigo/CodigoPrincipal/mqtt_events/scheduler/weight_timer_scheduler.c) | Computa próximo horário mais próximo (adiantando ao dia seguinte se necessário), arma timer one-shot FreeRTOS, notifica `task_worker` dedicada. Fluxo: seq → `pw_log_measurement("scheduled")` → publica `[WEI]{xx.xx}` QoS 2 → falha → outbox. |
| [tasks/sensors_task/sensors_task.c](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/Esp32_Codigo/CodigoPrincipal/tasks/sensors_task/sensors_task.c) | 4 tasks leitoras (10 Hz) + 1 task processadora (1 Hz) que soma as células e aplica deadband (soma ≤ 10 g → 0). Protege o peso global com mutex. |
| [drivers/hx711/hx711.c](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/Esp32_Codigo/CodigoPrincipal/drivers/hx711/hx711.c) | Driver HX711: leitura raw bit-bang (24 bits, ganho 128), timeout, seção crítica; mediana aparada (7 amostras, descarta 2 extremos de cada lado, média das 3 centrais); média (tara = 40 amostras). Cálculo `peso = (raw − offset)/calib_factor`. Mutex por célula. |
| [drivers/sdcard/sdcard.c](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/Esp32_Codigo/CodigoPrincipal/drivers/sdcard/sdcard.c) | HAL baixo-nível: SPI mount (4 MHz, cluster 16 KB, max_files=3), árvore `/sdcard/scales/`, escritas com mutex. |
| [drivers/sdcard_persistence/sdcard_persistence.c](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/Esp32_Codigo/CodigoPrincipal/drivers/sdcard_persistence/sdcard_persistence.c) | Camada de aplicação. Define `g_sys`. `pw_safe_epoch()` (SNTP OU tempo desde boot). Rotação de arquivos. **Buffer RAM circular estático (10 slots) como fallback de outbox quando SD down.** |
| [tasks/mqtt_task/mqtt_task.c](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/Esp32_Codigo/CodigoPrincipal/tasks/mqtt_task/mqtt_task.c) | Manager MQTT (reinício em erro), command worker (fila 10), **outbox_worker 1 Hz** que resolve SD ou RAM buffer. |
| [tasks/sdcard_task/sdcard_task.c](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/Esp32_Codigo/CodigoPrincipal/tasks/sdcard_task/sdcard_task.c) | Writer assíncrono de `logs.txt` via fila; após 5 falhas recorrentes gera evento crítico `SD_FULL`/`SD_FAIL` (atualmente só loga em audit/critical, `MQTT_TOPIC_EVENTS` está comentado). |

---

## 5. Mapa de Tasks FreeRTOS (dados reais do source)

| Task | Stack (B) | Prioridade | Periodicidade | Observação |
|------|-----------|------------|---------------|------------|
| `led_task` | 2048 | 5 | — | Padrões de LED via fila |
| `sensor_reader` (×4) | 4096 | HIGH (3) | 10 Hz (`vTaskDelayUntil` 100 ms) | Leitura individual de célula |
| `sensor_proc` | 4096 | MEDIUM (2) | 1 Hz | Agregação (soma) + deadband |
| `WeightMeasure` (task_worker) | 4096 | 2 | a cada horário agendado | Pesagem agendada (notificação) |
| `wifi_manager` | 8192 | MEDIUM (2) | — | Provisiona; nunca bloqueia `app_main` |
| `mqtt_manager` | 4096 | 5 | — | Reinicia cliente MQTT sob erro |
| `mqtt_cmd_worker` | 4096 | MEDIUM (2) | — | Consome fila de comandos |
| `mqtt_outbox_worker` | 4096 | MEDIUM (2) | 1 Hz | Reenvia 1 pendente por tick |
| `gravar_logs_sd` (sdcard_writer) | 4096 | MEDIUM (2) | — | Writer de `logs.txt` |

---

## 6. Contrato MQTT

### Tópicos (em [mqtt3.h](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/Esp32_Codigo/CodigoPrincipal/comm/mqtt_config/mqtt3.h))

| Tópico | Direção | Conteúdo |
|--------|---------|----------|
| `/scales/<service>` | **Inbound** | Comandos textuais (QoS 1) |
| `/weights/<service>` | **Outbound** | Pesagens: payload legacy `[MEA]{xx.xx}` (manual, QoS 1) / `[WEI]{xx.xx}` (agendada, QoS 2) |
| `/wifi/<service>` | **Outbound** | RSSI: `[WFS]{rssi}` |
| `/status/<service>` | **Outbound** | LWT `DISCONNECTED` (retain, QoS 1); `CONNECTED`; alerta CRITICAL de SD_FAIL |

`MQTT_TOPIC_EVENTS` (`/events/<service>`) está **comentado** no header — eventos estruturados (`EVT|...`) são gravados apenas em SD (audit.log/critical.log), não publicados.

### Comandos inbound

| Comando | Exemplo | Efeito real |
|---------|---------|-------------|
| `[BAB]` | `[BAB]BEBE001` | Define baby_id ativo, limpa rotina anterior, persiste |
| `[TIM]` | `[TIM]08:00` | Adiciona horário (até `MAX_WEIGHT_TIMES`=10) |
| `[RUN]` | `[RUN]` | Persiste rotina em baby.txt e arma scheduler (se WiFi/SNTP ok) |
| `[CLE]` | `[CLE]` | Limpa baby e horários; para timer |
| `[MEA]` | `[MEA]` | **Medição manual**: seq → `pw_log_measurement("manual")` → publish em `/weights/` (fallback outbox) |
| `[WFS]` | `[WFS]` | Publica RSSI em `/wifi/` |
| `[TAR]` | `[TAR]` | **Implementado**: para medição, tara as 4 células (`hx711_tare_safe`), retoma medição |
| `[WIF]` | `[WIF]` | Para MQTT → `reset_wifi()` → `esp_restart()` |

> **Correção aplicada:** versões anteriores marcavam `[TAR]` como "não implementado". No HEAD, `tare_routine` está completo e registrado.

---

## 7. Fluxo de Pesagem e Persistência

### Formato estruturado em weights.txt (`MEA|...`)

```
MEA|<seq>|<epoch_safe>|<origem: manual|scheduled>|<peso_2casas>
MEA|12|1722518400|manual|3245.12
```

Em [sdcard_persistence.c](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/Esp32_Codigo/CodigoPrincipal/drivers/sdcard_persistence/sdcard_persistence.c#L196-L206).

### Pesagem manual ([MEA])

```
[MEA] em /scales/<service> → measure_routine()
  ├─ global_weight = get_global_weight()          // peso agregado atual
  ├─ seq = pw_next_sequence_id()
  ├─ pw_log_measurement(seq,"manual",w) → weights.txt (se SD up)
  ├─ "legacy = [MEA]{%.2f}"
  └─ mqtt_publish(/weights/, legacy, qos=1)
       └─ falhou → pw_outbox_add()
            ├─ SD up   → "P|seq|qos|topic|payload" em outbox.log
            └─ SD down → RAM buffer circular (10 slots)
```

### Pesagem agendada — `task_worker` (scheduler)

```
timer one-shot dispara → xTaskNotifyGive(task_worker)
task_worker:
  ├─ w = get_global_weight()
  ├─ seq = pw_next_sequence_id()
  ├─ pw_log_measurement(seq,"scheduled",w) → weights.txt
  ├─ "legacy = [WEI]{%.2f}"
  └─ mqtt_publish(/weights/, legacy, qos=2)
       └─ falhou → pw_outbox_add(...)
  ├─ se scale_has_baby() && number_of_weight_times>0 → schedule_next_measure()
```

### Reenvio offline (`mqtt_outbox_worker`)

- Roda 1 Hz; chama `pw_outbox_load_pending(1 entry)`.
- SD up: lê 1 pendente do outbox.log, publica, sucesso → grava `S|seq`.
- SD down: dequeue de 1 slot do RAM buffer, publica, sucesso → remove da fila.
- Parsing rígido por `sscanf` (`P|%lu|%d|%63[^|]|%255[^\n]`); linhas malformadas são ignoradas sem crash.

---

## 8. Persistência no SD Card (`/sdcard/scales/`)

| Arquivo | Rotação | Conteúdo |
|---------|----------|----------|
| `logs.txt` | — | Log genérico (sdcard_log) |
| `weights.txt` | 128 KB × 3 | Pesagens `MEA\|seq\|epoch\|origem\|peso` |
| `baby.txt` | — | baby_id + `weight_time` agendados |
| `state.txt` | — | Snapshot (boot_epoch, reset_reason, baby_id, horários) |
| `sequence.txt` | ~24 B | Último sequence_id (uint32 monotônico) |
| `audit.log` | 128 KB × 3 | Eventos `EVT\|...` |
| `commands.log` | 64 KB × 3 | Comandos `CMD\|...` |
| `critical.log` | 64 KB × 3 | Apenas eventos CRITICAL |
| `outbox.log` | 256 KB × 2 | Pendentes `P\|...` + enviados `S\|seq` |

**NVS:** namespace `boot_meta/last_reset` (razão do último reset) e `storage/timestamp` (último NTP recebido). Credenciais WiFi: storage nativo do esp_wifi.

**Buffer RAM (fallback SD down):** 10 slots estáticos (BSS), fila circular head/tail/count. Finito e **volátil** — em power-cut com SD down e fila cheia, pesos pendentes são perdidos (pior caso mitigado pelo sanity 120 s).

---

## 9. Bloqueio de Segurança (Sanity check 120 s)

Em [main.c#L57-L88](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/Esp32_Codigo/CodigoPrincipal/main/main.c#L57-L88):

```
Sanity lê g_sys.sd_ok e g_sys.mqtt_up a 120 s após boot:
  ├─ SD=FAIL & MQTT=FAIL → pw_safety_critical_loop("SD + MQTT INDISPONIVEIS...")
  │                        → LED CRITICAL + loop infinito (vTaskDelay 2 s)
  │                        → não pesa (evita pesagem sem rastro)
  ├─ SD=FAIL & MQTT=OK   → publica em /status/:
  │                        "EVT|seq|epoch|CRITICAL|SD_FAIL|OPERATING_ONLINE_ONLY_NO_OFFLINE_FALLBACK"
  │                        → segue pesando, sem fallback offline
  └─ demais              → silencioso
```

**Saída do bloqueio:** somente por reset (power-cycle ou `[WIF]`). Não há auto-recuperação.

---

## 10. Matriz de Comportamento por Cenário (UTI)

| # | SD | WiFi/MQTT | Pesagem manual/agendada? | Persistência | Reenvio ao voltar WiFi |
|---|----|-----------|--------------------------|--------------|------------------------|
| 1 | OK | OK | Sim | weights.txt + MQTT | — |
| 2 | OK | down | Sim (porém **agendada só se já estava armada**; sem WiFi no boot, scheduler não arma) | weights.txt + outbox.log PENDENTE | Outbox 1 Hz → `S\|seq` |
| 3 | FAIL | OK | Sim | MQTT na hora (sem fallback offline) | — |
| 4 | FAIL | down (< 120 s) | Manual não (precisa MQTT); agendada não arma sem WiFi | RAM buffer 10 slots | Quando MQTT sobe → outbox dequeue RAM |
| 5 | FAIL | FAIL (≥ 120 s) | Bloqueada (safety critical) | Nenhuma | — |
| Runtime: SD cai | — | — | Sim (se já online) | RAM buffer 10 slots | Sim |
| Runtime: WiFi cai | OK | — | Sim (se scheduler já armado; manual via MQTT não) | outbox.log PENDENTE | Sim |

---

## 11. Observabilidade

1. **UART:** `ESP_LOGx` com tags.
2. **SD `/logs.txt`:** `sdcard_log()` de operação.
3. **SD estruturado:** audit.log, commands.log, weights.txt, outbox.log → sync via MQTT ou leitura física do cartão.

---

## 12. Salvaguardas (validadas no source)

- ✅ `mqtt_publish()` com mutex (sem race multi-task).
- ✅ Todas as escritas SD com mutex.
- ✅ Pesagem agendada em task dedicada (HX711 SPI bloqueante não estoura deadline do timer).
- ✅ `pw_safe_epoch()` nunca é 0 (SNTP ou tempo desde boot).
- ✅ Outbox lê 1 pendente por vez (evita WDT/stack overflow).
- ✅ RAM buffer é BSS estático (sem malloc, sem array em stack).
- ✅ `sdcard_persistence` não crasha se SD down (`if (!g_sys.sd_ok) return ESP_OK;`).
- ✅ `wifi_manager_task` não bloqueia `app_main`.
- ✅ `sscanf` rígido no parsing do outbox.log.
- ✅ Sanity 120 s bloqueia operação sem nenhum meio de auditoria.

---

## 13. Limitações Conhecidas (fiel ao código)

1. **Pesagem agendada e manual dependem de WiFi/MQTT.** O scheduler é armado apenas após WiFi+SNTP; logo não há pesagem agendada em boot "offline".
2. **`/weights/<service>`** usa payload legacy `[MEA]{...}`/`[WEI]{...}` (compatibilidade de API); o dado estruturado `MEA|...` fica só em SD/outbox.
3. **`MQTT_TOPIC_EVENTS` comentado** — eventos estruturados não são publicados, só gravados em SD.
4. **RAM buffer (10 slots) é volátil.** Power-cut com SD fail + fila cheia perde pendentes.
5. **Rotação FAT** renomeia em runtime; SD removido no meio pode deixar `.1`/`.2` sem base (recupera no próximo boot).
6. **Tara automática de boot está comentada** (`// tare_routine(TARE_AUTOMATICALLY);`), mas `hx711_initialize_sensors()` já executa tara por célula na inicialização.
7. **`SD_FAIL`/`SD_FULL`** (sdcard_task, após 5 falhas) atualmente gera evento em audit/critical.log; publicação MQTT está comentada.

---

## 14. Testes Relacionados

- [TESTES_CRITICOS.md](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/Esp32_Codigo/CodigoPrincipal/md_files/TESTES_CRITICOS.md): checklist de injeção de falhas (WiFi drop, SD ausente/runtime/full, power-cut, saturação de comandos, horários) alinhado à arquitetura real.
- [FIRMWARE_ALGORITMOS_PRECISAO.md](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/Esp32_Codigo/CodigoPrincipal/md_files/FIRMWARE_ALGORITMOS_PRECISAO.md): pipeline de precisão (HX711, filtragem, tara, calibração, agregação).
- [DISSERTACAO_CONTEXTO.md](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/Esp32_Codigo/CodigoPrincipal/md_files/DISSERTACAO_CONTEXTO.md): narrativa acadêmica (objetivos, metodologia, contribuições, validação) para geração de texto via NotebookLM.