#!/usr/bin/env bash
set -euo pipefail

INPUT=${1:?input contigs FASTA required}
OUT=${2:?output directory required}
THREADS=${THREADS:-20}
GENOMAD_DB=${GENOMAD_DB:?Set GENOMAD_DB}
DVF_SCRIPT=${DVF_SCRIPT:-/path/to/DeepVirFinder/dvf.py}

mkdir -p "$OUT"/{virsorter2,genomad,vibrant,deepvirfinder}

virsorter run \
  -w "$OUT/virsorter2" \
  -i "$INPUT" \
  --min-length 5000 \
  --include-groups dsDNAphage,ssDNA,RNA,lavidaviridae,NCLDV \
  -j "$THREADS" all

genomad end-to-end \
  --min-score 0.7 \
  --cleanup \
  "$INPUT" "$OUT/genomad" "$GENOMAD_DB"

VIBRANT_run.py \
  -i "$INPUT" \
  -t "$THREADS" \
  -folder "$OUT/vibrant"

python "$DVF_SCRIPT" \
  -i "$(dirname "$INPUT")" \
  -o "$OUT/deepvirfinder" \
  -l 1000 \
  -c "$THREADS"

# DeepVirFinder accepts an input directory; keep only intended FASTA files in the input directory.
