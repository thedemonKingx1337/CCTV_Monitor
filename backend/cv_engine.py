import json
import random
import time
import math
import os
from datetime import datetime

try:
    import cv2
    import numpy as np
    HAS_OPENCV = True
except ImportError:
    HAS_OPENCV = False

class Shopper:
    def __init__(self, shopper_id, zones, width=640, height=480):
        self.id = shopper_id
        self.width = width
        self.height = height
        
        # Start at entry/exit boundary
        self.x = random.choice([0, width])
        self.y = random.choice([height - 50, height - 10])
        
        self.zones = [z for z in zones if z["id"] != "zone_billing"] # Can't go directly to billing
        self.current_zone = "none"
        self.state = "browse" # browse, queue, checkout, exit
        
        # Choose a target zone
        self.target_zone = random.choice(self.zones)
        self.target_x, self.target_y = self._get_random_point_in_zone(self.target_zone)
        
        self.dwell_time = random.uniform(5.0, 15.0)
        self.dwell_started = None
        self.speed = random.uniform(2.5, 5.0)
        self.color = (random.randint(100, 255), random.randint(100, 255), random.randint(100, 255))
        self.path = []

    def _get_random_point_in_zone(self, zone):
        poly = zone["polygon"]
        x_coords = [p[0] for p in poly]
        y_coords = [p[1] for p in poly]
        min_x, max_x = min(x_coords), max(x_coords)
        min_y, max_y = min(y_coords), max(y_coords)
        # Margin
        margin = 10
        return random.randint(min_x + margin, max_x - margin), random.randint(min_y + margin, max_y - margin)

    def update(self, billing_zone, queue_zone):
        self.path.append((int(self.x), int(self.y)))
        if len(self.path) > 15:
            self.path.pop(0)
            
        if self.state == "browse":
            # Move towards target point
            dx = self.target_x - self.x
            dy = self.target_y - self.y
            dist = math.hypot(dx, dy)
            
            if dist > 5:
                # Normalise and move
                self.x += (dx / dist) * self.speed
                self.y += (dy / dist) * self.speed
            else:
                # Arrived at destination zone, begin dwell
                if self.dwell_started is None:
                    self.dwell_started = time.time()
                elif time.time() - self.dwell_started >= self.dwell_time:
                    # Dwell finished. Now either go to queue/billing or exit
                    self.dwell_started = None
                    if random.random() < 0.7:  # 70% buy something
                        self.state = "queue"
                        self.target_zone = queue_zone
                        self.target_x, self.target_y = self._get_random_point_in_zone(queue_zone)
                    else:
                        self.state = "exit"
                        self.target_x = random.choice([0, self.width])
                        self.target_y = self.height - 20
        
        elif self.state == "queue":
            dx = self.target_x - self.x
            dy = self.target_y - self.y
            dist = math.hypot(dx, dy)
            if dist > 5:
                self.x += (dx / dist) * self.speed
                self.y += (dy / dist) * self.speed
            else:
                # Dwell in queue, then move to billing
                if self.dwell_started is None:
                    self.dwell_started = time.time()
                    self.dwell_time = random.uniform(3.0, 8.0)
                elif time.time() - self.dwell_started >= self.dwell_time:
                    self.dwell_started = None
                    self.state = "checkout"
                    self.target_zone = billing_zone
                    self.target_x, self.target_y = self._get_random_point_in_zone(billing_zone)
                    
        elif self.state == "checkout":
            dx = self.target_x - self.x
            dy = self.target_y - self.y
            dist = math.hypot(dx, dy)
            if dist > 5:
                self.x += (dx / dist) * self.speed
                self.y += (dy / dist) * self.speed
            else:
                if self.dwell_started is None:
                    self.dwell_started = time.time()
                    self.dwell_time = random.uniform(2.0, 4.0)
                elif time.time() - self.dwell_started >= self.dwell_time:
                    # Transaction complete!
                    self.dwell_started = None
                    self.state = "exit"
                    self.target_x = random.choice([0, self.width])
                    self.target_y = self.height - 20
                    
        elif self.state == "exit":
            dx = self.target_x - self.x
            dy = self.target_y - self.y
            dist = math.hypot(dx, dy)
            if dist > 5:
                self.x += (dx / dist) * self.speed
                self.y += (dy / dist) * self.speed
            else:
                return True # Finished and exited
        return False

class CCTVEngine:
    def __init__(self, layout_path="data/store_layout.json"):
        with open(layout_path, "r") as f:
            self.layout = json.load(f)
            
        self.width, self.height = self.layout["resolution"]
        self.zones = self.layout["zones"]
        self.shoppers = []
        self.shopper_counter = 0
        self.active_alerts = []
        
        # Extract specific zones
        self.billing_zone = next(z for z in self.zones if z["id"] == "zone_billing")
        self.queue_zone = next(z for z in self.zones if z["id"] == "zone_queue")
        
    def is_point_in_poly(self, x, y, poly):
        n = len(poly)
        inside = False
        p1x, p1y = poly[0]
        for i in range(n + 1):
            p2x, p2y = poly[i % n]
            if y > min(p1y, p2y):
                if y <= max(p1y, p2y):
                    if x <= max(p1x, p2x):
                        if p1y != p2y:
                            xints = (y - p1y) * (p2x - p1x) / (p2y - p1y) + p1x
                        if p1x == p2x or x <= xints:
                            inside = not inside
            p1x, p1y = p2x, p2y
        return inside

    def get_zone_for_point(self, x, y):
        for z in self.zones:
            if self.is_point_in_poly(x, y, z["polygon"]):
                return z["id"]
        return "none"

    def step(self):
        # Spawn new shoppers
        if len(self.shoppers) < 5 and random.random() < 0.05:
            self.shopper_counter += 1
            shopper_id = f"SHOP_{self.shopper_counter:03d}"
            self.shoppers.append(Shopper(shopper_id, self.zones, self.width, self.height))
            
        # Update shoppers
        exited_shoppers = []
        telemetry_events = []
        
        for s in self.shoppers:
            exited = s.update(self.billing_zone, self.queue_zone)
            if exited:
                exited_shoppers.append(s)
            else:
                old_zone = s.current_zone
                s.current_zone = self.get_zone_for_point(s.x, s.y)
                
                event_type = "move"
                if old_zone != s.current_zone:
                    event_type = "enter" if s.current_zone != "none" else "exit"
                elif s.dwell_started is not None:
                    event_type = "dwell"
                    
                if s.state == "checkout" and s.dwell_started is not None:
                    event_type = "checkout"

                telemetry_events.append({
                    "timestamp": datetime.utcnow().isoformat() + "Z",
                    "shopper_id": s.id,
                    "x": int(s.x),
                    "y": int(s.y),
                    "zone_id": s.current_zone,
                    "event_type": event_type,
                    "state": s.state
                })
                
        # Remove exited shoppers
        for s in exited_shoppers:
            self.shoppers.remove(s)
            
        return telemetry_events

    def render_frame(self):
        if not HAS_OPENCV:
            return None
            
        # Create dark background frame (Purplle aesthetics: deep rich dark background)
        frame = np.zeros((self.height, self.width, 3), dtype=np.uint8)
        frame[:, :] = (18, 12, 22) # Soft Dark Violet
        
        # Draw Zones
        for z in self.zones:
            poly = np.array(z["polygon"], dtype=np.int32)
            color_hex = z.get("color_hex", "#ffffff").lstrip('#')
            rgb = tuple(int(color_hex[i:i+2], 16) for i in (4, 2, 0)) # BGR in opencv
            bgr = (rgb[2], rgb[1], rgb[0])
            
            # Fill zone with translucent color
            overlay = frame.copy()
            cv2.fillPoly(overlay, [poly], bgr)
            cv2.addWeighted(overlay, 0.15, frame, 0.85, 0, frame)
            
            # Draw boundary line
            cv2.polylines(frame, [poly], True, bgr, 2, cv2.LINE_AA)
            
            # Draw label
            centroid_x = int(sum(p[0] for p in z["polygon"]) / len(z["polygon"]))
            centroid_y = int(sum(p[1] for p in z["polygon"]) / len(z["polygon"]))
            cv2.putText(frame, z["name"], (centroid_x - 60, centroid_y), 
                        cv2.FONT_HERSHEY_SIMPLEX, 0.45, (220, 220, 220), 1, cv2.LINE_AA)
            
        # Draw shoppers
        for s in self.shoppers:
            # Draw path
            if len(s.path) > 1:
                for i in range(len(s.path) - 1):
                    alpha = i / len(s.path)
                    color = (int(s.color[0]*alpha), int(s.color[1]*alpha), int(s.color[2]*alpha))
                    cv2.line(frame, s.path[i], s.path[i+1], color, 1, cv2.LINE_AA)
            
            # Draw shopper dot
            cv2.circle(frame, (int(s.x), int(s.y)), 8, s.color, -1, cv2.LINE_AA)
            cv2.circle(frame, (int(s.x), int(s.y)), 10, (255, 255, 255), 1, cv2.LINE_AA)
            
            # Bounding Box representing AI Tracking
            cv2.rectangle(frame, (int(s.x)-15, int(s.y)-15), (int(s.x)+15, int(s.y)+15), s.color, 1, cv2.LINE_AA)
            
            # Label
            label = f"{s.id} ({s.state})"
            cv2.putText(frame, label, (int(s.x) - 25, int(s.y) - 22),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.35, (255, 255, 255), 1, cv2.LINE_AA)
            
        # Add metadata headers
        cv2.rectangle(frame, (0, 0), (self.width, 35), (28, 20, 32), -1)
        cv2.putText(frame, f"STORE INTEL: ACTIVE CUSTOMERS: {len(self.shoppers)} | QUEUE: {len([s for s in self.shoppers if s.state == 'queue'])}", 
                    (15, 22), cv2.FONT_HERSHEY_SIMPLEX, 0.45, (230, 180, 255), 1, cv2.LINE_AA)
        
        # Encode to JPEG
        _, jpeg = cv2.imencode('.jpg', frame)
        return jpeg.tobytes()

if __name__ == "__main__":
    print("Testing CCTV Simulation Engine...")
    engine = CCTVEngine()
    for _ in range(5):
        events = engine.step()
        print(f"Step completed. Shoppers: {len(engine.shoppers)}. New events generated: {len(events)}")
        time.sleep(0.5)
    print("Simulated CCTV Engine runs successfully!")
