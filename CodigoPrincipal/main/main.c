/* Videos uteis
 * https://www.youtube.com/watch?v=7rbZFcqTaGc -> explica tasks e semaforo mutex
 * https://www.youtube.com/watch?v=s6RPzYDAMDM -> Mqtt e Wifi control semaforo binary(00:48) / (04:14) filas pra dados sensor / (12:10) Events groups /
 * https://www.youtube.com/watch?v=JzQTPnCspNM -> Outro exemplo de semaforo
 */

#include "../config/config.h"

char *ROTULO_LOCAL = "MAIN";

hx711_t sensors[NUM_WEIGHT_SENSORS] = {
    {.id = 0, .dout_pin = SCALE1_DOUT, .sck_pin = SCALE1_SCK, .offset = DEFAULT_OFFSET, .calib_factor = 0.002464073379},
    {.id = 1, .dout_pin = SCALE2_DOUT, .sck_pin = SCALE2_SCK, .offset = DEFAULT_OFFSET, .calib_factor = 0.002606863625},
    {.id = 2, .dout_pin = SCALE3_DOUT, .sck_pin = SCALE3_SCK, .offset = DEFAULT_OFFSET, .calib_factor = 0.002503721628},
    {.id = 3, .dout_pin = SCALE4_DOUT, .sck_pin = SCALE4_SCK, .offset = DEFAULT_OFFSET, .calib_factor = 0.002512369584}};

static char *get_reset_reason_string(esp_reset_reason_t reason)
{
    switch (reason)
    {
    case ESP_RST_POWERON:
        return "Razao do último reset: Power-On Reset";
    case ESP_RST_SW:
        return "Razao do último reset: Software Reset (esp_restart)";
    case ESP_RST_PANIC:
        return "Razao do último reset: Panic/Crash Reset";
    case ESP_RST_INT_WDT:
        return "Razao do último reset: Interrupt Watchdog Reset";
    case ESP_RST_TASK_WDT:
        return "Razao do ultimo reset: Task Watchdog Reset";
    case ESP_RST_WDT:
        return "Razao do ultimo reset: Other Watchdog Reset";
    case ESP_RST_DEEPSLEEP:
        return "Razao do ultimo reset: Deep Sleep Wakeup";
    case ESP_RST_BROWNOUT:
        return "Razao do ultimo reset: Brownout Reset";
    case ESP_RST_SDIO:
        return "Razao do ultimo reset: SDIO Reset";
    default:
        return "Razao do ultimo reset: Unknown Reset Reason";
    }
}

static esp_err_t initialize_nvs_flash_storage(void)
{
    esp_err_t ret = nvs_flash_init();
    if (ret == ESP_ERR_NVS_NO_FREE_PAGES || ret == ESP_ERR_NVS_NEW_VERSION_FOUND)
    {
        ESP_ERROR_CHECK(nvs_flash_erase());
        ret = nvs_flash_init();
    }
    return ret;
}

void PW_ERROR_CHECK(esp_err_t task)
{
    if (task != ESP_OK)
    {
        ESP_LOGE(ROTULO_LOCAL, "Erro critico");
        set_pattern_to_led_task(BLINK_LED_CRITICAL_ERROR);
        while (1)
        {
            vTaskDelay(pdMS_TO_TICKS(1000)); // yields CPU, feeds watchdog automatically
        }
    }
}

void app_main()
{
    // Leds
    ESP_ERROR_CHECK(initialize_led_task());
    ESP_ERROR_CHECK(set_pattern_to_led_task(BLINK_LED_STARTING_TASKS));

    esp_log_at_terminal(ROTULO_LOCAL, "Salvando Causa do Reset na memoria nao volatil (NVS).");
    PW_ERROR_CHECK(initialize_nvs_flash_storage());
    PW_ERROR_CHECK(pw_save_reset_reason_nvs(esp_reset_reason()));

    // Sdcard
    esp_log_at_terminal(ROTULO_LOCAL, "Inicializando Cartao SD.");
    PW_ERROR_CHECK(initialize_sdcard());
    esp_log_at_terminal(ROTULO_LOCAL, "Inicializando BD em memoria.");
    PW_ERROR_CHECK(sdcard_persistence_init());

    // Reset reason
    PW_ERROR_CHECK(sdcard_log(LOG_WARN, get_reset_reason_string(esp_reset_reason()), ROTULO_LOCAL));
    PW_ERROR_CHECK(pw_log_event(PW_SEV_INFO, "BOOT", ROTULO_LOCAL, get_reset_reason_string(esp_reset_reason())));
    PW_ERROR_CHECK(pw_state_save_boot(esp_reset_reason(), pw_now_epoch()));

    // Inicia wifi e sincroniza relogio interno com data e hora atual pela rede
    PW_ERROR_CHECK(sdcard_log(LOG_INFO, "Cartao SD inicializado. Inicializando Wi-Fi", ROTULO_LOCAL));
    init_wifi();
    PW_ERROR_CHECK(start_date_time_routine());

    sdcard_log(LOG_INFO, "Wi-Fi inicializado com sucesso. Inicializando MQTT.", ROTULO_LOCAL);
    PW_ERROR_CHECK(init_mqtt_task());

    PW_ERROR_CHECK(sdcard_log(LOG_INFO, "Task MQTT inicializada com sucesso. Inicializando leitores HX711.", ROTULO_LOCAL));
    PW_ERROR_CHECK(hx711_initialize_sensors());

    PW_ERROR_CHECK(sdcard_log(LOG_INFO, "Sensores inicializados. Inicializando Tasks de SD Card e Sensores.", ROTULO_LOCAL));
    PW_ERROR_CHECK(init_sdcard_task());
    PW_ERROR_CHECK(init_sensors_task());

    PW_ERROR_CHECK(sdcard_log(LOG_INFO, "Tasks de SD Card e Sensores inicializadas. Inicalizando Timers.", ROTULO_LOCAL));
    PW_ERROR_CHECK(init_weight_sensors_timer()); // Inicia agendamento da pesagem do bebe se houver
    update_current_time();

    // Sisteam operante
    char m[90] = {0};
    snprintf(m, 90, "Sistema inicializado com sucesso em %s \r\n", current_time);
    PW_ERROR_CHECK(sdcard_log(LOG_INFO, m, ROTULO_LOCAL));
    PW_ERROR_CHECK(pw_state_save());
    PW_ERROR_CHECK(set_pattern_to_led_task(BLINK_LED_NORMAL_OPER));
}
