# PreciousWeight (ESP32) — Current Architecture

Single source of truth da arquitetura atual do firmware. Reflete a implementação em HEAD: inicialização por fases independentes, degradação graciosa por falhas, outbox persistido em SD + RAM fallback, canais de pesagem (manual/agendada) sempre ativos, e bloqueio de segurança quando nenhum meio de persistência estiver disponível.

## 1. Propósito

Firmware para balança pediátrica de UTI neonatal:
- 4 células de carga HX711
- Leitura contínua + peso global agregado
- Provisionamento Wi-Fi por BLE
- MQTT para comandos, estados e pesagens
- Cartão SD como auditoria local + fallback offline

**Premissa central de segurança:** nenhuma pesagem pode ser "anônima" (perdida sem rastro). Se ambos os meios de persistência (SD + MQTT online) estiverem indisponíveis por tempo crítico, a balança se bloqueia em modo CRITICAL para não gerar risco jurídico.

## 2. Módulos Principais

| Módulo | Responsabilidade |
|---|---|
| [main/main.c](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/Esp32_Codigo/CodigoPrincipal/main/main.c) | **Orquestrador de boot por fases + bloqueio de segurança (120s).** Fase 0 (travas): LED, NVS, reset reason. Fase 1 (degradável): SD card (SD down → continua). Fase 2 (travas): HX711, tasks de sensors/sdcard, timers AGENDADOS (antes do WiFi). Fase 3 (assíncrona): WiFi manager (não bloqueia app_main). Fase 4: sanity check 120s. |
| [comm/wifi_prov_ble/wifi_prov_ble.c](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/Esp32_Codigo/CodigoPrincipal/comm/wifi_prov_ble/wifi_prov_ble.c) | **`wifi_manager_task` assíncrona 8KB.** Caminho: inicializa netif/event loop → se provisionado → STA 3x15s → timeout cai em BLE provisionamento (polling 500ms, não trava) → SNTP → `init_mqtt_task()`. Flags em `g_sys.wifi_up / g_sys.datetime_synced`. Wrapper `init_wifi()` agora delega para `start_wifi_manager_async()`. |
| [comm/mqtt_config/mqtt3.c](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/Esp32_Codigo/CodigoPrincipal/comm/mqtt_config/mqtt3.c) | Lifecycle MQTT TLS mútuo, mutex de publicação, `mqtt_publish()` com warn-quando-desconectado. Setta `g_sys.mqtt_up` nos eventos `MQTT_EVENT_CONNECTED / DISCONNECTED / ERROR`. |
| [tasks/mqtt_task/mqtt_task.c](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/Esp32_Codigo/CodigoPrincipal/tasks/mqtt_task/mqtt_task.c) | Manager MQTT + command worker + **outbox_worker 1Hz** que roda `pw_outbox_load_pending` (agora funciona de SD ou RAM buffer). |
| [mqtt_events/parser/process_mqtt_data.c](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/Esp32_Codigo/CodigoPrincipal/mqtt_events/parser/process_mqtt_data.c) | Parsing de comandos [BAB]/[TIM]/[RUN]/[CLE]/[MEA]/[WFS]/[TAR]/[WIF]. Helper **`mqtt_send_or_spool`** unificado (publish → se falhar → `pw_outbox_add`). Pesagem manual: gera seq → `pw_log_measurement` → `send_or_spool` no tópico `/weights/<service>` com payload `"RECEIVED_MEASURE{xx.xx}"`. |
| [mqtt_events/scheduler/weight_timer_scheduler.c](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/Esp32_Codigo/CodigoPrincipal/mqtt_events/scheduler/weight_timer_scheduler.c) | Computa próximo horário, arma one-shot timer, notifica `task_worker` dedicada (leitura HX711 é pesada). Fluxo: gera seq → **`pw_log_measurement(seq, "scheduled", w)` em weights.txt** → tenta publicar, falhou → `pw_outbox_add(seq, ...)`. |
| [tasks/sensors_task/sensors_task.c](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/Esp32_Codigo/CodigoPrincipal/tasks/sensors_task/sensors_task.c) | Amostragem e agregação → `get_global_weight()`. |
| [drivers/sdcard/sdcard.c](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/Esp32_Codigo/CodigoPrincipal/drivers/sdcard/sdcard.c) | HAL baixo-nível: SPI mount, criação de árvore /sdcard/scales, escrita protegida com mutex (sdcard_write_file / sdcard_overwrite_file). |
| [drivers/sdcard_persistence/sdcard_persistence.c](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/Esp32_Codigo/CodigoPrincipal/drivers/sdcard_persistence/sdcard_persistence.c) | Camada de aplicação. **Definição de `system_state_t g_sys` global.** `pw_safe_epoch()` (SNTP sincronizado OU fallback tempo desde boot com `g_sys.boot_tick`). Checagens `g_sys.sd_ok` em TODO write (NÃO crasha se SD down). **Buffer RAM circular 10 slots estático (FIFO)** como fallback de `pw_outbox_add` quando SD=fail. Rotação automática de arquivos estruturados. |
| [config/config.h](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/Esp32_Codigo/CodigoPrincipal/config/config.h#L71-L99) | `PW_RAM_BUFFER_SLOTS=10`. `typedef system_state_t` + `extern g_sys`. Protótipos do buffer RAM. |

## 3. Estado Global `g_sys` (source truth em sdcard_persistence.c)

```c
typedef struct {
    bool sd_ok;                   // SD montou? (fase1)
    bool wifi_provisioned;        // Credenciais WiFi existem em NVS?
    bool wifi_connecting;         // STA tentando conectar agora
    bool wifi_up;                 // STA tem IP?
    bool mqtt_up;                 // MQTT conectou no broker?
    bool datetime_synced;         // SNTP sincronizou (senão, usa tempo desde boot)
    uint8_t wifi_fail_count;      // (reservado)
    TickType_t boot_tick;         // xTaskGetTickCount em app_main() → pw_safe_epoch
} system_state_t;
```

Toda decisão de degradação (SD down, WiFi pending, etc) consulta esta struct.

## 4. Fluxo de Inicialização (app_main) — ORDEM CRÍTICA

Em [main.c](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/Esp32_Codigo/CodigoPrincipal/main/main.c#L103-L174):

| Fase | Nome | Trava em falha? | Ação |
|---|---|---|---|
| 0 | Infra | **SIM** | LED task. NVS flash. Salva reset_reason em NVS via `pw_save_reset_reason_nvs`. |
| 1 | SD Card | **NÃO** (degrada) | Tenta `initialize_sdcard()`. OK → `g_sys.sd_ok=true`. FAIL → `g_sys.sd_ok=false`, loga e **CONTINUA**. Depois `sdcard_persistence_init()` (se SD down, usa sequence_id em RAM começando em 0). Loga evento BOOT, salva state.txt. |
| 2 | **PESAGEM (antes do WiFi)** | **SIM** | 1) `hx711_initialize_sensors` → 2) `init_sdcard_task` (SOMENTE se SD OK) → 3) `init_sensors_task` → 4) `init_weight_sensors_timer`. **Balança já funciona neste ponto.** |
| 3 | WiFi/SNTP/MQTT | **NÃO** (assíncrono) | `start_wifi_manager_async()`. Cria task `wifi_manager` 8KB, stack dedicada, não bloqueia. Esta task segue: provisionamento STA/BLE → IP → SNTP → init MQTT task (que inicia o outbox_worker 1Hz). |
| 4 | Sanity Check 120s | — | Timer one-shot (FreeRTOS software timer). |

**Resultado da Fase 2 antes da Fase 3:** Mesmo que o usuário demore 5 minutos no provisionamento BLE via celular do enfermeiro, se houver um horário agendado às 08:00 e o boot foi às 07:59, **a pesagem dispara no horário certo, grava no SD/outbox.log e é enviada depois quando WiFi conectar**.

## 5. Modelo de Conectividade

### WiFi — agora assíncrono

- Se já provisionado → `wifi_manager_task` tenta **STA 3 vezes com timeout 15s cada** (total ~45s).
- Se falhar → cai em **BLE provisionamento com polling 500ms** (loop `xEventGroupWaitBits` com yield; não trava nem dispara Task WDT).
- Se dispositivo novo → direto para provisionamento BLE.
- Evento `IP_EVENT_STA_GOT_IP`: `g_sys.wifi_up=true` e event group BIT0 setado.
- Depois que conectar: `start_date_time_routine()` → se OK `g_sys.datetime_synced=true`, se FAIL usa `boot_tick` em `pw_safe_epoch`.
- Depois chama `init_mqtt_task()`.

### BLE Provisioning

Mesmo modelo (esp-idf wifi_prov manager), POP em `MQTT_POP`, nome `WIFI_DEVICE_NAME`, service UUID custom.

### MQTT

- Broker TLS: certs cliente/client_key/CA embutidos no binário via cmakefile.
- Inscrição em **1 tópico só**: `/scales/<service>` (comandos).
- Publicações: `/status/<service>`, `/events/<service>`, `/weights/<service>`, `/conn/status/<service>`.

## 6. Contrato MQTT

### Incoming
- `/scales/<service>`: comandos textuais.

### Outgoing
- `/status/<service>`: LWT e connection state.
- `/events/<service>`: eventos estruturados (ainda não 100% usados em fluxo; ver `pw_log_event`).
- `/weights/<service>`: **único canal de pesagem ativo hoje.** Payload `"RECEIVED_MEASURE{xx.xx}"` (tanto manual quanto agendado).
- `/conn/status/<service>`: mensagem de alerta no sanity_check quando SD=fail mas MQTT=ok (payload crítico).
- `/measurements/<service>` e `/acks/<service>`: **canais desativados (código comentado/removido).** Não usados.

## 7. Comandos Suportados

| Comando | Exemplo | Efeito |
|---|---|---|
| `[BAB]` | `[BAB]BEBE001` | Define baby_id ativo, limpa rotina anterior |
| `[TIM]` | `[TIM]08:00` | Adiciona um horário (até `MAX_WEIGHT_TIMES`) |
| `[RUN]` | `[RUN]` | Persiste rotina em baby.txt e arma scheduler |
| `[CLE]` | `[CLE]` | Limpa baby e horários |
| `[MEA]` | `[MEA]` | **Medição manual.** seq → `pw_log_measurement("manual")` → send_or_spool em `/weights/` |
| `[WFS]` | `[WFS]` | Publica RSSI atual |
| `[TAR]` | `[TAR]` | **Não implementado ainda** |
| `[WIF]` | `[WIF]` | Stop MQTT → reset WiFi → `esp_restart()` |

## 8. Fluxo de Pesagem

### 8.1 Estrutura logada no SD Card (weights.txt)

Em [sdcard_persistence.c#L201-L211](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/Esp32_Codigo/CodigoPrincipal/drivers/sdcard_persistence/sdcard_persistence.c#L201-L211):

```
MEA|<seq>|<epoch_safe>|<origem: "manual"|"scheduled">|<peso_2casas>
```

Exemplo:
```
MEA|12|1722518400|manual|3245.12
MEA|13|1722519600|scheduled|3244.89
```

### 8.2 Manual ([MEA]) — process_mqtt_data.c
```
[MEA] chegando em /scales/<service>
  └─ measure_routine()
     ├─ seq = pw_next_sequence_id()
     ├─ pw_log_measurement(seq, "manual", global_weight) → weights.txt (se SD up)
     ├─ snprintf("RECEIVED_MEASURE{%.2f}")
     └─ mqtt_send_or_spool(seq, MQTT_TOPIC_WEIGHTS_PUB, 1, payload)
        ├─ SUCESSO → MQTT enviou
        └─ FALHOU (WiFi down / broker down) → pw_outbox_add()
           ├─ SD up   → grava P|seq|qos|topic|payload em outbox.log
           └─ SD fail → enfileira em RAM buffer 10 slots
```

### 8.3 Agendada — weight_timer_scheduler.c
Mesmo fluxo, trocando `"manual"` por `"scheduled"` e `qos=2`.

### 8.4 Reenvio quando WiFi voltar
- `mqtt_outbox_worker_task` (tasks/mqtt_task) roda a cada 1 segundo.
- Chama `pw_outbox_load_pending()` → **resolve automaticamente SD OU RAM buffer.**
- Se SD up: lê 1 pendente por iteração, publica, sucesso → grava `S|seq` no outbox.log (marcador enviado).
- Se SD fail: 1 pendente por iteração do RAM buffer, publica, sucesso → **dequeue do RAM**.

## 9. Persistência no SD Card

### Caminho raiz: `/sdcard/scales/`

| Arquivo | Tamanho limite (rotação) | Versões | Conteúdo |
|---|---|---|---|
| `logs.txt` | sdcard.h | — | Log genérico (sdcard_log) |
| `weights.txt` | 128 KB | 3 | Pesagens estruturadas MEA\|\|\| |
| `baby.txt` | sdcard.h | — | baby_id + weight_time[] agendados |
| `state.txt` | sdcard.h | — | Snapshot completo (boot_epoch, reset_reason, baby_id, horários) |
| `sequence.txt` | ~24 bytes | — | Último sequence_id monotônico |
| `audit.log` | 128 KB | 3 | Eventos estruturados EVT\|\|\| |
| `commands.log` | 64 KB | 3 | Comandos recebidos CMD\|\|\| |
| `critical.log` | 64 KB | 3 | Duplicata de EVT critical apenas |
| `outbox.log` | 256 KB | 2 | Mensagens pendentes `P|seq|qos|topic|payload` + enviadas `S|seq` |

**OBS:** `measurements.log` foi **removido**. Tudo que era measurements agora vai em **weights.txt**.

### Uso de NVS
- Namespace `boot_meta` / chave `last_reset`: razão do último reset (ex: TG1WDT, power-on, SW reset). **Crítico mesmo sem SD.**
- Namespace `storage` / chave `timestamp`: último timestamp NTP conhecido (rotação diária).
- Credenciais WiFi: armazenamento interno padrão do esp_wifi.

### Buffer RAM (fallback SD down)
- 10 slots estáticos `pw_outbox_entry_t[PW_RAM_BUFFER_SLOTS]`.
- Fila circular head/tail/count.
- `pw_outbox_add` quando `g_sys.sd_ok=false` → enfileira aqui.
- Se encher (10 cheios): loga ERRO e descarta (melhor que crashar).
- **Volátil (reinício/power-cut perde tudo).** Solução de último recurso.

## 10. Bloqueio de Segurança (Sanity check, FASE 4)

Timer one-shot FreeRTOS em [main.c#L57-L88](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/Esp32_Codigo/CodigoPrincipal/main/main.c#L57-L88) disparando **120s após boot**:

```
Sanity check lê g_sys.sd_ok e g_sys.mqtt_up:
  ├─ SD=FAIL & MQTT=FAIL → 🔴 pw_safety_critical_loop(
  │                         "SD + MQTT INDISPONIVEIS. NENHUM MEIO DE PERSISTENCIA VALIDO APOS 120S.")
  │                         → LED CRITICAL_ERROR + loop infinito logando a cada 2s.
  │                         → Não pesa (para não gerar pesagem "perdida" juridicamente).
  ├─ SD=FAIL & MQTT=OK  → 🟡 Publica evento CRITICAL em MQTT_TOPIC_CONN_STATUS:
  │                         "EVT|seq|epoch|CRITICAL|SD_FAIL|OPERATING_ONLINE_ONLY_NO_OFFLINE_FALLBACK"
  │                         → Balança continua pesando, mas sem fallback offline.
  └─ Demais combinações  → 🟢 Silencioso (tá tudo ok, ou SD está ok sozinho).
```

## 11. Matriz de Comportamento por Cenário (UTI)

| # | SD | WiFi / MQTT | Balança pesa (manual+agendado)? | Persistência de pesagens | Reenvio quando voltar WiFi? |
|---|---|---|---|---|---|
| 1 | ✅ | ✅ | ✅ | weights.txt + MQTT | — |
| 2 | ✅ | ⏬ (qualquer fase: boot, runtime) | ✅ | weights.txt + outbox.log PENDENTE | ✅ Outbox worker a cada 1s reenvia, marca S\|seq |
| 3 | ⛔ | ✅ (120s) | ✅ | MQTT na hora (sem fallback offline) | — |
| 4 | ⛔ | ⏬ (dentro de 120s) | ✅ | **RAM buffer 10 slots** + MQTT tentando em background | ✅ Quando mqtt sobe → outbox_worker dequeue RAM |
| 5 | ⛔ | ⛔ (após 120s sanity) | ❌ BLOQUEADA | Nenhuma (bloqueio de segurança) | — |
| Runtime: SD up → SD cai durante operação | — | — | ✅ | A partir da próxima escrita: cai em RAM buffer 10 slots | ✅ |
| Runtime: WiFi cai durante operação | ✅ | — | ✅ | A partir da próxima publicação: cai em outbox.log P | ✅ Quando voltar WiFi → reenvio |

## 12. Observabilidade

3 camadas, em ordem de "mais volátil" → "mais permanente":
1. **UART (terminal):** ESP_LOGx com tags.
2. **SD /logs.txt:** sdcard_log() legacy de operação.
3. **SD estruturado + MQTT:** audit.log, commands.log, weights.txt, outbox.log → depois sincronizados via MQTT ou leitura física do cartão.

Backend consegue observar:
- online / offline
- comandos recebidos
- origem pesagem (manual vs scheduled)
- modo degradado SD_FAIL com alerta CRITICAL ao conectar
- bloqueio de segurança (só UART + LED — por design, sistema está propositalmente não-funcional)

## 13. Salvaguardas

- ✅ `mqtt_publish()` tem mutex (sem race de multi-task).
- ✅ Todas writes SD em sdcard.c têm mutex.
- ✅ Pesagem agendada roda em task separada (hx711 é bloqueante SPI, timer não perde deadline).
- ✅ `pw_safe_epoch` nunca é 0.
- ✅ `pw_outbox_load_pending` lê 1 pendente por vez (não enche stack; evita WDT / stack overflow).
- ✅ `pw_ram_buffer` é **static global (BSS)**. Nenhum malloc, nenhum array em task stack.
- ✅ `sdcard_persistence` NÃO crasha se SD down. Todos caminhos: `if (!g_sys.sd_ok) return ESP_OK;`.
- ✅ `wifi_manager_task` não trava app_main — pesagens ativas ANTES do provisionamento.
- ✅ sscanf rígido no parsing do outbox.log: `P|%lu|%d|%63[^|]|%255[^\n]`.
- ✅ Sanity 120s bloqueia o sistema antes de permitir operação sem nenhum meio de auditoria.

## 14. Limitações Conhecidas

1. `[TAR]` (tara) **ainda não implementado.**
2. `/weights/<service>` permanece com payload legacy `"RECEIVED_MEASURE{xx.xx}"` para compatibilidade API. O dado estruturado MEA\|\|\| está apenas em weights.txt + outbox.log por enquanto.
3. Identidade do dispositivo: compile-time por `MQTT_SERVICE_NAME` e `WIFI_DEVICE_NAME`.
4. RAM buffer (10 slots) é volátil. Se cair energia com SD=fail e 10 pesos pendentes, perdem-se. Este é o pior caso conhecido (mitigado pelo sanity check 120s que bloqueia).
5. Rotação de arquivos: renomeia no FAT — se SD for removido no meio da rotação, pode gerar nomes .1/.2 sem arquivo base. Recuperação no próximo boot é automática (cria novo arquivo base vazio).

## 15. Testes Relacionados

- `TESTES_CRITICOS.md`: checklist para injeção de falhas (WiFi drop, SD ausente / em runtime / full, power-cut, saturação comandos, horários). **Atualizado agora também: weights.txt é novo path, measurements.log removido, buffer RAM 10 slots, novos cenários de bloqueio 120s.**
