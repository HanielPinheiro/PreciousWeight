## Precious Weight Firmware

- 'Dicionário'
  vTaskDelay(): Pausa a tarefa sem bloquear o processador
  pdMS_TO_TICKS(): Converte milissegundos para ticks do RTOS
  IDF FreeRTOS source code is based on Vanilla FreeRTOS v10.5.1 but contains significant modifications to both kernel behavior and API in order to support dual-core SMP.

# Explicações

    As conexões wifi no esp32 sao protegidas pro protocolos que envolvem algoritmos Diffi-Helmman: https://www.devmedia.com.br/criptografia-e-protocolo-diffie-hellman/10717
        https://www.youtube.com/watch?v=IRl1IjlY5xY&t (Discrete Logarithm Problem)

    Por que o CMakeList principal é diferente do CmakeList dos componentes?
        O principal coordena o projeto todo.
        Os dos componentes são mínimos (apenas registram seus arquivos).

    Conceitos Importantes do FreeRTOS:
    Tarefas vs. Filas (Queues)
        Tarefa: Uma "thread" independente (ex.: ler sensores, escrever no SD).
        No FreeRTOS, "task" e "thread" são termos intercambiáveis (ambas são linhas de execução independentes).
        Fila (Queue): Estrutura segura para troca de dados entre tarefas.
            Exemplo:
                Tarefa do sensor lê peso e envia para a fila.
                Tarefa do SD Card pega o valor da fila e salva.
    Task (Tarefa)
    O que é: Uma unidade independente de execução no FreeRTOS, como um "trabalhador" especializado
    Exemplo prático:
        Imagine uma fábrica com 3 funcionários:
            Funcionário 1 (SensorTask): Só mede pesos e coloca em uma caixa (fila).
            Funcionário 2 (SDTask): Só pega os pesos da caixa e anota em um livro (SD Card).
            Funcionário 3 (MonitorTask): Verifica se a caixa não está muito cheia ou vazia.

    O Que São Filas (Queues) no FreeRTOS?
        Um canal de comunicação entre tarefas, garantindo que os dados sejam passados de forma segura e ordenada.
        Exemplo: A caixa onde o Funcionário 1 coloca os pesos e o Funcionário 2 pega. Se a caixa estiver cheia,
                 o Funcionário 1 espera; se estiver vazia, o Funcionário 2 espera.
        Estrutura FIFO: Primeiro a entrar, primeiro a sair.
        Thread-safe: Seguro para comunicação entre tarefas.
        Bloqueante: Tarefas podem esperar por novos dados automaticamente.
    Por Que Usar Filas?
        Desacoplamento: Sensores e SD Card não precisam saber um do outro.
        Segurança: Evita corrupção de dados por acesso concorrente.
        Controle: Prioridades diferentes para cada tarefa (ex.: sensores > SD Card).

    Mutex/Semáforos
        Mutex: "Trava" para evitar que duas tarefas usem o mesmo recurso ao mesmo tempo (ex.: SD Card).
        Semáforo: Similar, mas controla acesso a múltiplas instâncias.
        Problema: Se duas tarefas tentarem acessar o SD Card ao mesmo tempo, pode corromper dados.
        Solução: Usar um semáforo como "aviso de ocupado".
        Exemplo:
            Semáforo: Um cartão "EM USO" colocado no SD Card.
            Se a SDTask estiver escrevendo, a task_monitor espera até o cartão ser removido.

    system_manager_start
    |
    |---> Hardware
                |
                |---> SD Card
                        |
                        |---> Sensores
                                    |
                                    |---> Fila (Queue)
                                            |
                                            |---> Tarefas (Tasks)

Sensor enviando dados
|
|---> Sensor->>Fila: Envia dados (non-blocking)
|
|---> Fila->>SD: Entrega dados (blocking)
|
|---> SD->>Fila: Confirma recebimento

    Mqtt safety
    |
    |-- Is your system on a public or private network?
            |
            |-- Public (e.g., Internet or Cloud Broker)
            |     |
            |     |-- Do you need strong device authentication?
            |           |
            |           |-- Yes --> Mutual TLS (mTLS) --> `ssl_mutual_auth`
            |           |
            |           |-- No  --> Server-side TLS only --> `ssl`
            |
            |-- Private (e.g., Factory LAN or VPN)
                |
                |-- Do you need hardware-backed key protection?
                |      |
                |      |-- Yes --> Digital Signature (DS Peripheral) --> `ssl_ds`
                |      |
                |      |-- No
                |            |
                |            |-- Do you need fast and simple authentication?
                |                   |
                |                   |-- Yes --> Pre-Shared Key (PSK) --> `ssl_psk`
                |                   |
                |                   |-- No  --> Server-side TLS only --> `ssl`

    when deploying medical devices in a hospital, security and trust become non-negotiable. Use ssl_mutual_auth
    Hospitals follow zero-trust security models: every connection must be authenticated, even inside the internal network.
    mTLS supports this model natively — every ESP32 proves its identity cryptographically.
    Prevent Man-in-the-Middle (MITM) Attacks.
    mTLS ensures:
        Data comes from a verified device. (has the key)
        Commands go to the correct target. (validated server key)
        Nothing is tampered with in transit. (no intervention of a third (MITM attack))
    ESP32 Device
    |
    |-- TLS with mTLS (ssl_mutual_auth)
            |
            |-- MQTT v5 Features (ttl, metadata, etc.)

            MQTT v5 in Medical Context: What It Adds on Top of TLS
            Metadata with User Properties:
                Send extra data in the message header (e.g., device_type, patient_id, location_id) without bloating the payload.
                Perfect for hospital systems where context matters (e.g., “bed 4 in ICU” vs “bed 4 in ER”).
            Message Expiry / TTL:
                MQTT v5 lets you define a Time-To-Live for messages.
                If the subscriber is offline too long, the broker will discard stale data.
                Ideal for real-time monitoring: you don't want to act on a 30s-old heartbeat reading.
            Session Expiry & Resumption:
                Client can define how long the broker should keep the session alive.
                Useful for mobile devices (e.g., wearable ECG sensors that reconnect to Wi-Fi).
            Improved Error Reporting:
                MQTT v3.1 just said "connection refused" — no detail.
                MQTT v5 provides detailed reason codes (e.g., "not authorized", "quota exceeded").
                Helps debugging and logging in medical infrastructure.
            Flow Control / Message Size Hints:
                Limit how many messages or how much data a device can publish or receive.
                Useful in bandwidth-constrained environments (e.g., wireless telemetry carts).
            Shared Subscriptions
                Multiple devices (e.g., dashboards or nurse stations) can share a single subscription.
                Load balancing is automatic at the MQTT broker.
            Topic Aliases
                Reduce message overhead by assigning short aliases to long topic names.
                Saves bandwidth in high-frequency telemetry.

Para um dispositivo médico, considere também:
Certificação de software médico (IEC 62304)
Testes de validação rigorosos
Registro de todas as operações para auditoria
Mecanismos de recall/update seguro

[BOOT] → [INITIALIZING] → [PROVISIONING?] → [CONNECTING] → [OPERATIONAL]
↓ ↓ ↓ ↓
[ERROR] ←──────[RECOVERY] ←──────[DISCONNECTED] ←──[ERROR]
