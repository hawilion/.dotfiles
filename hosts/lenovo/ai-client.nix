# hosts/lenovo/ai-client.nix
{ config, pkgs, ... }:

{
  # Local Open WebUI interface on Lenovo workstation
  services.open-webui = {
    enable = true;
    port = 8080;
    environment = {
      # Target the remote CPU/GPU inference host
      OLLAMA_BASE_URL = "http://192.168.79.86:11434";
      WEBUI_URL = "http://127.0.0.1:8080";

      # Force local admin permissions
      WEBUI_ADMIN_EMAIL = "mlillie57@gmail.com";

      # Avoid local HuggingFace/PyTorch hangs by offloading embeddings to Ollama on llama
      RAG_EMBEDDING_ENGINE = "ollama";
      RAG_OLLAMA_BASE_URL = "http://192.168.79.86:11434";
      RAG_EMBEDDING_MODEL = "nomic-embed-text";
      VECTOR_DB = "chroma";
      ENABLE_RAG_HYBRID_SEARCH = "False";

      ANONYMIZED_TELEMETRY = "False";
      DO_NOT_TRACK = "True";
    };
  };

  # Keep local port accessible if navigating from other browser windows
  networking.firewall.allowedTCPPorts = [ 8080 ];
}
