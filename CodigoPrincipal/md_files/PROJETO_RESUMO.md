# PreciousWeight (ESP32) — Current Architecture

This is the single source of truth for the current firmware architecture in this repository. It reflects the implementation that is on the branch now, including MQTT audit channels, SD-backed persistence, offline replay, Wi-Fi reprovisioning, and scheduled/manual measurements.

## 1. Purpose

`PreciousWeight` is an ESP32 firmware for a neonatal ICU scale with:

- 4 HX711 load cells
- continuous weight aggregation
- Wi-Fi provisioning over BLE
- MQTT command/control and telemetry
- SD card persistence for local audit and recovery

The design goal is not only to measure weight, but to preserve operational history locally and synchronize relevant events to backend systems.

## 2. Main Modules

- `main/main.c`
  Boot orchestration.
- `comm/wifi_prov_ble/wifi_prov_ble.c`
  Wi-Fi station mode, BLE provisioning, NTP sync, reprovisioning fallback.
- `comm/mqtt_config/mqtt3.c`
  MQTT client lifecycle, publish locking, reconnect-safe stop/restart.
- `tasks/mqtt_task/mqtt_task.c`
  MQTT manager task, command worker, outbox replay worker.
- `mqtt_events/parser/process_mqtt_data.c`
  Command parsing, ACK generation, routine persistence, immediate measurement handling.
- `mqtt_events/scheduler/weight_timer_scheduler.c`
  Next scheduled measurement computation and scheduled publish flow.
- `tasks/sensors_task/sensors_task.c`
  Sensor sampling and global weight calculation.
- `drivers/sdcard/sdcard.c`
  Raw SD file handling and legacy log writing.
- `drivers/sdcard_persistence/sdcard_persistence.c`
  Structured state, audit logs, measurement logs, outbox, sequence IDs, file rotation.

## 3. Boot Flow

Current boot order in `app_main()`:

1. Start LED task.
2. Mount and validate SD card.
3. Initialize Wi-Fi and provisioning logic.
4. Sync time with SNTP.
5. Initialize SD persistence layer.
6. Persist boot metadata:
   - reset reason
   - boot epoch
   - first audit event
7. Start MQTT task stack.
8. Initialize HX711 sensors.
9. Start SD writer task and sensor tasks.
10. Start scheduled measurement timer.
11. Save current state snapshot.

## 4. Connectivity Model

### Wi-Fi

- The device boots in STA mode if already provisioned.
- If it does not obtain an IP within the configured wait window, it calls `reset_wifi()` and reboots.
- If repeated runtime disconnections reach the configured threshold, it also resets Wi-Fi and reboots.

### BLE Provisioning

- Uses ESP-IDF Wi-Fi Provisioning Manager over BLE.
- Provisioning security: `WIFI_PROV_SECURITY_1`
- Uses:
  - `WIFI_DEVICE_NAME`
  - `MQTT_POP`
  - custom BLE service UUID

### MQTT

- Broker: `mqtts://mqtt.velarsoluti.vps-kinghost.net:8883`
- TLS client certificate, key, and CA are configured in the active MQTT client config.
- The firmware subscribes only to its command topic and publishes status, events, measurements, ACKs, and legacy compatibility payloads.

## 5. MQTT Contract

All topics are device-scoped by `MQTT_SERVICE_NAME`.

### Incoming

- `/scales/<service>`
  Command channel.

### Outgoing

- `/status/<service>`
  Connection state, including LWT.
- `/events/<service>`
  Operational and critical events.
- `/measurements/<service>`
  Structured weight telemetry.
- `/acks/<service>`
  Structured command acknowledgements.
- `/weights/<service>`
  Legacy compatibility channel still used for `"1"`, `"0"`, `[MEA]{...}`, `[WFS]{...}`, and some legacy errors.

## 6. Supported Commands

Commands are sent as payloads to `/scales/<service>`.

| Command | Example        | Effect                                              |
| ------- | -------------- | --------------------------------------------------- |
| `[BAB]` | `[BAB]BEBE001` | Defines active baby ID and clears previous routine  |
| `[TIM]` | `[TIM]08:00`   | Adds one schedule time                              |
| `[RUN]` | `[RUN]`        | Persists current routine and arms scheduler         |
| `[CLE]` | `[CLE]`        | Clears baby and schedule state                      |
| `[MEA]` | `[MEA]`        | Publishes a manual measurement                      |
| `[WFS]` | `[WFS]`        | Publishes current Wi-Fi RSSI                        |
| `[CAL]` | `[CAL]...`     | Stub only, returns success but does not recalibrate |
| `[WIF]` | `[WIF]`        | Stops MQTT, resets Wi-Fi, and reboots               |

## 7. Message Formats

### ACK channel

Published to `/acks/<service>`:

```text
ACK|<seq>|<epoch>|<command>|OK
ACK|<seq>|<epoch>|<command>|ERR
ACK|<seq>|<epoch>|<command>|ERR|MAX_WEIGHT_TIMES
```

### Measurement channel

Published to `/measurements/<service>`:

```text
MEA|<seq>|<epoch>|manual|<weight>
MEA|<seq>|<epoch>|scheduled|<weight>
```

### Event channel

Published to `/events/<service>`:

```text
EVT|<seq>|<epoch>|<severity>|<event_type>|...
```

Current examples include:

- `MQTT_CONNECTED`
- `MQTT_DISCONNECTED`
- `MQTT_ERROR`
- `MQTT_COMMAND_RX`
- `WIFI_RSSI`
- `SD_FAIL`
- `SD_FULL`
- `SENSOR_INIT_FAIL`
- `SENSOR_NO_VALID_READING`

## 8. Weight Processing

Sensor model:

- 4 HX711 channels
- one reader flow per sensor
- one aggregation flow for `global_weight`

The firmware keeps a continuously updated global weight in memory and uses it for:

- immediate measurement on `[MEA]`
- scheduled measurement on the timer worker

## 9. Scheduling Model

The scheduler:

- stores up to `MAX_WEIGHT_TIMES`
- computes the next closest future schedule
- arms a one-shot timer
- on trigger:
  - reads current global weight
  - writes a structured measurement log
  - publishes to `/measurements/<service>`
  - publishes legacy payload to `/weights/<service>`
  - reschedules the next measurement

## 10. SD Card Persistence Model

The firmware now uses the SD card for both legacy logs and structured persistence.

### Files

- `/sdcard/logs.txt`
  Legacy operational log queue output.
- `/sdcard/baby.txt`
  Persisted current routine snapshot for baby and schedule.
- `/sdcard/state.txt`
  Current device state snapshot.
- `/sdcard/audit.log`
  Structured event log.
- `/sdcard/commands.log`
  Structured command receipt log.
- `/sdcard/measurements.log`
  Structured measurement log.
- `/sdcard/critical.log`
  Critical-only structured events.
- `/sdcard/outbox.log`
  Pending and sent MQTT messages for offline replay.

### State snapshot

`state.txt` stores:

- `boot_epoch`
- `reset_reason`
- `baby_id`
- each persisted `weight_time`

### Outbox

If MQTT publish fails for supported structured channels, the firmware appends a pending record to `outbox.log`. A dedicated MQTT outbox worker periodically reloads pending records and retries publication. When successful, it appends a sent marker.

### Rotation

Structured files rotate automatically when they exceed configured size thresholds in `sdcard_persistence.c`.

## 11. Observability and Audit

The current architecture has three observability layers:

1. **Serial log**
   Developer/runtime inspection.
2. **Legacy SD log**
   Human-readable operational trace in `logs.txt`.
3. **Structured SD + MQTT audit**
   Sequence-based records for commands, measurements, events, and offline replay.

This means the backend can observe:

- online/offline status
- command receipt and result
- measurement origin (`manual` vs `scheduled`)
- critical failures such as SD degradation

## 12. Reliability Behavior

Implemented safeguards in the current branch:

- bounded retries instead of infinite loops in key MQTT response flows
- mutex-protected MQTT lifecycle
- queued command processing outside MQTT callback
- offline message spooling for structured topics
- periodic replay of pending outbox items
- SD failure escalation via MQTT event
- schedule limit enforcement for `MAX_WEIGHT_TIMES`
- atomic overwrite pattern for state-like files

## 13. Known Limitations

These are still true in the current solution:

- `[CAL]` is still not implemented.
- `/weights/<service>` remains as a legacy mixed channel for backward compatibility.
- Device identity is still compile-time fixed by `MQTT_SERVICE_NAME` and `WIFI_DEVICE_NAME`.
- The app/API must consume `/acks`, `/events`, and `/measurements` to use the full architecture; consuming only `/weights` is no longer sufficient.

## 14. Minimal Integration Guidance

To integrate correctly, the API/app should:

1. Publish commands to `/scales/<service>`.
2. Subscribe to:
   - `/status/<service>`
   - `/acks/<service>`
   - `/events/<service>`
   - `/measurements/<service>`
3. Keep `/weights/<service>` only if backward compatibility is still required.
4. Treat the SD card as the local source of audit continuity, not just a debug log sink.

## 15. Related Documentation

- `TESTES_CRITICOS.md`
  Validation checklist for fault injection, connectivity loss, SD failure, power loss, and schedule integrity.
