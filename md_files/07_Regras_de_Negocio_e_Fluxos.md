# Regras de Negócio e Fluxos

> Documento técnico para a dissertação. Descreve as regras de negócio e os fluxos operacionais implementados no `BabyService` e no `ScaleService`, conforme o código-fonte real.

## 1. Estados

### Bebês (`BabyService.BabyStates`)

- `disabled = 0`
- `enabled = 1`

### Balanças (`ScaleService.ScaleStates`)

- `nonOperant = 0`
- `operant = 1`

## 2. Regras de Negócio (Invariantes)

1. **Um bebê pode ter no máximo uma balança** (relacionamento 1:1) e **uma balança pode ter no máximo um bebê**.
2. **Ativar/desativar bebê**: só é possível se o bebê **não tiver balança vinculada** (`assignedScale == null`).
3. **Ativar/desativar balança**: só é possível se a balança **não tiver bebê vinculado** (`assignedBaby == null`). Lança `"Scale has a baby attached to it. Unset the baby first."`.
4. **Vincular bebê a balança**: exige que
   - a balança exista;
   - a balança **não tenha** outro bebê;
   - o bebê exista;
   - o bebê **não tenha** outra balança;
   - a balança esteja **operante** (`scale_state == 1`).
5. **Desvincular bebê da balança**: remove o vínculo e envia `[CLE]` à balança.
6. **Alteração de horários de pesagem**: se o bebê estiver vinculado a uma balança e o `babyWeightTime` mudar, o backend reenvia `[CLE]` + `[BAB]` + `[TIM]` + `[RUN]` para a balança (`SendNewWeightTimesToScaleViaMqtt`).
7. **Registro de balança de negócio** (`/scales/set/{uuidId}`): só pode registrar se o UUID existir em `auth.scales` e se ainda não houver balança de negócio com o mesmo hash.

## 3. Fluxos Operacionais

### 3.1 Associar Bebê a Balança (`POST /scales/baby/set`)

1. Busca a balança por `scaleId`.
2. Validações (regras 4 acima).
3. Grava `assignedBaby = baby` em `scale.scaleId`.
4. Resolve o MAC via `GetMacFromScaleByHash(scaleHash)`.
5. Envia comandos MQTT (`SendBabyDataToScaleViaMqtt`): `[CLE]` → `[BAB]<id>` → `[TIM]...` → `[RUN]`.
6. Retorna a balança atualizada.

### 3.2 Desassociar Bebê (`POST /scales/baby/unset`)

1. Busca a balança.
2. Limpa `assignedBaby = null`.
3. Envia `[CLE]` à balança.
4. Salva e retorna.

### 3.3 Medição Manual de Peso (`POST /scales/measure_now/{scaleId}`)

1. Resolve o MAC.
2. Zera a flag `_globalFlagWeightNow`.
3. Publica `[MEA]` em `/scales/<mac>` (QoS 2).
4. Aguarda resposta por até 5s (`WaitEsp32Answer`).
5. A balança publica em `/weights/<mac>` um payload `[MEA]{<valor>}`; o valor é armazenado em memória (`_lastManualMeasuredWeigth`) e **não é salvo no banco**.
6. Retorna o último `WeightModel` com o valor atualizado.

### 3.4 Tarar Balança (`POST /scales/tare/{scaleId}`)

1. Publica `[TAR]` em `/scales/<mac>`.
2. Aguarda 2 segundos (`WaitTwoSeconds`).
3. Retorna `true`.

### 3.5 Medir Intensidade WiFi (`POST /scales/wifi_strength/{scaleId}`)

1. Publica `[WFS]` em `/scales/<mac>`.
2. Zera a flag `_globalFlagWifiStrengthNow` e aguarda resposta.
3. A balança responde em `/wifi/<mac>` com `[WFS]<inteiro>`.
4. O valor é **salvo** em `wifi_strengths` e `scale_last_wifi_strength` é atualizado.
5. Retorna `WifiStrengthResponse`.

### 3.6 Trocar Rede WiFi (`POST /scales/change_wifi/{scaleId}`)

1. Publica `[WIF]` em `/scales/<mac>`.
2. Aguarda 2 segundos.
3. Retorna `true`.

### 3.7 Atualizar Horários de Pesagem (`update` em `BabyService`)

1. Busca o bebê.
2. Atualiza campos básicos (hospitalId, nome, mãe, nascimento, imagem text).
3. Se `babyWeightTime` mudou **e** o bebê tem balança vinculada → envia novos horários via MQTT (`[CLE]` + `[BAB]` + `[TIM]...` + `[RUN]`).

### 3.8 Evento de Conexão/Desconexão (`/status/<mac>`)

`UpdateConnectionStatusFromBroker(mac, boolean)`:
1. Atualiza mapa `brokerConnectionStatus`.
2. Busca `ScaleDataModel` (auth) por MAC; se não existir, sai.
3. Busca `ScaleModel` (app) pelo UUID.
4. Grava registro em `wifi_connectivity` (`CONNECTED`/`DISCONNECTED`).
5. Atualiza `is_connected` e `lastConnectedAt`/`lastDisconnectedAt`.
6. Ao receber **peso**: marca a balança conectada se ainda não estiver (`SetScaleIsConnectedIfNot`).

### 3.9 Registro de Dispositivo e Vinculação de Balança

1. `POST /scale_data/new` (admin) cria um `ScaleDataModel` com UUID (auto), MAC e PoP gerado (8 caracteres) se não informado.
2. `POST /scale_data/qr/{id}` retorna um QR Code **PNG 250x250** (ZXing) contendo o UUID textual.
3. `POST /scales/set/{uuid}` cria o `ScaleModel` de negócio com `scale_hash = uuid`. O campo de conexão inicial vem do mapa de status do broker do MAC.

## 4. Conversões DTO→Entidade Relevantes

- `BabyRequest` → `BabyModel` (via construtor; não inclui imagem).
- `WeightRequest.ToModel()`: cria `WeightModel` com `weightDate = now`, `scaleId`, `babyId`, `weightValue`.
- `WifiConnectivityModel(scaleId, boolean)`: converte booleano em string `"CONNECTED"`/`"DISCONNECTED"` e marca a data atual.

## 5. Sincronização de Sinal WiFi

`SyncLatestWifiStrength(scale)` (no `ScaleService`):
- Lê o último `WifiStrengthModel` da balança (`findFirstByScaleIdOrderByWifiStrengthDateDesc`).
- Se diferir do `scale_last_wifi_strength`, atualiza e salva.
- Aplicado ao listar/buscar balanças.

## 6. Resumo dos Efeitos Colaterais (MQTT) Disparados por Ações HTTP

| Ação HTTP | Comandos MQTT | Efeito |
|-----------|---------------|--------|
| `/scales/baby/set` | `[CLE]` `[BAB]` `[TIM]` `[RUN]` | Balança passa a reconhecer o bebê e seus horários |
| `/scales/baby/unset` | `[CLE]` | Balança limpa dados do bebê |
| `/babies/update` (horários alterados) | `[CLE]` `[BAB]` `[TIM]` `[RUN]` | Atualiza agenda da balança |
| `/scales/measure_now/{id}` | `[MEA]` | Medição manual (não persiste) |
| `/scales/tare/{id}` | `[TAR]` | Zera a balança |
| `/scales/wifi_strength/{id}` | `[WFS]` | Leitura de sinal (persiste) |
| `/scales/change_wifi/{id}` | `[WIF]` | Reconfigura rede WiFi da balança |