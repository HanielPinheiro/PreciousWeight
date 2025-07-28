idf_component_register(
    SRCS "bios.c"  "config_system.c" "sdcard_task""mqtt_task.c" "sensors_task.c"
    INCLUDE_DIRS "."
    REQUIRES hx711 sdcard wifi_prov_ble mqtt
)