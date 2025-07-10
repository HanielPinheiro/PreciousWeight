#include "hx711.h"

static const char *TAG = "HX711";

esp_err_t hx711_init(hx711_t *dev, gpio_num_t dout, gpio_num_t sck, hx711_mode_t mode)
{
    if (!dev)
        return ESP_ERR_INVALID_ARG;

    dev->sck_pin = sck;
    dev->dout_pin = dout;
    dev->clock_cycles = (int)mode;

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

    // Configure DOUT as input
    gpio_config_t dout_conf = {
        .pin_bit_mask = 1ULL << dout,
        .mode = GPIO_MODE_INPUT,
        .pull_up_en = GPIO_PULLUP_DISABLE,
        .pull_down_en = GPIO_PULLDOWN_DISABLE,
        .intr_type = GPIO_INTR_DISABLE,
    };
    ESP_ERROR_CHECK(gpio_config(&dout_conf));

    // Dummy read to clear/reset
    hx711_read(dev, pdMS_TO_TICKS(1000));

    return ESP_OK;
}

int32_t hx711_read(hx711_t *dev, TickType_t timeout_ticks)
{
    int count = 0;
    while (gpio_get_level(dev->dout_pin) == 1)
    {
        if (count++ > timeout_ticks)
        {
            ESP_LOGE(TAG, "Timeout waiting for DOUT to go LOW");
            return HX711_UNDEFINED;
        }
        vTaskDelay(1);
    }

    esp_rom_delay_us(5);

    int32_t data = 0;
    for (int i = 0; i < dev->clock_cycles; i++)
    {
        gpio_set_level(dev->sck_pin, 1);
        esp_rom_delay_us(1);

        if (i < 24)
        {
            data = data << 1;
            if (gpio_get_level(dev->dout_pin))
            {
                data++;
            }
        }

        gpio_set_level(dev->sck_pin, 0);
        esp_rom_delay_us(1);
    }

    // Convert from 24-bit signed to 32-bit signed
    if (data & 0x800000)
    {
        data |= 0xFF000000;
    }

    return data;
}
