idf_component_register(SRCS "wifi_prov_ble.c"
                       REQUIRES esp_wifi nvs_flash wifi_provisioning
                       INCLUDE_DIRS ".")