# DISSERTACAO_CONTEXTO.md — Contexto Acadêmico para Geração de Dissertação

> Documento-síntese usado como **fonte primária no NotebookLM** para redigir a dissertação. Consolida objetivos, referencial conceitual, metodologia, arquitetura implementada, resultados de validação e limitações do sistema **PreciousWeight** — balança pediátrica inteligente para UTI neonatal. Toda descrição técnica é fiel ao firmware em HEAD (ESP32 / ESP-IDF v5.4 / FreeRTOS). Leia junto com os demais arquivos da pasta `md_files`.

---

## 1. Resumo executivo

Este trabalho desenvolve uma **balança pediátrica inteligente para UTI neonatal** baseada em ESP32, com **4 células de carga** instrumentadas por amplificadores **HX711**, comunicação **MQTT/TLS** para integração hospitalar, e **persistência local em cartão SD** com mecanismo de **outbox offline** que garante rastreabilidade de todas as pesagens. A arquitetura adota um modelo de **degradação graciosa** e um **bloqueio de segurança** que impede operação sem nenhum meio de auditoria de dados, em alinhamento com requisitos rigorosos de contexto clínico.

Contribuição principal: a **garantia de não-anonimidade da medição** — isto é, nenhuma pesagem é perdida sem deixar rastro — combinada a um pipeline de aquisição com filtragem robusta (mediana aparada) e agregação multi-célula para atingir precisão de **erro máximo inferior a 5 g**.

---

## 2. Problema e motivação

- Monitoramento de peso é crítico em recém-nascidos, especialmente prematuros e de baixo peso, nos quais pequenas variações (< 50 g) têm relevância clínica.
- Em ambiente hospitalar, a **rastreabilidade** da medição (quem/como/quando e a integridade do dado) é requisito jurídico e de segurança do paciente.
- Desafios técnicos: baixo nível de sinal nas células de carga, ruído e vibração, drift térmico, histerese mecânica, e a necessidade de funcionamento confiável durante quedas de energia/rede.

---

## 3. Objetivos

### Geral
Projetar e validar o firmware de uma balança pediátrica inteligente de 4 células de carga, para UTI neonatal, com precisão de **erro máximo < 5 g** e garantia de rastreabilidade de todas as pesagens.

### Específicos
1. Implementar aquisição multi-célula HX711 com filtragem robusta (mediana aparada) e agregação.
2. Implementar provisionamento Wi-Fi por BLE e comunicação MQTT/TLS com controle mútuo.
3. Garantir pesagem confiável com **outbox offline** (SD + buffer RAM) e bloqueio de segurança em falha total de persistência.
4. Definir um protocolo de dados estruturado (`MEA|...`) e uma trilha de auditoria (audit.log, commands.log, weights.txt, outbox.log).
5. Validar por injeção de falhas (energia, Wi-Fi, SD) conforme checklist.

---

## 4. Fundamentação conceitual

- **Célula de carga TAL220 e ponte de Wheatstone:** gera sinal diferencial de baixa amplitude proporcional à carga.
- **HX711 (ADC sacima-delta 24 bits, Canal A, ganho 128):** amplifica e digitaliza o sinal da célula. Leitura raw convertida em peso por modelo linear `w = (raw − offset)/calib_factor`.
- **ESP32 / ESP-IDF v5.4 / FreeRTOS:** microcontrolador com dual-core, WiFi/BT, e RTOS preemptivo para tarefas concorrentes (leitores, processador, comunicação, persistência).
- **Filtragem:** a **mediana aparada (trimmed mean)** combina robustez a outliers com aproveitamento de amostras centrais, mais adequada que mediana pura e mais estável que média simples sob ruído impulsivo.
- **MQTT/TLS mútuo:** publicar/assinar com autenticação de certificado de ambos os lados, LWT para deteção de queda, QoS 1/2 para entrega.
- **Padrões de confiabilidade:** outbox pattern (fila persistente de envio), watchdog de tarefas, degradação graciosa, redunância de persistência.

---

## 5. Metodologia

### 5.1 Geral
Abordagem experimental de desenvolvimento orientado a hardware. Fases: levantamento de requisitos → arquitetura de firmware → implementação modular → validação por injeção de falhas → análise de registros.

### 5.2 Sequência de boot do firmware (implementada)
1. **Fase 0 — Infra:** LED task, NVS, persistência da razão de reset.
2. **Fase 1 — SD (degradável):** montagem do cartão e do banco em memória; se falhar, segue **sem** persistência local.
3. **Fase 2 — Aquisição (trava):** inicialização HX711 + tara por célula + tasks de leitura/agregação. Roda **independente de rede**.
4. **Fase 3 — WiFi/SNTP/MQTT (assíncrona):** tarefa `wifi_manager` provisiona (STA/BLE), sincroniza relógio, e só então arma o **scheduler de horários** e inicia o **MQTT**.
5. **Fase 4 — Sanity check 120 s:** avalia SD e MQTT; em falha dupla, ativa o **bloqueio de segurança**.

### 5.3 Aquisição e tratamento de sinal
- Cada célula: mediana aparada de 7 amostras (média das 3 centrais).
- Agregação: **soma das 4 células** a 1 Hz, com deadband de 10 g.
- Tara de boot (40 amostras por célula) e tara remota via comando `[TAR]`.

### 5.4 Rastreabilidade e persistência
- Arquivos estruturados em `/sdcard/scales/`: `weights.txt`, `audit.log`, `commands.log`, `critical.log`, `outbox.log`, `state.txt`, `sequence.txt`.
- **Outbox:** mensagem publicada é gravada como `P|seq|qos|topic|payload`; reenviada por task a 1 Hz e marcada `S|seq` quando entregue. SD indisponível → **buffer RAM circular** de 10 slots (fallback volátil).
- **sequence_id monotônico** persistido em `sequence.txt`.

### 5.5 Validação
Checklist de injeção de falhas em [TESTES_CRITICOS.md](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/Esp32_Codigo/CodigoPrincipal/md_files/TESTES_CRITICOS.md): queda de Wi-Fi, broker MQTT fora, SD ausente/cheio/removido em runtime, corte de energia durante escrita e durante publish, saturação de comandos, e bloqueio de segurança após 120 s.

---

## 6. Resultados e discussão

### 6.1 Arquitetura entregue
- Inicialização por fases com política por-falha (trava vs degrade).
- Pipeline de precisão descrito em [FIRMWARE_ALGORITMOS_PRECISAO.md](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/Esp32_Codigo/CodigoPrincipal/md_files/FIRMWARE_ALGORITMOS_PRECISAO.md).
- Contrato MQTT definido (tópicos, comandos, QoS).

### 6.2 Limitações observadas (fiel ao código)
1. **Pesagem agendada/manual dependem de Wi-Fi/MQTT** — o scheduler só é armado após WiFi+SNTP; não há disparo horário em boot offline. O que roda independente de rede é a aquisição/agregação contínua.
2. **Calibração estática** (fatores fixos), sem compensação térmica dinâmica ou equalização de matriz de acoplamento entre células.
3. **Buffer RAM volátil** (10 slots): perda de pendentes em power-cut com SD offline e fila cheia.
4. `MQTT_TOPIC_EVENTS` comentado: eventos estruturados não são publicados (apenas em SD).
5. **Monotonicidade do sequence** depende de escrita atômica; corrupção de `sequence.txt` re-inicia o ID em 0.

### 6.3 Discussão para a dissertação
- Analisar o **trade-off precisão × responsividade**: filtragem mediana aparada aumenta estabilidade mas adiciona latência (~70 ms por leitura filtrada). Em dinâmica lenta (peso de neonato) isto é aceitável.
- Analisar o **Trade-off rastreabilidade × disponibilidade**: o bloqueio de segurança troca disponibilidade por garantia de não-perda de dado — justificável num contexto de auditoria hospitalar.
- Discutir a **extensão futura** para calibração multiponto, compensação térmica e filtração adaptativa (IIR/Kalman) como caminho para consolidar a meta < 5 g sob repetibilidade.

---

## 7. Trabalhos futuros

1. Calibração **multiponto** com pesos-treino validados e ajuste automático de histese.
2. **Compensação de drift térmico** dos offsets e ganhos.
3. **Equalização de matriz de acoplamento** entre as 4 células.
4. **Filtro adaptativo/Kalman** com deteção de estabilização.
5. Habilitar publicação de eventos estruturados (`/events/`).
6. Estudo de **consumo energético / modos de sono** para operação em bateria.

---

## 8. Glossário e convenções de dados

- `MEA|seq|epoch|origem|peso` — linha de pesagem em weights.txt (`origem` ∈ {manual, scheduled}).
- `EVT|seq|epoch|severity|tipo|origem|msg` — evento de auditoria (`severity` ∈ {INFO, WARN, ERROR, CRITICAL}).
- `CMD|seq|epoch|payload` — comando recebido (commands.log).
- `P|seq|qos|topic|payload` / `S|seq` — outbox (pendente / enviado).
- `pw_safe_epoch()` — timestamp SNTP se sincronizado, senão tempo desde boot (nunca 0).

---

## 9. Referência rápida de arquivos de código

| Camada | Arquivo |
|--------|---------|
| Boot / orquestração | [main/main.c](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/Esp32_Codigo/CodigoPrincipal/main/main.c) |
| Drives de medição | [drivers/hx711/hx711.c](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/Esp32_Codigo/CodigoPrincipal/drivers/hx711/hx711.c) |
| Aquisição/agregação | [tasks/sensors_task/sensors_task.c](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/Esp32_Codigo/CodigoPrincipal/tasks/sensors_task/sensors_task.c) |
| Conectividade WiFi/prov | [comm/wifi_prov_ble/wifi_prov_ble.c](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/Esp32_Codigo/CodigoPrincipal/comm/wifi_prov_ble/wifi_prov_ble.c) |
| MQTT | [comm/mqtt_config/mqtt3.c](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/Esp32_Codigo/CodigoPrincipal/comm/mqtt_config/mqtt3.c) |
| Comandos / parser | [mqtt_events/parser/process_mqtt_data.c](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/Esp32_Codigo/CodigoPrincipal/mqtt_events/parser/process_mqtt_data.c) |
| Agendamento | [mqtt_events/scheduler/weight_timer_scheduler.c](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/Esp32_Codigo/CodigoPrincipal/mqtt_events/scheduler/weight_timer_scheduler.c) |
| Persistência / outbox / g_sys | [drivers/sdcard_persistence/sdcard_persistence.c](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/Esp32_Codigo/CodigoPrincipal/drivers/sdcard_persistence/sdcard_persistence.c) |
| SD HAL | [drivers/sdcard/sdcard.c](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/Esp32_Codigo/CodigoPrincipal/drivers/sdcard/sdcard.c) |
| MQTT task / outbox worker | [tasks/mqtt_task/mqtt_task.c](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/Esp32_Codigo/CodigoPrincipal/tasks/mqtt_task/mqtt_task.c) |

---

## 10. Nota de fidelidade para a geração de texto

Ao usar este material no NotebookLM, **não inferir capacidades ausentes do firmware**. Em particular:
- Não afirmar que pesagens agendadas ocorrem offline (elas dependem de WiFi/SNTP).
- Não afirmar que existe calibração multiponto ou compensação térmica automática.
- Tratar a meta de **erro < 5 g** como **objetivo de projeto/validação pendente**, não como resultado medido comprovado (os fatores de calibração são estáticos de fábrica).