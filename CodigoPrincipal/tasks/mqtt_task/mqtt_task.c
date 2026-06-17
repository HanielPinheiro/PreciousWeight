#include "../../config/config.h"

static TaskHandle_t mqtt_manager_task_handle = NULL;
static SemaphoreHandle_t mqtt_restart_sem = NULL;
static char *ROTULO_LOCAL = "MQTT_TASK";

void mqtt_manager_task(void *pvParameters)
{ // Wait for restart signal or periodic check
    while (1)
    {
        if (xSemaphoreTake(mqtt_restart_sem, pdMS_TO_TICKS(10000)))
        {
            ESP_LOGI(ROTULO_LOCAL, "Processing MQTT restart request");
            esp_mqtt_client_handle_t client = mqtt_get_client_handle();
            if (client)
            {
                ESP_LOGI(ROTULO_LOCAL, "Stopping MQTT client");
                esp_mqtt_client_stop(client);
                vTaskDelay(pdMS_TO_TICKS(500));

                ESP_LOGI(ROTULO_LOCAL, "Destroying MQTT client");
                esp_mqtt_client_destroy(client);
                vTaskDelay(pdMS_TO_TICKS(1000));
                mqtt_reset_client_handle();
            }

            ESP_LOGI(ROTULO_LOCAL, "Reinitializing MQTT");
            mqtt_app_start();
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
         *  /sensors/ = balança envia estado dos sensors (medidas)
         *  /weights/ = balança envia peso nos horarios
         *  LOGO, balança publica em 3 canais, status, sensors, weights, e recebe dados em 1
         * A balança só recebe os dados dela -> /scales/MAC_ADDRESS_ESP32 (SERVICE NAME)
         */
        if (strncmp(event->topic, MQTT_TOPIC_SCALES, event->topic_len) == 0)
        {
            // Cria uma cópia null-terminated segura dos dados
            char msg_copy[event->data_len + 1]; // +1 para o null terminator
            memcpy(msg_copy, event->data, event->data_len);
            msg_copy[event->data_len] = '\0'; // Garante terminação nula

            update_current_time();
            sdcard_log(LOG_INFO, current_time, ROTULO_LOCAL);
            sdcard_log(LOG_INFO, "MENSAGEM RECEBIDA VIA MQTT:", ROTULO_LOCAL);
            sdcard_log(LOG_INFO, msg_copy, ROTULO_LOCAL);

            process_mqtt_data(msg_copy);
        }
        break;

    default:
        break;
    }
}

esp_err_t init_mqtt_task()
{
    mqtt_restart_sem = xSemaphoreCreateBinary();
    if (xTaskCreate(mqtt_manager_task, ROTULO_LOCAL, 4096, NULL, 5, &mqtt_manager_task_handle) != pdPASS)
    {
        ESP_LOGE(ROTULO_LOCAL, "Falha ao criar 'mqtt_manager_task'");
        return ESP_FAIL;
    }
    mqtt_init(mqtt_connection_status_callback);
    return ESP_OK;
}