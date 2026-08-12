#!/usr/bin/env bash
set -euo pipefail

VOTU=${1:?vOTU FASTA required}
OUT=${2:?output directory required}
THREADS=${THREADS:-16}
IMGVR_BLAST_DB=${IMGVR_BLAST_DB:?Set IMGVR_BLAST_DB}
REFSEQ_VIRAL_BLAST_DB=${REFSEQ_VIRAL_BLAST_DB:?Set REFSEQ_VIRAL_BLAST_DB}
VCONTACT2_DB=${VCONTACT2_DB:-ProkaryoticViralRefSeq201-Merged}
VPF_CLASS_BIN=${VPF_CLASS_BIN:?Set VPF_CLASS_BIN}
VPF_CLASS_INDEX=${VPF_CLASS_INDEX:?Set VPF_CLASS_INDEX}

mkdir -p "$OUT" "$OUT/vpf_class"

blastn -task megablast \
  -query "$VOTU" -db "$IMGVR_BLAST_DB" \
  -num_threads "$THREADS" \
  -out "$OUT/vOTU_vs_IMGVR.tsv" \
  -outfmt '6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore qlen slen' \
  -perc_identity 90 -qcov_hsp_perc 75

blastn -task megablast \
  -query "$VOTU" -db "$REFSEQ_VIRAL_BLAST_DB" \
  -num_threads "$THREADS" \
  -out "$OUT/vOTU_vs_RefSeqViral.tsv" \
  -outfmt '6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore qlen slen' \
  -perc_identity 90 -qcov_hsp_perc 75

prodigal -p meta -q -m -i "$VOTU" \
  -a "$OUT/vOTU.faa" -d "$OUT/vOTU.genes.fna" -o "$OUT/vOTU.gff" -f gff

vcontact2_gene2genome \
  -p "$OUT/vOTU.faa" \
  -o "$OUT/vcontact2_gene2genome.csv" \
  -s Prodigal-FAA

vcontact2 \
  --raw-proteins "$OUT/vOTU.faa" \
  --rel-mode Diamond \
  --proteins-fp "$OUT/vcontact2_gene2genome.csv" \
  --db "$VCONTACT2_DB" \
  --pcs-mode MCL \
  --vcs-mode ClusterONE \
  --output-dir "$OUT/vcontact2" \
  -t "$THREADS"

# VPF-Class
"$VPF_CLASS_BIN" \
  --data-index "$VPF_CLASS_INDEX" \
  -i "$VOTU" \
  -o "$OUT/vpf_class"

# Recorded post-filtering thresholds:
# family/genus: membership_ratio > 0.5 and confidence_score > 0.75
# baltimore3.tsv: membership_ratio > 0.2 and confidence_score > 0.2
