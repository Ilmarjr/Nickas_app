# How to Run the Nickas Frontend

This is the mobile/frontend application for Nickas, built with Flutter.

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed and added to your PATH.
- Android Studio or VS Code with Flutter extensions.
- An emulator (Android/iOS) running, or a physical device connected.

## Setup

1. **Navigate to the frontend directory:**
   ```bash
   cd nickas_frontend
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

## Authentication
 
Currently, the app uses a simple username/password authentication (connected to the backend).
**Google Sign-In is currently on standby.**
 
### Default Credentials
To log in, use the pre-configured admin user:
- **Username:** `admin`
- **Password:** `admin`
 
## Backend Requirement
 
**Crucial:** The frontend requires the backend to be running to verify credentials.
1. Ensure `nickas_backend` is running at `http://127.0.0.1:8000`.
2. See `../nickas_backend/docs/RUNNING.md` for backend instructions.

## Running the App

To run the app in debug mode on your connected device or emulator:

```bash
flutter run
```

### Run Options

- **Target a specific device:**
  ```bash
  flutter run -d <device_id>
  ```
  (Use `flutter devices` to list available devices)

- **Run in release mode:**
  ```bash
  flutter run --release
  ```

## Troubleshooting

- If you encounter build issues, try cleaning the build artifacts:
  ```bash
  flutter clean
  flutter pub get
  ```
- Ensure you have the necessary platform requirements (Android SDK/Xcode) installed via `flutter doctor`.
