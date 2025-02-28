#include "HX711.h"

// HX711 circuit wiring
const int SCALE1_DOUT_PIN = 16;
const int SCALE1_SCK_PIN = 4;
const int SCALE2_DOUT_PIN = 22;
const int SCALE2_SCK_PIN = 23;

HX711 scale1;
HX711 scale2;

// Observações, a sensibilidade muda de sensor pra sensor

void setup() {
  Serial.begin(115200);
  scale1.begin(SCALE1_DOUT_PIN, SCALE1_SCK_PIN);
  scale2.begin(SCALE2_DOUT_PIN, SCALE2_SCK_PIN);
  // scale.set_scale();
  // Serial.println("Tare... remove any weights from the scale.");
  // delay(5000);
  // scale.tare();
  // Serial.println("Tare done...");
}

void loop() {

  if (scale1.is_ready()) {
    Serial.print("reading 1:\t");
    Serial.println(scale1.get_units(), 1);
  } else {
    Serial.println("scale 1 not found.");
  }
  if (scale2.is_ready()) {
    Serial.print("reading 2:\t");
    Serial.println(scale2.get_units(), 1);
    // Serial.print("\t| average:\t");
    // Serial.println(scale.get_units(10), 1);
  } else {
    Serial.println("scale 2 not found.");
  }

  delay(100);
}
