# Key Takeaways

- The backend is a Spring Boot API with 7 controllers, JWT-based method security, JPA persistence, Hibernate Envers auditing, and an MQTT bridge layer centered in `ScaleService`, `MqttPublisherService`, and `MqttSubscriberService`.
- All mapped API endpoints use `POST`, including reads and list operations, with route constants defined in `ApiConstants`.
- Security is enforced primarily by `@PreAuthorize`; HTTP security globally permits requests, then method-level rules decide access in `SecurityConfig`.
- The ESP32 firmware, documented in `PROJETO_RESUMO.md`, reads 4 HX711 sensors, provisions Wi-Fi over BLE, stores config/logs on SD, accepts MQTT control commands, and publishes measurement/status telemetry.
- The current Java backend supports command dispatch and direct `/weights/#` ingestion, but it does not currently subscribe to the firmware's `/status/<service>` channels, so online/offline and scheduled telemetry are not yet fully integrated.

# Backend Architecture

- **Controllers**: `BabyController`, `ScaleController`, `WeightController`, `AuditController`, `LoginController`, `ScaleDataController`, `UserController`.
- **Auth model**: `POST /login` creates JWTs with a `scope` claim derived from user roles in `LoginController`; token expiry is `3000` seconds.
- **Security behavior**: `@PreAuthorize("isAuthenticated()")` protects most app endpoints; `hasAuthority('SCOPE_ADMIN')` protects admin-only scale-data and user-list operations; `POST /login`, `POST /reset_password`, and `POST /users/new` are public because they have no method guard and `anyRequest().permitAll()` is enabled in `SecurityConfig`.
- **Persistence split**: app entities (`BabyModel`, `ScaleModel`, `WeightModel`) live in the application DB, while auth/device registry (`UserModel`, `RoleModel`, `ScaleDataModel`) live in the auth DB.
- **Auditing**: babies, scales, and weights are Envers-audited entities, queried through `AuditRepository`.

# API Endpoint Map

- **Baby APIs**: `BabyController` with business logic in `BabyService`.
- `POST /babies/list` | Auth: authenticated | Request: none | Response: `List<BabyResponse>` with `babyId`, `babyName`, `babyMotherName`, `babyBirthDate`, `babyState`, `babyWeightTime`, `babyHospitalId`, `babyImageText`, derived `babyImageQr`, `scaleId` | Logic: returns all babies.
- `POST /babies/search/{id}` | Auth: authenticated | Request: path `id` | Response: `BabyResponse` | Logic: loads one baby by numeric ID or returns `400`.
- `POST /babies/save` | Auth: authenticated | Request: `BabyRequest { babyId, babyName, babyMotherName, babyBirthDate, babyState, babyWeightTime, babyHospitalId, babyImageText }` | Response: `BabyResponse` | Logic: creates or updates via `new BabyModel(request)`.
- `POST /babies/enable/{id}` | Auth: authenticated | Request: path `id` | Response: `BabyResponse` | Logic: sets state to enabled only if the baby exists and has no assigned scale.
- `POST /babies/disable/{id}` | Auth: authenticated | Request: path `id` | Response: `BabyResponse` | Logic: sets state to disabled only if the baby has no assigned scale.
- `POST /babies/update/{id}` | Auth: authenticated | Request: path `id` plus `BabyRequest` | Response: `BabyResponse` | Logic: updates editable fields; if `babyWeightTime` changes and a scale is assigned, it pushes fresh MQTT schedule data to the scale.
- `POST /babies/image/{id}` | Auth: authenticated | Request: multipart form-data with `file` | Response: plain string `"Image Updated Successfully"` | Logic: stores the uploaded image as a SQL `Blob`.
- `POST /babies/qr/{id}` | Auth: authenticated | Request: path `id` | Response: PNG bytes or error JSON | Logic: returns the stored QR/image blob from the baby record.

- **Scale APIs**: `ScaleController` with business logic in `ScaleService`.
- `POST /scales/list` | Auth: authenticated | Request: none | Response: `List<ScaleResponse>` with `scaleId`, `scaleHash`, `scaleState`, `babyId` | Logic: returns all commercial/application scales.
- `POST /scales/search/{id}` | Auth: authenticated | Request: path `id` | Response: `ScaleResponse` or `404` | Logic: returns scale by numeric DB ID.
- `POST /scales/enable/{id}` | Auth: authenticated | Request: path `id` | Response: `ScaleResponse` | Logic: marks scale operant only if it exists and has no assigned baby.
- `POST /scales/disable/{id}` | Auth: authenticated | Request: path `id` | Response: `ScaleResponse` | Logic: marks scale non-operant only if it has no assigned baby.
- `POST /scales/hash/{hashId}` | Auth: authenticated | Request: UUID-like path `hashId` | Response: `ScaleResponse` or `404` | Logic: finds scale by `scaleHash`.
- `POST /scales/set/{id}` | Auth: authenticated | Request: UUID path `id` | Response: `ScaleResponse` | Logic: links a registered auth-side scale UUID into the app DB as a new scale record with `scaleHash = UUID` and initial state `0`.
- `POST /scales/baby/set` | Auth: authenticated | Request: `ScaleRequest { scaleId, babyId }` | Response: `ScaleResponse` | Logic: validates scale, baby, uniqueness, and operant state; assigns the baby; resolves MAC from auth registry; sends MQTT `[BAB]`, `[TIM]`, `[RUN]`.
- `POST /scales/baby/unset` | Auth: authenticated | Request: `ScaleRequest { scaleId, babyId }` | Response: `ScaleResponse` | Logic: clears assigned baby and sends MQTT `[CLE]`.
- `POST /scales/measure_now/{scaleId}` | Auth: authenticated | Request: path `scaleId` | Response: `WeightModel` | Logic: resolves MAC, sends MQTT `[MEA]`, blocks up to 5 seconds waiting for a `/weights/#` message to be persisted, then returns the latest saved weight.

- **Weight APIs**: `WeightController`.
- `POST /weight/list` | Auth: authenticated | Request: none | Response: raw `List<WeightModel>` | Logic: returns all persisted weights.
- `POST /weight/save` | Auth: authenticated | Request: `WeightRequest { scaleId, babyId, weightValue }` | Response: saved `WeightModel` | Logic: stamps `weightDate = now()` and persists.
- `POST /weight/babies/{babyId}` | Auth: authenticated | Request: path `babyId` | Response: raw `List<WeightModel>` | Logic: filters weights by baby ID.
- `POST /weight/scales/{scaleId}` | Auth: authenticated | Request: path `scaleId` | Response: raw `List<WeightModel>` | Logic: filters weights by scale ID.

- **Audit APIs**: `AuditController`.
- `POST /audit/babies/{babyId}` | Auth: authenticated | Request: path `babyId` | Response: `List<Object[]>` where each row is `[BabyResponse, revisionEntity, revisionType]` | Logic: returns Envers revision history for one baby.
- `POST /audit/scales/{scaleId}` | Auth: authenticated | Request: path `scaleId` | Response: `List<Object[]>` where each row is `[ScaleResponse, revisionEntity, revisionType]` | Logic: returns Envers revision history for one scale.
- `POST /audit/weights/{babyId}` | Auth: authenticated | Request: path `babyId` | Response: raw Envers `List<Object[]>` for weight revisions by `babyId` | Logic: returns weight history revisions without DTO conversion.

- **Authentication APIs**: `LoginController`.
- `POST /login` | Auth: public | Request: `LoginRequest { email, password }` | Response: `LoginResponse { accessToken, expiresIn, user }` | Logic: validates BCrypt password and issues JWT with `scope` claim from roles.
- `POST /reset_password` | Auth: public | Request: `LoginRequest { email, password }` | Response: empty `200 OK` | Logic: looks up user by email and replaces stored password hash.

- **Device Registry APIs**: `ScaleDataController` with business logic in `ScaleDataService`.
- `POST /scale_data/search/{id}` | Auth: authenticated | Request: UUID path `id` | Response: `ScaleDataResponse { scaleId, mac, pop }` | Logic: looks up registered device metadata.
- `POST /scale_data/qr/{id}` | Auth: authenticated | Request: UUID path `id` | Response: PNG bytes | Logic: generates a QR code image for the UUID.
- `POST /scale_data/list` | Auth: `SCOPE_ADMIN` | Request: none | Response: `List<ScaleDataResponse>` | Logic: lists all device registry records.
- `POST /scale_data/new` | Auth: `SCOPE_ADMIN` | Request: `ScaleDataRequest { id?, mac }` | Response: `ScaleDataResponse` | Logic: rejects duplicate MACs, generates a new random 8-char PoP, saves record.
- `POST /scale_data/update` | Auth: `SCOPE_ADMIN` | Request: `ScaleDataRequest { id, mac }` | Response: `ScaleDataResponse` | Logic: validates the record exists, rejects duplicate MACs, regenerates PoP, saves changes.

- **User APIs**: `UserController`.
- `POST /users/new` | Auth: public | Request: `UserRequest { email, password, organization }` | Response: empty `200 OK` | Logic: creates a user with BCrypt password and default `BASIC` role.
- `POST /users/list` | Auth: `SCOPE_ADMIN` | Request: none | Response: raw `List<UserModel>` with password suppressed by `@JsonIgnore` | Logic: returns all users.

# Response and Error Patterns

- Most controllers wrap service exceptions as `400` with `{ "error": "<message>" }`.
- `ScaleController.search/{id}` and some QR endpoints may return `404` or `400` rather than a consistent not-found contract.
- Some endpoints return DTOs, but `weight/*`, `users/list`, and `audit/weights/{babyId}` return raw entities/raw tuples instead of response models, so the API shape is not uniform.

# ESP32 Functionality

- The firmware reads 4 HX711 load-cell channels continuously and computes a global weight in grams every second, applying low/high threshold adjustments before storing `final_weight`.
- Wi-Fi is provisioned over BLE using ESP-IDF provisioning manager, `Security 1`, and a PoP; first boot or reprovisioning is BLE-driven, not MQTT-driven.
- Persistent data is stored on SD card, including logs in `/sdcard/logs.txt` and baby schedule state in `/sdcard/baby.txt`.
- Device runtime includes sensor tasks, SD logging tasks, MQTT task management, and a one-shot scheduler for timed measurements.
- MQTT commands supported by the firmware are `[BAB]`, `[TIM]`, `[RUN]`, `[CLE]`, `[MEA]`, `[CAL]`, and `[WIF]`.
- Immediate measurement publishes `[MEA];Peso{<gramas>}` to `/weights/<service>` and also sends an ACK `"1"`.
- Scheduled measurements publish `Peso{<gramas>}` to `/sensors/<service>`.
- Device availability is published on `/status/<service>` as `CONNECTED` and `DISCONNECTED` via LWT behavior.
- Firmware-side MQTT contract, payloads, and workflows are documented in `PROJETO_RESUMO.md`.

# Backend-to-ESP32 MQTT Integration

- The Java API publishes outbound commands to `/scales/<suffix>` through `MqttPublisherService` and subscribes to `/scales/#` and `/weights/#` through `MqttSubscriberService`.
- The backend's identity bridge is: app `ScaleModel.scaleHash` = auth `ScaleDataModel.scaleId` UUID; auth registry maps UUID to `mac`; MQTT topic suffix is then resolved from that stored `mac`.
- Scale-to-baby assignment and baby schedule updates are the main API flows that trigger device configuration: `[BAB]<babyId>`, one or more `[TIM]<HH:mm>`, then `[RUN]`.
- Unassignment triggers `[CLE]`.
- Immediate measurement triggers `[MEA]`, and the API waits synchronously until the subscriber persists a matching weight into the database.
- Incoming `/weights/#` messages are parsed in `SaveWeightFromScale()` by extracting the numeric value from `Peso{...}` and storing a `WeightModel`.

# Important Integration Observations

- The current backend does **not** subscribe to `/sensors/#`, so scheduled weights described in the firmware document are not currently ingested into the Java application.
- The current backend does **not** subscribe to `/status/#`, so device online/offline state is not exposed through the API today.
- The firmware document says topic suffixes are derived from `MQTT_SERVICE_NAME`, while the Java backend publishes to `/scales/<mac>` and expects `/weights/<mac>`; this is a potential identifier mismatch unless the deployed firmware's service name is intentionally the MAC-equivalent value.
- The firmware multiplexes ACKs (`"1"`/`"0"`) and real weight payloads on `/weights/<service>`, but `SaveWeightFromScale()` expects `Peso{...}` format; ACK messages will therefore log parsing errors instead of being handled as acknowledgements.
- The Java backend publishes API liveness to `api/status` in `MqttConfig`, but that is separate from device status handling.

# Combined Mental Model

- The backend manages users, babies, scale registry, scale assignment, and historical weights through HTTP.
- The auth-side `scale_data` records are the provisioning/identity registry for devices, carrying UUID, MAC, and generated PoP.
- The app-side `scales` table represents business-visible scales that can be enabled, assigned to babies, and measured.
- MQTT is the control plane between backend and ESP32: backend sends commands, ESP32 executes them, then publishes confirmations and measurements.
- The most complete end-to-end flow already implemented is: register device -> attach device into app scale table -> assign baby -> push baby/schedule over MQTT -> request measurement now -> persist returned weight.
- The two biggest current gaps relative to the firmware capabilities are scheduled telemetry ingestion and device status tracking.

# Optional Next Steps

- Turn this into an endpoint matrix in CSV or Markdown table form.
- Build a sequence diagram for HTTP <-> MQTT <-> ESP32.
- Produce a gap analysis of what must change in the Java backend to fully support all firmware features.
