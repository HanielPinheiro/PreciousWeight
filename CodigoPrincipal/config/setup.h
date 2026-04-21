#pragma once
#ifndef SETUP_H
// Prioridades das tasks
typedef enum
{
    TASK_PRIORITY_LOW = 1,
    TASK_PRIORITY_MEDIUM = 2,
    TASK_PRIORITY_HIGH = 3,
    TASK_PRIORITY_CRITICAL = 4
} task_priority_t;

typedef enum
{
    LOG_INFO = 0,
    LOG_WARN = 1,
    LOG_ERROR = 2
} log_type_t;

#define WIFI_DEVICE_NAME "PW_D0EF76590B7C"
#define MQTT_SERVICE_NAME "D0EF76590B7C"
#define MQTT_POP "KwS2@y6G"
#define MODO_DEBUG true

#define LED_GPIO GPIO_NUM_2

#endif // COMM_LIBS_H