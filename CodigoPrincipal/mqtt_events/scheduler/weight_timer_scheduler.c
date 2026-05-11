#include "../../config/config.h"

static const char *ROTULO_LOCAL = "SENSOR_TASK";
static TimerHandle_t schedule_weight_measure_timer = {0};
static QueueHandle_t weight_measure = NULL;
static bool control = false;
static char log_msg[150] = {0};

#pragma region Static

static void scheduled_weight_measurement(TimerHandle_t xTimer)
{
    // This runs when the timer expires
    int64_t w = get_global_weight();
    xQueueSend(weight_measure, &w, 0);

    // Schedule the next event
    if (number_of_weight_times > 0)
        schedule_next_measure();
}

static void task_worker(void *pvParams)
{
    while (1)
    {
        int64_t w = {0};
        if (xQueueReceive(weight_measure, &w, portMAX_DELAY))
        {
            snprintf(log_msg, sizeof(log_msg), "Peso{%lld}", w);
            sdcard_log(LOG_INFO, log_msg, ROTULO_LOCAL);
            mqtt_publish(MQTT_TOPIC_PUB_SENSOR, log_msg, 2);
        }
    }
}

#pragma endregion

esp_err_t schedule_next_measure()
{
    if (!scale_has_baby() || number_of_weight_times <= 0)
    {
        ESP_LOGW(ROTULO_LOCAL, "No schedule available - waiting...");
        return ESP_OK; // não é um erro, apenas nao tem bebe ou horario agendado
    }

    time_t now = {0};
    struct tm timeinfo = {0};
    time(&now);
    localtime_r(&now, &timeinfo);

    uint32_t smallest_delay = UINT32_MAX;
    int closest_idx = 0;

    for (int i = 0; i < number_of_weight_times; i++)
    {
        ESP_LOGW(ROTULO_LOCAL, "Comparing: TimeNow{%d:%d}, WeightTime[%d]{%d:%d}", timeinfo.tm_hour, timeinfo.tm_min, i, weight_times[i].hour, weight_times[i].minutes);

        uint32_t current_mins = timeinfo.tm_hour * 60 + timeinfo.tm_min;
        uint32_t scheduled_mins = weight_times[i].hour * 60 + weight_times[i].minutes;
        if (scheduled_mins <= current_mins) // schedule is next day
            scheduled_mins += 1440;         // Add 24 hours (1440 mins)

        uint32_t delay_mins = scheduled_mins - current_mins;
        if (delay_mins < smallest_delay)
        {
            smallest_delay = delay_mins;
            closest_idx = i;
        }
    }

    // Convert to milliseconds (with 1s minimum delay)
    uint32_t delay_ms = smallest_delay * 60000UL;
    if (delay_ms == 0)
    {
        if (control)
            delay_ms = 60000UL;
        else
        {
            control = true;
            delay_ms = 1000UL;
        }
    }

    ESP_LOGW(ROTULO_LOCAL, "Chosen time:{%d:%d}", weight_times[closest_idx].hour, weight_times[closest_idx].minutes);
    ESP_LOGW(ROTULO_LOCAL, "Delay: %lu ms (%.1f hours)", delay_ms, delay_ms / 3600000.0);

    // Schedule timer
    if (xTimerChangePeriod(schedule_weight_measure_timer, pdMS_TO_TICKS(delay_ms), portMAX_DELAY) == pdPASS)
    {
        if (xTimerStart(schedule_weight_measure_timer, portMAX_DELAY) != pdPASS)
        {
            return ESP_FAIL;
        }
        return ESP_OK;
    }
    else
        return ESP_FAIL;
}

esp_err_t stop_schedule_timer()
{
    if (xTimerStop(schedule_weight_measure_timer, portMAX_DELAY) != pdPASS)
        return ESP_FAIL;

    ESP_LOGI(ROTULO_LOCAL, "weight_sensors_timer stoped");
    return ESP_OK;
}

esp_err_t init_weight_sensors_timer()
{
    schedule_weight_measure_timer = xTimerCreate(
        "SchedulerTimer",            // Name
        pdMS_TO_TICKS(1000),         // Initial period (dummy value)
        pdFALSE,                     // One-shot timer
        (void *)0,                   // Timer ID
        scheduled_weight_measurement // Callback
    );
    weight_measure = xQueueCreate(MAX_WEIGHT_TIMES, sizeof(int64_t));
    if (xTaskCreate(task_worker, "WeightMeasure", 4096, NULL, 2, NULL) != pdPASS)
        return ESP_FAIL;

    if (scale_has_baby() && number_of_weight_times > 0)
        return schedule_next_measure();

    return ESP_OK;
}