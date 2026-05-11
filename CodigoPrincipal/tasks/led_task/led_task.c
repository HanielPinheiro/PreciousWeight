#include "../../config/config.h"

static QueueHandle_t led_queue = NULL;

typedef struct
{ // Pattern definitions (timings in milliseconds)
    const uint16_t on_time_ms;
    const uint16_t off_time_ms;
    const uint8_t repeat_count; // 0 = infinite
} pattern_step_t;

typedef struct
{
    led_pattern_t pattern;
    const pattern_step_t *steps;
    uint8_t num_steps;
} pattern_step;

// OPERAÇÃO NORMAL -> LED DESLIGADO
static const pattern_step_t pattern_normal[] = {{0, UINT16_MAX, 0}};

// ERRO CRITICO -> LED LIGADO O TEMPO TODO
static const pattern_step_t pattern_critical_error[] = {{UINT16_MAX, 0, 0}};

// INICIALIZANDO TASKS (PISCANDO LENTO)
static const pattern_step_t pattern_task_initializer[] = {{500, 1500, 0}};

// PISCADA 2x E DELAY -> OK
static const pattern_step_t pattern_events[] = {{100, 100, 1}, {100, 300, 0}};

// PISCADA 5x E DELAY -> ERRO
static const pattern_step_t pattern_events_error[] = {{100, 100, 4}, {100, 300, 0}};

static const pattern_step pattern_db[] = {
    {BLINK_LED_NORMAL_OPER, pattern_normal, 1},
    {BLINK_LED_CRITICAL_ERROR, pattern_critical_error, 1},
    {BLINK_LED_STARTING_TASKS, pattern_task_initializer, 1},
    {BLINK_LED_EVENTS, pattern_events, 2},
    {BLINK_LED_EVENTS_ERROR, pattern_events_error, 2},
};

static void led_task(void *arg)
{
    gpio_set_direction(LED_GPIO, GPIO_MODE_OUTPUT);
    gpio_set_level(LED_GPIO, LED_LOW_LEVEL); // start with off

    led_pattern_t current_pattern = BLINK_LED_NORMAL_OPER;
    const pattern_step_t *steps = pattern_normal;
    uint8_t num_steps = 1;
    uint8_t step_idx = 0;
    uint8_t repeat_counter = 0;
    TickType_t next_change = 0;

    led_pattern_t pattern;
    while (1)
    {
        // Wait for either a new pattern command or the next step timeout
        TickType_t wait_ms = (next_change > xTaskGetTickCount()) ? (next_change - xTaskGetTickCount()) : portMAX_DELAY;
        if (xQueueReceive(led_queue, &pattern, pdMS_TO_TICKS(wait_ms)) == pdTRUE)
        {
            // New pattern requested
            current_pattern = pattern;
            // Find steps in database
            for (int i = 0; i < sizeof(pattern_db) / sizeof(pattern_db[0]); i++)
            {
                if (pattern_db[i].pattern == current_pattern)
                {
                    steps = pattern_db[i].steps;
                    num_steps = pattern_db[i].num_steps;
                    break;
                }
            }
            step_idx = 0;
            repeat_counter = 0;
            // Set initial LED state immediately
            if (steps[step_idx].on_time_ms > 0)
                gpio_set_level(LED_GPIO, LED_HIGH_LEVEL);
            else
                gpio_set_level(LED_GPIO, LED_LOW_LEVEL);

            next_change = xTaskGetTickCount() + pdMS_TO_TICKS(steps[step_idx].on_time_ms ? steps[step_idx].on_time_ms : steps[step_idx].off_time_ms);
        }

        // Time to advance to next step
        if (xTaskGetTickCount() >= next_change)
        {
            step_idx++;
            if (step_idx >= num_steps)
            {
                step_idx = 0;
                repeat_counter++;
                const pattern_step_t *last_step = &steps[num_steps - 1];
                if (last_step->repeat_count != 0 && repeat_counter >= last_step->repeat_count)
                {
                    // End of pattern, stay in last state? We'll just repeat from start.
                    repeat_counter = 0;
                }
            }
            // Apply new step
            const pattern_step_t *step = &steps[step_idx];
            if (step->on_time_ms > 0)
                gpio_set_level(LED_GPIO, LED_HIGH_LEVEL);
            else
                gpio_set_level(LED_GPIO, LED_LOW_LEVEL);

            next_change = xTaskGetTickCount() + pdMS_TO_TICKS(step->on_time_ms ? step->on_time_ms : step->off_time_ms);
        }
    }
}

esp_err_t led_indicator_start(void)
{
    led_queue = xQueueCreate(5, sizeof(led_pattern_t));
    if (!led_queue)
        return ESP_ERR_NO_MEM;
    xTaskCreate(led_task, "led_task", 2048, NULL, 5, NULL);
    return ESP_OK;
}

esp_err_t led_indicator_set_pattern(led_pattern_t pattern)
{
    if (!led_queue)
        return ESP_ERR_INVALID_STATE;

    if (xQueueSend(led_queue, &pattern, 0) != pdTRUE)
        return ESP_ERR_TIMEOUT;

    return ESP_OK;
}