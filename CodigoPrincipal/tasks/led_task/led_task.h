#pragma once
#ifndef LED_TASK_H
#define LED_TASK_H

#include "esp_err.h"

#define LED_GPIO GPIO_NUM_2
#define LED_HIGH_LEVEL 1
#define LED_LOW_LEVEL 0

/**
 *  BLINK_LED_NORMAL_OPER                   	OPERAÇÃO NORMAL -> LED DESLIGADO
 *  BLINK_LED_CRITICAL_ERROR                    ERRO CRITICO -> LED LIGADO O TEMPO TODO
 *  BLINK_LED_STARTING_TASKS            	    INICIALIZANDO TASKS (PISCANDO LENTO)
 *  BLINK_LED_EVENTS        	                PISCADA 2x E DELAY -> OK
 *  BLINK_LED_EVENTS_ERROR	                    PISCADA 5x E DELAY -> ERRO
 */
typedef enum
{
    BLINK_LED_NORMAL_OPER,
    BLINK_LED_STARTING_TASKS,
    BLINK_LED_CRITICAL_ERROR,
    BLINK_LED_EVENTS,
    BLINK_LED_EVENTS_ERROR,
} led_pattern_t;

esp_err_t led_indicator_start(void);
esp_err_t led_indicator_set_pattern(led_pattern_t pattern);

#endif // LED_TASK_H