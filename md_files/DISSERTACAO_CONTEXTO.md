# DISSERTACAO_CONTEXTO.md — Contexto Acadêmico do Aplicativo Flutter (PreciousWeight)

> Documento-síntese usado como **fonte primária no NotebookLM** para redigir a dissertação. Consolida a solução do **aplicativo móvel Flutter** do sistema **PreciousWeight** — balança pediátrica inteligente para UTI neonatal. Toda descrição técnica é **fiel ao código em HEAD** (revisado contra o source, sem comportamento presumido). Este arquivo deve ser lido em conjunto com os documentos de `md_files` dos demais componentes do sistema (firmware ESP32 e API Java), pois o app é apenas uma das três camadas da solução.

> **Posicionamento deste documento:** cobre **somente o aplicativo móvel**. A descrição do firmware (ESP32/HX711/precisão < 5 g) e da API Java (front-end de integração HTTP↔MQTT) pertence aos arquivos equivalentes dos respectivos repositórios. Aqui, o foco é: como o app entrega o fluxo clínico de monitoramento neonatal, como ele se comunica com a API, e como ele realiza o provisionamento Wi-Fi da balança via BLE.

---

## 1. Resumo executivo

O **Precious Weight** é um aplicativo móvel **Flutter** (Dart) para dispositivos mobile que apoia o **monitoramento do peso de recém-nascidos (RN) em ambiente hospitalar/UTI neonatal**. O app cobre o ciclo operacional completo do uso clínico, integrando-se a uma **API backend Java** (HTTP) que, por sua vez, conversa com a **balança (ESP32)** via **MQTT**.

Principais capacidades implementadas no app:

- **Autenticação** de equipe hospitalar (login, cadastro de usuário e redefinição de senha).
- **Gestão de bebês (pacientes)**: cadastro, edição, ativação/inativação, identidade por QR e horários de coleta de peso.
- **Gestão de balanças (dispositivos)**: cadastro por QR, ativação/inativação, estado operacional, conectividade e força de sinal Wi-Fi.
- **Associação 1-bebê ↔ 1-balança** (vínculo exclusivo mútuo).
- **Medição de peso em tempo real** ("Medir Peso Agora") com opção de salvar no banco.
- **Tara remota** e **troca/reescolha de rede Wi-Fi** da balança via BLE.
- **Provisionamento Wi-Fi da balança via BLE (Bluetooth Low Energy)**, iniciado por leitura de QR code, usando o protocolo oficial de provisioning do ESP32 (`flutter_esp_ble_prov`).
- **Visualização da evolução ponderal** do bebê (gráfico de linha interativo + lista de medições, agrupados por mês, com resumos diários por mediana/mín/máx).
- **Histórico de auditoria** (quem alterou o quê e quando) para bebês, balanças e pesos.

**Contribuição para o contexto de dissertação:** o app materializa o **fecho do loop de dados** do sistema — é a interface humana que inicia medições, associa o paciente ao dispositivo, acompanha a evolução ponderal e consulta a auditoria. Ele também realiza a **etapa de onboarding físico** da balança (provisionamento de credenciais Wi-Fi via BLE), fechando a ponte entre o dispositivo embarcado e a infraestrutura de rede clinica.

---

## 2. Papel do app dentro da arquitetura de 3 camadas

O sistema completo tem 3 partes — todas já documentadas separadamente:

1. **App Flutter** (este repositório) — interface do usuário + onboarding BLE.
2. **API Java** (`Api_Java`) — ponte HTTP ↔ MQTT, persistência de dados de negócio e auditoria.
3. **ESP32** (`Esp32_Codigo`) — balança, aquisição de peso, comunicação MQTT.

Hierarquia de comunicação (fluxo de dados real):

- O **app** fala **somente com a API** por **HTTP (JSON)**, nunca diretamente com o broker MQTT nem com o ESP32.
- A **API** recebe comandos HTTP do app, valida regras de negócio, persiste dados e **publica comandos MQTT** para a balança.
- A **API** também **assina** tópicos MQTT de resposta/peso/status da balança e devolve os resultados ao app via HTTP.
- A exceção a esse padrão (contato direto do app com o dispositivo) é o **provisionamento Wi-Fi via BLE**, em que o app escaneia e envia as credenciais Wi-Fi diretamente ao ESP32 via Bluetooth — neste passo não há envolvimento da API (embora os dados `mac`/`pop` usados no provisioning venham da API).

> **Nota de fidelidade:** o app **não assina tópicos MQTT diretamente**. Toda medição, status ou força de sinal chega ao app **por resposta HTTP síncrona** da API, que por sua vez obteve o dado da balança via MQTT.

---

## 3. Stack tecnológica e dependências

- **Linguagem:** Dart (SDK `^3.5.0`), framework **Flutter**.
- **Gerenciador de estado:** pacote `provider` (`ChangeNotifier` + `MultiProvider`).
- **HTTP:** pacote `http` + `http_parser`; suporte a `IOClient` com certificado custom (modo debug).
- **QR Code:** `mobile_scanner` (leitura) e `pretty_qr_code` (renderização/exibição).
- **Provisionamento BLE do ESP32:** `flutter_esp_ble_prov` (protocolo oficial Wi-Fi provisioning do ESP-IDF).
- **Grâfico de evolução:** `fl_chart`.
- **Captura de imagem (foto do QR do bebê):** `image_picker`.
- **Permissões de plataforma:** `permission_handler`.
- **Detecção da versão Android (SDK):** `device_info_plus`.
- **Fonte/tipografia:** `google_fonts` (Amaranth, Baloo 2, Roboto Flex, Noto Sans KR, Caprasimo, Poppins).
- **Utilitários:** `intl` (datas/horas), `path_provider`.
- **Configuração de artefatos:** `flutter_native_splash`, `flutter_launcher_icons`.

Lista completa e versões versionadas em [pubspec.yaml](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/pubspec.yaml).

---

## 4. Estrutura de código (organização por camadas)

O projeto separa **UI**, **estado** e **infraestrutura**:

| Camada | Diretório | Responsabilidade |
|--------|-----------|------------------|
| Entrada do app | [lib/main.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/main.dart) | Registra Providers (`MultiProvider`) e define `MaterialApp`, temas luz/escuro e rota inicial (Login). |
| Views (UI) | [lib/views/](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/views/) | Telas e fluxos: Login, Home, Bebês, Balanças, Registros (auditoria). |
| Providers (estado) | [lib/repository/providers/](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/repository/providers/) | `BabyProvider` e `ScalesProvider` (`ChangeNotifier`) com cache em memória. |
| API clients | [lib/api/](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/api/) | Clients por recurso: users, babies, scales, weights, logs. |
| Models | [lib/models/](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/models/) | Modelos de domínio e mapeamento JSON. |
| Services (infra) | [lib/repository/services/](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/repository/services/) | `api_service.dart` (HTTP + erros), `qrcode_service.dart` (scanner), `bluefi_service.dart` (provisionamento BLE). |
| Design system | [lib/repository/design/](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/repository/design/) | Tema, cores, tipografia e estilos de botão. |
| Widgets reutilizáveis | [lib/repository/widgets/](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/repository/widgets/) | `elements.dart` (componentes de UI), `menu.dart` (navegação inferior), `baby_weight_chart.dart` (gráfico). |

---

## 5. Inicialização do app e gerenciamento de estado

### 5.1 Boot (`main.dart`)

Em [main.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/main.dart#L9-L17), o `runApp` injeta dois providers globais via `MultiProvider`:

- `BabyProvider` — gerencia bebês.
- `ScalesProvider` — gerencia balanças.

Aplicação:

- `MaterialApp` com `themeMode: ThemeMode.system`, temas `PreciousWeightTheme.light()` e `.dark()`.
- Rota inicial: `LoginPage`.

### 5.2 Providers (cache em memória)

- [BabyProvider](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/repository/providers/baby_provider.dart) mantém um `Map<int, BabyModel>` como cache. Expõe listas filtradas (`activeBabies`, `inactiveBabies`, `availableBabies`). Ao carregar, enriquece cada bebê com dados extras (QR e balança associada). Valida o payload obrigatório antes de chamar a API.
- [ScalesProvider](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/repository/providers/scales_provider.dart) mantém uma `List<ScaleModel>`. Ao carregar, enriquece cada balança com `mac`/`pop` vindos da API (necessários ao BLE). Também agrega as operações remotas (medir peso, tara, trocar Wi-Fi, força de sinal) e o estado de conectividade da balança em cache.

> **Implicação de design:** ambos os providers usam **cache em memória** e **não persistem tokens ou dados sensíveis**. Isso tem impacto direto no modelo de segurança (ver seção 11).

### 5.3 Padrão de acesso escolhido

As views usam `context.watch<T>()` para reagir a mudanças de estado e `context.read<T>()` para acessos pontuais sem re-render (ex.: em handlers de evento). Esse padrão está documentado em comentários nos próprios arquivos de UI (ex.: [scales.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/views/scales/scales.dart#L12-L17)).

---

## 6. Camada de rede e tratamento de erros

### 6.1 `ApiService`

[api_service.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/repository/services/api_service.dart) é o wrapper HTTP central com:

- Método `apiConn()` para chamadas `POST` retornando o corpo decodificado como **UTF-8** (usa `Utf8Decoder` sobre `bodyBytes`).
- Em modo debug (`kDebugMode` local, constante custom em constants), usa `IOClient` com `badCertificateCallback` para aceitar um **único IP de VPS** (`191.252.159.22`) — artefato de desenvolvimento.
- Erros não-2xx viram `ApiException` estruturada com `statusCode`, `message` e `details`.
- `getQrCode()` baixa bytes de imagem (QR).
- `uploadQrCode()` envia PNG via `MultipartRequest`.
- `SafeApi.call<T>()` é o helper usado pelas telas/providers: executa a chamada, aplica `onSuccess`, e em erro chama `ApiErrorHandler.handleError` (exceto quando `abortErrorMessage = true`), propagando a exceção.

### 6.2 `ApiErrorHandler`

[api_error_handler.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/repository/helper/api_error_handler.dart):

- Detecta erros contendo "401" e dispara o fluxo **"Login Expirado"**: mostra diálogo, faz `UserApi().Logout()` e redireciona para `LoginPage`.
- Demais erros abrem um diálogo genérico ("Erro de requisição").

### 6.3 Base da API

A URL base está em [constants.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/repository/helper/constants.dart#L26-L29). Estado atual no código:

- `address_api = "https://pw-api.velarsoluti.vps-kinghost.net"` (produção, HTTPS).
- Endpoints desativados/legados comentados: endereço local de emulador e um IP de VPS de teste.

---

## 7. Autenticação e sessão

[user_api.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/api/user_api.dart) implementa um **Singleton `UserApi()`** que mantém o usuário logado e o token em memória:

- `Login(email, password)` — chamada `POST /login`; em falha de rede lança erro específico; senha incorreta gera mensagem "Usuario ou senha incorretos!".
  - **Nota de fidelidade:** existem fallbacks hardcoded de credenciais admin no corpo da `Login` quando os campos vêm vazios (artefato de desenvolvimento presente no HEAD).
- `Logout()` — zera o objeto singleton.
- `NewUser(email, password)` — `POST /users/new` (grava `organization: "Hospital Geral"` fixo).
- `ResetPassword(email, newPassword)` — `POST /reset_password`.
- `listUsers()` — `POST /users/list`.

Todos os endpoints autenticados enviam `Authorization: Bearer <accessToken>` (montado nos API clients via `UserApi().token!.accessToken`).

**Implicações de segurança (fiel ao código):**

- O token é guardado **somente em memória** (sem secure storage). Matar o app exige novo login.
- Não há refresh de token implementado nesta base.
- `userUser` mantém `organization`, `userId`, `email` e `roles`.

---

## 8. Domínio de dados (modelos)

### 8.1 `BabyModel` — [baby.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/models/baby.dart)

Campos principais (recebidos da API como JSON):

- `hospitalRegister` (registro hospitalar), `name`, `motherName`, `birthDate`.
- `isActive` — status interno/em tratamento.
- Identidade QR: `qrCodeText` (texto escaneado) **ou** `qrCodeImage` (foto/imagem do QR). O flag `hasQrCode` é `true` quando há imagem (i.e., `qrCodeText == null`).
- `scaleId` e `assignedScale` — vínculo com a balança.
- `weightHour` — horário(s) da coleta de peso (string separada por `$`).

O modelo também expõe `getWeights()` (busca pesos do bebê via `WeightApi`).

### 8.2 `ScaleModel` — [scales.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/models/scales.dart)

Campos principais:

- `id` (numérico, vindo da API), `hash` (identidade via QR).
- `status` (1 ativo / 0 inativo) — `ScaleOperation()` traduz para "Operante"/"Não Operante".
- `babyId`/`assignedBaby` — vínculo com bebê.
- `mac` e `pop` — preenchidos a partir da API (necessários ao provisioning BLE).
- `isConnected`, `connectedAt`, `disconnectedAt` — estado de conectividade.
- `wifiStrength` — força do sinal Wi-Fi (dBm).

### 8.3 `WeightModel` — [weight.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/models/weight.dart)

- `id`, `date` (convertido de UTC para hora local via `parseUtcTime`), `scaleId`, `babyId`, `weight` (gramas, `double`).

### 8.4 `LogModel` — [logs.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/models/logs.dart)

- Para auditoria: `entity` (snapshot da entidade), `revision`, `revisionType` (`ADD`/`MOD`/`DEL`), `revisionDate`, `username`.
- Parse especial `fromApiArray` para o formato de resposta da API (array `[entity, revisionInfo, action]`).
- Helpers de UI: `getActionText()` (Criar/Atualizar/Deletar), ícones e nomes por tipo de log.

### 8.5 `User` / `Token` / `Role` — [user.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/models/user.dart)

Estruturas de autenticação/autorição com mapeamento JSON.

### 8.6 Enumerações — [enums.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/models/enums.dart)

- `MenuItens { home, babies, scales, logs }`
- `LogType { scale, baby, weight }`
- `ScanCategory { baby, scale, change_scale }`

### 8.7 Formatação de data — [conversions.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/repository/helper/conversions.dart)

- `parseUtcTime(String)` — anexa `"Z"` e converte para local.
- Formatadores `dateFormatter_dbToObj` (`yyyy-MM-dd`), `dateFormatter_objToDb` (`dd/MM/yyyy`), `dateFormatter_log`, `dateFormatter_HHMM`.
- `imageToUint8List(Image)` — converte `Image` em `Uint8List` (para re-upload de QR).

---

## 9. Fluxos de usuário implementados (detalhamento por módulo)

### 9.1 Autenticação e navegação raiz

- **Login** ([login.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/views/login/login.dart)): tela inicial. Ao logar com sucesso, navega para `MenuManager`.
- **Cadastro** ([cadastro.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/views/login/cadastro.dart)) e **Resetar Senha** ([reset_senha.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/views/login/reset_senha.dart)).

### 9.2 Navegação inferior — [menu.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/repository/widgets/menu.dart)

`MenuManager` exibe AppBar com saudação ("Olá {organization}") e botão **SAIR**, e `NavigationBar` com 4 abas: Home, Bebês, Balanças, Registros. O corpo troca entre as 4 views conforme `currentPageIndex`.

### 9.3 Home (hub de escaneamento) — [home.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/views/home/home.dart)

- **"Escanear Bebês"** — abre diálogo de fonte (foto ou QR). Dependendo da escolha, captura imagem ou escaneia QR, e navega para `BabiesRegister` com o conteúdo capturado.
- **"Escanear Balança"** — escaneia QR e trata o texto/`hash` da balança via `_handleScale()` (fluxo explicado na seção 10).
- **"Trocar de Balança"** — **não implementado** (diálogo "Não implementado / Falta implementar!"). O botão está comentado no código.

### 9.4 Módulo Bebês

- **Lista** ([babies.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/views/babies/babies.dart)): alterna ativos/inativos; mostra "Último peso" quando existir (via `FutureBuilder` sobre `baby.getWeights()`). FAB adiciona bebê.
- **Detalhes** ([babies_details.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/views/babies/babies_details.dart)): dados demográficos, QR, idade calculada, resumo clínico (último peso, variação, total e primeira medição), gráfico de evolução e detalhes de seleção. Botão "Inativar/Ativar Bebê" é **desabilitado quando o bebê está vinculado a uma balança** (`scaleId != null`) — regra de negócio de integridade.
- **Registro** ([babies_register.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/views/babies/babies_register.dart)): formulário de cadastro; salva bebê e, quando a identidade veio como imagem (não texto), faz upload do QR como PNG.
- **Edição** ([babies_edit.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/views/babies/babies_edit.dart)): formulário de edição com recriação do QR (imagem ou texto).

**Gerenciador de horários de coleta:** componente `ElementsOfViews.ShowTimeManager` (ver seção 12) controla os horários de pesagem do bebê (máx. 10, separados por `$`), com seletor de hora (formato 24h) e ajuste de fuso GMT-3.

### 9.5 Módulo Balanças

- **Lista** ([scales.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/views/scales/scales.dart)): alterna ativas/inativas; card mostra estado operacional e conectividade (Online/Offline). FAB adiciona balança por QR (mesmo fluxo da Home).
- **Detalhes** ([scales_details.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/views/scales/scales_details.dart)): maior tela funcional. Ver seção 10.3.

### 9.6 Módulo Registros (auditoria)

- **Entrada** ([logs.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/views/logs/logs.dart)): três caminhos — Histórico de Bebês, Balanças e Peso.
- **Seleção de item** ([logs_itens.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/views/logs/logs_itens.dart)): lista entidades de um tipo.
- **Lista de revisões** ([logs_list.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/views/logs/logs_list.dart)): lista revisões de uma entidade.
- **Detalhe** ([log_details.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/views/logs/log_details.dart)): interpreta o `entity` como bebê/balança/peso (provas de desserialização) e exibe os campos.

---

## 10. Fluxo da balança: QR, provisionamento BLE e operações remotas

### 10.1 Onboarding da balança (escanear → provisionar)

Em [home.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/views/home/home.dart#L46-L59) e no FAB de [scales.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/views/scales/scales.dart):

1. Scanner ([qrcode_service.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/repository/services/qrcode_service.dart)) lê o QR; extrai `text` (hash) e opcionalmente `image`.
2. O app consulta `getScaleIdFromHash(hash)` na API para saber se a balança **já existe** no sistema:
   - Se **não existe** (`id == null`): chama `setNewScale(hash)` para **registrar a balança** na API.
3. Se a balança foi recém-criada e ainda **não está conectada**, abre `BluefiService(hash)` para o **provisionamento Wi-Fi via BLE**.

### 10.2 Provisionamento Wi-Fi via BLE — [bluefi_service.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/repository/services/bluefi_service.dart)

Fluxo detalhado:

1. Busca `mac` e `pop` da API pelo hash (`getScaleDataFromHash`).
2. Solicita permissões por plataforma:
   - **Android 12+ (SDK ≥ 31):** `location`, `bluetoothScan`, `bluetoothConnect`, `bluetoothAdvertise`.
   - **Android ≤ 11:** `location`, `bluetooth`.
   - **iOS:** `bluetooth`, `locationWhenInUse`.
3. Verifica se o Bluetooth está ligado (via canal nativo `BluetoothHelper`).
4. Usuário informa SSID/senha do Wi-Fi.
5. Escaneia dispositivos BLE com **prefixo `PW_`** (`scanBleDevices("PW_")`).
6. Envia credenciais com `provisionWifi(deviceName, pop, ssid, password)`.

**Integração nativa de Bluetooth:**
- O app usa `MethodChannel('bluetooth_helper')` (checagem pontual) e `EventChannel('bluetooth_helper_state')` (monitora ligar/desligar do BT).
- Implementação **Android** em [MainActivity.kt](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/android/app/src/main/kotlin/com/example/untitled/MainActivity.kt) (usa `BluetoothAdapter` + `BroadcastReceiver`).
- Implementação **iOS** em [AppDelegate.swift](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/ios/Runner/AppDelegate.swift) (usa `CBCentralManager`).

> **Nota de fidelidade:** após o sucesso do provisionamento, o app **não atualiza por conta própria** o status de conectividade na API por este caminho; o estado `isConnected` é administrado nas telas de detalhes da balança (leitura de força de sinal e troca de Wi-Fi) e via chamadas a `updateScaleConnectivity` do provider.

### 10.3 Tela de detalhes da balança — [scales_details.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/views/scales/scales_details.dart)

É a tela com o maior número de operações remotas. Estados internos:

- `_isScaleOnline` = balança ativa **e** `isConnected`.
- `_canReceiveMqttCommands` = `_isScaleOnline && _scaleActive`.

Bloco **sem bebê** (`_withoutBaby`):
- "Ativar/Inativar Balança" — `enableOrDisableScale`.
- "Associar Balança a um Bebê" — abre `ScaleBabies` para escolher bebê disponível.

Bloco **detalhes** (`_showScaleDetails`): exibe hash e estado operacional.

Bloco **comandos** (`_showScaleCommands`):
- **Força de sinal Wi-Fi** — na carga (`_loadData`), se `isConnected`, chama `requestWifiStrength` para atualizar o cache (e, em falha, marca a balança offline via `updateScaleConnectivity`).
- **"Medir Peso Agora"** (`_measureWeightNow`): executa `requestWeightNow`, exibe o valor retornado numa caixa "Peso Medido", e **permite salvar o peso no banco** (`WeightApi.saveWeight`) **somente se houver bebê associado**.
- **"Realizar Tara"** (`_tareScale`): chama `requestTare`.
- **"Trocar Wi-Fi via BLE"** (`_changeWifi`): solicita troca de Wi-Fi (`requestChangeWifi`), marca a balança offline e reabre o provisioning `BluefiService`.
- **"Conectar ao Wi-Fi via BLE"** (`_connectToWifiUsingBle`): abre `BluefiService` para (re)conexão.

Bloco **bebê associado** (`_showBabyDetails`): mostra QR, nome, mãe e nascimento do bebê, com botão "Trocar Bebê de Balança" (desassocia via `setOrUnsetBaby` sem código de bebê).

### 10.4 Escolha de bebê/balança — [scales_babies.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/views/scales/scales_babies.dart)

Tela genérica reutilizada nos dois sentidos (recebe `scale` ou `baby`):

- Se recebeu `baby` → lista **balanças ativas sem bebê** para associar.
- Se recebeu `scale` → lista **bebês ativos disponíveis** (sem balança) para associar.

Retorna o item selecionado via `Navigator.pop`, e a tela de origem efetua a associação.

### 10.5 Endpoints usados pelo app (relevantes para a dissertação)

Constantes em [constants.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/repository/helper/constants.dart#L34-L70):

- **Bebês:** `babies/list`, `babies/search/{code}`, `babies/save`, `babies/qr/{code}`, `babies/image/{code}`, `babies/enable/{code}`, `babies/disable/{code}`, `babies/update/{code}`.
- **Balanças:** `scales/list`, `scales/search/{code}`, `scales/hash/{hash}`, `scales/set/{hash}`, `scales/enable/{code}`, `scales/disable/{code}`, `scales/baby/set`, `scales/baby/unset`, `scales/measure_now/{code}`, `scales/tare/{code}`, `scales/change_wifi/{code}`, `scales/wifi_strength/{code}`.
- **Registro de dispositivo / provisioning:** `scale_data/search/{hash}`, `scale_data/qr/{hash}`.
- **Auth:** `login`, `reset_password`, `users/new`, `users/list`.
- **Peso:** `weight/list`, `weight/babies/{code}`, `weight/scales/{code}`, `weight/save`.
- **Auditoria:** `audit/babies/{code}`, `audit/scales/{code}`, `audit/weights/{code}`.

---

## 11. Permissões e segurança

### 11.1 Android — [AndroidManifest.xml](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/android/app/src/main/AndroidManifest.xml)

- Feature obrigatória: `android.hardware.bluetooth_le`.
- Permissões: `INTERNET`, `ACCESS_NETWORK_STATE`; Bluetooth clássico (`BLUETOOTH`/`BLUETOOTH_ADMIN`) até SDK 30; Bluetooth moderno (`BLUETOOTH_SCAN`, `BLUETOOTH_ADVERTISE`, `BLUETOOTH_CONNECT`); localização (`ACCESS_FINE/COARSE/BACKGROUND_LOCATION`).
- Permissões de runtime são solicitadas pela tela de provisioning (seção 10.2).

### 11.2 iOS — [Info.plist](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/ios/Runner/Info.plist)

- Strings de uso: câmera (QR), fotos (QR da biblioteca), Bluetooth (always/peripheral), localização (when-in-use / always-and-when-in-use), rede local.
- `NSBonjourServices` com `mqtt.tcp`.

### 11.3 Quadro de segurança atual (fiel ao código)

- **Token em memória somente** — não há secure storage nem refresh automático.
- API em produção via **HTTPS** (`https://pw-api.velarsoluti.vps-kinghost.net`).
- Em modo debug, o app aceita um **certificado de VPS específico** (`badCertificateCallback`), restrito a um IP fixo.
- **Não há certificate pinning** além do caso de debug acima, nem armazenamento seguro de credenciais de usuário.
- O **PoP** do provisioning BLE é obtido da API e usado em memória apenas durante a sessão.

> **Implicação acadêmica:** como o app lida com dados de pacientes (RN), a dissertação deve apontar a **recomendação de hardening de segurança** (secure storage do token, refresh token, pinning, HTTPS consistente) como trabalho futuro — não como algo já implementado nesta base.

---

## 12. Design system e UI

### 12.1 Tema — [theme.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/repository/design/theme.dart)

`PreciousWeightTheme` define `ColorScheme` e `ThemeData` para os modos **light** e **dark**:

- Light: `primary` preto, `surface` branco, `onPrimary` azul, `onSecondary` laranja forte.
- Dark: derivado do light (inverte `primary`/`surface`).

### 12.2 Cores — [colors.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/repository/design/colors.dart)

Paleta custom: `strongOrange`, `medium_orange`, `light_orange`, `blue`, `green`, `red`, `black`, `light_gray`, `gray`, `white`.

### 12.3 Tipografia — [fonts.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/repository/design/fonts.dart)

Famílias via `google_fonts`: Amaranth, Baloo 2, Roboto Flex, Noto Sans KR, Caprasimo. TextStyles do Material App para escalas (body, title, display, headline).

### 12.4 Estilos e decoração — [button_styles.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/repository/design/button_styles.dart)

`MyButtonStyles` (estilo de logout) e `MyDecorations` (`GetInputDecoration`, `GetBoxDecoration` — borda arredondada padrão dos cards).

### 12.5 Kit de widgets — [elements.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/repository/widgets/elements.dart)

`ElementsOfViews` reúne componentes reutilizáveis:

- `ScanButton` / `ScanButtonNoImage` — grandes botões da Home/Logs.
- Diálogos: `showSimpleDialog`, `showApiAnswerDialog`, `showConfirmDialog`, `showWeightResultDialog` (exibição do peso medido com botão opcional "Salvar peso no BD").
- `MenuAppBar`, `SimpleAppBar`.
- `InputWithController` (com suporte a senha com toggle de visibilidade), `DateInput` (máscara automática dd/mm/yyyy), `ShowTimeManager` (gerenciador de horários de coleta com picker GMT-3, máx. 10).
- `SimpleButton`, `IconContrastButton`, `PwIconButton`, `CardToList`, `CardToText`, `ResponsiveCard`, `GroupChildrenInRow/Column`, `NormalInputText`.

### 12.6 Gráfico de evolução ponderal — [baby_weight_chart.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/repository/widgets/baby_weight_chart.dart)

Componente robusto para visualizar o histórico de pesos do bebê:

- **Modo gráfico**: linha por dia usando a **mediana** dos pesos do dia (ignora taras `weight == 0` na mediana, mas as contabiliza); eixos adaptativos; seleção de dia ao tocar; `InteractiveViewer` para zoom/pan (constrained false, com dimensões explícitas).
- **Modo lista**: medições individuais ordenáveis (asc/desc), destacando **taras** com ícone próprio.
- **Seletor de mês** (anterior/próximo) e navegação entre modos.
- Expõe callbacks `onDaySelected`/`onWeightSelected` para o estado pai exibir os detalhes (conforme convenção de engenharia do projeto).

---

## 13. Testes

Existem 2 arquivos de teste em [test/](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/test/):

- [baby_provider_test.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/test/baby_provider_test.dart): testa o `BabyProvider` com `FakeBabyApi`/`FakeScaleApi`/`TestBabyModel` — carregamento e enriquecimento, cadastro, validação de payload, ativação/inativação, e render de `ScaleBabies`/`BabiesPage`.
- [baby_weight_chart_test.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/test/baby_weight_chart_test.dart): teste de agrupamento por mês, navegação entre meses, `InteractiveViewer` e render em scroll vertical sem exceções (`takeException() == null`).

---

## 14. Pontos de atenção e limitações (fiel ao código)

1. **Sem comunicação MQTT direta do app** — o app depende da API para todo dado vindo da balança (peso, status, RSSI). Isso adiciona latência e um ponto único de falha (a API) entre app e dispositivo.
2. **Credenciais de fallback e strings hardcoded no login** — credenciais admin padrão embutidas em `user_api.dart` (artefato de desenvolvimento; não adequado a produção).
3. **"Trocar de Balança" não implementada** — o fluxo de re-associação manual de balança não existe (mantido comentado na Home).
4. **Token/sessão só em memória** — sem persistência segura; logout em 401 é o único tratamento de sessão expirada.
5. **Cache em memória dos providers** — após kill do app, reler da API; possível inconsistência se a API mudar.
6. **Status de conectividade é assíncrono e heurístico** — `isConnected` é derivado de leitura de força de sinal/troca de Wi-Fi na tela de detalhes, não de um canal push assíncrono de MQTT dentro do app.
7. **Fuso GMT-3 no gerenciador de horários** — o picker aplica subtração de 3h; adequado ao contexto de fuso do ambiente, mas fixo no código.
8. **Certificado custom apenas em debug** — o aceite de self-signed/CAs específicas está limitado à constante `kDebugMode` local (não em `flutter define`).
9. **Upload de QR como PNG** — foto/QR do bebê é enviada como imagem; identidade por texto e por imagem são mutuamente exclusivas no modelo (`hasQrCode`).

---

## 15. Nota de fidelidade para a geração de texto (NotebookLM)

Ao usar este material, **não inferir capacidades ausentes do código**. Em particular:

- **NÃO afirmar** que o app se conecta diretamente ao broker MQTT — todo dado de peso/status vem via API HTTP.
- **NÃO afirmar** que a associação de bebê↔balança exibe dados em tempo real via push — as atualizações dependem de nova carga/navegação ou de requisições explícitas.
- **NÃO afirmar** que "Trocar de Balança" remoto da Home existe — está marcado como não implementado.
- **NÃO afirmar** que o app persiste token ou usa refresh token — o modelo é memória-somente.
- A descrição de precisão e do pipeline HX711 (filtragem, célula de carga etc.) **pertence ao firmware**, não a este documento; não replicar aqui afirmações de precisão < 5 g como se fossem responsabilidade do app.
- Tratar como **trabalho futuro** (não implementado): secure storage de sessão, refresh token, pinning de certificado, push/realtime de peso, provisão dinâmica de múltiplas balanças.

---

## 16. Referência rápida de arquivos de código (mapa do app)

| Camada / função | Arquivo |
|-----------------|---------|
| Entrada / providers | [main.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/main.dart) |
| Navegação inferior + sair | [menu.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/repository/widgets/menu.dart) |
| Estado bebês | [baby_provider.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/repository/providers/baby_provider.dart) |
| Estado balanças | [scales_provider.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/repository/providers/scales_provider.dart) |
| HTTP + erros | [api_service.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/repository/services/api_service.dart) |
| Tratamento 401/expirado | [api_error_handler.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/repository/helper/api_error_handler.dart) |
| QR scanner | [qrcode_service.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/repository/services/qrcode_service.dart) |
| Provisionamento BLE | [bluefi_service.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/repository/services/bluefi_service.dart) |
| Home (hub de escaneamento) | [home.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/views/home/home.dart) |
| Detalhes balança (operações remotas) | [scales_details.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/views/scales/scales_details.dart) |
| Associação bebê↔balança | [scales_babies.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/views/scales/scales_babies.dart) |
| Detalhes bebê (gráfico) | [babies_details.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/views/babies/babies_details.dart) |
| Gráfico evolução | [baby_weight_chart.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/repository/widgets/baby_weight_chart.dart) |
| Kit de UI | [elements.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/repository/widgets/elements.dart) |
| Constantes/endpoints/base | [constants.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/repository/helper/constants.dart) |
| Modelos (bebê/balança/peso/log/usuário) | [lib/models/](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/models/) |
| Clients de API | [lib/api/](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/lib/api/) |
| Bluetooth nativo (Android/iOS) | [MainActivity.kt](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/android/app/src/main/kotlin/com/example/untitled/MainActivity.kt) · [AppDelegate.swift](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/ios/Runner/AppDelegate.swift) |
| Permissões (Android/iOS) | [AndroidManifest.xml](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/android/app/src/main/AndroidManifest.xml) · [Info.plist](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/ios/Runner/Info.plist) |
| Testes | [test/baby_provider_test.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/test/baby_provider_test.dart) · [test/baby_weight_chart_test.dart](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/App_Flutter/test/baby_weight_chart_test.dart) |