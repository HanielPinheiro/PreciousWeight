# Rerun Scripts

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
-- Execute only if these columns and table do not exist yet.
```
