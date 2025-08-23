/*
    Adaptado de: https://github.com/espressif/esp-idf/blob/release/v5.4/examples/provisioning/wifi_prov_mgr/main/app_main.c
    por Haniel Pinheiro
*/

#include "wifi_prov_ble.h"

#pragma region DATE_TIME

#define STORAGE_NAMESPACE "storage"
#define TIME_PERIOD (86400000000ULL)

static void initialize_sntp(void)
{
    ESP_LOGI("DATE_TIME", "Initializing SNTP");
    esp_sntp_config_t config = ESP_NETIF_SNTP_DEFAULT_CONFIG_MULTIPLE(2, ESP_SNTP_SERVER_LIST("a.st1.ntp.br", "b.st1.ntp.br"));
    esp_netif_sntp_init(&config);
}

static esp_err_t obtain_time(void)
{
    int retry = 0;
    const int retry_count = 10;

    while (esp_netif_sntp_sync_wait(pdMS_TO_TICKS(2000)) != ESP_OK && ++retry < retry_count)
        ESP_LOGI("DATE_TIME", "Waiting for system time to be set... (%d/%d)", retry, retry_count);

    if (retry == retry_count)
        return ESP_FAIL;

    return ESP_OK;
}

static esp_err_t fetch_and_store_time_in_nvs(void *args)
{
    ESP_LOGI("DATE_TIME", "Iniciando fetch_and_store_time_in_nvs");
    nvs_handle_t my_handle = 0;
    esp_err_t err;

    ESP_LOGI("DATE_TIME", "Inicializando SNTP");
    initialize_sntp();

    ESP_LOGI("DATE_TIME", "Obtendo tempo...");
    if (obtain_time() != ESP_OK)
    {
        ESP_LOGE("DATE_TIME", "Falha ao obter tempo do NTP");
        err = ESP_FAIL;
        goto exit;
    }

    time_t now;
    time(&now);
    ESP_LOGI("DATE_TIME", "Tempo obtido: %lld", now);

    // Open
    err = nvs_open(STORAGE_NAMESPACE, NVS_READWRITE, &my_handle);
    if (err != ESP_OK)
    {
        ESP_LOGE("DATE_TIME", "Erro abrindo NVS: %s", esp_err_to_name(err));
        goto exit;
    }

    // Write
    ESP_LOGI("DATE_TIME", "Armazenando timestamp no NVS");
    err = nvs_set_i64(my_handle, "timestamp", now);
    if (err != ESP_OK)
    {
        ESP_LOGE("DATE_TIME", "Erro escrevendo NVS: %s", esp_err_to_name(err));
        goto exit;
    }

    err = nvs_commit(my_handle);
    if (err != ESP_OK)
        ESP_LOGE("DATE_TIME", "Erro commit NVS: %s", esp_err_to_name(err));

exit:
    if (my_handle != 0)
        nvs_close(my_handle);

    esp_netif_sntp_deinit();

    ESP_LOGI("DATE_TIME", "fetch_and_store_time_in_nvs finalizado: %s", esp_err_to_name(err));
    return err;
}

static void start_date_time()
{
    ESP_ERROR_CHECK(fetch_and_store_time_in_nvs(NULL)); // always update timestamp in NVS when wifi conn drops and restart

    const esp_timer_create_args_t nvs_update_timer_args = {
        .callback = (void *)&fetch_and_store_time_in_nvs,
    };

    esp_timer_handle_t nvs_update_timer;
    ESP_ERROR_CHECK(esp_timer_create(&nvs_update_timer_args, &nvs_update_timer));
    ESP_ERROR_CHECK(esp_timer_start_periodic(nvs_update_timer, TIME_PERIOD));
}

static void set_timezone_gmt3()
{
    setenv("TZ", "EST+3", 1);
    tzset();
}

#pragma endregion

static EventGroupHandle_t wifi_event_group;
static const char *ROTULO_LOCAL = "WIFI";

/* This step is only useful when scheme is wifi_prov_scheme_ble.
 * This will set a custom 128 bit UUID which will be included in the BLE advertisement and will correspond to the primary GATT service that provides provisioning endpoints as GATT characteristics.
 * Each GATT characteristic will be formed using the primary service UUID as base, with different auto assigned 12th and 13th bytes (assume counting starts from 0th byte).
 * The client side applications must identify the endpoints by reading the User Characteristic Description descriptor (0x2901) for each characteristic, which contains the endpoint name of the characteristic.
 * LSB <------------------------------------------------------------------------------> MSB
 * Ex: 550e8400-e29b-41d4-a716-446655440000 -> 550e8400e29b41d4a716446655440000 -> Split into byte pairs (in reverse order for little-endian systems)*/
static uint8_t my_bluetooth_uuid[] = {
    0xb4,
    0xdf,
    0x5a,
    0x1c,
    0x3f,
    0x6b,
    0xf4,
    0xbf,
    0xea,
    0x4a,
    0x82,
    0x03,
    0x04,
    0x90,
    0x1a,
    0x02,
};

/* Event handler for catching system events */
static void event_handler(void *arg, esp_event_base_t event_base, int32_t event_id, void *event_data)
{
    if (event_base == WIFI_PROV_EVENT)
    {
        switch (event_id)
        {
        case WIFI_PROV_START:
            ESP_LOGI(ROTULO_LOCAL, "Provisioning started");
            break;
        case WIFI_PROV_CRED_RECV:
        {
            wifi_sta_config_t *wifi_sta_cfg = (wifi_sta_config_t *)event_data;
            ESP_LOGI(ROTULO_LOCAL, "Received Wi-Fi credentials"
                                   "\n\tSSID     : %s\n\tPassword : %s",
                     (const char *)wifi_sta_cfg->ssid,
                     (const char *)wifi_sta_cfg->password);
            break;
        }
        case WIFI_PROV_CRED_FAIL:
        {
            wifi_prov_sta_fail_reason_t *reason = (wifi_prov_sta_fail_reason_t *)event_data;
            ESP_LOGE(ROTULO_LOCAL, "Provisioning failed!\n\tReason : %s"
                                   "\n\tPlease reset to factory and retry provisioning",
                     (*reason == WIFI_PROV_STA_AUTH_ERROR) ? "Wi-Fi station authentication failed" : "Wi-Fi access-point not found");
            /* Reset the state machine on provisioning failure. It allows the provisioning manager to retry the provisioning process
            based on the number of attempts specified in wifi_conn_attempts.*/
            wifi_prov_mgr_reset_sm_state_on_failure();
            break;
        }
        case WIFI_PROV_CRED_SUCCESS:
            ESP_LOGI(ROTULO_LOCAL, "Provisioning successful");
            break;
        case WIFI_PROV_END: /* De-initialize manager once provisioning is finished */
            wifi_prov_mgr_deinit();
            break;
        default:
            break;
        }
    }
    else if (event_base == WIFI_EVENT)
    {
        switch (event_id)
        {
        case WIFI_EVENT_STA_START:
            esp_wifi_connect();
            break;
        case WIFI_EVENT_STA_CONNECTED:
            ESP_LOGI(ROTULO_LOCAL, "Connected. Getting Date Time from SNTP");

            vTaskDelay(pdMS_TO_TICKS(5000));
            start_date_time();
            set_timezone_gmt3();
            break;

        case WIFI_EVENT_STA_DISCONNECTED:
            ESP_LOGI(ROTULO_LOCAL, "Disconnected. Connecting to the AP again...");
            esp_netif_sntp_deinit();
            esp_wifi_connect();
            break;
        default:
            break;
        }
    }
    else if (event_base == IP_EVENT && event_id == IP_EVENT_STA_GOT_IP)
    {
        ip_event_got_ip_t *event = (ip_event_got_ip_t *)event_data;
        ESP_LOGI(ROTULO_LOCAL, "Connected with IP Address:" IPSTR, IP2STR(&event->ip_info.ip));
        xEventGroupSetBits(wifi_event_group, BIT0); /* Signal main application to continue execution */
    }
    else if (event_base == PROTOCOMM_TRANSPORT_BLE_EVENT)
    {
        switch (event_id)
        {
        case PROTOCOMM_TRANSPORT_BLE_CONNECTED:
            ESP_LOGI(ROTULO_LOCAL, "BLE transport: Connected!");
            break;
        case PROTOCOMM_TRANSPORT_BLE_DISCONNECTED:
            ESP_LOGI(ROTULO_LOCAL, "BLE transport: Disconnected!");
            break;
        default:
            break;
        }
    }
    else if (event_base == PROTOCOMM_SECURITY_SESSION_EVENT)
    {
        switch (event_id)
        {
        case PROTOCOMM_SECURITY_SESSION_SETUP_OK:
            ESP_LOGI(ROTULO_LOCAL, "Secured session established!");
            break;
        case PROTOCOMM_SECURITY_SESSION_INVALID_SECURITY_PARAMS:
            ESP_LOGE(ROTULO_LOCAL, "Received invalid security parameters for establishing secure session!");
            break;
        case PROTOCOMM_SECURITY_SESSION_CREDENTIALS_MISMATCH:
            ESP_LOGE(ROTULO_LOCAL, "Received incorrect username and/or PoP for establishing secure session!");
            break;
        default:
            break;
        }
    }
}

/* Handler for the optional provisioning endpoint registered by the application. The data format can be chosen by applications. Here, we are using plain ascii text.
 * Applications can choose to use other formats like protobuf, JSON, XML, etc.
 * Note that memory for the response buffer must be allocated using heap as this buffer gets freed by the protocomm layer once it has been sent by the transport layer. */
static esp_err_t custom_prov_data_handler(uint32_t session_id, const uint8_t *inbuf, ssize_t inlen, uint8_t **outbuf, ssize_t *outlen, void *priv_data)
{
    if (inbuf)
    {
        ESP_LOGI(ROTULO_LOCAL, "Received data: %.*s", inlen, (char *)inbuf);
    }
    char response[] = "SUCCESS";
    *outbuf = (uint8_t *)strdup(response);
    if (*outbuf == NULL)
    {
        ESP_LOGE(ROTULO_LOCAL, "System out of memory");
        return ESP_ERR_NO_MEM;
    }
    *outlen = strlen(response) + 1; /* +1 for NULL terminating byte */

    return ESP_OK;
}
static void reset_wifi()
{
    ESP_ERROR_CHECK(nvs_flash_erase()); /* NVS partition was truncated and needs to be erased */
    ESP_ERROR_CHECK(nvs_flash_init());  /* Retry nvs_flash_init */
}

static void wifi_init_all()
{
    ESP_LOGI(ROTULO_LOCAL, "Inicializando sistema de rede e eventos...");

    /* Initialize NVS partition */
    esp_err_t ret = nvs_flash_init();
    if (ret == ESP_ERR_NVS_NO_FREE_PAGES || ret == ESP_ERR_NVS_NEW_VERSION_FOUND)
        reset_wifi();

    ESP_ERROR_CHECK(esp_netif_init());                /* Initialize TCP/IP */
    ESP_ERROR_CHECK(esp_event_loop_create_default()); /* Initialize the event loop */

    wifi_event_group = xEventGroupCreate();

    /* Register our event handler for Wi-Fi, IP and Provisioning related events */
    ESP_ERROR_CHECK(esp_event_handler_register(WIFI_PROV_EVENT, ESP_EVENT_ANY_ID, &event_handler, NULL));
    ESP_ERROR_CHECK(esp_event_handler_register(PROTOCOMM_TRANSPORT_BLE_EVENT, ESP_EVENT_ANY_ID, &event_handler, NULL));
    ESP_ERROR_CHECK(esp_event_handler_register(PROTOCOMM_SECURITY_SESSION_EVENT, ESP_EVENT_ANY_ID, &event_handler, NULL));
    ESP_ERROR_CHECK(esp_event_handler_register(IP_EVENT, IP_EVENT_STA_GOT_IP, &event_handler, NULL));

    /* Initialize Wi-Fi including netif with default config */
    esp_netif_create_default_wifi_sta();

    wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();
    ESP_ERROR_CHECK(esp_wifi_init(&cfg));
}

static void start_wifi_sta() // Conectar usando dados salvos(modo STA)
{
    ESP_LOGI(ROTULO_LOCAL, "Iniciando Wi-Fi STA com credenciais salvas...");
    ESP_ERROR_CHECK(esp_event_handler_register(WIFI_EVENT, ESP_EVENT_ANY_ID, &event_handler, NULL));
    ESP_ERROR_CHECK(esp_wifi_set_mode(WIFI_MODE_STA));
    ESP_ERROR_CHECK(esp_wifi_start());
    xEventGroupWaitBits(wifi_event_group, BIT0, true, true, portMAX_DELAY);
}

void full_wifi_reset()
{
    ESP_LOGI(ROTULO_LOCAL, "Performing full WiFi reset...");

    // 2. After stop mqtt client Deinit provisioning manager
    wifi_prov_mgr_deinit();

    // 3. Stop WiFi
    ESP_ERROR_CHECK(esp_wifi_stop());
    ESP_ERROR_CHECK(esp_wifi_deinit());

    // 4. Erase NVS (this is what your reset_wifi does)
    reset_wifi();

    // 5. Restart the ESP32
    ESP_LOGI(ROTULO_LOCAL, "Wi-Fi reseted. Restarting ESP32...");
    vTaskDelay(pdMS_TO_TICKS(1000));
    esp_restart();
}

void start_ble_provisioning()
{ // Provisionamento via BLE pela primeira vez
    ESP_LOGI(ROTULO_LOCAL, "Iniciando provisioning BLE...");

    /* Configuration for the provisioning manager */
    wifi_prov_mgr_config_t config = {
        .wifi_prov_conn_cfg = {
            .wifi_conn_attempts = 3,
        },
        .scheme = wifi_prov_scheme_ble,
        .scheme_event_handler = WIFI_PROV_SCHEME_BLE_EVENT_HANDLER_FREE_BTDM};

    /* Initialize provisioning manager with the configuration parameters set above */
    ESP_ERROR_CHECK(wifi_prov_mgr_init(config));
    ESP_ERROR_CHECK(wifi_prov_scheme_ble_set_service_uuid(my_bluetooth_uuid));
    ESP_ERROR_CHECK(wifi_prov_mgr_endpoint_create("PW_PROVISION_DATA"));
    ESP_ERROR_CHECK(wifi_prov_mgr_start_provisioning(WIFI_PROV_SECURITY_1, MQTT_POP, WIFI_DEVICE_NAME, NULL));
    ESP_ERROR_CHECK(wifi_prov_mgr_endpoint_register("custom-data", custom_prov_data_handler, NULL));

    xEventGroupWaitBits(wifi_event_group, BIT0, true, true, portMAX_DELAY);
}

void init_wifi()
{
    wifi_init_all();

    bool provisioned = false;
    ESP_ERROR_CHECK(wifi_prov_mgr_is_provisioned(&provisioned));

    if (provisioned)
    {
        ESP_LOGI(ROTULO_LOCAL, "Dispositivo já provisionado. Conectando...");
        start_wifi_sta();
        ESP_LOGI(ROTULO_LOCAL, "Conectado");
    }
    else
    {
        ESP_LOGW(ROTULO_LOCAL, "Dispositivo novo. Iniciando provisioning...");
        start_ble_provisioning();
        ESP_LOGI(ROTULO_LOCAL, "Provisionado");
    }
}

void print_efuse_mac()
{ // também é encontrado nessa linha ao ligar a máquina no wifi -> wifi:mode : sta (d0:ef:76:59:0b:7c)
    uint8_t base_mac[6] = {0};
    ESP_ERROR_CHECK(esp_efuse_mac_get_default(base_mac));
    printf("Factory eFuse MAC: %02X:%02X:%02X:%02X:%02X:%02X\n", base_mac[0], base_mac[1], base_mac[2], base_mac[3], base_mac[4], base_mac[5]);
}

bool is_wifi_connected()
{
    wifi_ap_record_t ap_info;
    esp_err_t err = esp_wifi_sta_get_ap_info(&ap_info);

    if (err == ESP_OK)
    {
        ESP_LOGI(ROTULO_LOCAL, "WiFi is connected to SSID: %s", ap_info.ssid);
        return true;
    }
    else if (err == ESP_ERR_WIFI_NOT_CONNECT)
    {
        ESP_LOGI(ROTULO_LOCAL, "WiFi is not connected");
        return false;
    }
    else
    {
        ESP_LOGE(ROTULO_LOCAL, "Failed to get WiFi connection status: %s", esp_err_to_name(err));
        return false;
    }
}

char current_time[SIZE_TIME];
void update_current_time()
{
    time_t now;
    struct tm timeinfo;
    time(&now);                                                        // Obtém o tempo atual
    localtime_r(&now, &timeinfo);                                      // Converte para GMT-3
    strftime(current_time, SIZE_TIME, "%d/%m/%Y %H:%M:%S", &timeinfo); // Formata a string (ex: "04/08/2025 14:30:45")
}