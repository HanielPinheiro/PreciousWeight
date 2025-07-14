/*
    Adaptado de: https://github.com/espressif/esp-idf/blob/release/v5.4/examples/provisioning/wifi_prov_mgr/main/app_main.c
    por Haniel Pinheiro
*/

#include "wifi_prov_ble.h"

static EventGroupHandle_t wifi_event_group;
static const char *ROTULO_LOCAL = "wifi_prov_ble";

/* This step is only useful when scheme is wifi_prov_scheme_ble.
 * This will set a custom 128 bit UUID which will be included in the BLE advertisement and will correspond to the primary GATT service that provides provisioning endpoints as GATT characteristics.
 * Each GATT characteristic will be formed using the primary service UUID as base, with different auto assigned 12th and 13th bytes (assume counting starts from 0th byte).
 * The client side applications must identify the endpoints by reading the User Characteristic Description descriptor (0x2901) for each characteristic, which contains the endpoint name of the characteristic.
 * LSB <------------------------------------------------------------------------------> MSB */
static uint8_t custom_service_uuid[] = {
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
        case WIFI_EVENT_STA_DISCONNECTED:
            ESP_LOGI(ROTULO_LOCAL, "Disconnected. Connecting to the AP again...");
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

static void get_device_service_name(char *service_name, size_t max)
{
    uint8_t eth_mac[6];
    const char *ssid_prefix = "PROV_";
    esp_wifi_get_mac(WIFI_IF_STA, eth_mac);
    snprintf(service_name, max, "%s%02X%02X%02X",
             ssid_prefix, eth_mac[3], eth_mac[4], eth_mac[5]);
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

void reset_wifi(void)
{
    ESP_ERROR_CHECK(nvs_flash_erase());
    ESP_ERROR_CHECK(nvs_flash_init());
}

void wifi_init_all(void)
{
    ESP_LOGI(ROTULO_LOCAL, "Inicializando sistema de rede e eventos...");

    /* Initialize NVS partition */
    esp_err_t ret = nvs_flash_init();
    if (ret == ESP_ERR_NVS_NO_FREE_PAGES || ret == ESP_ERR_NVS_NEW_VERSION_FOUND)
    {
        ESP_ERROR_CHECK(nvs_flash_erase()); /* NVS partition was truncated and needs to be erased */
        ESP_ERROR_CHECK(nvs_flash_init());  /* Retry nvs_flash_init */
    }

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

void start_wifi_sta(void) // Conectar usando dados salvos(modo STA)
{
    ESP_LOGI(ROTULO_LOCAL, "Iniciando Wi-Fi STA com credenciais salvas...");
    ESP_ERROR_CHECK(esp_event_handler_register(WIFI_EVENT, ESP_EVENT_ANY_ID, &event_handler, NULL));
    ESP_ERROR_CHECK(esp_wifi_set_mode(WIFI_MODE_STA));
    ESP_ERROR_CHECK(esp_wifi_start());
    xEventGroupWaitBits(wifi_event_group, BIT0, true, true, portMAX_DELAY);
}

void start_ble_provisioning(void)
{ // Provisionamento via BLE pela primeira vez
    ESP_LOGI(ROTULO_LOCAL, "Iniciando provisioning BLE...");

    /* Configuration for the provisioning manager */
    wifi_prov_mgr_config_t config = {
        .wifi_prov_conn_cfg = {
            .wifi_conn_attempts = CONFIG_EXAMPLE_PROV_MGR_CONNECTION_CNT,
        },
        .scheme = wifi_prov_scheme_ble,
        .scheme_event_handler = WIFI_PROV_SCHEME_BLE_EVENT_HANDLER_FREE_BTDM};

    /* Initialize provisioning manager with the configuration parameters set above */
    ESP_ERROR_CHECK(wifi_prov_mgr_init(config));
    // wifi_prov_mgr_disable_auto_stop(10); // mantem ativo até você decidir parar
    wifi_prov_scheme_ble_set_service_uuid(custom_service_uuid);
    wifi_prov_mgr_endpoint_create("PW_PROVISION_DATA");

    char service_name[12];
    get_device_service_name(service_name, sizeof(service_name));
    const char *service_key = NULL;
    const char *pop = "abcd1234";
    wifi_prov_security_t security = WIFI_PROV_SECURITY_1;

    ESP_ERROR_CHECK(wifi_prov_mgr_start_provisioning(security, (const void *)pop, service_name, service_key));
    wifi_prov_mgr_endpoint_register("custom-data", custom_prov_data_handler, NULL);
    xEventGroupWaitBits(wifi_event_group, BIT0, true, true, portMAX_DELAY);
}

void wifi_setup(void)
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