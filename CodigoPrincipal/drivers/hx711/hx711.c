#include "../../config/config.h"

static const char *ROTULO_LOCAL = "HX711 DRIVER";
static portMUX_TYPE s_hx711_mux = portMUX_INITIALIZER_UNLOCKED;

#pragma region Initialize

static esp_err_t setup_hx711(hx711_t *sensor)
{
    if (!sensor)
        return ESP_ERR_INVALID_ARG;

    // Configure DOUT as input
    gpio_config_t dout_conf = {
        .pin_bit_mask = 1ULL << sensor->dout_pin,
        .mode = GPIO_MODE_INPUT,
        .pull_up_en = GPIO_PULLUP_DISABLE,
        .pull_down_en = GPIO_PULLDOWN_DISABLE,
        .intr_type = GPIO_INTR_DISABLE,
    };
    ESP_ERROR_CHECK(gpio_config(&dout_conf));

    // Configure SCK as output
    gpio_config_t sck_conf = {
        .pin_bit_mask = 1ULL << sensor->sck_pin,
        .mode = GPIO_MODE_OUTPUT,
        .pull_up_en = GPIO_PULLUP_DISABLE,
        .pull_down_en = GPIO_PULLDOWN_DISABLE,
        .intr_type = GPIO_INTR_DISABLE,
    };
    ESP_ERROR_CHECK(gpio_config(&sck_conf));

    gpio_set_level(sensor->sck_pin, 0); // idle low
    return ESP_OK;
}

esp_err_t initialize_hx711_sensors()
{
    for (int i = 0; i < NUM_WEIGHT_SENSORS; i++)
    {
        char msg[80];
        if (setup_hx711(&sensors[i]) != ESP_OK)
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

#pragma endregion

#pragma region Hx711 Check health

static inline bool hx711_is_ready(const hx711_t *sensor)
{
    return gpio_get_level(sensor->dout_pin) == 0;
}

static esp_err_t hx711_wait_ready_timeout(hx711_t *sensor, uint32_t timeout_ms)
{
    TickType_t start_ticks = xTaskGetTickCount();
    TickType_t timeout_ticks = pdMS_TO_TICKS(timeout_ms);

    while (!hx711_is_ready(sensor))
    {
        if ((xTaskGetTickCount() - start_ticks) > timeout_ticks)
            return ESP_ERR_TIMEOUT;
        vTaskDelay(pdMS_TO_TICKS(10));
    }
    return ESP_OK;
}

#pragma endregion

#pragma region Read Raw, Average, Tare

static int32_t hx711_read_raw(hx711_t *sensor)
{
    if (!sensor)
        return HX711_INVALID_READING;

    if (hx711_wait_ready_timeout(sensor, 200) != ESP_OK)
        return HX711_INVALID_READING;

    int32_t data = 0;
    portENTER_CRITICAL(&s_hx711_mux);
    for (int i = 0; i < HX711_CHANNEL_A_128; i++)
    {
        gpio_set_level(sensor->sck_pin, 1);
        esp_rom_delay_us(1);

        if (i < 24)
        {
            data = data << 1;
            if (gpio_get_level(sensor->dout_pin))
                data++;
        }
        gpio_set_level(sensor->sck_pin, 0);
        esp_rom_delay_us(1);
    }
    portEXIT_CRITICAL(&s_hx711_mux);

    // Convert from 24-bit signed to 32-bit signed
    if (data & 0x800000)
        data |= 0xFF000000;

    return data;
}

static int32_t hx711_read_average(hx711_t *sensor, uint8_t samples)
{
    if (!sensor || samples == 0)
        return HX711_INVALID_READING;

    int64_t sum = 0;
    uint8_t count = 0;
    uint16_t invalid_count = 0;

    while (count < samples)
    {
        int32_t reading = hx711_read_raw(sensor);
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

#pragma endregion

#pragma region Weight

weight_t hx711_read_sensor_weight(hx711_t *sensor)
{
    int32_t raw = hx711_read_average(sensor, AVERAGE_NUMBER);
    if (raw == HX711_INVALID_READING)
    {
        // Leitura inválida: retorna sentinela e deixa a camada de monitoramento (sensors_task)
        // decidir quando logar/acionar falha com base em streak/timeout.
        weight_t invalid = {.raw_value = HX711_INVALID_READING, .value = 0};
        return invalid;
    }

    int32_t diff = raw - sensor->offset;
    double weight = diff / sensor->calib_factor;

    if (weight >= 3000.0)
        weight *= 0.99; // coreção de fator exponencial / logaritmico

    // if (weight < sensor->invalid_limit)
    //     return 0;

    if (MODO_DEBUG)
    {
        ESP_LOGI(ROTULO_LOCAL, "Sensor[%d]:Raw{%ld}|Offset{%ld}|Diff{%ld}|Weight{%f}",
                 sensor->id, raw, sensor->offset, diff, weight);
    }

    weight_t sensor_weight = {.raw_value = diff, .value = (int32_t)weight};
    return sensor_weight;
}

#pragma endregion