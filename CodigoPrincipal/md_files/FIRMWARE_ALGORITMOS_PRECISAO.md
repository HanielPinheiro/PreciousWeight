# FIRMWARE_ALGORITMOS_PRECISAO.md — Pipeline de Medição de Alta Precisão

Documento técnico do **pipeline de medição** da balança PreciousWeight, derivado estritamente do código em HEAD ([hx711.c](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/Esp32_Codigo/CodigoPrincipal/drivers/hx711/hx711.c), [sensors_task.c](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/Esp32_Codigo/CodigoPrincipal/tasks/sensors_task/sensors_task.c)). Sem valores inventados: parâmetros, tolerâncias e constantes são os do source.

**Objetivo de projeto:** sistema de 4 células de carga com **erro máximo < 5 g**, operação em ambiente de UTI neonatal (pesos típicos < 5 kg, resolução de 0,01 g na transmissão).

---

## 1. Hardware de Medição

- 4 amplificadores **HX711** (ADC sigma-delta de 24 bits, Canal A, **ganho 128**), um por célula de carga TAL220.
- Interface **bit-bang por GPIO** (DOUT + SCK), sem SPI dedicado para o HX711.

Pinos (em [hx711.h](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/Esp32_Codigo/CodigoPrincipal/drivers/hx711/hx711.h#L10-L20)):

| Célula | DOUT | SCK |
|--------|------|-----|
| 1 | GPIO 21 | GPIO 22 |
| 2 | GPIO 16 | GPIO 14 |
| 3 | GPIO 32 | GPIO 33 |
| 4 | GPIO 25 | GPIO 26 |

Estrutura por célula (`hx711_t`): `id`, `dout_pin`, `sck_pin`, `offset` (int32) e `calib_factor` (double). Offsets e fatores de calibração são **inicializados estaticamente** em [main.c#L11-L15](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/Esp32_Codigo/CodigoPrincipal/main/main.c#L11-L15):

| Célula | offset | calib_factor |
|--------|--------|--------------|
| 0 | 405827 | 397.34 |
| 1 | 217586 | 405.06 |
| 2 | 316565 | 390.86 |
| 3 | 310182 | 398.96 |

> **Calibração atual:** é uma calibração **de fábrica** (fatores fixos embutidos), não um procedimento de calibração multiponto dinâmica em runtime. `AT_CALIBRATION = 0` (modo produção ativado). A validação da meta de 5 g deve ser feita com pesos-treino sobre esses fatores.

---

## 2. Camadas de Aquisição (hx711.c)

### 2.1 Leitura raw do HX711 — `hx711_read_raw()`

- Aguarda DOUT ir a nível baixo (`hx711_wait_ready_timeout`, **timeout 200 ms**, checagem a cada 10 ms).
- Caso timeout → retorna `HX711_INVALID_READING` (`0x80000000`).
- Faz **25 pulsos de clock** no SCK (24 de dados + 1 para gravar Canal A ganho 128) dentro de **seção crítica** (`portENTER_CRITICAL`/`portEXIT_CRITICAL`), com `esp_rom_delay_us(1)`.
- Converte 24 bits com sinal para 32 bits com sinal: `if (data & 0x800000) data |= 0xFF000000;`.

### 2.2 Filtro de mediana aparada — `hx711_read_median_trimmed()`

Parâmetros: `MEDIAN_SAMPLES = 7`, descarte de 2 extremos de cada lado, média das 3 amostras centrais:

```
1) Coleta 7 amostras válidas (espaciadas por vTaskDelay 10 ms).
   - amostra inválida: incrementa invalid_count; se > 14 (7*2) → retorna INVALID.
2) insertion_sort das 7 amostras.
3) soma = samples[2] + samples[3] + samples[4]; retorna sum/3 (média truncada).
```

**Justificativa técnica:** a mediana aparada (trimmed mean) rejeita **outliers de curto período** (spikes elétricos, tremor mecânico transitório) de forma determinística, com custo O(n²) desprezível para n=7. Remove os 2 maiores e 2 menores, mantendo a tendência central — mais estável que média simples pura sob poisson/impulsos, e mais sensível que mediana pura (aproveita 3 amostras). Trade-off: menor taxa de amostragem efetiva (~7 leituras brutas a cada ~70 ms).

### 2.3 Média aritmética — `hx711_read_average()`

- Média de N amostras válidas; amostra inválida incrementa `invalid_count`; se inválidas exceder N, interrompe e retorna INVALID.
- Usada com **`TARE_NUMBER = 40`** no procedimento de tara de boot.

### 2.4 Conversão peso

```
peso_célula (double) = ( raw_mediana_aparada − offset ) / calib_factor
```

Em [hx711_read_sensor_weight](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/Esp32_Codigo/CodigoPrincipal/drivers/hx711/hx711.c#L282-L308): com `AT_CALIBRATION=1` loga `Sensor[id]:Raw|Offset|Diff`; em produção a razão é calculada e retornada. Leitura inválida → retorna `HX711_INVALID_READING` como double.

---

## 3. Concorrência no HX711

- Um `portMUX_TYPE` para a seção crítica **por célula** durante o bit-bang (protege SCK/DOUT contra interrupções que corromperiam o clocking).
- Um `SemaphoreHandle_t` (`s_mutex`, `xSemaphoreCreateMutex`) global para proteger o acesso aos campos `offset`/`calib_factor` das structs (`hx711_get_offset`/`set_offset`/`hx711_set_calib_factor`/`hx711_tare_safe`).

---

## 4. Tara

### 4.1 Tara de inicialização — `hx711_tare()` (chamada por `hx711_initialize_sensors`)

- Para cada célula: média de **40 amostras** (`TARE_NUMBER`), até 3 tentativas.
- Sucesso → `hx711_set_offset(id, média)`. Todas as tentativas inválidas → **offset = 0** (não trava boot; retorna `ESP_ERR_INVALID_STATE` apenas informativo).
- Ao final, `vTaskDelay(2000 ms)` para **estabilização térmica** das células.
- Executa na **Fase 2** do boot (antes do WiFi).

### 4.2 Tara por comando — `tare_routine()` (`[TAR]`)

Em [process_mqtt_data.c](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/Esp32_Codigo/CodigoPrincipal/mqtt_events/parser/process_mqtt_data.c#L125-L146):

1. `sensors_set_tare_mode(true)` — **sinaliza as tasks leitoras para pararem de gravar** (`s_tare_in_progress`).
2. `vTaskDelay(1200 ms)` — drena leituras em andamento.
3. Para cada célula: `hx711_tare_safe(id)` — loop até conseguir leitura válida (média de 2), então seta offset.
4. `sensors_set_tare_mode(false)` — retoma a medição contínua.

> Corrigido: `[TAR]` está **implementado** no HEAD. A linha `// tare_routine(TARE_AUTOMATICALLY);` no final de `app_main` está **comentada**, ou seja, não há tara automática pós-boot adicional além da tara já feita em `hx711_initialize_sensors`.

---

## 5. Pipeline de Agregação Multi-Sensor (sensors_task.c)

### 5.1 Tasks leitoras (`sensor_reader_task`, ×4)

- Uma task por célula, prioridade **HIGH** (3), stack 4096.
- Loop com `vTaskDelayUntil(&last_wake, pdMS_TO_TICKS(100))` → **10 Hz** por célula.
- Lê `hx711_read_sensor_weight(id)`; se válida, grava em `s_last_readings[id]` sob mutex.
- Skipped enquanto `s_tare_in_progress` (comandos de tara suspendem a gravação).

### 5.2 Task processadora (`sensor_processor_task`)

- Prioridade **MEDIUM** (2), stack 4096, loop a **1 Hz** (`vTaskDelayUntil` 1000 ms).
- **Soma aritmética das 4 células** → peso global candidato.
- **Deadband:** se soma ≤ **10,0 g** → força soma = 0 (suprime ruído residual de offset em plataforma vazia).
- Grava em `final_weight` via `set_global_weight()` sob mutex.
- Se nenhuma célula válida → `final_weight=0` + evento `SENSOR_NO_VALID_READING`.

### 5.3 Consumo do peso global

`get_global_weight()` (mutex) retorna o último valor agregado. É consumido por:
- Pesagem manual `[MEA]` (measure_routine).
- Pesagem agendada (task_worker do scheduler).

---

## 6. Precisão e Implicações

- A **filtragem** de cada célula é mediana aparada de 7 (com 3 centrais). A **taxa de saída** por célula é 10 Hz (uma mediana aparada a cada 100 ms).
- A **resolução de exibição/transmissão** é `%.2f` (centésimos de grama) na linha `MEA|...` e no payload `[MEA]{...}`/`[WEI]{...}`.
- O **erro final** depende da qualidade dos `calib_factor` e `offset` (lineares estáticos). Não há compensação térmica ou igualação dinâmica entre células **no firmware atual** — a homogeneização (células com calib_factors distintos: 390.86–405.06) é feita por fator estático, assumindo resposta linear.
- **Ganho efetivo:** características do HX711 (24 bits, ganho 128, ±11 dB de atenuação para tensão de alimentação 5 V nominal) fornecem a resolução crua; o fator de calibração (≈390–405) converte counts em gramas.

---

## 7. Recomendações para Atingir a Meta < 5 g (por prioridade)

### Alta prioridade
1. **Calibração multiponto por célula** substituindo/ajustando os fatores estáticos (atuais medem a inclinação linear, não cubem histerese/não-linearidade em toda a faixa).
2. **Plataforma mecânica livre de histerese e torção** — estrutura rígida, pontos de carga alinhados (mitigação mecânica antes de algoritmos, per diretriz do projeto).
3. **Compensação de drift por temperatura** dos `offset` (tara recorrente em vazio) e dos ganhos.

### Média prioridade
4. **Igualação/ponderação dinâmica** entre células (calibração de matriz de acoplamento) para reduzir erro de carga fora do centro.
5. **Detecção de estabilização** (janela de variância/tendência) antes de coletar o valor final, suprimindo leitura durante vibração.

### Baixa prioridade
6. Aumentar `MEDIAN_SAMPLES` ou adotar filtro IIR/Kalman adaptativo para cenários de vibração contínua — ao custo de latência.
7. **Auto-calibração de sobrecarga** e detcção de célula com leitura anômala (tolerância a falha de célula individual).

---

## 8. Referência rápida de constantes (source)

| Constante | Valor | Uso |
|-----------|-------|-----|
| `NUM_WEIGHT_SENSORS` | 4 | nº de células |
| `HX711_CHANNEL_A_128` | 25 | pulsos de clock por leitura |
| `HX711_INVALID_READING` | 0x80000000 | marcador de leitura inválida |
| timeout ready | 200 ms | `hx711_wait_ready_timeout` |
| `MEDIAN_SAMPLES` | 7 | mediana aparada |
| `TARE_NUMBER` | 40 | média na tara de boot |
| `AVERAGE_NUMBER` | 20 | definido (não usado no fluxo atual) |
| intervalo leituras | 10 ms | `vTaskDelay` no filtro/e loop |
| taxa leitora | 10 Hz | `vTaskDelayUntil` 100 ms |
| taxa processadora | 1 Hz | `vTaskDelayUntil` 1000 ms |
| deadband agregado | 10.0 g | soma ≤ 10 → 0 |
| resolução out | 0.01 g | `%.2f` |
| calib_factors | 397.34 / 405.06 / 390.86 / 398.96 | inclinação por célula |