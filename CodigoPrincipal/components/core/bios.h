#pragma once
#ifndef BIOS_H
#define BIOS_H

#include "comm_libs.h"
#include "buzzer.h"
#include "sdcard.h"
#include "hx711.h"

#define LED_GPIO GPIO_NUM_2
#define NUM_WEIGHT_SENSORS 4

extern hx711_t sensors[NUM_WEIGHT_SENSORS];
weight_t measure_weight();
void init_hardware(void);

#endif // BIOS_H
