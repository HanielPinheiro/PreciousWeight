#include "buzzer.h"

void buzzer_init()
{
    gpio_reset_pin(BUZZER_GPIO);
    gpio_set_direction(BUZZER_GPIO, GPIO_MODE_OUTPUT);
    gpio_set_level(BUZZER_GPIO, 0);
}

void buzzer_short_beep()
{
    gpio_set_level(BUZZER_GPIO, 1);
    vTaskDelay(pdMS_TO_TICKS(SHORT_TIME));
    gpio_set_level(BUZZER_GPIO, 0);
}

void buzzer_long_beep()
{
    gpio_set_level(BUZZER_GPIO, 1);
    vTaskDelay(pdMS_TO_TICKS(LONG_TIME));
    gpio_set_level(BUZZER_GPIO, 0);
}
