#pragma once
#ifndef HX711_H
#define HX711_H

#define NUM_WEIGHT_SENSORS 4

#define DEFAULT_OFFSET 0
#define DEFAULT_OFFSET 0

#define SCALE1_DOUT GPIO_NUM_21
#define SCALE1_SCK GPIO_NUM_22
#define SCALE1_FACTOR 88.848

#define SCALE2_DOUT GPIO_NUM_16
#define SCALE2_SCK GPIO_NUM_14 // PIN 17 original, 14 na atual pq deu problema na solda
#define SCALE2_FACTOR 11.694

#define SCALE3_DOUT GPIO_NUM_32
#define SCALE3_SCK GPIO_NUM_33
#define SCALE3_FACTOR 82.316

#define SCALE4_DOUT GPIO_NUM_25
#define SCALE4_SCK GPIO_NUM_26
#define SCALE4_FACTOR 107.285

#define HX711_INVALID_READING 0x80000000
#define AVERAGE_NUMBER 20
#define TARE_NUMBER 200
#define HX711_CHANNEL_A_128 25

#include <stdint.h>
#include "driver/gpio.h"
#include "esp_err.h"

typedef struct
{
    uint8_t id;
    gpio_num_t dout_pin;
    gpio_num_t sck_pin;
    int32_t offset;
    double calib_factor;
} hx711_t;

typedef struct
{
    int32_t raw_value;
    int32_t value;
} weight_t;

esp_err_t initialize_hx711_sensors(void);
void hx711_tare(hx711_t *sensor);
weight_t hx711_read_sensor_weight(hx711_t *sensor);
weight_t measure_scale_weight(void);

#endif // HX711_H
