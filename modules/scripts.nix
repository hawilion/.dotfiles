{ config, pkgs, lib, ... }:

let
  rebuildLenovoScript = pkgs.writeShellScriptBin "rebuild-lenovo" (builtins.readFile ./scripts/rebuild-lenovo.sh);
  rebuildLlamaScript  = pkgs.writeShellScriptBin "rebuild-llama"  (builtins.readFile ./scripts/rebuild-llama.sh);
  borgBackupScript    = pkgs.writeShellScriptBin "borg-run"       (builtins.readFile ./scripts/borg-run.sh);
  borgJournalScript   = pkgs.writeShellScriptBin "borg-journal"   (builtins.readFile ./scripts/borg-journal.sh);
  ollamaCtlScript     = pkgs.writeShellScriptBin "ollama-ctl"     (builtins.readFile ./scripts/ollama.sh);
  scanScript          = pkgs.writeShellScriptBin "scan-doc" ''
    export PATH="${lib.makeBinPath [ pkgs.imagemagick pkgs.sane-backends ]}:$PATH"
    ${builtins.readFile ./scripts/scan.sh}
  '';
in
{
  environment.systemPackages = [
    borgBackupScript
    borgJournalScript
    rebuildLenovoScript
    rebuildLlamaScript
    ollamaCtlScript
    scanScript
  ];
}
