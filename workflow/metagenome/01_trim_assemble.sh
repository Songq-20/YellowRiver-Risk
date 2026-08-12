#!/usr/bin/env bash
set -euo pipefail

# Trimmomatic -> MEGAHIT -> retain contigs >=1 kb
# Usage: ADAPTERS_FA=/path/TruSeq3-PE.fa bash 01_trim_assemble.sh R1.fq.gz R2.fq.gz SAMPLE OUTDIR

R1=${1:?R1 FASTQ required}
R2=${2:?R2 FASTQ required}
SAMPLE=${3:?sample ID required}
OUT=${4:?output directory required}
THREADS=${THREADS:-60}
ADAPTERS_FA=${ADAPTERS_FA:?Set ADAPTERS_FA}

mkdir -p "$OUT/trimmed" "$OUT/assembly" "$OUT/contigs_1k"

trimmomatic PE -threads 4 \
  "$R1" "$R2" \
  "$OUT/trimmed/${SAMPLE}.R1_T.fq.gz" "$OUT/trimmed/${SAMPLE}.R1_U.fq.gz" \
  "$OUT/trimmed/${SAMPLE}.R2_T.fq.gz" "$OUT/trimmed/${SAMPLE}.R2_U.fq.gz" \
  "ILLUMINACLIP:${ADAPTERS_FA}:2:30:10" LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36

megahit \
  -1 "$OUT/trimmed/${SAMPLE}.R1_T.fq.gz" \
  -2 "$OUT/trimmed/${SAMPLE}.R2_T.fq.gz" \
  -t "$THREADS" \
  --out-prefix "$SAMPLE" \
  --out-dir "$OUT/assembly/${SAMPLE}"

seqkit seq -m 1000 \
  "$OUT/assembly/${SAMPLE}/${SAMPLE}.contigs.fa" \
  > "$OUT/contigs_1k/${SAMPLE}_1k.fa"
