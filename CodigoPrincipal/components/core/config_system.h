#pragma once
#ifndef CONFIG_SYSTEM_H
#define CONFIG_SYSTEM_H

#include "esp_system.h"

#define MAX_WEIGHT_TIMES 10

// Prioridades das tasks
typedef enum
{
    TASK_PRIORITY_LOW = 1,
    TASK_PRIORITY_MEDIUM = 2,
    TASK_PRIORITY_HIGH = 3,
    TASK_PRIORITY_CRITICAL = 4
} task_priority_t;

typedef enum
{
    ESTADO_SEM_BEBE,
    ESTADO_COM_BEBE
} estado_balanca_t;

typedef struct
{
    uint8_t hora;
    uint8_t minuto;
    int8_t gmt;
} horario_pesagem_t;

// Declarações externas
extern uint8_t number_times;
extern horario_pesagem_t weight_times[MAX_WEIGHT_TIMES];

// Protótipos de funções
void handle_estado_com_bebe();
void handle_estado_sem_bebe();
char *get_reset_reason_string(esp_reset_reason_t reason);

#endif // CONFIG_SYSTEM_H