#pragma once
#ifndef HX711_H
#define HX711_H

#include "stdint.h"
#include "driver/gpio.h"
#include "freertos/FreeRTOS.h" // ← Needed for vTaskDelay()
#include "freertos/task.h"     // ← Needed for pdMS_TO_TICKS()
#include "esp_log.h"

#define NUM_WEIGHT_SENSORS 4

#define SCALE1_DOUT GPIO_NUM_21
#define SCALE1_SCK GPIO_NUM_22

#define SCALE2_DOUT GPIO_NUM_16
#define SCALE2_SCK GPIO_NUM_14 // PIN 17 original, 14 na atual pq deu problema na solda

#define SCALE3_DOUT GPIO_NUM_32
#define SCALE3_SCK GPIO_NUM_33

#define SCALE4_DOUT GPIO_NUM_25
#define SCALE4_SCK GPIO_NUM_26

#define HX711_INVALID_READING 0x80000000
#define WEIGHT_NUMBER_TO_AVERAGE 20
#define WEIGHT_NUMBER_TO_TARE 200

typedef enum
{
    HX711_CHANNEL_A_128 = 25,
    HX711_CHANNEL_B_32 = 26,
    HX711_CHANNEL_A_64 = 27
} hx711_mode_t;

typedef struct
{
    uint8_t id;
    gpio_num_t dout_pin;
    gpio_num_t sck_pin;
    int clock_cycles_from_mode;
    int32_t offset; // tara
    double calib_factor;
} hx711_t;

typedef struct
{
    int32_t raw_value;
    float value;
} weight_t;

typedef struct
{
    int dout_pin;       // Pino DT (Data Out)
    int sck_pin;        // Pino SCK (Clock)
    float calib_factor; // Fator de calibração
    long zero_offset;   // Offset de tara (vZero)
    int invalid_limit;  // Limite para leitura inválida (gramas)
    bool connected;     // Status de conexão
    const char *name;   // Nome do sensor
} SensorConfig;

extern float scale_in_grams;
esp_err_t hx711_init(hx711_t *sensor, gpio_num_t dout, gpio_num_t sck, hx711_mode_t mode);
int32_t hx711_read_average(hx711_t *sensor);
void hx711_tare(hx711_t *sensor);

#endif // HX711_H