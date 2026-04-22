#pragma once
#ifndef WIFI_H
#define WIFI_H
#include "../../config/include/setup.h"
#define SIZE_TIME 50
extern char current_time[SIZE_TIME];

void update_current_time();
void print_efuse_mac();

void start_ble_provisioning();
void reset_wifi();
void init_wifi();
bool is_wifi_connected();

#endif // WIFI_H