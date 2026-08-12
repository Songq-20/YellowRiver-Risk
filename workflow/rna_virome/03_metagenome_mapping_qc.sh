#!/usr/bin/env bash
set -euo pipefail

RDRP_ORF_NT=${1:?candidate RdRp ORF nucleotide FASTA required}
MG_SAMPLE_TSV=${2:?TSV with columns sample_id R1 R2 required}
OUT=${3:?output directory required}
THREADS=${THREADS:-30}
mkdir -p "$OUT"/{index,sam,bam}

bowtie2-build "$RDRP_ORF_NT" "$OUT/index/rdrp_orf_nt"

tail -n +2 "$MG_SAMPLE_TSV" | while IFS=$'\t' read -r sample r1 r2 rest; do
  bowtie2 \
    -x "$OUT/index/rdrp_orf_nt" \
    -1 "$r1" -2 "$r2" \
    -S "$OUT/sam/${sample}.sam" \
    --threads "$THREADS" --sensitive --no-unal

  samtools view -@ "$THREADS" -q 30 -F 0x08 -b -f 0x2 "$OUT/sam/${sample}.sam" \
    | samtools sort -@ "$THREADS" -o "$OUT/bam/${sample}.bam"
done

coverm contig \
  --bam-files "$OUT"/bam/*.bam \
  -t "$THREADS" \
  --methods covered_fraction \
  -o "$OUT/rdrp_contig_2_metag_coverage.tsv"

coverm contig \
  --bam-files "$OUT"/bam/*.bam \
  -t "$THREADS" \
  --methods trimmed_mean \
  -o "$OUT/rdrp_contig_2_metag_mean.tsv"

