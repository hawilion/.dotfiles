# hosts/lenovo/ai-client.nix
{ config, pkgs, ... }:

{
  services.open-webui = {
    enable = true;
    port = 8080;
    environment = {
      # Target the remote Ollama host on llama
      OLLAMA_BASE_URL = "http://192.168.79.86:11434";
      OLLAMA_BASE_URLS = "http://192.168.79.86:11434";
      ENABLE_OLLAMA_API = "True";
      WEBUI_URL = "http://127.0.0.1:8080";

      DEFAULT_USER_ROLE = "admin";
      WEBUI_ADMIN_EMAIL = "mlillie57@gmail.com";

      # Explicitly offload or disable local RAG transformers to prevent CPU lockup
      RAG_EMBEDDING_ENGINE = "ollama";
      RAG_OLLAMA_BASE_URL = "http://192.168.79.86:11434";
      RAG_EMBEDDING_MODEL = "nomic-embed-text:latest";
      ENABLE_RAG_HYBRID_SEARCH = "False";
      ENABLE_RAG_LOCAL_WEB_FETCH = "False";

      ANONYMIZED_TELEMETRY = "False";
      DO_NOT_TRACK = "True";
    };
  };

  networking.firewall.allowedTCPPorts = [ 8080 ];
}
