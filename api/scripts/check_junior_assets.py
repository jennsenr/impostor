import json
import os

def check_junior_assets():
    path = "api/internal/infrastructure/data/words.json"
    public_path = "api/public"
    
    with open(path, "r") as f:
        words = json.load(f)
        
    missing_url = []
    missing_file = []
    
    for w in words:
        if w.get("is_junior"):
            url = w.get("image_url")
            if not url:
                missing_url.append(w["text"])
            else:
                filepath = os.path.join(public_path, url.lstrip("/"))
                if not os.path.exists(filepath):
                    missing_file.append(f"{w['text']} ({url})")
                    
    print(f"Total Junior Words: {len([w for w in words if w.get('is_junior')])}")
    print(f"Missing image_url in JSON: {len(missing_url)}")
    if missing_url:
        print(", ".join(missing_url))
        
    print(f"\nMissing files on disk: {len(missing_file)}")
    for f in missing_file:
        print(f" - {f}")

if __name__ == "__main__":
    check_junior_assets()
