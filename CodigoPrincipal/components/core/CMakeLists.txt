idf_component_register(
    SRCS "bios.c" "tasks.c"
    INCLUDE_DIRS "."
    REQUIRES freertos buzzer hx711 sdcard wifi_prov_ble mqtt
)