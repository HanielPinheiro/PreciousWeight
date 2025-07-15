#pragma once

#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/queue.h"
#include "esp_log.h"
#include "buzzer.h"
#include "hx711.h"
#include "sdcard.h"

// Configurações de prioridade das tarefas
typedef enum
{
    TASK_PRIORITY_SENSOR = 3, // Alta prioridade
    TASK_PRIORITY_SD = 2,     // Média prioridade
    TASK_PRIORITY_MONITOR = 1 // Baixa prioridade
} task_priority_t;

// Estrutura de dados do sensor (otimizada para alinhamento de memória)
typedef struct __attribute__((packed))
{
    float weight;         // Peso em gramas (4 bytes)
    uint8_t sensor_id;    // ID do sensor (1 byte)
    TickType_t timestamp; // Timestamp (4 bytes)
} sensor_data_t;

// Configuração dinâmica da fila
typedef struct
{
    UBaseType_t size;   // Tamanho máximo
    TickType_t timeout; // Timeout de envio
} queue_config_t;

// API Pública
void system_manager_start(void);
bool system_manager_send_data(const sensor_data_t *data);
bool system_manager_receive_data(sensor_data_t *data, TickType_t timeout);