import asyncio
import json
import base64
import os
from typing import List
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from cv_engine import CCTVEngine
from analytics import StoreAnalytics
from anomalies import AnomalyDetector

app = FastAPI(title="Purplle Store Intelligence API", version="1.0")

# Enable CORS for Flutter web / desktop connections
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Core Pipeline instances
cctv_engine = CCTVEngine()
store_analytics = StoreAnalytics()
anomaly_detector = AnomalyDetector()

# WebSocket Connection Manager
class ConnectionManager:
    def __init__(self):
        self.active_connections: List[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        self.active_connections.remove(websocket)

    async def broadcast(self, message: str):
        for connection in self.active_connections:
            try:
                await connection.send_text(message)
            except Exception:
                # Connection might have dropped
                pass

manager = ConnectionManager()

# Background task to continuously run CV Engine simulation & broadcast telemetry
async def cctv_pipeline_loop():
    print("Starting Store Intelligence Pipeline Loop...")
    while True:
        # Step CV / Shopper simulation
        events = cctv_engine.step()
        
        # Record events to analytics
        for event in events:
            store_analytics.record_event(event)
            # Write events to sample_events.jsonl to maintain logs
            try:
                with open("data/sample_events.jsonl", "a") as f:
                    f.write(json.dumps(event) + "\n")
            except Exception:
                pass
                
        # Evaluate state anomalies
        active_alerts, alert_history = anomaly_detector.evaluate_store_state(
            cctv_engine.shoppers, cctv_engine.zones
        )
        
        # Render simulated CCTV frame
        jpeg_bytes = cctv_engine.render_frame()
        base64_frame = ""
        if jpeg_bytes:
            base64_frame = base64.b64encode(jpeg_bytes).decode('utf-8')
            
        # Build telemetry state payload
        shoppers_data = []
        for s in cctv_engine.shoppers:
            shoppers_data.append({
                "id": s.id,
                "x": int(s.x),
                "y": int(s.y),
                "zone_id": s.current_zone,
                "state": s.state,
                "speed": round(s.speed, 2)
            })
            
        payload = {
            "timestamp": AnomalyDetector().billing_empty_since or "",
            "active_shoppers_count": len(cctv_engine.shoppers),
            "queue_count": len([s for s in cctv_engine.shoppers if s.state == "queue"]),
            "billing_active": len([s for s in cctv_engine.shoppers if s.current_zone == "zone_billing"]) > 0,
            "shoppers": shoppers_data,
            "alerts": active_alerts,
            "frame": base64_frame
        }
        
        # Broadcast to all connected clients
        await manager.broadcast(json.dumps(payload))
        
        # Simulating ~10 frames per second
        await asyncio.sleep(0.12)

# Start CV loop on startup
@app.on_event("startup")
async def startup_event():
    asyncio.create_task(cctv_pipeline_loop())

@app.get("/")
def read_root():
    return {"message": "Purplle Store Intelligence Backend is running!"}

@app.get("/api/layout")
def get_layout():
    return cctv_engine.layout

@app.get("/api/metrics")
def get_metrics():
    return store_analytics.get_metrics_summary()

@app.get("/api/alerts")
def get_alerts():
    return {
        "active_alerts": anomaly_detector.active_alerts,
        "alert_history": anomaly_detector.alert_history
    }

# Web socket endpoint
@app.websocket("/ws/telemetry")
async def websocket_endpoint(websocket: WebSocket):
    await manager.connect(websocket)
    try:
        while True:
            # Keep connection open, client can send control signals if needed
            data = await websocket.receive_text()
            # Handle client control inputs (e.g. acknowledge an alert)
            try:
                msg = json.loads(data)
                if msg.get("action") == "acknowledge_alert":
                    alert_id = msg.get("alert_id")
                    for a in anomaly_detector.active_alerts:
                        if a["id"] == alert_id:
                            a["status"] = "acknowledged"
            except Exception:
                pass
    except WebSocketDisconnect:
        manager.disconnect(websocket)
