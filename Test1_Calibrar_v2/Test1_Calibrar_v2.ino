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

// HX711 scale1;
// HX711 scale2;
// HX711 scale3;
HX711 scale4;

void setup() {
  Serial.begin(115200);
  Serial.println("Waking up");
  // scale1.begin(SCALE1_DOUT_PIN, SCALE1_SCK_PIN);
  // scale2.begin(SCALE2_DOUT_PIN, SCALE2_SCK_PIN);
  // scale3.begin(SCALE3_DOUT_PIN, SCALE3_SCK_PIN);
  scale4.begin(SCALE4_DOUT_PIN, SCALE4_SCK_PIN);
  Serial.println("Waked");
}

void loop() {
  // extraido de => https://randomnerdtutorials.com/arduino-load-cell-hx711/#comment-780712
  //martelo -> 382g
  //scale1 33940 / 382 = 88,848
  //scale2 4467 / 382 = 11,694
  //scale3 31443 / 382 = 82,316
  //scale4 40983 / 382 = 107,285
  if (scale4.is_ready()) {
    scale4.set_scale();    
    Serial.println("Tare... remove any weights from the scale.");    
    delay(5000);

    scale4.tare();    
    Serial.println("Tare done...");
    Serial.print("Place a known weight on the scale...");
    delay(5000);

    long reading = scale4.get_units(10);
    Serial.print("Result: ");
    Serial.println(reading);

    while(true){}
  } else 
    Serial.println("scale not found.");  
}
