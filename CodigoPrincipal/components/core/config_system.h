#pragma once
#ifndef CONFIG_SYSTEM_H
#define CONFIG_SYSTEM_H

#include "esp_system.h"
#include "sdcard.h"
#include "mqtt3.h"
#include "sdcard_task.h"

#define MAX_WEIGHT_TIMES 10
#define RECEIVED_BABY "[Baby]"
#define RECEIVED_WEIGHTS "[Weights]"
#define RECEIVED_RUN "[Run]"
#define RECEIVED_CLEAR "[Clear]"
#define RECEIVED_MEASURE "[Measure]"
#define RECEIVED_CALIBRATE "[Calibrate]"

typedef struct
{
    uint8_t hora;
    uint8_t minuto;
} horario_pesagem_t;

typedef struct
{
    const char *prefix;
    esp_err_t (*handler)(const char *data);
    const char *success_msg;
    const char *error_msg;
    const char *log_success;
    char *log_error;
} CommandHandler;

extern uint8_t number_times;
extern horario_pesagem_t weight_times[MAX_WEIGHT_TIMES];
extern char baby_id[12];
extern bool has_baby;

void process_mqtt_data(const char *mqtt_data);
char *get_reset_reason_string(esp_reset_reason_t reason);
bool should_measure_weight_now();
#endif // CONFIG_SYSTEM_H