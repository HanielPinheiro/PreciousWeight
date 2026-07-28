# Precious Weight Architecture

## What This Document Covers

This file describes the current solution that is actually implemented in the Java backend and how it communicates with the scale over MQTT.

Only the active flow is documented here.
Topics and features that are not part of the current backend solution were intentionally removed.

## System Overview

The system has 3 main parts:

1. Flutter app
2. Java backend (`spring.security`)
3. ESP32 scale connected through MQTT

The backend is the bridge between HTTP and MQTT:

- Flutter calls HTTP endpoints
- The backend validates business rules and persists data
- The backend publishes MQTT commands to the scale
- The backend listens for MQTT responses and stores the returned data

## Databases

There are 2 logical databases in the solution:

### App DB

Stores business data used by the application:

- babies
- scales
- weights
- wifi_strengths

Relevant scale fields now used by the solution:

- `scale_id`
- `scale_hash`
- `scale_state`
- `is_connected`
- `scale_last_connected_at`
- `scale_last_disconnected_at`

### Auth DB

Stores authentication and device registry data:

- users
- roles
- scale_data

The `scale_data` record is the device registry entry used to connect the business scale to the physical device.

Important fields:

- `scale_id` (UUID)
- `mac`
- `pop`

## Scale Identity Mapping

The backend uses this mapping:

- app scale `scale_hash` = auth scale_data `scale_id`
- auth scale_data `mac` = MQTT topic suffix used by the backend

This means:

1. A device is first registered in `scale_data`
2. The same UUID is linked into the app `scales` table
3. When the backend needs to talk to the scale, it resolves:
   - app scale -> scale hash
   - scale hash -> auth scale UUID
   - auth scale UUID -> MAC
   - MAC -> MQTT topic suffix

## MQTT Contract Used By The Backend

The current backend uses these topics:

### Command Topic

- `/scales/<mac>`

Used by the backend to send commands to the scale.

Commands currently used:

- `[BAB]<babyId>`
- `[TIM]<HH:mm>`
- `[RUN]`
- `[CLE]`
- `[MEA]`
- `[WFS]`

### Weight Topic

- `/weights/<mac>`

Used by the scale to publish weight measurements.

Expected payload format:

- `Peso{<value>}`

The backend parses the numeric value and stores it in `weights`.

### Status Topic

- `/status/<mac>`

Used by the scale to publish connectivity events:

- `CONNECTED`
- `DISCONNECTED`

The backend updates the scale connection state and timestamps in the database.

### Wi-Fi Strength Response

The current solution expects the Wi-Fi strength response on:

- `/scales/<mac>`

Expected payload prefix:

- `[WFS]`

The backend extracts the integer value from the payload and stores it in `wifi_strengths`.

### Disabled Topic

The backend does not use `/sensors/#`.

This topic was intentionally removed from the documented solution.

## Active Backend Flow

### 1. Register device in auth registry

Admin creates a `scale_data` record with:

- UUID
- MAC
- generated PoP

The current PoP generation happens in:

- [ScaleDataService.java](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/Api_Java/spring.security/src/main/java/precious_weight/auth/services/ScaleDataService.java)

Current behavior:

- create: generates a PoP
- update: also regenerates the PoP

### 2. Link device into app scale table

The backend creates an app `scales` row using the auth UUID as `scale_hash`.

### 3. Assign baby to scale

When a baby is assigned, the backend sends:

1. `[BAB]<babyId>`
2. one or more `[TIM]<HH:mm>`
3. `[RUN]`

### 4. Unassign baby from scale

The backend sends:

- `[CLE]`

### 5. Measure weight now

The backend:

1. publishes `[MEA]` to `/scales/<mac>`
2. waits for a response in `/weights/<mac>`
3. persists the value in `weights`
4. returns the latest stored weight

### 6. Measure Wi-Fi strength now

The backend:

1. publishes `[WFS]` to `/scales/<mac>`
2. waits for a response in `/scales/<mac>`
3. extracts the integer signal value from the payload
4. persists it in `wifi_strengths`
5. returns the latest stored Wi-Fi strength

### 7. Track connection status

When the scale publishes to `/status/<mac>`:

- `CONNECTED`:
  - `is_connected = true`
  - `scale_last_connected_at = now`
- `DISCONNECTED`:
  - `is_connected = false`
  - `scale_last_disconnected_at = now`

## Relevant Endpoints

These are the most relevant endpoints for the current solution:

### Scale management

- `POST /scales/list`
- `POST /scales/search/{id}`
- `POST /scales/hash/{hashId}`
- `POST /scales/set/{id}`
- `POST /scales/enable/{id}`
- `POST /scales/disable/{id}`

### Baby-scale relation

- `POST /scales/baby/set`
- `POST /scales/baby/unset`

### Real-time operations

- `POST /scales/measure_now/{scaleId}`
- `POST /scales/wifi_strength/{scaleId}`
- `POST /scales/connection/{scaleId}`

### Device registry

- `POST /scale_data/list`
- `POST /scale_data/new`
- `POST /scale_data/update`
- `POST /scale_data/search/{id}`
- `POST /scale_data/qr/{id}`

## Files That Implement The Current Solution

Main backend files:

- [ScaleController.java](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/Api_Java/spring.security/src/main/java/precious_weight/controllers/app/ScaleController.java)
- [ScaleService.java](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/Api_Java/spring.security/src/main/java/precious_weight/app/services/ScaleService.java)
- [MqttSubscriberService.java](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/Api_Java/spring.security/src/main/java/precious_weight/auth/services/MqttSubscriberService.java)
- [MqttPublisherService.java](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/Api_Java/spring.security/src/main/java/precious_weight/auth/services/MqttPublisherService.java)
- [ScaleDataService.java](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/Api_Java/spring.security/src/main/java/precious_weight/auth/services/ScaleDataService.java)

Persistence for the recent solution changes:

- [WifiStrengthModel.java](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/Api_Java/spring.security/src/main/java/precious_weight/app/models/WifiStrengthModel.java)
- [ScaleModel.java](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/Api_Java/spring.security/src/main/java/precious_weight/app/models/ScaleModel.java)
- [RerunScripts.md](file:///e:/Academico/Mestrado/UNIFESP/LuizGalvao/PreciousWeight/Api_Java/md_files/RerunScripts.md)

## What Was Removed From The Documentation

The following items were intentionally removed because they do not describe the current backend solution:

- generic Spring Boot boilerplate docs
- old flow text not tied to the real implementation
- `/sensors/#` as part of the active API integration
- unnecessary firmware internals that do not change the backend contract
