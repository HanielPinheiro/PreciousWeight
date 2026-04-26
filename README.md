# Precious Weight (Flutter App)

Precious Weight is a Flutter mobile application designed to support **real-time monitoring of newborn/baby weight** using **network-connected baby scales**. The app covers the full operational flow used in a clinical environment:

- Authenticate hospital staff
- Register and manage babies (patients)
- Register and manage scales (devices)
- Associate a baby ↔ scale (one-to-one association)
- Visualize weight history and trends (charts)
- View audit logs (who changed what and when)
- Provision a scale onto a Wi‑Fi network using **BLE (Bluetooth Low Energy)**, driven by a QR code workflow

This repository contains only the Flutter app. It assumes the existence of a backend API that stores babies/scales/weights/logs and provides scale provisioning data.

---

## Quick Start

### Prerequisites

- Flutter SDK compatible with Dart `^3.5.0` (see [pubspec.yaml](pubspec.yaml))
- Android Studio / Xcode (depending on the target platform)
- A running backend API (base URL configured in [constants.dart](lib/repository/helper/constants.dart))
- (For scale provisioning) A compatible BLE provisionable scale firmware/device

### Run

```bash
flutter pub get
flutter run
```

---

## Project Structure (How the code is organized)

The app uses a straightforward structure that separates UI, state, and infrastructure:

- [lib/main.dart](lib/main.dart)  
  App entry point. Registers Providers and defines the `MaterialApp` theme and initial route (Login).

- `lib/views/`  
  Screens and UI flows (Login, Home, Babies, Scales, Logs).

- `lib/repository/providers/`  
  State management using `provider` (`ChangeNotifier`) for babies and scales.

- `lib/api/`  
  API clients for each backend resource (users, babies, scales, weights, audit logs).

- `lib/models/`  
  Data models (`BabyModel`, `ScaleModel`, `WeightModel`, `LogModel`) and JSON mapping.

- `lib/repository/services/`  
  Infrastructure services:
  - `api_service.dart`: HTTP wrapper and safe API execution
  - `qrcode_service.dart`: QR scanner screen (MobileScanner)
  - `bluefi_service.dart`: BLE-based provisioning UI flow (ESP BLE provisioning)

- `lib/repository/design/` and `lib/repository/widgets/`  
  Reusable UI styles, theme, and widget helpers.

---

## Architecture Overview

### State management

This project uses the `provider` package:

- [BabyProvider](lib/repository/providers/baby_provider.dart) manages:
  - loading babies from the backend
  - caching babies in memory
  - adding/updating babies
  - enabling/disabling babies
  - managing QR code upload/display

- [ScalesProvider](lib/repository/providers/scales_provider.dart) manages:
  - loading scales from the backend
  - caching scale list in memory
  - adding new scales based on a scanned hash
  - enabling/disabling scales
  - associating/unassociating baby ↔ scale
  - retrieving provisioning data (`mac`, `pop`) for BLE onboarding

Providers are injected in [main.dart](lib/main.dart) using `MultiProvider`.

### Networking & error handling

- [ApiService](lib/repository/services/api_service.dart) wraps HTTP `POST` calls, decodes UTF-8 body bytes, and throws a structured `ApiException` when status codes are not 2xx.
- [SafeApi.call](lib/repository/services/api_service.dart#L87-L98) is used by screens/providers to:
  - centralize error handling
  - show UI dialogs
  - handle expired sessions
- [ApiErrorHandler](lib/repository/helper/api_error_handler.dart) detects 401-like errors and forces logout + redirect to Login.

### Authentication model

- Authentication is performed via [UserApi](lib/api/user_api.dart).
- The token is kept in memory inside a Singleton `UserApi()` instance.
- All authenticated endpoints attach `Authorization: Bearer <accessToken>`.

Important implication:

- If the app is killed, the user must log in again (no token persistence in secure storage in this codebase).

---

## Domain Concepts (What the app manages)

### Baby (Patient)

Represented by [BabyModel](lib/models/baby.dart), with key fields:

- Hospital register/ID (`hospitalRegister`)
- Name, mother name, birth date
- Active status (admitted vs discharged)
- QR identity (either `qrCodeText` from scanning OR `qrCodeImage` captured as a photo)
- Optional association to a scale (`scaleId`, `assignedScale`)
- Weight schedule (“Horário(s) da(s) coleta(s) do peso”)

### Scale (Device)

Represented by [ScaleModel](lib/models/scales.dart):

- Numeric ID (`id`) from backend
- Hash (`hash`) used as the QR identity
- Operational status (`status` = 1 active / 0 inactive)
- Optional baby association (`babyId` and `assignedBaby`)
- Provisioning info fetched from backend (`mac`, `pop`)

### Weight (Measurement)

Represented by [WeightModel](lib/models/weight.dart):

- Date/time (converted from UTC string to local time)
- Weight value (grams)
- References to baby ID and scale ID

Weights are fetched through [WeightApi](lib/api/weight_api.dart) and visualized in:

- Baby details screen via [BabyWeightChart](lib/repository/widgets/baby_weight_chart.dart) when there is enough data

### Audit Logs

Represented by [LogModel](lib/models/logs.dart). The backend returns an array-like structure per entry:

- `entity`: snapshot of the entity at that revision
- `revisionInfo`: revision metadata (id, date, username)
- `action`: `ADD`, `MOD`, `DEL`

The app can show audit history for:

- Babies
- Scales
- Weights

---

## Main User Flows (What happens in the app)

### 1) Login / Logout

- Start screen: [LoginPage](lib/views/login/login.dart)
- On successful login, user is redirected to [MenuManager](lib/repository/widgets/menu.dart)
- Logout clears the singleton user object in `UserApi` and returns to Login.

### 2) Home (Scanning hub)

Screen: [HomePage](lib/views/home/home.dart)

Buttons:

1. “Escanear Bebês”
   - Choose between:
     - scanning a QR code (camera)
     - taking a photo (camera) of the QR label
   - Redirects to baby registration ([BabiesRegister](lib/views/babies/babies_register.dart)) with the captured text/image

2. “Escanear Balança”
   - Scan QR code and open BLE provisioning screen ([BluefiService](lib/repository/services/bluefi_service.dart))

3. “Trocar de Balança”
   - Marked as not implemented in the current codebase

### 3) Babies module

Screens in `lib/views/babies/`:

- List: [BabiesPage](lib/views/babies/babies.dart)
  - Toggle between active/inactive babies
  - Shows last known weight when available

- Details: [BabiesDetails](lib/views/babies/babies_details.dart)
  - View baby demographics
  - View QR identity
  - View weight trend chart or latest weight
  - Associate/unassociate a scale (through ScalesProvider)

- Register: [BabiesRegister](lib/views/babies/babies_register.dart)
  - Creates a new baby in backend
  - If QR was provided as image (not text), uploads it as a PNG

### 4) Scales module

Screens in `lib/views/scales/`:

- List: [ScalesPage](lib/views/scales/scales.dart)
  - Toggle between active and inactive scales
  - Can add a new scale by scanning the QR (opens provisioning)

- Details: [ScaleDetails](lib/views/scales/scales_details.dart)
  - Enable/disable scale
  - Associate/unassociate a baby
  - Shows scale hash and operational status

### 5) Logs module (audit)

- Entry screen: [LogsPage](lib/views/logs/logs.dart)
- The user can open logs for babies/scales/weights.

---

## BLE + Wi‑Fi Provisioning (Scale onboarding)

Provisioning is implemented in [bluefi_service.dart](lib/repository/services/bluefi_service.dart) and is triggered after scanning a scale QR code (the QR contains a `hash`).

### Step-by-step flow

1. User scans a scale QR code (hash).
2. The app calls the backend to retrieve provisioning data for this hash:
   - `mac` (used by the backend/device identification)
   - `pop` (“Proof of Possession”) used by ESP provisioning
3. The app requests required permissions (Android 12+ Bluetooth runtime permissions + location; iOS Bluetooth + location when required).
4. The app checks Bluetooth state and waits for it to be enabled.
5. The app scans BLE devices using a prefix:
   - Prefix is currently hard-coded as `PW_` inside the provisioning flow.
6. The user provides Wi‑Fi SSID + password.
7. The app sends the Wi‑Fi credentials over BLE using `flutter_esp_ble_prov`:
   - `provisionWifi(deviceName, pop, ssid, password)`
8. If provisioning succeeds:
   - The app registers the scale in the backend if it does not exist yet (`setNewScale(hash)`).

### Bluetooth state (native integration)

The provisioning screen uses a small native integration to check and listen to Bluetooth state changes:

- Dart: `MethodChannel('bluetooth_helper')` + `EventChannel('bluetooth_helper_state')`
  - see [bluefi_service.dart](lib/repository/services/bluefi_service.dart)
- Android implementation: [MainActivity.kt](android/app/src/main/kotlin/com/example/untitled/MainActivity.kt)
- iOS implementation: [AppDelegate.swift](ios/Runner/AppDelegate.swift)

---

## QR Code Scanning

QR reading is implemented via `mobile_scanner` in:

- [ScanQrCode](lib/repository/services/qrcode_service.dart)

The scanner returns:

- `text`: barcode raw value
- `image`: captured frame image (when `returnImage: true`)

This output is used in two contexts:

- Baby registration: QR identity can be saved either as scanned text or image
- Scale onboarding: QR text is treated as a scale hash

---

## Backend API Configuration

### Base URL

The backend URL is configured in:

- [constants.dart](lib/repository/helper/constants.dart#L26-L29)

Example currently present in the code:

- `address_api = "http://100.96.1.34:8080"`

Note for Android emulator:

- `localhost` from the emulator is not your machine. The file already documents that the correct alias is usually `10.0.2.2`.

### Endpoints used

The app uses endpoints for:

- Auth: `/login`, `/reset_password`, `/users/new`, `/users/list`
- Babies: list/search/save/update/enable/disable, QR image fetch/upload
- Scales: list/search/set/enable/disable, link/unlink baby
- Weights: list by baby/scale
- Audit logs: `/audit/*`

All endpoint path constants are in [constants.dart](lib/repository/helper/constants.dart).

---

## Platform Permissions

### Android

Android permissions and BLE feature requirement are declared in:

- [AndroidManifest.xml](android/app/src/main/AndroidManifest.xml)

Highlights:

- Bluetooth LE feature required (`android.hardware.bluetooth_le`)
- Bluetooth permissions for Android 12+ (`BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`, `BLUETOOTH_ADVERTISE`)
- Location permissions (used historically for BLE scanning on older Android versions)
- Internet/network permissions

Runtime permissions are requested by the provisioning UI.

### iOS

iOS permission usage strings are configured in:

- [Info.plist](ios/Runner/Info.plist)

Includes:

- Camera (QR scanning)
- Photos (QR from photo library)
- Bluetooth usage
- Location usage (when needed)

---

## UI and Theming

The app has a custom theme and reusable UI elements:

- Theme: [theme.dart](lib/repository/design/theme.dart)
- Fonts: [fonts.dart](lib/repository/design/fonts.dart)
- Common widgets/dialogs: [elements.dart](lib/repository/widgets/elements.dart)

Most UI labels are currently written in Portuguese (with a few English constants also present).

---

## Troubleshooting

### “Login Expirado” / repeated redirects to login

- The backend returned an HTTP 401 (or an error containing “401”).
- The app will force logout and return to Login (see [ApiErrorHandler](lib/repository/helper/api_error_handler.dart)).

### QR code scan does not read anything

- Check camera permission
- Ensure the QR is in focus and well lit
- If using baby registration, you can capture a photo instead of scanning text

### BLE provisioning cannot find the device

- Ensure Bluetooth is enabled
- Ensure runtime permissions were granted
- Ensure the device advertises with the expected prefix (`PW_`)
- Ensure the backend returns valid provisioning data (`pop`) for the scanned hash

### Backend unreachable / timeouts

- Validate `address_api` in [constants.dart](lib/repository/helper/constants.dart)
- Ensure the device and the API server are reachable on the same network
- Check firewall rules and that the server listens on the configured port

---

## Security Notes (Current state)

This README documents what the code currently does; it does not claim full healthcare-grade security:

- Access tokens are stored in memory only (not in secure storage).
- API base URL is plain HTTP in constants (no TLS), which is not suitable for sensitive environments.
- No certificate pinning is implemented.

If this app is intended to handle patient data in production environments, a security review and hardening workstream is recommended.

---

## License

See [LICENSE](LICENSE).
