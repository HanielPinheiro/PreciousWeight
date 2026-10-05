# Autenticação, Autorização e Segurança

> Documento técnico para a dissertação. Descreve como o backend autentica usuários (JWT assinado com RSA), controla acesso por papéis (`@PreAuthorize`) e protege as rotas, conforme o código-fonte real (`SecurityConfig`, `LoginController`, `UserController`, `AdminUserConfig`).

## 1. Visão Geral

- **Autenticação**: JWT (JSON Web Token) **assimétrico RSA (RS256)**, emitido pelo próprio backend.
- **Autorização**: Spring Method Security com `@PreAuthorize` sobre os controllers.
- **Senhas**: hasheadas com **BCrypt**.
- **Sessão**: stateless (`SessionCreationPolicy.STATELESS`).

## 2. Configuração de Segurança (`SecurityConfig`)

Classe `config/auth/SecurityConfig` com anotações `@EnableWebSecurity` e `@EnableMethodSecurity(prePostEnabled = true)`. Os beans:

| Bean | Descrição |
|------|-----------|
| `SecurityFilterChain` | Cadeia de filtros HTTP |
| `JwtDecoder` | `NimbusJwtDecoder.withPublicKey(publicKey)` |
| `JwtEncoder` | `NimbusJwtEncoder` a partir do par RSA (JWKSet) |
| `BCryptPasswordEncoder` | Encoder de senhas BCrypt (strength padrão) |

### Cadeia de filtros (`securityFilterChain`)

```java
http
    .authorizeHttpRequests(auth -> auth.anyRequest().permitAll())          // TODAS as rotas permitidas
    .csrf(csrf -> csrf.disable())                                          // CSRF desabilitado (teste/prod via JWT)
    .oauth2ResourceServer(oauth2 -> oauth2.jwt(Customizer.withDefaults())) // Valida JWT Bearer
    .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS));
```

**Interpretação**: como o filtro global está como `permitAll()`, a autorização efetiva é feita **por endpoint** via `@PreAuthorize`. O `oauth2ResourceServer...jwt` é o que valida o token quando o cabeçalho `Authorization: Bearer` está presente. Isso significa que rotas protegidas por `@PreAuthorize("isAuthenticated()")` dependem do JWT.

### Chaves (RSA)

- `jwt.public.key = classpath:app.pub` → chave pública (validação do token).
- `jwt.private.key = classpath:app.key` → chave privada (emissão do token).
- Arquivos localizados em `src/main/resources/app.pub` e `app.key`.

## 3. Fluxo de Login (`LoginController`)

Endpoint `POST /login` (público):

1. Recebe `LoginRequest` (`email`, `password`).
2. Busca usuário por email (`iUser.findByEmail`).
3. Se não existe **ou** senha incorreta (`isLoginCorrect` + BCrypt `matches`) → HTTP 400.
4. Monta os claims JWT:
   - `issuer` = `precious_weight_backend` (constante `LoginController_BackEndName`)
   - `subject` = `user_id` (UUID)
   - `issuedAt` / `expiresAt` = expiração em **3000 segundos (~50 minutos)**
   - `scope` = nomes dos papéis concatenados com espaço (ex.: `"ADMIN BASIC"`)
5. Codifica o token com `JwtEncoder` (RS256).
6. Retorna `LoginResponse` com `accessToken`, `expiresIn` (3000) e `user` (`UserModel`).

> Devido à presença do claim `scope`, o Spring Security OAuth2 converte cada papel em authority `SCOPE_<ROLE>` (ex.: `SCOPE_ADMIN`, `SCOPE_BASIC`). É por isso que os `@PreAuthorize` usam `hasAuthority('SCOPE_ADMIN')`.

### Reset de senha

Endpoint `POST /login/reset_password` (público):
1. Busca usuário por email; se não existir → HTTP 400.
2. Codifica a nova senha com BCrypt e salva.

## 4. Usuários e Papéis

### Criação de usuário (`POST /users/new`, público)

1. Obtém o papel `BASIC` (`iRole.findByName(RoleModel.Values.BASIC.name())`).
2. Se o email já existir → HTTP 400.
3. Cria `UserModel` com senha BCrypt e papel `BASIC` (todo novo usuário nasce como papel básico).

### Listagem (`POST /users/list`)

Requer `hasAuthority('SCOPE_ADMIN')`. Retorna todos os `UserModel`.

### Papéis (roles)

- `ADMIN` (id 1), `BASIC` (id 2) — enum `RoleModel.Values`.
- Relação usuário-papel: `@ManyToMany` com `fetch = EAGER` via tabela `user_roles_rel`.

## 5. Usuário Admin Inicial (`AdminUserConfig`)

Classe `config/auth/AdminUserConfig` — `CommandLineRunner` (`@DependsOn("authEntityManagerFactory")`), executa no primeiro boot (transacional):

1. Se o papel `ADMIN` não existir, cria `ADMIN` e `BASIC`.
2. Se não existir usuário com email `admin@precious_weight.com`, cria:
   - email: `admin@precious_weight.com`
   - senha: `M1U1tr4H4rdPa550w0rd!` (BCrypt)
   - organização: `Precious Weight`
   - papéis: `ADMIN`

> **Atenção:** a senha do admin está fixa no código (orientação de "teste"). Em produção deve ser alterada/generificada. Documentado aqui apenas de forma técnica.

## 6. Resumo de Controle de Acesso por Controller

| Controller | Rota de acesso |
|------------|----------------|
| `BabyController`, `WeightController`, `ScaleController`, `AuditController` | `isAuthenticated()` |
| `ScaleDataController.search` e `ScaleDataController.qr` | `isAuthenticated()` |
| `ScaleDataController.list/new/update` | `hasAuthority('SCOPE_ADMIN')` |
| `UserController.new` | público |
| `UserController.list` | `hasAuthority('SCOPE_ADMIN')` |
| `LoginController`/login e reset | público |

## 7. Decisões e Recomendações (descritivas)

- O uso de **um único par de chaves RSA** para emissão e validação é simples e adequado a um monolito, porém conflitos de escalabilidade em microsserviços normalmente exigem um servidor de autorização separado (ex.: **Keycloak**, alternativa open-source não-americana) — fica como recomendação de evolução, sem alteração de código.
- O `anyRequest().permitAll()` combinado com `@PreAuthorize` é funcional, mas a validação final do JWT depende apenas da presença do cabeçalho Bearer. Para maior robustez, recomenda-se definir explicitamente as rotas públicas e autenticadas na cadeia de filtros.
- O CSRF está desabilitado, o que é adequado para APIs stateless com Bearer token.
- O `expiresIn` fixo de 3000s (~50 min) não possui refresh token no código atual.

## 8. Referências

- Segurança em projeto: `config/auth/SecurityConfig.java`, `config/auth/AdminUserConfig.java`.
- Login/reset: `controllers/auth/LoginController.java`.
- Usuário: `controllers/auth/UserController.java`.
- Papéis: `auth/models/RoleModel.java`.
- Usuário: `auth/models/UserModel.java`.