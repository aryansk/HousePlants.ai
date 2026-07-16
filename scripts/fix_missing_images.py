import json
import os
import urllib.request
import urllib.parse
import time
import ssl

jason_path = "/Users/aryan/Documents/HousePlants.ai/HousePlants/jason.json"
assets_path = "/Users/aryan/Documents/HousePlants.ai/HousePlants/Assets.xcassets"

def fix_missing_images():
    print(f"Loading plant data from {jason_path}...")
    with open(jason_path, 'r') as f:
        data = json.load(f)
    
    plants = data.get("plant_catalog", [])
    total = len(plants)
    
    missing_count = 0
    to_fix = []
    
    # First, identify which images are actually missing
    for plant in plants:
        pid = plant.get("id")
        image_name = plant.get("images", {}).get("main", f"{pid}_main")
        imageset_dir = os.path.join(assets_path, f"{image_name}.imageset")
        image_path = os.path.join(imageset_dir, f"{image_name}.jpg")
        
        if not os.path.exists(image_path):
            to_fix.append(plant)
            missing_count += 1
            
    if not to_fix:
        print("All plant images are present! Nothing to fix.")
        return

    print(f"Found {missing_count} missing images out of {total} total plants.")
    print("Starting download for missing images...\n")
    
    success = 0
    failed = []
    
    for i, plant in enumerate(to_fix, 1):
        pid = plant.get("id")
        name = plant.get("botanical_name", plant.get("common_name"))
        image_name = plant.get("images", {}).get("main", f"{pid}_main")
        imageset_dir = os.path.join(assets_path, f"{image_name}.imageset")
        
        # Create directory if it doesn't exist
        if not os.path.exists(imageset_dir):
            os.makedirs(imageset_dir)
            
        # Create Contents.json if it doesn't exist
        contents_path = os.path.join(imageset_dir, "Contents.json")
        if not os.path.exists(contents_path):
            contents_json = {
                "images": [
                    {
                        "filename": f"{image_name}.jpg",
                        "idiom": "universal",
                        "scale": "1x"
                    },
                    {
                        "idiom": "universal",
                        "scale": "2x"
                    },
                    {
                        "idiom": "universal",
                        "scale": "3x"
                    }
                ],
                "info": {
                    "author": "xcode",
                    "version": 1
                }
            }
            with open(contents_path, 'w') as f:
                json.dump(contents_json, f, indent=2)
            
        # Download Image
        image_path = os.path.join(imageset_dir, f"{image_name}.jpg")
        
        print(f"[{i}/{missing_count}] Downloading {name} ({pid})...", end=" ")
        
        try:
            prompt = f"natural realistic photograph of {name} houseplant in home setting, natural lighting, authentic indoor plant photography, high quality"
            encoded_prompt = urllib.parse.quote(prompt)
            url = f"https://gen.pollinations.ai/image/{encoded_prompt}?width=1024&height=1024&seed={i+42}&nologo=true"
            
            context = ssl._create_unverified_context()
            
            req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
            with urllib.request.urlopen(req, context=context, timeout=45) as response:
                if response.status == 200:
                    with open(image_path, 'wb') as f:
                        f.write(response.read())
                    print("✓")
                    success += 1
                else:
                    print(f"✗ (Status {response.status})")
                    failed.append(pid)
        except Exception as e:
            print(f"✗ ({str(e)[:50]})")
            failed.append(pid)
        
        # Be nice to the API
        time.sleep(0.5)
    
    print(f"\n{'='*60}")
    print(f"Repair Complete! Success: {success}/{missing_count}")
    if failed:
        print(f"Failed IDs: {failed}")

if __name__ == "__main__":
    fix_missing_images()
