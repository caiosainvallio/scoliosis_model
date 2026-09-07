#!/usr/bin/env Rscript

# Execução da Tarefa 09. Execute com:
# Rscript --vanilla scripts/run_flexible_modeling.R

script_args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", script_args, value = TRUE)
script_path <- if (length(file_arg)) sub("^--file=", "", file_arg[[1]]) else "scripts/run_flexible_modeling.R"
project_root <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)

source(file.path(project_root, "R", "00_config.R"), local = .GlobalEnv)
ensure_output_dirs()
source(file.path(project_root, "R", "01_dependencies.R"), local = .GlobalEnv)
check_dependencies(required = c("readxl"), relevant = RELEVANT_PACKAGES,
                   write_log = TRUE, fail = TRUE)
source(file.path(project_root, "R", "02_import_prepare.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "03_metrics_calibration.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "11_flexible_modeling.R"), local = .GlobalEnv)

raw <- import_prognostic_data()
cohort <- prepare_prognostic_data(raw)
result <- run_flexible_analysis(cohort, ids = cohort$id, write_outputs = TRUE)

pooled <- result$metrics[result$metrics$scope == "pooled_external_repeated", , drop = FALSE]
cat("Tarefa 09 concluída: modelagem flexível exploratória aninhada.\n")
for (family in unique(pooled$family)) {
  row <- pooled[pooled$family == family, , drop = FALSE]
  if (family == "continuous") {
    cat("Contínuo — R²:", format(row$r2, digits = 4),
        "RMSE:", format(row$rmse, digits = 4),
        "MAE:", format(row$mae, digits = 4), "\n")
  } else {
    cat("Logístico — AUC:", format(row$auc, digits = 4),
        "Brier:", format(row$brier_score, digits = 4),
        "Log loss:", format(row$log_loss, digits = 4), "\n")
  }
}
cat("Predições externas:", nrow(result$predictions), "\n")
cat("Auditoria de pré-processamento aprovada:", all(result$preprocessing_audit$approved), "\n")
cat("Ajustes globais foram usados somente para o apêndice exploratório.\n")
