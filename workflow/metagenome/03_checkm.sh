#!/usr/bin/env bash
set -euo pipefail

# CheckM quality assessment using the same lab wrapper used in the analysis.
# Usage: CHECKM_WRAPPER=/path/run_checkm.sh bash 03_checkm.sh id.txt BINS_ROOT OUTDIR

ID_LIST=${1:?ID list required}
BINS_ROOT=${2:?BASALT result root required}
OUT=${3:?output directory required}
CHECKM_WRAPPER=${CHECKM_WRAPPER:?Set CHECKM_WRAPPER to run_checkm.sh}

mkdir -p "$OUT"

while read -r id; do
  [[ -z "$id" ]] && continue
  mkdir -p "$OUT/$id"
  "$CHECKM_WRAPPER" "$id" fa "$BINS_ROOT/$id"/Final* "$OUT/$id"
done < "$ID_LIST"
