#!/usr/bin/env bash

DOTFILES_DIR="$HOME/.dotfiles"
HOST_CONFIG="$DOTFILES_DIR/hosts/lenovo/default.nix"

show_menu() {
    clear
    echo "=========================================="
    echo "       eBay Watcher Admin Panel           "
    echo "=========================================="
    echo "1) Check Service Status"
    echo "2) Tail Live Service Logs"
    echo "3) Update Price Bounds (min/max)"
    echo "4) Restart Service"
    echo "5) Test Run (Force One-Off Search)"
    echo "6) Exit"
    echo "=========================================="
    read -rp "Select an option [1-6]: " choice

    case $choice in
        1)
            echo -e "\n--- Systemd Service Status ---"
            sudo systemctl status ebay-watcher --no-pager
            read -rp "Press Enter to return..."
            ;;
        2)
            echo -e "\n--- Live Logs (Ctrl+C to stop) ---"
            sudo journalctl -u ebay-watcher -f -n 20
            ;;

        3)
    read -rp "Enter MIN price [e.g. 800]: " min_p
    read -rp "Enter MAX price [e.g. 1650]: " max_p
    
    if [[ -n "$min_p" && -n "$max_p" ]]; then
        echo "Updating $HOST_CONFIG..."
        sed -i -E "s/(minPrice = )[0-9]+;/\1$min_p;/" "$HOST_CONFIG"
        sed -i -E "s/(maxPrice = )[0-9]+;/\1$max_p;/" "$HOST_CONFIG"
        
        echo "Rebuilding NixOS configuration with nrlenovo..."
        cd "$DOTFILES_DIR" || exit
        git add "$HOST_CONFIG" 2>/dev/null
        git commit -m "Update ebay-watcher prices to $min_p - $max_p" 2>/dev/null || true
        
        # Execute build and restart regardless of git status
        nrlenovo
        sudo systemctl restart ebay-watcher
        echo "Done!"
    else
        echo "Invalid input."
    fi
    read -rp "Press Enter to return..."
    ;;
        4)
            echo -e "\nRestarting ebay-watcher service..."
            sudo systemctl restart ebay-watcher
            echo "Restarted."
            read -rp "Press Enter to return..."
            ;;
        5)
            echo -e "\n--- Executing Test Run ---"
            MIN_VAL=$(grep -E 'minPrice' "$HOST_CONFIG" | grep -oE '[0-9]+')
            MAX_VAL=$(grep -E 'maxPrice' "$HOST_CONFIG" | grep -oE '[0-9]+')
            
            MIN_VAL=${MIN_VAL:-800}
            MAX_VAL=${MAX_VAL:-1650}

            cd "$DOTFILES_DIR" || exit
            MIN_PRICE="$MIN_VAL" MAX_PRICE="$MAX_VAL" python3 "$DOTFILES_DIR/modules/services/ebay_watcher.py" --min "$MIN_VAL" --max "$MAX_VAL"
            read -rp "Press Enter to return..."
            ;;
        6)
            exit 0
            ;;
        *)
            echo "Invalid selection."
            sleep 1
            ;;
    esac
}

while true; do
    show_menu
done
