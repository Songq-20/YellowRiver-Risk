#!/usr/bin/env bash
set -euo pipefail

# DRAM annotation
# Usage: bash 06_dram.sh id_list.txt MAG_DIR OUTDIR

ID_LIST=${1:?MAG file list required}
MAG_DIR=${2:?MAG directory required}
OUT=${3:?output directory required}
THREADS=${THREADS:-10}

mkdir -p "$OUT"

while read -r line; do
  [[ -z "$line" ]] && continue
  name=${line%.*}
  DRAM.py annotate \
    -i "$MAG_DIR/$line" \
    -o "$OUT/dram_${name}" \
    --threads "$THREADS" \
    --use_vogdb
done < "$ID_LIST"
