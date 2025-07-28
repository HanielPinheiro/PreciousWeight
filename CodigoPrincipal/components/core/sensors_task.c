#include "sensors_task.h"

static const char *ROTULO_LOCAL = "SENSOR_TASK";

static QueueHandle_t sensor_data_queue = NULL;

static bool send_sensor_data_to_queue(const sensor_data_t *data)
{
    if (!data || !sensor_data_queue)
        return false;
    return xQueueSend(sensor_data_queue, data, pdMS_TO_TICKS(1000)) == pdTRUE;
}

static bool receive_sensor_data_from_queue(sensor_data_t *data)
{
    if (!data || !sensor_data_queue)
        return false;
    return xQueueReceive(sensor_data_queue, data, portMAX_DELAY) == pdTRUE;
}

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

static void sensor_data_process_task(void *pv_params)
{
    sensor_data_t data;
    char log_msg[150];
    while (1)
    {
        if (receive_sensor_data_from_queue(&data))
        {
            snprintf(log_msg, sizeof(log_msg), "Dados do sensor: Sensor{%d} - Raw{%ld} - Weight{%.2f}", data.sensor_id, data.raw, data.weight);
            sdcard_log(LOG_INFO, log_msg, ROTULO_LOCAL);

            char topic[50];
            snprintf(topic, sizeof(topic), "%s/%d", MQTT_TOPIC_PUB_SENSOR, data.sensor_id);

            char payload[50];
            snprintf(payload, sizeof(payload), "Raw{%ld}_Weight{%.2f}", data.raw, data.weight);

            mqtt_publish(topic, payload, 2);
        }
    }
}

esp_err_t init_sensors_task(hx711_t *sensores, uint8_t num_sensores)
{
    sensor_data_queue = xQueueCreate(10, sizeof(sensor_data_t));
    if (!sensor_data_queue)
    {
        ESP_LOGE(ROTULO_LOCAL, "Falha ao criar fila de dados dos sensores");
        return ESP_FAIL;
    }

    if (xTaskCreate(sensor_data_process_task, "processar_sensores", 4096, NULL, TASK_PRIORITY_MEDIUM, NULL) != pdPASS)
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

    return ESP_OK;
}
