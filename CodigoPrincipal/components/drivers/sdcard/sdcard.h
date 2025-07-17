#pragma once

#include "stdio.h"
#include "sdmmc_cmd.h"
#include "esp_vfs_fat.h"
#include "sys/unistd.h"
#include "sys/stat.h"
#include "string.h"

#define MODO_DEBUG true // controla notify_uart
#define MORE_LOGS false // controla write logs Abrindo arquivo ...

// Configuration
#define MOUNT_POINT "/sdcard"
#define LOG_FILE MOUNT_POINT "/logs.txt"
#define WEIGHT_FILE MOUNT_POINT "/weights.txt"

typedef enum
{
    LOG_INFO = 0,
    LOG_WARN = 1,
    LOG_ERROR = 2
} log_type_t;

void sdcard_close(void);
void notify_uart(const char *stack_trace, char *message);
int sdcard_check_file_exists(char *path);

esp_err_t sdcard_init(void);
esp_err_t sdcard_format(void);
esp_err_t sdcard_rename_file(char *actual_name, char *new_name);
esp_err_t sdcard_create_file(char *path);
esp_err_t sdcard_read_file(char *path);
esp_err_t sdcard_write_file(char *path, char *data);
esp_err_t sdcard_delete_file(char *path);
esp_err_t sdcard_log(log_type_t log_type, char *message, const char *trace);