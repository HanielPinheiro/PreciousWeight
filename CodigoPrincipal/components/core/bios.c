#include "bios.h"

static const char *ROTULO_LOCAL = "BIOS";
hx711_t sensors[NUM_WEIGHT_SENSORS] = {0};

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
    // uint32_t calib_factor[4] = {86UL, 123UL, 74UL, 116UL}; // estimados manualmente
    uint32_t calib_factor[4] = {315UL, 315UL, 240UL, 315UL}; // estimados manualmente
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
    esp_log_at_terminal(ROTULO_LOCAL, "Inicializando Cartao SD.");

    initialize_sdcard();

    sdcard_log(LOG_INFO, "Cartao SD inicializado. Inicializando sensores HX711.", ROTULO_LOCAL);
    ESP_ERROR_CHECK(initialize_weight_sensors());

    sdcard_log(LOG_INFO, "Sensores inicializados.", ROTULO_LOCAL);
}