#!/usr/bin/env bash
set -euo pipefail

OUTPUT="${1:-scan_$(date +%Y%m%d_%H%M%S).pdf}"
DEVICE="escl:http://192.168.79.190:80"

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

echo "Attempting to scan from ADF (Brother MFC-L2710DW)..."

# Try scanning from ADF; catch errors if the feeder is empty
if scanimage -d "$DEVICE" \
     --source "ADF" \
     --format=tiff \
     --resolution 300 \
     --batch="$TMPDIR/page_%04d.tif" 2>/dev/null; then
   # Check if batch actually captured any pages
   if [ -n "$(ls -A "$TMPDIR"/page_*.tif 2>/dev/null)" ]; then
     echo "ADF scan successful."
   else
     OUT_OF_PAPER=1
   fi
else
   OUT_OF_PAPER=1
fi

# Fallback to Flatbed if ADF was empty or failed
if [ "${OUT_OF_PAPER:-0}" -eq 1 ]; then
   echo "ADF is empty. Falling back to Flatbed..."
   scanimage -d "$DEVICE" \
     --source "Flatbed" \
     --format=tiff \
     --resolution 300 > "$TMPDIR/page_0001.tif"
fi

# Ensure we have pages before combining
if [ -z "$(ls -A "$TMPDIR"/page_*.tif 2>/dev/null)" ]; then
  echo "Error: No pages found from ADF or Flatbed."
  exit 1
fi

echo "Combining pages into $OUTPUT..."
magick "$TMPDIR"/page_*.tif "$OUTPUT"

echo "Saved scan to: $OUTPUT"
