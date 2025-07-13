#pragma once

#include "driver/gpio.h"
#include "freertos/FreeRTOS.h" // ← Needed for vTaskDelay()
#include "freertos/task.h"     // ← Needed for pdMS_TO_TICKS()

#define BUZZER_GPIO GPIO_NUM_21
#define SHORT_TIME 200
#define LONG_TIME 600

void buzzer_init();
void buzzer_short_beep();
void buzzer_long_beep();
void buzzer_short_alert();
void buzzer_long_alert();
