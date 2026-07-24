#include "../../config/config.h"

static TaskHandle_t mqtt_manager_task_handle = NULL;
static SemaphoreHandle_t mqtt_restart_sem = NULL;
static char *ROTULO_LOCAL = "MQTT_TASK";
static QueueHandle_t mqtt_command_queue = NULL;

#define MQTT_COMMAND_MAX_LENGTH 128

typedef struct
{
    char payload[MQTT_COMMAND_MAX_LENGTH];
} mqtt_command_entry_t;

static void mqtt_command_worker_task(void *pvParameters)
{
    mqtt_command_entry_t entry;
    while (1)
    {
        if (xQueueReceive(mqtt_command_queue, &entry, portMAX_DELAY) == pdTRUE)
            process_mqtt_data(entry.payload);
    }
}

void mqtt_manager_task(void *pvParameters)
{ // Wait for restart signal or periodic check
    while (1)
    {
        if (xSemaphoreTake(mqtt_restart_sem, pdMS_TO_TICKS(10000)))
        {
            ESP_LOGI(ROTULO_LOCAL, "Processing MQTT restart request");
            ESP_LOGI(ROTULO_LOCAL, "Reinitializing MQTT");
            if (mqtt_restart_client() != ESP_OK)
                ESP_LOGE(ROTULO_LOCAL, "Falha ao reiniciar cliente MQTT");
        }
    }
}

void mqtt_connection_status_callback(esp_mqtt_event_id_t connected)
{
    switch (connected)
    {
    case MQTT_EVENT_CONNECTED:
        ESP_LOGI(ROTULO_LOCAL, "MQTT - Connected to MQTT broker");
        mqtt_publish(MQTT_TOPIC_CONN_STATUS, "CONNECTED", 1);
        break;

    case MQTT_EVENT_DISCONNECTED:
        ESP_LOGW(ROTULO_LOCAL, "MQTT - Disconnected from broker");
        break;

    case MQTT_EVENT_ERROR:
        ESP_LOGW(ROTULO_LOCAL, "MQTT - Error, forcing full reinitialization");
        xSemaphoreGive(mqtt_restart_sem); // Signal the manager task
        break;

    case MQTT_EVENT_DATA:
        /**Aqui é onde eu devo tratar o DADO RECEBIDO! e avaliar o que é pra ser feito
         * A balança tem 4 canais de comunicação:
         *  /scales/ = balança recebe comandos
         *  /status/ = balança envia on/off mqtt3.c
         *  /weights/ = balança envia peso nos horarios
         *  LOGO, balança publica em 3 canais, status, weights, e recebe dados em 1 scales
         * A balança só recebe os dados dela -> /scales/MAC_ADDRESS_ESP32 (SERVICE NAME)
         */
        if (strncmp(event->topic, MQTT_TOPIC_SCALES, event->topic_len) == 0)
        {
            mqtt_command_entry_t entry = {0};
            size_t copy_len = event->data_len < (MQTT_COMMAND_MAX_LENGTH - 1) ? event->data_len : (MQTT_COMMAND_MAX_LENGTH - 1);
            memcpy(entry.payload, event->data, copy_len);
            entry.payload[copy_len] = '\0';

            update_current_time();
            sdcard_log(LOG_INFO, current_time, ROTULO_LOCAL);
            sdcard_log(LOG_INFO, "MENSAGEM RECEBIDA VIA MQTT:", ROTULO_LOCAL);
            sdcard_log(LOG_INFO, entry.payload, ROTULO_LOCAL);

            if (xQueueSend(mqtt_command_queue, &entry, pdMS_TO_TICKS(50)) != pdTRUE)
                sdcard_log(LOG_ERROR, "Fila de comandos MQTT cheia", ROTULO_LOCAL);
        }
        break;

    default:
        break;
    }
}

esp_err_t init_mqtt_task()
{
    mqtt_restart_sem = xSemaphoreCreateBinary();
    mqtt_command_queue = xQueueCreate(10, sizeof(mqtt_command_entry_t));
    if (mqtt_restart_sem == NULL || mqtt_command_queue == NULL)
    {
        ESP_LOGE(ROTULO_LOCAL, "Falha ao criar recursos da task MQTT");
        return ESP_FAIL;
    }

    if (xTaskCreate(mqtt_manager_task, ROTULO_LOCAL, 4096, NULL, 5, &mqtt_manager_task_handle) != pdPASS)
    {
        ESP_LOGE(ROTULO_LOCAL, "Falha ao criar 'mqtt_manager_task'");
        return ESP_FAIL;
    }
    if (xTaskCreate(mqtt_command_worker_task, "mqtt_cmd_worker", 4096, NULL, TASK_PRIORITY_MEDIUM, NULL) != pdPASS)
    {
        ESP_LOGE(ROTULO_LOCAL, "Falha ao criar 'mqtt_command_worker_task'");
        return ESP_FAIL;
    }
    mqtt_init(mqtt_connection_status_callback);
    return ESP_OK;
}
