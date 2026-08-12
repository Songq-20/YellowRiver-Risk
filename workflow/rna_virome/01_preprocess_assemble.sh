#!/usr/bin/env bash
set -euo pipefail

R1=${1:?R1 required}
R2=${2:?R2 required}
SAMPLE=${3:?sample ID required}
OUT=${4:?output directory required}
THREADS=${THREADS:-30}
ADAPTERS_FA=${ADAPTERS_FA:?Set ADAPTERS_FA}

SORTMERNA_RFAM_58S=${SORTMERNA_RFAM_58S:?Set SORTMERNA_RFAM_58S}
SORTMERNA_RFAM_5S=${SORTMERNA_RFAM_5S:?Set SORTMERNA_RFAM_5S}
SORTMERNA_SILVA_ARC_16S=${SORTMERNA_SILVA_ARC_16S:?Set SORTMERNA_SILVA_ARC_16S}
SORTMERNA_SILVA_ARC_23S=${SORTMERNA_SILVA_ARC_23S:?Set SORTMERNA_SILVA_ARC_23S}
SORTMERNA_SILVA_BAC_16S=${SORTMERNA_SILVA_BAC_16S:?Set SORTMERNA_SILVA_BAC_16S}
SORTMERNA_SILVA_BAC_23S=${SORTMERNA_SILVA_BAC_23S:?Set SORTMERNA_SILVA_BAC_23S}
SORTMERNA_SILVA_EUK_18S=${SORTMERNA_SILVA_EUK_18S:?Set SORTMERNA_SILVA_EUK_18S}
SORTMERNA_SILVA_EUK_28S=${SORTMERNA_SILVA_EUK_28S:?Set SORTMERNA_SILVA_EUK_28S}

mkdir -p "$OUT"/{trimmed,sortmerna,assembly,contigs_750}

trimmomatic PE -threads "$THREADS" \
  "$R1" "$R2" \
  "$OUT/trimmed/${SAMPLE}.R1_trimmed.fq.gz" "$OUT/trimmed/${SAMPLE}.R1_trimmed_U.fq.gz" \
  "$OUT/trimmed/${SAMPLE}.R2_trimmed.fq.gz" "$OUT/trimmed/${SAMPLE}.R2_trimmed_U.fq.gz" \
  "ILLUMINACLIP:${ADAPTERS_FA}:2:30:10" LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36

sortmerna \
  --ref "$SORTMERNA_RFAM_58S" \
  --ref "$SORTMERNA_RFAM_5S" \
  --ref "$SORTMERNA_SILVA_ARC_16S" \
  --ref "$SORTMERNA_SILVA_ARC_23S" \
  --ref "$SORTMERNA_SILVA_BAC_16S" \
  --ref "$SORTMERNA_SILVA_BAC_23S" \
  --ref "$SORTMERNA_SILVA_EUK_18S" \
  --ref "$SORTMERNA_SILVA_EUK_28S" \
  --fastx -a 15 -v --log \
  --reads "$OUT/trimmed/${SAMPLE}.R1_trimmed.fq.gz" \
  --reads "$OUT/trimmed/${SAMPLE}.R2_trimmed.fq.gz" \
  --aligned "$OUT/sortmerna/${SAMPLE}.align" \
  --other "$OUT/sortmerna/${SAMPLE}.unalign" \
  --paired_in --out2 \
  --workdir "$OUT/sortmerna/${SAMPLE}.work"

# SortMeRNA naming can vary by version. Set these to the actual paired unaligned outputs.
UNALIGNED_R1=${UNALIGNED_R1:-"$OUT/sortmerna/${SAMPLE}.unalign_fwd.fq.gz"}
UNALIGNED_R2=${UNALIGNED_R2:-"$OUT/sortmerna/${SAMPLE}.unalign_rev.fq.gz"}

megahit \
  -1 "$UNALIGNED_R1" \
  -2 "$UNALIGNED_R2" \
  -t "$THREADS" \
  --out-prefix "${SAMPLE}_megahit" \
  --out-dir "$OUT/assembly/${SAMPLE}"

ASSEMBLY="$OUT/assembly/${SAMPLE}/${SAMPLE}_megahit.contigs.fa"

# Retain contigs >=750 bp.
seqkit seq -m 750 "$ASSEMBLY" > "$OUT/contigs_750/${SAMPLE}.750.fa"

prodigal -p meta -q -m \
  -i "$OUT/contigs_750/${SAMPLE}.750.fa" \
  -d "$OUT/contigs_750/${SAMPLE}.ORF_nt.fna" \
  -a "$OUT/contigs_750/${SAMPLE}.ORF_aa.faa" \
  -o "$OUT/contigs_750/${SAMPLE}.ORF.gff"
