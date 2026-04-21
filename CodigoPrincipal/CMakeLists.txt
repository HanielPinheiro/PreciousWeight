cmake_minimum_required(VERSION 3.5)

set(EXTRA_COMPONENT_DIRS 
    "$ENV{IDF_PATH}/mqtt/esp-mqtt"
    
    "${CMAKE_CURRENT_SOURCE_DIR}/comm"
    
    "${CMAKE_CURRENT_SOURCE_DIR}/components/drivers/hx711"
    "${CMAKE_CURRENT_SOURCE_DIR}/components/drivers/sdcard"
    "${CMAKE_CURRENT_SOURCE_DIR}/components/core"
)

include($ENV{IDF_PATH}/tools/cmake/project.cmake)
idf_build_set_property(MINIMAL_BUILD ON)
project(PreciousWeightFirmware)
