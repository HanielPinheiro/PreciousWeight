/* Videos uteis
 * https://www.youtube.com/watch?v=7rbZFcqTaGc -> explica tasks e semaforo mutex
 * https://www.youtube.com/watch?v=s6RPzYDAMDM -> Mqtt e Wifi control semaforo binary(00:48) / (04:14) filas pra dados sensor / (12:10) Events groups /
 * https://www.youtube.com/watch?v=JzQTPnCspNM -> Outro exemplo de semaforo
 */

#include "bios.h"
#include "weight_timer_scheduler.h"
#include "sdcard_task.h"
#include "wifi_prov_ble.h"
#include "mqtt_task.h"
#include "process_mqtt_data.h"

void app_main()
{
    char *ROTULO_LOCAL = "MAIN";
    init_hardware();
    sdcard_log(LOG_WARN, get_reset_reason_string(esp_reset_reason()), ROTULO_LOCAL);
    sdcard_log(LOG_INFO, "Rotina da BIOS executada com sucesso.", ROTULO_LOCAL);

    init_wifi();
    sdcard_log(LOG_INFO, "Wi-Fi inicializado com sucesso. Inicializando MQTT.", ROTULO_LOCAL);

    if (init_mqtt_task() != ESP_OK)
    {
        sdcard_log(LOG_ERROR, "Falha ao inicializar init_mqtt_task", ROTULO_LOCAL);
        return;
    }
    sdcard_log(LOG_INFO, "Task MQTT Manager com Callback inicializada com sucesso. Iniciando Taks", ROTULO_LOCAL);

    if (init_sdcard_task() != ESP_OK)
    {
        sdcard_log(LOG_ERROR, "Falha ao inicializar init_sdcard_task", ROTULO_LOCAL);
        return;
    }

    init_weight_sensors_timer();

    char m[90];
    update_current_time();
    snprintf(m, 90, "Sistema inicializado com sucesso em %s \r\n", current_time);
    sdcard_log(LOG_INFO, m, ROTULO_LOCAL);

    while (1)
    {
        int32_t v[4] = {0UL, 0UL, 0UL, 0UL};
        int32_t v2[4] = {0UL, 0UL, 0UL, 0UL};
        for (int i = 0; i < SENSORS_COUNT; i++)
        {
            v[i] = hx711_read_average(&sensors[i], WEIGHT_NUMBER_TO_AVERAGE);
            v2[i] = v[i] - sensors[i].offset;
        }
        for (int i = 0; i < SENSORS_COUNT; i++)
            printf("Raw[%d]: {%ld}", i, v[i]);

        for (int i = 0; i < SENSORS_COUNT; i++)
            printf("Diff[%d]: {%ld}", i, v2[i]);
        printf("\n");
        vTaskDelay(pdMS_TO_TICKS(100));
    }
}
