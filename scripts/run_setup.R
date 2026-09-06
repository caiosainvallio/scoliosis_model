#!/usr/bin/env Rscript

# Setup reproduzível para uma sessão limpa. Execute com: Rscript --vanilla scripts/run_setup.R

script_args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", script_args, value = TRUE)
script_path <- if (length(file_arg)) sub("^--file=", "", file_arg[[1]]) else "scripts/run_setup.R"
project_root <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)

source(file.path(project_root, "R", "00_config.R"), local = .GlobalEnv)
ensure_output_dirs()
source(file.path(project_root, "R", "01_dependencies.R"), local = .GlobalEnv)
status <- check_dependencies(write_log = TRUE, fail = TRUE)
source(file.path(project_root, "R", "02_import_prepare.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "03_metrics_calibration.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "04_bootstrap_stability.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "05_nested_resampling.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "06_report_helpers.R"), local = .GlobalEnv)

record_environment(status)
data_raw <- import_prognostic_data()
data_prepared <- prepare_prognostic_data(data_raw)

cat("Setup concluído em sessão limpa.\n")
cat("Projeto:", PROJECT_ROOT, "\n")
cat("Fonte:", source_description(), "\n")
cat("Dimensões importadas:", nrow(data_prepared), "linhas x", ncol(data_prepared), "colunas\n")
cat("Dependências obrigatórias presentes:", paste(status$package[status$required_for_setup], collapse = ", "), "\n")
cat("Semente global:", GLOBAL_SEED, "\n")
cat("Sementes paralelas:", paste(PARALLEL_SEEDS, collapse = ", "), "\n")
