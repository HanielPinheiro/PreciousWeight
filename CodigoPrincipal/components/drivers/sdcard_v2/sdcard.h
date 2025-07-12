#pragma once
#include "stdio.h"
#include "driver/sdmmc_host.h"
#include "driver/sdspi_host.h"
#include "sdmmc_cmd.h"
#include "esp_vfs_fat.h"
#include "esp_sleep.h"

#pragma once
#include "esp_err.h"

#define MOUNT_POINT "/sdcard"
#define MAX_LOG_LENGTH 256

esp_err_t sdcard_init();
esp_err_t sdcard_write_file(const char *path, const char *data);
esp_err_t sdcard_log(const char *tag, const char *message);
void sdcard_deinit();