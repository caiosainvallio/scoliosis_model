#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg)) sub("^--file=", "", file_arg[[1]]) else "scripts/run_review_sensitivity.R"
project_root <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)

source(file.path(project_root, "R", "00_config.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "01_dependencies.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "02_import_prepare.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "03_metrics_calibration.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "04_bootstrap_stability.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "07_frozen_models.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "12_sensitivity_analysis.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "13_review_validation.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "14_review_sensitivity.R"), local = .GlobalEnv)

started <- Sys.time()
cohort <- prepare_prognostic_data(import_prognostic_data())
main <- run_frozen_models(cohort)
apparent <- run_sensitivity_analysis(cohort, main, write_outputs = FALSE)
cv <- review_sensitivity_resampling(cohort, main$models$formulas, folds = 10L, repeats = 5L,
                                    seed = 20260909L)
summary <- review_sensitivity_summary(cv$metrics)
baselines <- review_baseline_comparisons(cv$metrics)
strata <- review_strata_uncertainty(apparent$strata)

revision_root <- file.path(project_root, "results", "prognostico", "revisao")
dirs <- c(aggregated = file.path(revision_root, "aggregated"), logs = file.path(revision_root, "logs"),
          reduced_objects = file.path(revision_root, "reduced_objects"))
invisible(lapply(dirs, dir.create, recursive = TRUE, showWarnings = FALSE))
write_csv <- function(x, name, dir = dirs[["aggregated"]])
  utils::write.csv(x, file.path(dir, name), row.names = FALSE, na = "")

write_csv(apparent$criteria, "sensitivity_influence_criteria.csv")
write_csv(apparent$influence_summary, "sensitivity_influence_summary.csv")
write_csv(apparent$exclusions[c("scenario", "exclusion_basis", "n_excluded")], "sensitivity_exclusion_summary.csv")
write_csv(apparent$metrics, "sensitivity_apparent_and_full_cohort_metrics.csv")
write_csv(apparent$calibration, "sensitivity_apparent_and_full_cohort_calibration.csv")
write_csv(apparent$coefficients, "sensitivity_coefficient_changes.csv")
write_csv(apparent$prediction_summary, "sensitivity_prediction_changes.csv")
write_csv(apparent$cobb_target$metrics, "sensitivity_cobb_target_apparent_metrics.csv")
write_csv(apparent$cobb_target$calibration, "sensitivity_cobb_target_apparent_calibration.csv")
write_csv(apparent$cobb_target$coefficients, "sensitivity_cobb_target_apparent_coefficients.csv")
write_csv(strata, "sensitivity_strata_descriptive.csv")
write_csv(apparent$anatomical_region, "sensitivity_anatomical_region_summary.csv")
write_csv(cv$audit, "sensitivity_resampling_audit.csv")
write_csv(cv$metrics, "sensitivity_resampling_metrics_by_repeat.csv")
write_csv(summary, "sensitivity_resampling_metrics_summary.csv")
write_csv(baselines, "baseline_comparisons.csv")

equivalence <- data.frame(
  formulation_a = "delta ~ Cobb_basal + X", formulation_b = "Cobb_final ~ Cobb_basal + X; prediction reconverted to delta",
  folds = nrow(cv$audit), same_design_all_folds = all(cv$audit$same_design_matrix),
  maximum_prediction_absolute_difference = max(cv$audit$maximum_prediction_difference_delta_vs_final_reconverted),
  maximum_coefficient_absolute_difference_after_conversion = max(cv$audit$maximum_coefficient_difference_after_algebraic_conversion),
  numerical_tolerance = 1e-10, equivalent_within_tolerance =
    max(cv$audit$maximum_prediction_difference_delta_vs_final_reconverted,
        cv$audit$maximum_coefficient_difference_after_algebraic_conversion) < 1e-10,
  target_scale_for_comparison = "degrees_delta", stringsAsFactors = FALSE)
write_csv(equivalence, "sensitivity_cobb_reparameterization.csv")

get_metric <- function(scenario, model, metric) summary$mean_across_repeats[
  summary$scenario == scenario & summary$model == model & summary$metric == metric]
fit_range <- function(values) paste0(min(values), "-", max(values), " per fold")
primary_fit_range <- fit_range(cv$audit$n_train)
influence_fit_range <- paste0("linear ", fit_range(cv$audit$n_train - cv$audit$n_influence_excluded_linear),
                              "; logistic ", fit_range(cv$audit$n_train - cv$audit$n_influence_excluded_logistic))
hyper_fit_range <- fit_range(cv$audit$n_train - cv$audit$n_hypercorrection_excluded)
scenario_table <- data.frame(
  scenario = c("primary", "influence_excluded_train_only", "hypercorrection_excluded_train_only",
               "cobb_baseline_augmented", "training_mean_delta", "training_prevalence"),
  motivation = c("Frozen main specification", "Investigate Cook/leverage/standardized-residual signals",
                 "Temporarily examine three confirmed hypercorrections", "Condition delta on baseline Cobb",
                 "Simple continuous reference", "Simple binary reference"),
  n_fit = c(primary_fit_range, influence_fit_range, hyper_fit_range, primary_fit_range,
            primary_fit_range, primary_fit_range),
  evaluation_set = "same complete held-out folds; 615 predictions per repeat",
  quantitative_change = c(
    sprintf("RMSE %.4f degrees; logistic Brier %.4f", get_metric("primary", "linear", "rmse"), get_metric("primary", "logistic", "brier_score")),
    sprintf("RMSE change %+0.4f; Brier change %+0.4f versus primary", get_metric("influence_excluded_train_only", "linear", "rmse") - get_metric("primary", "linear", "rmse"), get_metric("influence_excluded_train_only", "logistic", "brier_score") - get_metric("primary", "logistic", "brier_score")),
    sprintf("RMSE change %+0.4f; Brier change %+0.4f versus primary", get_metric("hypercorrection_excluded_train_only", "linear", "rmse") - get_metric("primary", "linear", "rmse"), get_metric("hypercorrection_excluded_train_only", "logistic", "brier_score") - get_metric("primary", "logistic", "brier_score")),
    sprintf("RMSE %.4f degrees; change %+0.4f versus primary", get_metric("cobb_baseline_augmented", "linear", "rmse"), get_metric("cobb_baseline_augmented", "linear", "rmse") - get_metric("primary", "linear", "rmse")),
    sprintf("RMSE %.4f degrees", get_metric("training_mean_delta", "linear", "rmse")),
    sprintf("Brier %.4f", get_metric("training_prevalence", "logistic", "brier_score"))
  ),
  conclusion = c("Reference for paired internal comparisons", "Diagnostic exclusion is sensitivity only; no main-cohort change",
                 "Confirmed hypercorrections remain in main cohort", "Alternative conditioning analysis; not target selection by R-squared",
                 "Model gain interpreted as held-out RMSE reduction", "Model gain interpreted as held-out Brier reduction"),
  review_complement = c(FALSE, TRUE, TRUE, TRUE, TRUE, TRUE), stringsAsFactors = FALSE)
write_csv(scenario_table, "sensitivity_scenario_conclusions.csv")

saveRDS(list(metadata = list(source_sha256 = file_sha256(DATA_FILE), n = nrow(cohort),
  events = sum(cohort$delta_cat), folds = 10L, repeats = 5L, seed = 20260909L),
  resampling_audit = cv$audit, resampling_metrics = cv$metrics,
  equivalence = equivalence, apparent_exclusions = apparent$exclusions),
  file.path(dirs[["reduced_objects"]], "sensitivity_review_reduced.rds"), compress = "xz")

stopifnot(nrow(cohort) == 615L, sum(cohort$delta_cat) == 317L,
  all(c(81L, 174L, 401L) %in% cohort$id), all(cv$audit$n_test > 0),
  all(!cv$audit$test_used_for_fit), all(!cv$audit$test_used_for_exclusion),
  all(cv$audit$comparator_estimated_in_training), equivalence$equivalent_within_tolerance,
  all(cv$metrics$n_evaluated == 615L), all(baselines$training_only_estimation),
  all(cv$audit$n_warnings_primary_linear == 0L), all(cv$audit$n_warnings_primary_logistic == 0L),
  all(cv$audit$n_warnings_influence_linear == 0L),
  all(cv$audit$n_warnings_hypercorrection_linear == 0L),
  all(cv$audit$n_warnings_hypercorrection_logistic == 0L))

output_files <- c(list.files(dirs[["aggregated"]], pattern = "^(sensitivity_|baseline_comparisons)", full.names = TRUE),
                  file.path(dirs[["reduced_objects"]], "sensitivity_review_reduced.rds"))
output_files <- setdiff(output_files, file.path(dirs[["aggregated"]], "sensitivity_output_manifest.csv"))
manifest <- data.frame(artifact = sub(paste0("^", project_root, "/"), "", output_files),
  class = ifelse(grepl("reduced_objects", output_files), "internal_reduced_object", "aggregate_result"),
  source = "frozen_cohort_615_and_task09_fold_specification", script = "scripts/run_review_sensitivity.R",
  task = "10", sha256 = vapply(output_files, file_sha256, character(1)),
  consumption = "tasks_12_13_15", stringsAsFactors = FALSE)
write_csv(manifest, "sensitivity_output_manifest.csv")

elapsed <- as.numeric(difftime(Sys.time(), started, units = "secs"))
log_lines <- c("Task 10 — sensitivities, Cobb baseline and simple comparators",
  paste("execution_datetime:", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  paste("source_sha256:", file_sha256(DATA_FILE)), "cohort_events_nonevents: 615 317 298",
  "resampling: 5 repeats x 10 stratified folds; seed 20260909; same as Task 09",
  "preprocessing_and_all_estimation: training fold only; factor coding fixed a priori",
  "evaluation: complete common held-out folds; 615 predictions per repeat",
  paste("cobb_equivalence_max_prediction_difference:", format(equivalence$maximum_prediction_absolute_difference, scientific = TRUE)),
  paste("cobb_equivalence_max_coefficient_difference:", format(equivalence$maximum_coefficient_absolute_difference_after_conversion, scientific = TRUE)),
  paste("baseline_comparisons:", paste(baselines$model_scenario, signif(baselines$improvement_error_reduction, 6), collapse = "; ")),
  paste("influence_logistic_folds_with_extreme_probability_warning:", sum(cv$audit$n_warnings_influence_logistic > 0L), "of", nrow(cv$audit)),
  paste("repeat_metric_rows_with_warning:", sum(cv$metrics$metric_status == "available_with_warning")),
  paste("repeat_metric_rows_unavailable:", sum(cv$metrics$metric_status == "unavailable")),
  "main_cohort_changed: FALSE", "external_validation: not performed",
  "anatomical_limit: six-month maximum-curve region unavailable",
  paste("elapsed_seconds:", signif(elapsed, 7)), paste("R:", R.version.string))
writeLines(log_lines, file.path(dirs[["logs"]], "sensitivity_task10.log"))
cat(paste(log_lines, collapse = "\n"), "\n")
