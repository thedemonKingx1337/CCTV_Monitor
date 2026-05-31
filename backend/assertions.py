import json
import os
import pandas as pd

def load_layout(path="data/store_layout.json"):
    with open(path, "r") as f:
        return json.load(f)

def load_transactions(path="data/pos_transactions.csv"):
    return pd.read_csv(path)

def is_point_in_polygon(x, y, poly):
    # Ray casting algorithm
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

def test_store_layout():
    print("Testing store_layout.json loaded...")
    layout = load_layout()
    assert layout["store_id"] == "purplle_flagship_01", "Store ID mismatch"
    assert len(layout["zones"]) == 5, "Should have exactly 5 zones"
    print("[SUCCESS] store_layout.json is valid.")

def test_point_zone_mapping():
    print("Testing point-to-zone coordinates mapping...")
    layout = load_layout()
    zones = layout["zones"]
    
    # Test Cosmetics point (x=100, y=100)
    cosmetics_zone = next(z for z in zones if z["id"] == "zone_cosmetics")
    assert is_point_in_polygon(100, 100, cosmetics_zone["polygon"]), "Point (100,100) should be in cosmetics"
    
    # Test billing counter point (x=450, y=400)
    billing_zone = next(z for z in zones if z["id"] == "zone_billing")
    assert is_point_in_polygon(450, 400, billing_zone["polygon"]), "Point (450,400) should be in billing desk"
    
    # Test point outside
    assert not is_point_in_polygon(0, 0, cosmetics_zone["polygon"]), "Point (0,0) should be outside cosmetics"
    print("[SUCCESS] Coordinate point mapping is correct.")

def test_pos_transactions():
    print("Testing pos_transactions.csv loaded...")
    df = load_transactions()
    assert len(df) >= 10, "Should have at least 10 entries in transactions CSV"
    assert "transaction_id" in df.columns, "Missing transaction_id column"
    assert "zone_id" in df.columns, "Missing zone_id column"
    print("[SUCCESS] pos_transactions.csv matches expected schemas.")

if __name__ == "__main__":
    print("Running Purplle Challenge evaluation assertions...")
    try:
        test_store_layout()
        test_point_zone_mapping()
        test_pos_transactions()
        print("\nAll evaluation assertions PASSED! System state is verified.")
    except AssertionError as e:
        print(f"\n[FAILURE] Assertion failed: {e}")
        exit(1)
