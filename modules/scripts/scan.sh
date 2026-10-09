#!/usr/bin/env bash
set -euo pipefail

OUTPUT="${1:-scan_$(date +%Y%m%d_%H%M%S).pdf}"
SOURCE="${2:-ADF}" # Pass "Flatbed" as second argument if you want glass instead
DEVICE="escl:http://192.168.79.190:80"

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

echo "Scanning from Brother MFC-L2710DW using source: $SOURCE..."

if [ "$SOURCE" = "ADF" ]; then
  # Batch mode for multi-page ADF feeding
  scanimage -d "$DEVICE" \
    --source "ADF" \
    --format=tiff \
    --resolution 300 \
    --batch="$TMPDIR/page_%04d.tif"
else
  # Single page flatbed scan
  scanimage -d "$DEVICE" \
    --source "Flatbed" \
    --format=tiff \
    --resolution 300 > "$TMPDIR/page_0001.tif"
fi

if [ -z "$(ls -A "$TMPDIR"/page_*.tif 2>/dev/null)" ]; then
  echo "No pages scanned."
  exit 1
fi

echo "Combining pages into $OUTPUT..."
magick "$TMPDIR"/page_*.tif "$OUTPUT"

echo "Saved scan to: $OUTPUT"
