import json

with open("HousePlants/jason.json", "r") as f:
    data = json.load(f)

plants = data.get("plant_catalog", [])

missing = []
for p in plants:
    if "images" not in p:
        missing.append(p["id"])

print(f"Missing images in {len(missing)} plants:")
print(missing)
