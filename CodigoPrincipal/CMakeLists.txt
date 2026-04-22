cmake_minimum_required(VERSION 3.5)

set(EXTRA_COMPONENT_DIRS 
    # "$ENV{IDF_PATH}/mqtt/esp-mqtt"

    "${CMAKE_CURRENT_SOURCE_DIR}/config"

    # "${CMAKE_CURRENT_SOURCE_DIR}/comm"
    "${CMAKE_CURRENT_SOURCE_DIR}/comm/mqtt_config"
    "${CMAKE_CURRENT_SOURCE_DIR}/comm/wifi_prov_ble"

    # "${CMAKE_CURRENT_SOURCE_DIR}/drivers"
    "${CMAKE_CURRENT_SOURCE_DIR}/drivers/hx711"
    "${CMAKE_CURRENT_SOURCE_DIR}/drivers/sdcard"

    # "${CMAKE_CURRENT_SOURCE_DIR}/mqtt_events"    
    "${CMAKE_CURRENT_SOURCE_DIR}/mqtt_events/parser"    
    "${CMAKE_CURRENT_SOURCE_DIR}/mqtt_events/scheduler"    

    # "${CMAKE_CURRENT_SOURCE_DIR}/tasks"  
    "${CMAKE_CURRENT_SOURCE_DIR}/tasks/mqtt_task"    
    "${CMAKE_CURRENT_SOURCE_DIR}/tasks/sdcard_task"    
    "${CMAKE_CURRENT_SOURCE_DIR}/tasks/sensors_task"    
)

include($ENV{IDF_PATH}/tools/cmake/project.cmake)
idf_build_set_property(MINIMAL_BUILD ON)
project(PreciousWeightFirmware)
