#include "sensors_task.h"

static const char *ROTULO_LOCAL = "SENSOR_TASK";
static QueueHandle_t sensor_data_queue = {0};
static TaskHandle_t reader_tasks[NUM_WEIGHT_SENSORS] = {0};
static SemaphoreHandle_t barrier_semaphore = {0};
static sensor_data_t sensor_readings[NUM_WEIGHT_SENSORS] = {0};
static int readings_count = 0;

static void sensor_reader_task(void *pv_params)
{
    int sensor_id = (int)pv_params;
    hx711_t sensor = sensors[sensor_id];

    while (1)
    {
        // Aguarda sinal para iniciar leitura sincronizada
        ulTaskNotifyTake(pdTRUE, portMAX_DELAY);

        sensor_data_t data = {.sensor_id = sensor_id, .raw_value = hx711_read_average(&sensor, WEIGHT_NUMBER_TO_AVERAGE)};
        int32_t diff = data.raw_value - sensor.offset;
        data.units = diff < 0 ? diff * -1 : diff;
        data.weight = data.units / sensor.calib_factor;

        // Armazena leitura e verifica se todas completaram
        sensor_readings[sensor_id] = data;
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

static void sensor_coordinator_task(void *pv_params)
{
    while (1)
    {
        for (int i = 0; i < NUM_WEIGHT_SENSORS; i++) // Notifica todas as tasks de leitura simultaneamente
        {
            xTaskNotifyGive(reader_tasks[i]);
        }
        vTaskDelay(pdMS_TO_TICKS(1000));
    }
}

static void sensor_data_process_task(void *pv_params)
{
    sensor_data_t sensor_data[NUM_WEIGHT_SENSORS] = {0};
    // int count_err[NUM_WEIGHT_SENSORS] = {0, 0, 0, 0};
    while (1)
    {
        if (xQueueReceive(sensor_data_queue, &sensor_data, portMAX_DELAY))
        {
            ESP_LOGW(ROTULO_LOCAL, "Sensor[%d]:Raw{%ld}|Diff{%ld};Sensor[%d]:Raw{%ld}|Diff{%ld};Sensor[%d]:Raw{%ld}|Diff{%ld};Sensor[%d]:Raw{%ld}|Diff{%ld}",
                     sensor_data[0].sensor_id, sensor_data[0].raw_value, sensor_data[0].units,
                     sensor_data[1].sensor_id, sensor_data[1].raw_value, sensor_data[1].units,
                     sensor_data[2].sensor_id, sensor_data[2].raw_value, sensor_data[2].units,
                     sensor_data[3].sensor_id, sensor_data[3].raw_value, sensor_data[3].units);

            // Aqui você pode adicionar o processamento conjunto dos dados
            ESP_LOGE(ROTULO_LOCAL, "Sensor[%d]:Weight{%ld};Sensor[%d]:Weight{%ld};Sensor[%d]:Weight{%ld};Sensor[%d]:Weight{%ld}",
                     sensor_data[0].sensor_id, sensor_data[0].weight,
                     sensor_data[1].sensor_id, sensor_data[1].weight,
                     sensor_data[2].sensor_id, sensor_data[2].weight,
                     sensor_data[3].sensor_id, sensor_data[3].weight);

            // int32_t final_weight = 0UL;
            // for (int i = 0; i < NUM_WEIGHT_SENSORS; i++)
            //     final_weight += sensor_data[i].weight;
            // final_weight /= NUM_WEIGHT_SENSORS;
            // ESP_LOGI(ROTULO_LOCAL, "Peso{%ld}", final_weight);

            // // Correcao do offset
            // int32_t err = 0UL;
            // int32_t tolerance = 3; // em gramas -> unidade do peso final

            // for (int i = 0; i < NUM_WEIGHT_SENSORS; i++)
            // {
            //     err = final_weight - sensor_data[i].weight;
            //     if (err < 0 && err < final_weight - tolerance)
            //     {
            //         count_err[i]++;
            //         if (count_err[i] == 5)
            //         {
            //             int32_t new_factor = sensors[i].calib_factor-10;//sensor_data[i].units / final_weight;
            //             ESP_LOGI(ROTULO_LOCAL, "TrocandoCalibFactor Sensor[%d];AntigoFator{%ld};NovoFator{%ld}", sensors[i].id, sensors[i].calib_factor, new_factor);
            //             sensors[i].calib_factor = new_factor;
            //             count_err[i] = 0;
            //         }
            //     }
            // }
        }
    }
}

esp_err_t init_sensors_task()
{
    for (int i = 0; i < NUM_WEIGHT_SENSORS; i++)
    {
        ESP_LOGI(ROTULO_LOCAL, "Tare - Sensor[%d]", i);
        hx711_tare(&sensors[i], WEIGHT_NUMBER_TO_TARE);
    }

    // Cria recursos de sincronização
    barrier_semaphore = xSemaphoreCreateCounting(1, 1);
    sensor_data_queue = xQueueCreate(10, sizeof(sensor_data_t) * NUM_WEIGHT_SENSORS);

    // Cria tasks de leitura individuais
    for (int i = 0; i < NUM_WEIGHT_SENSORS; i++)
    {
        xTaskCreate(sensor_reader_task, "sensor_reader", 2048, (void *)i, TASK_PRIORITY_HIGH, &reader_tasks[i]);
    }

    // Cria tasks de coordenação e processamento
    xTaskCreate(sensor_coordinator_task, "coordinator", 2048, NULL, TASK_PRIORITY_HIGH, NULL);
    xTaskCreate(sensor_data_process_task, "processor", 4096, NULL, TASK_PRIORITY_MEDIUM, NULL);

    return ESP_OK;
}
