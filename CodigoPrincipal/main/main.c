/* Videos uteis
 * https://www.youtube.com/watch?v=7rbZFcqTaGc -> explica tasks e semaforo mutex
 * https://www.youtube.com/watch?v=s6RPzYDAMDM -> Mqtt e Wifi control semaforo binary(00:48) / (04:14) filas pra dados sensor / (12:10) Events groups /
 * https://www.youtube.com/watch?v=JzQTPnCspNM -> Outro exemplo de semaforo
 */

#include "bios.h"
#include "sensors_task.h"
#include "sdcard_task.h"
#include "wifi_prov_ble.h"
#include "mqtt_task.h"
#include "config_system.h"

void app_main()
{
    char *ROTULO_LOCAL = "MAIN";

    init_hardware();
    sdcard_log(LOG_INFO, get_reset_reason_string(esp_reset_reason()), ROTULO_LOCAL);
    sdcard_log(LOG_INFO, "Rotina da BIOS executada com sucesso.", ROTULO_LOCAL);

    update_current_time();
    sdcard_log(LOG_INFO, current_time, ROTULO_LOCAL);

    init_wifi();
    sdcard_log(LOG_INFO, "Wi-Fi inicializado com sucesso. Inicializando MQTT.", ROTULO_LOCAL);

    if (init_mqtt_task() != ESP_OK)
    {
        sdcard_log(LOG_ERROR, "Falha ao inicializar init_mqtt_task", ROTULO_LOCAL);
        return;
    }
    sdcard_log(LOG_INFO, "Task MQTT Manager com Callback inicializada com sucesso. \r\n ", ROTULO_LOCAL);

    if (init_sdcard_task() != ESP_OK)
    {
        sdcard_log(LOG_ERROR, "Falha ao inicializar init_sdcard_task", ROTULO_LOCAL);
        return;
    }

    // if (init_sensors_task(sensores, NUM_SENSORES_PESO) != ESP_OK)
    // {
    //     sdcard_log(LOG_ERROR, "Falha ao inicializar init_sensors_task", ROTULO_LOCAL);
    //     return;
    // }

    update_current_time();
    sdcard_log(LOG_INFO, current_time, ROTULO_LOCAL);
    sdcard_log(LOG_INFO, "ENTRANDO EM LOOP", ROTULO_LOCAL);

    while (1)
    {
        vTaskDelay(pdMS_TO_TICKS(1000));
    }
}
