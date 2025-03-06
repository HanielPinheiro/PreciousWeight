void setup() {
  pinMode(BUZZER_PINOUT, OUTPUT);

  Serial.begin(115200);
  WiFi.onEvent(SysProvEvent);
  Serial.println("Begin Provisioning using BLE");

  // Sample uuid that user can pass during provisioning using BLE
  // uint8_t _uuid[16] = { 0xb4, 0xdf, 0x5a, 0x1c, 0x3f, 0x6b, 0xf4, 0xbf, 0xea, 0x4a, 0x82, 0x03, 0x04, 0x90, 0x1a, 0x02 };
  const char *pop = "abcd1234";           // Proof of possession - otherwise called a PIN - string provided by the device, entered by the user in the phone app
  const char *service_name = "PROV_123";  // Name of your device (the Espressif apps expects by default device name starting with "Prov_")
  const char *service_key = NULL;         // service key is only used if the esp32 acts like a Access Point (Router). Not used in this case
  bool reset_provisioned = true;          // When true the library will automatically delete previously provisioned data.
  WiFiProv.beginProvision(NETWORK_PROV_SCHEME_BLE, NETWORK_PROV_SCHEME_HANDLER_FREE_BLE, NETWORK_PROV_SECURITY_1, pop, service_name, service_key, NULL, reset_provisioned);
}

// O fabricante deve anotar o Pop e o service name aqui
// O app deve enviar o service_name para o DB, retorna o pop, o app envia o pop de forma automática
// User insere Wifi Credentials
// Sistema conecta ao WIFI, faz o log no cartão SD das credenciais
// Toda vez que wifi desconectar e ele for neessário, tenta reconectar usando dados do cartão

// App atualiza a conta do cliente e a conta da empresa dizendo quais as balanças vinculadas aquela conta
// Balança aparece no app pro cliente
// Cliente deve efetuar teste rápido da balança
// Comando vem do App pro Esp32 por MQTT
// Deve realizar 10 medidas, 10 vezes, extrair a média das médias e realizar a tara da balança
// Após isso, atualiza internamente o valor de Tara e manda um peso conhecido pro cliente validar, o cliente não sabe o peso,
// ele coloca na balança e a balança informa se está ok ou não
// Se houver erros detalhar o Log com o máximo de detalhes possíveis
// Se tudo estiver ok, habilita balança para receber paciente
// Cliente pode escanear um paciente se ele tiver uma ou mais balanças habilitadas
// Ao escanear um paciente, é necessário fazer a coleta do peso na hora de colocá-lo na incubadora, e então deve-se configurar via App o melhor horário de cada 
// dia para efetuar a coleta.

