#include "../../config/config.h"

static char *ROTULO_LOCAL = "PROCESS_MQTT_DATA";
static bool has_baby = false;
// static const uint8_t MAX_MQTT_PUBLISH_RETRIES = 3;
static const uint8_t OUTBOX_QOS = 1;

static void mqtt_send_or_spool(uint32_t seq, const char *topic, int qos, const char *payload)
{
    if (!mqtt_publish(topic, payload, qos))
        pw_outbox_add(seq, topic, qos, payload);
}

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
    pw_state_save();
    stop_schedule_timer();
    return ESP_OK;
}

static esp_err_t run_routine()
{
    char routine_snapshot[256] = {0};
    int offset = 0;
    offset += snprintf(routine_snapshot, sizeof(routine_snapshot), "baby_id:%s;\n", baby_id);
    for (int i = 0; i < number_of_weight_times && offset < sizeof(routine_snapshot); i++)
        offset += snprintf(routine_snapshot + offset, sizeof(routine_snapshot) - offset, "weight_time:%02d:%02d;\n", weight_times[i].hour, weight_times[i].minutes);

    if (offset <= 0 || offset >= sizeof(routine_snapshot))
    {
        sdcard_log(LOG_ERROR, "Falha ao montar snapshot da rotina", ROTULO_LOCAL);
        return ESP_FAIL;
    }

    ESP_LOGW(ROTULO_LOCAL, "Vai salvar no SD: %s", routine_snapshot);

    if (sdcard_overwrite_file(BABY_HOURS_FILE, routine_snapshot) != ESP_OK)
        return ESP_FAIL;
    pw_state_save();

    if (scale_has_baby() && number_of_weight_times > 0)
    {
        esp_err_t schedule_ret = schedule_next_measure();
        if (schedule_ret != ESP_OK && schedule_ret != ESP_ERR_INVALID_STATE)
            return schedule_ret;
    }

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
        pw_state_save();

        ESP_LOGW(ROTULO_LOCAL, "BABY_ID: %s", baby_id);
        return ESP_OK;
    }
    return ESP_FAIL;
}

static esp_err_t weight_times_routine(const char *data)
{
    weight_time_t weight;
    if (number_of_weight_times >= MAX_WEIGHT_TIMES)
        return ESP_ERR_NO_MEM;

    // Verifica se a string tem formato HH:MM (ex: "08:00")
    if (strlen(data) >= 5 && data[2] == ':')
    {
        weight.hour = (uint8_t)extract_number(&data[0]);    // HH
        weight.minutes = (uint8_t)extract_number(&data[3]); // MM
        ESP_LOGW(ROTULO_LOCAL, "Horário: %02d:%02d", weight.hour, weight.minutes);

        weight_times[number_of_weight_times] = weight;
        ESP_LOGW(ROTULO_LOCAL, "[%d] Horário: %02d:%02d", number_of_weight_times, weight_times[number_of_weight_times].hour, weight_times[number_of_weight_times].minutes);
        number_of_weight_times++;
        pw_state_save();

        return ESP_OK;
    }
    return ESP_FAIL;
}

static esp_err_t measure_routine(const char *data)
{
    double global_weight = get_global_weight();
    uint32_t seq = pw_next_sequence_id();
    int64_t now = pw_now_epoch();
    char m[PW_OUTBOX_PAYLOAD_MAX];
    (void)data;
    snprintf(m, sizeof(m), "MEA|%lu|%lld|manual|%.2f", (unsigned long)seq, (long long)now, global_weight);
    pw_log_measurement(seq, "manual", global_weight);
    if (mqtt_publish(MQTT_TOPIC_MEASUREMENTS, m, OUTBOX_QOS))
        ;
    else if (pw_outbox_add(seq, MQTT_TOPIC_MEASUREMENTS, OUTBOX_QOS, m) != ESP_OK)
        return ESP_FAIL;

    char legacy[50];
    snprintf(legacy, sizeof(legacy), "%s{%.2f}", RECEIVED_MEASURE, global_weight);
    mqtt_publish(MQTT_TOPIC_WEIGHTS, legacy, 1);
    return ESP_OK;
}

static esp_err_t wifi_strength_routine(const char *data)
{
    int wifi_strength = 0;
    uint32_t seq = pw_next_sequence_id();
    int64_t now = pw_now_epoch();
    char m[PW_OUTBOX_PAYLOAD_MAX];
    (void)data;

    if (get_wifi_strength(&wifi_strength) != ESP_OK)
        return ESP_FAIL;

    snprintf(m, sizeof(m), "EVT|%lu|%lld|INFO|WIFI_RSSI|%d", (unsigned long)seq, (long long)now, wifi_strength);
    pw_log_event(PW_SEV_INFO, "WIFI_RSSI", ROTULO_LOCAL, "wifi_rssi");
    if (mqtt_publish(MQTT_TOPIC_EVENTS, m, OUTBOX_QOS))
        ;
    else
        pw_outbox_add(seq, MQTT_TOPIC_EVENTS, OUTBOX_QOS, m);

    char legacy[50];
    snprintf(legacy, sizeof(legacy), "%s{%d}", RECEIVED_WIFI_STRENGTH, wifi_strength);
    mqtt_publish(MQTT_TOPIC_WEIGHTS, legacy, 1);
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
    mqtt_stop_client();
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
    {RECEIVED_WIFI_STRENGTH, wifi_strength_routine, "Intensidade do WiFi enviada", "ERRO AO LER INTENSIDADE WIFI"},
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
            uint32_t cmd_seq = pw_next_sequence_id();
            pw_log_command(cmd_seq, mqtt_data);
            if (number_of_weight_times >= MAX_WEIGHT_TIMES && strcmp(h->prefix, RECEIVED_TIMES) == 0)
            {
                char ack[PW_OUTBOX_PAYLOAD_MAX];
                snprintf(ack, sizeof(ack), "ACK|%lu|%lld|%s|ERR|MAX_WEIGHT_TIMES", (unsigned long)cmd_seq, (long long)pw_now_epoch(), h->prefix);
                mqtt_send_or_spool(cmd_seq, MQTT_TOPIC_ACKS, OUTBOX_QOS, ack);
                mqtt_publish(MQTT_TOPIC_WEIGHTS, "ERROR_MAX_WEIGHT_TIMES_ACHIEVED", 1);
                return;
            }

            const char *SUCCESS_MSG = "1";
            const char *ERROR_MSG = "0";
            const char *data = mqtt_data + len;
            esp_err_t result = h->handler(data);
            if (result == ESP_OK)
            {
                char ack[PW_OUTBOX_PAYLOAD_MAX];
                snprintf(ack, sizeof(ack), "ACK|%lu|%lld|%s|OK", (unsigned long)cmd_seq, (long long)pw_now_epoch(), h->prefix);
                mqtt_send_or_spool(cmd_seq, MQTT_TOPIC_ACKS, OUTBOX_QOS, ack);
                mqtt_publish(MQTT_TOPIC_WEIGHTS, SUCCESS_MSG, 1);
                ESP_LOGI(ROTULO_LOCAL, "%s", h->log_success);
                // if (strstr(h->log_success, "%s"))
                //     ESP_LOGI(ROTULO_LOCAL, "%s - %s", h->log_success, baby_id);
                // else
                // ESP_LOGI(ROTULO_LOCAL, "%s", h->log_success);
            }
            else
            {
                sdcard_log(LOG_ERROR, h->log_error, ROTULO_LOCAL);
                char ack[PW_OUTBOX_PAYLOAD_MAX];
                snprintf(ack, sizeof(ack), "ACK|%lu|%lld|%s|ERR", (unsigned long)cmd_seq, (long long)pw_now_epoch(), h->prefix);
                mqtt_send_or_spool(cmd_seq, MQTT_TOPIC_ACKS, OUTBOX_QOS, ack);
                mqtt_publish(MQTT_TOPIC_WEIGHTS, ERROR_MSG, 1);
            }
            return;
        }
    }
}
