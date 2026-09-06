#!/usr/bin/env Rscript

# Reajuste reproduzível dos modelos congelados. Execute com: Rscript --vanilla scripts/run_frozen_models.R

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg)) sub("^--file=", "", file_arg[[1]]) else "scripts/run_frozen_models.R"
project_root <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)

source(file.path(project_root, "R", "00_config.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "01_dependencies.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "02_import_prepare.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "07_frozen_models.R"), local = .GlobalEnv)

status <- check_dependencies(write_log = TRUE, fail = TRUE)
raw <- import_prognostic_data()
cohort <- prepare_prognostic_data(raw)
cohort_audit <- write_cohort_audit_outputs(cohort, raw_data = raw)
results <- run_frozen_models(cohort)
write_frozen_outputs(results, cohort)

stopifnot(
  nrow(cohort) == 615L,
  sum(cohort$delta_cat == 1L) == 317L,
  sum(cohort$delta_cat == 0L) == 298L,
  ncol(results$design) - 1L == 19L,
  qr(results$design)$rank == 20L,
  isTRUE(cohort_audit$model_identity$mesmas_linhas[[1]]),
  isTRUE(results$input_identity$same_rows_and_columns[[1]]),
  isTRUE(results$models$logistic$converged),
  all(is.finite(stats::coef(results$models$linear))),
  all(is.finite(stats::coef(results$models$logistic))),
  all(results$equivalence$equivalent)
)

verification <- c(
  "Tarefa 03 — verificação dos modelos congelados",
  paste("data_execucao:", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  paste("n:", nrow(cohort)),
  paste("eventos:", sum(cohort$delta_cat == 1L)),
  paste("nao_eventos:", sum(cohort$delta_cat == 0L)),
  paste("parametros_preditivos:", ncol(results$design) - 1L),
  paste("colunas_com_intercepto:", ncol(results$design)),
  paste("posto_linear:", results$rank$rank[results$rank$model == "linear"]),
  paste("posto_logistico:", results$rank$rank[results$rank$model == "logistic"]),
  paste("mesmas_linhas_e_colunas_preditoras:", results$input_identity$same_rows_and_columns[[1]]),
  paste("convergencia_logistica:", results$models$logistic$converged),
  paste("coeficientes_finitos:", all(is.finite(stats::coef(results$models$logistic)))),
  paste("equivalencia_metricas:", all(results$equivalence$equivalent)),
  paste("observacoes_influentes_linear:", sum(results$residual_linear$influential_any)),
  paste("observacoes_influentes_logistica:", sum(results$residual_logistic$influential_any)),
  paste("selecao_p_valor_stepwise_splines_interacoes:", "FALSE FALSE FALSE FALSE"),
  "Nenhuma observação influente foi excluída automaticamente.",
  "Nenhum texto ou objeto de progressão foi introduzido."
)
writeLines(verification, file.path(RESULTS_DIRS[["logs"]], "frozen_models_verification.txt"))
writeLines(capture.output(sessionInfo()), file.path(RESULTS_DIRS[["logs"]], "frozen_models_session_info.txt"))

cat("Tarefa 03 concluída com asserções aprovadas.\n")
cat("Coorte:", nrow(cohort), "participantes; eventos / não eventos:",
    sum(cohort$delta_cat == 1L), "/", sum(cohort$delta_cat == 0L), "\n")
cat("Matriz:", ncol(results$design), "colunas; posto:", qr(results$design)$rank, "\n")
