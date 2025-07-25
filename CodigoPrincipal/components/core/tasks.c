#include "tasks.h"

static const char *ROTULO_LOCAL = "TASKS";

static QueueHandle_t sensor_data_queue = NULL;
static uint8_t sd_failure_counter = 0;
static TaskHandle_t sd_task_handler = NULL;

static void sensor_reader_task(void *pv_params)
{
    hx711_t *sensor = (hx711_t *)pv_params;
    sensor_data_t data = {0};
    char log_msg[150];
    while (1)
    {
        data.raw = hx711_read_raw(sensor);
        data.weight = hx711_read_weight(sensor);
        data.sensor_id = sensor->sensor_id;
        if (!send_sensor_data_to_queue(&data))
        {
            snprintf(log_msg, sizeof(log_msg), "Falha ao enviar dados do sensor para a fila: Sensor{%d} - Raw{%ld} - Weight{%.2f}", data.sensor_id, data.raw, data.weight);
            sdcard_log(LOG_INFO, log_msg, ROTULO_LOCAL);
        }

        vTaskDelay(pdMS_TO_TICKS(5000)); // Intervalo de leitura
    }
}

static void data_processor_task(void *pv_params)
{
    sensor_data_t data;
    char log_msg[150];
    while (1)
    {
        if (receive_sensor_data_from_queue(&data, portMAX_DELAY))
        {
            snprintf(log_msg, sizeof(log_msg), "Dados do sensor: Sensor{%d} - Raw{%ld} - Weight{%.2f}", data.sensor_id, data.raw, data.weight);
            sdcard_log(LOG_INFO, log_msg, ROTULO_LOCAL);

            char topic[50];
            snprintf(topic, sizeof(topic), "%s/%d/%s", MQTT_TOPIC_PUB_PREFIX, data.sensor_id, MQTT_TOPIC_PUB_SUFIX);

            char payload[50];
            snprintf(payload, sizeof(payload), "Raw{%ld}_Weight{%.2f}", data.raw, data.weight);

            mqtt_publish(topic, payload, 2);
        }
    }
}

static void sd_writer_task(void *pv_params)
{
    log_entry_t entry;

    while (1)
    {
        if (xQueueReceive(sdcard_log_queue, &entry, pdMS_TO_TICKS(100)))
        {
            esp_err_t ret = sdcard_write_file(LOG_FILE, entry.message); // já com mutex lá dentro
            if (ret != ESP_OK)
            {
                vTaskDelay(pdMS_TO_TICKS(1000));
                sd_failure_counter++;
                if (sd_failure_counter == 5)
                {
                    vTaskSuspend(sd_task_handler);
                }
            }
        }
    }
}

bool send_sensor_data_to_queue(const sensor_data_t *data)
{
    if (!data || !sensor_data_queue)
        return false;
    return xQueueSend(sensor_data_queue, data, pdMS_TO_TICKS(1000)) == pdTRUE;
}

bool receive_sensor_data_from_queue(sensor_data_t *data, TickType_t timeout)
{
    if (!data || !sensor_data_queue)
        return false;
    return xQueueReceive(sensor_data_queue, data, timeout) == pdTRUE;
}

esp_err_t tasks_init(hx711_t *sensores, uint8_t num_sensores)
{
#pragma region sensor_data

    sensor_data_queue = xQueueCreate(20, sizeof(sensor_data_t));
    if (!sensor_data_queue)
    {
        ESP_LOGE(ROTULO_LOCAL, "Falha ao criar fila de dados dos sensores");
        return ESP_FAIL;
    }

    if (xTaskCreate(data_processor_task, "processar_sensores", 4096, NULL, TASK_PRIORITY_MEDIUM, NULL) != pdPASS)
    {
        ESP_LOGE(ROTULO_LOCAL, "Falha ao criar task de processamento");
        return ESP_FAIL;
    }

    // Cria tasks de leitura para cada sensor
    for (int i = 0; i < num_sensores; i++)
    {
        if (xTaskCreate(sensor_reader_task, "ler_sensores", 2048, &sensores[i], TASK_PRIORITY_LOW, NULL) != pdPASS)
        {
            ESP_LOGE(ROTULO_LOCAL, "Falha ao criar task de leitura para sensor %d", i);
            return ESP_FAIL;
        }
    }

#pragma endregion

#pragma region sdcard_log

    sdcard_log_queue = xQueueCreate(5, sizeof(log_entry_t));
    if (!sdcard_log_queue)
    {
        ESP_LOGE(ROTULO_LOCAL, "Falha ao criar fila de log");
        return ESP_FAIL;
    }

    if (xTaskCreate(sd_writer_task, "gravar_logs_sd", 4096, NULL, TASK_PRIORITY_MEDIUM, &sd_task_handler) != pdPASS)
    {
        ESP_LOGE(ROTULO_LOCAL, "Falha ao criar task de gravação de logs");
        return ESP_FAIL;
    }

#pragma endregion

    return ESP_OK;
}
