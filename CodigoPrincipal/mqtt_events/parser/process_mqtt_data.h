#pragma once
#ifndef CONFIG_SYSTEM_H
#define CONFIG_SYSTEM_H

#define DEBOUNCE_COUNT 4
#define MAX_WEIGHT_TIMES 10
#define RECEIVED_RUN "[RUN]"
#define RECEIVED_BABY "[BAB]"
#define RECEIVED_WIFI "[WIF]"
#define RECEIVED_CLEAR "[CLE]"
#define RECEIVED_TIMES "[TIM]"
#define RECEIVED_MEASURE "[MEA]"
#define RECEIVED_CALIBRATE "[CAL]"

typedef struct
{
    uint8_t hour;
    uint8_t minutes;
} weight_time_t;

typedef struct
{
    const char *prefix;
    esp_err_t (*handler)(const char *data);
    const char *log_success;
    char *log_error;
} CommandHandler;

extern uint8_t number_of_weight_times;
extern weight_time_t weight_times[MAX_WEIGHT_TIMES];
extern char baby_id[12];

void process_mqtt_data(const char *mqtt_data);
void update_has_baby_flag(bool state);
bool scale_has_baby();

#endif // CONFIG_SYSTEM_H