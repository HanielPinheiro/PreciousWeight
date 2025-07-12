/**
 Por que simplifiquei o código?
    Motivo: Seu código original tinha um buffer interno e lógica complexa para flushing. Minhas alterações foram focadas em:
        Clareza: Separar funções básicas (init, write_file, log).
        Confiabilidade: Usar esp_vfs_fat_sdmmc (API oficial do ESP-IDF) em vez de buffers gerenciados manualmente.
        Logs estruturados: Adicionei [TAG] TIMESTAMP message para facilitar debugging.

        O que é esp_vfs_fat_sdmmc?
        É a API recomendada pelo ESP-IDF para SD Cards. Ela:
        Gerencia automaticamente o sistema de arquivos (FAT).
        Oferece montagem/desmontagem segura.
        Lida com erros de hardware (ex.: cartão removido).
*/

#include "sdcard.h"
#include "esp_vfs_fat.h"
#include "sdmmc_cmd.h"
#include "driver/sdmmc_host.h"
#include "driver/spi_common.h"
#include "esp_log.h"
#include "esp_timer.h"

/**
Explicação sobre logging:
    No ESP32, "log" normalmente se refere a escrever mensagens de depuração no console via USB.
    Nesse caso, como você quer escrever no SD Card, vamos chamar de:
        sdcard_write_file(): Escreve em qualquer arquivo
        sdcard_log(): Escreve no arquivo de logs padrão com formato específico
*/

static const char *TAG = "SDCARD";
static sdmmc_card_t *card = NULL;

esp_err_t sdcard_init()
{
    sdmmc_host_t host = SDMMC_HOST_DEFAULT();
    sdmmc_slot_config_t slot_config = SDMMC_SLOT_CONFIG_DEFAULT();

    esp_vfs_fat_sdmmc_mount_config_t mount_config = {
        .format_if_mount_failed = false,
        .max_files = 5,
        .allocation_unit_size = 16 * 1024};

    esp_err_t ret = esp_vfs_fat_sdmmc_mount("/sdcard", &host, &slot_config, &mount_config, &card);
    if (ret != ESP_OK)
    {
        ESP_LOGE(TAG, "Falha ao montar SD Card: %s", esp_err_to_name(ret));
        return ret;
    }
    return ESP_OK;
}

esp_err_t sdcard_write_file(const char *path, const char *data)
{
    FILE *f = fopen(path, "a");
    if (f == NULL)
    {
        ESP_LOGE(TAG, "Falha ao abrir arquivo: %s", path);
        return ESP_FAIL;
    }
    fprintf(f, "%s\n", data);
    fclose(f);
    return ESP_OK;
}

esp_err_t sdcard_log(const char *tag, const char *message)
{
    char log_entry[MAX_LOG_LENGTH];
    snprintf(log_entry, MAX_LOG_LENGTH, "[%s] %lld %s", tag, esp_timer_get_time(), message);
    return sdcard_write_file("/sdcard/system/logs.txt", log_entry);
}

void sdcard_deinit()
{
    esp_vfs_fat_sdmmc_unmount();
    card = NULL;
}