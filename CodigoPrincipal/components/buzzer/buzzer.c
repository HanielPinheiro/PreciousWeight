#include "buzzer.h"

#define BUZZER_GPIO GPIO_NUM_18
#define FAST_TIME 600
#define SLOW_TIME 200

void buzzer_fast_beep(void)
{
    gpio_set_level(BUZZER_GPIO, 1);
    vTaskDelay(pdMS_TO_TICKS(FAST_TIME));
    gpio_set_level(BUZZER_GPIO, 0);
}

void buzzer_slow_beep(void)
{
    gpio_set_level(BUZZER_GPIO, 1);
    vTaskDelay(pdMS_TO_TICKS(SLOW_TIME));
    gpio_set_level(BUZZER_GPIO, 0);
}
