#pragma once
#ifndef MQTT_TASK_H
#define MQTT_TASK_H

#include "mqtt3.h"
#include "wifi_prov_ble.h"
#include "config_system.h"

extern TaskHandle_t mqtt_manager_task_handle;
extern SemaphoreHandle_t mqtt_restart_sem;

void mqtt_connection_status_callback(esp_mqtt_event_id_t connected);
void mqtt_manager_task(void *pvParameters);
esp_err_t init_mqtt_task();

#endif // MQTT_TASK_H