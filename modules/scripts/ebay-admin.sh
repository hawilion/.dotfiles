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
            read -rp "Enter MAX price [e.g. 1500]: " max_p
            
            if [[ -n "$min_p" && -n "$max_p" ]]; then
                echo "Updating $HOST_CONFIG..."
                sed -i -E "s/(minPrice = )[0-9]+;/\1$min_p;/" "$HOST_CONFIG"
                sed -i -E "s/(maxPrice = )[0-9]+;/\1$max_p;/" "$HOST_CONFIG"
                
                echo "Rebuilding NixOS configuration..."
                cd "$DOTFILES_DIR" || exit
                git add "$HOST_CONFIG"
                git commit -m "Update ebay-watcher prices to $min_p - $max_p"
                sudo nixos-rebuild switch --flake .#lenovo
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
            cd "$DOTFILES_DIR" || exit
            python3 "$DOTFILES_DIR/modules/services/ebay_watcher.py"
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
