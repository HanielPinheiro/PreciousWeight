#include "sdcard_task.h"

static const char *ROTULO_LOCAL = "SDCARD_TASK";
static uint8_t sd_failure_counter = 0;
static TaskHandle_t sd_task_handler = NULL;

QueueHandle_t sdcard_log_queue = NULL;
static void sdcard_writer_task(void *pv_params)
{
    log_entry_t entry;

    while (1)
    {
        if (xQueueReceive(sdcard_log_queue, &entry, pdMS_TO_TICKS(100)))
        {
            esp_err_t ret = sdcard_write_file(entry.path, entry.message); // já com mutex lá dentro
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

esp_err_t init_sdcard_task()
{
    sdcard_log_queue = xQueueCreate(10, sizeof(log_entry_t));
    if (!sdcard_log_queue)
    {
        sdcard_log(LOG_ERROR, "Falha ao criar fila de log", ROTULO_LOCAL);
        return ESP_FAIL;
    }

    if (xTaskCreate(sdcard_writer_task, "gravar_logs_sd", 4096, NULL, TASK_PRIORITY_MEDIUM, &sd_task_handler) != pdPASS)
    {
        sdcard_log(LOG_ERROR, "Falha ao criar task de gravação de logs", ROTULO_LOCAL);
        return ESP_FAIL;
    }

    return ESP_OK;
}
