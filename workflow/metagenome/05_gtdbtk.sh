#!/usr/bin/env bash
set -euo pipefail

# GTDB-Tk classification (GTDB-Tk 2.4.0 in the original analysis)
# Usage: GTDBTK_DATA_PATH=/path/to/gtdb_db bash 05_gtdbtk.sh BINS_DIR OUTDIR PREFIX

GENOME_DIR=${1:?MAG directory required}
OUT=${2:?output directory required}
PREFIX=${3:?output prefix required}
THREADS=${THREADS:-30}

export GTDBTK_DATA_PATH=${GTDBTK_DATA_PATH:?Set GTDBTK_DATA_PATH}

gtdbtk classify_wf \
  -x fa \
  --prefix "$PREFIX" \
  --genome_dir "$GENOME_DIR" \
  --out_dir "$OUT" \
  --skip_ani_screen \
  --min_perc_aa 30 \
  --cpus "$THREADS"
