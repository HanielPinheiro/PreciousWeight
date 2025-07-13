#pragma once

#include "stdio.h"
#include "driver/sdmmc_host.h"
#include "driver/sdspi_host.h"
#include "sdmmc_cmd.h"
#include "esp_vfs_fat.h"
#include "esp_sleep.h"
#include "esp_err.h"

// Configuration
#define MOUNT_POINT "/sdcard"
#define LOG_FILE MOUNT_POINT "/log.txt"

#define ALLOC_UNIT_SIZE 4096 // 4KB clusters (optimized for small files)

#define LINES 250 // Buffer logs in RAM before writing
#define MAX_LOG_LENGTH 256
#define EXAMPLE_MAX_CHAR_SIZE 64

// Power-optimized functions
esp_err_t sdcard_init(void);
esp_err_t sdcard_format(void);
void sdcard_close(void);

int sdcard_check_file_exists(char *path);
esp_err_t sdcard_rename_file(char *actual_name, char *new_name);

esp_err_t sdcard_create_file(char *path);
esp_err_t sdcard_read_file(char *path);
esp_err_t sdcard_write_file(char *path, char *data);
esp_err_t sdcard_delete_file(char *path);

// esp_err_t sdcard_log(const char *tag, const char *message, bool flush_immediately);
// esp_err_t sdcard_flush(void); // Manual flush for critical data
// void sdcard_cleanup(bool power_down_spi);