#pragma once
#ifndef WIFI_H
#define WIFI_H

#include "comm_libs.h"

#include "time.h"
#include "sys/time.h"
#include "esp_timer.h"
#include "esp_netif_sntp.h"

#include "wifi_provisioning/manager.h"
#include "wifi_provisioning/scheme_ble.h"

#define SIZE_TIME 50
extern char current_time[SIZE_TIME];

void update_current_time();
void print_efuse_mac();

void start_ble_provisioning();
void reset_wifi();
void init_wifi();
bool is_wifi_connected();

#endif // WIFI_H