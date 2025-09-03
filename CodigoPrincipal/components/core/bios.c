#include "bios.h"

static const char *ROTULO_LOCAL = "BIOS";
hx711_t sensors[NUM_WEIGHT_SENSORS] = {0};

static void initialize_buzzers()
{
    buzzer_init();
    buzzer_long_beep(); // Ligando

    if (MODO_DEBUG)
    { // confirma que hardware iniciou usando led azul
        gpio_reset_pin(LED_GPIO);
        gpio_set_direction(LED_GPIO, GPIO_MODE_OUTPUT);
        gpio_set_level(LED_GPIO, 1);
    }
}

static esp_err_t initialize_sdcard()
{
    uint8_t retry_count = 0;
    const uint8_t max_retries = 3;
    esp_err_t ret = ESP_FAIL;
    do
    {
        sdcard_notify_uart(ROTULO_LOCAL, "Loop While");
        ret = sdcard_init();
        if (ret == ESP_OK)
        {
            ret = sdcard_log(LOG_INFO, "Testando Logs no Cartao SD ", ROTULO_LOCAL);
            if (ret == ESP_OK)
                break;

            sdcard_notify_uart(ROTULO_LOCAL, "Problema ao escrever Logs!!");
            buzzer_short_alert();
            vTaskDelay(pdMS_TO_TICKS(1000));
            retry_count++;
            continue;
        }

        sdcard_notify_uart(ROTULO_LOCAL, "Falha ao iniciar Cartao SD");
        buzzer_short_alert();
        retry_count++;
        vTaskDelay(pdMS_TO_TICKS(1000));
    } while (retry_count < max_retries);

    return ret;
}

static esp_err_t weight_sensors_routine(hx711_t *sensor, gpio_num_t dout, gpio_num_t sck)
{
    if (hx711_init(sensor, dout, sck, HX711_CHANNEL_A_128) != ESP_OK)
    {
        char msg[80];
        snprintf(msg, 80, "Falha ao inicializar sensor 1, portas: %d [OUT] e %d [CLK].", sensor->dout_pin, sensor->sck_pin);
        sdcard_log(LOG_ERROR, msg, ROTULO_LOCAL);
        return ESP_FAIL;
    }
    return ESP_OK;
}

static esp_err_t initialize_weight_sensors()
{
    int dout[4] = {SCALE1_DOUT, SCALE2_DOUT, SCALE3_DOUT, SCALE4_DOUT};
    int sck[4] = {SCALE1_SCK, SCALE2_SCK, SCALE3_SCK, SCALE4_SCK};
    uint32_t calib_factor[4] = {86UL, 123UL, 74UL, 116UL}; // estimados manualmente
    for (int i = 0; i < NUM_WEIGHT_SENSORS; i++)
    {
        sensors[i].id = i;
        sensors[i].calib_factor = calib_factor[i];
        if (weight_sensors_routine(&sensors[i], dout[i], sck[i]) != ESP_OK)
            return ESP_FAIL;
    }
    return ESP_OK;
}

weight_t measure_weight()
{
    sdcard_log(LOG_INFO, "Medindo peso agendado", ROTULO_LOCAL);
    weight_t weight;
    weight.raw_value = 0UL;
    weight.value = 0.0;

    for (int i = 0; i < NUM_WEIGHT_SENSORS; i++)
    {
        int32_t average_raw = hx711_read_average(&sensors[i], WEIGHT_NUMBER_TO_AVERAGE);
        weight.raw_value += average_raw;
        // offset = tara. Supondo o valor da medida na tara é 5000 e o valor agora é 8000, o delta bruto é 3000
        //  se eu calibrei com um peso conhecido, ou seja, eu sei que 3000 é 998 gramas, multiplico
        //  ((raw_value - raw_offset)  /calib_factor) * scale_in_grams =>
        int32_t dividend = (sensors[i].calib_factor != 0) ? sensors[i].calib_factor : 1;
        weight.value += ((average_raw - sensors[i].offset) / dividend) * scale_in_grams;
    }

    weight.raw_value /= NUM_WEIGHT_SENSORS;
    weight.value /= NUM_WEIGHT_SENSORS;
    return weight;
}

void init_hardware()
{
    initialize_buzzers();
    sdcard_notify_uart(ROTULO_LOCAL, "Buzzer inicializado. Inicializando Cartao SD.");

    esp_err_t ret = initialize_sdcard();
    if (ret != ESP_OK)
        buzzer_critical_alert();

    sdcard_log(LOG_INFO, "Cartao SD inicializado. Inicializando sensores HX711.", ROTULO_LOCAL);
    ESP_ERROR_CHECK(initialize_weight_sensors());

    sdcard_log(LOG_INFO, "Sensores inicializados.", ROTULO_LOCAL);
}