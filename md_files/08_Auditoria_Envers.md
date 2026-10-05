# Auditoria (Hibernate Envers)

> Documento técnico para a dissertação. Descreve a trilha de auditoria do backend, implementada com Hibernate Envers, conforme o código-fonte real (`models/envers`, `AuditController`) e a configuração de `application.properties`.

## 1. Motivação

Em um sistema de pesagem neonatal, o histórico de alterações é importante para rastreabilidade: saber **quem** alterou **o quê**, **quando** e **de que tipo** (criação, modificação ou exclusão). O backend implementa isso com **Hibernate Envers**.

## 2. Configuração

Em `application.properties`:

```
spring.jpa.properties.org.hibernate.envers.audit_table_suffix = _AUDIT
spring.jpa.properties.org.hibernate.envers.revision_field_name = REV
spring.jpa.properties.org.hibernate.envers.revision_type_field_name = REVTYPE
spring.jpa.show-sql = true
```

- Tabelas de histórico recebem sufixo **`_AUDIT`** (ex.: `weights_AUDIT`).
- Cada linha de histórico tem `REV` (número da revisão) e `REVTYPE` (ADD=0, MOD=1, DEL=2).
- Dependência: `org.hibernate.orm:hibernate-envers:6.4.4.Final`.

## 3. Entidades Auditadas

Todas as entidades da camada `app` são anotadas com `@Audited`:

- `BabyModel`
- `ScaleModel`
- `WeightModel`
- `WifiConnectivityModel`
- `WifiStrengthModel`

### Campo não auditado

`BabyModel.babyImage` é `@NotAudited` (o Blob de imagem/QRCode não entra no histórico).

> As entidades da camada `auth` (`UserModel`, `RoleModel`, `ScaleDataModel`) **não** são `@Audited`.

## 4. Entidade de Revisão Customizada

`CustomRevisionEntity` (em `models/envers`) estende `DefaultRevisionEntity` e adiciona o campo **`username`**, permitindo associar cada revisão ao usuário responsável pela alteração.

O `DefaultRevisionEntity` fornece `id` (número da revisão) e `timestamp`.

> **Observação:** o campo `username` existe na entidade, mas o preenchimento automático depende de um `RevisionListener` que associe o usuário logado; tal listener não está presente no código atual, portanto o preenchimento fica condicionado à implementação/uso existente.

## 5. Repositório de Auditoria — `AuditRepository`

Classe `@Repository` em `models/envers`, usa `AuditReaderFactory.get(entityManager)` para consultar o histórico.

Métodos:

| Método | O que consulta | Filtro |
|--------|----------------|--------|
| `getBabyRevisions(Integer babyId)` | `BabyModel` | ID do bebê |
| `getScaleRevisions(Integer scaleId)` | `ScaleModel` | ID da balança |
| `getWeightRevisions(Integer babyId)` | `WeightModel` | propriedade `babyId` (via `AuditEntity.property("babyId").eq(babyId)`) |

Cada consulta retorna uma lista de `Object[]` com 3 posições: `[Entidade, CustomRevisionEntity, RevisionType]`.

## 6. Endpoints de Auditoria

`AuditController` (caminho `/audit`):

| Método | Caminho | Retorno |
|--------|---------|---------|
| POST | `/audit/babies/{babyId}` | `List<Object[]>` — converte `BabyModel` → `BabyResponse` |
| POST | `/audit/scales/{scaleId}` | `List<Object[]>` — converte `ScaleModel` → `ScaleResponse` |
| POST | `/audit/weights/{babyId}` | `List<Object[]>` — retorna `WeightModel` cru |

Todos exigem `isAuthenticated()`.

> Para pesos, o filtro é por `babyId` (campo da entidade), pois `WeightModel` não possui o `babyId` como chave primária — por isso é usada a API programática de Envers (`AuditEntity.property`).

## 7. Exemplo conceitual de revisão

Uma modificação no registro de uma balança gera, na tabela `scales_AUDIT`:
- `scale_id` (chave);
- valores das colunas após a alteração;
- `REV` (número da revisão) e `REVTYPE` (ex.: `2` para modificação);
- associação com `CustomRevisionEntity` que guarda `id`, `timestamp` e `username`.

## 8. Considerações de Projeto (descritivas)

- Envers **não registra o campo** de imagem (`@NotAudited`), reduzindo volume de dados binários no histórico.
- A consulta de histórico de peso é por bebê (não por pesagem), alinhada ao interesse clínico de acompanhar a evolução de peso do recém-nascido.