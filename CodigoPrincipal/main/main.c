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

hx711_t sensors[NUM_WEIGHT_SENSORS] = {0};
SensorConfig sensors_config[NUM_WEIGHT_SENSORS] = {
    {21, 22, 88.848, 0, -1, false, "Sensor 1"},
    {16, 14, 11.694, 0, -1, false, "Sensor 2"},
    {32, 33, 82.316, 0, -1, false, "Sensor 3"},
    {25, 26, 107.285, 0, -1, false, "Sensor 4"}};

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

#pragma region Bios

// extern hx711_t sensors[NUM_WEIGHT_SENSORS];

void init_hardware()
{
    esp_log_at_terminal(ROTULO_LOCAL, "Inicializando Cartao SD.");

    initialize_sdcard();

    sdcard_log(LOG_INFO, "Cartao SD inicializado. Inicializando sensores HX711.", ROTULO_LOCAL);
    ESP_ERROR_CHECK(initialize_weight_sensors());

    sdcard_log(LOG_INFO, "Sensores inicializados.", ROTULO_LOCAL);
}

static esp_err_t initialize_sdcard()
{
    uint8_t retry_count = 0;
    const uint8_t max_retries = 3;
    esp_err_t ret = ESP_FAIL;
    do
    {
        esp_log_at_terminal(ROTULO_LOCAL, "Loop While");
        ret = sdcard_init();
        if (ret == ESP_OK)
        {
            ret = sdcard_log(LOG_INFO, "Testando Logs no Cartao SD ", ROTULO_LOCAL);
            if (ret == ESP_OK)
                break;

            esp_log_at_terminal(ROTULO_LOCAL, "Problema ao escrever Logs!!");
            vTaskDelay(pdMS_TO_TICKS(1000));
            retry_count++;
            continue;
        }

        esp_log_at_terminal(ROTULO_LOCAL, "Falha ao iniciar Cartao SD");
        retry_count++;
        vTaskDelay(pdMS_TO_TICKS(1000));
    } while (retry_count < max_retries);

    return ret;
}

static esp_err_t initialize_weight_sensors()
{
    int dout[4] = {SCALE1_DOUT, SCALE2_DOUT, SCALE3_DOUT, SCALE4_DOUT};
    int sck[4] = {SCALE1_SCK, SCALE2_SCK, SCALE3_SCK, SCALE4_SCK};
    // uint32_t calib_factor[4] = {86UL, 123UL, 74UL, 116UL}; // estimados manualmente
    uint32_t calib_factor[4] = {315UL, 315UL, 240UL, 315UL}; // estimados manualmente
    for (int i = 0; i < NUM_WEIGHT_SENSORS; i++)
    {
        sensors[i].id = i;
        sensors[i].calib_factor = calib_factor[i];
        if (hx711_init(&sensors[i], dout[i], sck[i], HX711_CHANNEL_A_128) != ESP_OK)
        {
            char msg[80];
            snprintf(msg, 80, "Falha ao inicializar sensor 1, portas: %d [OUT] e %d [CLK].", &sensors[i]->dout_pin, &sensors[i]->sck_pin);
            sdcard_log(LOG_ERROR, msg, ROTULO_LOCAL);
            return ESP_FAIL;
        }
        return ESP_OK;
    }
    vTaskDelay(pdMS_TO_TICKS(2000)); // Aguarda dois segundos para estabilização térmica
    return ESP_OK;
}

#pragma endregion