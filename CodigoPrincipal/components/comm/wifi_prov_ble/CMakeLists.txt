idf_component_register(SRCS "wifi_prov_ble.c"
                       PRIV_REQUIRES esp_wifi nvs_flash wifi_provisioning
                       INCLUDE_DIRS ".")