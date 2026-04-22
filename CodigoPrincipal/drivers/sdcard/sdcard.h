#pragma once
#ifndef SDCARD_H
#define SDCARD_H

#include "../../main/main.h"

#define MORE_LOGS false
#define MAX_LOG_LENGTH 160

#define SDCARD_MOSI GPIO_NUM_23
#define SDCARD_MISO GPIO_NUM_19
#define SDCARD_CLK GPIO_NUM_18
#define SDCARD_CS GPIO_NUM_5

#define MOUNT_POINT "/sdcard"
#define LOG_FILE MOUNT_POINT "/logs.txt"
#define WEIGHT_FILE MOUNT_POINT "/weights.txt"
#define BABY_HOURS_FILE MOUNT_POINT "/baby.txt"

typedef struct
{
    char *path;
    char message[MAX_LOG_LENGTH];
} log_entry_t;

typedef enum
{
    LOG_INFO = 0,
    LOG_WARN = 1,
    LOG_ERROR = 2
} log_type_t;

extern sdmmc_card_t *sdcard;

esp_err_t initialize_sdcard(void);
esp_err_t sdcard_write_file(char *path, char *data);
esp_err_t sdcard_create_file(char *path);
esp_err_t sdcard_log(log_type_t log_type, char *message, const char *trace);
void esp_log_at_terminal(const char *stack_trace, char *message);

esp_err_t sdcard_load_weight_times();
void sdcard_clear_file(const char *filename);

#endif // SDCARD_H