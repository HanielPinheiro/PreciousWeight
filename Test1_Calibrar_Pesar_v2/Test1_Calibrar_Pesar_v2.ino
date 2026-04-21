/*************************************************
 * Test1_Calibrar_Pesar_v2.ino
 * Sistema de Calibração e Pesagem com 4 Sensores HX711
 * Versão para ESP32 DevKit V1
 *
 * Baseado na lógica do Balanca_Versao_Final_2.ino
 * Bit-banging para HX711 (sem biblioteca)
 *
 * Pinos ESP32 DevKit V1:
 * - Sensor 1: DT=26, SCK=25
 * - Sensor 2: DT=33, SCK=32
 * - Sensor 3: DT=15, SCK=04
 * - Sensor 4: DT=21, SCK=22
 *
 * Fatores de calibração (SCALE_FACTOR):
 * - Sensor 1: 88.848
 * - Sensor 2: 11.694
 * - Sensor 3: 82.316
 * - Sensor 4: 107.285
**************************************************/

#include <Arduino.h>

// ============================================
// CONFIGURAÇÃO DOS 4 SENSORES
// ============================================

#define NUM_SENSORS 4

typedef struct {
    int dout_pin;       // Pino DT (Data Out)
    int sck_pin;       // Pino SCK (Clock)
    float calib_factor; // Fator de calibração
    long zero_offset;  // Offset de tara (vZero)
    int invalid_limit; // Limite para leitura inválida (gramas)
    bool connected;    // Status de conexão
    const char* name;  // Nome do sensor
} SensorConfig;

SensorConfig sensors[NUM_SENSORS] = {
    {21, 22, 88.848,  0, -1, false, "Sensor 1"},
    {16, 14, 11.694,  0, -1, false, "Sensor 2"},
    {32, 33, 82.316,  0, -1, false, "Sensor 3"},
    {25, 26, 107.285, 0, -1, false, "Sensor 4"}
};

int active_sensor = 0;

// ============================================
// VARIÁVEIS GLOBAIS
// ============================================

unsigned long tempo = 0;
unsigned long tExbPeso = 0;
const unsigned long READING_INTERVAL = 300;

long conv_raw = 0;
float pesoCalculado = 0;
float pesoKalman = 0;

// Controle de filtros
bool useKalmanFilter = false;
bool useOriginalFilter = true;

// ============================================
// PROTÓTIPOS DAS FUNÇÕES
// ============================================

unsigned long readCount(int ADSK, int ADDO);
void performTare(int sensorIndex);
float readWeight(int sensorIndex, bool useKalman);
float readWeightOriginal(int sensorIndex);
float kalmanFilter(float measurement, float& estimate, float& error_covariance, float process_noise, float measurement_noise);
bool isValidReading(float weight, int sensorIndex);
void displayHelp();
void handleSerialCommand(char cmd);

// ============================================
// SETUP
// ============================================

void setup() {
    Serial.begin(115200);
    Serial.println();
    Serial.println("===========================================");
    Serial.println("HX711 - Sistema de Calibração v2 para ESP32");
    Serial.println("===========================================");
    Serial.println();

    Serial.println("Testando conexao dos pinos...");
    for (int i = 0; i < NUM_SENSORS; i++) {
        pinMode(sensors[i].dout_pin, INPUT_PULLUP);
        pinMode(sensors[i].sck_pin, OUTPUT);
        digitalWrite(sensors[i].sck_pin, LOW);
        sensors[i].connected = true;
        sensors[i].zero_offset = 0;

        delay(100);

        int dtState = digitalRead(sensors[i].dout_pin);
        Serial.print("Configurado: ");
        Serial.print(sensors[i].name);
        Serial.print(" | DT=");
        Serial.print(sensors[i].dout_pin);
        Serial.print(" (estado atual=");
        Serial.print(dtState);
        Serial.print(") | SCK=");
        Serial.print(sensors[i].sck_pin);
        Serial.print(" | Scale=");
        Serial.println(sensors[i].calib_factor, 3);

        if (dtState == LOW) {
            Serial.println("  ATENCAO: DT está em LOW! Sensor pode estar desconectado.");
        }
    }

    Serial.println();
    Serial.println("-------------------------------------------");
    Serial.println("Configurando sensor ativo...");
    Serial.println("-------------------------------------------");

    active_sensor = 0;
    Serial.print("Sensor ativo: ");
    Serial.println(sensors[active_sensor].name);

    performTare(active_sensor);

    Serial.println();
    Serial.println("===========================================");
    Serial.println("COMANDOS SERIAIS:");
    Serial.println("===========================================");
    displayHelp();
    Serial.println("===========================================");
    Serial.println();
    Serial.println("Iniciando leitura continua...");
    Serial.println();
}

// ============================================
// LOOP PRINCIPAL
// ============================================

void loop() {
    if (Serial.available()) {
        char cmd = Serial.read();
        handleSerialCommand(cmd);
    }

    unsigned long currentTime = millis();

    if (currentTime - tExbPeso >= READING_INTERVAL) {
        pesoCalculado = readWeightOriginal(active_sensor);
        pesoKalman = readWeight(active_sensor, true);

        Serial.print("[");
        Serial.print(sensors[active_sensor].name);
        Serial.print("] ");

        if (useOriginalFilter) {
            Serial.print("Original: ");
            Serial.print(pesoCalculado, 1);
            Serial.print("g");
        }

        if (useOriginalFilter && useKalmanFilter) {
            Serial.print(" | ");
        }

        if (useKalmanFilter) {
            Serial.print("Kalman: ");
            Serial.print(pesoKalman, 1);
            Serial.print("g");
        }

        if (!useOriginalFilter && !useKalmanFilter) {
            Serial.print("Filtros desabilitados");
        }

        if (!isValidReading(pesoCalculado, active_sensor)) {
            Serial.print(" [INVÁLIDO - Re-tarando...]");
        }

        Serial.println();

        tExbPeso = currentTime;
    }
}

// ============================================
// LEITURA HX711 (BIT-BANGING COM TIMEOUT)
// ============================================

unsigned long readCount(int ADSK, int ADDO) {
    unsigned long Count = 0;
    unsigned char i;   

    digitalWrite(ADSK, LOW);
    delayMicroseconds(1);

    while (digitalRead(ADDO) == HIGH) {
        delayMicroseconds(10);        
    }

    for (i = 0; i < 24; i++) {
        digitalWrite(ADSK, HIGH);
        delayMicroseconds(1);
        Count = Count << 1;
        digitalWrite(ADSK, LOW);
        delayMicroseconds(1);
        if (digitalRead(ADDO)) Count++;
    }

    digitalWrite(ADSK, HIGH);
    delayMicroseconds(1);
    Count = Count ^ 0x800000;
    digitalWrite(ADSK, LOW);
    delayMicroseconds(1);

    return Count;
}

// ============================================
// TARA (MÉDIA MÓVEL DE 200 AMOSTRAS)
// ============================================

void performTare(int sensorIndex) {
    SensorConfig &sensor = sensors[sensorIndex];

    const int NUM_SAMPLES = 200;
    long sum = 0;
    unsigned long tTara = millis();

    Serial.print("Zerando ");
    Serial.print(sensor.name);
    Serial.println("...");
    Serial.println("Aguarde 2 segundos para estabilização térmica...");

    delay(2000);

    Serial.print("Coletando ");
    Serial.print(NUM_SAMPLES);
    Serial.println(" amostras...");

    for (int i = 0; i < NUM_SAMPLES; i++) {
        conv_raw = readCount(sensor.sck_pin, sensor.dout_pin);
        sum += conv_raw;

        sensor.zero_offset = sum / (i + 1);

        if (i % 50 == 0) {
            Serial.print("Amostra ");
            Serial.print(i + 1);
            Serial.print("/");
            Serial.print(NUM_SAMPLES);
            Serial.print(" | Raw: ");
            Serial.print(conv_raw);
            Serial.print(" | Offset: ");
            Serial.println(sensor.zero_offset);
        }

        delay(10);
    }

    Serial.print("Tara concluída! Offset final: ");
    Serial.print(sensor.zero_offset);
    Serial.print("tempo total => ");
    Serial.print(millis() - tTara);
    Serial.println();
}

// ============================================
// FILTRO ORIGINAL (MÉDIA MÓVEL SIMPLES)
// ============================================

float readWeightOriginal(int sensorIndex) {
    SensorConfig &sensor = sensors[sensorIndex];

    conv_raw = readCount(sensor.sck_pin, sensor.dout_pin);

    long adjusted = conv_raw - sensor.zero_offset;
    float weight = adjusted / sensor.calib_factor;

    if (weight >= 3000) {
        weight = weight * 0.99;
    }

    return weight;
}

// ============================================
// FILTRO DE KALMAN
// ============================================

float kalmanFilter(float measurement, float& estimate, float& error_covariance,
                   float process_noise, float measurement_noise) {
    // Predição
    float predicted_estimate = estimate;
    float predicted_error_covariance = error_covariance + process_noise;

    // Atualização
    float kalman_gain = predicted_error_covariance / (predicted_error_covariance + measurement_noise);
    estimate = predicted_estimate + kalman_gain * (measurement - predicted_estimate);
    error_covariance = (1 - kalman_gain) * predicted_error_covariance;

    return estimate;
}

// Variáveis de estado do Kalman por sensor
float kalmanEstimate[NUM_SENSORS] = {0};
float kalmanErrorCov[NUM_SENSORS] = {1};
const float PROCESS_NOISE = 0.1;
const float MEASUREMENT_NOISE = 5.0;

float readWeight(int sensorIndex, bool useKalman) {
    SensorConfig &sensor = sensors[sensorIndex];

    float raw_weight = readWeightOriginal(sensorIndex);

    if (!useKalman) {
        return raw_weight;
    }

    return kalmanFilter(raw_weight, kalmanEstimate[sensorIndex],
                        kalmanErrorCov[sensorIndex], PROCESS_NOISE, MEASUREMENT_NOISE);
}

// ============================================
// VALIDAÇÃO DE LEITURA
// ============================================

bool isValidReading(float weight, int sensorIndex) {
    SensorConfig &sensor = sensors[sensorIndex];

    if (weight < sensor.invalid_limit) {
        return false;
    }
    return true;
}

// ============================================
// COMandos SERIAIS
// ============================================

void handleSerialCommand(char cmd) {
    switch (cmd) {
        case '1':
        case '2':
        case '3':
        case '4': {
            int newSensor = cmd - '1';
            if (newSensor < NUM_SENSORS) {
                active_sensor = newSensor;
                performTare(active_sensor);
            } else {
                Serial.println("Sensor inválido!");
            }
            break;
        }

        case 't':
        case 'T': {
            Serial.println("Re-tarando sensor ativo...");
            performTare(active_sensor);
            kalmanEstimate[active_sensor] = 0;
            kalmanErrorCov[active_sensor] = 1;
            break;
        }

        case 'k':
        case 'K': {
            useKalmanFilter = !useKalmanFilter;
            Serial.print("Filtro Kalman: ");
            Serial.println(useKalmanFilter ? "ATIVADO" : "DESATIVADO");
            break;
        }

        case 'o':
        case 'O': {
            useOriginalFilter = !useOriginalFilter;
            Serial.print("Filtro Original: ");
            Serial.println(useOriginalFilter ? "ATIVADO" : "DESATIVADO");
            break;
        }

        case 'c':
        case 'C': {
            Serial.println();
            Serial.println("========== STATUS DO SENSOR ==========");
            Serial.print("Sensor ativo: ");
            Serial.println(sensors[active_sensor].name);
            Serial.print("DT Pin: ");
            Serial.println(sensors[active_sensor].dout_pin);
            Serial.print("SCK Pin: ");
            Serial.println(sensors[active_sensor].sck_pin);
            Serial.print("Fator calibração: ");
            Serial.println(sensors[active_sensor].calib_factor, 3);
            Serial.print("Zero offset: ");
            Serial.println(sensors[active_sensor].zero_offset);
            Serial.print("Limite inválido: ");
            Serial.print(sensors[active_sensor].invalid_limit);
            Serial.println("g");
            Serial.print("Filtro Kalman: ");
            Serial.println(useKalmanFilter ? "ATIVADO" : "DESATIVADO");
            Serial.print("Filtro Original: ");
            Serial.println(useOriginalFilter ? "ATIVADO" : "DESATIVADO");
            Serial.print("Kalman estimate: ");
            Serial.println(kalmanEstimate[active_sensor], 2);
            Serial.print("Kalman error cov: ");
            Serial.println(kalmanErrorCov[active_sensor], 4);
            Serial.println("======================================");
            break;
        }

        case 'l':
        case 'L': {
            Serial.println();
            Serial.println("========== LISTA DE SENSORES ==========");
            for (int i = 0; i < NUM_SENSORS; i++) {
                Serial.print("[");
                Serial.print(i + 1);
                Serial.print("] ");
                Serial.print(sensors[i].name);
                Serial.print(" | DT=");
                Serial.print(sensors[i].dout_pin);
                Serial.print(" | SCK=");
                Serial.print(sensors[i].sck_pin);
                Serial.print(" | Scale=");
                Serial.print(sensors[i].calib_factor, 3);
                if (i == active_sensor) {
                    Serial.print(" <-- ATIVO");
                }
                Serial.println();
            }
            Serial.println("======================================");
            Serial.println();
            break;
        }

        case 'i':
        case 'I': {
            Serial.println();
            Serial.print("Digite o novo limite de invalidez para ");
            Serial.print(sensors[active_sensor].name);
            Serial.println(":");
            Serial.println("(Aguardando valor numérico em gramas, ex: -150)");
            while (!Serial.available()) {
                delay(10);
            }
            String input = Serial.readStringUntil('\n');
            input.trim();
            if (input.length() > 0) {
                int newLimit = input.toInt();
                sensors[active_sensor].invalid_limit = newLimit;
                Serial.print("Limite atualizado para: ");
                Serial.print(newLimit);
                Serial.println("g");
            }
            break;
        }

        case 'h':
        case 'H':
        case '?': {
            displayHelp();
            break;
        }

        default:
            break;
    }
}

void displayHelp() {
    Serial.println();
    Serial.println("COMANDOS DISPONÍVEIS:");
    Serial.println("----------------------");
    Serial.println("1, 2, 3, 4 - Trocar sensor ativo e tarar");
    Serial.println("t ou T     - Re-tarar sensor ativo");
    Serial.println("k ou K     - Ativar/desativar filtro Kalman");
    Serial.println("o ou O     - Ativar/desativar filtro Original");
    Serial.println("c ou C     - Mostrar status do sensor");
    Serial.println("l ou L     - Listar todos os sensores");
    Serial.println("i ou I     - Alterar limite de leitura inválida");
    Serial.println("h, H, ?    - Mostrar esta ajuda");
    Serial.println();
    Serial.println("EXEMPLO DE USO:");
    Serial.println("1. Envie '3' para ativar Sensor 3");
    Serial.println("2. Coloque peso conhecido na célula");
    Serial.println("3. Observe 'Original' vs 'Kalman' no console");
    Serial.println("4. Use 't' para re-tarar se necessário");
    Serial.println();
}
