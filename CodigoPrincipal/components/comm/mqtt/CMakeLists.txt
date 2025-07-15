idf_component_register(SRCS "mqtt3_mutual_ssl.c"
                        PRIV_REQUIRES mqtt nvs_flash esp_netif esp_wifi esp_partition app_update esp-mqtt
                        INCLUDE_DIRS ".")

target_add_binary_data(${COMPONENT_TARGET} "certs/client.crt" TEXT)
target_add_binary_data(${COMPONENT_TARGET} "certs/client.key" TEXT)
target_add_binary_data(${COMPONENT_TARGET} "certs/ca.crt" TEXT)

