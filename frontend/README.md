# store_monitor

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Activate Project and Run

Follow these steps from the repository root `d:\pbcode\CCTV_Monitor`.

1. Open PowerShell in the workspace root.
2. Activate the Python `.venv`:
   ```powershell
   .\.venv\Scripts\Activate.ps1
   ```
3. Install backend dependencies if needed:
   ```powershell
   python -m pip install -r backend\requirements.txt
   ```
4. Start the FastAPI backend (from the repository root or the `/backend` folder):
   ```powershell
   cd backend
   python -m uvicorn main:app --reload --host 127.0.0.1 --port 8000
   ```
   - Swagger REST API Docs are active at `http://127.0.0.1:8000/docs`.
5. Open a new PowerShell terminal, then run the Flutter frontend:
   ```powershell
   cd d:\pbcode\CCTV_Monitor\frontend
   flutter pub get
   flutter test
   flutter devices
   flutter run -d windows
   ```
   If you want to run on a browser or another target, use:
   ```powershell
   flutter run -d chrome
   flutter run -d edge
   flutter run -d <device_id>
   ```

## Notes

- Ensure `.venv` is created in the repository root before activating it.
- Keep the backend running while the Flutter app connects to API and WebSocket endpoints.
- Run `flutter devices` to list available targets before using `flutter run -d <device_id>`.
- Use `flutter run -d windows` for the Windows desktop build, or `-d chrome` / `-d edge` for web.
