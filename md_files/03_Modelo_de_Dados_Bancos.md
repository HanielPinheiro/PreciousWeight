# Modelo de Dados e Bancos de Dados

> Documento técnico para a dissertação. Descreve os dois bancos MySQL do backend, as tabelas, colunas e o mapeamento JPA extraído diretamente do código-fonte (`DataTransferLayerConstants`, `models/`).

## 1. Visão Geral

O backend usa **dois bancos MySQL logicamente separados**:

- **`app_db`** — dados operacionais de negócio.
- **`auth_db`** — segurança (usuários, papéis) e registro de dispositivos (scale_data).

Os nomes de tabelas e colunas não aparecem "hardcoded" nas entidades, mas são centralizados na classe `config/system/DataTransferLayerConstants.java`.

> A auditoria via Hibernate Envers gera, para cada entidade `@Audited`, uma tabela de histórico com sufixo **`_AUDIT`** (config `org.hibernate.envers.audit_table_suffix = _AUDIT`). Os campos REV (número de revisão) e REVTYPE (tipo: ADD/MOD/DEL) são usados.

## 2. Banco de Dados `app_db`

### 2.1 Tabela `babies` (Bebês)

Entidade: `BabyModel` — `@Audited`

| Coluna | Tipo (Java) | Detalhes |
|--------|-------------|----------|
| `baby_id` | Integer | PK, auto-increment |
| `baby_name` | String | Nome |
| `baby_mother_name` | String | Nome da mãe |
| `baby_birthdate` | LocalDate | Data de nascimento (`yyyy-MM-dd`) |
| `baby_state` | Integer | Estado (0 = disabled, 1 = enabled) |
| `baby_weight_hour` | String | Horário(s) de pesagem (pode ser único ou múltiplos separados por `$`) |
| `baby_hospital_id` | String | Identificador hospitalar — `nullable=false`, `unique=true` |
| `baby_image_text` | String | Texto/QRCode textual |
| `baby_image` | Blob | Imagem (QRCode) — `@NotAudited`, `@JsonIgnore`, unique |

Relacionamento: `@OneToOne(mappedBy = "assignedBaby", fetch = LAZY)` com `ScaleModel` (lado inverso).

### 2.2 Tabela `scales` (Balanças de negócio)

Entidade: `ScaleModel` — `@Audited`

| Coluna | Tipo (Java) | Detalhes |
|--------|-------------|----------|
| `scale_id` | Integer | PK, auto-increment |
| `scale_hash` | String | UUID (string) — `nullable=false`, `unique=true`. É o mesmo valor do `scale_id` de `auth.scales`. |
| `scale_state` | Integer | `nullable=false` (0 = nonOperant, 1 = operant) |
| `is_connected` | Boolean | `nullable=false`, default `false` |
| `scale_last_connected_at` | LocalDateTime | Timestamp de última conexão |
| `scale_last_disconnected_at` | LocalDateTime | Timestamp de última desconexão |
| `scale_last_wifi_strength` | Integer | `nullable=false` — último valor de intensidade WiFi (RSSI) |
| `baby_id` | Integer (FK) | `@OneToOne @JoinColumn` para `babies` (bebê vinculado) |

### 2.3 Tabela `weights` (Pesagens)

Entidade: `WeightModel` — `@Audited`

| Coluna | Tipo (Java) | Detalhes |
|--------|-------------|----------|
| `weight_id` | Integer | PK, auto-increment |
| `weight_date` | LocalDateTime | `nullable=false` — data/hora da pesagem |
| `scale_id` | Integer | `nullable=false` — FK lógica para `scales` |
| `baby_id` | Integer | `nullable=false` — FK lógica para `babies` |
| `weight_value` | Double | `nullable=false` — valor do peso (kg) |

> Ausência de `@ManyToOne`: `scale_id` e `baby_id` são apenas campos inteiros (FK denormalizada).

### 2.4 Tabela `wifi_connectivity` (Conectividade)

Entidade: `WifiConnectivityModel` — `@Audited`

| Coluna | Tipo (Java) | Detalhes |
|--------|-------------|----------|
| `wifi_connectivity_id` | Integer | PK, auto-increment |
| `wifi_connectivity_date` | LocalDateTime | `nullable=false` |
| `scale_id` | Integer | `nullable=false` — FK lógica |
| `wifi_connectivity_value` | String | `nullable=false` — valores literais `"CONNECTED"` / `"DISCONNECTED"` |

### 2.5 Tabela `wifi_strengths` (Intensidade de sinal)

Entidade: `WifiStrengthModel` — `@Audited`

| Coluna | Tipo (Java) | Detalhes |
|--------|-------------|----------|
| `wifi_strength_id` | Integer | PK, auto-increment |
| `wifi_strength_date` | LocalDateTime | `nullable=false` |
| `scale_id` | Integer | `nullable=false` — FK lógica |
| `wifi_strength_value` | Integer | `nullable=false` — valor do sinal |

> O `ScaleModel.scale_last_wifi_strength` é sincronizado com o último registro desta tabela (método `SyncLatestWifiStrength` do `ScaleService`).

## 3. Banco de Dados `auth_db`

### 3.1 Tabela `users` (Usuários)

Entidade: `UserModel`

| Coluna | Tipo (Java) | Detalhes |
|--------|-------------|----------|
| `user_id` | UUID | PK (`GenerationType.UUID`) |
| `user_email` | String | `nullable=false`, `unique=true` |
| `user_password` | String | `nullable=false`, `@JsonIgnore` (hasheada BCrypt) |
| `user_org` | String | `nullable=false` — organização |

Relacionamento: `@ManyToMany` com `RoleModel` via tabela `user_roles_rel`, `fetch = EAGER`, `cascade = MERGE`.

### 3.2 Tabela `roles` (Papéis)

Entidade: `RoleModel`

| Coluna | Tipo (Java) | Detalhes |
|--------|-------------|----------|
| `role_id` | Long | PK, auto-increment |
| `role_name` | String | Nome do papel |

Valores fixos (enum `RoleModel.Values`):
- `ADMIN` → role_id `1`
- `BASIC` → role_id `2`

### 3.3 Tabela `user_roles_rel` (Junção N:N)

| Coluna | Tipo | Detalhes |
|--------|------|----------|
| `user_id` | FK | Referencia `users.user_id` |
| `role_id` | FK | Referencia `roles.role_id` |

### 3.4 Tabela `scales` (Registro de dispositivos — scale_data)

Entidade: `ScaleDataModel`

| Coluna | Tipo (Java) | Detalhes |
|--------|-------------|----------|
| `scale_id` | UUID | PK (`GenerationType.UUID`) |
| `scale_mac` | String | Endereço MAC da balança (ESP32) |
| `scale_pop` | String | Proof of Possession (senha de posse, 8 caracteres) |
| `scale_qrcode` | Blob | Imagem QR Code binária |

> **Importante:** no banco `auth`, a tabela do registro do dispositivo chama-se `scales` (mesmo nome da tabela de negócio em `app`), mas a entidade é `ScaleDataModel`. A documentação se refere a esse registro também pela nomenclatura **scale_data** (usada no controller `/scale_data`).

## 4. Relacionamentos entre Entidades

```
BabyModel (1) <--1:1--> (0..1) ScaleModel
   |                              |
   | (N, via baby_id)             | (N, via scale_id)
   v                              v
WeightModel                 WeightModel
                                 | (N, via scale_id)
                                +--> WifiConnectivityModel
                                +--> WifiStrengthModel
```

- Relacionamento **1:1** real via JPA: `BabyModel` ↔ `ScaleModel`.
- Relacionamentos **1:N implícitos** (sem anotação JPA): `WeightModel`, `WifiConnectivityModel`, `WifiStrengthModel` referenciam `scale_id`/`baby_id` como inteiros.

## 5. Auditoria Envers

- Configurações (em `application.properties`):
  - `audit_table_suffix = _AUDIT`
  - `revision_field_name = REV`
  - `revision_type_field_name = REVTYPE`
- Todas as entidades `app` são `@Audited`; `baby_image` é `@NotAudited`.
- A entidade de revisão customizada `CustomRevisionEntity` estende `DefaultRevisionEntity` e adiciona o campo **`username`** (identifica quem fez a alteração).
- Query de histórico implementada em `AuditRepository` usando `AuditReaderFactory`:
  - `getBabyRevisions(babyId)`
  - `getScaleRevisions(scaleId)`
  - `getWeightRevisions(babyId)` (filtra por `babyId` via `AuditEntity.property("babyId")`)
- Cada revisão retorna um array de 3 elementos: `[Entidade, CustomRevisionEntity, RevisionType]`.

## 6. Provisionamento e Inicialização

- `docker/docker-compose.yml`: container MySQL (`precious-weight-mysql`, porta 3306), usuário `admin`, senha `123`, banco inicial `app_db`, e monta `docker/init.sql` em `/docker-entrypoint-initdb.d/`.
- `docker/init.sql`: cria o banco `auth_db` e concede privilégios ao usuário `admin`.
- Schema de `app` e `auth` é gerenciado automaticamente pelo Hibernate (`hibernate.hbm2ddl.auto = update`) em ambos os EntityManagers (não via script SQL inicial).
- O `AdminUserConfig` (CommandLineRunner) cria os papéis `ADMIN`/`BASIC` e um usuário admin padrão no primeiro boot (ver documento de segurança).

## 7. Scripts SQL manuais (para ajuste do banco)

O arquivo **RerunScripts.md** reúne scripts auxiliares (ex.: adicionar colunas de conectividade em `scales`, criar a tabela `wifi_strengths`) para cenários em que a migração automática não resolve. São executados na base `app_db`.