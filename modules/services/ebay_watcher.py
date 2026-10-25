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

seen_ids = load_seen_cache()is_first_run = len(seen_ids) == 0
if is_first_run and current_run_ids:
            is_first_run = False
            print(f"[*] Initial baseline established with {len(current_run_ids)} items.", flush=True)

        if current_run_ids:
            save_seen_cache(seen_ids)
        else:
            print(f"[*] Skipping cache write due to 0 items parsed (preserving existing cache).", flush=True)
HEADERS = {
    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4.1 Safari/605.1.15",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.9",
    "Accept-Encoding": "gzip, deflate, br",
    "Referer": "https://www.ebay.com/",
}

session = requests.Session()
session.headers.update(HEADERS)

try:
    print("[*] Warming up session on ebay.com...", flush=True)
    res_warm = session.get("https://www.ebay.com/", impersonate="safari17_0", timeout=15)
    print(f"[*] Warmup HTTP Status: {res_warm.status_code}", flush=True)
except Exception as e:
    print(f"[!] Warmup warning: {e}", flush=True)

def check_ebay():
    global is_first_run
    url = f"https://www.ebay.com/sch/i.html?_nkw={SEARCH_QUERY}&_udlo={MIN_PRICE}&_udhi={MAX_PRICE}&_sop=10&LH_BIN=1"
    
    print(f"[*] Checking eBay for '{SEARCH_QUERY}' (${MIN_PRICE}-{MAX_PRICE})...", flush=True)
    
    try:
        res = session.get(url, impersonate="safari17_0", timeout=15)
        print(f"[*] HTTP Status Code: {res.status_code}", flush=True)

        soup = BeautifulSoup(res.text, 'html.parser')
        title_tag = soup.find('title')
        if title_tag:
            print(f"[*] Page Title: {title_tag.text.strip()}", flush=True)
        
        items = soup.select('li.s-item')
        if not items:
            items = soup.select('.s-item')
        if not items:
            item_links = soup.find_all('a', href=lambda h: h and '/itm/' in h)
            items = []
            seen_containers = set()
            for link_el in item_links:
                container = link_el.find_parent('div') or link_el.find_parent('li')
                if container and id(container) not in seen_containers:
                    seen_containers.add(id(container))
                    items.append(container)
            
        print(f"[*] Found {len(items)} raw items on page.", flush=True)
        
        new_matches = 0
        current_run_ids = set()

        for item in items:
            title_el = item.select_one('.s-item__title') or item.find(['h3', 'span'], class_=lambda c: c and 'title' in c.lower())
            link_el = item.find('a', href=lambda h: h and '/itm/' in h)
            price_el = item.select_one('.s-item__price') or item.find(['span', 'div'], class_=lambda c: c and 'price' in c.lower())
            
            if not title_el or not link_el:
                continue
                
            title = title_el.text.strip()
            link = link_el.get('href', '').split('?')[0]
            price_str = price_el.text.strip() if price_el else "N/A"
            
            if "Shop on eBay" in title:
                continue
                
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
        requests.post("https://ntfy.sh", data=json.dumps(payload), impersonate="safari17_0", timeout=10)
    except Exception as e:
        print(f"[!] Failed to send ntfy notification: {e}", flush=True)

if __name__ == "__main__":
    print("[*] eBay Monitor Daemon started.", flush=True)
    while True:
        check_ebay()
        time.sleep(POLL_INTERVAL)
