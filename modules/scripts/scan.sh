#!/usr/bin/env bash
set -euo pipefail

OUTPUT="${1:-scan_$(date +%Y%m%d_%H%M%S).pdf}"
FORCE_FLATBED="${2:-}"
DEVICE="escl:http://192.168.79.190:80"

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

if [ "$FORCE_FLATBED" = "flatbed" ] || [ "$FORCE_FLATBED" = "-f" ]; then
   echo "Scanning directly from Flatbed..."
   scanimage -d "$DEVICE" \
     --source "Flatbed" \
     --format=tiff \
     --resolution 300 > "$TMPDIR/page_0001.tif"
else
   echo "Attempting to scan from ADF (Brother MFC-L2710DW)..."
   if scanimage -d "$DEVICE" \
        --source "ADF" \
        --format=tiff \
        --resolution 300 \
        --batch="$TMPDIR/page_%04d.tif" 2>/dev/null; then
      if [ -n "$(ls -A "$TMPDIR"/page_*.tif 2>/dev/null)" ]; then
        echo "ADF scan successful."
      else
        OUT_OF_PAPER=1
      fi
   else
      OUT_OF_PAPER=1
   fi

   if [ "${OUT_OF_PAPER:-0}" -eq 1 ]; then
      echo "ADF is empty. Falling back to Flatbed..."
      scanimage -d "$DEVICE" \
        --source "Flatbed" \
        --format=tiff \
        --resolution 300 > "$TMPDIR/page_0001.tif"
   fi
fi

if [ -z "$(ls -A "$TMPDIR"/page_*.tif 2>/dev/null)" ]; then
  echo "Error: No pages found from ADF or Flatbed."
  exit 1
fi

echo "Combining pages into $OUTPUT..."
magick "$TMPDIR"/page_*.tif "$OUTPUT"

echo "Saved scan to: $OUTPUT"
