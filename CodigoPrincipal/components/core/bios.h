#pragma once

#include "system_core.h"
#include "hx711.h"


#define LED_GPIO GPIO_NUM_2
#define NUM_SENSORES_PESO 4

extern hx711_t scale1, scale2, scale3, scale4;
extern hx711_t sensores[NUM_SENSORES_PESO];

void init_hardware(void);
