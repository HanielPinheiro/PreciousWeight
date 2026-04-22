#include "sensors_task.h"

static const char *ROTULO_LOCAL = "SENSOR_TASK";
static SemaphoreHandle_t barrier_semaphore = {0};
static QueueHandle_t sensor_data_queue = {0};
static TaskHandle_t reader_tasks[NUM_WEIGHT_SENSORS] = {0};

static void sensor_coordinator_task(void *pv_params)
{
    while (1)
    {
        for (int i = 0; i < NUM_WEIGHT_SENSORS; i++)
        { // Notifica todas as tasks de leitura
            xTaskNotifyGive(reader_tasks[i]);
        }
        vTaskDelay(pdMS_TO_TICKS(1000)); // leituras a cada 1s
    }
}

static void sensor_reader_task(void *pv_params)
{
    int sensor_id = (int)pv_params;
    hx711_t sensor = sensors[sensor_id];

    while (1)
    {        
        ulTaskNotifyTake(pdTRUE, portMAX_DELAY);
      
        // Armazena leitura e verifica se todas completaram
        sensor_readings[sensor_id] = ;
        if (xSemaphoreTake(barrier_semaphore, portMAX_DELAY))
        {
            readings_count++;
            if (readings_count == NUM_WEIGHT_SENSORS)
            {
                // Todas as leituras completas - libera processamento
                xQueueSend(sensor_data_queue, &sensor_readings, 0);
                readings_count = 0;
            }
            xSemaphoreGive(barrier_semaphore);
        }
    }
}

static void sensor_data_process_queue(void *pv_params)
{
    while (1)
    {
        if (xQueueReceive(sensor_data_queue, &sensor_data, portMAX_DELAY))
        { // recebeu sinal da leitura, processa
            int32_t weight = measure_weight();
        }
    }
}

/**
 * Além da leitura do peso é necessário monitorar os sensores
 * por isso existe uma estrutura de task e filas para ler sensores
 * Dessa forma a leitura é feita em thread especifica
 */

esp_err_t init_sensors_task()
{       
    //Semaforo para evitar acesso concorrente
    barrier_semaphore = xSemaphoreCreateCounting(1, 1);
    sensor_data_queue = xQueueCreate(10, sizeof(sensor_data_t) * NUM_WEIGHT_SENSORS);

    // Cria tasks de leitura individuais
    for (int i = 0; i < NUM_WEIGHT_SENSORS; i++)
    {
        xTaskCreate(sensor_reader_task, "sensor_reader", 2048, (void *)i, TASK_PRIORITY_HIGH, &reader_tasks[i]);
    }

    // Cria tasks de coordenação e processamento
    xTaskCreate(sensor_coordinator_task, "coordinator", 2048, NULL, TASK_PRIORITY_HIGH, NULL);
    xTaskCreate(sensor_data_process_queue, "processor", 4096, NULL, TASK_PRIORITY_MEDIUM, NULL);

    return ESP_OK;
}
