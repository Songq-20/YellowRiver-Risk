#!/usr/bin/env bash
set -euo pipefail

# dRep dereplication
# Original parameters: secondary ANI 0.95, completeness >=50%, contamination <=10%
# Usage: bash 04_drep.sh BINS_DIR checkm.csv OUTDIR

BINS_DIR=${1:?directory containing MAG FASTA files required}
GENOME_INFO=${2:?CheckM genomeInfo CSV required}
OUT=${3:-dRep95}
THREADS=${THREADS:-30}

dRep dereplicate "$OUT" \
  -sa 0.95 \
  -p "$THREADS" \
  -comp 50 \
  -con 10 \
  -g "$BINS_DIR"/*.fa \
  --genomeInfo "$GENOME_INFO"
