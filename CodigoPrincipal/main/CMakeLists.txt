idf_component_register(
    SRCS "main.c"    
    REQUIRES fatfs freertos esp_wifi nvs_flash wifi_provisioning mqtt esp_driver_gpio mqtt_task sdcard_task sensors_task scheduler parser mqtt_config hx711 sdcard wifi_prov_ble
)
