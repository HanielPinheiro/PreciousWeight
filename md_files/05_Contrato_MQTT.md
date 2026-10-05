# Contrato MQTT do Backend

> Documento técnico para a dissertação. Descreve o protocolo MQTT **exatamente como implementado** no backend actual (`MqttConstants`, `MqttConfig`, `MqttPublisherService`, `MqttSubscriberService`, `ScaleService`).

## 1. Visão Geral

O backend comunica-se com as balanças (firmware ESP32) através de um broker MQTT **Mosquitto**. O backend é, ao mesmo tempo:

- **Publisher** (cliente): envia comandos para as balanças em tópicos `/scales/<mac>`.
- **Subscriber** (cliente): escuta respostas em tópicos `/weights/<mac>`, `/status/<mac>` e `/wifi/<mac>`.
- **API liveness**: publica status retido em `api/status`.

Biblioteca: Eclipse Paho (`org.eclipse.paho.client.mqttv3`), cliente **assíncrono** (`MqttAsyncClient`).

## 2. Configuração do Cliente (`MqttConfig`)

| Propriedade | Valor (application.properties) |
|-------------|--------------------------------|
| `mqtt.broker.url` | `tcp://localhost:5278` |
| `mqtt.broker.username` | `admin` |
| `mqtt.broker.password` | `UltraH4rdP4ss!@` |
| Client ID | `PW_API_SERVICE` (constante `MQTT_API_SERVICE_NAME`) |

Opções de conexão:
- `setCleanSession(false)` — sessão persistente (necessária para QoS 2).
- `setAutomaticReconnect(true)` — reconexão automática.
- `setConnectionTimeout(10)`.

Comportamento do cliente:
- **`connectComplete`**: publica mensagem **retida** `CONNECTED` em `api/status` (QoS 2).
- Após `connect` inicial: publica mensagem **retida** `ONLINE` em `api/status`.
- **Shutdown hook**: publica mensagem **retida** `OFFLINE` em `api/status` e desconecta.

> **Ambiente:** o broker do repositório (`mosquitto/mosquitto.conf`) expõe um listener **sem TLS** na porta **5278** (`allow_anonymous true`) e um listener **TLS** na porta **8883** (com `require_certificate true` e certificados em `certs/`). O backend conecta na porta 5278 (sem TLS).

## 3. Tópicos Utilizados

### 3.1 Publicação (backend → balança)

| Tópico | Descrição | QoS | Retido? |
|--------|-----------|-----|---------|
| `/scales/<mac>` | Comandos de controle para uma balança específica | 2 | Não |
| `api/status` | Status de vida da própria API (`ONLINE`/`OFFLINE`/`CONNECTED`) | 2 | Sim |

### 3.2 Subscrição (balança → backend)

| Tópico | Descrição | QoS |
|--------|-----------|-----|
| `/weights/#` | Pesos publicados pela balança | 2 |
| `/status/#` | Eventos de conexão (`CONNECTED` / `DISCONNECTED`) | 2 |
| `/wifi/#` | Intensidade de sinal WiFi (`[WFS]<valor>`) | 2 |

O sufixo `/#` é substituído pelo **MAC** da balança; ao receber a mensagem, o `MqttSubscriberService` remove o prefixo do tópico e usa o MAC restante como identificador.

## 4. Comandos Publicados (`/scales/<mac>`)

Definidos em `MqttConstants` e enviados por `MqttPublisherService.sendCriticalCommand(mac, comando)`.

| Constante | Payload | Significado | Uso no código |
|-----------|---------|-------------|---------------|
| `MQTT_COMMAND_RUN` | `[RUN]` | Iniciar o monitoramento de pesagem na balança | Após associar bebê/horários |
| `MQTT_COMMAND_BABY` | `[BAB]<id>` | Informar o novo id do bebê | Associar bebê à balança |
| `MQTT_COMMAND_CLEAR` | `[CLE]` | Limpar os dados do bebê anterior | Desassociar bebê / antes de reenviar |
| `MQTT_COMMAND_WEIGHT_TIME` | `[TIM]<HH:mm>` | Agendar um horário de pesagem | Enviar horários do bebê |
| `MQTT_COMMAND_MANUAL_MEASURE` | `[MEA]` | Solicitar uma medição manual imediata | `MeasureWeightViaMqtt` |
| `MQTT_COMMAND_TARE` | `[TAR]` | Tarar (zerar) a balança | `TareScaleViaMqtt` |
| `MQTT_COMMAND_WIFI_STRENGTH` | `[WFS]` | Solicitar a intensidade do sinal WiFi | `MeasureWifiStrengthViaMqtt` |
| `MQTT_COMMAND_CHANGE_WIFI` | `[WIF]` | Solicitar troca/reconfiguração da rede WiFi | `ChangeWifiViaMqtt` |
| `MQTT_COMMAND_SCHEDULED_MEASURE` | `[WEI]` | Prefijo usado na resposta de medição agendada (não é enviado como comando) | — |

### Sequência de associar bebê (`SendBabyDataToScaleViaMqtt`)

```
[CLE]              (limpar estado anterior)
[BAB]<babyId>      (informar bebê)
[TIM]<HH:mm>       (um ou vários horários; múltiplos separados por $)
[RUN]              (iniciar monitoramento)
```

- Se `babyWeightTime` for nulo → usa `DEFAULT_WEIGHT_TIME = "12:00"`.
- Se múltiplos tipos (separados por `$`) → envia um `[TIM]` para cada.
- Acontece ao associar bebê e ao alterar horários (`SendNewWeightTimesToScaleViaMqtt`).

> **Nota sobre `[WIF]`:** o `ScaleController` distingue "medir sinal" (`/wifi_strength`) de "trocar WiFi" (`/change_wifi`). O comando de medir é `[WFS]`; o de trocar é `[WIF]`.

## 5. Publicação com Retry (`MqttPublisherService`)

- Método `sendCriticalCommand(mac, data)` publica em thread separada (`ExecutorService` de 1 thread), **QoS 2**, com `waitForCompletion()`.
- Em falha de envio sobre o ESP32, tenta novamente com **retry** (recursivo, até 100 tentativas, intervalo de 1s).
- É o método usado para `[BAB]`, `[TIM]`, `[RUN]`, `[CLE]`, `[MEA]`, `[TAR]`, `[WFS]`, `[WIF]`.

## 6. Respostas Recebidas (Subscriber)

### 6.1 Pesos — tópico `/weights/<mac>`

`MqttSubscriberService.SubscribeToWeightTopic()` → delega a `ScaleService.SaveWeightFromBroker(mac, payload)`.

O payload da balança tem o formato `PRE{\<valor\>}` ou `PREvalor`:
- `[MEA]{<valor>}` — medição **manual** (`{0.0}`): o valor **não é salvo** no banco; apenas armazenado em memória (`_lastManualMeasuredWeigth`) e retornado ao endpoint.
- `[WEI]<valor>` — medição **agendada**: o valor **é salvo** na tabela `weights`.

Processamento:

```java
message[0]        -> prefijo  (ex.: [MEA] ou [WEI])
message[1]        -> valor    (ex.: 0.0)
Double.parseDouble(message[1].replace("}", ""))
if prefijo == "[WEI]"  -> grava em weights e define flag
else                    -> _lastManualMeasuredWeigth = valor
```

Antes de gravar, a balança é marcada como **conectada** (`SetScaleIsConnectedIfNot`). O `babyId` é obtido da balança vinculada (pode ser `-1` se não houver).

### 6.2 Status de conexão — tópico `/status/<mac>`

`SubscribeToStatusTopic()` → `UpdateConnectionStatusFromBroker(mac, boolean)`.
- Payload `CONNECTED` → `connected = true`.
- Payload `DISCONNECTED` → `connected = false`.

O `ScaleService` então:
1. Atualiza o mapa interno `brokerConnectionStatus`.
2. Busca o `ScaleDataModel` no banco `auth` pelo MAC.
3. Busca o `ScaleModel` de negócio (`app`) pelo UUID/hash.
4. Grava um registro em `wifi_connectivity` (`CONNECTED`/`DISCONNECTED`).
5. Atualiza `is_connected` e `lastConnectedAt`/`lastDisconnectedAt` da balança.

### 6.3 Intensidade de sinal — tópico `/wifi/<mac>`

`SubscribeToWifiTopic()`:
1. Filtra payloads que começam com `[WFS]`.
2. Extrai o inteiro da parte restante via regex `-?\d+`.
3. Delega a `SaveWifiStrengthFromBroker(mac, valor)`.
4. O `ScaleService` grava em `wifi_strengths` e atualiza `scale_last_wifi_strength` da balança, marcando-a como conectada.

> **Correção vs. documentação anterior:** a resposta da intensidade WiFi chega no tópico `/wifi/<mac>` (não `/scales/<mac>`). O tópico `/sensors/#` **não é utilizado** pelo backend atual.

## 7. Espera por Resposta (Sincronismo)

Como o Paho é assíncrono, o `ScaleService` usa um mecanismo de espera por polling com flags:

- `_globalFlagWeightNow` e `_globalFlagWifiStrengthNow` (ints) são zerados antes de enviar o comando e setados a `1` quando a resposta chega (callbacks de `SaveWeightFromBroker` / `SaveWifiStrengthFromBroker`).
- `WaitEsp32Answer(id)` espera em loop (a cada 200 ms) por até **5 segundos**; após esse tempo lança exceção ("Can't receive an answer of scale %d").
- `MeasureWeightViaMqtt` zera a flag de peso, envia `[MEA]`, espera e retorna o último peso medido.
- `MeasureWifiStrengthViaMqtt` zera a flag de WiFi, envia `[WFS]`, espera e retorna o último valor salvo.

> **Limitação observada:** trata-se de um sincronismo global por instância (não thread-safe). Recomenda-se em evolução futura um mecanismo com `CompletableFuture`/correlação por solicitação.

## 8. Heartbeat do Subscriber

`MqttSubscriberService` possui um `@Scheduled(fixedRate = 300000)` (a cada 5 minutos) que apenas registra log `"MQTT subscriber is alive"`.

## 9. Diagrama Resumido do Fluxo MQTT

```
Flutter/API (HTTP)
   |  (ex.: POST /scales/measure_now/{id})
   v
ScaleService.measure   ---(comando)-->   MqttPublisher.sendCriticalCommand:
   v                                          tópico /scales/<mac>  payload [MEA]  (QoS2)
Balança ESP32 responde:
   v
/weights/<mac>  [MEA]{valor}   ->  SaveWeightFromBroker -> flag=1 -> retorna peso
/wifi/<mac>     [WFS]<valor>   ->  SaveWifiStrengthFromBroker -> wifi_strengths
/status/<mac>   CONNECTED/DISCONNECTED -> UpdateConnectionStatusFromBroker
```