/* Videos uteis
 * https://www.youtube.com/watch?v=7rbZFcqTaGc -> explica tasks e semaforo mutex
 * https://www.youtube.com/watch?v=s6RPzYDAMDM -> Mqtt e Wifi control semaforo binary(00:48) / (04:14) filas pra dados sensor / (12:10) Events groups /
 * https://www.youtube.com/watch?v=JzQTPnCspNM -> Outro exemplo de semaforo
 */

#include "bios.h"
#include "tasks.h"
#include "mqtt3.h"
#include "wifi_prov_ble.h"

#pragma region MQTT

static TaskHandle_t mqtt_manager_task_handle = NULL;
static SemaphoreHandle_t mqtt_restart_sem = NULL;

static void mqtt_manager_task(void *pvParameters)
{
    while (1)
    {
        // Wait for restart signal or periodic check
        if (xSemaphoreTake(mqtt_restart_sem, pdMS_TO_TICKS(10000)))
        {
            ESP_LOGI("MQTT_MANAGER", "Processing MQTT restart request");
            esp_mqtt_client_handle_t client = mqtt_get_client_handle();
            if (client)
            {
                ESP_LOGI("MQTT_MANAGER", "Stopping MQTT client");
                esp_mqtt_client_stop(client);
                vTaskDelay(pdMS_TO_TICKS(500));

                ESP_LOGI("MQTT_MANAGER", "Destroying MQTT client");
                esp_mqtt_client_destroy(client);
                vTaskDelay(pdMS_TO_TICKS(1000));
                mqtt_reset_client_handle();
            }

            ESP_LOGI("MQTT_MANAGER", "Reinitializing MQTT");
            mqtt_app_start();
        }
    }
}

static void mqtt_connection_status_callback(mqtt_state_t connected)
{
    switch (connected)
    {
    case MQTT_STATE_CONNECTED:
        ESP_LOGI("MAIN", "MQTT - Connected to MQTT broker");
        mqtt_publish("/status", "Esp32_online", 1);
        break;

    case MQTT_STATE_DISCONNECTED:
        ESP_LOGW("MAIN", "MQTT - Disconnected from broker");
        break;

    case MQTT_STATE_ERROR:
        ESP_LOGW("MAIN", "MQTT - Error, forcing full reinitialization");
        xSemaphoreGive(mqtt_restart_sem); // Signal the manager task
        break;

    default:
        break;
    }
}

#pragma endregion

void app_main()
{
    const char *ROTULO_LOCAL = "MAIN";
    init_hardware();
    sdcard_log(LOG_INFO, "Rotina da BIOS executada com sucesso.", ROTULO_LOCAL);

    wifi_init();
    sdcard_log(LOG_INFO, "Wi-Fi inicializado com sucesso. Inicializando MQTT.", ROTULO_LOCAL);

    mqtt_restart_sem = xSemaphoreCreateBinary();
    xTaskCreate(mqtt_manager_task, "mqtt_manager", 4096, NULL, 5, &mqtt_manager_task_handle);
    mqtt_init(mqtt_connection_status_callback);
    sdcard_log(LOG_INFO, "Task MQTT inicializada com sucesso. \r\n ", ROTULO_LOCAL);

    if (tasks_init(sensores, NUM_SENSORES_PESO) != ESP_OK)
    {
        sdcard_log(LOG_ERROR, "Falha ao inicializar tasks", "MAIN");
        return;
    }

    while (1)
    {
        vTaskDelay(pdMS_TO_TICKS(1000));
    }
}
