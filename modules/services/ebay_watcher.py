#!/usr/bin/env python3
import time
import re
import json
import os
from curl_cffi import requests
from bs4 import BeautifulSoup

# Load core configuration from environment variables
SEARCH_QUERY = os.environ.get("SEARCH_QUERY", "RTX 3090")
MIN_PRICE = int(os.environ.get("MIN_PRICE", 800))
MAX_PRICE = int(os.environ.get("MAX_PRICE", 1650))
NTFY_TOPIC = os.environ.get("NTFY_TOPIC", "mike_3090_alerts")
POLL_INTERVAL = int(os.environ.get("POLL_INTERVAL", 180))

# Define exclude words
EXCLUDE_WORDS = ["dell", "hp", "alienware", "omen", "waterblock", "block"]
CACHE_FILE = "/home/mike/.cache/ebay_seen.json"

def load_seen_cache():
    if os.path.exists(CACHE_FILE):
        try:
            with open(CACHE_FILE, "r") as f:
                return set(json.load(f))
        except Exception:
            pass
    return set()

def save_seen_cache(seen_set):
    os.makedirs(os.path.dirname(CACHE_FILE), exist_ok=True)
    try:
        with open(CACHE_FILE, "w") as f:
            json.dump(list(seen_set), f)
    except Exception as e:
        print(f"[!] Failed to save cache: {e}", flush=True)

seen_ids = load_seen_cache()
is_first_run = len(seen_ids) == 0

# Chrome 120 headers
HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.9",
    "Accept-Encoding": "gzip, deflate, br",
    "Referer": "https://www.ebay.com/",
    "Sec-Ch-Ua": '"Not_A Brand";v="8", "Chromium";v="120", "Google Chrome";v="120"',
    "Sec-Ch-Ua-Mobile": "?0",
    "Sec-Ch-Ua-Platform": '"Windows"',
    "Sec-Fetch-Dest": "document",
    "Sec-Fetch-Mode": "navigate",
    "Sec-Fetch-Site": "same-origin",
    "Sec-Fetch-User": "?1",
    "Upgrade-Insecure-Requests": "1",
}

def check_ebay():
    global is_first_run
    url = f"https://www.ebay.com/sch/i.html?_nkw={SEARCH_QUERY}&_udlo={MIN_PRICE}&_udhi={MAX_PRICE}&_sop=10&LH_BIN=1"
    
    print(f"[*] Checking eBay for '{SEARCH_QUERY}' (${MIN_PRICE}-{MAX_PRICE})...", flush=True)
    
    # Create a fresh session every check using Chrome impersonation
    session = requests.Session()
    session.headers.update(HEADERS)
    
    try:
        print("[*] Warming up session on ebay.com...", flush=True)
        res_warm = session.get("https://www.ebay.com/", impersonate="chrome120", timeout=15)
        print(f"[*] Warmup HTTP Status: {res_warm.status_code}", flush=True)
        
        if res_warm.status_code != 200:
            print("[!] Warmup failed. Skipping this poll.", flush=True)
            return

        # Brief pause between warmup and search to mimic human behavior
        time.sleep(3)
        
        res = session.get(url, impersonate="chrome120", timeout=15)
        print(f"[*] HTTP Status Code: {res.status_code}", flush=True)

        soup = BeautifulSoup(res.text, 'html.parser')
        title_tag = soup.find('title')
        if title_tag:
            page_title = title_tag.text.strip()
            print(f"[*] Page Title: {page_title}", flush=True)
            
            if "Pardon Our Interruption" in page_title or "Robot" in page_title or "Error Page" in page_title:
                print("[!] Hit eBay bot challenge wall. Backing off...", flush=True)
                return
        
        # Target new eBay s-card layout
        items = soup.select('li.s-card')
        if not items:
            items = soup.select('.s-item')
            
        print(f"[*] Found {len(items)} raw items on page.", flush=True)
        
        new_matches = 0
        current_run_ids = set()

        for card in items:
            item_id = card.get('data-listingid')
            
            title_el = card.find(['span', 'div', 'a', 'h3'], class_=lambda c: c and 'title' in c.lower())
            link_el = card.find('a', href=lambda h: h and '/itm/' in h)
            price_el = card.find(['span', 'div'], class_=lambda c: c and 'price' in c.lower())
            
            if not title_el or not link_el:
                continue
                
            title = title_el.text.strip()
            link = link_el.get('href', '').split('?')[0]
            price_str = price_el.text.strip() if price_el else "N/A"
            
            if "Shop on eBay" in title or not title:
                continue
                
            if not item_id:
                item_id_match = re.search(r'/itm/(\d+)', link)
                item_id = item_id_match.group(1) if item_id_match else link
            
            current_run_ids.add(item_id)
            
            if item_id in seen_ids:
                continue
                
            title_lower = title.lower()
            if any(bad in title_lower for bad in EXCLUDE_WORDS):
                print(f"[-] Excluding: {title} ({price_str})", flush=True)
                seen_ids.add(item_id)
                continue
                
            seen_ids.add(item_id)
            
            # If this is the very first run, populate baseline quietly without alerting
            if is_first_run:
                print(f"[*] Baseline loaded (quiet): {title} | {price_str}", flush=True)
                continue

            new_matches += 1
            print(f"[+] New matching listing found: {title} | {price_str}", flush=True)
            send_ntfy_alert(title, price_str, link)
        
        if is_first_run and current_run_ids:
            is_first_run = False
            print(f"[*] Initial baseline established with {len(current_run_ids)} items.", flush=True)

        if current_run_ids:
            save_seen_cache(seen_ids)
        else:
            print(f"[*] Skipping cache write due to 0 items parsed (preserving existing cache).", flush=True)

        print(f"[*] Check complete. {new_matches} new alert(s) sent.", flush=True)
        
    except Exception as e:
        print(f"[!] Error checking eBay: {e}", flush=True)

def send_ntfy_alert(title, price, link):
    payload = {
        "topic": NTFY_TOPIC,
        "title": f"🚨 RTX 3090 Listed: {price}",
        "message": f"{title}\n\n{link}",
        "priority": 5,
        "tags": ["desktop_computer", "moneybag"],
        "click": link,
        "actions": [
            {
                "action": "view",
                "label": "Open eBay Listing",
                "url": link
            }
        ]
    }
    try:
        requests.post("https://ntfy.sh", data=json.dumps(payload), impersonate="chrome120", timeout=10)
    except Exception as e:
        print(f"[!] Failed to send ntfy notification: {e}", flush=True)

if __name__ == "__main__":
    print("[*] eBay Monitor Daemon started.", flush=True)
    while True:
        check_ebay()
        time.sleep(POLL_INTERVAL)
