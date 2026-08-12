#!/usr/bin/env bash
set -euo pipefail

# BASALT binning
# Original parameters: -t 40 -m 400
# Usage: CHECKM2DB=/path/uniref100.KO.1.dmnd bash 02_basalt.sh assembly_1k.fa R1_T.fq.gz R2_T.fq.gz OUTDIR

ASSEMBLY=$(realpath "${1:?1-kb contig FASTA required}")
R1=$(realpath "${2:?trimmed R1 required}")
R2=$(realpath "${3:?trimmed R2 required}")
OUT=${4:?output directory required}

export CHECKM2DB=${CHECKM2DB:?Set CHECKM2DB to uniref100.KO.1.dmnd}

mkdir -p "$OUT"
cd "$OUT"

BASALT -a "$ASSEMBLY" -s "$R1,$R2" -t 40 -m 400

# Temporary files removed after the original BASALT runs.
rm -rf core* *.fq *.fq.gz
