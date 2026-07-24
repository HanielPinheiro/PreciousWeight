#pragma once
#ifndef WIFI_H
#define WIFI_H

#define SIZE_TIME 50
extern char current_time[SIZE_TIME];

esp_err_t start_date_time_routine();
void update_current_time();
void print_efuse_mac();

void start_ble_provisioning();
void reset_wifi();
void init_wifi();
bool is_wifi_connected();
esp_err_t get_wifi_strength(int *wifi_strength);

#endif // WIFI_H
