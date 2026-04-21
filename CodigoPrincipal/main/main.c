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
#include "sensors_task.h"

QueueHandle_t sensor_queues[NUM_WEIGHT_SENSORS] = {0};
TaskHandle_t sensor_tasks[NUM_WEIGHT_SENSORS] = {0};
TaskHandle_t display_task_handle = {0};

void app_main()
{
    char *ROTULO_LOCAL = "MAIN";
    init_hardware();
    sdcard_log(LOG_WARN, get_reset_reason_string(esp_reset_reason()), ROTULO_LOCAL);
    sdcard_log(LOG_INFO, "Rotina da BIOS executada com sucesso.", ROTULO_LOCAL);

    // init_wifi();
    // sdcard_log(LOG_INFO, "Wi-Fi inicializado com sucesso. Inicializando MQTT.", ROTULO_LOCAL);

    // if (init_mqtt_task() != ESP_OK)
    // {
    //     sdcard_log(LOG_ERROR, "Falha ao inicializar init_mqtt_task", ROTULO_LOCAL);
    //     return;
    // }
    // sdcard_log(LOG_INFO, "Task MQTT Manager com Callback inicializada com sucesso. Iniciando Taks", ROTULO_LOCAL);

    if (init_sdcard_task() != ESP_OK)
    {
        sdcard_log(LOG_ERROR, "Falha ao inicializar init_sdcard_task", ROTULO_LOCAL);
        return;
    }

    if (init_sensors_task() != ESP_OK)
    {
        sdcard_log(LOG_ERROR, "Falha ao inicializar init_sensors_task", ROTULO_LOCAL);
        return;
    }

    // init_weight_sensors_timer();
    measure_weight();

    char m[90] = {0};
    update_current_time();
    snprintf(m, 90, "Sistema inicializado com sucesso em %s \r\n", current_time);
    sdcard_log(LOG_INFO, m, ROTULO_LOCAL);
}
