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
  
  delay(5000); // Delay de estabilização dos sensores

  bool s1_ok = prepare_scale(scale1, "S1");
  bool s2_ok = prepare_scale(scale2, "S2");
  bool s3_ok = prepare_scale(scale3, "S3");
  bool s4_ok = prepare_scale(scale4, "S4");

  if (!s1_ok || !s2_ok || !s3_ok || !s4_ok) {
    Serial.println("Falha na inicialização de uma ou mais balanças.");
    while (true) {
      Serial.print(".");
      delay(500);
    }
  }
}
// unsigned long previousMillis; 
  // extraido de => https://randomnerdtutorials.com/arduino-load-cell-hx711/#comment-780712
void loop() {
  // unsigned long currentMillis = millis();

  // // Check if 1 second has passed
  // if (currentMillis - previousMillis >= 100) {
    
    // Only proceed if all four scales have new data ready
    if (scale1.is_ready() && scale2.is_ready() && scale3.is_ready() && scale4.is_ready()) {
      
      long reading;

      reading = scale1.read(); // get_units() without arguments defaults to 1 reading (fastest)
      Serial.print("S1: "); Serial.print(reading); Serial.print(" - ");

      reading = scale2.read();
      Serial.print("S2: "); Serial.print(reading); Serial.print(" - ");

      reading = scale3.read();
      Serial.print("S3: "); Serial.print(reading); Serial.print(" - ");

      reading = scale4.read();
      Serial.print("S4: "); Serial.println(reading);

    //   previousMillis = currentMillis; 
    // }
  }
}

bool prepare_scale(HX711 &scale, const char* scaleName) {
  bool ret = false;
  unsigned long startTime = millis(); // Registra o tempo de início

  while (true) {    
    if (millis() - startTime >= 5000) { // Timeout de 5 segundos
      Serial.print(scaleName);  Serial.println(" Timeout: Scale not ready.");
      break; 
    }

    if (scale.is_ready()) {
      scale.set_scale();
      Serial.print("Initializing Tare "); Serial.print(scaleName); Serial.println("...");      

      scale.tare();
      
      Serial.print("Tare ");Serial.print(scaleName);Serial.println(" done...");
      ret = true;
      break;
    } else {
      Serial.print(scaleName); Serial.println(" Fail.");
      delay(200); // Pausa para não sobrecarregar o monitor serial
    }
  }
  return ret;
}
