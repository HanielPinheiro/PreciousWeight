void BlufiEvent(arduino_event_t *event) {
  switch (event->event_id) {
    case ARDUINO_EVENT_WIFI_STA_GOT_IP:
      {
        Serial.println("\nConnected");
        isProvisioned = true;     ]
        SlowBuzzer_OneTime();
        break;
      }
    case ARDUINO_EVENT_WIFI_STA_DISCONNECTED:
      {
        Serial.println("\nDisconnected");
        isProvisioned = false;
        SlowBuzzer_TwoTimes();
        break;
      }
    default: break;
  }
}