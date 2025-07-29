#include "config_system.h"

static char *ROTULO_LOCAL = "BABY_CONTROL";

char baby_id[12] = {0};
bool has_baby = false;
horario_pesagem_t weight_times[MAX_WEIGHT_TIMES];
uint8_t number_times = 0;

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
{
    // Limpa dados atuais
    memset(baby_id, 0, sizeof(baby_id));
    memset(weight_times, 0, sizeof(weight_times));
    number_times = 0;
    has_baby = false;
    sdcard_clear_file(BABY_HOURS_FILE);
    return ESP_OK;
}

static esp_err_t run_routine()
{
    log_entry_t entry;
    entry.path = BABY_HOURS_FILE;

    int offset = 0;
    offset += snprintf(entry.message, sizeof(entry.message), "baby_id:%s;\n", baby_id);
    for (int i = 0; i < number_times && offset < sizeof(entry.message); i++)
        offset += snprintf(entry.message + offset, sizeof(entry.message) - offset, "weight_time:%02d:%02d;\n", weight_times[i].hora, weight_times[i].minuto);

    ESP_LOGW(ROTULO_LOCAL, "VAI SALVAR: %s", entry.message);

    while (1)
    {
        if (xQueueSend(sdcard_log_queue, &entry, pdMS_TO_TICKS(100)) == pdTRUE)
            break;
        vTaskDelay(pdMS_TO_TICKS(500));
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
        has_baby = true;

        ESP_LOGW(ROTULO_LOCAL, "BABY_ID: %s", baby_id);
        return ESP_OK;
    }
    return ESP_FAIL;
}

static esp_err_t weight_times_routine(const char *data)
{
    horario_pesagem_t weight;
    // Verifica se a string tem formato HH:MM,GMT (ex: "08:00,-3")
    if (strlen(data) >= 8 && data[2] == ':' && data[5] == ',')
    {
        weight.hora = (uint8_t)extract_number(&data[0]);   // HH
        weight.minuto = (uint8_t)extract_number(&data[3]); // MM
        ESP_LOGW(ROTULO_LOCAL, "Horário: %02d:%02d", weight.hora, weight.minuto);

        weight_times[number_times] = weight;
        ESP_LOGW(ROTULO_LOCAL, "[%d] Horário: %02d:%02d", number_times, weight_times[number_times].hora, weight_times[number_times].minuto);
        number_times++;

        return ESP_OK;
    }
    return ESP_FAIL;
}

static esp_err_t measure_routine()
{
    return ESP_OK;
}

static esp_err_t calibrate_routine()
{
    return ESP_OK;
}

static const CommandHandler handlers[] = {
    {RECEIVED_BABY, baby_routine, "BABY_ID_RECEIVED", "ERROR_BABY_ID", "Baby ID recebido", "ERRO AO LER BABY ID"},
    {RECEIVED_WEIGHTS, weight_times_routine, "WEIGHT_TIME_RECEIVED", "ERROR_WEIGHTS", "Horario recebido", "ERRO AO LER WEIGHTS"},
    {RECEIVED_RUN, run_routine, "RUN_RECEIVED", "ERROR_RUN", "Bebe e horarios salvos", "ERRO AO LER RUN"},
    {RECEIVED_CLEAR, clear_routine, "CLEAR_RECEIVED", "ERROR_CLEAR", "Bebe e horarios apagados", "ERRO AO LER CLEAR"},
    {RECEIVED_MEASURE, measure_routine, "MEASURE_RECEIVED", "ERROR_MEASURE", "Medida realizada", "ERRO AO LER MEASURE"},
    {RECEIVED_CALIBRATE, calibrate_routine, "CALIBRATE_RECEIVED", "ERROR_CALIBRATE", "Calibração realizada", "ERRO AO LER CALIBRATE"},
};

void process_mqtt_data(const char *mqtt_data)
{
    int handlers_size = sizeof(handlers) / sizeof(handlers[0]);
    for (int i = 0; i < handlers_size; i++)
    {
        const CommandHandler *h = &handlers[i];
        size_t len = strlen(h->prefix);
        if (strncmp(mqtt_data, h->prefix, len) == 0)
        {
            if (!has_baby && strcmp(h->prefix, RECEIVED_BABY))
            {
                mqtt_publish(MQTT_TOPIC_PUB_WEIGHT, "ERROR_BABY_NOT_INFORMED", 1);
                return;
            }

            if (number_times >= MAX_WEIGHT_TIMES && strcmp(h->prefix, RECEIVED_WEIGHTS))
            {
                mqtt_publish(MQTT_TOPIC_PUB_WEIGHT, "ERROR_MAX_WEIGHT_TIMES_ACHIEVED", 1);
                return;
            }

            const char *data = mqtt_data + len;
            esp_err_t result = h->handler(data);

            if (result == ESP_OK)
            {
                mqtt_publish(MQTT_TOPIC_PUB_WEIGHT, h->success_msg, 1);
                if (strstr(h->log_success, "%s"))
                    ESP_LOGI(ROTULO_LOCAL, "%s - %s", h->log_success, baby_id);
                else
                    ESP_LOGI(ROTULO_LOCAL, "%s", h->log_success);
            }
            else
            {
                sdcard_log(LOG_ERROR, h->log_error, ROTULO_LOCAL);
                mqtt_publish(MQTT_TOPIC_PUB_WEIGHT, h->error_msg, 1);
            }
            return;
        }
    }
}

bool should_measure_weight_now()
{
    time_t now;
    struct tm timeinfo;
    time(&now);
    localtime_r(&now, &timeinfo);

    for (int i = 0; i < number_times; i++)
    {
        ESP_LOGW(ROTULO_LOCAL, "Compare TimeInfo:{%d:%d}, WeightTime[%d]{%d:%d}", timeinfo.tm_hour, timeinfo.tm_min, i, weight_times[i].hora, weight_times[i].minuto);
        if (weight_times[i].hora == timeinfo.tm_hour && weight_times[i].minuto == timeinfo.tm_min)
            return true;
    }
    return false;
}

void handle_estado_sem_bebe()
{
    // iniciar_task_peso();
    // iniciar_task_sd();
    // estado_atual = ESTADO_COM_BEBE;

    // Outros eventos relevantes para estado sem bebê
}

void handle_estado_com_bebe()
{
    // Parar tasks de peso/SD para economizar recursos
    // parar_task_peso();
    // parar_task_sd();
    // estado_atual = ESTADO_SEM_BEBE;
    // realizar_pesagem();
    // enviar_mqtt_se_conectado();
    // salvar_log_sd();
    // if (verificar_sd_cheio())
    // {
    //     compactar_logs_sd(); // Apaga metade dos logs
    // }
    // Outros eventos relevantes para estado com bebê
}

char *get_reset_reason_string(esp_reset_reason_t reason)
{
    switch (reason)
    {
    case ESP_RST_POWERON:
        return "Razao do último reset: Power-On Reset";
    case ESP_RST_SW:
        return "Razao do último reset: Software Reset (esp_restart)";
    case ESP_RST_PANIC:
        return "Razao do último reset: Panic/Crash Reset";
    case ESP_RST_INT_WDT:
        return "Razao do último reset: Interrupt Watchdog Reset";
    case ESP_RST_TASK_WDT:
        return "Razao do ultimo reset: Task Watchdog Reset";
    case ESP_RST_WDT:
        return "Razao do ultimo reset: Other Watchdog Reset";
    case ESP_RST_DEEPSLEEP:
        return "Razao do ultimo reset: Deep Sleep Wakeup";
    case ESP_RST_BROWNOUT:
        return "Razao do ultimo reset: Brownout Reset";
    case ESP_RST_SDIO:
        return "Razao do ultimo reset: SDIO Reset";
    default:
        return "Razao do ultimo reset: Unknown Reset Reason";
    }
}
