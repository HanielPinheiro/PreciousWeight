# API REST — Catálogo de Endpoints

> Documento técnico para a dissertação. Lista todos os endpoints HTTP implementados, com método, caminho, autorização, parâmetros, corpo e retorno, conforme o código-fonte real (`ApiConstants` e controllers). **Não há prefixo `/api/v1`** — as rotas partem da raiz do contexto (base do servidor).

## 1. Convenções Gerais

- Todos os endpoints são **POST**.
- Respostas de erro são, na maioria, `400 Bad Request` com corpo `{"error": "<mensagem>"}`.
- Autorização:
  - Vários exigem apenas `isAuthenticated()`.
  - Alguns exigem `hasAuthority('SCOPE_ADMIN')`.
  - Login, reset de senha e criação de usuário são públicos.
- Autenticação via `Authorization: Bearer <token>` (JWT).

## 2. Autenticação — `LoginController`

| Método | Caminho | Autorização | Corpo | Retorno |
|--------|---------|-------------|-------|---------|
| POST | `/login` | Público | `LoginRequest {email, password}` | `LoginResponse {accessToken, expiresIn, user}` |
| POST | `/login/reset_password` | Público | `LoginRequest {email, password}` | `Void` (200) |

## 3. Usuários — `UserController`

| Método | Caminho | Autorização | Corpo | Retorno |
|--------|---------|-------------|-------|---------|
| POST | `/users/new` | Público | `UserRequest {email, password, organization}` | `Void` (200) — cria usuário com papel BASIC |
| POST | `/users/list` | `SCOPE_ADMIN` | — | `List<UserModel>` |

## 4. Registro de Dispositivos (scale_data) — `ScaleDataController`

| Método | Caminho | Autorização | Corpo | Retorno |
|--------|---------|-------------|-------|---------|
| POST | `/scale_data/search/{id}` | `isAuthenticated()` | `{id}` (UUID path) | `ScaleDataResponse {scaleId, mac, pop}` |
| POST | `/scale_data/qr/{id}` | `isAuthenticated()` | `{id}` (UUID path) | Imagem QR Code (PNG) |
| POST | `/scale_data/list` | `SCOPE_ADMIN` | — | `List<ScaleDataResponse>` |
| POST | `/scale_data/new` | `SCOPE_ADMIN` | `ScaleDataRequest {id?, mac, pop?}` | `ScaleDataResponse` |
| POST | `/scale_data/update` | `SCOPE_ADMIN` | `ScaleDataRequest {id, mac, pop?}` | `ScaleDataResponse` |

Regras:
- **new**: valida se o MAC já foi registrado; se sim → 400.
- **update**: valida existência do registro e se o novo MAC não colide com outro.

## 5. Bebês — `BabyController`

| Método | Caminho | Autorização | Corpo | Retorno |
|--------|---------|-------------|-------|---------|
| POST | `/babies/list` | `isAuthenticated()` | — | `List<BabyResponse>` |
| POST | `/babies/search/{id}` | `isAuthenticated()` | `{id}` (Integer path) | `BabyResponse` |
| POST | `/babies/save` | `isAuthenticated()` | `BabyRequest` | `BabyResponse` |
| POST | `/babies/enable/{id}` | `isAuthenticated()` | `{id}` | `BabyResponse` |
| POST | `/babies/disable/{id}` | `isAuthenticated()` | `{id}` | `BabyResponse` |
| POST | `/babies/update/{id}` | `isAuthenticated()` | `{id}` + `BabyRequest` | `BabyResponse` |
| POST | `/babies/image/{id}` | `isAuthenticated()` | `multipart file` | `"Image Updated Successfully"` |
| POST | `/babies/qr/{id}` | `isAuthenticated()` | `{id}` | Imagem QR Code (PNG), 404 se não houver |

## 6. Balanças — `ScaleController`

| Método | Caminho | Autorização | Corpo | Retorno |
|--------|---------|-------------|-------|---------|
| POST | `/scales/list` | `isAuthenticated()` | — | `List<ScaleResponse>` |
| POST | `/scales/search/{id}` | `isAuthenticated()` | `{id}` (Integer) | `ScaleResponse` |
| POST | `/scales/hash/{hashId}` | `isAuthenticated()` | `{hashId}` (UUID) | `ScaleResponse` |
| POST | `/scales/set/{id}` | `isAuthenticated()` | `{id}` (UUID) | `ScaleResponse` — registra balança de negócio a partir do scale_data |
| POST | `/scales/enable/{id}` | `isAuthenticated()` | `{id}` (Integer) | `ScaleResponse` |
| POST | `/scales/disable/{id}` | `isAuthenticated()` | `{id}` (Integer) | `ScaleResponse` |
| POST | `/scales/baby/set` | `isAuthenticated()` | `ScaleRequest {ScaleId, BabyId}` | `ScaleResponse` |
| POST | `/scales/baby/unset` | `isAuthenticated()` | `ScaleRequest {ScaleId, BabyId}` | `ScaleResponse` |
| POST | `/scales/measure_now/{scaleId}` | `isAuthenticated()` | `{scaleId}` (Integer) | `WeightModel` (via MQTT) |
| POST | `/scales/tare/{scaleId}` | `isAuthenticated()` | `{scaleId}` | `true` (via MQTT) |
| POST | `/scales/wifi_strength/{scaleId}` | `isAuthenticated()` | `{scaleId}` | `WifiStrengthResponse` (via MQTT) |
| POST | `/scales/change_wifi/{scaleId}` | `isAuthenticated()` | `{scaleId}` | `true` (via MQTT) |

## 7. Pesagens — `WeightController`

| Método | Caminho | Autorização | Corpo | Retorno |
|--------|---------|-------------|-------|---------|
| POST | `/weight/list` | `isAuthenticated()` | — | `List<WeightModel>` |
| POST | `/weight/save` | `isAuthenticated()` | `WeightRequest {scaleId, babyId, weightValue}` | `WeightModel` |
| POST | `/weight/babies/{babyId}` | `isAuthenticated()` | `{babyId}` | `List<WeightModel>` |
| POST | `/weight/scales/{scaleId}` | `isAuthenticated()` | `{scaleId}` | `List<WeightModel>` |

> **Nota:** `WeightController` está no caminho `/weight` (singular), conforme `ApiConstants.WeightController`. Os retornos usam `WeightModel` diretamente (não `WeightResponse`).

## 8. Auditoria — `AuditController`

| Método | Caminho | Autorização | Corpo | Retorno |
|--------|---------|-------------|-------|---------|
| POST | `/audit/babies/{babyId}` | `isAuthenticated()` | `{babyId}` | `List<Object[]>` (revisões do bebê) |
| POST | `/audit/scales/{scaleId}` | `isAuthenticated()` | `{scaleId}` | `List<Object[]>` (revisões da balança) |
| POST | `/audit/weights/{babyId}` | `isAuthenticated()` | `{babyId}` | `List<Object[]>` (revisões de pesagem do bebê) |

Cada revisão é um array de 3 posições: `[Entidade (DTO), CustomRevisionEntity (com username), RevisionType]`.

## 9. Mapa de Constantes de Rota (referência)

`ApiConstants.java`:

```
/login
/login/reset_password
/users
/scale_data
/scale_data/update
/babies
/scales
  /set/{id}
  /baby/set
  /baby/unset
  /hash/{hashId}
  /measure_now/{scaleId}
  /tare/{scaleId}
  /wifi_strength/{scaleId}
  /change_wifi/{scaleId}
/weight
  /babies/{babyId}
  /scales/{scaleId}
/audit
  /babies/{babyId}
  /scales/{scaleId}
  /weights/{babyId}
```

## 10. Observações

- Todos os endpoints usam **POST**, inclusive operações de leitura (`list`, `search`) — escolha de design do projeto.
- A resposta de `measure_now` retorna `WeightModel` (o último peso manual recebido).
- A resposta de `tare` e `change_wifi` são simplesmente `true` após envio do comando MQTT e espera de 2s.