#!/usr/bin/env Rscript

# Reconstrói apenas as 50 árvores externas da CART a partir dos folds e
# hiperparâmetros já salvos. Não repete tuning nem altera o baseline congelado.

script_args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", script_args, value = TRUE)
script_path <- if (length(file_arg)) sub("^--file=", "", file_arg[[1]]) else "scripts/review_cart_structure.R"
project_root <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)

source(file.path(project_root, "R", "00_config.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "02_import_prepare.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "10_cart_nested.R"), local = .GlobalEnv)

if (!requireNamespace("readxl", quietly = TRUE) || !requireNamespace("rpart", quietly = TRUE)) {
  stop("A revisão da CART requer readxl e rpart já instalados.", call. = FALSE)
}

baseline_path <- file.path(RESULTS_DIRS[["reduced_objects"]], "cart_nested_internal.rds")
review_root <- file.path(RESULTS_ROOT, "revisao")
output_dir <- file.path(review_root, "aggregated")
log_dir <- file.path(review_root, "logs")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(log_dir, recursive = TRUE, showWarnings = FALSE)

saved <- readRDS(baseline_path)
raw <- import_prognostic_data()
cohort <- prepare_prognostic_data(raw)
models <- cart_refit_saved_outer_models(cohort, saved)
review <- cart_review_structure_outputs(models, saved, output_dir)

# A árvore ilustrativa usa a configuração global já selecionada no baseline.
# O ajuste em toda a coorte serve somente para regras aparentes/visualização.
final_recipe <- cart_preprocess_fit(cohort)
final_x <- cart_preprocess_apply(cohort, final_recipe)
illustrative_model <- cart_fit(final_x, as.integer(cohort$delta_cat), saved$global_tuning$selected)
illustrative_info <- list(model = illustrative_model, tree_id = 0L,
                          repeat_id = NA_integer_, outer_fold = NA_integer_)
illustrative <- cart_structure_tables(
  list(illustrative_info), fit_origin = "full_cohort_illustrative_saved_hyperparameters"
)
utils::write.csv(illustrative$primary_splits,
                 file.path(output_dir, "cart_illustrative_primary_splits.csv"), row.names = FALSE, na = "")
utils::write.csv(illustrative$leaf_rules,
                 file.path(output_dir, "cart_illustrative_leaf_rules.csv"), row.names = FALSE, na = "")

primary <- review$structures$primary_splits
competitors <- review$structures$competitor_splits
surrogates <- review$structures$surrogate_splits
nodes <- review$structures$node_sizes
frequency <- review$outputs$cart_variable_frequency_summary
calibration <- review$outputs$cart_calibration_validity_summary

checks <- c(
  primary_equals_internal_nodes = nrow(primary) == sum(!nodes$terminal),
  all_primary_roles = all(primary$split_role == "primary"),
  frequency_in_unit_interval = all(frequency$relative_frequency >= 0 & frequency$relative_frequency <= 1),
  explicit_scopes = setequal(unique(frequency$scope), c("root", "depths_1_2", "deeper_than_2", "all_levels")),
  calibration_intercepts_valid_49 = calibration$valid_folds[calibration$metric == "calibration_intercept"] == 49L,
  source_rows_preserved = nrow(raw) == 621L,
  cohort_rows_preserved = nrow(cohort) == 615L,
  events_preserved = sum(cohort$delta_cat == 1L) == 317L
)
if (!all(checks)) stop("Uma ou mais verificações da revisão CART falharam.", call. = FALSE)

log_lines <- c(
  "Task 06 — reconstrução estrutural CART",
  paste("executed_at:", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  paste("r_version:", R.version.string),
  paste("rpart_version:", as.character(utils::packageVersion("rpart"))),
  paste("baseline_object_sha256:", file_sha256(baseline_path)),
  paste("source_sha256:", file_sha256(DATA_FILE)),
  "method: refit outer trees from saved indices and selected hyperparameters; no retuning",
  paste("trees:", length(models)),
  paste("primary_splits:", nrow(primary)),
  paste("internal_nodes:", sum(!nodes$terminal)),
  paste("competitor_splits:", nrow(competitors)),
  paste("surrogate_splits:", nrow(surrogates)),
  paste("categorical_primary_splits:", sum(primary$split_type == "categorical")),
  paste("leaf_rules:", nrow(review$structures$leaf_rules)),
  paste("illustrative_primary_splits:", nrow(illustrative$primary_splits)),
  paste("illustrative_leaf_rules:", nrow(illustrative$leaf_rules)),
  paste("calibration_intercept_valid_folds:", calibration$valid_folds[calibration$metric == "calibration_intercept"]),
  paste("calibration_intercept_invalid_folds:", calibration$invalid_folds[calibration$metric == "calibration_intercept"]),
  paste(names(checks), checks, sep = ": ")
)
writeLines(log_lines, file.path(log_dir, "cart_structure_rebuild.log"), useBytes = TRUE)
cat(paste(log_lines, collapse = "\n"), "\n")
