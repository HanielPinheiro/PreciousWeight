# For more information about build system see
# https://docs.espressif.com/projects/esp-idf/en/latest/api-guides/build-system.html
# The following five lines of boilerplate have to be in your project's
# CMakeLists in this exact order for cmake to work correctly
cmake_minimum_required(VERSION 3.5)
# set(EXTRA_COMPONENT_DIRS "${CMAKE_CURRENT_SOURCE_DIR}/components")
set(EXTRA_COMPONENT_DIRS 
    "${CMAKE_CURRENT_SOURCE_DIR}/components/models/babies"
    "${CMAKE_CURRENT_SOURCE_DIR}/components/models/weights"

    "${CMAKE_CURRENT_SOURCE_DIR}/components/drivers/buzzer"
    "${CMAKE_CURRENT_SOURCE_DIR}/components/drivers/hx711"
    "${CMAKE_CURRENT_SOURCE_DIR}/components/drivers/sdcard"
    "${CMAKE_CURRENT_SOURCE_DIR}/components/drivers/sdcard_v2"

    "${CMAKE_CURRENT_SOURCE_DIR}/components/core/system_manager"

    "${CMAKE_CURRENT_SOURCE_DIR}/components"
)
include($ENV{IDF_PATH}/tools/cmake/project.cmake)
project(CodigoPrincipal)