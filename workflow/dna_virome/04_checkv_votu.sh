#!/usr/bin/env bash
set -euo pipefail

INPUT=${1:?candidate viral contigs FASTA required}
OUT=${2:?output directory required}
THREADS=${THREADS:-30}
CHECKV_DB=${CHECKV_DB:?Set CHECKV_DB}
ANICALC=${ANICALC:?Set ANICALC to anicalc.py}
ANICLUST=${ANICLUST:?Set ANICLUST to aniclust.py}

mkdir -p "$OUT/checkv" "$OUT/votu"

checkv end_to_end "$INPUT" "$OUT/checkv" -t "$THREADS" -d "$CHECKV_DB"

# Retain sequences with virus_gene >= 1 from the CheckV result before clustering.
FILTERED_FASTA=${FILTERED_FASTA:-"$OUT/virus_gene_ge1.fa"}
if [[ ! -s "$FILTERED_FASTA" ]]; then
  echo "Missing $FILTERED_FASTA. Generate it from the CheckV output using the virus_gene >= 1 criterion." >&2
  exit 2
fi

makeblastdb -in "$FILTERED_FASTA" -dbtype nucl -out "$OUT/votu/blastdb"
blastn \
  -query "$FILTERED_FASTA" \
  -db "$OUT/votu/blastdb" \
  -outfmt '6 std qlen slen' \
  -max_target_seqs 10000 \
  -out "$OUT/votu/all_vs_all.tsv" \
  -num_threads "$THREADS"

if [[ ! -f "$ANICALC" || ! -f "$ANICLUST" ]]; then
  echo "Cannot find ANICALC or ANICLUST helper script." >&2
  exit 3
fi

python3 "$ANICALC" -i "$OUT/votu/all_vs_all.tsv" -o "$OUT/votu/pairwise_ani.tsv"
python3 "$ANICLUST" \
  --fna "$FILTERED_FASTA" \
  --ani "$OUT/votu/pairwise_ani.tsv" \
  --out "$OUT/votu/clusters.tsv" \
  --min_ani 95 --min_tcov 85 --min_qcov 0

awk '{print $1}' "$OUT/votu/clusters.tsv" > "$OUT/votu/representatives.list"
seqkit grep -n -f "$OUT/votu/representatives.list" "$FILTERED_FASTA" -o "$OUT/vOTU.fa"
