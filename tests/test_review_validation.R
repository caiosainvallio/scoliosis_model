# Testes independentes da revisão de validação e incerteza.

project_root <- normalizePath(".", mustWork = TRUE)
source(file.path(project_root, "R", "00_config.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "03_metrics_calibration.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "04_bootstrap_stability.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "09_shrinkage_equations.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "13_review_validation.R"), local = .GlobalEnv)

# O deslocamento deve ser aplicado aos quantis da métrica aparente, não aos
# quantis do otimismo. Esta construção sintética distingue os dois resultados.
toy_table <- data.frame(status = rep("valid", 4), train_rmse = c(1, 2, 4, 8),
                        test_rmse = c(2, 2, 3, 5), optimism_rmse = c(1, 0, -1, -3))
toy_summary <- data.frame(metric = "rmse", direction = "error", apparent = 3,
                          n_valid = 4, n_failed_replicas = 0,
                          n_metric_unavailable = 0, mean_optimism = 0.5, corrected = 3.5)
toy_internal <- list(
  linear = list(summary = rbind(
    toy_summary,
    data.frame(metric = c("r2", "mae", "mean_error", "calibration_intercept", "calibration_slope"),
               direction = c("benefit", "error", "target", "target", "target"), apparent = 1,
               n_valid = 4, n_failed_replicas = 0, n_metric_unavailable = 0,
               mean_optimism = 0, corrected = 1)
  ), table = transform(data.frame(status = rep("valid", 4)),
    train_rmse = c(1, 2, 4, 8), train_r2 = 1, train_mae = 1, train_mean_error = 1,
    train_calibration_intercept = 1, train_calibration_slope = 1)),
  logistic = list(summary = data.frame(
    metric = c("auc", "brier_score", "log_loss", "calibration_in_the_large", "calibration_slope"),
    direction = c("benefit", "error", "error", "target", "target"), apparent = 1,
    n_valid = 4, n_failed_replicas = 0, n_metric_unavailable = 0,
    mean_optimism = 0, corrected = 1),
    table = transform(data.frame(status = rep("valid", 4)), train_auc = 1,
      train_brier_score = 1, train_log_loss = 1, train_calibration_in_the_large = 1,
      train_calibration_slope = 1))
)
ci <- location_shifted_performance_ci(toy_internal, level = 0.5)
rmse_row <- ci[ci$model == "linear" & ci$metric == "rmse", ]
expected <- as.numeric(quantile(c(1, 2, 4, 8), c(.25, .75), type = 6)) + 0.5
stopifnot(max(abs(c(rmse_row$ci_lower, rmse_row$ci_upper) - expected)) < 1e-12)
stopifnot(all(is.na(ci$ci_lower[!ci$primary_metric])),
          all(ci$interval_method[!ci$primary_metric] == "unavailable_degenerate_apparent_bootstrap_statistic"))

# Falhas são contadas uma vez por réplica e indisponibilidade por métrica é
# separada, mesmo quando uma falha tornaria várias métricas ausentes.
failure_internal <- toy_internal
failure_internal$linear$table$status[1] <- "failed"
failure_internal$linear$table$failure_reason <- c("fit_error", NA, NA, NA)
audit <- review_bootstrap_failure_audit(failure_internal)
total <- audit[audit$model == "linear" & audit$record_type == "failed_replicas_total", ]
stopifnot(total$n == 1L, total$denominator == 4L)

set.seed(91)
n <- 100L
toy <- data.frame(x = rnorm(n), z = rnorm(n))
toy$delta <- 1 + 2 * toy$x + toy$z * abs(toy$x + 1) + rnorm(n, sd = exp(0.2 * toy$x))
toy$delta_cat <- as.integer(toy$delta < median(toy$delta))
formulas <- list(linear = delta ~ x + z, logistic = delta_cat ~ x + z)
splits_a <- review_stratified_folds(toy$delta_cat, folds = 5L, repeats = 2L, seed = 92L)
splits_b <- review_stratified_folds(toy$delta_cat, folds = 5L, repeats = 2L, seed = 92L)
stopifnot(identical(splits_a, splits_b), length(splits_a) == 10L,
          all(vapply(splits_a, function(x) !length(intersect(x$train, x$test)), logical(1))))

complete <- evaluate_complete_shrinkage(toy, formulas, folds = 5L, repeats = 1L,
                                        inner_times = 12L, seed = 93L)
stopifnot(nrow(complete$audit) == 5L, all(!complete$audit$test_used_for_factor),
          all(!complete$audit$test_used_for_intercept),
          all(complete$audit$factor_linear >= 0 & complete$audit$factor_linear <= 1),
          all(complete$audit$factor_logistic >= 0 & complete$audit$factor_logistic <= 1))

conformal <- evaluate_conformal_prediction_intervals(toy, formulas, splits = splits_a[1:5],
                                                     inner_times = 12L, level = .90, seed = 94L)
stopifnot(nrow(conformal$folds) == 5L, all(conformal$folds$mean_width_degrees > 0),
          all(!conformal$folds$test_used_for_fit), all(!conformal$folds$calibration_used_for_factor),
          all(conformal$folds$observed_coverage >= 0 & conformal$folds$observed_coverage <= 1))

availability <- prediction_interval_availability()
stopifnot(all(availability$status[1:2] == "unavailable"), !any(availability$external_validation))

cat("Revisão da Task 09: todos os testes passaram.\n")
