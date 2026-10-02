#!/usr/bin/env bash
TARGET_HOST="192.168.79.86"
CURRENT_HOST="$(hostname)"
OLLAMA_PORT="11434"

usage() {
    echo "Usage: ollama [serve|status|remote-serve]"
    echo "  serve         - Start Ollama server locally (CPU mode)"
    echo "  status        - Check if Ollama is responding locally or on 'llama'"
    echo "  remote-serve  - SSH into llama via Tailscale and start server"
}

case "$1" in
    serve)
        echo "Starting Ollama locally on $CURRENT_HOST (CPU-only mode)..."
        OLLAMA_HOST="0.0.0.0:$OLLAMA_PORT" ollama serve
        ;;
    status)
        echo "Checking local Ollama status..."
        if curl -s "http://127.0.0.1:$OLLAMA_PORT/api/tags" > /dev/null; then
            echo " [OK] Local Ollama is running on $CURRENT_HOST"
        else
            echo " [X] Local Ollama is not responding on $CURRENT_HOST"
        fi

        echo "Checking remote 'llama' node ($TARGET_HOST)..."
        if curl -s "http://$TARGET_HOST:$OLLAMA_PORT/api/tags" > /dev/null; then
            echo " [OK] Ollama is running on llama ($TARGET_HOST)"
        else
            echo " [X] Ollama is not responding on llama ($TARGET_HOST)"
        fi
        ;;
    remote-serve)
        echo "Connecting to llama ($TARGET_HOST) via Tailscale to start Ollama..."
        ssh "root@$TARGET_HOST" "ollama serve"
        ;;
    *)
        usage
        exit 1
        ;;
esac
