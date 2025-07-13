idf_component_register(
    SRCS "system_manager.c"
    INCLUDE_DIRS "."
    REQUIRES freertos buzzer hx711 sdcard
)