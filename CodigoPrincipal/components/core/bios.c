#include "bios.h"
#include "tasks.h"

static const char *ROTULO_LOCAL = "BIOS";

hx711_t scale1, scale2, scale3, scale4;
hx711_t sensores[NUM_SENSORES_PESO];

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
        notify_uart(ROTULO_LOCAL, "Loop While");
        ret = sdcard_init();
        if (ret == ESP_OK)
        {
            ret = sdcard_log(LOG_INFO, "Testando Logs no Cartao SD ", ROTULO_LOCAL);
            if (ret == ESP_OK)
                break;

            notify_uart(ROTULO_LOCAL, "Problema ao escrever Logs!!");
            buzzer_short_alert();
            vTaskDelay(pdMS_TO_TICKS(1000));
            retry_count++;
            continue;
        }

        notify_uart(ROTULO_LOCAL, "Falha ao iniciar Cartao SD");
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
        snprintf(msg, 80, "Falha ao inicializar sensor 1, portas: %d [OUT] e %d [CLK].", SCALE1_DOUT, SCALE1_SCK);
        sdcard_log(LOG_ERROR, msg, ROTULO_LOCAL);
        return ESP_FAIL;
    }
    hx711_tare(sensor, 10);
    return ESP_OK;
}

static esp_err_t initialize_weight_sensors()
{
    // 2. Inicializa Sensores
    scale1.sensor_id = 1;
    if (weight_sensors_routine(&scale1, SCALE1_DOUT, SCALE1_SCK) != ESP_OK)
        return ESP_FAIL;
    scale2.sensor_id = 2;
    if (weight_sensors_routine(&scale2, SCALE2_DOUT, SCALE2_SCK) != ESP_OK)
        return ESP_FAIL;
    scale3.sensor_id = 3;
    if (weight_sensors_routine(&scale3, SCALE3_DOUT, SCALE3_SCK) != ESP_OK)
        return ESP_FAIL;
    scale4.sensor_id = 4;
    if (weight_sensors_routine(&scale4, SCALE4_DOUT, SCALE4_SCK) != ESP_OK)
        return ESP_FAIL;

    // Aqui pode ter algum algoritmo pra validar a pesagem dos sensores
    sensores[0] = scale1;
    sensores[1] = scale2;
    sensores[2] = scale3;
    sensores[3] = scale4;

    return ESP_OK;
}

void init_hardware()
{
    initialize_buzzers();
    notify_uart(ROTULO_LOCAL, "Buzzer inicializado. Inicializando Cartao SD.");

    esp_err_t ret = initialize_sdcard();
    if (ret != ESP_OK)
        buzzer_critical_alert();

    sdcard_log(LOG_INFO, "Cartao SD inicializado. Inicializando sensores HX711.", ROTULO_LOCAL);
    ESP_ERROR_CHECK(initialize_weight_sensors());

    sdcard_log(LOG_INFO, "Sensores inicializados.", ROTULO_LOCAL);
}