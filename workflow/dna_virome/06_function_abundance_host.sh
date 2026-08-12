#!/usr/bin/env bash
set -euo pipefail

VOTU=${1:?vOTU FASTA required}
OUT=${2:?output directory required}
THREADS=${THREADS:-30}
IPHOP_DB=${IPHOP_DB:?Set IPHOP_DB}

mkdir -p "$OUT"

# --- DRAM-v preparation and annotation ---
virsorter run \
  --seqname-suffix-off \
  --provirus-off \
  --keep-original-seq \
  --viral-gene-enrich-off \
  -w "$OUT/virsorter_prepare" \
  -i "$VOTU" \
  --prep-for-dramv \
  --min-length 0 \
  --min-score 0 \
  -j "$THREADS" all

DRAM-v.py annotate \
  -i "$OUT/virsorter_prepare/for-dramv/final-viral-combined-for-dramv.fa" \
  -v "$OUT/virsorter_prepare/for-dramv/viral-affi-contigs-for-dramv.tab" \
  -o "$OUT/dramv_result" \
  --threads "$THREADS"

DRAM-v.py distill \
  -i "$OUT/dramv_result/annotations.tsv" \
  -o "$OUT/dramv_distill"

# The original notes identify candidate AMGs from annotations.tsv using amg_flags
# containing M/K/E. Preserve the exact downstream filtering script if available.

# --- Host prediction ---
iphop predict \
  --fa_file "$VOTU" \
  --db_dir "$IPHOP_DB" \
  --out_dir "$OUT/iphop"

# --- Abundance mapping ---
# Build the index once:
bowtie2-build "$VOTU" "$OUT/vOTU_bowtie2"

cat <<'ABUNDANCE_USAGE'
For each DNA-virome sample, run:

bowtie2 -x <OUT>/vOTU_bowtie2 \
  -1 <sample.R1_trimmed.fq.gz> \
  -2 <sample.R2_trimmed.fq.gz> \
  -S <sample.sam> \
  --threads 36 --sensitive --no-unal

The supplied source notes end at the Bowtie2 mapping step; the exact SAM/BAM-to-abundance calculation used for the final manuscript should be added here from the actual downstream script.
ABUNDANCE_USAGE
