#include "../../config/config.h"

static const char *ROTULO_LOCAL = "SENSOR_TASK";

#define SENSOR_POLL_PERIOD_MS 1000
#define SENSOR_INVALID_STREAK_LIMIT 3
#define SENSOR_JUMP_THRESHOLD_GRAMS 500
#define SENSOR_JUMP_STREAK_LIMIT 2
#define SENSOR_FAULT_LOG_INTERVAL_MS 5000

enum
{
    SENSOR_FAULT_NONE = 0,
    SENSOR_FAULT_INVALID = 1 << 0,
    SENSOR_FAULT_JUMP = 1 << 1,
};

typedef struct
{
    uint32_t timestamp_ms;
    weight_t reading[NUM_WEIGHT_SENSORS];
    uint8_t fault[NUM_WEIGHT_SENSORS];
} sensors_frame_t;

static QueueHandle_t s_frame_queue = NULL;
static TaskHandle_t s_poll_task = NULL;
static TaskHandle_t s_process_task = NULL;

static int32_t i32_abs(int32_t value)
{
    return (value < 0) ? -value : value;
}

static void sensors_poll_task(void *pv_params)
{
    (void)pv_params;

    TickType_t last_wake_ticks = xTaskGetTickCount();
    int32_t last_value[NUM_WEIGHT_SENSORS] = {0};
    bool has_last[NUM_WEIGHT_SENSORS] = {0};
    uint8_t invalid_streak[NUM_WEIGHT_SENSORS] = {0};
    uint8_t jump_streak[NUM_WEIGHT_SENSORS] = {0};
    uint32_t last_fault_log_ms[NUM_WEIGHT_SENSORS] = {0};

    while (1)
    {
        sensors_frame_t frame = {0};
        frame.timestamp_ms = esp_log_timestamp();

        for (int i = 0; i < NUM_WEIGHT_SENSORS; i++)
        {
            weight_t w = hx711_read_sensor_weight(&sensors[i]);
            frame.reading[i] = w;

            uint8_t fault = SENSOR_FAULT_NONE;
            bool valid = (w.raw_value != HX711_INVALID_READING);

            if (!valid)
            {
                invalid_streak[i]++;
                jump_streak[i] = 0;
                fault |= SENSOR_FAULT_INVALID;
            }
            else
            {
                invalid_streak[i] = 0;

                if (has_last[i] && (i32_abs(w.value - last_value[i]) > SENSOR_JUMP_THRESHOLD_GRAMS))
                {
                    jump_streak[i]++;
                    fault |= SENSOR_FAULT_JUMP;
                }
                else
                {
                    jump_streak[i] = 0;
                }

                last_value[i] = w.value;
                has_last[i] = true;
            }

            frame.fault[i] = fault;

            bool fault_persistent = (invalid_streak[i] >= SENSOR_INVALID_STREAK_LIMIT) || (jump_streak[i] >= SENSOR_JUMP_STREAK_LIMIT);
            if (fault_persistent && ((frame.timestamp_ms - last_fault_log_ms[i]) >= SENSOR_FAULT_LOG_INTERVAL_MS))
            {
                char msg[120];
                if (invalid_streak[i] >= SENSOR_INVALID_STREAK_LIMIT)
                {
                    snprintf(msg, sizeof(msg), "Falha HX711: sensor %d sem leitura valida (%u ciclos).", i, (unsigned)invalid_streak[i]);
                    sdcard_log(LOG_ERROR, msg, ROTULO_LOCAL);
                }
                else
                {
                    snprintf(msg, sizeof(msg), "Falha HX711: sensor %d salto brusco (%u ciclos).", i, (unsigned)jump_streak[i]);
                    sdcard_log(LOG_WARN, msg, ROTULO_LOCAL);
                }
                last_fault_log_ms[i] = frame.timestamp_ms;
            }
        }

        if (s_frame_queue)
            (void)xQueueOverwrite(s_frame_queue, &frame);

        vTaskDelayUntil(&last_wake_ticks, pdMS_TO_TICKS(SENSOR_POLL_PERIOD_MS));
    }
}

static void sensors_process_task(void *pv_params)
{
    (void)pv_params;

    while (1)
    {
        sensors_frame_t frame = {0};
        if (!xQueueReceive(s_frame_queue, &frame, portMAX_DELAY))
            continue;

        int64_t sum_grams = 0;
        int count = 0;

        for (int i = 0; i < NUM_WEIGHT_SENSORS; i++)
        {
            if (i == 2)
                continue;
            if (frame.reading[i].raw_value == HX711_INVALID_READING)
                continue;

            sum_grams += frame.reading[i].value;
            count++;
        }

        if (count > 0)
        {
            weight = (int32_t)(sum_grams / count);
        }
        else
        {
            weight = 0;
            sdcard_log(LOG_ERROR, "Falha HX711: nenhuma leitura valida disponivel para compor o peso.", ROTULO_LOCAL);
        }
    }
}

esp_err_t init_sensors_task()
{
    s_frame_queue = xQueueCreate(1, sizeof(sensors_frame_t));
    if (!s_frame_queue)
    {
        sdcard_log(LOG_ERROR, "Falha ao criar fila de leitura dos sensores", ROTULO_LOCAL);
        return ESP_ERR_NO_MEM;
    }

    if (xTaskCreate(sensors_poll_task, "hx711_poll", 4096, NULL, TASK_PRIORITY_HIGH, &s_poll_task) != pdPASS)
    {
        sdcard_log(LOG_ERROR, "Falha ao criar task de leitura HX711", ROTULO_LOCAL);
        return ESP_ERR_NO_MEM;
    }

    if (xTaskCreate(sensors_process_task, "hx711_proc", 4096, NULL, TASK_PRIORITY_MEDIUM, &s_process_task) != pdPASS)
    {
        sdcard_log(LOG_ERROR, "Falha ao criar task de processamento HX711", ROTULO_LOCAL);
        return ESP_ERR_NO_MEM;
    }

    return ESP_OK;
}
