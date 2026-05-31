# Purplle Store Intelligence System

AI-powered store monitoring dashboard with a FastAPI backend and a Flutter frontend. The system simulates CCTV-style shopper telemetry, correlates visitor movement with POS transactions, and presents live store health signals in a premium dark glassmorphic UI.

## Features

- Real-time shopper telemetry over WebSocket.
- Store layout, metrics, and alert APIs from FastAPI.
- Dwell-rate, conversion, and POS transaction analytics.
- Bottleneck and checkout queue anomaly detection.
- Flutter dashboard with Riverpod state controllers and responsive widgets.

## Repository Layout

```text
backend/                 FastAPI server, simulation engine, analytics, anomalies
backend/data/            Store layout and POS input data
frontend/                Flutter application
docs/                    Architecture, setup, and repository rules
agents.md                Agent handbook for contributors
```

## Quick Start

Start the backend:

```powershell
cd backend
python -m pip install -r requirements.txt
python assertions.py
python -m uvicorn main:app --reload --host 127.0.0.1 --port 8000
```

Start the Flutter frontend in a second terminal:

```powershell
cd frontend
flutter pub get
flutter test
flutter run -d windows
```

For web:

```powershell
flutter run -d chrome
```

## API Endpoints

- Swagger UI: `http://127.0.0.1:8000/docs`
- WebSocket telemetry: `ws://127.0.0.1:8000/ws/telemetry`
- Store layout: `http://127.0.0.1:8000/api/layout`
- Metrics summary: `http://127.0.0.1:8000/api/metrics`
- Active alerts: `http://127.0.0.1:8000/api/alerts`

## Documentation

- [Architecture](docs/architecture.md)
- [Runner instructions](docs/instructions.md)
- [Gating rules](docs/rules.md)

## Data Notes

`backend/data/sample_events.jsonl` is treated as a local generated trace file and is ignored by Git. Keep committed datasets limited to stable inputs such as `store_layout.json` and `pos_transactions.csv`.
