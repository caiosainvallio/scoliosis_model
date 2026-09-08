#!/usr/bin/env Rscript

project_root <- normalizePath(".", mustWork = TRUE)
source(file.path(project_root, "R", "00_config.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "03_metrics_calibration.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "11_flexible_modeling.R"), local = .GlobalEnv)

revision_root <- file.path(project_root, "results", "prognostico", "revisao")
current_path <- file.path(revision_root, "reduced_objects", "flexible_nested_internal.rds")
impact_path <- file.path(revision_root, "reduced_objects", "flexible_solver_before_after.rds")
previous_path <- file.path(project_root, "results", "prognostico", "reduced_objects",
                           "flexible_nested_internal.rds")
stopifnot(file.exists(current_path), file.exists(impact_path), file.exists(previous_path))

current <- readRDS(current_path)
previous <- readRDS(previous_path)
impact <- readRDS(impact_path)

stopifnot(
  length(current$indices) == 50L,
  flexible_indices_content_equal(current$indices, previous$indices),
  isTRUE(impact$same_indices),
  nrow(current$predictions) == 6150L,
  all(current$selected$converged),
  max(current$selected$kkt_max) <= FLEXIBLE_KKT_TOLERANCE,
  all(current$preprocessing_audit$approved),
  all(current$paired_prediction_audit$approved),
  all(current$resampling_audit$outer_disjoint),
  all(current$resampling_audit$outer_complete),
  all(current$resampling_audit$all_inner_disjoint),
  all(current$resampling_audit$all_inner_complete_within_outer_train),
  all(current$resampling_audit$minimum_test_coverage == 5L),
  all(current$resampling_audit$maximum_test_coverage == 5L),
  all(current$hierarchy$parents_present),
  all(!current$active_hierarchy$formal_hierarchy_constraint),
  any(current$active_hierarchy$interaction_active),
  all(current$spline_specification$degrees_of_freedom == 3L),
  all(current$design_expansion$total_candidate_columns == 48L)
)

selected_failures <- current$failure_audit$stage %in%
  c("selected_outer_fit", "global_illustrative_fit")
stopifnot(all(current$failure_audit$n_failed[selected_failures] == 0L))
inner_failures <- current$failure_audit$stage == "inner_tuning_configuration_folds" &
  current$failure_audit$n_failed > 0L
stopifnot(all(current$failure_audit$failure_reasons[inner_failures] != "none"))

comparison <- current$frozen_comparison_summary
relevant <- (comparison$family == "continuous" & comparison$metric %in% c("rmse", "mae")) |
  (comparison$family == "logistic" & comparison$metric %in%
     c("auc", "brier_score", "log_loss", "calibration_intercept", "calibration_slope"))
stopifnot(
  all(comparison$n_repeats[relevant] == 5L),
  all(grepl("nao e IC", comparison$dependence_note[relevant], fixed = TRUE)),
  !any(grepl("confidence|lower|upper", names(comparison), ignore.case = TRUE))
)

expected_outputs <- c(
  "flexible_active_hierarchy_audit.csv", "flexible_design_expansion.csv",
  "flexible_external_metrics.csv", "flexible_failure_audit.csv",
  "flexible_frozen_comparison_summary.csv", "flexible_methodological_appendix.md",
  "flexible_paired_prediction_audit.csv", "flexible_resampling_audit.csv",
  "flexible_solver_before_after_metrics.csv", "flexible_spline_specification.csv"
)
stopifnot(all(file.exists(file.path(revision_root, "aggregated", expected_outputs))))
stopifnot(file.exists(file.path(revision_root, "logs", "flexible_reexecution.log")))

cat("Task 05: reexecução, folds, solver, hierarquia e comparações verificados.\n")
