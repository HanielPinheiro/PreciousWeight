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

#include "../../main/main.h"

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
    int32_t offset; // tara
    double calib_factor;
} hx711_t;

esp_err_t initialize_weight_sensors(void);
void hx711_tare(hx711_t *sensor);
int32_t measure_weight(void);

#endif // HX711_H