#include "sdcard.h"
#include "esp_log.h"
#include "esp_timer.h"
#include "driver/spi_common.h"

static const char *TAG = "SDCARD";
sdmmc_card_t *sdcard = NULL;
static char log_buffer[MAX_LOG_ENTRIES][256];
static uint16_t log_count = 0;

esp_err_t sdcard_setup(void)
{
    sdmmc_host_t host = SDSPI_HOST_DEFAULT();
    host.max_freq_khz = 4000; // ← Correct speed setting

    spi_bus_config_t bus_cfg = {
        .mosi_io_num = GPIO_NUM_23,
        .miso_io_num = GPIO_NUM_19,
        .sclk_io_num = GPIO_NUM_18,
        .quadwp_io_num = -1,
        .quadhd_io_num = -1,
        .max_transfer_sz = 2048,
    };

    ESP_ERROR_CHECK(spi_bus_initialize(host.slot, &bus_cfg, SDSPI_DEFAULT_DMA));

    sdspi_device_config_t slot_config = SDSPI_DEVICE_CONFIG_DEFAULT();
    slot_config.gpio_cs = GPIO_NUM_5;
    slot_config.host_id = host.slot;

    esp_vfs_fat_sdmmc_mount_config_t mount_config = {
        .format_if_mount_failed = false,
        .max_files = 3,
        .allocation_unit_size = 4096,
    };

    esp_err_t ret = esp_vfs_fat_sdmmc_mount(MOUNT_POINT, &host, &slot_config, &mount_config, &sdcard);
    if (ret != ESP_OK)
    {
        ESP_LOGE(TAG, "Mount failed: %s", esp_err_to_name(ret));
        spi_bus_free(host.slot);
        return ret;
    }
    return ESP_OK;
}

// Buffered Logging (Power-Aware)
esp_err_t sdcard_log(const char *message, bool flush_immediately)
{
    if (log_count >= MAX_LOG_ENTRIES)
    {
        sdcard_flush(); // Auto-flush if buffer full
    }

    snprintf(log_buffer[log_count++], 256, "[%lld] %s", esp_timer_get_time(), message);

    if (flush_immediately)
    {
        return sdcard_flush();
    }
    return ESP_OK;
}

// Manual Flush (For Critical Data)
esp_err_t sdcard_flush(void)
{
    if (!sdcard || log_count == 0)
        return ESP_OK;

    FILE *file = fopen(LOG_FILE, "a");
    if (!file)
        return ESP_FAIL;

    for (uint16_t i = 0; i < log_count; i++)
    {
        fprintf(file, "%s\n", log_buffer[i]);
    }
    fclose(file);
    log_count = 0;
    return ESP_OK;
}

// Safe Unmount (with SPI Power-Down)
void sdcard_cleanup(bool power_down_spi)
{
    if (sdcard)
    {
        esp_vfs_fat_sdcard_unmount(MOUNT_POINT, sdcard); // ← Modern unmount
        sdcard = NULL;
        if (power_down_spi)
        {
            spi_bus_free(SDSPI_DEFAULT_HOST);
        }
    }
}