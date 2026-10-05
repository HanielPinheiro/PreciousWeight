# Precious Weight — Arquitetura (Resumo)

## Sobre Este Documento

Este arquivo resume a arquitetura do **backend Java** atual (Spring Boot) do sistema Precious Weight (balanças neonatais). O conteúdo foi **verificado contra o código-fonte** e corrigido em relação a versões anteriores.

> Para um detalhamento temático, consulte os arquivos complementares:
> `01_Visao_Geral_Backend.md`, `02_Arquitetura_e_Camadas.md`, `03_Modelo_de_Dados_Bancos.md`,
> `04_Autenticacao_e_Seguranca.md`, `05_Contrato_MQTT.md`, `06_API_REST_Endpoints.md`,
> `07_Regras_de_Negocio_e_Fluxos.md` e `08_Auditoria_Envers.md`.

## Sistema em Visão Geral

O sistema tem 3 partes:
1. **App Flutter** (cliente — não neste repositório)
2. **Backend Java** (`spring.security` — este repositório)
3. **Balança ESP32** (dispositivo físico, acessa via MQTT)

O backend é a ponte HTTP ↔ MQTT:
- O Flutter chama endpoints HTTP.
- O backend valida regras e persiste dados.
- O backend publica comandos MQTT para a balança.
- O backend escuta as respostas MQTT e armazena o resultado.

## Bancos de Dados

Dois bancos MySQL lógicos:

### Banco `app` (negócio)
- `babies`, `scales`, `weights`, `wifi_connectivity`, `wifi_strengths`
- Campos de balança relevantes: `scale_id`, `scale_hash`, `scale_state`, `is_connected`, `scale_last_connected_at`, `scale_last_disconnected_at`, `scale_last_wifi_strength`

### Banco `auth` (segurança + registro de dispositivos)
- `users`, `roles`, `user_roles_rel`, `scales` (registro de dispositivo = `ScaleDataModel`)
- Campos do registro: `scale_id` (UUID), `scale_mac`, `scale_pop`, `scale_qrcode`

## Mapeamento de Identidade da Balança

- `app.scales.scale_hash` = `auth.scales.scale_id` (UUID)
- `auth.scales.scale_mac` = sufixo dos tópicos MQTT (`/scales/<mac>`, `/weights/<mac>`, `/status/<mac>`, `/wifi/<mac>`)

Resolução de identidade: `scale_id` (app) → `scale_hash` → UUID (auth) → `mac` → tópico MQTT.

## Contrato MQTT (Atualizado)

O backend usa os seguintes tópicos:

| Direção | Tópico | Payloads |
|---------|--------|----------|
| Comandos (backend→balança) | `/scales/<mac>` | `[BAB]<id>`, `[TIM]<HH:mm>`, `[RUN]`, `[CLE]`, `[MEA]`, `[TAR]`, `[WFS]`, `[WIF]` |
| Pesos (balança→backend) | `/weights/<mac>` | `[MEA]{<valor>}` (manual, **não salva**) / `[WEI]<valor>` (agendada, **salva**) |
| Status (balança→backend) | `/status/<mac>` | `CONNECTED`, `DISCONNECTED` |
| Sinal WiFi (balança→backend) | `/wifi/<mac>` | `[WFS]<inteiro>` |
| Status da API | `api/status` | `ONLINE`, `OFFLINE`, `CONNECTED` (retido) |

**Divergência corrigida:** a resposta de intensidade WiFi chega em `/wifi/<mac>` (e **não** `/scales/<mac>`). O tópico `/sensors/#` **não** é usado.

Comandos publicados por `MqttPublisherService` (QoS 2, com retry).

## Fluxos Ativos

1. **Registrar dispositivo (admin)**: cria `ScaleDataModel` (UUID, MAC, PoP gerado em 8 caracteres). QR Code PNG 250×250 via ZXing com o UUID.
2. **Vincular balança de negócio**: cria `ScaleModel` com `scale_hash = uuid`.
3. **Associar bebê à balança**: valida regras; envia `[CLE]` → `[BAB]` → `[TIM]...` → `[RUN]`.
4. **Desassociar bebê**: envia `[CLE]`; limpa vínculo.
5. **Medição manual**: publica `[MEA]`, aguarda resposta em `/weights/<mac>`, retorna o peso (não persiste).
6. **Medição de sinal WiFi**: publica `[WFS]`, aguarda resposta em `/wifi/<mac>`, persiste em `wifi_strengths`.
7. **Tarar / trocar WiFi**: publica `[TAR]` / `[WIF]`, aguarda 2s.
8. **Rastreio de conexão**: `/status/<mac>` `CONNECTED`/`DISCONNECTED` → atualiza `is_connected`, timestamps e grava `wifi_connectivity`.

## Endpoints Relevantes

### Balanças (`/scales`)
- `list`, `search/{id}`, `hash/{hashId}`, `set/{id}`, `enable/{id}`, `disable/{id}`
- `baby/set`, `baby/unset`
- `measure_now/{scaleId}`, `tare/{scaleId}`, `wifi_strength/{scaleId}`, `change_wifi/{scaleId}`

### Registro de dispositivos (`/scale_data`)
- `search/{id}`, `qr/{id}`, `list`, `new`, `update`

### Outros
- Bebês: `/babies/list|search|save|enable|disable|update|image|qr`
- Pesagens: `/weight/list|save|babies/{babyId}|scales/{scaleId}`
- Auditoria: `/audit/babies|scales|weights`
- Autenticação: `/login`, `/login/reset_password`; usuários: `/users/new`, `/users/list`

> **Nota:** os caminhos não possuem prefixo `/api/v1`. Todos os endpoints usam POST.

## Arquivos Principais do Backend

- `controllers/app/ScaleController.java`, `controllers/app/BabyController.java`, `controllers/app/WeightController.java`, `controllers/app/AuditController.java`
- `controllers/auth/LoginController.java`, `controllers/auth/ScaleDataController.java`, `controllers/auth/UserController.java`
- `app/services/ScaleService.java`, `app/services/BabyService.java`
- `auth/services/MqttPublisherService.java`, `auth/services/MqttSubscriberService.java`, `auth/services/ScaleDataService.java`
- `config/auth/SecurityConfig.java`, `config/auth/AdminUserConfig.java`
- `config/data_source/AppDataSourceConfig.java`, `config/data_source/AuthDataSourceConfig.java`
- `config/mqtt/MqttConfig.java`
- `config/system/ApiConstants.java`, `config/system/MqttConstants.java`, `config/system/DataTransferLayerConstants.java`

## Removido da Documentação

- Não são parte da solução atual do backend: `/sensors/#`, fluxos de firmware não utilizados no contrato backend, e conteúdo genérico de boilerplate Spring não relacionado.