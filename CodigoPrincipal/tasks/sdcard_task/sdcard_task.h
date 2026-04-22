#pragma once
#ifndef SDCARD_TASK_H
#define SDCARD_TASK_H

#include "../../main/main.h"

extern QueueHandle_t sdcard_log_queue;
esp_err_t init_sdcard_task();

#endif // SDCARD_TASK_H