#include "hx711.h"

// static const char *ROTULO_LOCAL = "HX711";

/**
 * Esp32 PIN SCK = Output, HX711 PIN SCK = INPUT (Clock comes from uC)
 * Esp32 PIN DOUT = INPUT, HX711 PIN DOUT = Output (Data processed from sensors)
 */

esp_err_t hx711_init(hx711_t *dev, gpio_num_t dout, gpio_num_t sck, hx711_mode_t mode)
{
    if (!dev)
        return ESP_ERR_INVALID_ARG;

    dev->dout_pin = dout;
    dev->sck_pin = sck;
    dev->clock_cycles_from_mode = (int)mode;
    dev->offset = 0;
    dev->scale = 1.0f;

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

    // Dummy read to clear/reset
    hx711_read_raw(dev);

    return ESP_OK;
}

int32_t hx711_read_raw(hx711_t *dev)
{
    /**
    * Por que removi timeout_ticks?
      Motivo: Essa mudança foi didática. Na prática:
        Seu uso original (while (gpio_get_level() == 1)) pode travar o sistema se o sensor falhar.
        Em dispositivos médicos, timeouts fixos são perigosos (ex.: se o bebê estiver na balança e o sensor travar, o sistema deve continuar operando).
        Posteriormente, vamos substituir por filas (queues) e timeouts supervisionados pelo system manager.
    */

    int32_t data = 0;
    for (int i = 0; i < dev->clock_cycles_from_mode; i++)
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

float hx711_read_weight(hx711_t *dev)
{
    return (hx711_read_raw(dev) - dev->offset) * dev->scale;
}

void hx711_tare(hx711_t *dev, uint8_t samples)
{
    int32_t sum = 0;
    for (uint8_t i = 0; i < samples; i++)
    {
        sum += hx711_read_raw(dev);
        vTaskDelay(pdMS_TO_TICKS(10));
    }
    dev->offset = sum / samples;
}