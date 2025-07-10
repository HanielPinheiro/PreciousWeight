#pragma once

#include "driver/gpio.h"
#include "freertos/FreeRTOS.h" // ← Needed for vTaskDelay()
#include "freertos/task.h"     // ← Needed for pdMS_TO_TICKS()

void buzzer_fast_beep(void);
void buzzer_slow_beep(void);
