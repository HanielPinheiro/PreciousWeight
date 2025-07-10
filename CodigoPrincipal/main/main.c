#include "main.h"

// Define pins for 4 sensors
#define SCALE1_DOUT GPIO_NUM_13
#define SCALE1_SCK GPIO_NUM_14

#define SCALE2_DOUT GPIO_NUM_16
#define SCALE2_SCK GPIO_NUM_17

#define SCALE3_DOUT GPIO_NUM_32
#define SCALE3_SCK GPIO_NUM_33

#define SCALE4_DOUT GPIO_NUM_25
#define SCALE4_SCK GPIO_NUM_26

#define LED_GPIO GPIO_NUM_2

// Create 4 HX711 device structs
hx711_t scale1, scale2, scale3, scale4;

void app_main(void)
{
    setup();
    loop();
}

void setup()
{
    setup_blink();
    setup_hx711();
    setup_sdcard();
    setup_mqtt();
    setup_blufi();
}

void loop()
{
    while (1)
    {
        loop_blink();
        loop_hx711();
    }
}

#pragma region SetupFunctions

void setup_blink()
{ // BlinkLed
    gpio_reset_pin(LED_GPIO);
    gpio_set_direction(LED_GPIO, GPIO_MODE_OUTPUT);
    gpio_set_level(LED_GPIO, 0);
}

void setup_hx711()
{ // Initialize each HX711
    hx711_init(&scale1, SCALE1_DOUT, SCALE1_SCK, HX711_CHANNEL_A_128);
    hx711_init(&scale2, SCALE2_DOUT, SCALE2_SCK, HX711_CHANNEL_A_128);
    hx711_init(&scale3, SCALE3_DOUT, SCALE3_SCK, HX711_CHANNEL_A_128);
    hx711_init(&scale4, SCALE4_DOUT, SCALE4_SCK, HX711_CHANNEL_A_128);
}

void setup_sdcard()
{
}

void setup_mqtt()
{
}

void setup_blufi()
{
}

#pragma endregion

#pragma region LoopFunctions

void loop_blink()
{
    gpio_set_level(LED_GPIO, 1);
    vTaskDelay(pdMS_TO_TICKS(500));
    gpio_set_level(LED_GPIO, 0);
}

void loop_hx711()
{
    int32_t v1 = hx711_read(&scale1, pdMS_TO_TICKS(100));
    int32_t v2 = hx711_read(&scale2, pdMS_TO_TICKS(100));
    int32_t v3 = hx711_read(&scale3, pdMS_TO_TICKS(100));
    int32_t v4 = hx711_read(&scale4, pdMS_TO_TICKS(100));

    printf("Scale 1: %ld\t", (long)v1);
    printf("Scale 2: %ld\t", (long)v2);
    printf("Scale 3: %ld\t", (long)v3);
    printf("Scale 4: %ld\n", (long)v4);

    vTaskDelay(pdMS_TO_TICKS(500));
}

void loop_sdcard()
{
}

void loop_mqtt()
{
}

void loop_blufi()
{
}

#pragma endregion