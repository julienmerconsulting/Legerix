#!/usr/bin/env bash
# Download lightweight traineddata models from the upstream tessdata_fast repo
# and stage them under src/main/resources/tessdata/.
#
# Bundled languages (~31 MB total):
#   eng     — English
#   fra     — French
#   spa     — Spanish
#   chi_sim — Simplified Chinese
#   hin     — Hindi
#   rus     — Russian
#   por     — Portuguese
#   deu     — German
#   jpn     — Japanese
#   chi_tra — Traditional Chinese
#   ara     — Arabic
#   kor     — Korean
#   ita     — Italian
#   vie     — Vietnamese
#
# Usage:  fetch-traineddata.sh [output-dir]
# Default output dir: src/main/resources/tessdata

set -euo pipefail

OUTDIR="${1:-src/main/resources/tessdata}"
BASE_URL="https://github.com/tesseract-ocr/tessdata_fast/raw/main"
LANGS=(eng fra spa chi_sim hin rus por deu jpn chi_tra ara kor ita vie)

mkdir -p "$OUTDIR"

for lang in "${LANGS[@]}"; do
  url="${BASE_URL}/${lang}.traineddata"
  out="${OUTDIR}/${lang}.traineddata"
  echo "==> Fetching ${lang}.traineddata (fast model) from ${url}"
  curl -fsSL "$url" -o "$out"
done

echo "==> Staged traineddata files in $OUTDIR:"
ls -lh "$OUTDIR"/*.traineddata
