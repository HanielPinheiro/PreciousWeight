## Checklist de Testes Críticos

### Conectividade
- Provisionamento BLE: provisionar do zero e confirmar conexão Wi-Fi.
- Wi-Fi cai em runtime: desligar AP por 5 min e religar; verificar reconexão ou reprovisionamento conforme limite.
- Broker offline: derrubar broker e manter Wi-Fi; verificar que eventos/medidas entram no outbox e são reenviados ao voltar.

### Cartão SD
- SD ausente no boot: iniciar sem SD; verificar evento crítico via MQTT quando conectado.
- SD removido em runtime: remover SD durante escrita; verificar evento crítico via MQTT.
- SD cheio (ENOSPC): encher SD e forçar escrita; verificar evento `SD_FULL` via MQTT.

### Energia
- Queda de energia durante gravação: cortar energia durante escrita no SD; reiniciar e verificar integridade do `state.txt` e ausência de deadlock.
- Queda de energia durante publish: cortar energia ao enviar medida; reiniciar e verificar reenfileiramento/replay.

### Linha do tempo e auditoria
- Comandos: enviar sequência `[BAB]`, múltiplos `[TIM]`, `[RUN]`, `[MEA]`, `[WFS]`; confirmar `commands.log`, `audit.log` e `acks` em MQTT.
- Medidas agendadas: configurar agenda e verificar que cada disparo gera registro em `measurements.log` e publish em `/measurements`.

### Limites e robustez
- Exceder `MAX_WEIGHT_TIMES`: enviar >10 comandos `[TIM]` e confirmar bloqueio sem corrupção.
- Saturação de fila de comandos: flood em `/scales/<service>` e confirmar que o firmware não trava e registra erro de fila.
