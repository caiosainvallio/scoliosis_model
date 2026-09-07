#!/usr/bin/env Rscript

# Execução da Tarefa 06. Execute com: Rscript --vanilla scripts/run_internal_validation.R

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg)) sub("^--file=", "", file_arg[[1]]) else "scripts/run_internal_validation.R"
project_root <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)

source(file.path(project_root, "R", "00_config.R"), local = .GlobalEnv)
ensure_output_dirs()
source(file.path(project_root, "R", "01_dependencies.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "02_import_prepare.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "03_metrics_calibration.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "04_bootstrap_stability.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "07_frozen_models.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "08_internal_validation.R"), local = .GlobalEnv)

status <- check_dependencies(write_log = TRUE, fail = TRUE)
raw <- import_prognostic_data()
cohort <- prepare_prognostic_data(raw)
frozen_results <- run_frozen_models(cohort)

BOOTSTRAP_TIMES <- 2000L
BOOTSTRAP_SAMPLE_SIZE <- 615L
BOOTSTRAP_SEED <- GLOBAL_SEED

if (nrow(cohort) != BOOTSTRAP_SAMPLE_SIZE) stop("A coorte não tem 615 participantes.")
if (!isTRUE(all.equal(frozen_results$models$formulas$linear, frozen_model_formulas()$linear)) ||
    !isTRUE(all.equal(frozen_results$models$formulas$logistic, frozen_model_formulas()$logistic))) {
  stop("As fórmulas ajustadas não coincidem com as fórmulas congeladas.")
}

cat("Executando", BOOTSTRAP_TIMES, "réplicas lineares...\n")
linear_replicas <- bootstrap_replicates(
  data = cohort, formula = frozen_results$models$formulas$linear, family = "gaussian",
  times = BOOTSTRAP_TIMES, seed = BOOTSTRAP_SEED, original_data = cohort,
  sample_size = BOOTSTRAP_SAMPLE_SIZE
)
cat("Executando", BOOTSTRAP_TIMES, "réplicas logísticas...\n")
logistic_replicas <- bootstrap_replicates(
  data = cohort, formula = frozen_results$models$formulas$logistic, family = "binomial",
  times = BOOTSTRAP_TIMES, seed = BOOTSTRAP_SEED, original_data = cohort,
  sample_size = BOOTSTRAP_SAMPLE_SIZE
)

validate_bootstrap_contract(linear_replicas, BOOTSTRAP_TIMES, BOOTSTRAP_SAMPLE_SIZE)
validate_bootstrap_contract(logistic_replicas, BOOTSTRAP_TIMES, BOOTSTRAP_SAMPLE_SIZE)
outputs <- write_internal_validation_outputs(
  linear_replicas = linear_replicas, logistic_replicas = logistic_replicas,
  frozen_results = frozen_results, seed = BOOTSTRAP_SEED,
  times = BOOTSTRAP_TIMES, sample_size = BOOTSTRAP_SAMPLE_SIZE
)
writeLines(capture.output(sessionInfo()),
           file.path(RESULTS_DIRS[["logs"]], "frozen_bootstrap_session_info.txt"))

stopifnot(nrow(outputs$validation) == 2L,
          all(outputs$validation$attempts == BOOTSTRAP_TIMES),
          all(outputs$validation$valid >= 1980L),
          all(outputs$validation$criterion_met),
          nrow(outputs$linear) == 6L, nrow(outputs$logistic) == 5L,
          all(is.finite(outputs$linear$corrected)),
          all(is.finite(outputs$logistic$corrected)))

cat("Tarefa 06 concluída: 2.000 tentativas por modelo e mínimo de 99% válidas.\n")
print(outputs$validation[, c("model", "attempts", "valid", "failed", "validity_rate")], row.names = FALSE)
