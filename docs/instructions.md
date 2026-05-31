# Quick Start & Runner Instructions

Follow these step-by-step instructions to install dependencies, run tests, and spin up both the FastAPI backend and Flutter frontend.

---

## 1. Setup Python Backend
1. Open a terminal in the `/backend` directory:
   ```powershell
   cd d:\pbcode\CCTV_Monitor\backend
   ```
2. Install Python dependencies using the unified requirements list:
   ```powershell
   pip install -r requirements.txt
   ```
3. Run the validation assertion scripts to test coordinate point logic:
   ```powershell
   python assertions.py
   ```
4. Start the FastAPI server using the active Python interpreter module to prevent environment misalignment:
   ```powershell
   python -m uvicorn main:app --reload --host 127.0.0.1 --port 8000
   ```
   - Swagger REST API Docs are active at `http://127.0.0.1:8000/docs`.

---

## 2. Setup Flutter Frontend
1. Open a new terminal in the `/frontend` directory:
   ```powershell
   cd d:\pbcode\CCTV_Monitor\frontend
   ```
2. Fetch required package libraries:
   ```powershell
   flutter pub get
   ```
3. Verify widget compilations by running the test suite:
   ```powershell
   flutter test
   ```
4. Start the desktop or web application:
   - For Windows Native Desktop:
     ```powershell
     flutter run -d windows
     ```
   - For Web Browser (Chrome/Edge):
     ```powershell
     flutter run -d chrome
     ```

---

## 3. Operational Troubleshooting

### NumPy 2.x & Pandas Compatibility Crash (`_ARRAY_API not found`)
- **NumPy 2.x Incompatibility**: Installing latest dependencies on Python 3.9+ may automatically fetch NumPy 2.x. This causes a fatal crash with existing precompiled packages like `pandas` or `pyarrow` built for NumPy 1.x, showing `AttributeError: _ARRAY_API not found` or `ImportError: numpy.core.multiarray failed to import`.
- **Solution**: Restrict both package installs to mutually compatible NumPy 1.x bounds:
  ```powershell
  pip install "numpy<2" "opencv-python<4.10.0"
  ```
  Note: This is already pre-configured in `backend/requirements.txt`.

### CCTV Feed Offline / Signal Loss
- **Missing OpenCV**: Make sure `opencv-python` (`cv2`) is installed in the exact Python environment running your FastAPI uvicorn server. If uvicorn starts but warns of missing libraries, CCTV frame rendering falls back to returning empty base64 strings.
- **Python Environment Mismatch**: If you have multiple Python interpreters (e.g. Anaconda and global Python), always install dependencies and run uvicorn using the identical interpreter:
  ```powershell
  python -m pip install -r requirements.txt
  python -m uvicorn main:app --reload --host 127.0.0.1 --port 8000
  ```

### WebSocket Upgrade Failure (404)
- **Missing WebSocket Support**: Standard uvicorn requires standard packages like `websockets` or `wsproto` to support connections. Ensure `websockets` is installed (listed in `requirements.txt`).
- **Connection Refused**: Confirm the backend FastAPI uvicorn server is running on port `8000`. The Flutter app will auto-reconnect every 3 seconds.
- **Port Conflict**: If port `8000` is already in use, run the backend on an alternate port and update `wsUrl` in `telemetry_provider.dart` and `baseApiUrl` in `metrics_provider.dart`.


