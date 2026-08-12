#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 5) {
  stop("Usage: Rscript 03_score_filter.R virsorter2.tsv genomad.tsv deepvirfinder.tsv vibrant.tsv output.tsv")
}

vs2 <- read.delim(args[1], stringsAsFactors = FALSE, check.names = FALSE)
gn  <- read.delim(args[2], stringsAsFactors = FALSE, check.names = FALSE)
dvf <- read.delim(args[3], stringsAsFactors = FALSE, check.names = FALSE)
vib <- read.delim(args[4], stringsAsFactors = FALSE, check.names = FALSE)

required <- list(
  virsorter2 = c("raw_id", "max_score"),
  genomad = c("raw_id", "score"),
  deepvirfinder = c("raw_id", "score", "pvalue"),
  vibrant = c("raw_id")
)
inputs <- list(virsorter2 = vs2, genomad = gn, deepvirfinder = dvf, vibrant = vib)
for (nm in names(required)) {
  missing_cols <- setdiff(required[[nm]], colnames(inputs[[nm]]))
  if (length(missing_cols) > 0) stop(nm, " missing columns: ", paste(missing_cols, collapse = ", "))
}

vs2$vs2_score <- ifelse(vs2$max_score >= 0.9, 1,
                         ifelse(vs2$max_score >= 0.5, 0.5, 0))

gn$genomad_score <- ifelse(gn$score >= 0.8, 1,
                            ifelse(gn$score >= 0.7, 0.5, 0))

dvf$dvf_score <- ifelse(dvf$pvalue < 0.05 & dvf$score >= 0.9, 1,
                         ifelse(dvf$pvalue < 0.05 & dvf$score >= 0.7, 0.5, 0))

vib$vibrant_score <- 1

keep_cols <- function(x, cols) x[, cols, drop = FALSE]
merged <- Reduce(
  function(x, y) merge(x, y, by = "raw_id", all = TRUE),
  list(
    keep_cols(vs2, c("raw_id", "vs2_score")),
    keep_cols(gn, c("raw_id", "genomad_score")),
    keep_cols(dvf, c("raw_id", "dvf_score")),
    keep_cols(vib, c("raw_id", "vibrant_score"))
  )
)

score_cols <- c("vs2_score", "genomad_score", "dvf_score", "vibrant_score")
for (x in score_cols) merged[[x]][is.na(merged[[x]])] <- 0
merged$integrated_score <- rowSums(merged[, score_cols])
merged$retain <- merged$integrated_score >= 1

write.table(merged, args[5], sep = "\t", quote = FALSE, row.names = FALSE)
