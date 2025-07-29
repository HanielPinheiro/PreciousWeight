#pragma once
#ifndef SDCARD_H
#define SDCARD_H

#include "stdio.h"
#include "sdmmc_cmd.h"
#include "esp_vfs_fat.h"
#include "sys/unistd.h"
#include "sys/stat.h"
#include "string.h"
#include "errno.h"
#include "config_system.h"
#include "sdcard_task.h"

#define MODO_DEBUG true
#define MORE_LOGS false
#define MAX_LOG_LENGTH 160

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

esp_err_t sdcard_init(void);
esp_err_t sdcard_write_file(char *path, char *data);
esp_err_t sdcard_create_file(char *path);
esp_err_t sdcard_log(log_type_t log_type, char *message, const char *trace);
void sdcard_notify_uart(const char *stack_trace, char *message);

esp_err_t sdcard_load_weight_times();
void sdcard_clear_file(const char *filename);

#endif // SDCARD_H