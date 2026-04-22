#include "hx711.h"

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

esp_err_t initialize_weight_sensors()
{
    for (int i = 0; i < NUM_WEIGHT_SENSORS; i++)
    {
        if (setup_hx711(&sensors[i]) != ESP_OK)
        {
            char msg[80];
            snprintf(msg, 80, "Falha ao inicializar sensor %d, portas: %d [DOUT] e %d [SCK].", i, &sensors[i]->dout_pin, &sensors[i]->sck_pin);
            sdcard_log(LOG_ERROR, msg, ROTULO_LOCAL);
            return ESP_FAIL;
        }
        return ESP_OK;
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
    // Verifica se o sensor apresentou algum problema
    TickType_t start_ticks = xTaskGetTickCount();
    TickType_t timeout_ticks = pdMS_TO_TICKS(timeout_ms);
    while (!hx711_is_ready(sensor))
    {
        if ((xTaskGetTickCount() - start_ticks) > timeout_ticks)
            return ESP_ERR_TIMEOUT;
        vTaskDelay(pdMS_TO_TICKS(1));
    }
    return ESP_OK;
}

#pragma endregion

int32_t hx711_read_raw(hx711_t *sensor)
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

int32_t hx711_read_average(hx711_t *sensor, uint8_t samples)
{
    if (!sensor || samples == 0)
        return HX711_INVALID_READING;

    int32_t mean = 0;
    uint8_t count = 0;
    uint16_t invalid_count = 0;
    while (count < samples)
    {
        int32_t reading = hx711_read_raw(sensor);

        if (reading != HX711_INVALID_READING)
        {
            count++;
            mean += (reading - mean) / count;
        }
        else
        {
            invalid_count++;
            if (invalid_count > samples)
                break;
        }
    }
    return (count == samples) ? mean : HX711_INVALID_READING;
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
    sensor->offset = value;
    ESP_LOGI(ROTULO_LOCAL, "Tara da Balança:Samples=%d, Offset=%ld", TARE_NUMBER, sensor->offset);
}

static int32_t hx711_read_weight(hx711_t *sensor)
{
    ESP_LOGI(ROTULO_LOCAL, "Sensor:%d;CalibFactor:%f", sensor->id, sensor->calib_factor);
    int32_t diff = hx711_read_average(sensor, AVERAGE_NUMBER) - sensor->offset;
    ESP_LOGI(ROTULO_LOCAL, "Sensor:%d;Diff:%ld", sensor->id, diff);

    double weight = diff / sensor->calib_factor;
    if (weight >= 3000.0)
        weight *= 0.99; // coreção de fator exponencial / logaritmico

    // if (weight < sensor->invalid_limit)
    //     return 0;

    return (int32_t)weight;
}

int32_t measure_weight()
{
    return 0;
    // ESP_LOGI(ROTULO_LOCAL, "Sensor:%d;CalibFactor:%f", sensor->id, sensor->calib_factor);
    // int32_t diff = hx711_read_average(sensor, AVERAGE_NUMBER) - sensor->offset;
    // ESP_LOGI(ROTULO_LOCAL, "Sensor:%d;Diff:%ld", sensor->id, diff);

    // double weight = diff / sensor->calib_factor;
    // if (weight >= 3000.0)
    //     weight *= 0.99; // coreção de fator exponencial / logaritmico

    // // if (weight < sensor->invalid_limit)
    // //     return 0;

    // return (int32_t)weight;
}

/* Loop => task
pesoCalculado = readWeightOriginal(active_sensor);
if (!isValidReading(pesoCalculado, active_sensor))
    Serial.print(" [INVÁLIDO - Re-tarando...]");
*/

#pragma region Control Power State

// esp_err_t hx711_power_on(hx711_t *sensor)
// {
//     gpio_set_level(sensor->sck_pin, 0);
//     vTaskDelay(pdMS_TO_TICKS(5));
//     if (!hx711_is_ready(sensor))
//     {
//         gpio_set_level(sensor->dout_pin, 0);
//         vTaskDelay(pdMS_TO_TICKS(5));
//         if (hx711_is_ready(sensor) == false)
//             return ESP_ERR_NOT_FINISHED;
//     }
//     return ESP_OK;
// }

// esp_err_t hx711_power_down(hx711_t *sensor)
// {
//     for (int i = 0; i < NUM_WEIGHT_SENSORS; i++)
//     {
//         gpio_set_level(sensor->sck_pin, 0);
//         vTaskDelay(pdMS_TO_TICKS(1));

//         gpio_set_level(sensor->sck_pin, 1);
//         vTaskDelay(pdMS_TO_TICKS(1));

//         if (hx711_is_ready(sensor) == true)
//             return ESP_ERR_NOT_FINISHED;
//     }
//     return ESP_OK;
// }

#pragma endregion

#pragma region Kalman Filter

// Variáveis de estado do Kalman por sensor
// float kalmanEstimate[NUM_SENSORS] = {0};
// float kalmanErrorCov[NUM_SENSORS] = {1};
// const float PROCESS_NOISE = 0.1;
// const float MEASUREMENT_NOISE = 5.0;

// float readWeight(int sensorIndex, bool useKalman) {
//     SensorConfig &sensor = sensors[sensorIndex];

//     float raw_weight = readWeightOriginal(sensorIndex);

//     if (!useKalman) {
//         return raw_weight;
//     }

//     return kalmanFilter(raw_weight, kalmanEstimate[sensorIndex],
//                         kalmanErrorCov[sensorIndex], PROCESS_NOISE, MEASUREMENT_NOISE);
// }
// float kalmanFilter(float measurement, float &estimate, float &error_covariance,
//                    float process_noise, float measurement_noise)
// {
//     // Predição
//     float predicted_estimate = estimate;
//     float predicted_error_covariance = error_covariance + process_noise;

//     // Atualização
//     float kalman_gain = predicted_error_covariance / (predicted_error_covariance + measurement_noise);
//     estimate = predicted_estimate + kalman_gain * (measurement - predicted_estimate);
//     error_covariance = (1 - kalman_gain) * predicted_error_covariance;

//     return estimate;
// }

#pragma endregion
