# Balança Neonatal
## Descrição
Entendendo que o foco do projeto é aprimorar o produto para um modelo mais próximo do estado da arte - aquele pronto para o mercado - vamos aprimorar o fluxo do projeto de modo que o sistema de pesagem possa ser sincronizado a um aplicativo através de um microcontrolador com interface Wi-Fi (NodeMCU).

## Estrutura das branches:
- A branch main não receberá código, ela conterá informações gerais acerca das demais branches e do projeto.
- A branch NodeMCU tratará do código C/C++ do microcontrolador.
- A branch App tratará do código Flutter do aplicativo.
- A branch API tratará do código do Java das APIs.

## Desenvolvimento do software
- O design será feito em FIGMA. 
- O app será feito em Flutter. 
- Utilizar-se-á de APIS feita em Java para testar a sincronia entre App e MCU. 
- Por fim, a API passará para a nuvem na AWS, onde o sistema será avaliado. 
- A arquitetura do App é de MVC, e o desenvolvimento será orientado a componentes/módulos. 

## Desenvolvimento do hardware
- As células de carga serão as mesmas.
- A base da esturtura e o acabamento serão aperfeiçoados. 
- O Arduino será substituído pelo NodeMCU. 
- A central controladora desaparecerá.
- A tela de interface será o aplicativo.

## Sugestões de nome pro produto e pro app:
 - Precious Weight - Escolhi esse, podemos mudar depois.
 - Prem Balance
 - IncuBalance
 - Weight Premies

# Banco da empresa

## table: organization
- cd_organization (Not Null)
- name (Not Null)
- address (Not Null)
- cep (Not Null)
- cnpj (Null)
- website (Null)

## table: users
- cd_user (Not Null)
- cd_organization (Not Null)
- name (Not Null)
- email (Not Null) 
- password (Not Null)
- pepper //is a hash that is added to the password before it be crypto. It is splited in midlle, first half go in the end of passwor, last half go in beggining
- salt (Not Null) //is a hash that will be the crypto key to password
` The user input the password, password added by pepper, crypto by salt, must match password in db `
` if user reset password, generate new salt and pepper, generate random combination to be the password sended by e-mail `
` the data sended to api must be crypto by a algorithm that dont need key, like md5 `

## table: scales
- cd_scale
- Wifi_MAC
- eFuse_MAC
- provision_id `nome do dispositivo  -> PW_ + Wifi_MAC`
- pop
- uuid
`To think about...`
- decryptKey (Not Null) //Periodically changed
- salt (Not Null) //Periodically changed
- pepper (Not Null) //Periodically changed

### **Step 1: Improving Security in Wi-Fi Provisioning**

1. **AES256 Encryption**:
   - Combine `pop`, `key`, and `uuid` into a single string, e.g., `pop-key-uuid`.
   - Encrypt this string using AES256 with a secret key (stored securely on your server or app).
   - Generate a QR code with the encrypted string.

   Example:
   ```cpp
   String data = pop + "-" + key + "-" + uuid;
   String encryptedData = aes256Encrypt(data, secretKey);
   // Generate QR code with `encryptedData`
   ```

2. **QR Code Content**:
   - The QR code should contain the encrypted string and a version number (in case you update your encryption scheme in the future).
   - Example QR content: `v1:encryptedData`.

3. **Decryption in the App**:
   - When the user scans the QR code, your app decrypts the string using the same secret key.
   - Extract `pop`, `key`, and `uuid` from the decrypted string.

4. **Security Considerations**:
   - Use a unique `pop` (proof of possession) for each device to prevent replay attacks.
   - Rotate the secret key periodically and ensure it’s stored securely (e.g., in a secure enclave on the server or app).
   - Use HTTPS for all communication between the app and your server.

## Rotate the Secret Key
- Rotate the key periodically (e.g., monthly).
- Use a key management system (e.g., AWS KMS, HashiCorp Vault) to securely store and rotate keys.

## Salt:
 - Generate a unique random salt for each encryption operation.
 - Store the salt alongside the encrypted data (e.g., in the QR code or database).

## Pepper:
 - Use a secret pepper stored securely on your server.
 - Never store the pepper on the device or in the app.
 - Rotate the pepper at the same time as the secret key.
   
## Implementation Example
 ### Encryption:
 - Combine pop, key, and uuid into a string: data = pop + "-" + key + "-" + uuid.
 - Generate a unique salt for each encryption.
 - Add the pepper (stored on the server) to the data: data_with_pepper = data + pepper.
 - Encrypt the data using AES256 with the secret key: encrypted_data = AES256(data_with_pepper, secret_key).
 - Store the salt alongside the encrypted data: output = salt + ":" + encrypted_data.
  
 ### Decryption:
 - Extract the salt and encrypted data from the input.
 - Retrieve the pepper from the server.
 - Decrypt the data using the secret key: data_with_pepper = AES256_decrypt(encrypted_data, secret_key).
 - Remove the pepper to get the original data: data = data_with_pepper.replace(pepper, "").
 - Generate a QR code with the encrypted data and salt: salt + ":" + encrypted_data.

## Security Considerations
### Key Management:
- Use a secure key management system (e.g., AWS KMS, Google Cloud KMS) to store and rotate keys.
- Never hardcode keys in your code or store them in plaintext.
### Pepper Storage:
- Store the pepper securely on your server (e.g., in environment variables or a secrets manager).
- Never expose the pepper to the client (app or device).
### Salt Storage:
- Salts are not secret and can be stored alongside the encrypted data.
### Transport Security:
- Use HTTPS for all communication between the app, server, and devices.
- Use MQTT over TLS for secure communication with the ESP32.

# Summary
  -  Use salt and pepper for each encryption operation to ensure uniqueness and add an extra layer of security.
  -  Rotate the secret key and pepper periodically to limit the impact of a compromise.
  -  Combine both approaches for maximum security, but ensure you have a robust key management system in place.

---

### **Step 2: Provisioning Flow**

Your provisioning flow sounds good. Here’s a refined version:

1. **Initial State**:
   - ESP32 starts with a flag `isProvisioned = false`.
   - It enters provisioning mode (e.g., using `WiFiProv.beginProvision()`).

2. **QR Code Scanning**:
   - User scans the QR code in your app.
   - App decrypts the QR code content to get `pop`, `key`, and `uuid`.

3. **Device Discovery**:
   - App uses BLE or Wi-Fi scanning to discover the ESP32 device with the matching `uuid`.

4. **Wi-Fi Credentials**:
   - App prompts the user to enter their Wi-Fi credentials.
   - App sends the credentials to the ESP32 via BLE or Wi-Fi provisioning.

5. **Provisioning Completion**:
   - ESP32 connects to the Wi-Fi network.
   - Set `isProvisioned = true`.

---

### **Step 3: Post-Provisioning Communication**

Once the ESP32 is provisioned and connected to Wi-Fi, you can use MQTT or HTTP to communicate between the app and the ESP32. Here’s how:

1. **Communication Protocol**:
   - Use **MQTT** for lightweight, real-time communication.
     - ESP32 publishes weight data to an MQTT topic.
     - App subscribes to the same topic to receive data.
   - Alternatively, use **HTTP** for simple request-response communication.
     - ESP32 hosts a REST API endpoint to receive commands (e.g., set measurement time).
     - App sends HTTP requests to the ESP32.

2. **Setting Measurement Time**:
   - App sends the measurement time to the ESP32 via MQTT or HTTP.
   - Example MQTT topic: `esp32/scale1234/set_time`.
   - Example HTTP request: `POST /set_time { "time": 60 }`.

3. **Logging Data to SD Card**:
   - Use the SD card module to log Wi-Fi credentials and measurement time.
   - Example format for the log file:
     ```
     SSID: MyWiFi
     Password: MyPassword
     MeasurementTime: 60
     ```
   - Use the `SD.h` library to write and read from the SD card.

   Example code:
   ```cpp
   #include <SD.h>

   void logDataToSD(String ssid, String password, int measurementTime) {
       File file = SD.open("/config.txt", FILE_WRITE);
       if (file) {
           file.println("SSID: " + ssid);
           file.println("Password: " + password);
           file.println("MeasurementTime: " + String(measurementTime));
           file.close();
       }
   }
   ```

4. **Reconnection Logic**:
   - On boot, ESP32 reads the Wi-Fi credentials from the SD card.
   - If `isProvisioned == true`, it connects to the stored Wi-Fi network.
   - If the connection fails, it re-enters provisioning mode.

---

### **Step 4: Measuring Weight and Sending Data**

1. **Weight Measurement**:
   - Use a load cell and HX711 amplifier to measure weight.
   - Calibrate the load cell and convert the raw ADC values to weight.

2. **Sending Data to API**:
   - Use HTTP POST or MQTT to send weight data to your API.
   - Example HTTP POST:
     ```cpp
     String url = "https://yourapi.com/weight";
     String payload = "{\"scale_id\": \"scale1234\", \"weight\": " + String(weight) + "}";
     http.begin(url);
     http.addHeader("Content-Type", "application/json");
     int httpResponseCode = http.POST(payload);
     http.end();
     ```

3. **Scheduling Measurements**:
   - Use a timer or `millis()` to trigger weight measurements at the specified interval.
   - Example:
     ```cpp
     unsigned long previousMillis = 0;
     int measurementInterval = 60000; // 60 seconds

     void loop() {
         unsigned long currentMillis = millis();
         if (currentMillis - previousMillis >= measurementInterval) {
             previousMillis = currentMillis;
             float weight = readWeight();
             sendWeightToAPI(weight);
         }
     }
     ```

---

### **Summary of Your Flow**

1. **Provisioning**:
   - Encrypt `pop`, `key`, and `uuid` with AES256.
   - Generate a QR code with the encrypted data.
   - App decrypts the QR code, discovers the ESP32, and sends Wi-Fi credentials.

2. **Post-Provisioning**:
   - ESP32 connects to Wi-Fi and logs credentials to SD card.
   - App sends measurement time via MQTT or HTTP.
   - ESP32 logs measurement time to SD card.

3. **Measurement**:
   - ESP32 measures weight at the specified interval.
   - Sends weight data to your API via HTTP or MQTT.

4. **Reconnection**:
   - ESP32 reads Wi-Fi credentials from SD card on boot.
   - Reconnects to Wi-Fi automatically.

---
http://www.steves-internet-guide.com/mqtt/
https://www.emqx.com/en/blog/mqtt-vs-http
3. Hybrid Approach (MQTT + HTTP)
    Use MQTT for real-time communication (e.g., weight updates, commands).
    Use HTTP for initial provisioning, firmware updates, or less frequent tasks

For real-time, bidirectional communication with low resource consumption, MQTT is ideal. For simple request/response interactions, such as client data collection and submission, actively pulling data from the server, or leveraging existing web infrastructure, HTTP is more appropriate.

### **Step-by-Step: Exposing MQTT Broker with Cloudflare and NGINX**

#### **1. Prerequisites**
- A Linux server with **Mosquitto MQTT broker** installed.
- A domain name pointed to your server via **Cloudflare**.
- **NGINX** installed on your server.

---

#### **2. Configure Mosquitto MQTT Broker**
1. **Edit Mosquitto Configuration**:
   - Open the Mosquitto config file:
     ```bash
     sudo nano /etc/mosquitto/mosquitto.conf
     ```
   - Add the following lines to configure the broker:
     ```bash
     listener 1883
     allow_anonymous false
     password_file /etc/mosquitto/passwd
     ```
   - Create a password file for authentication:
     ```bash
     sudo mosquitto_passwd -c /etc/mosquitto/passwd your_username
     ```
   - Restart Mosquitto:
     ```bash
     sudo systemctl restart mosquitto
     ```

2. **Test Locally**:
   - Ensure Mosquitto is running and accessible locally:
     ```bash
     mosquitto_sub -h localhost -t "test/topic" -u "your_username" -P "your_password"
     mosquitto_pub -h localhost -t "test/topic" -m "Hello, MQTT!" -u "your_username" -P "your_password"
     ```

---

#### **3. Configure NGINX as a Reverse Proxy**
1. **Install NGINX**:
   - If not already installed:
     ```bash
     sudo apt update
     sudo apt install nginx
     ```

2. **Create an NGINX Configuration for MQTT**:
   - Create a new configuration file:
     ```bash
     sudo nano /etc/nginx/sites-available/mqtt
     ```
   - Add the following configuration:
     ```nginx
     server {
         listen 80;
         server_name mqtt.yourdomain.com; # Replace with your domain

         location / {
             proxy_pass http://localhost:1883;
             proxy_http_version 1.1;
             proxy_set_header Upgrade $http_upgrade;
             proxy_set_header Connection "Upgrade";
             proxy_set_header Host $host;
         }
     }
     ```

3. **Enable the Configuration**:
   - Create a symbolic link to enable the configuration:
     ```bash
     sudo ln -s /etc/nginx/sites-available/mqtt /etc/nginx/sites-enabled/
     ```
   - Test the NGINX configuration:
     ```bash
     sudo nginx -t
     ```
   - Reload NGINX:
     ```bash
     sudo systemctl reload nginx
     ```

---

#### **4. Configure Cloudflare**
1. **Add Your Domain to Cloudflare**:
   - Log in to Cloudflare and add your domain.
   - Update your domain’s nameservers to point to Cloudflare.

2. **Create a DNS Record**:
   - Add an `A` record for your MQTT subdomain (e.g., `mqtt.yourdomain.com`) pointing to your server’s IP address.

3. **Enable SSL/TLS**:
   - In Cloudflare, go to **SSL/TLS** > **Overview**.
   - Set the encryption mode to **Full** or **Full (Strict)**.

4. **Configure Firewall Rules**:
   - In Cloudflare, go to **Firewall** > **Firewall Rules**.
   - Create a rule to allow traffic to `mqtt.yourdomain.com` on port 80.

---

#### **5. Secure MQTT with SSL/TLS**
1. **Generate SSL Certificates**:
   - Use Let’s Encrypt to generate SSL certificates:
     ```bash
     sudo apt install certbot python3-certbot-nginx
     sudo certbot --nginx -d mqtt.yourdomain.com
     ```

2. **Update NGINX Configuration for HTTPS**:
   - Certbot will automatically update your NGINX configuration to use HTTPS.

3. **Update Mosquitto Configuration for SSL**:
   - Edit the Mosquitto config file:
     ```bash
     sudo nano /etc/mosquitto/mosquitto.conf
     ```
   - Add the following lines:
     ```bash
     listener 8883
     cafile /etc/letsencrypt/live/mqtt.yourdomain.com/chain.pem
     certfile /etc/letsencrypt/live/mqtt.yourdomain.com/cert.pem
     keyfile /etc/letsencrypt/live/mqtt.yourdomain.com/privkey.pem
     ```
   - Restart Mosquitto:
     ```bash
     sudo systemctl restart mosquitto
     ```

---

#### **6. Test Your Setup**
1. **From ESP32**:
   - Use the `PubSubClient` library to connect to `mqtt.yourdomain.com` on port 8883 with SSL.

2. **From Android App**:
   - Use an MQTT client library (e.g., `Eclipse Paho`) to connect to `mqtt.yourdomain.com` on port 8883 with SSL.

---

### **Why You Might Not Need Node.js/Python/C++**

If your ecosystem consists of:
- **ESP32**: Publishes/subscribes to MQTT topics.
- **Android App**: Subscribes/publishes to MQTT topics.
- **Mosquitto MQTT Broker**: Handles message routing.

You don’t necessarily need **Node.js/Python/C++** unless:
1. **You Need a Backend**:
   - For storing data (e.g., weight measurements) in a database.
   - For processing data (e.g., analytics, alerts).

2. **You Need Additional Logic**:
   - For example, if you want to send notifications or integrate with third-party APIs.

If your Android app and ESP32 can handle all the logic and communication via MQTT, then **Mosquitto + Android + ESP32** is sufficient.

---

### **Summary**
1. Set up **Mosquitto MQTT broker** on your Linux server.
2. Use **NGINX** as a reverse proxy to expose Mosquitto securely.
3. Configure **Cloudflare** for DNS, SSL, and firewall rules.
4. Use **Let’s Encrypt** to enable HTTPS for secure communication.
5. Connect your **ESP32** and **Android app** directly to the MQTT broker.


