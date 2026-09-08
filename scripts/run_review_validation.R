#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg)) sub("^--file=", "", file_arg[[1]]) else "scripts/run_review_validation.R"
project_root <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)

source(file.path(project_root, "R", "00_config.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "01_dependencies.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "02_import_prepare.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "03_metrics_calibration.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "04_bootstrap_stability.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "07_frozen_models.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "08_internal_validation.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "09_shrinkage_equations.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "13_review_validation.R"), local = .GlobalEnv)

started <- Sys.time()
cohort <- prepare_prognostic_data(import_prognostic_data())
frozen <- run_frozen_models(cohort)
internal_path <- file.path(RESULTS_DIRS[["reduced_objects"]], "frozen_bootstrap_internal.rds")
if (!file.exists(internal_path)) stop("Bootstrap congelado ausente: ", internal_path)
internal <- readRDS(internal_path)
stopifnot(nrow(cohort) == 615L, internal$metadata$n_original == 615L,
          internal$metadata$times == 2000L, file_sha256(DATA_FILE) == internal$metadata$source_sha256)

revision_root <- file.path(project_root, "results", "prognostico", "revisao")
dirs <- c(aggregated = file.path(revision_root, "aggregated"),
          logs = file.path(revision_root, "logs"), reduced_objects = file.path(revision_root, "reduced_objects"))
invisible(lapply(dirs, dir.create, recursive = TRUE, showWarnings = FALSE))
write_csv <- function(x, name) utils::write.csv(x, file.path(dirs[["aggregated"]], name), row.names = FALSE, na = "")

performance_ci <- location_shifted_performance_ci(internal)
failure_audit <- review_bootstrap_failure_audit(internal)
final_shrinkage <- run_shrinkage_analysis(frozen, internal, cohort, FACTOR_LEVELS, internal)
objects <- review_validation_object_table(frozen, internal, final_shrinkage)
splits <- review_stratified_folds(cohort$delta_cat, folds = 10L, repeats = 5L, seed = 20260909L)

complete <- evaluate_complete_shrinkage(cohort, frozen$models$formulas, FACTOR_LEVELS,
                                        folds = 10L, repeats = 5L, inner_times = 200L,
                                        seed = 20260909L)
conformal <- evaluate_conformal_prediction_intervals(
  cohort, frozen$models$formulas, FACTOR_LEVELS, splits = splits,
  inner_times = 200L, level = 0.95, seed = 20260910L
)
availability <- prediction_interval_availability()

write_csv(performance_ci, "validation_performance_ci.csv")
write_csv(failure_audit, "validation_failure_audit.csv")
write_csv(objects, "validation_objects.csv")
write_csv(final_shrinkage$shrinkage_summary, "validation_final_shrinkage_summary.csv")
write_csv(final_shrinkage$coefficients, "validation_final_shrinkage_coefficients.csv")
write_csv(complete$audit, "validation_shrinkage_procedure_audit.csv")
write_csv(complete$metrics, "validation_shrinkage_metrics_by_repeat.csv")
shrinkage_summary <- aggregate(value ~ model + metric + unit + procedure + target + evaluation + interval_status,
                               data = complete$metrics, FUN = mean)
names(shrinkage_summary)[names(shrinkage_summary) == "value"] <- "mean_across_repeats"
shrinkage_summary$minimum_across_repeats <- mapply(function(model, metric) {
  min(complete$metrics$value[complete$metrics$model == model & complete$metrics$metric == metric])
}, shrinkage_summary$model, shrinkage_summary$metric)
shrinkage_summary$maximum_across_repeats <- mapply(function(model, metric) {
  max(complete$metrics$value[complete$metrics$model == model & complete$metrics$metric == metric])
}, shrinkage_summary$model, shrinkage_summary$metric)
shrinkage_summary$n_repeats <- 5L
write_csv(shrinkage_summary, "validation_shrinkage_metrics_summary.csv")
write_csv(conformal$folds, "prediction_intervals_coverage_by_fold.csv")
write_csv(conformal$repeats, "prediction_intervals_coverage_by_repeat.csv")
write_csv(availability, "prediction_intervals_availability.csv")
writeLines(make_review_equation_text(final_shrinkage$linear, final_shrinkage$logistic),
           file.path(dirs[["aggregated"]], "validation_final_equations.txt"))

saveRDS(list(
  metadata = list(source_sha256 = file_sha256(DATA_FILE), n = nrow(cohort),
                  performance_bootstrap_times = 2000L, cv_folds = 10L, cv_repeats = 5L,
                  inner_bootstrap_times = 200L, seeds = c(performance = 20260906L,
                  shrinkage_cv = 20260909L, conformal = 20260910L)),
  final_models = list(linear = final_shrinkage$linear, logistic = final_shrinkage$logistic),
  complete_shrinkage_audit = complete$audit,
  complete_shrinkage_metrics = complete$metrics,
  conformal_folds = conformal$folds, conformal_repeats = conformal$repeats
), file.path(dirs[["reduced_objects"]], "validation_review_reduced.rds"), compress = "xz")

stopifnot(
  nrow(performance_ci) == 11L,
  all(performance_ci$n_failed_replicas == 0L),
  all(performance_ci$ci_lower[performance_ci$primary_metric] <= performance_ci$estimate[performance_ci$primary_metric] &
      performance_ci$estimate[performance_ci$primary_metric] <= performance_ci$ci_upper[performance_ci$primary_metric]),
  all(is.na(performance_ci$ci_lower[!performance_ci$primary_metric])),
  nrow(complete$audit) == 50L,
  all(!complete$audit$test_used_for_factor), all(!complete$audit$test_used_for_intercept),
  all(complete$audit$inner_valid_linear >= 198L), all(complete$audit$inner_valid_logistic >= 198L),
  nrow(conformal$folds) == 50L,
  all(!conformal$folds$test_used_for_fit), all(!conformal$folds$test_used_for_factor),
  all(!conformal$folds$test_used_for_intercept), all(!conformal$folds$calibration_used_for_fit),
  all(conformal$folds$observed_coverage >= 0 & conformal$folds$observed_coverage <= 1),
  all(conformal$folds$mean_width_degrees > 0)
)

output_files <- c(
  setdiff(list.files(dirs[["aggregated"]], pattern = "^(validation_|prediction_intervals_)", full.names = TRUE),
          file.path(dirs[["aggregated"]], "validation_output_manifest.csv")),
  file.path(dirs[["reduced_objects"]], "validation_review_reduced.rds")
)
output_manifest <- data.frame(
  artifact = sub(paste0("^", project_root, "/"), "", output_files),
  class = ifelse(grepl("reduced_objects", output_files), "internal_reduced_object", "aggregate_result"),
  source = "frozen_cohort_615_fixed_models_and_verified_bootstrap",
  script = "scripts/run_review_validation.R", task = "09",
  sha256 = vapply(output_files, file_sha256, character(1)),
  consumption = "tasks_10_12_13_15", stringsAsFactors = FALSE
)
utils::write.csv(output_manifest, file.path(dirs[["aggregated"]], "validation_output_manifest.csv"),
                 row.names = FALSE, na = "")

elapsed <- as.numeric(difftime(Sys.time(), started, units = "secs"))
primary <- performance_ci[performance_ci$primary_metric, ]
log_lines <- c(
  "Task 09 — validacao interna, incerteza e shrinkage",
  paste("execution_datetime:", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  paste("source_sha256:", file_sha256(DATA_FILE)),
  paste("cohort_events_nonevents:", nrow(cohort), sum(cohort$delta_cat == 1L), sum(cohort$delta_cat == 0L)),
  "performance_ci_method: Noma et al. 2021 location-shifted percentile bootstrap",
  "performance_ci_resamples: 2000 frozen verified participant-level bootstrap replicates",
  paste("primary_metrics:", paste(paste(primary$model, primary$metric, signif(primary$estimate, 6),
                                         sprintf("[%0.6f,%0.6f]", primary$ci_lower, primary$ci_upper)), collapse = "; ")),
  "full_shrinkage_evaluation: 5 repeats x 10 outer folds; 200 inner bootstraps/model/fold",
  paste("full_shrinkage_inner_valid_min_linear_logistic:", min(complete$audit$inner_valid_linear),
        min(complete$audit$inner_valid_logistic)),
  "test_reuse_for_factor_or_intercept: FALSE",
  paste("conformal_coverage_by_repeat:", paste(signif(conformal$repeats$observed_coverage, 5), collapse = " ")),
  paste("conformal_mean_width_degrees_by_repeat:", paste(signif(conformal$repeats$mean_width_degrees, 5), collapse = " ")),
  "conditional_mean_ci_final_equation: unavailable; heteroscedasticity and shrinkage-factor uncertainty not handled by legacy formula",
  "individual_pi_final_all_data_equation: unavailable; no independent calibration sample remains",
  "external_validation: not performed",
  paste("elapsed_seconds:", signif(elapsed, 7)),
  paste("R:", R.version.string)
)
writeLines(log_lines, file.path(dirs[["logs"]], "validation_task09.log"))
cat(paste(log_lines, collapse = "\n"), "\n")
