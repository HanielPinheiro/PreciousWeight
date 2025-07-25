#pragma once

#include "system_core.h"
#include "buzzer.h"
#include "mqtt_client.h"

#define MQTT_ADDRESS "mqtts://192.168.0.15:8883"

#define MQTT_RECONNECT_DELAY_MS 5000
#define MQTT_KEEPALIVE 60
#define MQTT_TOPIC_SUBSCRIBE "/scale/{id}"
#define MQTT_TOPIC_PUB_PREFIX "/sensor"
#define MQTT_TOPIC_PUB_SUFIX "weight"
#define MQTT_TOPIC_CONNECTED "/status/on"
#define MQTT_TOPIC_DISCONNECTED "/status/off"

typedef enum
{
    MQTT_STATE_DISCONNECTED,
    MQTT_STATE_CONNECTING,
    MQTT_STATE_CONNECTED,
    MQTT_STATE_ERROR
} mqtt_state_t;

typedef void (*mqtt_connection_callback_t)(mqtt_state_t connected);

void mqtt_app_start(void);
void mqtt_init(mqtt_connection_callback_t ext_connection_cb);
bool mqtt_publish(const char *topic, const char *data, int qos);
esp_mqtt_client_handle_t mqtt_get_client_handle();
void mqtt_reset_client_handle();