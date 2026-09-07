#!/usr/bin/env Rscript

# Execução reproduzível da Tarefa 10. Execute com:
# Rscript --vanilla scripts/run_sensitivity_analysis.R

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg)) sub("^--file=", "", file_arg[[1]]) else "scripts/run_sensitivity_analysis.R"
project_root <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)

source(file.path(project_root, "R", "00_config.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "01_dependencies.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "02_import_prepare.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "03_metrics_calibration.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "07_frozen_models.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "12_sensitivity_analysis.R"), local = .GlobalEnv)

check_dependencies(write_log = TRUE, fail = TRUE)
raw <- import_prognostic_data()
cohort <- prepare_prognostic_data(raw)
main_results <- run_frozen_models(cohort)
sensitivity <- run_sensitivity_analysis(cohort, main_results, write_outputs = TRUE)

stopifnot(
  nrow(cohort) == 615L,
  sensitivity$n_primary == 615L,
  all(c(81L, 174L, 401L) %in% cohort$id),
  all(cohort$correcao_colete[match(c(81L, 174L, 401L), cohort$id)] > 100),
  all(sensitivity$criteria$threshold > 0),
  all(sensitivity$exclusions$n_excluded >= 0),
  all(sensitivity$metrics$n[sensitivity$metrics$scope == "coorte_completa_615"] == 615L),
  nrow(sensitivity$strata) > 0L,
  all(sensitivity$strata$n > 0L),
  nrow(sensitivity$cobb_target$metrics) == 2L
)

cat("Tarefa 10 concluída com asserções aprovadas.\n")
cat("Coorte principal:", sensitivity$n_primary, "participantes; influentes linear/logístico:",
    length(sensitivity$flagged_linear), "/", length(sensitivity$flagged_logistic), "\n")
cat("Hipercorreções mantidas na principal:", paste(sensitivity$hyper_ids, collapse = ", "), "\n")
