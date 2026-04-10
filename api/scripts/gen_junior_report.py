import json
import os

path = "api/internal/infrastructure/data/words.json"
public_path = "api/public"

with open(path, "r") as f:
    words = json.load(f)

print("| Palabra | Categoría | Asset URL | Existe? |")
print("|---|---|---|---|")
for w in words:
    if w.get("is_junior"):
        url = w.get("image_url")
        if not url:
            print(f"| {w.get('text', 'N/A')} | {w.get('category_id', 'N/A')} | MISSING | NO |")
        else:
            filepath = os.path.join(public_path, url.lstrip("/"))
            exists = "✅" if os.path.exists(filepath) else "❌"
            print(f"| {w.get('text', 'N/A')} | {w.get('category_id', 'N/A')} | {url} | {exists} |")
