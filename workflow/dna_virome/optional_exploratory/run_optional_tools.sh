#!/usr/bin/env bash
set -euo pipefail

INPUT=${1:?input viral FASTA required}
OUT=${2:?output directory required}
THREADS=${THREADS:-30}
mkdir -p "$OUT"

cat <<'EOF2'
Examples reconstructed from the supplied working notes. Verify versions and use only if these analyses are part of the final manuscript.

# PhaGCN3
python /path/to/PhaGCN3/run_Speed_up.py --contigs <input.fa> --outpath <output_dir>

# ViralRecall
cd /path/to/viralrecall
python ./viralrecall.py -i <input_dir> -p <output_dir> -t 6 -b

# GV-Class
cd /path/to/gvclass
snakemake -j 30 --use-conda --config querydir="<directory_with_one_sequence_per_file>"
EOF2
