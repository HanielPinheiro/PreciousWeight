#pragma once
#ifndef COMM_LIBS_H
#define COMM_LIBS_H

#include "stdio.h"
#include "stdint.h"
#include "stddef.h"
#include "string.h"

#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/event_groups.h"
#include "freertos/semphr.h"
#include "freertos/queue.h"

#include "esp_log.h"
#include "esp_wifi.h"
#include "esp_mac.h"

#include "nvs_flash.h"

#define MQTT_SERVICE_NAME "PW_D0EF76590B7C"
#define MQTT_POP "KwS2@y6G"

#endif // COMM_LIBS_H