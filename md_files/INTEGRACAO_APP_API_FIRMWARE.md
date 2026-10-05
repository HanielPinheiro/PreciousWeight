# INTEGRACAO_APP_API_FIRMWARE.md — Integração do App Flutter com a API e o Firmware

> Documento complementar de **integração** para uso no NotebookLM. Este arquivo conecta o conhecimento do **app Flutter** (`App_Flutter`) com a **API Java** (`Api_Java`) e o **firmware ESP32** (`Esp32_Codigo`), descrevendo **como o app aciona e recebe dados da balança do ponto de vista do desenvolvedor mobile**. Deve ser lido junto com o `DISSERTACAO_CONTEXTO.md` do app e com os documentos equivalentes dos demais componentes.

---

## 1. Princípio central: o app nunca fala com o broker MQTT

A única exceção de comunicação direta app↔dispositivo é o **provisionamento Wi-Fi via BLE** (envio de SSID/senha ao ESP32). Fora isso:

```
App (Flutter)  ──HTTP/JSON──▶  API (Java)  ──MQTT──▶  Balança (ESP32)
App (Flutter)  ◀──HTTP/JSON──  API (Java)  ◀──MQTT──  Balança (ESP32)
App (Flutter)  ──BLE (provisão Wi-Fi)──────────────▶  Balança (ESP32)   [apenas onboarding]
```

Consequências para a dissertação:

- **Latência e consistência**: todo peso/status chegam ao app por **resposta HTTP síncrona** da API. Não há push/realtime de peso dentro do app.
- **Ponto único de falha**: se a API estiver inacessível, o app não consegue medir peso nem consultar status, mesmo que a balança continue online no MQTT.

---

## 2. Mapeamento de identidade (como o app enxerga a balança)

O app trata a balança por dois identificadores distintos ao longo do fluxo:

| Identificador | Onde é usado no app | Origem |
|---------------|---------------------|--------|
| `hash` | Texto do QR lido; usado para `setNewScale`, `getScaleIdFromHash`, `getScaleDataFromHash` | QR code físico da balança |
| `id` (numérico) | Operações remotas (`measure_now`, `tare`, `change_wifi`, `wifi_strength`, `baby/set`, `baby/unset`, `enable/disable`) | Retornado pela API após registrar/localizar a balança |

Sequência no onboarding:

1. App lê QR → `hash`.
2. `getScaleIdFromHash(hash)` → se `null`, chama `setNewScale(hash)` → API retorna o `ScaleModel` com `id`.
3. `getScaleDataFromHash(hash)` → `[mac, pop]` → usados no provisioning BLE.
4. A partir daí, o app usa majoritariamente o `id` numérico para operar a balança.

> A relação completa com o backend (`scale_hash = scale_data UUID`, `mac = sufixo MQTT`) está documentada no repositório da API Java. Aqui o app só consome os resultados.

---

## 3. Comandos que o app dispara sobre a balança

Tabela dos fluxos de aplicação → API → firmware (do ponto de vista do código Flutter):

| Ação no app | Método do `ScalesProvider` | Endpoint (API) | Papel do firmware (MQTT) |
|-------------|-----------------------------|-----------------|---------------------------|
| Registrar balança (QR) | `setNewScale` | `POST /scales/set/{hash}` | — (registro na API) |
| Medir peso agora | `requestWeightNow` | `POST /scales/measure_now/{id}` | Publica `[MEA]`, devolve peso |
| Tara | `requestTare` | `POST /scales/tare/{id}` | `[TAR]` (tara as 4 células) |
| Trocar Wi-Fi | `requestChangeWifi` | `POST /scales/change_wifi/{id}` | `[WIF]` (reset Wi-Fi + restart) |
| Força de sinal | `requestWifiStrength` | `POST /scales/wifi_strength/{id}` | `[WFS]` (RSSI) |
| Associar bebê | `setOrUnsetBaby(..., baby_code)` | `POST /scales/baby/set` | `[BAB]` + `[TIM]` + `[RUN]` |
| Desassociar bebê | `setOrUnsetBaby(...)` | `POST /scales/baby/unset` | `[CLE]` |
| Ativar/Inativar balança | `enableOrDisableScale` | `POST /scales/enable/{id}` / `/scales/disable/{id}` | — (estado na API) |
| Salvar peso medido | `WeightApi.saveWeight` | `POST /weight/save` | — (persistência na API) |

**Observação de relevância acadêmica:** a existência de `tare`, `change_wifi`, `measure_now` e `wifi_strength` no app (presentes em [scales_details.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/views/scales/scales_details.dart)) demonstra que o app expõe operações **ativas/operacionais** sobre a balança, indo além de apenas consulta passiva.

---

## 4. Como o peso chega ao usuário (passo a passo)

Fluxo de **“Medir Peso Agora”** no app ([scales_details.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/views/scales/scales_details.dart#L124-L174)):

1. Pré-condição: balança **ativa** e **online** (`_canReceiveMqttCommands`).
2. Exibe diálogo de carregamento ("Lendo peso...").
3. `ScalesProvider.requestWeightNow(id)` → `ScaleApi.requestWeightNow` → `POST /scales/measure_now/{id}`.
   - A resposta bruta é recebida; o provider faz parse (pega o conteúdo após o último `:`).
4. O valor é convertido com `double.tryParse`.
   - Se inválido → diálogo de erro ("Valor de peso inválido retornado").
5. Exibe "Peso Medido" (`{valor} g`) em `showWeightResultDialog`.
6. **Se há bebê associado** (`_hasBaby`), oferece o botão **"Salvar peso no BD"**, que chama `WeightApi.saveWeight(babyId, scaleId, weightValue)` (`POST /weight/save`).
7. Se salvo, confirma "Peso salvo no banco de dados!".

> **Nota de fidelidade:** o valor de peso exibido é o **retorno síncrono da API** (que mediu via MQTT `[MEA]` na balança). O app **não** calcula nem filtra o peso; ele apenas formata e, opcionalmente, persiste.

---

## 5. Como o app obtém status e força de sinal

Em `_loadData` ([scales_details.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/views/scales/scales_details.dart#L53-L84)):

- Se a balança está `isConnected` no cache, o app chama `requestWifiStrength(id)`.
  - Sucesso → atualiza `scale.wifiStrength`.
  - Falha → `updateScaleConnectivity(id, false)` e marca a balança offline.
- `_isScaleOnline` = balança ativa E `isConnected`.
- `connectedAt`/`disconnectedAt` vêm do `ScaleModel` populado pela API.

O estado de conectividade **não** vem de um canal push MQTT dentro do app; ele é **derivado** da listagem da API e de uma chamada ativa (força de sinal) na abertura da tela de detalhes.

---

## 6. Associação bebê ↔ balança e integração com horários

- A **associação** é feita no app via `ScalesProvider.setOrUnsetBaby`, chamando `/scales/baby/set` (com `{scaleId, babyId}`) ou `/scales/baby/unset` (com `{scaleId}`).
- Os **horários de coleta de peso** do bebê (`weightHour`, string com horários separados por `$`) são definidos/armazenados no **cadastro do bebê** no app, não diretamente na balança.
- **Documentação necessária (fiel ao código):** o fluxo completo de "configurar horários → alertar a balança via `[TIM]`/`[RUN]`" é responsabilidade da **API** (que lê o horário e publica os comandos MQTT). No app, os horários são apenas capturados/exibidos junto ao cadastro do bebê; o app **não publica** `[TIM]`/`[RUN]` diretamente.

---

## 7. Provisionamento BLE e re-provisionamento (troca de rede)

- **Primeiro onboarding / balança não conectada:** scan com prefixo `PW_`, envia SSID/senha com `pop` (`flutter_esp_ble_prov.provisionWifi`).
- **Troca de Wi-Fi remota** (balança online): `requestChangeWifi` → API publica `[WIF]` → balança reinicia sem rede → o app marca `isConnected=false` e **reabre `BluefiService`** para o usuário informar a nova rede e reprovisionar via BLE.

Esse ciclo ilustra o **looping onboarding ↔ operação** e é relevante para discutir a robustez de dispositivos IoT com Wi-Fi em hospitais.

---

## 8. Dependências entre camadas (para discutir na dissertação)

- **App depende da API** para: autenticação, CRUD de bebês/balanças, pesagem, status, RSSI, associação e auditoria.
- **API depende do broker MQTT e da balança** para executar as operações remotas que o app solicita.
- **A balança depende do Wi-Fi** (provisionado via app/BLE) e da infraestrutura para aceitar comandos (`[MEA]`, `[TAR]`, `[WIF]`, `[WFS]`) e reportar peso.
- **Falha em qualquer elo reduz o conjunto de capacidades do app**:
  - Wi-Fi da balança fora → app não mede peso (ação exige `_canReceiveMqttCommands`).
  - API fora → app não faz nada que dependa de rede/estado.
  - Balança online, API ok → app opera normalmente, mas sem push de eventos.

---

## 9. Conclusão para o texto acadêmico

O app **não é apenas um visualizador**: ele orquestra o **onboarding físico** da balança (BLE), dispara **operações remotas ativas** (medir/tara/trocar rede/RSSI), coordena a **associação clínica** bebê↔dispositivo e **persiste** medições avulsas. Contudo, ele permanece **desacoplado do MQTT**, delegando à API a tradução HTTP↔MQTT — o que introduz um **trade-off arquitetural entre simplicidade de UI e resiliência/latência** a ser discutido na dissertação.