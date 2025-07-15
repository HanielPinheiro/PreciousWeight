/* Adaptado de: https://github.com/espressif/esp-idf/tree/master/examples/protocols/mqtt/ssl_mutual_auth
 * por Haniel Pinheiro - MQTT v3*/
/*
    Gerar client.key e client.csr com openssl, usando ca.crt gerado por mim:
    Generate your own CA:
        openssl genrsa -out ca.key 4096
        openssl req -x509 -new -nodes -key ca.key -sha256 -days 3650 -out ca.crt
    Generate Client Certificate (signed by your CA)
        openssl genrsa -out client.key 2048
        openssl req -new -key client.key -out client.csr
        openssl x509 -req -in client.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out client.crt -days 365
    senha do certificado Pr3c10usw3e1ght!@

    Ajustar o caminho ate os certificados no cmakelists global
    Conectar na internet corretament (etapa feita pelo wifi_prov_ble), e então evoluir pro codigo atual
*/

#include "mqtt3.h"
static const char *ROTULO_LOCAL = "mqtt3";

extern const uint8_t client_cert_pem_start[] asm("_binary_client_crt_start");
extern const uint8_t client_cert_pem_end[] asm("_binary_client_crt_end");
extern const uint8_t client_key_pem_start[] asm("_binary_client_key_start");
extern const uint8_t client_key_pem_end[] asm("_binary_client_key_end");
extern const uint8_t ca_cert_pem_start[] asm("_binary_ca_crt_start");
extern const uint8_t ca_cert_pem_end[] asm("_binary_ca_crt_end");

static void log_error_if_nonzero(const char *message, int error_code)
{
    if (error_code != 0)
    {
        ESP_LOGE(ROTULO_LOCAL, "Last error %s: 0x%x", message, error_code);
    }
}

/*
 * @brief Event handler registered to receive MQTT events
 *
 *  This function is called by the MQTT client event loop.
 *
 * @param handler_args user data registered to the event.
 * @param base Event base for the handler(always MQTT Base in this example).
 * @param event_id The id for the received event.
 * @param event_data The data for the event, esp_mqtt_event_handle_t.
 */
static void mqtt_event_handler(void *handler_args, esp_event_base_t base, int32_t event_id, void *event_data)
{
    ESP_LOGD(ROTULO_LOCAL, "Event dispatched from event loop base=%s, event_id=%" PRIi32, base, event_id);
    esp_mqtt_event_handle_t event = event_data;
    esp_mqtt_client_handle_t client = event->client;
    int msg_id;

    switch ((esp_mqtt_event_id_t)event_id)
    {
    case MQTT_EVENT_CONNECTED:
        ESP_LOGI(ROTULO_LOCAL, "MQTT_EVENT_CONNECTED");
        msg_id = esp_mqtt_client_subscribe(client, "/topic/qos0", 0);
        ESP_LOGI(ROTULO_LOCAL, "sent subscribe successful, msg_id=%d", msg_id);

        msg_id = esp_mqtt_client_subscribe(client, "/topic/qos1", 1);
        ESP_LOGI(ROTULO_LOCAL, "sent subscribe successful, msg_id=%d", msg_id);

        msg_id = esp_mqtt_client_unsubscribe(client, "/topic/qos1");
        ESP_LOGI(ROTULO_LOCAL, "sent unsubscribe successful, msg_id=%d", msg_id);
        break;

    case MQTT_EVENT_DISCONNECTED:
        ESP_LOGI(ROTULO_LOCAL, "MQTT_EVENT_DISCONNECTED");
        break;

    case MQTT_EVENT_SUBSCRIBED:
        ESP_LOGI(ROTULO_LOCAL, "MQTT_EVENT_SUBSCRIBED, msg_id=%d", event->msg_id);
        msg_id = esp_mqtt_client_publish(client, "/topic/qos0", "data", 0, 0, 0);
        ESP_LOGI(ROTULO_LOCAL, "sent publish successful, msg_id=%d", msg_id);
        break;

    case MQTT_EVENT_UNSUBSCRIBED:
        ESP_LOGI(ROTULO_LOCAL, "MQTT_EVENT_UNSUBSCRIBED, msg_id=%d", event->msg_id);
        break;

    case MQTT_EVENT_PUBLISHED:
        ESP_LOGI(ROTULO_LOCAL, "MQTT_EVENT_PUBLISHED, msg_id=%d", event->msg_id);
        break;

    case MQTT_EVENT_DATA:
        ESP_LOGI(ROTULO_LOCAL, "MQTT_EVENT_DATA");
        printf("TOPIC=%.*s\r\n", event->topic_len, event->topic);
        printf("DATA=%.*s\r\n", event->data_len, event->data);
        break;

    case MQTT_EVENT_ERROR:
        ESP_LOGI(ROTULO_LOCAL, "MQTT_EVENT_ERROR");
        if (event->error_handle->error_type == MQTT_ERROR_TYPE_TCP_TRANSPORT)
        {
            log_error_if_nonzero("reported from esp-tls", event->error_handle->esp_tls_last_esp_err);
            log_error_if_nonzero("reported from tls stack", event->error_handle->esp_tls_stack_err);
            log_error_if_nonzero("captured as transport's socket errno", event->error_handle->esp_transport_sock_errno);
            ESP_LOGI(ROTULO_LOCAL, "Last errno string (%s)", strerror(event->error_handle->esp_transport_sock_errno));
        }
        break;

    default:
        ESP_LOGI(ROTULO_LOCAL, "Other event id:%d", event->event_id);
        break;
    }
}

static void mqtt_app_start(void)
{
    const esp_mqtt_client_config_t mqtt_cfg = {
        .broker.address.uri = "mqtts://192.168.0.15:8883",
        .broker.verification.certificate = (const char *)ca_cert_pem_start,

        /*  Na criptografia TLS, o cliente deve garantir que está falando com o servidor certo. Isso é feito comparando:
         *  Common Name (CN) ou Subject Alternative Name (SAN) DO certificado do servidor COM o nome do host no URI (broker.address.uri)
         *  Essa opção(.broker.verification.skip_cert_common_name_check = true) diz ao ESP32: Não se preocupe se o nome comum (CN) do certificado do servidor
         *  não bate com o hostname que estou usando no código.
         *  Se seu server.crt tem: CN = precious_weight E seu código usa: .broker.address.uri = "mqtts://192.168.0.10:8883"
         *  O ESP32 rejeita com mbedtls_ssl_handshake returned -0x2700
         *  Em ambiente de produção, o ideal é: 1. Usar nomes de domínio válidos (FQDN); 2. Certificados com CN = nome do domínio;
         *  3. E não usar .skip_cert_common_name_check = true para garantir segurança contra ataques man-in-the-middle (MITM)
         *  O esp nao comporta conexoes com CN=192.168.0.10 (CN = IP), portanto, testar usando .broker.verification.skip_cert_common_name_check = true e depois desativar em producao*/
        .broker.verification.skip_cert_common_name_check = true,
        /** */

        .credentials = {
            .authentication = {
                .certificate = (const char *)client_cert_pem_start,
                .key = (const char *)client_key_pem_start,
            },
        }};

    ESP_LOGI(ROTULO_LOCAL, "[APP] Free memory: %" PRIu32 " bytes", esp_get_free_heap_size());
    esp_mqtt_client_handle_t client = esp_mqtt_client_init(&mqtt_cfg);

    /* The last argument may be used to pass data to the event handler, in this example mqtt_event_handler */
    esp_mqtt_client_register_event(client, ESP_EVENT_ANY_ID, mqtt_event_handler, NULL);
    esp_mqtt_client_start(client);
}

void mqtt_mutal_ssl_v3(void)
{
    ESP_LOGI(ROTULO_LOCAL, "[APP] Startup..");
    ESP_LOGI(ROTULO_LOCAL, "[APP] Free memory: %" PRIu32 " bytes", esp_get_free_heap_size());
    ESP_LOGI(ROTULO_LOCAL, "[APP] IDF version: %s", esp_get_idf_version());

    // ESP_LOGI(ROTULO_LOCAL, "CA Cert start:\n%.200s", ca_cert_pem_start);
    // ESP_LOGI(ROTULO_LOCAL, "Cliente Key start:\n%.200s", client_key_pem_start);
    // ESP_LOGI(ROTULO_LOCAL, "Client Cert start:\n%.200s", client_cert_pem_start);

    esp_log_level_set("*", ESP_LOG_VERBOSE);
    esp_log_level_set("mqtt_client", ESP_LOG_VERBOSE);
    esp_log_level_set("transport_base", ESP_LOG_VERBOSE);
    esp_log_level_set("transport", ESP_LOG_VERBOSE);
    esp_log_level_set("outbox", ESP_LOG_VERBOSE);

    mqtt_app_start();
}