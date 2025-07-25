#pragma once

#include "mqtt3.h"
#include "sdcard.h"
#include "hx711.h"

// Tipos de dados
typedef struct
{
    uint8_t sensor_id;
    int32_t raw;
    float weight;
} sensor_data_t;

// Prioridades das tasks
typedef enum
{
    TASK_PRIORITY_LOW = 1,
    TASK_PRIORITY_MEDIUM = 2,
    TASK_PRIORITY_HIGH = 3,
    TASK_PRIORITY_CRITICAL = 4
} task_priority_t;

// Protótipos de funções
esp_err_t tasks_init(hx711_t *sensores, uint8_t num_sensores);
bool send_sensor_data_to_queue(const sensor_data_t *data);
bool receive_sensor_data_from_queue(sensor_data_t *data, TickType_t timeout);