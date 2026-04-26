#include "../../config/config.h"

static const char *ROTULO_LOCAL = "SENSOR_TASK";

static int64_t s_last_readings[NUM_WEIGHT_SENSORS];
static SemaphoreHandle_t s_data_mutex[NUM_WEIGHT_SENSORS];
static SemaphoreHandle_t global_weight_mutex;
static int64_t final_weight;

// Parâmetros de cada tarefa leitora
#define SENSOR_READ_DELAY_MS 100 // atraso entre ciclos de leitura (ajustável)

#pragma region static
/**
 * Leitura individual de cada sensor
 */
static void sensor_reader_task(void *arg)
{
    int id = (int)arg;
    TickType_t last_wake = xTaskGetTickCount();
    configASSERT(s_data_mutex[id] != NULL); // ao inves de checar se o mutex esta disponivel no loop, checa fora dele

    while (1)
    {
        int64_t raw_avg = hx711_read_sensor_weight(id);
        if (raw_avg != HX711_INVALID_READING)
        {
            xSemaphoreTake(s_data_mutex[id], portMAX_DELAY);
            s_last_readings[id] = raw_avg;
            xSemaphoreGive(s_data_mutex[id]);
        }

        vTaskDelayUntil(&last_wake, pdMS_TO_TICKS(SENSOR_READ_DELAY_MS)); // Aguarda o próximo ciclo (evita polling excessivo)
    }
}

// Tarefa de processamento: calcula o peso global a partir dos valores mais recentes
static void sensor_processor_task(void *pvParams)
{
    TickType_t last_wake = xTaskGetTickCount();
    while (1)
    {
        // Coleta todas as leituras atuais sob mutex
        int64_t readings = 0;
        int8_t valid_count = 0;
        int64_t sum = 0;
        for (int i = 0; i < NUM_WEIGHT_SENSORS; i++)
        {
            if (s_data_mutex[i] != NULL)
            {
                xSemaphoreTake(s_data_mutex[i], portMAX_DELAY);
                readings = s_last_readings[i];
                xSemaphoreGive(s_data_mutex[i]);
            }

            sum += readings;
            valid_count++;
        }

        if (valid_count > 0)
        {
            int64_t w = (int64_t)(sum / SCALE_MEASURE_FACTOR);
            if (w >= 3000.0)
                w = (int64_t)w * 0.99;
            if (w < 0)
                w = 0;

            set_global_weight(w);
            ESP_LOGI(ROTULO_LOCAL, "Peso: %lld g ", w);
        }
        else
        {
            set_global_weight((int64_t)0);
            ESP_LOGW(ROTULO_LOCAL, "Nenhum sensor gerando leitura válida");
            sdcard_log(LOG_ERROR, "Falha HX711: nenhuma leitura valida disponivel para compor o peso.", ROTULO_LOCAL);
        }

        vTaskDelayUntil(&last_wake, pdMS_TO_TICKS(1000)); // Aguarda o próximo ciclo de processamento
    }
}

static int64_t last = 0;
static uint8_t down3 = 0;
static uint8_t cooldown = 0;
static int8_t inited = 0;

static int8_t check_if_tare_is_needed(int64_t w, int64_t step, uint8_t cooldown_reads)
{
    if (inited == 0)
    {
        last = w;
        inited = 1;
        return 0;
    }

    if (cooldown)
    {
        cooldown--;
        last = w;
        return 0;
    }

    int64_t d = w - last;

    if (d <= -step)
    {
        down3++;
        if (down3 >= 3)
        {
            down3 = 0;
            cooldown = cooldown_reads;
            last = w;
            return 1;
        }
    }
    else
    {
        down3 = 0;
    }

    last = w;
    return 0;
}

#pragma endregion

int64_t get_global_weight()
{
    int64_t w;
    xSemaphoreTake(global_weight_mutex, portMAX_DELAY);
    w = final_weight;
    xSemaphoreGive(global_weight_mutex);
    return w;
}

void set_global_weight(int64_t new_value)
{
    xSemaphoreTake(global_weight_mutex, portMAX_DELAY);
    final_weight = new_value;
    xSemaphoreGive(global_weight_mutex);
    if (check_if_tare_is_needed(new_value, 15, 8))
    {
        ESP_LOGW(ROTULO_LOCAL, "Realizando tara (re-tara)");
        for (int8_t i = 0; i < NUM_WEIGHT_SENSORS; i++)
            hx711_tare_safe(i);
    }
}

esp_err_t init_sensors_task(void)
{
    // inicializa semaforo que controla acesso ao peso global
    global_weight_mutex = xSemaphoreCreateMutex();

    // Inicializa o array de leituras como inválido
    memset(s_last_readings, 0, sizeof(s_last_readings));

    // Cria uma tarefa leitora para cada sensor
    for (int i = 0; i < NUM_WEIGHT_SENSORS; i++)
    {
        s_data_mutex[i] = xSemaphoreCreateMutex();

        if (s_data_mutex[i] == NULL)
        {
            ESP_LOGE(ROTULO_LOCAL, "Falha ao criar mutex %d", i);
            return ESP_ERR_NO_MEM;
        }

        TaskHandle_t task_handle = NULL;
        if (xTaskCreate(sensor_reader_task, "sensor_reader", 4096, (void *)i, TASK_PRIORITY_HIGH, &task_handle) != pdPASS)
        {
            ESP_LOGE(ROTULO_LOCAL, "Falha ao criar tarefa para sensor %d", i);
            return ESP_ERR_NO_MEM;
        }
    }

    // Cria a tarefa de processamento (prioridade média)
    if (xTaskCreate(sensor_processor_task, "sensor_proc", 4096, NULL, TASK_PRIORITY_MEDIUM, NULL) != pdPASS)
    {
        ESP_LOGE(ROTULO_LOCAL, "Falha ao criar tarefa de processamento");
        return ESP_ERR_NO_MEM;
    }

    ESP_LOGI(ROTULO_LOCAL, "Sistema de leitura de sensores inicializado com %d tarefas leitoras", NUM_WEIGHT_SENSORS);
    return ESP_OK;
}