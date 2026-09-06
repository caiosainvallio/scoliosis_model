#!/usr/bin/env Rscript

# Auditoria da coorte analítica. Execute com: Rscript --vanilla scripts/run_cohort_audit.R

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg)) sub("^--file=", "", file_arg[[1]]) else "scripts/run_cohort_audit.R"
project_root <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)

source(file.path(project_root, "R", "00_config.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "02_import_prepare.R"), local = .GlobalEnv)

raw <- import_prognostic_data()
cohort <- prepare_prognostic_data(raw)
outputs <- write_cohort_audit_outputs(cohort, raw_data = raw)
design_matrix <- stats::model.matrix(stats::reformulate(MODEL_PREDICTORS), data = cohort)
design_rank <- qr(design_matrix)$rank

stopifnot(
  nrow(raw) == 621L,
  length(unique(raw$id)) == 621L,
  nrow(cohort) == 615L,
  length(unique(cohort$id)) == 615L,
  sum(cohort$delta_cat == 1L) == 317L,
  sum(cohort$delta_cat == 0L) == 298L,
  identical(sort(outputs$flow$n_restante), c(615L, 618L, 621L)),
  all(outputs$pair_audit$identico),
  all(outputs$derivation_check$aprovado),
  isTRUE(outputs$model_identity$mesmas_linhas[[1]]),
  outputs$model_identity$n_modelo_linear[[1]] == 615L,
  outputs$model_identity$n_modelo_logistico[[1]] == 615L,
  ncol(design_matrix) == 20L,
  design_rank == 20L,
  all(cohort[cohort$id %in% c(81, 174, 401), "correcao_colete"] > 100)
)

verification_lines <- c(
  "Auditoria executável da coorte prognóstica",
  paste("arquivo:", normalizePath(DATA_FILE, mustWork = TRUE)),
  paste("aba:", DATA_SHEET),
  paste("registros_brutos:", nrow(raw)),
  paste("ids_unicos_pos_deduplicacao:", outputs$flow$n_restante[[2]]),
  paste("casos_completos_finais:", nrow(cohort)),
  paste("eventos_melhora:", sum(cohort$delta_cat == 1L)),
  paste("nao_eventos:", sum(cohort$delta_cat == 0L)),
  paste("pares_identicos_confirmados:", nrow(outputs$pair_audit)),
  paste("ids_duplicata_excluidos:", paste(attr(cohort, "cohort_audit")$duplicate_ids, collapse = ", ")),
  paste("ids_lenke_ausente_excluidos:", paste(attr(cohort, "cohort_audit")$incomplete_ids, collapse = ", ")),
  paste("linhas_modelo_linear:", outputs$model_identity$n_modelo_linear[[1]]),
  paste("linhas_modelo_logistico:", outputs$model_identity$n_modelo_logistico[[1]]),
  paste("mesmas_linhas_nos_modelos:", outputs$model_identity$mesmas_linhas[[1]]),
  paste("parametros_preditivos:", ncol(design_matrix) - 1L),
  paste("posto_matriz_com_intercepto:", design_rank),
  paste("derivacoes_independentes_aprovadas:", all(outputs$derivation_check$aprovado)),
  paste("sha256:", outputs$metadata$sha256)
)
writeLines(verification_lines, file.path(RESULTS_DIRS[["logs"]], "cohort_verification_summary.txt"))

cat("Auditoria da coorte concluída com asserções aprovadas.\n")
cat("Registros brutos:", nrow(raw), "\n")
cat("IDs únicos após deduplicação:", outputs$flow$n_restante[[2]], "\n")
cat("Casos completos finais:", nrow(cohort), "\n")
cat("Eventos / não eventos:", sum(cohort$delta_cat == 1L), "/", sum(cohort$delta_cat == 0L), "\n")
cat("Empates na maior curva basal:", sum(cohort$empate_cobb_inicial), "\n")
cat("SHA-256:", outputs$metadata$sha256, "\n")
