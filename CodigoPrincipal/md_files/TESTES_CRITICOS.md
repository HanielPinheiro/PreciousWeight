# TESTES_CRITICOS.md — Checklist de Validação (UTI Neonatal)

Checklist de injeção de falhas **alinhado ao comportamento real do firmware em HEAD**. Revisado contra o source: **pesagem agendada e manual dependem de WiFi/MQTT** (o scheduler só é armado após WiFi+SNTP), enquanto a **aquisição/agregação de sensores roda desde o boot (Fase 2)**. O teste 120 s de segurança e o outbox offline permanecem válidos.

---

## 1. Provisionamento BLE

| ID | Caso | Passo-a-passo | Esperado |
|----|------|---------------|----------|
| P1 | Provisionamento frio (sem credenciais) | 1. Flash o firmware. 2. Acione `[WIF]` para forçar estado não provisionado. 3. App de provisionamento conecta no device name. 4. Envie SSID + senha da rede válida. | BLE visível até credencial enviada. Em ~5 s: BLE some, ESP32 conecta no AP, obtém IP, sincroniza SNTP, inicia MQTT. `audit.log` ganha `EVT\|...\|MQTT_CONNECTED`. |
| P2 | Timeout de STA antes de reprovisionamento BLE | 1. Credenciais existem, mas AP desligado. 2. Reset. 3. Mede tempo de espera. | 3 tentativas STA × 15 s ≈ 45 s. Sem IP, cai em BLE provisioning. **Atenção:** durante esse período **não há scheduler armado** (depende de WiFi); apenas leitura/agregação de sensores e tara de boot ativas. `g_sys.wifi_up=false`. |
| P3 | Provisionamento enquanto "passa o horário agendado" | 1. Boot sem WiFi. 2. Horário agendado em baby.txt é carregado do SD. 3. Demora no BLE passando do horário. | **A pesagem agendada NÃO dispara sem WiFi** — o scheduler (`init_weight_sensors_timer`) só é criado após WiFi+SNTP. O horário carregado fica armazenado e, quando o WiFi subir, o scheduler arma o **próximo** horário a partir daquele momento (ver §5 para o cálculo). Nenhum `MEA|...|scheduled` é gerado durante o BLE. |

---

## 2. Conectividade — Runtime

| ID | Caso | Passo-a-passo | Esperado |
|----|------|---------------|----------|
| C1 | WiFi cai por 5 min enquanto pesa | 1. Sistema online normal (scheduler armado). 2. Agende 1 min à frente. 3. Desligue o AP por 5 min. 4. Deixe 2 pesagens agendadas passarem. 5. Ligue AP. | Cada pesagem: grava em weights.txt e, se publish falhar, `P\|...` no outbox.log. Sem crash/WDT durante ausência. Quando WiFi volta (~30 s DHCP+SNTP+MQTT), outbox_worker (1 Hz) reenvia e marca `S\|seq`. |
| C2 | Broker MQTT cai mas WiFi fica UP | 1. Online. 2. `[MEA]`. 3. Desligue broker 3 min. 4. `[MEA]` 2× + 1 agendado. 5. Ligue broker. | WiFi OK mas publish falha → as medições vão a outbox.log pendentes. Broker sobe → outbox_worker reenvia e marca `S\|seq`. |
| C3 | Flood de desconexões → reset | 1. Runtime WiFi UP. 2. Desliga AP permanentemente. 3. Conta `WIFI_EVENT_STA_DISCONNECTED`. | Após **15 desconexões**: `reset_wifi()` → stop MQTT → `esp_wifi_restore()` (apaga credenciais) → `esp_wifi_deinit()` → `esp_restart()`. No próximo boot, provisionamento BLE. |
| C4 | Força do sinal WiFi | 1. Online. 2. `[WFS]`. | Publica RSSI em `/wifi/<service>` com payload `[WFS]{rssi}`. Não crasha. |

---

## 3. Cartão SD

### 3.1 Estrutura de arquivos

Após boot + ≥1 comando, `/sdcard/scales/` deve conter:

```
/sdcard/scales/
├── logs.txt            (sdcard_log)
├── weights.txt         (MEA|seq|epoch|manual/scheduled|xx.xx)
├── baby.txt            (baby_id + weight_times)
├── state.txt           (boot_epoch, reset_reason, baby_id, horários)
├── sequence.txt        (uint32 monotônico)
├── audit.log           (EVT|...)
├── commands.log        (CMD|seq|epoch|payload)
├── critical.log        (só EVT critical)
└── outbox.log          (P|... e S|...)
```

❌ `measurements.log` não deve existir — regressão.

### 3.2 Casos de falha SD

| ID | Caso | Passo-a-passo | Esperado |
|----|------|---------------|----------|
| S1 | Cartão em branco / sem `/sdcard/scales` | 1. Cartão FAT32 vazio. 2. Insira. 3. Boot. | Cria `/sdcard/scales/`. Arquivos aparecem no primeiro uso. Passa normal. |
| S2 | Cartão ausente no boot | 1. Retire SD. 2. Reset. 3. `[MEA]` (via MQTT) nos primeiros 120 s. | Fase 1: `g_sys.sd_ok=false`; boot continua. Fase 2 inicializa HX711/sensors. **O `[MEA]`/agendada não geram peso sem WiFi/MQTT** (ver §2). Se MQTT estiver up, peso é publicado; em SD down, `pw_outbox_add` cai em **RAM buffer 10 slots**. No sanity 120 s: SD=fail & MQTT=fail → bloqueio; SD=fail & MQTT=ok → alerta CRITICAL em `/status/` e segue. |
| S3 | SD ausente, MQTT conecta < 120 s | 1. Retire SD. 2. Boot. 3. Broker ok. 4. Mede tempo até MQTT conectar (<120 s). 5. Sanity 120 s. | Pesa e publica via MQTT (pesagens exigem comando/agenda → online). Sanity vê `mqtt_up=true, sd_ok=false` → alerta CRITICAL (1 vez). Sistema operante, sem fallback offline. |
| S4 | Remove SD durante runtime | 1. SD OK, online. 2. Remova. 3. `[MEA]`. 4. Espere agendado. | Próxima escrita SD falha; `g_sys.sd_ok` fica inconsistente (true), writes falham silenciosamente → cai em RAM buffer. Se >10 pendentes: loga ERRO "RAM buffer CHEIO" e descarta novos. Não crasha. |
| S5 | SD FULL (ENOSPC) | 1. Cartão ~100% cheio. 2. Loop `[MEA]`. | `sdcard_write_file` retorna ESP_FAIL; `last_sd_errno=ENOSPC`. Na task sdcard, após 5 falhas, gera evento CRITICAL `SD_FULL` em audit/critical.log (publicação MQTT comentada). Não crasha. |

---

## 4. Energia / Power-Cut

| ID | Caso | Passo-a-passo | Esperado |
|----|------|---------------|----------|
| E1 | Corte de energia DURANTE escrita SD | 1. Loop de pesagem agendado (online, 1 min). 2. Corte energia na escrita. 3. Religue. | Cartão permanece legível. `state.txt` recriado se vazio. `sequence.txt` corrompido → recria em 0 (monotonicidade perdida nesse caso, ver nota). Sem deadlock/loop de crash. |
| E2 | Corte DURANTE publish `[MEA]` (outbox pendente) | 1. WiFi UP. 2. `[MEA]`. 3. Corte antes do ack do broker. 4. Religue. 5. Verifique outbox.log. | Se `P\|seq\|...` escrito antes do corte → boot reenvia e marca `S\|seq` (nada perdido). Se linha malformada → `sscanf` rígido ignora e segue, sem crash. |

> Nota E1: a monotonicidade estrita do `sequence.txt` assume escrita atômica; um corte no meio da sobrescrita pode zerar o ID (código recria em 0). É uma limitação conhecida — backends devem tolerar reinício de sequência após corrupção do arquivo.

---

## 5. Timeline / Auditoria

| ID | Caso | Esperado |
|----|------|----------|
| A1 | `[BAB]` + vários `[TIM]` + `[RUN]` + `[MEA]` + `[WFS]` | `commands.log` grava `CMD\|...` para cada comando; `audit.log` grava `EVT`; `weights.txt` grava `MEA` para `[MEA]` e pesagens agendadas. Atenção: `[RUN]` só arma scheduler se WiFi/SNTP ok. |
| A2 | Pesagem agendada: 1 entrada weights + 1 publish/outbox | 1 linha `MEA`. 1 publicação (sucesso) OU 1 `P\|...` no outbox (falha). Sem duplicatas nem meia-publicação. |
| A3 | Manutenção de sequence_id por reboot | `[MEA]` → seq=X; reset; `[MEA]` → seq=X+1. **Nota:** se SD ausente no boot, sequence roda em RAM a partir de 0 (reinicia). Com SD ok, é monotônico persistido. |

---

## 6. Limites / Robustez

| ID | Caso | Esperado |
|----|------|----------|
| L1 | Exceder `MAX_WEIGHT_TIMES` (10) | Enviar >10 `[TIM]` → extras rejeitados (retorna "ERROR_MAX_WEIGHT_TIMES_ACHIEVED" em `/weights/`). Sem leak/corrupção. |
| L2 | Flood de comandos em `/scales/` | 1000 cmd/s. Sem trava. Se fila de comandos (10) encher → loga "Fila de comandos MQTT cheia". Sem WDT reset. Agendadas mantêm deadline (task dedicada). |
| L3 | RAM buffer 10 slots + SD=fail | SD down, WiFi down (sem pesagens possíveis, mas validar enfileiramento se MQTT estiver up). 1–10: bufferiza em RAM; >10: ERRO "RAM buffer CHEIO", descarta. Não crasha. |
| L4 | Bloqueio de segurança 120 s | SD ausente + AP desligado (MQTT nunca conecta). Boot. Esperar 120 s. | 0–120 s: aquisição de sensores ativa, porém sem pesagens (sem MQTT p/ comandar/agendar). >120 s: `pw_safety_critical_loop` dispara, LED CRITICAL, mensagem a cada 2 s "SD + MQTT INDISPONIVEIS...". Sistema para de operar propositalmente. WDT não dispara (`vTaskDelay`). |

---