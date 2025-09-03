#include "hx711.h"

static const char *ROTULO_LOCAL = "HX711 DRIVER";
float scale_in_grams = 1000.0;
/**
 * Esp32 PIN SCK = Output, HX711 PIN SCK = INPUT (Clock comes from uC)
 * Esp32 PIN DOUT = INPUT, HX711 PIN DOUT = Output (Data processed from sensors)
 */

esp_err_t hx711_init(hx711_t *sensor, gpio_num_t dout, gpio_num_t sck, hx711_mode_t mode)
{
    if (!sensor)
        return ESP_ERR_INVALID_ARG;

    sensor->dout_pin = dout;
    sensor->sck_pin = sck;
    sensor->clock_cycles_from_mode = (int)mode;
    sensor->offset = 0;

    // Configure DOUT as input
    gpio_config_t dout_conf = {
        .pin_bit_mask = 1ULL << dout,
        .mode = GPIO_MODE_INPUT,
        .pull_up_en = GPIO_PULLUP_DISABLE,
        .pull_down_en = GPIO_PULLDOWN_DISABLE,
        .intr_type = GPIO_INTR_DISABLE,
    };
    ESP_ERROR_CHECK(gpio_config(&dout_conf));

    // Configure SCK as output
    gpio_config_t sck_conf = {
        .pin_bit_mask = 1ULL << sck,
        .mode = GPIO_MODE_OUTPUT,
        .pull_up_en = GPIO_PULLUP_DISABLE,
        .pull_down_en = GPIO_PULLDOWN_DISABLE,
        .intr_type = GPIO_INTR_DISABLE,
    };
    ESP_ERROR_CHECK(gpio_config(&sck_conf));
    gpio_set_level(sck, 0); // idle low

    return ESP_OK;
}

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

int32_t hx711_read_raw(hx711_t *sensor)
{
    // The HX711 data sheet says that the DOUT pin will go high when it is not ready, and low when it is ready.
    int32_t data = 0;
    for (int i = 0; i < sensor->clock_cycles_from_mode; i++)
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

    // Convert from 24-bit signed to 32-bit signed
    if (data & 0x800000)
        data |= 0xFF000000;

    return data;
}

int32_t hx711_read_average(hx711_t *sensor, uint8_t samples)
{
    int32_t mean = 0;
    int8_t count = 0;
    while (count < samples)
    {
        int32_t reading = hx711_read_raw(sensor);

        if (reading != -1)
        {
            count++;
            mean += (reading - mean) / count;
        }

        vTaskDelay(pdMS_TO_TICKS(100));
    }
    return mean;
}
void hx711_tare(hx711_t *sensor, uint8_t samples)
{
    sensor->offset = hx711_read_average(sensor, samples);
    ESP_LOGI(ROTULO_LOCAL, "Tara da Balança:Samples=%d, Offset=%ld", samples, sensor->offset);
}

int32_t hx711_read_units(hx711_t *sensor, uint8_t samples)
{
    int32_t diff = hx711_read_average(sensor, samples) - sensor->offset;
    ESP_LOGI(ROTULO_LOCAL, "Sensor:%d;Diff:%ld", sensor->id, diff);
    return diff < 0 ? (diff * -1) : diff;
}

int32_t hx711_read_weight(hx711_t *sensor, uint8_t samples)
{
    ESP_LOGI(ROTULO_LOCAL, "Sensor:%d;CalibFactor:%ld", sensor->id, sensor->calib_factor);
    return hx711_read_units(sensor, samples) / sensor->calib_factor;
}
