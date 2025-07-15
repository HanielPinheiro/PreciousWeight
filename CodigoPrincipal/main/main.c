// #include "system_manager.h"
#include "wifi_prov_ble.h"
#include "mqtt3.h"

void app_main()
{
    wifi_setup();
    mqtt_mutal_ssl_v3();
    // system_manager_start();
}
