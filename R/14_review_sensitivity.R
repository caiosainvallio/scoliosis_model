# Sensibilidades comparáveis da revisão (Task 10).
#
# Os modelos principais não são alterados. Toda exclusão ocorre somente no
# treinamento do fold; o teste externo interno permanece completo e comum aos
# modelos e aos comparadores simples.

review_influence_flags <- function(fit, data, model) {
  n <- nrow(data); p <- length(stats::coef(fit))
  standardized <- if (model == "linear") stats::rstandard(fit) else stats::rstandard(fit, type = "pearson")
  stats::cooks.distance(fit) > 4 / n |
    stats::hatvalues(fit) > 2 * p / n |
    abs(standardized) > 2
}

review_fit_predict <- function(formula, train, test, model) {
  fit_warnings <- character()
  fit <- withCallingHandlers(
    if (model == "linear") stats::lm(formula, data = train) else
      stats::glm(formula, data = train, family = stats::binomial()),
    warning = function(w) {
      fit_warnings <<- c(fit_warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    })
  if (any(!is.finite(stats::coef(fit))) || (model == "logistic" && !isTRUE(fit$converged)))
    stop("Ajuste não finito ou não convergente na sensibilidade.", call. = FALSE)
  prediction <- withCallingHandlers(
    as.numeric(stats::predict(fit, newdata = test, type = "response")),
    warning = function(w) {
      fit_warnings <<- c(fit_warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    })
  list(fit = fit, prediction = prediction, warnings = unique(fit_warnings))
}

review_metric_rows <- function(predictions) {
  keys <- unique(predictions[c("repeat_id", "scenario", "model")])
  do.call(rbind, lapply(seq_len(nrow(keys)), function(i) {
    key <- keys[i, ]; x <- predictions[
      predictions$repeat_id == key$repeat_id & predictions$scenario == key$scenario &
        predictions$model == key$model, , drop = FALSE]
    metric_warnings <- character()
    values <- withCallingHandlers(review_test_metrics(x$observed, x$predicted, key$model),
      warning = function(w) {
        metric_warnings <<- c(metric_warnings, conditionMessage(w))
        invokeRestart("muffleWarning")
      })
    data.frame(repeat_id = key$repeat_id, scenario = key$scenario, model = key$model,
               metric = names(values), value = unname(values), n_evaluated = nrow(x),
               evaluation_set = "same_complete_test_folds_615_per_repeat",
               metric_status = ifelse(is.finite(values),
                 if (length(metric_warnings)) "available_with_warning" else "available", "unavailable"),
               metric_warning = if (length(metric_warnings)) paste(unique(metric_warnings), collapse = " | ") else NA_character_,
               unit = ifelse(names(values) %in% c("rmse", "mae", "mean_error") |
                               (key$model == "linear" & names(values) == "calibration_intercept"),
                             "degrees_delta", ifelse(key$model == "logistic" &
                               names(values) == "calibration_in_the_large", "log_odds", ifelse(names(values) == "brier_score",
                             "squared_probability_error", ifelse(names(values) == "log_loss",
                             "logarithmic_score", "proportion_or_slope")))),
               stringsAsFactors = FALSE)
  }))
}

review_sensitivity_resampling <- function(cohort, formulas, folds = 10L, repeats = 5L,
                                          seed = 20260909L) {
  splits <- review_stratified_folds(cohort$delta_cat, folds, repeats, seed)
  rows <- vector("list", length(splits)); audits <- vector("list", length(splits))
  for (i in seq_along(splits)) {
    split <- splits[[i]]; train <- cohort[split$train, , drop = FALSE]
    test <- cohort[split$test, , drop = FALSE]
    primary_linear <- review_fit_predict(formulas$linear, train, test, "linear")
    primary_logistic <- review_fit_predict(formulas$logistic, train, test, "logistic")
    flag_linear <- review_influence_flags(primary_linear$fit, train, "linear")
    flag_logistic <- review_influence_flags(primary_logistic$fit, train, "logistic")
    hyper <- train$correcao_colete > 100

    influence_linear <- review_fit_predict(formulas$linear, train[!flag_linear, , drop = FALSE], test, "linear")
    influence_logistic <- review_fit_predict(formulas$logistic, train[!flag_logistic, , drop = FALSE], test, "logistic")
    hyper_linear <- review_fit_predict(formulas$linear, train[!hyper, , drop = FALSE], test, "linear")
    hyper_logistic <- review_fit_predict(formulas$logistic, train[!hyper, , drop = FALSE], test, "logistic")

    delta_cobb_formula <- stats::reformulate(c("cobb_inicial_maior", MODEL_PREDICTORS), response = "delta")
    final_cobb_formula <- stats::reformulate(c("cobb_inicial_maior", MODEL_PREDICTORS), response = "maior_curva_6_meses")
    delta_cobb <- review_fit_predict(delta_cobb_formula, train, test, "linear")
    final_cobb <- review_fit_predict(final_cobb_formula, train, test, "linear")
    final_as_delta <- final_cobb$prediction - test$cobb_inicial_maior
    equivalence <- max(abs(delta_cobb$prediction - final_as_delta))

    make <- function(scenario, model, observed, predicted) data.frame(
      repeat_id = split$repeat_id, fold = split$fold, row_index = split$test,
      scenario = scenario, model = model, observed = observed, predicted = predicted,
      stringsAsFactors = FALSE)
    rows[[i]] <- rbind(
      make("primary", "linear", test$delta, primary_linear$prediction),
      make("influence_excluded_train_only", "linear", test$delta, influence_linear$prediction),
      make("hypercorrection_excluded_train_only", "linear", test$delta, hyper_linear$prediction),
      make("cobb_baseline_augmented", "linear", test$delta, delta_cobb$prediction),
      make("training_mean_delta", "linear", test$delta, rep(mean(train$delta), nrow(test))),
      make("primary", "logistic", test$delta_cat, primary_logistic$prediction),
      make("influence_excluded_train_only", "logistic", test$delta_cat, influence_logistic$prediction),
      make("hypercorrection_excluded_train_only", "logistic", test$delta_cat, hyper_logistic$prediction),
      make("training_prevalence", "logistic", test$delta_cat, rep(mean(train$delta_cat), nrow(test)))
    )
    delta_coef <- stats::coef(delta_cobb$fit); final_coef <- stats::coef(final_cobb$fit)
    expected_final <- delta_coef
    expected_final[["cobb_inicial_maior"]] <- expected_final[["cobb_inicial_maior"]] + 1
    audits[[i]] <- data.frame(
      repeat_id = split$repeat_id, fold = split$fold, n_train = nrow(train), n_test = nrow(test),
      n_influence_excluded_linear = sum(flag_linear),
      n_influence_excluded_logistic = sum(flag_logistic), n_hypercorrection_excluded = sum(hyper),
      maximum_prediction_difference_delta_vs_final_reconverted = equivalence,
      maximum_coefficient_difference_after_algebraic_conversion = max(abs(final_coef - expected_final)),
      same_design_matrix = identical(
        stats::model.matrix(stats::delete.response(stats::terms(delta_cobb_formula)), train),
        stats::model.matrix(stats::delete.response(stats::terms(final_cobb_formula)), train)),
      test_used_for_fit = FALSE, test_used_for_exclusion = FALSE,
      comparator_estimated_in_training = TRUE, stringsAsFactors = FALSE)
    audits[[i]]$n_warnings_primary_linear <- length(primary_linear$warnings)
    audits[[i]]$n_warnings_primary_logistic <- length(primary_logistic$warnings)
    audits[[i]]$n_warnings_influence_linear <- length(influence_linear$warnings)
    audits[[i]]$n_warnings_influence_logistic <- length(influence_logistic$warnings)
    audits[[i]]$n_warnings_hypercorrection_linear <- length(hyper_linear$warnings)
    audits[[i]]$n_warnings_hypercorrection_logistic <- length(hyper_logistic$warnings)
    audits[[i]]$influence_logistic_warning <- if (length(influence_logistic$warnings))
      paste(influence_logistic$warnings, collapse = " | ") else NA_character_
  }
  predictions <- do.call(rbind, rows); audit <- do.call(rbind, audits)
  metrics <- review_metric_rows(predictions)
  list(predictions = predictions, audit = audit, metrics = metrics)
}

review_sensitivity_summary <- function(metrics) {
  keys <- unique(metrics[c("scenario", "model", "metric", "unit", "evaluation_set")])
  do.call(rbind, lapply(seq_len(nrow(keys)), function(i) {
    key <- keys[i, ]; take <- metrics$scenario == key$scenario & metrics$model == key$model &
      metrics$metric == key$metric; values <- metrics$value[take]
    finite <- values[is.finite(values)]
    data.frame(key, mean_across_repeats = if (length(finite)) mean(finite) else NA_real_,
               minimum_across_repeats = if (length(finite)) min(finite) else NA_real_,
               maximum_across_repeats = if (length(finite)) max(finite) else NA_real_,
               n_repeats = length(values), n_repeats_available = length(finite),
               interval_status = "range_across_repeats_not_confidence_interval",
               stringsAsFactors = FALSE)
  }))
}

review_baseline_comparisons <- function(metrics) {
  pairs <- rbind(
    data.frame(model = "linear", model_scenario = c("primary", "cobb_baseline_augmented"),
               baseline_scenario = "training_mean_delta", metric = c("rmse", "rmse")),
    data.frame(model = "logistic", model_scenario = "primary",
               baseline_scenario = "training_prevalence", metric = c("brier_score"))
  )
  do.call(rbind, lapply(seq_len(nrow(pairs)), function(i) {
    p <- pairs[i, ]; model_rows <- metrics[metrics$model == p$model &
      metrics$scenario == p$model_scenario & metrics$metric == p$metric, ]
    base_rows <- metrics[metrics$model == p$model & metrics$scenario == p$baseline_scenario &
      metrics$metric == p$metric, ]
    joined <- merge(model_rows[c("repeat_id", "value")], base_rows[c("repeat_id", "value")],
                    by = "repeat_id", suffixes = c("_model", "_baseline"))
    improvement <- joined$value_baseline - joined$value_model
    data.frame(model = p$model, model_scenario = p$model_scenario,
               comparator = p$baseline_scenario, metric = p$metric,
               model_mean = mean(joined$value_model), comparator_mean = mean(joined$value_baseline),
               improvement_error_reduction = mean(improvement),
               minimum_improvement_across_repeats = min(improvement),
               maximum_improvement_across_repeats = max(improvement), n_repeats = nrow(joined),
               training_only_estimation = TRUE,
               evaluation_set = "same_complete_test_folds_615_per_repeat",
               interpretation = if (p$model == "linear")
                 "Positive values are RMSE reduction in degrees of delta versus the training mean."
               else "Positive values are Brier-score reduction versus training prevalence.",
               stringsAsFactors = FALSE)
  }))
}

review_strata_uncertainty <- function(strata) {
  z <- stats::qnorm(.975)
  se_mean <- strata$delta_rmse / sqrt(strata$n)
  p <- strata$probability_observed; n <- strata$n
  center <- (p + z^2 / (2 * n)) / (1 + z^2 / n)
  half <- z * sqrt(p * (1 - p) / n + z^2 / (4 * n^2)) / (1 + z^2 / n)
  data.frame(strata,
    mean_delta_ci_lower_approx = strata$mean_delta_observed - z * se_mean,
    mean_delta_ci_upper_approx = strata$mean_delta_observed + z * se_mean,
    improvement_prevalence_wilson_lower = pmax(0, center - half),
    improvement_prevalence_wilson_upper = pmin(1, center + half),
    uncertainty_note = "Descriptive 95% intervals; no subgroup interaction test and no multiplicity claim.",
    stringsAsFactors = FALSE)
}
