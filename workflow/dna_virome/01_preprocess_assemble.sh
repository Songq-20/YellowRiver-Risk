#!/usr/bin/env bash
set -euo pipefail

R1=${1:?R1 required}
R2=${2:?R2 required}
SAMPLE=${3:?sample ID required}
OUT=${4:?output directory required}
THREADS=${THREADS:-30}
ADAPTERS_FA=${ADAPTERS_FA:?Set ADAPTERS_FA}

mkdir -p "$OUT/trimmed" "$OUT/assembly" "$OUT/contigs_5kb"

trimmomatic PE -threads "$THREADS" \
  "$R1" "$R2" \
  "$OUT/trimmed/${SAMPLE}.R1.trimmed.fq.gz" "$OUT/trimmed/${SAMPLE}.R1.unpaired.fq.gz" \
  "$OUT/trimmed/${SAMPLE}.R2.trimmed.fq.gz" "$OUT/trimmed/${SAMPLE}.R2.unpaired.fq.gz" \
  "ILLUMINACLIP:${ADAPTERS_FA}:2:30:10" LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36

megahit \
  -1 "$OUT/trimmed/${SAMPLE}.R1.trimmed.fq.gz" \
  -2 "$OUT/trimmed/${SAMPLE}.R2.trimmed.fq.gz" \
  -t "$THREADS" \
  --out-prefix "$SAMPLE" \
  --out-dir "$OUT/assembly/${SAMPLE}"

ASSEMBLY="$OUT/assembly/${SAMPLE}/${SAMPLE}.contigs.fa"

# Remove description text after the first whitespace and add a sample prefix.
seqkit replace -p '\s.+' "$ASSEMBLY" \
  | seqkit replace -p '^' -r "${SAMPLE}_" \
  | seqkit seq -m 5000 \
  > "$OUT/contigs_5kb/${SAMPLE}.5kb.fa"
