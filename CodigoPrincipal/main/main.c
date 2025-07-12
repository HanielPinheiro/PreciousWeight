#include "system_manager.h"

void app_main()
{
    system_manager_start();
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
        Fila (Queue): Estrutura segura para troca de dados entre tarefas.
            Exemplo:
                Tarefa do sensor lê peso e envia para a fila.
                Tarefa do SD Card pega o valor da fila e salva.

    Mutex/Semáforos
        Mutex: "Trava" para evitar que duas tarefas usem o mesmo recurso ao mesmo tempo (ex.: SD Card).
        Semáforo: Similar, mas controla acesso a múltiplas instâncias.

    O Que São Filas (Queues) no FreeRTOS?
        Estrutura FIFO: Primeiro a entrar, primeiro a sair.
        Thread-safe: Seguro para comunicação entre tarefas.
        Bloqueante: Tarefas podem esperar por novos dados automaticamente.
    Por Que Usar Filas?
        Desacoplamento: Sensores e SD Card não precisam saber um do outro.
        Segurança: Evita corrupção de dados por acesso concorrente.
        Controle: Prioridades diferentes para cada tarefa (ex.: sensores > SD Card).
*/
