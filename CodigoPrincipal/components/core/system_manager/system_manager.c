#include "system_manager.h"

// Tags para logging
static const char *TAG = "SystemManager";
static const char *TAG_SENSOR = "SensorTask";
static const char *TAG_SD = "SDTask";

// Handles globais (static para encapsulamento)
static QueueHandle_t sensor_queue = NULL;
static queue_config_t queue_config = {
    .size = 10,                   // Tamanho padrão da fila
    .timeout = pdMS_TO_TICKS(100) // Timeout de 100ms
};

// Tarefas (declarações forward)
static void task_sensor(void *pv_params);
static void task_sd(void *pv_params);
static void task_monitor(void *pv_params);

// Inicializa a fila (static para uso interno)
static bool init_queue(void)
{
    sensor_queue = xQueueCreate(queue_config.size, sizeof(sensor_data_t));
    if (sensor_queue == NULL)
    {
        ESP_LOGE(TAG, "Falha ao criar fila");
        return false;
    }
    return true;
}

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

void system_manager_start()
{
    // 1. Hardware básico
    gpio_reset_pin(LED_GPIO);
    gpio_set_direction(LED_GPIO, GPIO_MODE_OUTPUT);
    buzzer_init();

    // 2. SD Card (com tratamento de erro)
    if (sdcard_init() != ESP_OK)
    {
        ESP_LOGE(TAG, "Falha no SD Card");
        buzzer_alert(); // Função personalizada para alertas
        vTaskDelay(pdMS_TO_TICKS(1000));
    }

    // 3. Sensores
    hx711_t scale1;
    hx711_init(&scale1, SCALE1_DOUT, SCALE1_SCK, HX711_CHANNEL_A_128);
    hx711_tare(&scale1, 10);

    // 4. Fila e tarefas
    if (!init_queue())
    {
        ESP_LOGE(TAG, "Abortando inicialização");
        return;
    }

    xTaskCreatePinnedToCore(task_sensor, "Sensor", 3072, &scale1, // Passa o sensor como parâmetro
                            TASK_PRIORITY_SENSOR, NULL, 1);       // Fixa no core 1 (evita conflitos com WiFi/BT)

    xTaskCreate(task_sd, "SD", 4096, NULL, TASK_PRIORITY_SD, NULL);

    xTaskCreate(task_monitor, "Monitor", 2048, NULL, TASK_PRIORITY_MONITOR, NULL);
}

// Implementação das tarefas
static void task_sensor(void *pv_params)
{
    hx711_t *scale = (hx711_t *)pv_params;
    sensor_data_t data = {0};

    while (1)
    {
        data.weight = hx711_read_weight(scale);
        data.timestamp = xTaskGetTickCount();

        if (!system_manager_send_data(&data))
        {
            ESP_LOGW(TAG_SENSOR, "Fila cheia - dado descartado");
        }

        vTaskDelay(pdMS_TO_TICKS(500)); // Intervalo fixo
    }
}

static void task_sd(void *pv_params)
{
    sensor_data_t data;

    while (1)
    {
        if (system_manager_receive_data(&data, portMAX_DELAY))
        {
            char log_msg[64];
            snprintf(log_msg, sizeof(log_msg),
                     "Sensor %u: %.2fg @ %lu",
                     data.sensor_id, data.weight, data.timestamp);

            if (sdcard_log("WEIGHT", log_msg) != ESP_OK)
            {
                ESP_LOGE(TAG_SD, "Falha ao escrever no SD");
            }
        }
    }
}

static void task_monitor(void *pv_params)
{
    while (1)
    {
        UBaseType_t items = uxQueueMessagesWaiting(sensor_queue);
        ESP_LOGI(TAG, "Uso da fila: %u/%u", items, queue_config.size);
        vTaskDelay(pdMS_TO_TICKS(5000)); // A cada 5 segundos
    }
}

// API da fila
bool system_manager_send_data(const sensor_data_t *data)
{
    return xQueueSend(sensor_queue, data, queue_config.timeout) == pdTRUE;
}

bool system_manager_receive_data(sensor_data_t *data, TickType_t timeout)
{
    return xQueueReceive(sensor_queue, data, timeout) == pdTRUE;
}