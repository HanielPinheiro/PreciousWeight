#pragma once
#ifndef SENSORS_TASK_H
#define SENSORS_TASK_H

#include "../../config/include/setup.h"

typedef struct
{
    int32_t raw_value;
    int32_t units;
    int32_t weight;
    uint8_t sensor_id;
} sensor_data_t;

esp_err_t init_sensors_task();
#endif // SENSORS_TASK_H