#pragma once
#include "stdio.h"
#include "driver/sdmmc_host.h"
#include "driver/sdspi_host.h"
#include "sdmmc_cmd.h"
#include "esp_vfs_fat.h"
#include "esp_sleep.h"

// Configuration
#define MOUNT_POINT "/sdcard"
#define LOG_FILE MOUNT_POINT "/log.txt"
#define MAX_LOG_ENTRIES 1000 // Buffer logs in RAM before writing
#define ALLOC_UNIT_SIZE 4096 // 4KB clusters (optimized for small files)

// SD Card Handle (externally accessible)
extern sdmmc_card_t *sdcard;

// Power-optimized functions
esp_err_t sdcard_setup(void);
esp_err_t sdcard_log(const char *message, bool flush_immediately);
esp_err_t sdcard_flush(void); // Manual flush for critical data
void sdcard_cleanup(bool power_down_spi);