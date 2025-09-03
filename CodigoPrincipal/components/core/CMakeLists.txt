idf_component_register(
    SRCS "sensors_task.c" "weight_timer_scheduler.c" "process_mqtt_data.c" "sdcard_task.c" "bios.c"  "mqtt_task.c"
    INCLUDE_DIRS "."
    REQUIRES hx711 sdcard wifi_prov_ble mqtt
)