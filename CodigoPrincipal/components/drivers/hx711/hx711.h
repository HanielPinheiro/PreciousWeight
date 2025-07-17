#pragma once

#include "stdint.h"
#include "driver/gpio.h"
#include "freertos/FreeRTOS.h" // ← Needed for vTaskDelay()
#include "freertos/task.h"     // ← Needed for pdMS_TO_TICKS()

#define QTDE_SENSORES 4
#define SCALE1_DOUT GPIO_NUM_13
#define SCALE1_SCK GPIO_NUM_14

#define SCALE2_DOUT GPIO_NUM_16
#define SCALE2_SCK GPIO_NUM_17

#define SCALE3_DOUT GPIO_NUM_32
#define SCALE3_SCK GPIO_NUM_33

#define SCALE4_DOUT GPIO_NUM_25
#define SCALE4_SCK GPIO_NUM_26

typedef enum
{
    HX711_CHANNEL_A_128 = 25,
    HX711_CHANNEL_B_32 = 26,
    HX711_CHANNEL_A_64 = 27
} hx711_mode_t;

typedef struct
{
    gpio_num_t dout_pin;
    gpio_num_t sck_pin;
    int clock_cycles_from_mode;
    int32_t offset;
    float scale;
    uint8_t sensor_id;
} hx711_t;

esp_err_t hx711_init(hx711_t *dev, gpio_num_t dout, gpio_num_t sck, hx711_mode_t mode);
int32_t hx711_read_raw(hx711_t *dev);
float hx711_read_weight(hx711_t *dev);
void hx711_tare(hx711_t *dev, uint8_t samples);
