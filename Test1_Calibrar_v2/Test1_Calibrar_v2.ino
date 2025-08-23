#include "HX711.h"

// HX711 circuit wiring
const int SCALE1_DOUT_PIN = 13;
const int SCALE1_SCK_PIN = 14;

const int SCALE2_DOUT_PIN = 16;
const int SCALE2_SCK_PIN = 17;

const int SCALE3_DOUT_PIN = 32;
const int SCALE3_SCK_PIN = 33;

const int SCALE4_DOUT_PIN = 25;
const int SCALE4_SCK_PIN = 26;

const int BUZZER_PINOUT = 21;
const int SLOW_DELAY = 500;
const int FAST_DELAY = 300;

HX711 scale1;
HX711 scale2;
HX711 scale3;
HX711 scale4;

void setup() {
  pinMode(BUZZER_PINOUT, OUTPUT);
  Serial.begin(115200);
  Serial.println("Waking up");
  scale1.begin(SCALE1_DOUT_PIN, SCALE1_SCK_PIN);
  scale2.begin(SCALE2_DOUT_PIN, SCALE2_SCK_PIN);
  scale3.begin(SCALE3_DOUT_PIN, SCALE3_SCK_PIN);
  scale4.begin(SCALE4_DOUT_PIN, SCALE4_SCK_PIN);
  FastBuzzer_TwoTimes();
  SlowBuzzer_TwoTimes();
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


void FastBuzzer_OneTime() {
  digitalWrite(BUZZER_PINOUT, 1);
  delay(FAST_DELAY);
  digitalWrite(BUZZER_PINOUT, 0);
}

void FastBuzzer_TwoTimes() {
  for (int i = 1; i <= 2; i++) {
    SlowBuzzer_OneTime();
    delay(FAST_DELAY);
  }
}

void FastBuzzer_ThreeTimes() {
  for (int i = 1; i <= 3; i++) {
    SlowBuzzer_OneTime();
    delay(FAST_DELAY);
  }
}

void SlowBuzzer_OneTime() {
  digitalWrite(BUZZER_PINOUT, 1);
  delay(SLOW_DELAY);
  digitalWrite(BUZZER_PINOUT, 0);
}

void SlowBuzzer_TwoTimes() {
  for (int i = 1; i <= 2; i++) {
    SlowBuzzer_OneTime();
    delay(SLOW_DELAY);
  }
}

void SlowBuzzer_ThreeTimes() {
  for (int i = 1; i <= 3; i++) {
    SlowBuzzer_OneTime();
    delay(SLOW_DELAY);
  }
}
