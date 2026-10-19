#!/usr/bin/env python3
import time
import re
import json
import os
import requests
from bs4 import BeautifulSoup

# Load core configuration from environment variables
SEARCH_QUERY = os.environ.get("SEARCH_QUERY", "RTX 3090")
MIN_PRICE = int(os.environ.get("MIN_PRICE", 900))
MAX_PRICE = int(os.environ.get("MAX_PRICE", 1150))
NTFY_TOPIC = os.environ.get("NTFY_TOPIC", "mike_3090_alerts")

# Define exclude words directly in Python to avoid environment escaping issues
EXCLUDE_WORDS = ["dell", "hp", "alienware", "omen", "waterblock", "block"]

seen_ids = set()

def check_ebay():
    url = f"https://www.ebay.com/sch/i.html?_nkw={SEARCH_QUERY}&_udlo={MIN_PRICE}&_udhi={MAX_PRICE}&_sop=10&LH_BIN=1"
    headers = {
        'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    }
    
    try:
        res = requests.get(url, headers=headers, timeout=10)
        soup = BeautifulSoup(res.text, 'html.parser')
        
        items = soup.select('li.s-item')
        for item in items:
            title_el = item.select_one('.s-item__title')
            link_el = item.select_one('a.s-item__link')
            price_el = item.select_one('.s-item__price')
            
            if not title_el or not link_el:
                continue
                
            title = title_el.text.strip()
            link = link_el.get('href', '').split('?')[0]
            
            if "Shop on eBay" in title:
                continue
                
            item_id_match = re.search(r'/itm/(\d+)', link)
            item_id = item_id_match.group(1) if item_id_match else link
            
            if item_id in seen_ids:
                continue
                
            title_lower = title.lower()
            if any(bad in title_lower for bad in EXCLUDE_WORDS):
                continue
                
            price_str = price_el.text.strip() if price_el else "N/A"
            
            seen_ids.add(item_id)
            send_ntfy_alert(title, price_str, link)
            
    except Exception:
        pass

def send_ntfy_alert(title, price, link):
    payload = {
        "topic": NTFY_TOPIC,
        "title": f"🚨 RTX 3090 Listed: {price}",
        "message": f"{title}\n\n{link}",
        "priority": 5,
        "tags": ["desktop_computer", "moneybag"],
        "actions": [
            {
                "action": "view",
                "label": "Open eBay Listing",
                "url": link
            }
        ]
    }
    requests.post("https://ntfy.sh", data=json.dumps(payload))

if __name__ == "__main__":
    while True:
        check_ebay()
        time.sleep(60)
