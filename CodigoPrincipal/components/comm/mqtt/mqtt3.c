/* Adaptado de: https://github.com/espressif/esp-idf/tree/master/examples/protocols/mqtt/ssl_mutual_auth
 * por Haniel Pinheiro - MQTT v3*/

/*
   Necessita  Conectar na internet corretamente (etapa feita pelo wifi_prov_ble)
   Gerar client.key e client.csr com openssl, usando ca.crt gerado por mim:
   Generate your own CA:
       openssl genrsa -out ca.key 4096
       openssl req -x509 -new -nodes -key ca.key -sha256 -days 3650 -out ca.crt
   Generate Client Certificate (signed by your CA)
       openssl genrsa -out client.key 2048
       openssl req -new -key client.key -out client.csr
       openssl x509 -req -in client.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out client.crt -days 365
   senha do certificado Pr3c10usw3e1ght!@

   Ajustar o caminho ate os certificados no cmakelists
*/
// EXPLICACAO
/*  Na criptografia TLS, o cliente deve garantir que está falando com o servidor certo. Isso é feito comparando:
 *  Common Name (CN) ou Subject Alternative Name (SAN) DO certificado do servidor COM o nome do host no URI (broker.address.uri)
 *  Essa opção(.broker.verification.skip_cert_common_name_check = true) diz ao ESP32: Não se preocupe se o nome comum (CN) do certificado do servidor
 *  não bate com o hostname que estou usando no código.
 *  Se seu server.crt tem: CN = precious_weight E seu código usa: .broker.address.uri = "mqtts://192.168.0.10:8883"
 *  O ESP32 rejeita com mbedtls_ssl_handshake returned -0x2700
 *  Em ambiente de produção, o ideal é: 1. Usar nomes de domínio válidos (FQDN); 2. Certificados com CN = nome do domínio;
 *  3. E não usar .skip_cert_common_name_check = true para garantir segurança contra ataques man-in-the-middle (MITM)
 *  O esp nao comporta conexoes com CN=192.168.0.10 (CN = IP), portanto, testar usando .broker.verification.skip_cert_common_name_check = true e depois desativar em producao*/

#include "mqtt3.h"
#include "buzzer.h"

static const char *ROTULO_LOCAL = "MQTT";
static mqtt_connection_callback_t connection_cb = NULL;
static bool connected = false;
static esp_mqtt_client_handle_t client = NULL;
static SemaphoreHandle_t mqtt_mutex;

extern const uint8_t client_cert_pem_start[] asm("_binary_client_crt_start");
extern const uint8_t client_cert_pem_end[] asm("_binary_client_crt_end");
extern const uint8_t client_key_pem_start[] asm("_binary_client_key_start");
extern const uint8_t client_key_pem_end[] asm("_binary_client_key_end");
extern const uint8_t ca_cert_pem_start[] asm("_binary_ca_crt_start");
extern const uint8_t ca_cert_pem_end[] asm("_binary_ca_crt_end");

esp_mqtt_client_handle_t mqtt_get_client_handle() { return client; }
void mqtt_reset_client_handle() { client = NULL; }

static void mqtt_event_handler(void *handler_args, esp_event_base_t base, int32_t event_id, void *event_data)
{
    esp_mqtt_event_handle_t event = event_data;

    switch ((esp_mqtt_event_id_t)event_id)
    {
    case MQTT_EVENT_CONNECTED:
        if (connection_cb)
            connection_cb(MQTT_STATE_CONNECTED);
        buzzer_short_beep();
        connected = true;
        esp_mqtt_client_subscribe(client, "scales/1", 1);
        break;

    case MQTT_EVENT_DISCONNECTED:
        if (connection_cb)
            connection_cb(MQTT_STATE_DISCONNECTED);
        buzzer_short_alert();
        connected = false;
        break;

    case MQTT_EVENT_ERROR:
        if (connection_cb)
            connection_cb(MQTT_STATE_ERROR);
        connected = false;
        break;

    case MQTT_EVENT_DATA:
        ESP_LOGW(ROTULO_LOCAL, "Received data on topic: %.*s", event->topic_len, event->topic);
        ESP_LOGW(ROTULO_LOCAL, "Data: %.*s", event->data_len, event->data);

        // Exemplo de como tratar dado
        //  if (strncmp(event->topic, "scales/1", event->topic_len) == 0)
        //  {
        //      char msg[event->data_len + 1];
        //      memcpy(msg, event->data, event->data_len);
        //      msg[event->data_len] = '\0';

        //     ESP_LOGI(ROTULO_LOCAL, "Mensagem em scales/1: %s", msg);

        //     // TODO: chamar função para tratar comando
        // }
        break;

    default:
        break;
    }
}

void mqtt_app_start(void)
{
    const esp_mqtt_client_config_t mqtt_cfg = {
        .broker = {
            .address.uri = MQTT_ADDRESS,
            .verification = {
                .certificate = (const char *)ca_cert_pem_start,
                .skip_cert_common_name_check = true}},
        .credentials = {.authentication = {
                            .certificate = (const char *)client_cert_pem_start,
                            .key = (const char *)client_key_pem_start,
                        },
                        .client_id = SERVICE_NAME},
        .session = {.keepalive = MQTT_KEEPALIVE, .disable_clean_session = true, .last_will = {.topic = "/status", .msg = "device_disconnected", .qos = 1, .retain = true}},
        .network = {.reconnect_timeout_ms = 10000, .disable_auto_reconnect = false}};

    client = esp_mqtt_client_init(&mqtt_cfg);
    esp_mqtt_client_register_event(client, ESP_EVENT_ANY_ID, mqtt_event_handler, NULL);
    esp_mqtt_client_start(client);
}

void mqtt_init(mqtt_connection_callback_t ext_connection_cb)
{
    connection_cb = ext_connection_cb;
    mqtt_mutex = xSemaphoreCreateMutex();
    mqtt_app_start();
}

bool mqtt_publish(const char *topic, const char *data, int qos)
{
    if (!client || !connected)
    {
        ESP_LOGW(ROTULO_LOCAL, "Cannot publish - not connected");
        return false;
    }

    if (xSemaphoreTake(mqtt_mutex, pdMS_TO_TICKS(1000)) == pdTRUE)
    {
        int msg_id = esp_mqtt_client_publish(client, topic, data, strlen(data), qos, 0);
        xSemaphoreGive(mqtt_mutex);
        return msg_id >= 0;
    }
    else
    {
        ESP_LOGW(ROTULO_LOCAL, "Timeout ao tentar pegar mutex do MQTT");
        return false;
    }
}