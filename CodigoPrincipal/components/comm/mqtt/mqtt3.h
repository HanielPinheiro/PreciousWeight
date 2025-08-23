#pragma once
#ifndef MQTT3_H
#define MQTT3_H

#include "comm_libs.h"
#include "mqtt_client.h"

#define MQTT_ADDRESS "mqtts://192.168.0.15:8883"

#define MQTT_RECONNECT_DELAY_MS 5000
#define MQTT_KEEPALIVE 60

#define MQTT_TOPIC_SUBSCRIBE "/scales/" MQTT_SERVICE_NAME
#define MQTT_TOPIC_PUB_SENSOR "/sensors/" MQTT_SERVICE_NAME
#define MQTT_TOPIC_PUB_WEIGHT "/weights/" MQTT_SERVICE_NAME
#define MQTT_TOPIC_CONN_DISCONN "/status/" MQTT_SERVICE_NAME

typedef void (*mqtt_connection_callback_t)(esp_mqtt_event_id_t connected);
extern esp_mqtt_event_handle_t event;

void mqtt_app_start(void);
void mqtt_init(mqtt_connection_callback_t ext_connection_cb);
bool mqtt_publish(const char *topic, const char *data, int qos);
esp_mqtt_client_handle_t mqtt_get_client_handle();
void mqtt_reset_client_handle();

#endif // MQTT3_H