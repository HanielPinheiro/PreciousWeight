// #include "../../config/config.h"

// static const char *ROTULO_LOCAL = "SENSOR_TASK";

// // Objetivo deste módulo:
// // - Manter uma leitura periódica dos HX711 (um "frame" com todas as leituras)
// // - Detectar falhas comuns:
// //      1) Sensor parou de ler (timeout em ms + streak de inválidos)
// //      2) Glitch de leitura (salto brusco confirmado + retorno ao normal)
// //
// // Arquitetura:
// // - 1 task de polling (prioridade alta): lê sensores e faz detecção de falhas
// // - 1 task de processamento (prioridade média): agrega leituras e atualiza "weight"
// // - 1 fila (tamanho 1) com overwrite: sempre mantém o frame mais recente (evita backlog)
// //
// // Obs.: O driver do HX711 já usa região crítica durante o shift do clock, então paralelizar
// // leitura em múltiplas tasks tende a aumentar overhead sem ganho real.

// // Periodicidade de leitura dos HX711 (ms).
// #define SENSOR_POLL_PERIOD_MS 1000

// // Detecção de "parou de ler":
// // - streak: conta quantas leituras inválidas seguidas ocorreram
// // - timeout: protege contra situações em que a task atrasa (N ciclos não é absoluto)
// #define SENSOR_INVALID_STREAK_LIMIT 3
// #define SENSOR_STUCK_TIMEOUT_MS 3500

// // Detecção de "salto brusco":
// // Em balança de bebê, 500g geralmente é alto demais para flag de glitch.
// // Aqui usamos threshold dinâmico baseado no ruído (EWMA), com limites mínimo e máximo.
// #define SENSOR_JUMP_THRESHOLD_MIN_GRAMS 80
// #define SENSOR_JUMP_THRESHOLD_MAX_GRAMS 800
// #define SENSOR_JUMP_NOISE_EWMA_ALPHA 0.15f
// #define SENSOR_JUMP_NOISE_MULTIPLIER 6.0f
// #define SENSOR_JUMP_BASE_MARGIN_GRAMS 20

// // Para confirmar glitch:
// // - precisa ocorrer em 2 leituras consecutivas (candidate -> confirmed)
// // - e depois haver retorno ao "baseline" (padrão spike)
// #define SENSOR_RETURN_BAND_GRAMS 30
// #define SENSOR_SPIKE_MAX_DURATION_MS 2000

// // Rate-limit de logs por sensor (evita flood no SD e no console).
// #define SENSOR_FAULT_LOG_INTERVAL_MS 5000

// enum
// {
//     SENSOR_FAULT_NONE = 0,
//     SENSOR_FAULT_INVALID = 1 << 0,
//     SENSOR_FAULT_JUMP = 1 << 1,
// };

// typedef struct
// {
//     uint32_t timestamp_ms;
//     weight_t reading[NUM_WEIGHT_SENSORS];
//     uint8_t fault[NUM_WEIGHT_SENSORS];
// } sensors_frame_t;

// static QueueHandle_t s_frame_queue = NULL;
// static TaskHandle_t s_poll_task = NULL;
// static TaskHandle_t s_process_task = NULL;

// static int32_t i32_abs(int32_t value)
// {
//     return (value < 0) ? -value : value;
// }

// static int32_t i32_clamp(int32_t value, int32_t min_value, int32_t max_value)
// {
//     if (value < min_value)
//         return min_value;
//     if (value > max_value)
//         return max_value;
//     return value;
// }

// static void sensors_poll_task(void *pv_params)
// {
//     (void)pv_params;

//     TickType_t last_wake_ticks = xTaskGetTickCount();

//     // Estado por sensor (não usar variáveis locais por task "reader", pois aqui é polling único).
//     int32_t stable_value[NUM_WEIGHT_SENSORS] = {0};
//     bool has_stable[NUM_WEIGHT_SENSORS] = {0};

//     // Último instante em que recebemos leitura válida (ms).
//     uint32_t last_valid_ms[NUM_WEIGHT_SENSORS] = {0};

//     // Streak de leituras inválidas (para detectar falhas rápidas).
//     uint8_t invalid_streak[NUM_WEIGHT_SENSORS] = {0};

//     // Estimativa de ruído (EWMA do delta absoluto) usada para threshold dinâmico.
//     float noise_ewma_abs_delta[NUM_WEIGHT_SENSORS] = {0};

//     // Máquina de estado para detectar glitches tipo "spike":
//     // 0 = normal
//     // 1 = candidate (1ª leitura acima do threshold)
//     // 2 = confirmed (2ª leitura consecutiva acima do threshold) aguardando retorno
//     uint8_t spike_state[NUM_WEIGHT_SENSORS] = {0};
//     uint32_t spike_start_ms[NUM_WEIGHT_SENSORS] = {0};

//     // Rate-limit de logs por sensor.
//     uint32_t last_fault_log_ms[NUM_WEIGHT_SENSORS] = {0};

//     while (1)
//     {
//         sensors_frame_t frame = {0};
//         frame.timestamp_ms = esp_log_timestamp();

//         for (int i = 0; i < NUM_WEIGHT_SENSORS; i++)
//         {
//             weight_t w = hx711_read_sensor_weight(&sensors[i]);
//             frame.reading[i] = w;

//             uint8_t fault = SENSOR_FAULT_NONE;
//             bool valid = (w.raw_value != HX711_INVALID_READING);
//             bool jump_glitch_confirmed = false;

//             if (!valid)
//             {
//                 invalid_streak[i]++;
//                 // Se a leitura ficou inválida, aborta detecção de spike (senão o estado pode ficar preso).
//                 spike_state[i] = 0;
//                 fault |= SENSOR_FAULT_INVALID;
//             }
//             else
//             {
//                 invalid_streak[i] = 0;
//                 last_valid_ms[i] = frame.timestamp_ms;

//                 if (!has_stable[i])
//                 {
//                     // Primeira leitura válida vira baseline inicial do sensor.
//                     stable_value[i] = w.value;
//                     has_stable[i] = true;
//                     noise_ewma_abs_delta[i] = 0;
//                     spike_state[i] = 0;
//                 }
//                 else
//                 {
//                     // Threshold dinâmico baseado no ruído estimado.
//                     // - quanto mais ruído, maior o threshold
//                     // - nunca abaixo de MIN e nunca acima de MAX
//                     int32_t dynamic_threshold = (int32_t)(noise_ewma_abs_delta[i] * SENSOR_JUMP_NOISE_MULTIPLIER) + SENSOR_JUMP_BASE_MARGIN_GRAMS;
//                     dynamic_threshold = i32_clamp(dynamic_threshold, SENSOR_JUMP_THRESHOLD_MIN_GRAMS, SENSOR_JUMP_THRESHOLD_MAX_GRAMS);

//                     int32_t delta_from_baseline = i32_abs(w.value - stable_value[i]);

//                     // Atualiza estimativa de ruído somente quando estamos em modo "normal" e perto do baseline.
//                     // Isso evita que spikes contaminem o EWMA.
//                     if (spike_state[i] == 0 && delta_from_baseline <= dynamic_threshold)
//                     {
//                         noise_ewma_abs_delta[i] = (SENSOR_JUMP_NOISE_EWMA_ALPHA * (float)delta_from_baseline) +
//                                                   ((1.0f - SENSOR_JUMP_NOISE_EWMA_ALPHA) * noise_ewma_abs_delta[i]);
//                     }

//                     // Detecção do padrão spike:
//                     // - candidate: 1 leitura acima do threshold
//                     // - confirmed: 2 leituras consecutivas acima do threshold
//                     // - glitch confirmado: após confirmed, há retorno ao baseline
//                     if (spike_state[i] == 0)
//                     {
//                         if (delta_from_baseline > dynamic_threshold)
//                         {
//                             spike_state[i] = 1;
//                             spike_start_ms[i] = frame.timestamp_ms;
//                             fault |= SENSOR_FAULT_JUMP;
//                         }
//                         else
//                         {
//                             stable_value[i] = w.value;
//                         }
//                     }
//                     else if (spike_state[i] == 1)
//                     {
//                         if (delta_from_baseline > dynamic_threshold)
//                         {
//                             spike_state[i] = 2;
//                             fault |= SENSOR_FAULT_JUMP;
//                         }
//                         else
//                         {
//                             // Não confirmou (voltou ao normal no 2º sample): considera ruído normal.
//                             spike_state[i] = 0;
//                             stable_value[i] = w.value;
//                         }
//                     }
//                     else
//                     {
//                         // spike_state == 2: aguardando retorno ao baseline para confirmar glitch.
//                         fault |= SENSOR_FAULT_JUMP;

//                         if (delta_from_baseline <= SENSOR_RETURN_BAND_GRAMS)
//                         {
//                             // Glitch confirmado: salto brusco + retorno.
//                             // Não muda o baseline de forma abrupta, apenas aceita o valor retornado.
//                             jump_glitch_confirmed = true;
//                             spike_state[i] = 0;
//                             stable_value[i] = w.value;
//                         }
//                         else if ((frame.timestamp_ms - spike_start_ms[i]) >= SENSOR_SPIKE_MAX_DURATION_MS)
//                         {
//                             // Se o "salto" persistiu tempo demais, é provavelmente um evento real
//                             // (ex.: alguém colocou peso na balança). Aceitamos como novo baseline.
//                             spike_state[i] = 0;
//                             stable_value[i] = w.value;
//                         }
//                     }
//                 }
//             }

//             // Timeout em ms: se faz muito tempo desde a última leitura válida, marca como inválido.
//             // Isso é complementar ao streak (que depende do ciclo).
//             if (has_stable[i] && (last_valid_ms[i] != 0))
//             {
//                 uint32_t since_valid_ms = frame.timestamp_ms - last_valid_ms[i];
//                 if (since_valid_ms >= SENSOR_STUCK_TIMEOUT_MS)
//                     fault |= SENSOR_FAULT_INVALID;
//             }

//             frame.fault[i] = fault;

//             // Log com rate-limit:
//             // - INVALID: dispara quando streak >= limite ou timeout estourou
//             // - JUMP: dispara apenas quando o spike foi confirmado e retornou ao normal (glitch)
//             bool invalid_persistent = (invalid_streak[i] >= SENSOR_INVALID_STREAK_LIMIT) ||
//                                       (has_stable[i] && last_valid_ms[i] != 0 && ((frame.timestamp_ms - last_valid_ms[i]) >= SENSOR_STUCK_TIMEOUT_MS));

//             if ((invalid_persistent || jump_glitch_confirmed) &&
//                 ((frame.timestamp_ms - last_fault_log_ms[i]) >= SENSOR_FAULT_LOG_INTERVAL_MS))
//             {
//                 char msg[120];
//                 if (invalid_persistent)
//                 {
//                     uint32_t since_valid_ms = (last_valid_ms[i] == 0) ? 0 : (frame.timestamp_ms - last_valid_ms[i]);
//                     snprintf(msg, sizeof(msg),
//                              "Falha HX711: sensor %d sem leitura valida (streak=%u, since_valid=%ums).",
//                              i, (unsigned)invalid_streak[i], (unsigned)since_valid_ms);
//                     sdcard_log(LOG_ERROR, msg, ROTULO_LOCAL);
//                 }
//                 else if (jump_glitch_confirmed)
//                 {
//                     snprintf(msg, sizeof(msg), "Falha HX711: sensor %d glitch (salto brusco + retorno).", i);
//                     sdcard_log(LOG_WARN, msg, ROTULO_LOCAL);
//                 }
//                 last_fault_log_ms[i] = frame.timestamp_ms;
//             }
//         }

//         if (s_frame_queue)
//             (void)xQueueOverwrite(s_frame_queue, &frame);

//         vTaskDelayUntil(&last_wake_ticks, pdMS_TO_TICKS(SENSOR_POLL_PERIOD_MS));
//     }
// }

// static void sensors_process_task(void *pv_params)
// {
//     (void)pv_params;

//     while (1)
//     {
//         sensors_frame_t frame = {0};
//         if (!xQueueReceive(s_frame_queue, &frame, portMAX_DELAY))
//             continue;

//         int64_t sum_grams = 0;
//         int8_t count = 0;

//         for (int i = 0; i < NUM_WEIGHT_SENSORS; i++)
//         {
//             if (frame.reading[i].raw_value == HX711_INVALID_READING)
//                 continue;

//             sum_grams += (int64_t)frame.reading[i].value * sensors[i].calib_factor_in_1e9;
//             count++;
//         }

//         if (count > 0)
//         {
//             global_weight = (int64_t)(sum_grams / SCALE_MEASURE_FACTOR); // arquivo main.c e config.h
//             ESP_LOGI(ROTULO_LOCAL, "Soma: %lld - Peso: %lld", sum_grams, global_weight);

//             if (global_weight >= 3000.0)
//                 global_weight = (int64_t)global_weight * 0.99; // coreção de fator exponencial / logaritmico

//             if (global_weight < 0)
//                 global_weight = 0;
//         }
//         else
//         {
//             global_weight = 0;
//             sdcard_log(LOG_ERROR, "Falha HX711: nenhuma leitura valida disponivel para compor o peso.", ROTULO_LOCAL);
//         }
//     }
// }

// esp_err_t init_sensors_task()
// {
//     s_frame_queue = xQueueCreate(1, sizeof(sensors_frame_t));
//     if (!s_frame_queue)
//     {
//         sdcard_log(LOG_ERROR, "Falha ao criar fila de leitura dos sensores", ROTULO_LOCAL);
//         return ESP_ERR_NO_MEM;
//     }

//     if (xTaskCreate(sensors_poll_task, "hx711_poll", 4096, NULL, TASK_PRIORITY_HIGH, &s_poll_task) != pdPASS)
//     {
//         sdcard_log(LOG_ERROR, "Falha ao criar task de leitura HX711", ROTULO_LOCAL);
//         return ESP_ERR_NO_MEM;
//     }

//     if (xTaskCreate(sensors_process_task, "hx711_proc", 4096, NULL, TASK_PRIORITY_MEDIUM, &s_process_task) != pdPASS)
//     {
//         sdcard_log(LOG_ERROR, "Falha ao criar task de processamento HX711", ROTULO_LOCAL);
//         return ESP_ERR_NO_MEM;
//     }

//     return ESP_OK;
// }

#include "sensors_task.h"
#include "../../config/config.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/queue.h"
#include "freertos/semphr.h"
#include "esp_log.h"

static const char *ROTULO_LOCAL = "SENSOR_TASK";

static int64_t s_last_readings[NUM_WEIGHT_SENSORS];
static SemaphoreHandle_t s_data_mutex[NUM_WEIGHT_SENSORS];

// Parâmetros de cada tarefa leitora
#define SENSOR_READ_DELAY_MS 100 // atraso entre ciclos de leitura (ajustável)

// Tarefa individual para cada sensor
static void sensor_reader_task(void *arg)
{
    int8_t id = (int8_t)arg;
    if (s_data_mutex[id] != NULL)
    {
        xSemaphoreTake(s_data_mutex[id], portMAX_DELAY);
        hx711_t *sensor = &sensors[id];
        TickType_t last_wake = xTaskGetTickCount();

        while (1)
        {
            // 1. Realiza a leitura com média (bloqueia internamente)
            int32_t raw_avg = hx711_read_average(sensor, AVERAGE_NUMBER);
            int64_t weight = -1;

            if (raw_avg != HX711_INVALID_READING)
            {
                weight = (raw_avg - sensor->offset) * sensor->calib_factor_in_1e9;
            }
            else
            {
                ESP_LOGW(ROTULO_LOCAL, "Sensor %d: leitura inválida", id);
            }

            s_last_readings[id] = weight;
        }

        xSemaphoreGive(s_data_mutex[id]);
        // 3. Aguarda o próximo ciclo (evita polling excessivo)
        vTaskDelayUntil(&last_wake, pdMS_TO_TICKS(SENSOR_READ_DELAY_MS));
    }
}

// Tarefa de processamento: calcula o peso global a partir dos valores mais recentes
static void sensor_processor_task(void *pvParams)
{
    (void)pvParams;
    TickType_t last_wake = xTaskGetTickCount();

    while (1)
    {
        // Coleta todas as leituras atuais sob mutex
        int64_t readings[NUM_WEIGHT_SENSORS];
        if (s_data_mutex != NULL)
        {
            xSemaphoreTake(s_data_mutex, portMAX_DELAY);
            memcpy(readings, s_last_readings, sizeof(readings));
            xSemaphoreGive(s_data_mutex);
        }

        int8_t valid_count = 0;
        int64_t sum = 0;
        for (int i = 0; i < NUM_WEIGHT_SENSORS; i++)
        {
            if (readings[i] > -1)
            {
                sum += readings[i];
                valid_count++;
            }
        }

        if (valid_count > 0)
        {
            global_weight = (int64_t)(sum / SCALE_MEASURE_FACTOR); // arquivo main.c e config.h
            ESP_LOGI(ROTULO_LOCAL, "Soma: %lld - Peso: %lld", sum, global_weight);

            if (global_weight >= 3000.0)
                global_weight = (int64_t)global_weight * 0.99; // coreção de fator exponencial / logaritmico

            if (global_weight < 0)
                global_weight = 0;

            ESP_LOGI(ROTULO_LOCAL, "Peso global: %lld g (baseado em %d sensores)", global_weight, valid_count);
        }
        else
        {
            global_weight = 0;
            ESP_LOGW(ROTULO_LOCAL, "Nenhum sensor gerando leitura válida");
            sdcard_log(LOG_ERROR, "Falha HX711: nenhuma leitura valida disponivel para compor o peso.", ROTULO_LOCAL);
        }
        // Aguarda o próximo ciclo de processamento (ex: 1 segundo)
        vTaskDelayUntil(&last_wake, pdMS_TO_TICKS(1000));
    }
}

esp_err_t init_sensors_task(void)
{
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