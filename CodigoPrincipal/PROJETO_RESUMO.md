# PreciousWeight (ESP32) — Referência de Projeto

Este arquivo descreve, de forma operacional e comparável, como o firmware do ESP32 funciona hoje: módulos, fluxo de dados do peso, contrato MQTT (tópicos/payloads), provisionamento Wi‑Fi via BLE, persistência em SD e caminhos de observabilidade (status/logs). A intenção é servir como base para outras IAs avaliarem integrações (Flutter, API, broker MQTT) e verificarem se estão usando todas as features expostas pelo firmware atual.

## 1) O que é este projeto

Firmware ESP32 (ESP-IDF) para uma balança (“Precious Weight”) com:

- Leitura contínua de 4 sensores HX711 (4 canais).
- Cálculo de “peso global” (em gramas) a partir das leituras.
- Publicação do peso via MQTT (por agendamento e por comando “medir agora”).
- Recebimento de comandos via MQTT (configurar bebê, horários, medir, limpar, reset de Wi‑Fi).
- Provisionamento Wi‑Fi via BLE (ESP-IDF Wi‑Fi Provisioning Manager).
- Registro de logs e persistência de configuração em cartão SD (FATFS).

## 2) Stack e estrutura (visão de alto nível)

- Linguagem: C
- Framework: ESP-IDF (FreeRTOS, Wi‑Fi, MQTT, provisioning BLE)
- Persistência: SD Card (/sdcard) para logs e “baby+horários”
- Comunicação externa:
  - BLE: apenas para provisionar Wi‑Fi (primeiro uso ou reprovisionamento)
  - MQTT v3.1.x: comandos e telemetria

Arquivos principais (para navegar rápido):

- Boot/orquestração: `main/main.c`
- Config central (IDs do dispositivo, includes): `config/config.h`
- Wi‑Fi + provisioning BLE: `comm/wifi_prov_ble/wifi_prov_ble.c`
- MQTT client (conexão, subscribe/publish): `comm/mqtt_config/mqtt3.c`
- Task MQTT (watchdog + roteamento de mensagens): `tasks/mqtt_task/mqtt_task.c`
- Parser de comandos MQTT: `mqtt_events/parser/process_mqtt_data.c`
- Scheduler (timer e publish agendado): `mqtt_events/scheduler/weight_timer_scheduler.c`
- Sensores (HX711) e peso global: `drivers/hx711/*` e `tasks/sensors_task/sensors_task.c`
- SD card (logs + persistência): `drivers/sdcard/*` e `tasks/sdcard_task/*`

## 3) Identidade do dispositivo (o “ID” usado nos tópicos)

Hoje o projeto usa strings fixas em `config/config.h`:

- `MQTT_SERVICE_NAME`: `"D0EF76590B7C"`
- `WIFI_DEVICE_NAME`: `"PW_D0EF76590B7C"`
- PoP do provisioning BLE (Security 1): `MQTT_POP`: `"KwS2@y6G"`

Consequência:

- Todos os tópicos MQTT do dispositivo são derivados de `MQTT_SERVICE_NAME`.
- Se você clonar esse firmware para outro ESP32 sem mudar essas constantes, vários dispositivos podem colidir nos mesmos tópicos.

## 4) Boot e runtime (ordem de inicialização)

Em `app_main()` (`main/main.c`), a sequência atual é:

1. Inicializa SD (`initialize_sdcard()`).
2. Inicializa Wi‑Fi (`init_wifi()`), podendo entrar em provisioning BLE.
3. Inicializa a task MQTT (`init_mqtt_task()`), que cria o client e assina o tópico de comandos.
4. Inicializa HX711 (`hx711_initialize_sensors()`).
5. Inicia tasks de SD e sensores (`init_sdcard_task()`, `init_sensors_task()`).
6. Inicia o scheduler/timer (`init_weight_sensors_timer()`).
7. Atualiza timestamp de “tempo atual” (`update_current_time()`).

## 5) Leitura do peso (como o “peso global” é calculado)

### 5.1 Sensores HX711

- Existem 4 sensores (`NUM_WEIGHT_SENSORS = 4`).
- Cada sensor tem pinos e fator de calibração definidos em `drivers/hx711/hx711.h`.

### 5.2 Tasks de sensores

Em `tasks/sensors_task/sensors_task.c`:

- 4 tasks “leitoras” (uma por sensor) atualizam `s_last_readings[i]` a cada ~100 ms.
- 1 task “processadora” recalcula o peso global a cada ~1000 ms:
  - Soma as leituras e divide por `SCALE_MEASURE_FACTOR` (1e9).
  - Ajustes atuais:
    - Se `w >= 3000`, aplica `w = w * 0.99`.
    - Se `w <= 50`, zera (`w = 0`).
  - Armazena em `final_weight` (protegido por mutex).

Unidade:

- O payload publicado usa “g” (gramas) com duas casas decimais no MQTT, no formato `[MEA]{123.45}`.

## 6) Provisionamento Wi‑Fi via BLE (o que um app Flutter precisa suportar)

O firmware usa o Wi‑Fi Provisioning Manager do ESP-IDF com scheme BLE:

- Segurança: `WIFI_PROV_SECURITY_1` com Proof-of-Possession (PoP).
- Service UUID BLE custom (definido em `wifi_prov_ble.c`).
- Endpoints registrados:
  - `"PW_PROVISION_DATA"` (criado)
  - `"custom-data"` (handler que responde `"SUCCESS"`)

Fluxo:

- No boot, `init_wifi()` chama `wifi_prov_mgr_is_provisioned()`:
  - Se já provisionado: tenta STA com credenciais salvas e espera obter IP (timeout atual ~10s). Se falhar, chama `reset_wifi()` e reinicia.
  - Se não provisionado: inicia provisioning BLE e aguarda finalização.

Reset Wi‑Fi:

- Função `reset_wifi()` faz: `wifi_prov_mgr_deinit()` → `esp_wifi_stop()` → `esp_wifi_restore()` → `esp_wifi_deinit()` → `esp_restart()`.
- Existe comando MQTT `[WIF]` que aciona esse reset (mas só funciona quando você já consegue mandar MQTT).

## 7) Contrato MQTT (tópicos, QoS, status e payloads)

### 7.1 Broker

Em `comm/mqtt_config/mqtt3.h`:

- `MQTT_ADDRESS`: `mqtt://192.168.15.4:5278`
- TLS/mTLS existe como opção comentada em `mqtt3.c`, mas o modo ativo atualmente é sem `.verification` e sem `.credentials`.

### 7.2 Tópicos

Todos os tópicos incluem o sufixo `MQTT_SERVICE_NAME` (ex.: `D0EF76590B7C`).

- Comandos (ESP32 recebe):
  - `/scales/<service>`
  - Ex.: `/scales/D0EF76590B7C`
- Status (ESP32 publica):
  - `/status/<service>`
  - Ex.: `/status/D0EF76590B7C`
- Peso sob demanda + ACK de comandos (ESP32 publica):
  - `/weights/<service>`
  - Ex.: `/weights/D0EF76590B7C`

Observação importante:

- O tópico `/weights/<service>` é “multiplexado”: nele aparecem ACKs (`"1"`/`"0"`), resultados de medida (`[MEA]{...}`), força do Wi‑Fi (`[WFS]{...}`) e mensagens de erro textuais (ex.: `ERROR_MAX_WEIGHT_TIMES_ACHIEVED`).

### 7.3 QoS e retain

- Subscribe de comandos: QoS 1.
- Publish status:
  - Ao conectar: `"CONNECTED"` (QoS 1).
  - Last Will (LWT): `"DISCONNECTED"` com `retain=true` (QoS 1).
- Publish de pesos agendados em `/weights`: QoS 2.
- Publish em `/weights` sob demanda e respostas simples: em geral QoS 1.

### 7.4 Status (como “ver o status da balança”)

Para saber se o firmware está online no broker:

- Inscreva no tópico: `/status/<service>`
- Interprete:
  - `CONNECTED`: o ESP32 conectou no broker.
  - `DISCONNECTED` (retained): o broker marcou o client como offline (LWT).

## 8) Comandos MQTT (o que uma API/app pode enviar)

Os comandos são enviados como payload (string) para `/scales/<service>`. O parser reconhece prefixos fixos:

| Comando           | Payload exemplo | Efeito no ESP32                                                    | Resposta (publish em `/weights/<service>`)               |
| ----------------- | --------------- | ------------------------------------------------------------------ | -------------------------------------------------------- |
| Definir bebê      | `[BAB]123456`   | Limpa estado atual e define `baby_id`                              | `"1"` (OK) ou `"0"` (erro)                               |
| Adicionar horário | `[TIM]08:00`    | Adiciona um horário à lista                                        | `"1"` ou `"0"`                                           |
| Rodar/agendar     | `[RUN]`         | Salva `baby_id`+horários no SD (`/sdcard/baby.txt`) e arma o timer | `"1"` ou `"0"`                                           |
| Limpar rotina     | `[CLE]`         | Zera bebê+horários, apaga arquivo e para o timer                   | `"1"` ou `"0"`                                           |
| Medir agora       | `[MEA]`         | Publica uma medida imediata                                        | Publica `[MEA]{<gramas com .00>}` e também publica `"1"` |
| Força do Wi‑Fi    | `[WFS]`         | Publica o RSSI atual do Wi‑Fi                                      | Publica `[WFS]{<rssi>}` e também publica `"1"`           |
| Calibrar          | `[CAL]...`      | Hoje é stub (retorna OK, não altera calibração)                    | `"1"` (mas não calibra de fato)                          |
| Reset Wi‑Fi       | `[WIF]`         | Para MQTT, reseta Wi‑Fi e reinicia o ESP32                         | geralmente não dá tempo de observar ACK consistente      |

### 8.1 “Medida em tempo real” (passo a passo)

1. Publique:

```text
topic: /scales/D0EF76590B7C
payload: [MEA]
```

2. Escute:

```text
topic: /weights/D0EF76590B7C
payload esperado: [MEA]{<gramas com .00>}
```

Observação:

- O mesmo tópico também receberá `"1"` como ACK de comando.

### 8.2 “Configurar horários e receber medidas automáticas”

Sequência típica:

```text
/scales/D0EF76590B7C  [BAB]BEBE001
/scales/D0EF76590B7C  [TIM]08:00
/scales/D0EF76590B7C  [TIM]12:00
/scales/D0EF76590B7C  [TIM]18:00
/scales/D0EF76590B7C  [RUN]
```

Depois disso, em cada horário escolhido, o firmware publica em:

```text
topic: /weights/D0EF76590B7C
payload: [MEA]{<gramas com .00>}
```

## 9) Scheduler (como o agendamento funciona)

O scheduler em `mqtt_events/scheduler/weight_timer_scheduler.c`:

- Calcula o “próximo horário” comparando `now` vs lista `weight_times[]`.
- Se o horário já passou no dia, agenda para o próximo dia.
- Usa um timer one-shot (FreeRTOS) para disparar a próxima medida.
- Ao disparar:
  - Lê `get_global_weight()`
  - Um worker publica em `/weights/<service>` como `[MEA]{...}`
  - Agenda o próximo disparo (se ainda existir schedule).

## 10) Persistência e logs (SD Card)

### 10.1 Arquivos usados

Em `drivers/sdcard/sdcard.h`:

- Logs: `/sdcard/logs.txt`
- Rotina bebê+horários: `/sdcard/baby.txt`
- Existe também `/sdcard/weights.txt` definido, mas o fluxo principal de publish não depende dele.

### 10.2 Como os logs são produzidos

- `sdcard_log()` empacota mensagens e envia para uma fila (`sdcard_log_queue`).
- `tasks/sdcard_task/sdcard_task.c` consome a fila e grava no arquivo.
- Ao receber um comando MQTT, o firmware loga no SD:
  - timestamp (`current_time`)
  - “MENSAGEM RECEBIDA VIA MQTT:”
  - o payload recebido

### 10.3 Como “ver logs vindo do app”

Não existe (ainda) um tópico MQTT de logs do ESP32. Então, para observar “logs” no caminho app→API→MQTT→ESP32, você tem 3 opções:

1. No broker/API, registre (log) cada publish feito para `/scales/<service>` e cada mensagem recebida de `/weights`, `/status` (isso cobre a trilha completa pelo MQTT).
2. No ESP32, use logs seriais (`ESP_LOGx`) via monitor serial.
3. No ESP32, leia o arquivo `/sdcard/logs.txt` (log persistente).

## 11) Integração com API e app (checklist prático)

### 11.1 Para uma API “ponte” (HTTP ↔ MQTT)

- Publish comandos em `/scales/<service>` (payloads `[BAB]`, `[TIM]`, `[RUN]`, `[CLE]`, `[MEA]`, `[WFS]`, `[WIF]`).
- Subscribe em:
  - `/status/<service>` (para online/offline; considerar retained do LWT)
  - `/weights/<service>` (ACK + resultados de `[MEA]` + resultados de `[WFS]` + medidas agendadas + possíveis erros textuais)
- Correlação recomendada:
  - Como o ACK é apenas `"1"`/`"0"` (sem ID de comando), a API deve serializar comandos por dispositivo (evitar enviar múltiplos em paralelo) para não confundir qual comando foi confirmado.

### 11.2 Para um app Flutter

Se o app precisa “usar todas as features” do firmware, o app (ou um módulo auxiliar) precisa suportar:

- BLE provisioning do ESP-IDF (Security 1 + PoP) para setar SSID/senha no primeiro uso.
- Exibir status online/offline via `/status/<service>`.
- Configurar rotina:
  - enviar bebê e horários e executar `[RUN]`
  - exibir resultados agendados (via `/weights/<service>`)
- “Medir agora”:
  - enviar `[MEA]` e capturar `[MEA]{...}` via `/weights/<service>`
- Força do Wi‑Fi:
  - enviar `[WFS]` e capturar `[WFS]{...}` via `/weights/<service>`

## 12) Pontos de atenção (estado atual e limitações)

- `/weights/<service>` mistura ACK e dados; não há “message id” para correlacionar respostas.
- Limite de horários:
  - Existe `MAX_WEIGHT_TIMES = 10`, mas o handler de `[TIM]` incrementa `number_of_weight_times` sem checar limite antes de escrever em `weight_times[]`.
  - A checagem em `process_mqtt_data()` não bloqueia corretamente o comando `[TIM]` quando o limite é atingido.
- `[CAL]` retorna OK, mas hoje não aplica calibração (stub).
- IDs do dispositivo e broker estão hardcoded; para produção, é esperado que o `service` seja derivado do MAC/serial e configurável.
- TLS/mTLS está preparado (comentado), mas no modo ativo o MQTT é sem TLS.

## 13) “Mapa mental” do fluxo (app → API → MQTT → ESP32)

### 13.1 Comandos (controle)

1. App/API publica comando → `/scales/<service>`
2. ESP32 recebe → valida prefixo → executa rotina
3. ESP32 publica:
   - ACK em `/weights/<service>`: `"1"` ou `"0"`
   - e, no caso de `[MEA]` e `[WFS]`, também publica o payload de retorno no mesmo tópico
4. API/app consome e atualiza UI/estado

### 13.2 Telemetria (pesos agendados)

1. Scheduler dispara no horário
2. ESP32 publica em `/weights/<service>`: `[MEA]{<g com .00>}`
3. API/app consome e registra/exibe
