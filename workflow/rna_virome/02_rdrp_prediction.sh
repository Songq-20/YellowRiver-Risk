#!/usr/bin/env bash
set -euo pipefail

PROTEINS=${1:?Prodigal protein FASTA required}
SAMPLE=${2:?sample ID required}
OUT=${3:?output directory required}
THREADS=${THREADS:-30}
RDRP_HMM=${RDRP_HMM:?Set RDRP_HMM}
LUCAPROT_SRC=${LUCAPROT_SRC:?Set LUCAPROT_SRC}
PALM_ANNOT_DIR=${PALM_ANNOT_DIR:?Set PALM_ANNOT_DIR}

mkdir -p "$OUT"/{hmmsearch,lucaprot_csv,lucaprot_emb,palm,tmp}

hmmsearch --cpu "$THREADS" -E 1 \
  --tblout "$OUT/hmmsearch/${SAMPLE}.tbl" \
  "$RDRP_HMM" "$PROTEINS"

python "$LUCAPROT_SRC/predict_many_samples.py" \
  --fasta_file "$PROTEINS" \
  --save_file "$OUT/lucaprot_csv/${SAMPLE}.csv" \
  --emb_dir "$OUT/lucaprot_emb/${SAMPLE}" \
  --truncation_seq_length 4096 \
  --dataset_name rdrp_40_extend \
  --dataset_type protein \
  --task_type binary_class \
  --model_type sefn \
  --time_str 20230201140320 \
  --step 100000 \
  --threshold 0.5 \
  --print_per_number 10 \
  --gpu_id 0

# Combine all HMM-positive proteins and LucaProt-positive proteins (prob = 1)
# into "$OUT/palm/pre_palm.faa" before running Palm_annot.

PREPALM="$OUT/palm/pre_palm.faa"
if [[ -s "$PREPALM" ]]; then
  python "$PALM_ANNOT_DIR/py/palm_annot.py" \
    --input "$PREPALM" --seqtype aa \
    --rdrp "$OUT/palm/pre_palm_out.faa" \
    --fev "$OUT/palm/pre_palm_out.fev" \
    --tmpdir "$OUT/tmp" --threads "$THREADS"

  python "$PALM_ANNOT_DIR/py/fev2tsv.py" \
    --input "$OUT/palm/pre_palm_out.fev" \
    --output "$OUT/palm/pre_palm_out.tsv"
else
  echo "Palm_annot skipped because $PREPALM is not yet available." >&2
fi

# Source-note criterion: retain Palm_annot rows for which 'score' has a value.
