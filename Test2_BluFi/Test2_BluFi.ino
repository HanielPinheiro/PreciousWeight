#include "WiFiProv.h"
#include "WiFi.h"
#include "PubSubClient.h"

#define BUZZER_PINOUT 3
bool isProvisioned = false;

const char *mqtt_server = "192.168.10.14";
WiFiClient espClient;
PubSubClient client(espClient);
long lastMsg = 0;
char msg[50];
int value = 0;

void SysProvEvent(arduino_event_t *sys_event) {
  switch (sys_event->event_id) {
    case ARDUINO_EVENT_WIFI_STA_GOT_IP:
      {
        Serial.println("\nConnected");
        client.setServer(mqtt_server, 5278);
        client.setCallback(callback);
        isProvisioned = true;
        break;
      }
    case ARDUINO_EVENT_WIFI_STA_DISCONNECTED:
      {
        Serial.println("\nDisconnected");
        isProvisioned = false;
        break;
      }
    default: break;
  }
}

void setup() {
  pinMode(BUZZER_PINOUT, OUTPUT);

  Serial.begin(115200);
  WiFi.onEvent(SysProvEvent);
  Serial.println("Begin Provisioning using BLE");

  // Sample uuid that user can pass during provisioning using BLE
  // uint8_t _uuid[16] = { 0xb4, 0xdf, 0x5a, 0x1c, 0x3f, 0x6b, 0xf4, 0xbf, 0xea, 0x4a, 0x82, 0x03, 0x04, 0x90, 0x1a, 0x02 };
  const char *pop = "abcd1234";           // Proof of possession - otherwise called a PIN - string provided by the device, entered by the user in the phone app
  const char *service_name = "PROV_123";  // Name of your device (the Espressif apps expects by default device name starting with "Prov_")
  const char *service_key = NULL;         //service key is only used if the esp32 acts like a Access Point (Router). Not used in this case
  bool reset_provisioned = true;          // When true the library will automatically delete previously provisioned data.
  WiFiProv.beginProvision(NETWORK_PROV_SCHEME_BLE, NETWORK_PROV_SCHEME_HANDLER_FREE_BLE, NETWORK_PROV_SECURITY_1, pop, service_name, service_key, NULL, reset_provisioned);
}

void callback(char *topic, byte *message, unsigned int length) {
  Serial.print("Message arrived on topic: ");
  Serial.print(topic);
  Serial.print(". Message: ");
  String messageTemp;

  for (int i = 0; i < length; i++) {
    Serial.print((char)message[i]);
    messageTemp += (char)message[i];
  }
  Serial.println();

  // Feel free to add more if statements to control more GPIOs with MQTT

  // If a message is received on the topic esp32/output, you check if the message is either "on" or "off".
  // Changes the output state according to the message
  if (String(topic) == "esp32/output") {
    Serial.print("Changing output to ");
    if (messageTemp == "on") {
      Serial.println("on");
      digitalWrite(ledPin, HIGH);
    } else if (messageTemp == "off") {
      Serial.println("off");
      digitalWrite(ledPin, LOW);
    }
  }
}

void reconnect() {
  // Loop until we're reconnected
  while (!client.connected()) {
    Serial.print("Attempting MQTT connection...");
    // Attempt to connect
    if (client.connect("ESP8266Client")) {
      Serial.println("connected");
      // Subscribe
      client.subscribe("esp32/output");
    } else {
      Serial.print("failed, rc=");
      Serial.print(client.state());
      Serial.println(" try again in 5 seconds");
      // Wait 5 seconds before retrying
      delay(5000);
    }
  }
}

void loop() {
  if (isProvisioned) {
    if (!client.connected()) {
      reconnect();
    }
    client.loop();
  }
}
