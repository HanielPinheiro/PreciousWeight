#include "HX711.h"

// HX711 circuit wiring
const int SCALE1_DOUT_PIN = 21;
const int SCALE1_SCK_PIN = 22;

const int SCALE2_DOUT_PIN = 16;
const int SCALE2_SCK_PIN = 14;

const int SCALE3_DOUT_PIN = 32;
const int SCALE3_SCK_PIN = 33;

const int SCALE4_DOUT_PIN = 25;
const int SCALE4_SCK_PIN = 26;

HX711 scale1;
HX711 scale2;
HX711 scale3;
HX711 scale4;

void setup() {
  Serial.begin(115200);
  Serial.println("Waking up");
  scale1.begin(SCALE1_DOUT_PIN, SCALE1_SCK_PIN);
  scale2.begin(SCALE2_DOUT_PIN, SCALE2_SCK_PIN);
  scale3.begin(SCALE3_DOUT_PIN, SCALE3_SCK_PIN);
  scale4.begin(SCALE4_DOUT_PIN, SCALE4_SCK_PIN);
  Serial.println("Waked");
}

void loop() {

  if (scale1.is_ready()) {
    Serial.print("reading 1:");
    Serial.print(scale1.get_units(), 1);
    Serial.print("\t");
  } else {
    Serial.println("scale 1 not found.");
  }

  if (scale2.is_ready()) {
    Serial.print("reading 2:");
    Serial.print(scale2.get_units(), 1);
    Serial.print("\t");
  } else {
    Serial.println("scale 2 not found.");
  }

  if (scale3.is_ready()) {
    Serial.print("reading 3:");
    Serial.print(scale3.get_units(), 1);
    Serial.print("\t");
  } else {
    Serial.println("scale 3 not found.");
  }

  if (scale4.is_ready()) {
    Serial.print("reading 4: ");
    Serial.println(scale4.get_units(), 1);
  } else {
    Serial.println("scale 4 not found.");
  }

  delay(333);
}
