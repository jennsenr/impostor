import json
import os
import time
import requests
from PIL import Image
from io import BytesIO
import re

# Config
WORDS_JSON = os.environ.get("WORDS_JSON", "api/internal/infrastructure/data/words.json")
ASSETS_DIR = os.environ.get("ASSETS_DIR", "api/public/assets")
MAX_JUNIOR_WORDS = int(os.environ.get("MAX_JUNIOR_WORDS", "0")) # Default to 0 (all)
PIXABAY_API_KEY = os.environ.get("PIXABAY_API_KEY", "")

import unicodedata
def slugify(text):
    text = unicodedata.normalize('NFD', text)
    text = "".join([c for c in text if unicodedata.category(c) != 'Mn'])
    text = text.lower()
    text = re.sub(r'[^\w\s-]', '', text)
    return re.sub(r'[-\s]+', '_', text).strip('_')

def fetch_images():
    if not PIXABAY_API_KEY:
        print("Error: PIXABAY_API_KEY environment variable not set.")
        return

    if not os.path.exists(WORDS_JSON):
        print(f"Error: {WORDS_JSON} not found.")
        return

    with open(WORDS_JSON, 'r', encoding='utf-8') as f:
        words = json.load(f)

    # Filter junior words
    junior_words = [w for w in words if w.get('is_junior') is True]
    if MAX_JUNIOR_WORDS > 0:
        junior_words = junior_words[:MAX_JUNIOR_WORDS]
        
    print(f"Processing {len(junior_words)} junior words (Limit: {'None' if MAX_JUNIOR_WORDS == 0 else MAX_JUNIOR_WORDS}).")

    processed_count = 0
    updated_count = 0

    for word_data in junior_words:
        word_text = word_data['text']
        category = word_data['category_id']
        
        # Target path
        slug = slugify(word_text)
        target_dir = os.path.join(ASSETS_DIR, category)
        os.makedirs(target_dir, exist_ok=True)
        
        target_filename = f"{slug}.png"
        target_path = os.path.join(target_dir, target_filename)
        public_url = f"/assets/{category}/{target_filename}"

        print(f"[{processed_count+1}/{len(junior_words)}] Searching image for: {word_text} ({category})...")
        
        try:
            # Pixabay Search
            # Use lang=es, image_type=illustration and children-friendly keywords
            import urllib.parse
            query_str = f"{word_text} {category} infantil dibujo cartoon"
            encoded_query = urllib.parse.quote(query_str)
            search_url = f"https://pixabay.com/api/?key={PIXABAY_API_KEY}&q={encoded_query}&lang=es&image_type=illustration&safesearch=true&per_page=3"
            
            response = requests.get(search_url, timeout=10)
            if response.status_code == 200:
                data = response.json()
                hits = data.get('hits', [])
                
                if hits:
                    # Take the first hit
                    img_url = hits[0]['webformatURL']
                    print(f"  Found URL: {img_url}")
                    
                    # Download
                    img_res = requests.get(img_url, timeout=10)
                    if img_res.status_code == 200:
                        # Convert to PNG
                        img = Image.open(BytesIO(img_res.content))
                        img.thumbnail((800, 800))
                        img.save(target_path, "PNG")
                        
                        # Update JSON data
                        word_data['image_url'] = public_url
                        updated_count += 1
                        print(f"  Saved to local assets: {target_path}")
                    else:
                        print(f"  Failed do download image: {img_res.status_code}")
                else:
                    print(f"  No hits found on Pixabay for '{word_text}'")
            else:
                print(f"  Pixabay API error: {response.status_code} - {response.text}")
                
        except Exception as e:
            print(f"  Error processing {word_text}: {e}")

        processed_count += 1
        # Small delay to respect Pixabay rate limits (max 100/min approx)
        time.sleep(0.5)

    # Save updated JSON
    if updated_count > 0:
        with open(WORDS_JSON, 'w', encoding='utf-8') as f:
            json.dump(words, f, ensure_ascii=False, indent=2)
        print(f"\nSUCCESS: Updated {updated_count} words in {WORDS_JSON}")
    else:
        print("\nNo changes made to JSON.")

if __name__ == "__main__":
    fetch_images()
