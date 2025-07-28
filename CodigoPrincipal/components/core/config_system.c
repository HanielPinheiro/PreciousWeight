#include "config_system.h"

horario_pesagem_t weight_times[MAX_WEIGHT_TIMES];
uint8_t number_times = 0;
estado_balanca_t estado_atual;

void set_actual_state()
{
    // estado_atual = sdcard_load_weight_times() != ESP_OK ? ESTADO_SEM_BEBE : ESTADO_COM_BEBE;
}

void handle_estado_sem_bebe()
{
    // iniciar_task_peso();
    // iniciar_task_sd();
    // estado_atual = ESTADO_COM_BEBE;

    // Outros eventos relevantes para estado sem bebê
}

void handle_estado_com_bebe()
{
    // Parar tasks de peso/SD para economizar recursos
    // parar_task_peso();
    // parar_task_sd();
    // estado_atual = ESTADO_SEM_BEBE;
    // realizar_pesagem();
    // enviar_mqtt_se_conectado();
    // salvar_log_sd();
    // if (verificar_sd_cheio())
    // {
    //     compactar_logs_sd(); // Apaga metade dos logs
    // }
    // Outros eventos relevantes para estado com bebê
}

char *get_reset_reason_string(esp_reset_reason_t reason)
{
    switch (reason)
    {
    case ESP_RST_POWERON:
        return "Razão do último reset: Power-On Reset";
    case ESP_RST_SW:
        return "Razão do último reset: Software Reset (esp_restart)";
    case ESP_RST_PANIC:
        return "Razão do último reset: Panic/Crash Reset";
    case ESP_RST_INT_WDT:
        return "Razão do último reset: Interrupt Watchdog Reset";
    case ESP_RST_TASK_WDT:
        return "Razão do último reset: Task Watchdog Reset";
    case ESP_RST_WDT:
        return "Razão do último reset: Other Watchdog Reset";
    case ESP_RST_DEEPSLEEP:
        return "Razão do último reset: Deep Sleep Wakeup";
    case ESP_RST_BROWNOUT:
        return "Razão do último reset: Brownout Reset";
    case ESP_RST_SDIO:
        return "Razão do último reset: SDIO Reset";
    default:
        return "Razão do último reset: Unknown Reset Reason";
    }
}
