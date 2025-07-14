// #include "system_manager.h"
#include "wifi_prov_ble.h"

void app_main()
{
    // system_manager_start();
    wifi_prov_init();
}

// vTaskDelay(): Pausa a tarefa sem bloquear o processador
// pdMS_TO_TICKS(): Converte milissegundos para ticks do RTOS
/*
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

    graph TD
    A[system_manager_start] --> B[Hardware]
    B --> C[SD Card]
    C --> D[Sensores]
    D --> E[Fila]
    E --> F[Tarefas]

    sequenceDiagram
    participant Sensor
    participant Fila
    participant SD
    Sensor->>Fila: Envia dados (non-blocking)
    Fila->>SD: Entrega dados (blocking)
    SD->>Fila: Confirma recebimento

    IDF FreeRTOS source code is based on Vanilla FreeRTOS v10.5.1 but contains significant modifications to both kernel behavior and API in order to support dual-core SMP.
*/
