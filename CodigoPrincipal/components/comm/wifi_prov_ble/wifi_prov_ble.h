#pragma once

#include "system_core.h"
#include "wifi_provisioning/manager.h"
#include "wifi_provisioning/scheme_ble.h"

void start_ble_provisioning();
void reset_wifi();
void wifi_init();
void print_efuse_mac();
bool is_wifi_connected();
