#include "../../config/config.h"

static const char *ROTULO_LOCAL = "PW_PERSIST";
static const char *STORAGE_NAMESPACE = "storage";

static uint32_t sequence_id = 0;
static bool nvs_ready = false;
static esp_reset_reason_t boot_reason = 0;
static int64_t boot_epoch = 0;

static esp_err_t pw_nvs_open(nvs_handle_t *out)
{
    if (nvs_open(STORAGE_NAMESPACE, NVS_READWRITE, out) != ESP_OK)
        return ESP_FAIL;
    return ESP_OK;
}

esp_err_t pw_persistence_init(void)
{
    nvs_handle_t h = 0;
    if (pw_nvs_open(&h) != ESP_OK)
    {
        nvs_ready = false;
        return ESP_FAIL;
    }

    uint32_t seq = 0;
    esp_err_t err = nvs_get_u32(h, "seq", &seq);
    if (err == ESP_OK)
        sequence_id = seq;
    else
        sequence_id = 0;

    nvs_ready = true;
    nvs_close(h);
    return ESP_OK;
}

uint32_t pw_current_sequence_id(void)
{
    return sequence_id;
}

uint32_t pw_next_sequence_id(void)
{
    sequence_id++;

    if (!nvs_ready)
        return sequence_id;

    nvs_handle_t h = 0;
    if (pw_nvs_open(&h) != ESP_OK)
        return sequence_id;

    if (nvs_set_u32(h, "seq", sequence_id) == ESP_OK)
        nvs_commit(h);
    nvs_close(h);
    return sequence_id;
}

int64_t pw_now_epoch(void)
{
    time_t now = 0;
    time(&now);
    return (int64_t)now;
}

static const char *pw_sev_to_str(pw_severity_t sev)
{
    switch (sev)
    {
    case PW_SEV_INFO:
        return "INFO";
    case PW_SEV_WARN:
        return "WARN";
    case PW_SEV_ERROR:
        return "ERROR";
    case PW_SEV_CRITICAL:
        return "CRITICAL";
    default:
        return "INFO";
    }
}

esp_err_t pw_rotate_if_needed(const char *path, size_t max_size_bytes, uint8_t keep_versions)
{
    if (max_size_bytes == 0 || keep_versions == 0)
        return ESP_OK;

    struct stat st = {0};
    if (stat(path, &st) != 0)
        return ESP_OK;
    if ((size_t)st.st_size < max_size_bytes)
        return ESP_OK;

    char src[96] = {0};
    char dst[96] = {0};

    snprintf(dst, sizeof(dst), "%s.%d", path, keep_versions);
    remove(dst);

    for (int i = (int)keep_versions - 1; i >= 1; i--)
    {
        snprintf(src, sizeof(src), "%s.%d", path, i);
        snprintf(dst, sizeof(dst), "%s.%d", path, i + 1);
        rename(src, dst);
    }

    snprintf(dst, sizeof(dst), "%s.1", path);
    rename(path, dst);
    return sdcard_overwrite_file(path, "");
}

static esp_err_t pw_append_line(const char *path, size_t max_size, uint8_t keep_versions, const char *line)
{
    (void)pw_rotate_if_needed(path, max_size, keep_versions);
    return sdcard_write_file((char *)path, (char *)line);
}

esp_err_t pw_log_event(pw_severity_t sev, const char *event_type, const char *origin, const char *msg)
{
    uint32_t seq = pw_next_sequence_id();
    int64_t now = pw_now_epoch();

    char line[320] = {0};
    snprintf(line, sizeof(line), "EVT|%lu|%lld|%s|%s|%s|%s",
             (unsigned long)seq, (long long)now, pw_sev_to_str(sev),
             event_type ? event_type : "", origin ? origin : "", msg ? msg : "");

    esp_err_t ret = pw_append_line(AUDIT_FILE, 128 * 1024, 3, line);
    if (sev == PW_SEV_CRITICAL)
        pw_append_line(CRITICAL_FILE, 64 * 1024, 3, line);
    return ret;
}

esp_err_t pw_log_command(uint32_t cmd_seq, const char *command_payload)
{
    int64_t now = pw_now_epoch();
    char line[320] = {0};
    snprintf(line, sizeof(line), "CMD|%lu|%lld|%s",
             (unsigned long)cmd_seq, (long long)now, command_payload ? command_payload : "");
    return pw_append_line(COMMANDS_FILE, 64 * 1024, 3, line);
}

esp_err_t pw_log_measurement(uint32_t meas_seq, const char *origin, double weight)
{
    int64_t now = pw_now_epoch();
    char line[320] = {0};
    snprintf(line, sizeof(line), "MEA|%lu|%lld|%s|%.2f",
             (unsigned long)meas_seq, (long long)now, origin ? origin : "", weight);
    return pw_append_line(MEASUREMENTS_FILE, 128 * 1024, 3, line);
}

esp_err_t pw_state_save_boot(esp_reset_reason_t reason, int64_t epoch)
{
    boot_reason = reason;
    boot_epoch = epoch;
    return pw_state_save();
}

esp_err_t pw_state_save(void)
{
    char snapshot[512] = {0};
    int offset = 0;

    offset += snprintf(snapshot + offset, sizeof(snapshot) - offset, "boot_epoch:%lld;\n", (long long)boot_epoch);
    offset += snprintf(snapshot + offset, sizeof(snapshot) - offset, "reset_reason:%d;\n", (int)boot_reason);
    offset += snprintf(snapshot + offset, sizeof(snapshot) - offset, "baby_id:%s;\n", baby_id);
    for (int i = 0; i < number_of_weight_times && offset < (int)sizeof(snapshot); i++)
        offset += snprintf(snapshot + offset, sizeof(snapshot) - offset, "weight_time:%02d:%02d;\n", weight_times[i].hour, weight_times[i].minutes);

    if (offset <= 0 || offset >= sizeof(snapshot))
    {
        ESP_LOGE(ROTULO_LOCAL, "Snapshot de state excedeu buffer");
        return ESP_FAIL;
    }

    return sdcard_overwrite_file(STATE_FILE, snapshot);
}

esp_err_t pw_outbox_add(uint32_t seq, const char *topic, int qos, const char *payload)
{
    char line[400] = {0};
    snprintf(line, sizeof(line), "P|%lu|%d|%s|%s",
             (unsigned long)seq, qos, topic ? topic : "", payload ? payload : "");
    return pw_append_line(OUTBOX_FILE, 256 * 1024, 2, line);
}

esp_err_t pw_outbox_mark_sent(uint32_t seq)
{
    char line[64] = {0};
    snprintf(line, sizeof(line), "S|%lu", (unsigned long)seq);
    return pw_append_line(OUTBOX_FILE, 256 * 1024, 2, line);
}

esp_err_t pw_outbox_load_pending(pw_outbox_entry_t *entries, size_t max_entries, size_t *out_count)
{
    if (out_count)
        *out_count = 0;
    if (entries == NULL || out_count == NULL || max_entries == 0)
        return ESP_ERR_INVALID_ARG;

    struct stat st = {0};
    if (stat(OUTBOX_FILE, &st) != 0)
        return ESP_OK;

    FILE *file = fopen(OUTBOX_FILE, "r");
    if (file == NULL)
        return ESP_FAIL;

    uint32_t sent_ids[64] = {0};
    size_t sent_count = 0;
    pw_outbox_entry_t pending[64] = {0};
    size_t pending_count = 0;

    char line[512] = {0};
    while (fgets(line, sizeof(line), file))
    {
        if (line[0] == 'S' && line[1] == '|')
        {
            unsigned long seq = 0;
            if (sscanf(line, "S|%lu", &seq) == 1 && sent_count < 64)
                sent_ids[sent_count++] = (uint32_t)seq;
            continue;
        }

        if (line[0] == 'P' && line[1] == '|')
        {
            unsigned long seq = 0;
            int qos = 0;
            char topic[PW_OUTBOX_TOPIC_MAX] = {0};
            char payload[PW_OUTBOX_PAYLOAD_MAX] = {0};

            char *p = line + 2;
            char *t1 = strchr(p, '|');
            if (!t1)
                continue;
            *t1 = '\0';
            seq = strtoul(p, NULL, 10);

            char *p2 = t1 + 1;
            char *t2 = strchr(p2, '|');
            if (!t2)
                continue;
            *t2 = '\0';
            qos = atoi(p2);

            char *p3 = t2 + 1;
            char *t3 = strchr(p3, '|');
            if (!t3)
                continue;
            *t3 = '\0';
            strncpy(topic, p3, sizeof(topic) - 1);

            char *p4 = t3 + 1;
            size_t len = strcspn(p4, "\r\n");
            p4[len] = '\0';
            strncpy(payload, p4, sizeof(payload) - 1);

            if (pending_count < 64)
            {
                pending[pending_count].seq = (uint32_t)seq;
                pending[pending_count].qos = qos;
                strncpy(pending[pending_count].topic, topic, sizeof(pending[pending_count].topic) - 1);
                strncpy(pending[pending_count].payload, payload, sizeof(pending[pending_count].payload) - 1);
                pending_count++;
            }
        }
    }

    fclose(file);

    size_t out_idx = 0;
    for (size_t i = 0; i < pending_count && out_idx < max_entries; i++)
    {
        bool is_sent = false;
        for (size_t j = 0; j < sent_count; j++)
        {
            if (sent_ids[j] == pending[i].seq)
            {
                is_sent = true;
                break;
            }
        }
        if (!is_sent)
            entries[out_idx++] = pending[i];
    }

    *out_count = out_idx;
    return ESP_OK;
}

