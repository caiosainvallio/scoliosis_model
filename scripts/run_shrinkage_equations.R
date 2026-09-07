#!/usr/bin/env Rscript

# Execução da Tarefa 07.
args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg)) sub("^--file=", "", file_arg[[1]]) else "scripts/run_shrinkage_equations.R"
project_root <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)
source(file.path(project_root, "R", "00_config.R"), local = .GlobalEnv)
ensure_output_dirs()
source(file.path(project_root, "R", "01_dependencies.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "02_import_prepare.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "03_metrics_calibration.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "04_bootstrap_stability.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "07_frozen_models.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "08_internal_validation.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "09_shrinkage_equations.R"), local = .GlobalEnv)
check_dependencies(write_log = TRUE, fail = TRUE)
cohort <- prepare_prognostic_data(import_prognostic_data())
frozen_results <- run_frozen_models(cohort)
internal_file <- file.path(RESULTS_DIRS[["reduced_objects"]], "frozen_bootstrap_internal.rds")
if (!file.exists(internal_file)) stop("Objeto da Tarefa 06 não encontrado: ", internal_file)
internal <- readRDS(internal_file)
if (!identical(internal$metadata$n_original, nrow(cohort)) || !identical(internal$metadata$sample_size, nrow(cohort)))
  stop("O objeto da Tarefa 06 não corresponde à coorte de 615 participantes.")
analysis <- run_shrinkage_analysis(frozen_results, internal, cohort, FACTOR_LEVELS, internal)
write_shrinkage_outputs(analysis, cohort)
stopifnot(all(analysis$validation$passed), all(c(analysis$linear$shrinkage_factor, analysis$logistic$shrinkage_factor) >= 0),
  all(c(analysis$linear$shrinkage_factor, analysis$logistic$shrinkage_factor) <= 1),
  nrow(analysis$stability) == 2L * nrow(cohort), all(analysis$stability$n_valid == 2000L))
cat("Tarefa 07 concluída: shrinkage, equações, estabilidade e intervalos de predição produzidos.\n")
print(analysis$shrinkage_summary, row.names = FALSE)
print(analysis$validation, row.names = FALSE)
