/**
 * Exemplo extraido e adaptado de: https://github.com/espressif/esp-idf/blob/5b11d5b26a8bf151fc6bac400158859eedd413bc/examples/storage/sd_card/sdspi/main/sd_card_example_main.c
 * Por Haniel Pinheiro em 12/07/2025
 */

#include "sdcard.h"

static const char *ROTULO_LOCAL = "SD_CARD";

struct stat st;
sdmmc_card_t *sdcard = NULL;
sdmmc_host_t host = SDSPI_HOST_DEFAULT(); // Define que estou usando o modulo sd na configuração de conexão (pinos)   SPI

esp_err_t sdcard_init(void)
{
    // Montagem remete a criação virtual (dentro do sofware) do driver de comunicação
    esp_vfs_fat_sdmmc_mount_config_t mount_config = {
        .format_if_mount_failed = false,
        .max_files = 3,                    // Número máximo de arquivos abertos simultaneamente.(Cada arquivo aberto consome ~20 bytes de RAM). RAM_consumida = max_files * sizeof(FILE) + buffers  // ~100-200 bytes no total
        .allocation_unit_size = 16 * 1024, // Tamanho do cluster (unidade de alocação) do sistema de arquivos FAT.Documentação oficial sugere múltiplos de 4096 (ex.: 4KB, 16KB, 32KB).
    };

    host.max_freq_khz = 4000; // ← Ajusta a velocidade do BUS para 4MHz

    // Ajusta pullup dos pinos:
    gpio_set_pull_mode(GPIO_NUM_5, GPIO_PULLUP_ONLY);  // CS
    gpio_set_pull_mode(GPIO_NUM_19, GPIO_PULLUP_ONLY); // MISO (obrigatório!)

    // Configura o trafego de informação via cabos (BUS)
    spi_bus_config_t bus_cfg = {
        .mosi_io_num = GPIO_NUM_23,
        .miso_io_num = GPIO_NUM_19,
        .sclk_io_num = GPIO_NUM_18,
        .quadwp_io_num = -1,     // Pinos para modo Quad SPI (QSPI), não usado em SD Cards (apenas para memórias Flash/QSPI).
        .quadhd_io_num = -1,     // Pinos para modo Quad SPI (QSPI), não usado em SD Cards (apenas para memórias Flash/QSPI).
        .max_transfer_sz = 4000, // Tamanho máximo de cada transferência SPI. No codigo github está 4000
    };

    /**
    * Quando Ajustar Esses Valores Acima?
        Aumente 'allocation_unit_size' se Escrever arquivos grandes (>1MB) para melhor desempenho.
        Reduza 'max_files' se Memória RAM estiver crítica (ex.: ESP32 com <80KB livres).
        Aumente 'max_transfer_sz' se Usar SD Cards de alta velocidade (teste com 8KB ou 16KB).
    */

    ESP_LOGI(ROTULO_LOCAL, "Iniciando o driver.");
    esp_err_t ret = spi_bus_initialize(host.slot, &bus_cfg, SDSPI_DEFAULT_DMA);
    if (ret != ESP_OK)
    {
        ESP_LOGE(ROTULO_LOCAL, "Falha no SPI: %s", esp_err_to_name(ret));
        return ret;
    }

    ESP_LOGI(ROTULO_LOCAL, "Bus inicializado.");
    // This initializes the slot without card detect (CD) and write protect (WP) signals.
    // Modify slot_config.gpio_cd and slot_config.gpio_wp if your board has these signals.
    sdspi_device_config_t slot_config = SDSPI_DEVICE_CONFIG_DEFAULT();
    slot_config.gpio_cs = GPIO_NUM_5;
    slot_config.host_id = host.slot;

    ESP_LOGI(ROTULO_LOCAL, "Montando Sistema de Arquivos (FAT)");
    ret = esp_vfs_fat_sdspi_mount(MOUNT_POINT, &host, &slot_config, &mount_config, &sdcard);

    if (ret != ESP_OK)
    {
        if (ret == ESP_FAIL)
            ESP_LOGE(ROTULO_LOCAL, "Falha na montagem do sistema de arquivos. Se desejar formatar, use a função sdcard_format.");
        else
            ESP_LOGE(ROTULO_LOCAL, "Erro não tratado. Mensagem: {%s}.", esp_err_to_name(ret));
        return ret;
    }

    // host.max_freq_khz = 10000; // Aumento a velocidade do Bus - Opcional

    ESP_LOGI(ROTULO_LOCAL, "Sistema de arquivos montado. Driver inicializado com sucesso.");
    // sdmmc_card_print_info(stdout, sdcard);
    return ESP_OK;
}

esp_err_t sdcard_write_file(char *path, char *data)
{
    if (sdcard_check_file_exists(path) < 0)
    {
        ESP_LOGI(ROTULO_LOCAL, "Arquivo nao encontrado. Criando arquivo {%s}", path);
        esp_err_t resultado = sdcard_create_file(path);
        if (resultado != ESP_OK)
        {
            ESP_LOGE(ROTULO_LOCAL, "Falha ao criar o arquivo {%s} para escrita.", path);
            return ESP_FAIL;
        }
    }

    if (MORE_LOGS)
        ESP_LOGI(ROTULO_LOCAL, "Abrindo arquivo {%s}", path);

    FILE *file = fopen(path, "w");
    if (file == NULL)
    {
        ESP_LOGE(ROTULO_LOCAL, "Falha ao abrir o arquivo {%s} para escrita.", path);
        return ESP_FAIL;
    }

    int result = fprintf(file, data);
    fclose(file);

    if (result < 0)
    {
        ESP_LOGE(ROTULO_LOCAL, "Erro ao tentar escrever os dados {%s} no arquivo, no caminho {%s}.", data, path);
        return ESP_FAIL;
    }

    if (MORE_LOGS)
        ESP_LOGI(ROTULO_LOCAL, "Arquivo escrito com sucesso.");

    return ESP_OK;
}

esp_err_t sdcard_create_file(char *path)
{
    FILE *file = fopen(path, "ab+");
    if (file)
        return ESP_OK;
    return ESP_FAIL;
}

int sdcard_check_file_exists(char *path)
{
    int result = stat(path, &st);
    return result;
}

esp_err_t sdcard_delete_file(char *path)
{
    if (sdcard_check_file_exists(path))
    {
        unlink(path);
        return ESP_OK;
    }
    else
        return ESP_FAIL;
}

esp_err_t sdcard_rename_file(char *actual_name, char *new_name)
{
    ESP_LOGI(ROTULO_LOCAL, "Renomeando arquivo {%s} para {%s}", actual_name, new_name);
    if (rename(actual_name, new_name) != 0)
    {
        ESP_LOGE(ROTULO_LOCAL, "Falha ao renomear.");
        return ESP_FAIL;
    }

    esp_err_t ret = sdcard_check_file_exists(new_name);
    if (ret != ESP_OK)
    {
        ESP_LOGE(ROTULO_LOCAL, "Falha ao renomear - arquivo como novo nome não localizado.");
        return ESP_FAIL;
    }

    ESP_LOGI(ROTULO_LOCAL, "Arquivo renomeado com sucesso!");
    return ESP_OK;
}

void sdcard_close()
{
    esp_vfs_fat_sdcard_unmount(MOUNT_POINT, sdcard); // All done, unmount partition and disable SPI peripheral
    spi_bus_free(host.slot);                         // turn off spi bus
    ESP_LOGI(ROTULO_LOCAL, "Cartão pode ser removido");
}

esp_err_t sdcard_format()
{
    esp_err_t ret = esp_vfs_fat_sdcard_format(MOUNT_POINT, sdcard);
    if (ret != ESP_OK)
    {
        ESP_LOGE(ROTULO_LOCAL, "Falha ao formatar no sistema de arquivo FAT (%s)", esp_err_to_name(ret));
        return ESP_FAIL;
    }

    ESP_LOGI(ROTULO_LOCAL, "Nenhum arquivo existente, formatação concluída");
    return ESP_OK;
}

esp_err_t sdcard_log(log_type_t log_type, char *message, const char *trace)
{
    //+8 = (+5 da palavra referente ao log, +1 do espaço em branco, +2 das '[]')
    size_t len = strlen(message) + 8;
    char *log_entry = malloc(len);
    if (!log_entry)
        return ESP_FAIL;
    switch (log_type)
    {
    case LOG_INFO:
        snprintf(log_entry, len, "[INFOS] %s", message);
        break;
    case LOG_WARN:
        snprintf(log_entry, len, "[WARNS] %s", message);
        break;
    case LOG_ERROR:
        snprintf(log_entry, len, "[ERROR] %s", message);
        break;
    default:
        snprintf(log_entry, len, "[INFOS] %s", message);
        break;
    }

    notify_uart(trace, message);

    return sdcard_write_file(LOG_FILE, log_entry);
}

void notify_uart(const char *stack_trace, char *message)
{
    if (!MODO_DEBUG)
        return;
    ESP_LOGI(stack_trace, "%s", message);
}