#include "../../config/config.h"

static const char *ROTULO_LOCAL = "HX711 DRIVER";
static portMUX_TYPE s_hx711_mux = portMUX_INITIALIZER_UNLOCKED;

#pragma region static / private

static esp_err_t hx711_setup(gpio_num_t dout_pin, gpio_num_t sck_pin)
{
    // Configure DOUT as input
    gpio_config_t dout_conf = {
        .pin_bit_mask = 1ULL << dout_pin,
        .mode = GPIO_MODE_INPUT,
        .pull_up_en = GPIO_PULLUP_DISABLE,
        .pull_down_en = GPIO_PULLDOWN_DISABLE,
        .intr_type = GPIO_INTR_DISABLE,
    };
    ESP_ERROR_CHECK(gpio_config(&dout_conf));

    // Configure SCK as output
    gpio_config_t sck_conf = {
        .pin_bit_mask = 1ULL << sck_pin,
        .mode = GPIO_MODE_OUTPUT,
        .pull_up_en = GPIO_PULLUP_DISABLE,
        .pull_down_en = GPIO_PULLDOWN_DISABLE,
        .intr_type = GPIO_INTR_DISABLE,
    };
    ESP_ERROR_CHECK(gpio_config(&sck_conf));

    gpio_set_level(sck_pin, 0); // idle low
    return ESP_OK;
}

static esp_err_t hx711_wait_ready_timeout(gpio_num_t dout_pin, uint32_t timeout_ms)
{
    TickType_t start_ticks = xTaskGetTickCount();
    TickType_t timeout_ticks = pdMS_TO_TICKS(timeout_ms);

    while (!gpio_get_level(dout_pin) == 0)
    {
        if ((xTaskGetTickCount() - start_ticks) > timeout_ticks)
            return ESP_ERR_TIMEOUT;
        vTaskDelay(pdMS_TO_TICKS(10));
    }
    return ESP_OK;
}

static int32_t hx711_read_raw(gpio_num_t dout_pin, gpio_num_t sck_pin)
{
    if (hx711_wait_ready_timeout(dout_pin, 200) != ESP_OK)
        return HX711_INVALID_READING;

    int32_t data = 0;
    portENTER_CRITICAL(&s_hx711_mux);
    for (int i = 0; i < HX711_CHANNEL_A_128; i++)
    {
        gpio_set_level(sck_pin, 1);
        esp_rom_delay_us(1);

        if (i < 24)
        {
            data = data << 1;
            if (gpio_get_level(dout_pin))
                data++;
        }
        gpio_set_level(sck_pin, 0);
        esp_rom_delay_us(1);
    }
    portEXIT_CRITICAL(&s_hx711_mux);

    // Convert from 24-bit signed to 32-bit signed
    if (data & 0x800000)
        data |= 0xFF000000;

    return data;
}

static int32_t hx711_read_average(gpio_num_t dout_pin, gpio_num_t sck_pin, uint8_t samples)
{
    int64_t sum = 0;
    uint8_t count = 0;
    uint16_t invalid_count = 0;

    while (count < samples)
    {
        int32_t reading = hx711_read_raw(dout_pin, sck_pin);
        if (reading != HX711_INVALID_READING)
        {
            sum += reading;
            count++;
        }
        else
        {
            invalid_count++;
            if (invalid_count > samples)
                break;
        }
    }
    return (count == samples) ? (int32_t)(sum / samples) : HX711_INVALID_READING;
}
#pragma endregion

#pragma region public

esp_err_t hx711_initialize_sensors()
{
    for (int i = 0; i < NUM_WEIGHT_SENSORS; i++)
    {
        if (!&sensors[i])
            return ESP_ERR_INVALID_ARG;

        char msg[80];
        if (hx711_setup(sensors[i].dout_pin, sensors[i].sck_pin) != ESP_OK)
        {
            snprintf(msg, sizeof(msg), "Falha ao inicializar sensor %d, portas: %d [DOUT] e %d [SCK].", i, (int)sensors[i].dout_pin, (int)sensors[i].sck_pin);
            sdcard_log(LOG_ERROR, msg, ROTULO_LOCAL);
            return ESP_FAIL;
        }
        snprintf(msg, sizeof(msg), "Sensor %d inicializado, portas: %d [DOUT] e %d [SCK].", i, (int)sensors[i].dout_pin, (int)sensors[i].sck_pin);
        sdcard_log(LOG_INFO, msg, ROTULO_LOCAL);

        hx711_tare(&sensors[i]);
        snprintf(msg, sizeof(msg), "Sensor %d TARA REALIZADA", i);
        sdcard_log(LOG_INFO, msg, ROTULO_LOCAL);
    }
    // Aguarda dois segundos para estabilização térmica dos sensores
    vTaskDelay(pdMS_TO_TICKS(2000));
    return ESP_OK;
}
void hx711_tare(hx711_t *sensor)
{
    int8_t try = 0;
    int32_t value = HX711_INVALID_READING;
    while (value == HX711_INVALID_READING && try < 3)
    {
        value = hx711_read_average(sensor, TARE_NUMBER);
        try++;
    }

    if (value == HX711_INVALID_READING)
    {
        value = 0; // se a leitura for ruim, usa zero de offset
        ESP_LOGW(ROTULO_LOCAL, "Falha na tara, usando offset 0");
    }

    sensor->offset = value;
    ESP_LOGI(ROTULO_LOCAL, "Tara da Balança:Samples=%d, Offset=%ld", TARE_NUMBER, sensor->offset);
}

int32_t hx711_read_sensor_weight(int8_t id)
{
    hx711_t *sensor = hx711_get_sensor(id);
    int32_t raw = hx711_read_average(sensor->dout_pin, sensor->sck_pin, AVERAGE_NUMBER);
    if (raw == HX711_INVALID_READING)
        return HX711_INVALID_READING;
    int32_t diff = raw - sensor->offset;

    if (MODO_DEBUG)
        ESP_LOGI(ROTULO_LOCAL, "Sensor[%d]:Raw{%ld}|Offset{%ld}|Diff{%ld}", id, raw, sensor->offset, diff);

    return diff;
}

#pragma endregion