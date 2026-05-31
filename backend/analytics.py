import os
import json
import random
import pandas as pd
from datetime import datetime

class StoreAnalytics:
    def __init__(self, transactions_path="data/pos_transactions.csv", layout_path="data/store_layout.json"):
        self.transactions_path = transactions_path
        self.layout_path = layout_path
        
        # Load static records
        self.transactions_df = pd.read_csv(self.transactions_path)
        with open(self.layout_path, "r") as f:
            self.layout = json.load(f)
            
        # Session states
        self.shopper_history = {} # shopper_id -> {zone_id -> total_dwell_time}
        self.shopper_visit_counts = {} # zone_id -> set of unique shopper_ids
        self.purchases = [] # list of purchase mappings
        self.total_revenue = float(self.transactions_df["amount"].sum())
        
        # Init counters
        for z in self.layout["zones"]:
            self.shopper_visit_counts[z["id"]] = set()

    def record_event(self, event):
        shopper_id = event["shopper_id"]
        zone_id = event["zone_id"]
        event_type = event["event_type"]
        
        if zone_id == "none" or not zone_id:
            return

        if shopper_id not in self.shopper_history:
            self.shopper_history[shopper_id] = {
                "zones": {},
                "enter_time": datetime.utcnow(),
                "converted": False
            }

        # Track visits
        if zone_id in self.shopper_visit_counts:
            self.shopper_visit_counts[zone_id].add(shopper_id)

        # Track dwell time
        if zone_id not in self.shopper_history[shopper_id]["zones"]:
            self.shopper_history[shopper_id]["zones"][zone_id] = 0
        
        self.shopper_history[shopper_id]["zones"][zone_id] += 1 # Incremented per heartbeat step (~1s)

        # If checkout happens, match with POS
        if event_type == "checkout" and not self.shopper_history[shopper_id]["converted"]:
            self.shopper_history[shopper_id]["converted"] = True
            self.match_pos_transaction(shopper_id)

    def match_pos_transaction(self, shopper_id):
        # Match shopper browsing with available transactions
        shopper_zones = self.shopper_history[shopper_id]["zones"]
        # Find which product zone shopper spent most time in
        product_zones = [z for z in shopper_zones.keys() if "cosmetics" in z or "skincare" in z or "fragrance" in z]
        
        if not product_zones:
            primary_zone = "zone_cosmetics" # Default fallback
        else:
            primary_zone = max(product_zones, key=lambda k: shopper_zones[k])
            
        # Find a transaction matching this zone that has not been mapped yet
        mapped_txns = [p["transaction_id"] for p in self.purchases]
        avail_txns = self.transactions_df[
            (self.transactions_df["zone_id"] == primary_zone) & 
            (~self.transactions_df["transaction_id"].isin(mapped_txns))
        ]
        
        if not avail_txns.empty:
            txn = avail_txns.iloc[0]
        else:
            # Pick any unmapped or create a synthetic transaction
            unmapped = self.transactions_df[~self.transactions_df["transaction_id"].isin(mapped_txns)]
            if not unmapped.empty:
                txn = unmapped.iloc[0]
            else:
                # Generate a real-looking transaction dynamically
                new_id = f"TXN{10000 + len(self.purchases) + 1}"
                new_row = {
                    "transaction_id": new_id,
                    "timestamp": datetime.utcnow().isoformat() + "Z",
                    "amount": round(500 + random.random()*4500, 2),
                    "items_count": random.randint(1, 4),
                    "zone_id": primary_zone,
                    "payment_method": random.choice(["UPI", "Card", "Cash"])
                }
                self.transactions_df = pd.concat([self.transactions_df, pd.DataFrame([new_row])], ignore_index=True)
                txn = new_row
                self.total_revenue += float(txn["amount"])

        # Create mapping
        self.purchases.append({
            "shopper_id": shopper_id,
            "transaction_id": txn["transaction_id"],
            "amount": float(txn["amount"]),
            "items_count": int(txn["items_count"]),
            "zone_id": primary_zone,
            "payment_method": txn["payment_method"],
            "timestamp": datetime.utcnow().isoformat() + "Z"
        })

    def get_metrics_summary(self):
        # Calculate conversion rates: (shopper purchases from zone / shopper visits to zone)
        zone_conversions = {}
        for z in self.layout["zones"]:
            z_id = z["id"]
            if z_id == "zone_queue" or z_id == "zone_billing":
                continue
            
            visits = len(self.shopper_visit_counts[z_id])
            purchases = len([p for p in self.purchases if p["zone_id"] == z_id])
            
            rate = 0.0
            if visits > 0:
                rate = min(round((purchases / visits) * 100, 1), 100.0)
                
            zone_conversions[z_id] = {
                "visits": visits,
                "purchases": purchases,
                "conversion_rate": rate
            }
            
        # Average Dwell time per zone
        avg_dwells = {}
        for z in self.layout["zones"]:
            z_id = z["id"]
            dwells = []
            for shop_id, history in self.shopper_history.items():
                if z_id in history["zones"]:
                    dwells.append(history["zones"][z_id])
            
            avg_dwells[z_id] = round(sum(dwells) / len(dwells), 1) if dwells else 0.0

        # Payments splits
        payment_splits = {}
        if self.purchases:
            df = pd.DataFrame(self.purchases)
            payment_splits = df["payment_method"].value_counts().to_dict()
            
        return {
            "total_revenue": round(self.total_revenue, 2),
            "total_customers_tracked": len(self.shopper_history),
            "total_purchases": len(self.purchases),
            "zone_metrics": zone_conversions,
            "average_dwell_times": avg_dwells,
            "payments_split": payment_splits,
            "recent_purchases": self.purchases[-5:]
        }
