## Critical Test Checklist

### Connectivity

- BLE provisioning: provision from scratch and confirm Wi-Fi connects successfully.
- Wi-Fi drop during runtime: turn off AP for 5 minutes and turn it back on; verify reconnect or reprovisioning after the configured threshold.
- Broker offline: take the broker down while keeping Wi-Fi up; verify events/measurements go to outbox and are replayed when the broker returns.

### SD Card

- Blank card / missing folders: start with an empty card (no `/sdcard/scales`); verify the firmware creates the directory automatically.
- SD absent at boot: boot without SD; verify a critical MQTT event is emitted when the device is online.
- SD removed during runtime: remove SD during writes; verify a critical MQTT event is emitted.
- SD full (ENOSPC): fill the card and force writes; verify `SD_FULL` is emitted via MQTT.

Expected SD file paths (after first boot):

- `/sdcard/scales/state.txt`
- `/sdcard/scales/audit.log`
- `/sdcard/scales/commands.log`
- `/sdcard/scales/measurements.log`
- `/sdcard/scales/critical.log`
- `/sdcard/scales/outbox.log`
- `/sdcard/scales/baby.txt`

### Power

- Power loss during SD write: cut power while writing; reboot and verify `state.txt` is still writable and there is no deadlock.
- Power loss during publish: cut power while sending a measurement; reboot and verify outbox replay behavior.

### Timeline / audit

- Commands: send `[BAB]`, multiple `[TIM]`, `[RUN]`, `[MEA]`, `[WFS]`; confirm `/acks` MQTT and `commands.log` / `audit.log`.
- Scheduled measurements: configure a schedule and verify every trigger produces:
  - one entry in `measurements.log`
  - one publish in `/measurements/<service>`

### Limits / robustness

- Exceed `MAX_WEIGHT_TIMES`: send >10 `[TIM]` and confirm it is rejected without memory corruption.
- Command queue saturation: flood `/scales/<service>` and confirm the firmware does not lock up and logs a queue-full error.
