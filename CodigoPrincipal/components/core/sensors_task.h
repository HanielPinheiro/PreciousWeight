#pragma once
#ifndef SENSORS_TASK_H
#define SENSORS_TASK_H

#include "config_system.h"
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

// Protótipos de funções
esp_err_t init_sensors_task(hx711_t *sensores, uint8_t num_sensores);
#endif // SENSORS_TASK_H