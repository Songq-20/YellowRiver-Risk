#!/usr/bin/env bash
set -euo pipefail

# 16S rRNA amplicon workflow used in the study.
#
# Usage:
#   USEARCH_BIN=/path/to/usearch \
#   SILVA_ALIGN=/path/to/silva.nr_v138.align \
#   SILVA_TAX=/path/to/silva.nr_v138.tax \
#   bash 16S_zOTU_workflow.sh R1.fastq R2.fastq output_dir
#
# Required software: USEARCH, SeqKit, mothur

R1=${1:?R1 FASTQ required}
R2=${2:?R2 FASTQ required}
OUT=${3:?output directory required}
THREADS=${THREADS:-10}
USEARCH_BIN=${USEARCH_BIN:?Set USEARCH_BIN}
SILVA_ALIGN=${SILVA_ALIGN:?Set SILVA_ALIGN}
SILVA_TAX=${SILVA_TAX:?Set SILVA_TAX}

mkdir -p "$OUT"

# Primer sequences documented for the V4-V5 amplicon:
# Forward: GTGCCAGCMGCCGCGGTAA  (19 nt)
# Reverse: CCGTCAATTCMTTTRAGTTT (20 nt)

# 1. Merge paired-end reads.
"$USEARCH_BIN" -fastq_mergepairs "$R1" \
  -reverse "$R2" \
  -relabel @ \
  -fastqout "$OUT/merged_f.fastq"

seqkit stats "$OUT/merged_f.fastq"

# 2. Remove primer-length sequence from both ends.
# These values reproduce the command in the final analysis notes.
"$USEARCH_BIN" -fastx_truncate "$OUT/merged_f.fastq" \
  -stripleft 19 \
  -stripright 20 \
  -fastqout "$OUT/stripped.fq"

seqkit stats "$OUT/stripped.fq"

# 3. Quality filtering using a maximum expected error of 1.0.
"$USEARCH_BIN" -fastq_filter "$OUT/stripped.fq" \
  -fastq_maxee 1.0 \
  -fastaout "$OUT/filtered.fa"

seqkit stats "$OUT/filtered.fa"

# 4. Summarize sequence lengths before length filtering.
mothur <<MOTHUR_SUMMARY_BEFORE
summary.seqs(fasta=$OUT/filtered.fa,processors=$THREADS)
quit()
MOTHUR_SUMMARY_BEFORE

# 5. Retain the length interval used in the final workflow.
# NOTE: the supplied analysis notes explicitly execute 367-375 bp.
seqkit seq -m 367 -M 375 "$OUT/filtered.fa" > "$OUT/filtered_length.fa"

seqkit stats "$OUT/filtered_length.fa"

mothur <<MOTHUR_SUMMARY_AFTER
summary.seqs(fasta=$OUT/filtered_length.fa,processors=$THREADS)
quit()
MOTHUR_SUMMARY_AFTER

# 6. Dereplicate and denoise to zero-radius OTUs (zOTUs).
"$USEARCH_BIN" -fastx_uniques "$OUT/filtered_length.fa" \
  -sizeout \
  -fastaout "$OUT/uniques.fa"

"$USEARCH_BIN" -unoise3 "$OUT/uniques.fa" \
  -zotus "$OUT/zotus.fa"

# 7. Generate the abundance table.
# The final supplied workflow maps the merged reads directly to zotus.fa.
"$USEARCH_BIN" -otutab "$OUT/merged_f.fastq" \
  -otus "$OUT/zotus.fa" \
  -otutabout "$OUT/zotutab_raw.txt"

# 8. Taxonomic classification with SILVA v138 in mothur.
mothur <<MOTHUR_CLASSIFY
classify.seqs(fasta=$OUT/zotus.fa,template=$SILVA_ALIGN,taxonomy=$SILVA_TAX,cutoff=80,processors=$THREADS)
quit()
MOTHUR_CLASSIFY
