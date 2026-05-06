#include "../../config/config.h"

static char *ROTULO_LOCAL = "BABY_CONTROL";
static bool has_baby = false;

char baby_id[12] = {0};
SemaphoreHandle_t has_baby_mutex = NULL;
weight_time_t weight_times[MAX_WEIGHT_TIMES];
uint8_t number_of_weight_times = 0;

#pragma region Static

static int extract_number(const char *str)
{
    char *endptr;
    int num = (int)strtol(str, &endptr, 10);

    if (num > 59)
        num = 59;
    else if (num < 0)
        num = 0;

    return num;
}

static esp_err_t clear_routine()
{ // Limpa dados atuais
    memset(baby_id, 0, sizeof(baby_id));
    memset(weight_times, 0, sizeof(weight_times));
    number_of_weight_times = 0;
    update_has_baby_flag(false);
    sdcard_clear_file(BABY_HOURS_FILE);
    stop_schedule_timer();
    return ESP_OK;
}

static esp_err_t run_routine()
{
    log_entry_t entry;
    entry.path = BABY_HOURS_FILE;

    int offset = 0;
    offset += snprintf(entry.message, sizeof(entry.message), "baby_id:%s;\n", baby_id);
    for (int i = 0; i < number_of_weight_times && offset < sizeof(entry.message); i++)
        offset += snprintf(entry.message + offset, sizeof(entry.message) - offset, "weight_time:%02d:%02d;\n", weight_times[i].hour, weight_times[i].minutes);

    ESP_LOGW(ROTULO_LOCAL, "Vai salvar no SD: %s", entry.message);

    while (1)
    {
        if (xQueueSend(sdcard_log_queue, &entry, pdMS_TO_TICKS(100)) == pdTRUE)
            break;

        vTaskDelay(pdMS_TO_TICKS(500));
    }

    if (scale_has_baby() && number_of_weight_times > 0)
        schedule_next_measure();

    return ESP_OK;
}

static esp_err_t baby_routine(const char *data)
{
    size_t id_len = strlen(data);
    if (id_len > 0 && id_len < sizeof(baby_id))
    {
        if (clear_routine() != ESP_OK)
            return ESP_FAIL;

        strncpy(baby_id, data, sizeof(baby_id) - 1);
        baby_id[sizeof(baby_id) - 1] = '\0'; // Garante terminação nula
        update_has_baby_flag(true);

        ESP_LOGW(ROTULO_LOCAL, "BABY_ID: %s", baby_id);
        return ESP_OK;
    }
    return ESP_FAIL;
}

static esp_err_t weight_times_routine(const char *data)
{
    weight_time_t weight;
    // Verifica se a string tem formato HH:MM (ex: "08:00")
    if (strlen(data) >= 5 && data[2] == ':')
    {
        weight.hour = (uint8_t)extract_number(&data[0]);    // HH
        weight.minutes = (uint8_t)extract_number(&data[3]); // MM
        ESP_LOGW(ROTULO_LOCAL, "Horário: %02d:%02d", weight.hour, weight.minutes);

        weight_times[number_of_weight_times] = weight;
        ESP_LOGW(ROTULO_LOCAL, "[%d] Horário: %02d:%02d", number_of_weight_times, weight_times[number_of_weight_times].hour, weight_times[number_of_weight_times].minutes);
        number_of_weight_times++;

        return ESP_OK;
    }
    return ESP_FAIL;
}

static esp_err_t measure_routine()
{
    int64_t global_weight = get_global_weight();
    char m[50];
    snprintf(m, 50, "%s;Peso{%lld}", RECEIVED_MEASURE, global_weight);
    sdcard_log(LOG_INFO, m, ROTULO_LOCAL);
    while (true)
    {
        if (mqtt_publish(MQTT_TOPIC_PUB_WEIGHT, m, 1))
            break;
        vTaskDelay(pdMS_TO_TICKS(300));
    }
    return ESP_OK;
}

static esp_err_t calibrate_routine(const char *data)
{
    // To do => precisa apenas trocar os fatores, vai receber do mqtt e aplicar nos sensores. Talvez precisa usar NVS.
    return ESP_OK;
}

static esp_err_t wifi_routine()
{
    sdcard_log(LOG_WARN, "Desligando MQTT", ROTULO_LOCAL);
    esp_mqtt_client_handle_t client = mqtt_get_client_handle();
    if (client)
    {
        esp_mqtt_client_stop(client);
        esp_mqtt_client_destroy(client);
        client = NULL;
    }
    sdcard_log(LOG_WARN, "MQTT desligado, desligando wifi", ROTULO_LOCAL);
    reset_wifi();
    return ESP_OK;
}

static const CommandHandler handlers[] = {
    {RECEIVED_BABY, baby_routine, "Baby ID recebido", "ERRO AO LER BABY ID"},
    {RECEIVED_TIMES, weight_times_routine, "Horario recebido", "ERRO AO LER WEIGHTS"},
    {RECEIVED_RUN, run_routine, "Bebe e horarios salvos", "ERRO AO LER RUN"},
    {RECEIVED_CLEAR, clear_routine, "Bebe e horarios apagados", "ERRO AO LER CLEAR"},
    {RECEIVED_MEASURE, measure_routine, "Medida realizada", "ERRO AO LER MEASURE"},
    {RECEIVED_CALIBRATE, calibrate_routine, "Calibração realizada", "ERRO AO LER CALIBRATE"},
    {RECEIVED_WIFI, wifi_routine, "Reset de WiFi realizado", "ERRO AO LER WIFI"},
};

#pragma endregion

void update_has_baby_flag(bool state)
{ // Restringe o acesso à flag para evitar concorrencia
    if (has_baby_mutex == NULL)
        has_baby = state;
    else
    {
        while (true)
        {
            if (xSemaphoreTake(has_baby_mutex, pdMS_TO_TICKS(100)) == pdTRUE)
            {
                has_baby = state;
                xSemaphoreGive(has_baby_mutex);
                break;
            }
            vTaskDelay(pdMS_TO_TICKS(300));
        }
    }
}

bool scale_has_baby()
{ // Restringe o acesso à flag para evitar concorrencia
    bool result = false;
    if (has_baby_mutex == NULL)
        result = has_baby;
    else
    {
        while (true)
        {
            if (xSemaphoreTake(has_baby_mutex, pdMS_TO_TICKS(100)) == pdTRUE)
            {
                result = has_baby;
                xSemaphoreGive(has_baby_mutex);
                break;
            }
            vTaskDelay(pdMS_TO_TICKS(300));
        }
    }
    return result;
}

void process_mqtt_data(const char *mqtt_data)
{
    if (has_baby_mutex == NULL)
        has_baby_mutex = xSemaphoreCreateMutex();

    // O array handlers ja gerencia a funcao de callback quando um determinado comando for recebido
    int handlers_size = sizeof(handlers) / sizeof(handlers[0]);
    for (int i = 0; i < handlers_size; i++)
    {
        const CommandHandler *h = &handlers[i];
        size_t len = strlen(h->prefix);
        if (strncmp(mqtt_data, h->prefix, len) == 0)
        {
            if (number_of_weight_times >= MAX_WEIGHT_TIMES && strcmp(h->prefix, RECEIVED_TIMES))
            {
                mqtt_publish(MQTT_TOPIC_PUB_WEIGHT, "ERROR_MAX_WEIGHT_TIMES_ACHIEVED", 1);
                return;
            }

            const char *SUCCESS_MSG = "1";
            const char *ERROR_MSG = "0";
            const char *data = mqtt_data + len;
            esp_err_t result = h->handler(data);
            if (result == ESP_OK)
            {
                mqtt_publish(MQTT_TOPIC_PUB_WEIGHT, SUCCESS_MSG, 1);
                ESP_LOGI(ROTULO_LOCAL, "%s", h->log_success);
                // if (strstr(h->log_success, "%s"))
                //     ESP_LOGI(ROTULO_LOCAL, "%s - %s", h->log_success, baby_id);
                // else
                // ESP_LOGI(ROTULO_LOCAL, "%s", h->log_success);
            }
            else
            {
                sdcard_log(LOG_ERROR, h->log_error, ROTULO_LOCAL);
                mqtt_publish(MQTT_TOPIC_PUB_WEIGHT, ERROR_MSG, 1);
            }
            return;
        }
    }
}