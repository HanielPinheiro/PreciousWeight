idf_component_register(
    SRCS "bios.c" "tasks.c"
    INCLUDE_DIRS "."
    REQUIRES hx711 sdcard wifi_prov_ble mqtt
)