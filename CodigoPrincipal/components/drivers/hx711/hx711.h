#pragma once

#include "../buzzer/buzzer.h"
#include "string.h"
#include "stdio.h"
#include "esp_log.h"
#include "esp_rom_sys.h"

#define HX711_UNDEFINED (0x80000000)

typedef enum
{
    HX711_CHANNEL_A_128 = 25,
    HX711_CHANNEL_B_32 = 26,
    HX711_CHANNEL_A_64 = 27
} hx711_mode_t;

typedef struct
{
    gpio_num_t sck_pin;
    gpio_num_t dout_pin;
    int clock_cycles;
} hx711_t;

esp_err_t hx711_init(hx711_t *dev, gpio_num_t dout, gpio_num_t sck, hx711_mode_t mode);
int32_t hx711_read(hx711_t *dev, TickType_t timeout_ticks);
