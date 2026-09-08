# Revisão da avaliação interna, incerteza e do procedimento pós-shrinkage.
#
# Este módulo não altera a especificação principal. Ele separa o IC do
# estimador corrigido, a avaliação do procedimento completo e a avaliação de
# intervalos individuais. Nenhuma função escreve nos resultados congelados.

review_metric_metadata <- function() {
  data.frame(
    model = c(rep("linear", 6L), rep("logistic", 5L)),
    metric = c("r2", "rmse", "mae", "mean_error", "calibration_intercept",
               "calibration_slope", "auc", "brier_score", "log_loss",
               "calibration_in_the_large", "calibration_slope"),
    unit = c("proportion", "degrees_delta", "degrees_delta", "degrees_delta",
             "degrees_delta", "slope", "probability", "squared_probability_error",
             "logarithmic_score", "log_odds", "slope"),
    primary_metric = c(TRUE, TRUE, TRUE, FALSE, FALSE, FALSE,
                       TRUE, TRUE, TRUE, FALSE, FALSE),
    target = "expected_performance_of_fixed_specification_refitted_in_same_population_with_n_615",
    stringsAsFactors = FALSE
  )
}

location_shifted_performance_ci <- function(internal_validation, level = 0.95) {
  if (level <= 0 || level >= 1) stop("level deve estar entre 0 e 1.", call. = FALSE)
  metadata <- review_metric_metadata()
  alpha <- 1 - level
  rows <- lapply(c("linear", "logistic"), function(model) {
    summary <- internal_validation[[model]]$summary
    replica_table <- internal_validation[[model]]$table
    do.call(rbind, lapply(seq_len(nrow(summary)), function(i) {
      metric <- summary$metric[[i]]
      values <- replica_table[[paste0("train_", metric)]]
      values <- values[replica_table$status == "valid" & is.finite(values)]
      shift <- summary$corrected[[i]] - summary$apparent[[i]]
      quantiles <- if (length(values)) {
        stats::quantile(values, c(alpha / 2, 1 - alpha / 2), names = FALSE, type = 6)
      } else c(NA_real_, NA_real_)
      meta <- metadata[metadata$model == model & metadata$metric == metric, , drop = FALSE]
      identifiable_interval <- isTRUE(meta$primary_metric[[1L]]) && length(values) && stats::sd(values) > 1e-10
      data.frame(
        model = model, metric = metric, estimate = summary$corrected[[i]],
        ci_lower = if (identifiable_interval) quantiles[[1L]] + shift else NA_real_,
        ci_upper = if (identifiable_interval) quantiles[[2L]] + shift else NA_real_,
        confidence_level = level,
        interval_method = if (identifiable_interval) "location_shifted_percentile_bootstrap" else "unavailable_degenerate_apparent_bootstrap_statistic",
        interval_limitation = if (identifiable_interval) NA_character_ else
          "The apparent calibration/mean-error statistic is fixed by construction in each fitted bootstrap sample; location shifting would create a spuriously degenerate interval.",
        apparent = summary$apparent[[i]], mean_optimism = summary$mean_optimism[[i]],
        location_shift = shift, attempts = nrow(replica_table), n_valid = length(values),
        n_failed_replicas = sum(replica_table$status == "failed"),
        n_metric_unavailable = sum(replica_table$status == "valid" & !is.finite(replica_table[[paste0("train_", metric)]])),
        direction = summary$direction[[i]], unit = meta$unit[[1L]],
        primary_metric = meta$primary_metric[[1L]], target = meta$target[[1L]],
        resampling_unit = "participant", evaluation = "internal_validation_not_external",
        stringsAsFactors = FALSE
      )
    }))
  })
  do.call(rbind, rows)
}

review_bootstrap_failure_audit <- function(internal_validation) {
  do.call(rbind, lapply(c("linear", "logistic"), function(model) {
    tab <- internal_validation[[model]]$table
    reasons <- sort(unique(tab$failure_reason[tab$status == "failed" & !is.na(tab$failure_reason)]))
    reason_rows <- if (length(reasons)) data.frame(
      model = model, record_type = "failed_replica_reason", key = reasons,
      n = vapply(reasons, function(x) sum(tab$status == "failed" & tab$failure_reason == x, na.rm = TRUE), integer(1)),
      denominator = nrow(tab), stringsAsFactors = FALSE
    ) else data.frame(model = model, record_type = "failed_replica_reason", key = "none",
                      n = 0L, denominator = nrow(tab), stringsAsFactors = FALSE)
    metric_columns <- grep("^train_", names(tab), value = TRUE)
    unavailable <- data.frame(
      model = model, record_type = "metric_unavailable_among_valid_replicas",
      key = sub("^train_", "", metric_columns),
      n = vapply(metric_columns, function(x) sum(tab$status == "valid" & !is.finite(tab[[x]])), integer(1)),
      denominator = sum(tab$status == "valid"), stringsAsFactors = FALSE
    )
    total <- data.frame(model = model, record_type = "failed_replicas_total", key = "all_reasons_once",
                        n = sum(tab$status == "failed"), denominator = nrow(tab), stringsAsFactors = FALSE)
    rbind(total, reason_rows, unavailable)
  }))
}

review_stratified_folds <- function(outcome, folds = 10L, repeats = 5L, seed = 20260909L) {
  outcome <- as.integer(outcome)
  if (folds < 2L || repeats < 1L || any(!outcome %in% c(0L, 1L)))
    stop("Configuração de folds ou desfecho inválido.", call. = FALSE)
  seeds <- derive_replica_seeds(seed, repeats)
  result <- vector("list", repeats)
  for (r in seq_len(repeats)) result[[r]] <- .with_local_seed(seeds[[r]], {
    assignment <- integer(length(outcome))
    for (class in c(0L, 1L)) {
      index <- sample(which(outcome == class))
      assignment[index] <- rep(seq_len(folds), length.out = length(index))
    }
    lapply(seq_len(folds), function(fold) list(
      repeat_id = r, fold = fold, train = which(assignment != fold), test = which(assignment == fold)
    ))
  })
  unlist(result, recursive = FALSE)
}

fit_fixed_models <- function(data, formulas) {
  list(linear = stats::lm(formulas$linear, data = data),
       logistic = stats::glm(formulas$logistic, data = data, family = stats::binomial()))
}

estimate_training_shrinkage <- function(data, formulas, times = 200L, seed = 20260909L) {
  fits <- fit_fixed_models(data, formulas)
  linear_replicas <- bootstrap_replicates(data, formulas$linear, "gaussian", times = times,
                                          seed = seed, original_data = data)
  logistic_replicas <- bootstrap_replicates(data, formulas$logistic, "binomial", times = times,
                                            seed = seed + 1L, original_data = data)
  apparent_linear <- .metric_values(data, formulas$linear, stats::predict(fits$linear, data), "linear")
  apparent_logistic <- .metric_values(data, formulas$logistic,
                                      stats::predict(fits$logistic, data, type = "response"), "logistic")
  corrected_linear <- consolidate_optimism(linear_replicas, apparent_linear, metric_directions("linear"))
  corrected_logistic <- consolidate_optimism(logistic_replicas, apparent_logistic, metric_directions("logistic"))
  slope <- function(x) x$corrected[x$metric == "calibration_slope"]
  list(
    fits = fits,
    factor_linear = clamp_shrinkage_factor(slope(corrected_linear)),
    factor_logistic = clamp_shrinkage_factor(slope(corrected_logistic)),
    valid_linear = sum(vapply(linear_replicas, function(x) identical(x$status, "valid"), logical(1))),
    valid_logistic = sum(vapply(logistic_replicas, function(x) identical(x$status, "valid"), logical(1))),
    attempts = times
  )
}

review_test_metrics <- function(observed, predicted, model) {
  if (model == "linear") {
    cal <- calibration_linear(observed, predicted)
    return(c(r2 = r_squared(observed, predicted), rmse = rmse(observed, predicted),
             mae = mae(observed, predicted), mean_error = mean_error(observed, predicted),
             calibration_intercept = cal$intercept, calibration_slope = cal$slope))
  }
  cal <- calibration_logistic(observed, predicted)
  c(auc = auc_rank(observed, predicted), brier_score = brier_score(observed, predicted),
    log_loss = log_loss(observed, predicted), calibration_in_the_large = cal$intercept,
    calibration_slope = cal$slope)
}

evaluate_complete_shrinkage <- function(data, formulas, factor_levels = NULL, folds = 10L,
                                        repeats = 5L, inner_times = 200L, seed = 20260909L) {
  splits <- review_stratified_folds(data$delta_cat, folds, repeats, seed)
  fold_seeds <- derive_replica_seeds(seed + 1000L, length(splits))
  predictions <- vector("list", length(splits))
  audit <- vector("list", length(splits))
  for (i in seq_along(splits)) {
    split <- splits[[i]]; train <- data[split$train, , drop = FALSE]; test <- data[split$test, , drop = FALSE]
    estimated <- estimate_training_shrinkage(train, formulas, inner_times, fold_seeds[[i]])
    linear <- build_shrunk_linear_model(estimated$fits$linear, train, estimated$factor_linear, factor_levels)
    logistic <- build_shrunk_logistic_model(estimated$fits$logistic, train, estimated$factor_logistic, factor_levels)
    predictions[[i]] <- data.frame(
      repeat_id = split$repeat_id, fold = split$fold, row_index = split$test,
      observed_linear = test$delta, observed_binary = test$delta_cat,
      predicted_linear = predict(linear, test), predicted_logistic = predict(logistic, test),
      stringsAsFactors = FALSE
    )
    audit[[i]] <- data.frame(
      repeat_id = split$repeat_id, fold = split$fold, n_train = nrow(train), n_test = nrow(test),
      factor_linear = estimated$factor_linear, factor_logistic = estimated$factor_logistic,
      inner_attempts_per_model = inner_times, inner_valid_linear = estimated$valid_linear,
      inner_valid_logistic = estimated$valid_logistic,
      test_used_for_factor = FALSE, test_used_for_intercept = FALSE, stringsAsFactors = FALSE
    )
  }
  predictions <- do.call(rbind, predictions); audit <- do.call(rbind, audit)
  metrics <- do.call(rbind, lapply(sort(unique(predictions$repeat_id)), function(r) {
    current <- predictions[predictions$repeat_id == r, , drop = FALSE]
    linear <- review_test_metrics(current$observed_linear, current$predicted_linear, "linear")
    logistic <- review_test_metrics(current$observed_binary, current$predicted_logistic, "logistic")
    rbind(data.frame(repeat_id = r, model = "linear", metric = names(linear), value = unname(linear)),
          data.frame(repeat_id = r, model = "logistic", metric = names(logistic), value = unname(logistic)))
  }))
  metadata <- review_metric_metadata()
  metrics <- merge(metrics, metadata[, c("model", "metric", "unit")], by = c("model", "metric"), all.x = TRUE)
  metrics$procedure <- "repeated_stratified_10_fold_cv_full_shrinkage"
  metrics$target <- "performance_of_complete_post_shrinkage_development_procedure"
  metrics$evaluation <- "internal_cross_validation_not_external"
  metrics$interval_status <- "distribution_across_repeats_not_confidence_interval"
  list(predictions = predictions, audit = audit, metrics = metrics)
}

fit_heteroscedastic_scale <- function(observed, predicted) {
  residual <- abs(as.numeric(observed) - as.numeric(predicted))
  floor_value <- max(stats::quantile(residual, 0.05, names = FALSE), 1e-3)
  fit <- stats::lm(log(pmax(residual, floor_value)) ~ predicted + I(predicted^2))
  list(fit = fit, floor = floor_value)
}

predict_heteroscedastic_scale <- function(object, predicted) {
  raw <- exp(stats::predict(object$fit, newdata = data.frame(predicted = as.numeric(predicted))))
  pmax(as.numeric(raw), object$floor)
}

conformal_quantile <- function(scores, level = 0.95) {
  scores <- sort(scores[is.finite(scores)])
  if (!length(scores)) stop("Nenhum escore conformal finito.", call. = FALSE)
  scores[[min(length(scores), ceiling((length(scores) + 1) * level))]]
}

evaluate_conformal_prediction_intervals <- function(data, formulas, factor_levels = NULL,
                                                     splits, inner_times = 200L,
                                                     level = 0.95, seed = 20260910L) {
  split_seeds <- derive_replica_seeds(seed, length(splits))
  fold_rows <- vector("list", length(splits))
  for (i in seq_along(splits)) {
    outer <- splits[[i]]; outer_train <- outer$train
    calibration_flag <- .with_local_seed(split_seeds[[i]], {
      flag <- logical(length(outer_train))
      for (class in c(0L, 1L)) {
        local <- which(data$delta_cat[outer_train] == class)
        flag[sample(local, size = max(1L, round(0.20 * length(local))))] <- TRUE
      }
      flag
    })
    proper_index <- outer_train[!calibration_flag]
    calibration_index <- outer_train[calibration_flag]
    proper <- data[proper_index, , drop = FALSE]
    calibration <- data[calibration_index, , drop = FALSE]
    test <- data[outer$test, , drop = FALSE]
    estimated <- estimate_training_shrinkage(proper, formulas, inner_times, split_seeds[[i]] + 1L)
    model <- build_shrunk_linear_model(estimated$fits$linear, proper,
                                       estimated$factor_linear, factor_levels)
    proper_prediction <- predict(model, proper)
    scale_model <- fit_heteroscedastic_scale(proper$delta, proper_prediction)
    calibration_prediction <- predict(model, calibration)
    calibration_scale <- predict_heteroscedastic_scale(scale_model, calibration_prediction)
    q <- conformal_quantile(abs(calibration$delta - calibration_prediction) / calibration_scale, level)
    test_prediction <- predict(model, test)
    test_scale <- predict_heteroscedastic_scale(scale_model, test_prediction)
    lower <- test_prediction - q * test_scale; upper <- test_prediction + q * test_scale
    covered <- test$delta >= lower & test$delta <= upper
    fold_rows[[i]] <- data.frame(
      repeat_id = outer$repeat_id, fold = outer$fold, n_proper_train = nrow(proper),
      n_calibration = nrow(calibration), n_test = nrow(test),
      nominal_coverage = level, observed_coverage = mean(covered),
      mean_width_degrees = mean(upper - lower), median_width_degrees = stats::median(upper - lower),
      min_width_degrees = min(upper - lower), max_width_degrees = max(upper - lower),
      conformal_quantile = q, factor_linear = estimated$factor_linear,
      inner_attempts = inner_times, inner_valid = estimated$valid_linear,
      test_used_for_fit = FALSE, test_used_for_factor = FALSE, test_used_for_intercept = FALSE,
      calibration_used_for_fit = FALSE, calibration_used_for_factor = FALSE,
      interval_method = "normalized_split_conformal_heteroscedastic_scale",
      target = "individual_future_delta_same_population_exchangeability",
      evaluation = "internal_coverage_not_external", stringsAsFactors = FALSE
    )
  }
  fold_rows <- do.call(rbind, fold_rows)
  repeat_rows <- do.call(rbind, lapply(split(fold_rows, fold_rows$repeat_id), function(x) data.frame(
    repeat_id = x$repeat_id[[1L]], folds = nrow(x), denominator_predictions = sum(x$n_test),
    nominal_coverage = level, observed_coverage = weighted.mean(x$observed_coverage, x$n_test),
    mean_width_degrees = weighted.mean(x$mean_width_degrees, x$n_test),
    interval_method = "normalized_split_conformal_heteroscedastic_scale",
    evaluation = "internal_coverage_not_external", stringsAsFactors = FALSE
  )))
  list(folds = fold_rows, repeats = repeat_rows)
}

review_validation_object_table <- function(frozen_results, internal, shrinkage) {
  data.frame(
    object = c("apparent_fit_linear", "apparent_fit_logistic",
               "optimism_corrected_fixed_specification_linear", "optimism_corrected_fixed_specification_logistic",
               "post_shrinkage_equation_linear", "post_shrinkage_equation_logistic"),
    model = rep(c("linear", "logistic"), 3L),
    fitted_on = c(rep("full_development_cohort_n_615", 2L),
                  rep("bootstrap_refits_of_fixed_specification_n_615", 2L),
                  rep("full_development_cohort_n_615", 2L)),
    target = c(rep("apparent_association_and_fit", 2L),
               rep("expected_performance_same_population_n_615", 2L),
               rep("equation_for_future_external_validation", 2L)),
    validation_status = c(rep("apparent_not_validated", 2L),
                          rep("internally_validated_not_external", 2L),
                          rep("procedure_evaluated_internally_not_external", 2L)),
    shrinkage_factor = c(NA, NA, NA, NA,
                         shrinkage$linear$shrinkage_factor, shrinkage$logistic$shrinkage_factor),
    intercept = c(unname(coef(frozen_results$models$linear)[[1L]]),
                  unname(coef(frozen_results$models$logistic)[[1L]]), NA, NA,
                  shrinkage$linear$intercept_recalibrated, shrinkage$logistic$intercept_recalibrated),
    stringsAsFactors = FALSE
  )
}

prediction_interval_availability <- function() {
  data.frame(
    estimand = c("conditional_mean_ci_final_shrunk_equation", "individual_prediction_interval_final_shrunk_equation",
                 "individual_prediction_interval_internal_procedure"),
    status = c("unavailable", "unavailable", "estimated_for_internal_coverage_assessment"),
    reason = c(
      "Historical formula assumes homoscedasticity and omits uncertainty of the estimated shrinkage factor; conformal assessment targets individuals, not the conditional mean.",
      "No observations independent of the all-data final fit remain for honest conformal calibration; historical intervals are not validated.",
      "Normalized split conformal intervals calibrated without using the outer test; coverage and width reported only in unused outer-fold observations."
    ),
    unit = "degrees_delta", external_validation = FALSE, stringsAsFactors = FALSE
  )
}

make_review_equation_text <- function(linear, logistic) {
  c(
    "Equações pós-shrinkage para futura validação externa", "",
    paste("Fator linear:", formatC(linear$shrinkage_factor, format = "fg", digits = 12)),
    paste("Fator logístico:", formatC(logistic$shrinkage_factor, format = "fg", digits = 12)), "",
    paste("Equação linear: delta_previsto =", equation_string(linear), "graus."),
    paste("Equação logística: eta =", equation_string(logistic), "; p(melhora) = plogis(eta)."),
    "Referências: sexo=feminino; Lenke=1; Risser=0; flexibilidade=flexível; escoliômetro=normal.",
    "Coeficientes não interceptais foram multiplicados pelo fator; o intercepto foi recalibrado nos 615 participantes de desenvolvimento.",
    "Avaliação do procedimento completo: validação cruzada interna repetida, com fator e intercepto estimados somente no treinamento de cada fold.",
    "Não houve validação externa.",
    "IC da média e intervalo individual para esta equação final estão indisponíveis: a fórmula histórica não cobre heteroscedasticidade nem incerteza do fator e não resta amostra independente para calibração conformal honesta."
  )
}
