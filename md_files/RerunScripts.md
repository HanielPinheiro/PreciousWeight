# Scripts de Ajuste do Banco (Rerun)

> Scripts SQL auxiliares usados para ajustes pontuais no banco **`app_db`**.
> **Observação:** em geral o schema é criado/atualizado automaticamente pelo Hibernate
> (`hibernate.hbm2ddl.auto = update` em ambos os EntityManagers). Estes scripts servem para
> cenários em que a migração automática não resolveu (ex.: incursão incremental durante o desenvolvimento).

## 1. Adicionar campos de conectividade na tabela `scales`

```sql
USE app_db;

ALTER TABLE scales
    ADD COLUMN scale_last_connected_at DATETIME NULL,
    ADD COLUMN scale_last_disconnected_at DATETIME NULL;
```

## 2. Criar tabela `wifi_strengths`

```sql
USE app_db;

CREATE TABLE wifi_strengths (
    wifi_strength_id INT NOT NULL AUTO_INCREMENT,
    wifi_strength_date DATETIME NOT NULL,
    scale_id INT NOT NULL,
    wifi_strength_value INT NOT NULL,
    PRIMARY KEY (wifi_strength_id)
);
```

## Observação

- Execute apenas se as colunas/tabelas acima ainda **não existirem**.
- Campos relacionados já mapeados pelo código:
  - `scales.scale_last_connected_at` / `scales.scale_last_disconnected_at` (Entity `ScaleModel`).
  - tabela `wifi_strengths` (Entity `WifiStrengthModel`).
- A tabela `wifi_connectivity` (Entity `WifiConnectivityModel`) também faz parte do modelo de dados atual e é criada automaticamente pelo Hibernate em `app_db`.

## Referências

- Modelo de dados completo: `03_Modelo_de_Dados_Bancos.md`