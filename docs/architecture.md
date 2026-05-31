# Decoupled System Architecture

This document describes the decoupled technical architecture of the **Store Intelligence System**.

```mermaid
graph TD
    subgraph Python Backend [Python Backend: FastAPI]
        CVEngine[cv_engine.py] -->|Simulates Shopper Trace Events| main.py[main.py WebSocket]
        Analytics[analytics.py] -->|Aggregates Store Metrics| main.py HTTP
        Anomalies[anomalies.py] -->|Detects Dwell/Queue Bottlenecks| main.py
    end

    subgraph Flutter Frontend [Flutter Frontend: MVC + Riverpod]
        main.py -->|WebSocket Live Stream| TelController[telemetry_provider.dart]
        main.py -->|HTTP GET Metrics| MetController[metrics_provider.dart]
        TelController & MetController -->|Reactive State Bindings| UIViews[Dashboard Views]
    end
```

---

## 1. Directory Structure

### `/backend`
- `cv_engine.py`: Dynamic CV coordinate pathing simulator for shoppers and live frame base64 JPEG renderer.
- `analytics.py`: Integrates customer tracking locations with POS checkout transaction logs.
- `anomalies.py`: Performs real-time anomaly analysis (bottleneck alert, queue length, staff attendance).
- `main.py`: FastAPI server setting up WebSocket streams and HTTP routes.
- `assertions.py`: Runs mathematical validations on coordinate-to-zone polygons intersection checks.
- `/backend/data`: Stores dataset dependencies like `store_layout.json` and `pos_transactions.csv`.

### `/frontend`
- `lib/models/`: Dart schemas defining store entities (`store_zone.dart`, `shopper.dart`, `alert.dart`, `transaction.dart`).
- `lib/controllers/`: Riverpod providers subscribing to WebSockets (`telemetry_provider.dart`) and REST polling heartbeats (`metrics_provider.dart`).
- `lib/views/`: Beautiful custom glassmorphic widgets and dashboard layout.
- `test/`: Verification smoke test configurations.

---

## 2. Decoupled Communication Protocols

1. **WebSocket Stream (`/ws/telemetry`)**: 
   - A single high-frequency connection pushing 10-12 packets per second containing active shopper listings, coordinates, alert feeds, and base64-encoded frame images.
2. **REST API Polling (`/api/metrics`)**:
   - A low-frequency heartbeat (every 3 seconds) retrieving transaction analytics charts, total revenue, zone conversions, and payment configurations.
