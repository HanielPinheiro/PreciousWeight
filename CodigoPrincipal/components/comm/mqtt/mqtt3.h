#pragma once

#include "stdio.h"
#include "stdint.h"
#include "stddef.h"
#include "string.h"
#include "esp_system.h"
#include "nvs_flash.h"
#include "esp_event.h"
#include "esp_netif.h"
#include "esp_wifi.h"
#include "esp_log.h"
#include "esp_timer.h"

#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/semphr.h"
#include "freertos/queue.h"

#include "lwip/sockets.h"
#include "lwip/dns.h"
#include "lwip/netdb.h"

#include "mqtt_client.h"

#define MQTT_ADDRESS "mqtts://192.168.0.15:8883"
#define SERVICE_NAME "PW_D0EF76590B7C"
#define MQTT_RECONNECT_DELAY_MS 5000
#define MQTT_KEEPALIVE 60

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