/**
 * Exemplo extraido e adaptado de: https://github.com/espressif/esp-idf/blob/5b11d5b26a8bf151fc6bac400158859eedd413bc/examples/storage/sd_card/sdspi/main/sd_card_example_main.c
 * Por Haniel Pinheiro em 12/07/2025
 */

#include "sdcard.h"

static const char *ROTULO_LOCAL = "SdCard";

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
        ESP_LOGE(ROTULO_LOCAL, "Falha ao iniciar o Bus SPI.");
        return ESP_FAIL;
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
        {
            ESP_LOGE(ROTULO_LOCAL, "Falha na montagem do sistema de arquivos. Se desejar formatar, use a função sdcard_format.");
        }
        else
        {
            ESP_LOGE(ROTULO_LOCAL, "Erro não tratado. Mensagem: {%s}.", esp_err_to_name(ret));
        }
        return ESP_FAIL;
    }

    // host.max_freq_khz = 10000; // Aumento a velocidade do Bus - Opcional

    ESP_LOGI(ROTULO_LOCAL, "Sistema de arquivos montado. Driver inicializado com sucesso.");
    sdmmc_card_print_info(stdout, sdcard);
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

esp_err_t sdcard_log(log_type_t log_type, char *message)
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

    return sdcard_write_file(LOG_FILE, log_entry);
}

// esp_err_t sdcard_read_file(char *path)
// {
//     //Precisa ser melhorada
//     if (!sdcard_check_file_exists(path))
//     {
//         ESP_LOGE(ROTULO_LOCAL, "Arquivo não existe {%s}", path);
//         return ESP_FAIL;
//     }

//     ESP_LOGI(ROTULO_LOCAL, "Lendo arquivo %s", path);
//     FILE *file = fopen(path, "r");

//     if (file == NULL)
//     {
//         ESP_LOGE(ROTULO_LOCAL, "Failed to open file for reading at path {%s}", path);
//         return ESP_FAIL;
//     }

//     char line[64]; // from original example
//     fgets(line, sizeof(line), file);
//     fclose(file);

//     return ESP_OK;
// }

// static char log_buffer[LINES][MAX_LOG_LENGTH];
// static uint16_t log_count = 0;

// static const char *TAG = "SD_CARD";
// sdmmc_card_t *sdcard = NULL;
// static char log_buffer[MAX_LOG_ENTRIES][MAX_LOG_LENGTH];
// static uint16_t log_count = 0;

// esp_err_t sdcard_init(void)
// {
//     // Define que estou usando o modulo sd na configuração de conexão (pinos)   SPI
//     sdmmc_host_t host = SDSPI_HOST_DEFAULT();
//     host.max_freq_khz = 4000; // ← Correct speed setting 4MHz

//     // Ajusta pullup dos pinos:
//     gpio_set_pull_mode(GPIO_NUM_5, GPIO_PULLUP_ONLY);  // CS
//     gpio_set_pull_mode(GPIO_NUM_19, GPIO_PULLUP_ONLY); // MISO (obrigatório!)

//     // Configura o trafego de informação via cabos (BUS)
//     spi_bus_config_t bus_cfg = {
//         .mosi_io_num = GPIO_NUM_23,
//         .miso_io_num = GPIO_NUM_19,
//         .sclk_io_num = GPIO_NUM_18,
//         .quadwp_io_num = -1,     // Pinos para modo Quad SPI (QSPI), não usado em SD Cards (apenas para memórias Flash/QSPI).
//         .quadhd_io_num = -1,     // Pinos para modo Quad SPI (QSPI), não usado em SD Cards (apenas para memórias Flash/QSPI).
//         .max_transfer_sz = 4000, // Tamanho máximo de cada transferência SPI. No codigo github está 4000
//     };
//     // Inicializa o Bus SPI
//     ESP_ERROR_CHECK(spi_bus_initialize(host.slot, &bus_cfg, SDSPI_DEFAULT_DMA));

//     // Configura as informações de CS -SPI device configuration involves setting parameters like clock frequency. The default settings can vary, but commonly include a specific clock frequency, 8-bit data length, and SPI mode 0 (CPOL=0, CPHA=0)
//     sdspi_device_config_t slot_config = SDSPI_DEVICE_CONFIG_DEFAULT();
//     slot_config.gpio_cs = GPIO_NUM_5;
//     slot_config.host_id = host.slot;

//     // Montagem remete a criação virtual (dentro do sofware) do driver de comunicação
//     esp_vfs_fat_sdmmc_mount_config_t mount_config = {
//         .format_if_mount_failed = false,
//         .max_files = 3,                    // Número máximo de arquivos abertos simultaneamente.(Cada arquivo aberto consome ~20 bytes de RAM). RAM_consumida = max_files * sizeof(FILE) + buffers  // ~100-200 bytes no total
//         .allocation_unit_size = 16 * 1024, // Tamanho do cluster (unidade de alocação) do sistema de arquivos FAT.Documentação oficial sugere múltiplos de 4096 (ex.: 4KB, 16KB, 32KB).
//     };
//     /**
//      * Quando Ajustar Esses Valores Acima?
//         Aumente 'allocation_unit_size' se Escrever arquivos grandes (>1MB) para melhor desempenho.
//         Reduza 'max_files' se Memória RAM estiver crítica (ex.: ESP32 com <80KB livres).
//         Aumente 'max_transfer_sz' se Usar SD Cards de alta velocidade (teste com 8KB ou 16KB).
//     */
//     esp_err_t ret = esp_vfs_fat_sdspi_mount(MOUNT_POINT, &host, &slot_config, &mount_config, &sdcard);

//     if (ret != ESP_OK)
//     {
//         ESP_LOGE(TAG, "Mount failed: %s", esp_err_to_name(ret));
//         spi_bus_free(host.slot);
//         return ret;
//     }

//     // Corrigi a frequencia de comunicação, em SPI o teto é 20000 kHz = 20 MHz. Deve iniciar com valor perto de 4000 (4 MHz) se não, ocorre erro de montagem.
//     // host.max_freq_khz = 8000;
//     return ESP_OK;
// }

// // Buffered Logging (Power-Aware)
// esp_err_t sdcard_log(const char *tag, const char *message, bool flush_immediately)
// {
//     /*
//     Exemplo de uso:
//         sdcard_log("TAG", "Mensagem", false); // Armazena no buffer
//         sdcard_log(NULL, NULL, true); // Força escrita no SD Card
//     Quando Usar o Buffer (Escrita em Memória RAM):
//         Dados não críticos: Logs de debug, telemetria periódica.
//         Frequência alta: Muitas mensagens em curto intervalo (ex.: sensores lendo a cada 100ms).
//         Economia de energia: Evita acordar o SD Card frequentemente (útil em baterias).
//         Prioridade de desempenho: Se outras tarefas (ex.: WiFi) não podem ser bloqueadas por I/O lento.
//     Quando Escrever Direto no SD Card:
//         Dados críticos: Eventos de erro, alarmes, ou dados que não podem ser perdidos (ex.: falha de hardware).
//         Baixa frequência: Eventos raros (ex.: configuração salva pelo usuário).
//         Buffer cheio: Quando log_count >= MAX_LOG_ENTRIES (flush automático).
//         Desligamento iminente: Antes de entrar em modo deep sleep ou reiniciar.
//     */

//     // 1. Flush imediato (se solicitado)
//     if (flush_immediately)
//     {
//         return sdcard_flush();
//     }
//     // 2. Se o buffer estiver cheio, força o flush
//     if (log_count >= MAX_LOG_ENTRIES)
//     {
//         esp_err_t ret = sdcard_flush();
//         if (ret != ESP_OK)
//         {
//             return ret; // Retorna erro se o flush falhar
//         }
//     }
//     // 3. Armazena a mensagem no buffer
//     if (log_count < MAX_LOG_ENTRIES)
//     {
//         snprintf(log_buffer[log_count], MAX_LOG_LENGTH, "[%s] %lld %s", tag, esp_timer_get_time(), message);
//         log_count++;
//         return ESP_OK;
//     }

//     return ESP_FAIL; // Caso inesperado (buffer cheio mesmo após flush)
// }

// Vamos precisar de duas funções, uma pra escrever forçado, outra pra dar o flush do buffer

// esp_err_t sdcard_flush(void)
// {
//     if (sdcard == NULL)
//     {
//         ESP_LOGE(TAG, "SD Card não inicializado");
//         return ESP_FAIL;
//     }
//     // MEXER AQUI AAAAAAAAAAAAAAAAAAAAAAAAA
//     // 2. Tenta abrir o arquivo (verificação implícita de montagem)
//     FILE *file = fopen(LOG_FILE, "a");
//     if (file == NULL)
//     {
//         ESP_LOGE(TAG, "Falha ao abrir arquivo (SD Card desmontado?)");
//         return ESP_FAIL;
//     }

//     // 3. Processa o buffer
//     for (uint16_t i = 0; i < log_count; i++)
//     {
//         if (fprintf(file, "%s\n", log_buffer[i]) < 0)
//         {
//             fclose(file);
//             ESP_LOGE(TAG, "Falha na escrita");
//             return ESP_FAIL;
//         }
//     }

//     fclose(file);
//     log_count = 0; // Zera somente após escrita bem-sucedida
//     ESP_LOGI(TAG, "Tudo ok, escreveu");
//     return ESP_OK;
// }

// // Safe Unmount (with SPI Power-Down)
// void sdcard_cleanup(bool power_down_spi)
// { // Como ejetar um pendrive com segurança no Windows antes de removê-lo
//     // Quando usar: Ao finalizar o programa ou se o cartão for removido fisicamente.
//     if (sdcard)
//     {
//         esp_vfs_fat_sdcard_unmount(MOUNT_POINT, sdcard); // ← Modern unmount
//         sdcard = NULL;

//         if (power_down_spi)
//         {
//             spi_bus_free(SDSPI_DEFAULT_HOST);
//         }
//     }
// }