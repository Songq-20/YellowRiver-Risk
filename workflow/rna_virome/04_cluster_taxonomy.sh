#!/usr/bin/env bash
set -euo pipefail

RDRP_AA=${1:?quality-checked RdRp protein FASTA required}
RDRP_CONTIG_NT=${2:?corresponding RdRp contig nucleotide FASTA required}
OUT=${3:?output directory required}
THREADS=${THREADS:-10}

RVMT_RDRP_DMND=${RVMT_RDRP_DMND:?Set RVMT_RDRP_DMND}
TARA_RDRP_DMND=${TARA_RDRP_DMND:?Set TARA_RDRP_DMND}
LUCA_RDRP_DMND=${LUCA_RDRP_DMND:?Set LUCA_RDRP_DMND}
NR_DMND=${NR_DMND:?Set NR_DMND}
RVMT_CONTIG_BLAST_DB=${RVMT_CONTIG_BLAST_DB:?Set RVMT_CONTIG_BLAST_DB}
TARA_CONTIG_BLAST_DB=${TARA_CONTIG_BLAST_DB:?Set TARA_CONTIG_BLAST_DB}
IMGVR_RNA_BLAST_DB=${IMGVR_RNA_BLAST_DB:?Set IMGVR_RNA_BLAST_DB}
REFSEQ_RNA_VIRAL_BLAST_DB=${REFSEQ_RNA_VIRAL_BLAST_DB:?Set REFSEQ_RNA_VIRAL_BLAST_DB}

mkdir -p "$OUT"/{cluster,diamond,blastn}

# RdRp OTUs: 90% amino-acid identity, as documented.
cd-hit -i "$RDRP_AA" \
  -o "$OUT/cluster/rdrp_orf_OTU_quality_check.faa" \
  -c 0.9 -d 0

QUERY="$OUT/cluster/rdrp_orf_OTU_quality_check.faa"

for pair in \
  "RVMT:$RVMT_RDRP_DMND" \
  "TaraOcean:$TARA_RDRP_DMND" \
  "LucaProt:$LUCA_RDRP_DMND" \
  "NR:$NR_DMND"
do
  name=${pair%%:*}
  db=${pair#*:}
  diamond blastp \
    --db "$db" --query "$QUERY" \
    --out "$OUT/diamond/${name}.tsv" \
    -f 6 qseqid sseqid pident length qcovhsp mismatch gapopen qstart qend sstart send evalue bitscore \
    --sensitive -k 1 --max-target-seqs 1 -p "$THREADS"
done

blastn -query "$RDRP_CONTIG_NT" -db "$RVMT_CONTIG_BLAST_DB" \
  -task megablast \
  -outfmt '7 qseqid sseqid pident length qcovs mismatch gapopen qstart qend sstart send evalue bitscore' \
  -max_target_seqs 1 -out "$OUT/blastn/RVMT.tsv" -num_threads "$THREADS"

blastn -query "$RDRP_CONTIG_NT" -db "$TARA_CONTIG_BLAST_DB" \
  -task megablast \
  -outfmt '7 qseqid sseqid pident length qcovs mismatch gapopen qstart qend sstart send evalue bitscore' \
  -max_target_seqs 1 -out "$OUT/blastn/TaraOcean.tsv" -num_threads "$THREADS"

blastn -query "$RDRP_CONTIG_NT" -db "$IMGVR_RNA_BLAST_DB" \
  -task megablast \
  -outfmt '7 qseqid sseqid pident length qcovs mismatch gapopen qstart qend sstart send evalue bitscore' \
  -max_target_seqs 1 -out "$OUT/blastn/IMGVR.tsv" -num_threads "$THREADS"

blastn -query "$RDRP_CONTIG_NT" -db "$REFSEQ_RNA_VIRAL_BLAST_DB" \
  -task megablast \
  -outfmt '7 qseqid sseqid pident length qcovs mismatch gapopen qstart qend sstart send evalue bitscore' \
  -max_target_seqs 1 -out "$OUT/blastn/RefSeq_RNA_viral.tsv" -num_threads "$THREADS"

if [[ -n "${VITAP_DIR:-}" && -n "${VITAP_DB:-}" ]]; then
  "$VITAP_DIR/scripts/VITAP" assignment \
    -i "$RDRP_CONTIG_NT" -d "$VITAP_DB" -o "$OUT/vitap" -p "$THREADS"
fi

