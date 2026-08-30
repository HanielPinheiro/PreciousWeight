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

bool calibrate = false;
float calibration_factor_1 = 45.0; 
float calibration_factor_2 = 92.0;
float calibration_factor_3 = 80.0; 
float calibration_factor_4 = 107.0;

void setup() {
  Serial.begin(115200);
  Serial.println("Waking up");

  scale1.begin(SCALE1_DOUT_PIN, SCALE1_SCK_PIN);
  scale2.begin(SCALE2_DOUT_PIN, SCALE2_SCK_PIN);
  scale3.begin(SCALE3_DOUT_PIN, SCALE3_SCK_PIN);
  scale4.begin(SCALE4_DOUT_PIN, SCALE4_SCK_PIN);

  Serial.println("Waked");
  
  delay(5000); // Delay de estabilização dos sensores

  prepare_scale(scale1, "S1", calibration_factor_1);
  prepare_scale(scale2, "S2", calibration_factor_2);
  prepare_scale(scale3, "S3", calibration_factor_3);
  prepare_scale(scale4, "S4", calibration_factor_4);
}

void loop() {
  float w1 = scale1.get_units(5);
  float w2 = scale2.get_units(5);
  float w3 = scale3.get_units(5);
  float w4 = scale4.get_units(5);  
  float avg = (w1 + w2 + w3 + w4) / 4.0;

  Serial.print("Scale 1 Weight: ");
  Serial.print(w1, 1);
  Serial.print(" g \t Scale 2 Weight: ");
  Serial.print(w2, 1);
  Serial.print(" g \t Scale 3 Weight: ");
  Serial.print(w3, 1);
  Serial.print(" g \t Scale 4 Weight: ");
  Serial.print(w4, 1);
  Serial.print(" g \t Average: ");
  Serial.println(avg, 1);

  delay(1000);
}

// Interactive calibration helper function
void prepare_scale(HX711 &scale, String scaleName, float &cal_factor) {
  if(calibrate){
  Serial.println("Calibrating " + scaleName);  
  Serial.println("Remove all weight from the platform and press Enter");
   while (!Serial.available()) {
    // Wait for user input
  }
  // Clear serial buffer
  while (Serial.available()) Serial.read();

  scale.set_scale();
  scale.tare(); // Reset the scale to 0

  Serial.println("Place a known weight on " + scaleName + ", then type the weight in grams (e.g. 100) and press Enter:");
  
  while (!Serial.available()) {
    // Wait for user input
  }

  float known_weight = Serial.parseFloat();
  // Clear serial buffer
  while (Serial.available()) Serial.read();

  // Get reading average and compute factor
  long reading = scale.get_units(10);
  cal_factor = reading / known_weight;

  scale.set_scale(cal_factor);

  Serial.print(scaleName);
  Serial.print(" Calibration Factor found: ");
  Serial.println(cal_factor);
  Serial.println("------------------------------------");
  }
  else {
    scale.set_scale(cal_factor);
    scale.tare(); // Reset the scale to 0
  }
}

