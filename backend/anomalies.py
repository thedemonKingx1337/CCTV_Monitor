import time
from datetime import datetime

class AnomalyDetector:
    def __init__(self):
        self.active_alerts = []
        self.alert_history = []
        self.billing_empty_since = None

    def evaluate_store_state(self, shoppers, zones):
        current_time = datetime.utcnow().isoformat() + "Z"
        new_alerts = []
        
        # 1. Queue Length Anomaly
        queue_shoppers = [s for s in shoppers if s.state == "queue" or s.current_zone == "zone_queue"]
        if len(queue_shoppers) >= 3:
            new_alerts.append({
                "id": f"alert_queue_{int(time.time())}",
                "timestamp": current_time,
                "type": "queue_bottleneck",
                "severity": "high",
                "zone_id": "zone_queue",
                "message": f"Checkout queue bottleneck! {len(queue_shoppers)} customers waiting.",
                "status": "active"
            })
            
        # 2. Staff Absence Anomaly
        billing_shoppers = [s for s in shoppers if s.current_zone == "zone_billing"]
        if not billing_shoppers and len(queue_shoppers) > 0:
            if self.billing_empty_since is None:
                self.billing_empty_since = time.time()
            elif time.time() - self.billing_empty_since >= 5.0:  # Billing counter empty for more than 5s with active queue
                new_alerts.append({
                    "id": f"alert_staff_{int(time.time())}",
                    "timestamp": current_time,
                    "type": "staff_absence",
                    "severity": "critical",
                    "zone_id": "zone_billing",
                    "message": "Staff absence detected at billing desk with waiting queue!",
                    "status": "active"
                })
        else:
            self.billing_empty_since = None

        # 3. Dwell Time Anomaly
        for s in shoppers:
            if s.dwell_started is not None:
                dwell_duration = time.time() - s.dwell_started
                if dwell_duration > 12.0 and s.state != "exit":  # Over 12s dwell
                    severity = "warning"
                    if dwell_duration > 20.0:
                        severity = "high"
                    new_alerts.append({
                        "id": f"alert_dwell_{s.id}_{int(time.time())}",
                        "timestamp": current_time,
                        "type": "high_dwell",
                        "severity": severity,
                        "zone_id": s.current_zone,
                        "message": f"Customer {s.id} dwelling in {s.current_zone} for {int(dwell_duration)}s.",
                        "status": "active"
                    })

        # Merge alerts and update history
        # Only add if an alert of the same type is not already active
        active_types = [a["type"] for a in self.active_alerts]
        for alert in new_alerts:
            # Check duplicates in active alerts
            duplicate = False
            for active in self.active_alerts:
                if active["type"] == alert["type"] and active["zone_id"] == alert["zone_id"]:
                    duplicate = True
                    break
            if not duplicate:
                self.active_alerts.append(alert)
                self.alert_history.append(alert)
                
        # Resolve active alerts if the condition is no longer met
        resolved_alerts = []
        for active in list(self.active_alerts):
            condition_still_met = False
            if active["type"] == "queue_bottleneck":
                condition_still_met = len(queue_shoppers) >= 3
            elif active["type"] == "staff_absence":
                condition_still_met = not billing_shoppers and len(queue_shoppers) > 0
            elif active["type"] == "high_dwell":
                # Check if the specific shopper is still there and dwelling
                shopper_id = active["id"].split("_")[2] # "alert_dwell_SHOP_001_12345"
                matching_shopper = next((s for s in shoppers if s.id == shopper_id), None)
                if matching_shopper and matching_shopper.dwell_started is not None:
                    condition_still_met = (time.time() - matching_shopper.dwell_started) > 12.0
                else:
                    condition_still_met = False
                    
            if not condition_still_met:
                self.active_alerts.remove(active)
                # Mark as resolved in history
                for h in self.alert_history:
                    if h["id"] == active["id"]:
                        h["status"] = "resolved"
                        h["resolved_at"] = current_time
                        
        return self.active_alerts, self.alert_history
