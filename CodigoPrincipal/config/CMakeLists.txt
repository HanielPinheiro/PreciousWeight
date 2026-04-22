# idf_component_register(
#     REQUIRES fatfs freertos esp_wifi nvs_flash wifi_provisioning freertos esp_wifi nvs_flash mqtt esp_driver_gpio freertos 
#fatfs mqtt_events tasks wifi_prov_ble mqtt_task sdcard_task sensors_task scheduler parser fatfs mqtt_config wifi_prov_ble parser
# )

idf_component_register(
    INCLUDE_DIRS "include"
    REQUIRES fatfs freertos esp_wifi nvs_flash wifi_provisioning mqtt esp_driver_gpio mqtt_task sdcard_task sensors_task scheduler parser mqtt_config hx711 sdcard wifi_prov_ble
)

