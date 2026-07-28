# Rerun Scripts
//Data 23-07-26, comando pra alterar a tabela no Banco de dados manualmente
## App DB

```sql
USE app_db;

ALTER TABLE scales
    ADD COLUMN scale_last_connected_at DATETIME NULL,
    ADD COLUMN scale_last_disconnected_at DATETIME NULL;
```

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

## Observacao

```sql
-- Se as colunas ou a tabela ja existirem, ajuste o script manualmente
-- antes de executar novamente no mesmo banco.
```
