# Visão Geral do Backend Precious Weight

> Documentação técnica do backend Java usada como material para a dissertação de mestrado.
> Escopo: **somente a camada de backend** contida no repositório `Api_Java/spring.security`.
> Seu objetivo é descrever o sistema real implementado, sem alucinação e sem conteúdo não existente no código.

## 1. Propósito do Sistema

O **Precious Weight** é um sistema de gerenciamento de pesagens de recém-nascidos (balanças neonatais). O repositório atual contém o **backend** Java (Spring Boot), responsável por:

1. Expor uma **API REST** consumida pelo aplicativo móvel (Flutter).
2. Validar as **regras de negócio** e persistir dados.
3. Intermediar a comunicação com a **balança física** (ESP32) via **MQTT**.
4. Garantir **autenticação e autorização** via JWT/OAuth2.
5. Manter **auditoria** das alterações (Hibernate Envers).

O backend é a ponte entre o mundo HTTP (aplicativo) e o mundo MQTT (balança):

- O aplicativo chama endpoints HTTP.
- O backend valida regras, persiste dados e publica comandos MQTT para a balança.
- O backend escuta os tópicos MQTT, processa as respostas da balança e armazena o resultado.

## 2. Componentes do Backend

O backend é um projeto Maven-Spring Boot com as seguintes características técnicas:

| Item | Valor |
|------|-------|
| Linguagem | Java **21** |
| Framework | Spring Boot **3.4.3** |
| Gerenciador | Maven (artifact `spring.security`, group `precious_weight`) |
| Segurança | Spring Security + OAuth2 Resource Server (JWT assimétrico RSA) |
| Persistência | Spring Data JPA + Hibernate Envers (auditoria) |
| Banco de dados | MySQL (2 bancos lógicos: `app` e `auth`) |
| Broker MQTT | Eclipse Paho (cliente assíncrono) + MOSQUITTO (broker) |
| QR Code | Google ZXing |
| Descrição do projeto | "Neonatal Scales Management" |

### Dependências principais (`pom.xml`)

- `spring-boot-starter-data-jpa`
- `spring-boot-starter-oauth2-client`
- `spring-boot-starter-security`
- `spring-boot-starter-web`
- `spring-security-oauth2-resource-server`
- `hibernate-envers` (6.4.4.Final)
- `org.eclipse.paho.client.mqttv3` (1.2.5)
- `mysql-connector-j`, `postgresql`
- `com.google.zxing:core` e `com.google.zxing:javase` (3.4.1)

## 3. Estrutura de Pacotes

```
precious_weight
├── app/                     # Camada de aplicação (dados de negócio)
│   ├── interfaces/          # Repositórios JPA (iBaby, iScale, iWeight, iWifiConnectivity, iWifiStrength)
│   ├── models/              # Entidades de negócio
│   │   ├── envers/          # Auditoria (AuditRepository, CustomRevisionEntity)
│   │   ├── request/         # DTOs de entrada
│   │   └── response/        # DTOs de saída
│   └── services/            # Serviços de negócio (BabyService, ScaleService)
├── auth/                    # Camada de autenticação e registro de dispositivos
│   ├── interfaces/          # Repositórios (iUser, iRole, iScaleData)
│   ├── models/              # Entidades de segurança
│   │   ├── request/         # DTOs (LoginRequest, ScaleDataRequest, UserRequest)
│   │   └── response/        # DTOs (LoginResponse, ScaleDataResponse, UserResponse)
│   └── services/            # MqttPublisher, MqttSubscriber, ScaleData, QrCode
├── config/                  # Configurações
│   ├── auth/                # SecurityConfig, AdminUserConfig
│   ├── data_source/         # AppDataSourceConfig (primary), AuthDataSourceConfig
│   ├── mqtt/                # MqttConfig
│   └── system/              # Constantes (ApiConstants, MqttConstants, DataTransferLayerConstants)
└── controllers/
    ├── app/                 # AuditController, BabyController, ScaleController, WeightController
    └── auth/                # LoginController, ScaleDataController, UserController
```

## 4. Dois Bancos de Dados Lógicos

O sistema separa responsabilidades em dois bancos MySQL:

| Banco | Papel | Pacote JPA scan | DataSource |
|-------|-------|-----------------|------------|
| `app_db` | Dados operacionais de negócio (bebês, balanças, pesagens, WiFi) | `precious_weight.app` | `appDataSource` (**@Primary**) |
| `auth_db` | Segurança e registro de dispositivos (usuários, papéis, scale_data) | `precious_weight.auth` | `authDataSource` |

Cada banco possui seu próprio DataSource, `EntityManagerFactory` e `TransactionManager` (configurados em `AppDataSourceConfig` e `AuthDataSourceConfig`). O banco `app` é o primário.

> Detalhe completo das tabelas e colunas está no arquivo **03_Modelo_de_Dados_Bancos.md**.

## 5. Cadeia de Execução Típica

1. O aplicativo autentica no `POST /login` e recebe um JWT (RSA assinado).
2. As requisições protegidas carregam o JWT no cabeçalho `Authorization: Bearer <token>`.
3. O Spring Security valida o token (OAuth2 Resource Server) e verifica permissões via `@PreAuthorize`.
4. O controller recebe o DTO de request, chama o serviço de negócio.
5. O serviço valida regras e persiste via repositório JPA no banco `app` **ou** `auth`.
6. Quando necessário, o serviço publica comandos MQTT para a balança e aguarda a resposta.
7. O `MqttSubscriberService` recebe as respostas e delega ao `ScaleService` para persistência.

## 6. Referência aos Demais Documentos

| Tema | Arquivo |
|------|---------|
| Camadas, padrões arquiteturais e decisões | `02_Arquitetura_e_Camadas.md` |
| Modelo de dados e bancos | `03_Modelo_de_Dados_Bancos.md` |
| Autenticação, autorização e segurança | `04_Autenticacao_e_Seguranca.md` |
| Contrato MQTT completo | `05_Contrato_MQTT.md` |
| Catálogo de endpoints REST | `06_API_REST_Endpoints.md` |
| Regras de negócio e fluxos | `07_Regras_de_Negocio_e_Fluxos.md` |
| Auditoria (Envers) | `08_Auditoria_Envers.md` |