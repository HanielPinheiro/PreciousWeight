# Arquitetura e Camadas do Backend

> Documento técnico para a dissertação. Apresenta a arquitetura lógica do backend, os padrões de código utilizados e as decisões de design observadas no código-fonte real.

## 1. Visão Arquitetural Geral

O backend segue um estilo de **arquitetura em camadas (layered/package-by-layer)** combinada com separação por **contexto** (`app` vs `auth`). Não se trata de um monólito com camadas rígidas de domínio/aplicação/infraestrutura em pacotes distintos, mas de uma organização por **módulos funcionais**, onde cada pacote agrupa interface (repositório), modelo, serviços e controllers relacionados.

As camadas lógicas são:

```
Controllers (REST)  ->  Services (regras de negócio)  ->  Repositories (JPA)  ->  MySQL/DB
                                                          |
                                                          +--> MQTT (publisher/subscriber) -> Balança ESP32
```

### Camada de Controllers
- `controllers/app`: AuditController, BabyController, ScaleController, WeightController.
- `controllers/auth`: LoginController, ScaleDataController, UserController.
- Toda chamada é delegada a um serviço; os controllers não contêm lógica de negócio.
- Utilizam `@PreAuthorize` para controle de acesso.

### Camada de Serviços
- `app/services`: `BabyService` (bebês), `ScaleService` (balanças e MQTT).
- `auth/services`: `MqttPublisherService`, `MqttSubscriberService`, `ScaleDataService`. Contém também `ProFuturo__QrCodeService`, um gerador de QR Code implementado manualmente (referência thonky.com, Reed-Solomon) que **não é referenciado por nenhum controller/serviço** — o QR Code efetivamente utilizado é o de `ScaleDataService` (biblioteca ZXing).

### Camada de Persistência
- Interfaces `i*` (`JpaRepository`) em `app/interfaces` e `auth/interfaces`.
- `models`: entidades JPA mapeadas via constantes de `DataTransferLayerConstants`.

### Camada de Configuração
- Segurança, DataSources, MQTT e constantes (config/system).

## 2. Mapeamento de Conceitos entre `app` e `auth`

Um ponto central da arquitetura é a **vinculação entre a balança de negócio (`app.scales`) e o registro de dispositivo (`auth.scales` / scale_data)**.

| Conceito | Entidade no banco `app` | Entidade/valor no banco `auth` |
|----------|--------------------------|--------------------------------|
| Identificador interno | `scale_id` (Integer, auto-increment) | — |
| Identificador (UUID) | `scale_hash` (String) | `scale_id` (UUID) |
| Endereço físico | — (obtido via service) | `scale_mac` (String) |
| Prova de posse | — | `scale_pop` (String) |
| QR Code | — | `scale_qrcode` (Blob) |

**Regra de resolução de identidade da balança (usada pelo `ScaleService`):**

1. `scale_id` (interno) → buscar `ScaleModel` (`app.scales`).
2. `scale_hash` → igual ao `scale_id` (UUID) do registro em `auth.scales`.
3. UUID → buscar o `mac` correspondente em `auth.scales` (via `ScaleDataService`).
4. `mac` → formar o **sufixo dos tópicos MQTT** (ex.: `/scales/<mac>`).

> **Importante:** no banco `auth`, a tabela que guarda o registro do dispositivo também se chama `scales` (constante `Auth_ScaleTable_TableName`), o que difere do nome lógico `scale_data` usado na documentação inicial. No código, a entidade é `ScaleDataModel`.

## 3. Padrões de Código Observados

| Padrão | Onde é usado |
|--------|--------------|
| **Repository Pattern** | Interfaces `iBaby`, `iScale`, `iWeight`, `iWifiStrength`, `iWifiConnectivity`, `iUser`, `iRole`, `iScaleData` (extendem `JpaRepository`). |
| **DTO Pattern (Request/Response)** | `models/request/*` para entrada; `models/response/*` para saída. Evitam expor entidades JPA diretamente (em parte). |
| **Service Layer** | `BabyService`, `ScaleService` centralizam regras de negócio. |
| **Constructor Injection** em auth (ex.: `LoginController`, `UserController`, `MqttPublisherService`) e `@Autowired` por campo em app. |
| **Enumeradores de estado** | `BabyService.BabyStates` (disabled=0, enabled=1); `ScaleService.ScaleStates` (nonOperant=0, operant=1). |
| **Constantes centralizadas** | `ApiConstants` (rotas), `MqttConstants` (tópicos/comandos), `DataTransferLayerConstants` (nomes de tabelas/colunas). |

## 4. Decisões de Design Relevantes

### 4.1 FKs denormalizadas em vez de relacionamentos JPA
As entidades `WeightModel`, `WifiConnectivityModel` e `WifiStrengthModel` **não** possuem `@ManyToOne`/`@OneToMany`; usam campos `Integer` simples (`scaleId`, `babyId`) como chaves estrangeiras lógicas. Isso desacopla as entidades mas perde integridade referencial gestionada pelo JPA.

### 4.2 Relacionamento 1:1 entre Bebê e Balança
- `ScaleModel.assignedBaby` é `@OneToOne @JoinColumn(name = baby_id)` (lado dono).
- `BabyModel.assignedScale` é `@OneToOne(mappedBy = "assignedBaby", fetch = LAZY)` (lado inverso).
- Um bebê pode ter no máximo uma balança e vice-versa.

### 4.3 Auditoria por padrão
Todas as entidades `app` (`BabyModel`, `ScaleModel`, `WeightModel`, `WifiConnectivityModel`, `WifiStrengthModel`) são `@Audited`. O campo de imagem do bebê é `@NotAudited` (Blob).

### 4.4 Retorno de `WeightModel`/`ScaleModel` direto em alguns controllers
O `WeightController` retorna `WeightModel` diretamente (não `WeightResponse`), enquanto `ScaleController` e `BabyController` usam DTOs de resposta. Há uma inconsistência de padronização no código-fonte real.

## 5. Pontos de Atenção Técnicos (observados no código)

> Itens apenas descritivos; o usuário pediu que **nenhum código fosse alterado**, apenas documentado.

1. **Sincronização assíncrona por "flags"**: o `ScaleService` usa variáveis `_globalFlagWeightNow` e `_globalFlagWifiStrengthNow` (int) + `_lastManualMeasuredWeigth` para aguardar resposta da balança. Não são thread-safe; em requisições concorrentes podem haver corridas.
2. **Busca com possível problema N+1**: `ScaleService.GetScales()` chama `SyncLatestWifiStrength` para cada balança, gerando consulta extra por item.
3. **Ausência de `@Transactional` explícita** em vários métodos de serviço que fazem múltiplos `save`.
4. **Exceções genéricas (`Exception`)** com mensagens mistas português/inglês.
5. **`ScaleRequest` usa PascalCase** nos campos (`ScaleId`, `BabyId`), divergindo do camelCase das demais entidades.
6. **Timezone fixo** `America/Sao_Paulo` via `@JsonFormat` em vários campos de data.

## 6. Configuração de Execução (parâmetros de ambiente)

Fonte: `application.properties`.

```
# Chaves JWT (RSA) — arquivos classpath
jwt.public.key = classpath:app.pub
jwt.private.key = classpath:app.key

# Envers
spring.jpa.properties.org.hibernate.envers.audit_table_suffix = _AUDIT
spring.jpa.properties.org.hibernate.envers.revision_field_name = REV
spring.jpa.properties.org.hibernate.envers.revision_type_field_name = REVTYPE

# Banco auth
spring.auth.datasource.jdbc-url = jdbc:mysql://localhost:3306/auth_db
spring.auth.datasource.username = admin
spring.auth.datasource.password = 123

# Banco app
spring.app.datasource.jdbc-url = jdbc:mysql://localhost:3306/app_db
spring.app.datasource.username = admin
spring.app.datasource.password = 123

# Broker MQTT
mqtt.broker.url = tcp://localhost:5278
mqtt.broker.username = admin
mqtt.broker.password = UltraH4rdP4ss!@
```

> **Observação de infraestrutura:** o broker Mosquitto deste repositório está configurado para a porta **5278** (vista em `mosquitto/mosquitto.conf` como ambiente de desenvolvimento) e o `docker-compose.yml` provisiona MySQL na porta 3306 com usuário `admin`/`123` e cria o banco `auth_db`. A credencial do broker é sensível; não usá-la em produção.