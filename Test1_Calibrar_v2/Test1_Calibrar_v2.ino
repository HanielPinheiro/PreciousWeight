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
float calibration_factor_1 = 1.0; 
float calibration_factor_2 = 1.0; 
float calibration_factor_3 = 1.0; 
float calibration_factor_4 = 1.0; 

// Insertion Sort: Muito mais rápido e eficiente que Bubble Sort para vetores pequenos
void insertionSort(float arr[], int n) {
  for (int i = 1; i < n; i++) {
    float key = arr[i];
    int j = i - 1;
    while (j >= 0 && arr[j] > key) {
      arr[j + 1] = arr[j];
      j = j - 1;
    }
    arr[j + 1] = key;
  }
}

// Filtro otimizado que descarta picos (Outliers) trabalhando com valores brutos
float read_filtered_weight(HX711 &scale) {
  const int TOTAL_SAMPLES = 7;
  float samples[TOTAL_SAMPLES];

  // Coleta amostras brutas isoladas (sem aplicar o fator individualmente)
  for (int i = 0; i < TOTAL_SAMPLES; i++) {
    samples[i] = scale.get_value(1); 
    delay(10); // Intervalo necessário para o registrador do HX711 atualizar
  }

  // Ordena as amostras brutas de forma rápida
  insertionSort(samples, TOTAL_SAMPLES);

  // Descarta as duas menores e as duas maiores leituras
  // Faz a média apenas das 3 leituras centrais estáveis
  float sum = 0;
  for (int i = 2; i < TOTAL_SAMPLES - 2; i++) {
    sum += samples[i];
  }
  float avg_raw = sum / 3.0;

  // Deduz a Tara (Offset) interna e aplica o fator de calibração apenas uma vez no final
  return (avg_raw - scale.get_offset()) / scale.get_scale();
}

void setup() {
  Serial.begin(115200);
  Serial.println("Waking up");

 turn_on_sensor(scale1, SCALE1_DOUT_PIN, SCALE1_SCK_PIN, calibration_factor_1);
 turn_on_sensor(scale2, SCALE2_DOUT_PIN, SCALE2_SCK_PIN, calibration_factor_2);
 turn_on_sensor(scale3, SCALE3_DOUT_PIN, SCALE3_SCK_PIN, calibration_factor_3);
 turn_on_sensor(scale4, SCALE4_DOUT_PIN, SCALE4_SCK_PIN, calibration_factor_4);
}
void loop() {
  // Leitura filtrada de alta performance
  float w1 = read_filtered_weight(scale1);
  float w2 = read_filtered_weight(scale2);
  float w3 = read_filtered_weight(scale3);
  float w4 = read_filtered_weight(scale4);

  Serial.print("Scale 1 Weight: ");
  Serial.print(w1, 1);
  Serial.print("\t Scale 2 Weight: ");
  Serial.print(w2, 1);
  Serial.print("\t Scale 3 Weight: ");
  Serial.print(w3, 1);
  Serial.print("\t Scale 4 Weight: ");
  Serial.println(w4, 1);
}

void turn_on_sensor(HX711 &scale, int dout, int sck, float &cal_factor)
{
 scale.begin(dout, sck);
    
  // Reseta eletricamente o canal analógico do HX711 para limpar ruídos residuais
  scale.power_down();
  delay(10);
  scale.power_up();

  Serial.println("Waked");
  delay(3000); // Aguarda estabilização das tensões internas

    if(calibrate)
      prepare_scale(scale, "S1", cal_factor);
    else {
      scale.set_scale(cal_factor);
      scale.tare(40); // Garante tara limpa e estável ao iniciar sem calibração
    }
}

// Interactive calibration helper function
void prepare_scale(HX711 &scale, String scaleName, float &cal_factor) {
    Serial.println("Calibrating " + scaleName);  
    Serial.println("Remove all weight from the platform and press Enter");
    while (!Serial.available()) { }
    while (Serial.available()) Serial.read();

    scale.set_scale(1.0); // Reseta para fator padrão antes da tara
    scale.tare(40);       // Aumentado para 40 amostras para garantir uma linha de zero perfeita

    Serial.println("Place a known weight on " + scaleName + ", then type the weight in grams (e.g. 100) and press Enter:");
    while (!Serial.available()) { }

    float known_weight = Serial.parseFloat();
    while (Serial.available()) Serial.read();

    // Na calibração tiramos uma média maior para mitigar qualquer desvio na amostragem
    long reading = scale.get_value(40); 
    cal_factor = (float)reading / known_weight;

    scale.set_scale(cal_factor);

    Serial.print(scaleName);
    Serial.print(" Calibration Factor found: ");
    Serial.println(cal_factor, 3);
    Serial.println("------------------------------------"); 
}
