#!/usr/bin/env Rscript

# Execução da Tarefa 08. Execute com: Rscript --vanilla scripts/run_cart_nested.R

script_args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", script_args, value = TRUE)
script_path <- if (length(file_arg)) sub("^--file=", "", file_arg[[1]]) else "scripts/run_cart_nested.R"
project_root <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)

source(file.path(project_root, "R", "00_config.R"), local = .GlobalEnv)
ensure_output_dirs()
source(file.path(project_root, "R", "01_dependencies.R"), local = .GlobalEnv)
status <- check_dependencies(
  required = c("readxl", "rpart"),
  relevant = unique(c(RELEVANT_PACKAGES, "rpart")),
  write_log = TRUE,
  fail = TRUE
)
source(file.path(project_root, "R", "02_import_prepare.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "03_metrics_calibration.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "10_cart_nested.R"), local = .GlobalEnv)

raw <- import_prognostic_data()
cohort <- prepare_prognostic_data(raw)
result <- run_cart_nested_analysis(cohort, ids = cohort$id, write_outputs = TRUE)

pooled <- result$metrics[result$metrics$scope == "pooled_external_repeated", , drop = FALSE]
cat("Tarefa 08 concluída: CART exploratória com validação aninhada.\n")
cat("Predições externas:", nrow(result$predictions), "\n")
cat("AUC externa agrupada:", format(pooled$auc, digits = 4), "\n")
cat("Brier externo agrupado:", format(pooled$brier_score, digits = 4), "\n")
cat("Log loss externo agrupado:", format(pooled$log_loss, digits = 4), "\n")
cat("Árvores sem divisão:", sum(result$tree_summaries$no_split), "de", nrow(result$tree_summaries), "\n")
cat("Nenhuma métrica da árvore ilustrativa em toda a coorte foi apresentada como externa.\n")
