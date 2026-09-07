# Análises de sensibilidade pré-especificadas para os modelos congelados.
#
# As exclusões deste arquivo são temporárias e nunca modificam a coorte ou os
# objetos da análise principal. Tabelas com IDs individuais são gravadas apenas
# em logs internos; tabelas agregadas não expõem linhas clínicas individuais.

sensitivity_influence_criteria <- function(n, n_parameters,
                                           cook_multiplier = 4,
                                           leverage_multiplier = 2,
                                           standardized_threshold = 2) {
  stopifnot(length(n) == 1L, length(n_parameters) == 1L, n > 0, n_parameters > 0)
  data.frame(
    criterion = c("distancia_de_cook", "leverage", "residuo_padronizado"),
    rule = c(
      "Cook > 4 / n",
      "leverage > 2 * p / n",
      "abs(residuo padronizado) > 2"
    ),
    threshold = c(cook_multiplier / n,
                  leverage_multiplier * n_parameters / n,
                  standardized_threshold),
    threshold_definition = c(
      paste0(cook_multiplier, " / ", n),
      paste0(leverage_multiplier, " * ", n_parameters, " / ", n),
      paste0("|residuo| > ", standardized_threshold)
    ),
    n = n,
    parameters_including_intercept = n_parameters,
    stringsAsFactors = FALSE
  )
}

sensitivity_influence_summary <- function(diagnostics, model_name) {
  flags <- c("flag_cook", "flag_leverage", "flag_standardized_residual", "influential_any")
  data.frame(
    model = model_name,
    criterion = flags,
    n_flagged = vapply(flags, function(x) sum(diagnostics[[x]], na.rm = TRUE), integer(1)),
    stringsAsFactors = FALSE
  )
}

sensitivity_safe_calibration <- function(observed, predicted, model) {
  result <- data.frame(
    calibration_intercept = NA_real_, calibration_slope = NA_real_,
    calibration_status = "not_calculated", stringsAsFactors = FALSE
  )
  fit_warnings <- character()
  value <- withCallingHandlers(tryCatch({
    if (model == "linear") {
      if (length(unique(predicted)) < 2L) stop("predicao sem variacao")
      fit <- stats::lm(observed ~ predicted)
      coefficients <- stats::coef(fit)
      if (length(coefficients) < 2L || any(!is.finite(coefficients))) {
        stop("coeficientes nao finitos")
      }
      c(intercept = unname(coefficients[[1]]), slope = unname(coefficients[[2]]))
    } else {
      if (length(unique(observed)) < 2L) stop("desfecho sem variacao")
      lp <- stats::qlogis(pmin(pmax(as.numeric(predicted), 1e-15), 1 - 1e-15))
      intercept_fit <- stats::glm(observed ~ 1 + offset(lp), family = stats::binomial())
      slope_fit <- stats::glm(observed ~ lp, family = stats::binomial())
      coefficients <- c(intercept = unname(stats::coef(intercept_fit)[[1]]),
                        slope = unname(stats::coef(slope_fit)[[2]]))
      if (any(!is.finite(coefficients)) || !isTRUE(slope_fit$converged)) {
        stop("calibracao logistica nao finita ou nao convergente")
      }
      coefficients
    }
  }, error = function(e) e), warning = function(w) {
    fit_warnings <<- c(fit_warnings, conditionMessage(w))
    invokeRestart("muffleWarning")
  })
  if (inherits(value, "error")) {
    result$calibration_status <- paste0("falhou: ", conditionMessage(value))
  } else {
    result$calibration_intercept <- value[["intercept"]]
    result$calibration_slope <- value[["slope"]]
    result$calibration_status <- if (length(fit_warnings)) {
      paste0("ok_com_warning: ", paste(unique(fit_warnings), collapse = " | "))
    } else "ok"
  }
  result
}

sensitivity_metric_row <- function(observed, predicted, model, scenario, scope,
                                   n_parameters) {
  if (model == "linear") {
    keep <- stats::complete.cases(observed, predicted)
    y <- as.numeric(observed[keep]); p <- as.numeric(predicted[keep])
    sst <- sum((y - mean(y))^2)
    r2_value <- if (sst == 0) NA_real_ else 1 - sum((y - p)^2) / sst
    r2_adjusted <- if (length(y) > n_parameters + 1L && is.finite(r2_value)) {
      1 - (1 - r2_value) * (length(y) - 1) / (length(y) - n_parameters - 1)
    } else NA_real_
    data.frame(
      scenario = scenario, model = model, scope = scope, n = length(y),
      events = NA_integer_, nonevents = NA_integer_, prevalence = NA_real_,
      r2 = r2_value, r2_adjusted = r2_adjusted, rmse = sqrt(mean((y - p)^2)),
      mae = mean(abs(y - p)), mean_error = mean(y - p), auc = NA_real_,
      brier_score = NA_real_, log_loss = NA_real_, stringsAsFactors = FALSE
    )
  } else {
    keep <- stats::complete.cases(observed, predicted)
    y <- as.numeric(observed[keep]); p <- pmin(pmax(as.numeric(predicted[keep]), 1e-15), 1 - 1e-15)
    events <- sum(y == 1L); nonevents <- sum(y == 0L)
    auc_value <- if (events > 0L && nonevents > 0L) {
      ranks <- rank(p, ties.method = "average")
      (sum(ranks[y == 1L]) - events * (events + 1) / 2) / (events * nonevents)
    } else NA_real_
    data.frame(
      scenario = scenario, model = model, scope = scope, n = length(y),
      events = events, nonevents = nonevents, prevalence = mean(y),
      r2 = NA_real_, r2_adjusted = NA_real_, rmse = NA_real_, mae = NA_real_,
      mean_error = NA_real_, auc = auc_value,
      brier_score = mean((y - p)^2),
      log_loss = -mean(y * log(p) + (1 - y) * log1p(-p)),
      stringsAsFactors = FALSE
    )
  }
}

sensitivity_fit_model <- function(cohort, model = c("linear", "logistic"),
                                   scenario = "sensitivity", exclude_ids = integer()) {
  model <- match.arg(model)
  response <- if (model == "linear") "delta" else "delta_cat"
  formula <- stats::reformulate(MODEL_PREDICTORS, response = response)
  retained <- !(cohort$id %in% exclude_ids)
  analysis <- cohort[retained, , drop = FALSE]
  if (nrow(analysis) <= length(MODEL_PREDICTORS) + 1L) {
    stop("Exclusao deixou poucas observacoes para o ajuste de sensibilidade.")
  }
  if (model == "logistic" && length(unique(analysis$delta_cat)) < 2L) {
    stop("Exclusao deixou o desfecho logistico sem variacao.")
  }

  fit_warnings <- character()
  fit <- withCallingHandlers({
    if (model == "linear") {
      stats::lm(formula, data = analysis, model = FALSE, x = FALSE, y = FALSE)
    } else {
      stats::glm(formula, data = analysis, family = stats::binomial(),
                 model = FALSE, x = FALSE, y = FALSE)
    }
  }, warning = function(w) {
    fit_warnings <<- c(fit_warnings, conditionMessage(w))
    invokeRestart("muffleWarning")
  })
  if (model == "logistic" && !isTRUE(fit$converged)) stop("Ajuste logistico nao convergiu.")
  coefficients <- stats::coef(fit)
  if (any(!is.finite(coefficients))) stop("Coeficientes nao finitos no ajuste de sensibilidade.")

  p_retained <- as.numeric(stats::predict(fit, newdata = analysis, type = "response"))
  p_all <- as.numeric(stats::predict(fit, newdata = cohort, type = "response"))
  y_retained <- if (model == "linear") analysis$delta else analysis$delta_cat
  y_all <- if (model == "linear") cohort$delta else cohort$delta_cat
  n_parameters <- length(coefficients)
  metrics <- rbind(
    sensitivity_metric_row(y_retained, p_retained, model, scenario,
                           "fit_subset_aparente", n_parameters),
    sensitivity_metric_row(y_all, p_all, model, scenario,
                           "coorte_completa_615", n_parameters)
  )
  calibration <- rbind(
    cbind(scenario = scenario, model = model, scope = "fit_subset_aparente",
          n = nrow(analysis),
          sensitivity_safe_calibration(y_retained, p_retained, model)),
    cbind(scenario = scenario, model = model, scope = "coorte_completa_615",
          n = nrow(cohort), sensitivity_safe_calibration(y_all, p_all, model))
  )
  list(
    scenario = scenario, model = model, exclude_ids = as.integer(exclude_ids),
    retained = retained, n_fit = nrow(analysis), fit = fit,
    predictions_all = p_all, predictions_retained = p_retained,
    metrics = metrics, calibration = calibration,
    coefficients = coefficients, warnings = unique(fit_warnings), formula = formula
  )
}

sensitivity_primary_model <- function(cohort, main_results, model = c("linear", "logistic")) {
  model <- match.arg(model)
  fit <- main_results$models[[model]]
  p <- as.numeric(stats::fitted(fit))
  y <- if (model == "linear") cohort$delta else cohort$delta_cat
  scenario <- "principal"
  n_parameters <- length(stats::coef(fit))
  list(
    scenario = scenario, model = model, exclude_ids = integer(),
    retained = rep(TRUE, nrow(cohort)), n_fit = nrow(cohort), fit = fit,
    predictions_all = p, predictions_retained = p,
    metrics = rbind(
      sensitivity_metric_row(y, p, model, scenario, "fit_subset_aparente", n_parameters),
      sensitivity_metric_row(y, p, model, scenario, "coorte_completa_615", n_parameters)
    ),
    calibration = rbind(
      cbind(scenario = scenario, model = model, scope = "fit_subset_aparente", n = nrow(cohort),
            sensitivity_safe_calibration(y, p, model)),
      cbind(scenario = scenario, model = model, scope = "coorte_completa_615", n = nrow(cohort),
            sensitivity_safe_calibration(y, p, model))
    ),
    coefficients = stats::coef(fit), warnings = attr(fit, "fit_warnings"),
    formula = main_results$models$formulas[[model]]
  )
}

sensitivity_coefficient_comparison <- function(primary, alternative) {
  terms <- union(names(primary$coefficients), names(alternative$coefficients))
  p <- unname(primary$coefficients[terms])
  s <- unname(alternative$coefficients[terms])
  relative <- abs(s - p) / pmax(abs(p), 1e-12)
  data.frame(
    scenario = alternative$scenario, model = alternative$model, term = terms,
    primary_estimate = p, sensitivity_estimate = s,
    difference = s - p, absolute_difference = abs(s - p),
    absolute_relative_change = relative,
    sign_changed = is.finite(p) & is.finite(s) & p != 0 & s != 0 & sign(p) != sign(s),
    stringsAsFactors = FALSE
  )
}

sensitivity_prediction_comparison <- function(cohort, primary, alternative) {
  difference <- alternative$predictions_all - primary$predictions_all
  data.frame(
    id = cohort$id, scenario = alternative$scenario, model = alternative$model,
    primary_prediction = primary$predictions_all,
    sensitivity_prediction = alternative$predictions_all,
    difference = difference,
    absolute_difference = abs(difference),
    excluded_in_sensitivity = cohort$id %in% alternative$exclude_ids,
    stringsAsFactors = FALSE
  )
}

sensitivity_prediction_summary <- function(predictions) {
  do.call(rbind, lapply(split(predictions, list(predictions$scenario, predictions$model), drop = TRUE), function(x) {
    data.frame(
      scenario = x$scenario[[1]], model = x$model[[1]], n_predictions = nrow(x),
      n_excluded = sum(x$excluded_in_sensitivity), mean_difference = mean(x$difference),
      mean_absolute_difference = mean(x$absolute_difference),
      median_absolute_difference = stats::median(x$absolute_difference),
      max_absolute_difference = max(x$absolute_difference),
      mean_absolute_difference_retained = mean(x$absolute_difference[!x$excluded_in_sensitivity]),
      mean_absolute_difference_excluded = if (any(x$excluded_in_sensitivity)) {
        mean(x$absolute_difference[x$excluded_in_sensitivity])
      } else NA_real_,
      stringsAsFactors = FALSE
    )
  }))
}

sensitivity_prediction_bands <- function(predicted, groups = 4L) {
  if (length(predicted) == 0L) return(character())
  rank_order <- rank(predicted, ties.method = "first")
  band <- pmin(groups, pmax(1L, ceiling(rank_order / length(predicted) * groups)))
  paste0("Q", band)
}

sensitivity_strata <- function(cohort, main_results, minimum_n = 20L) {
  p_linear <- as.numeric(stats::fitted(main_results$models$linear))
  p_logistic <- as.numeric(stats::fitted(main_results$models$logistic))
  groups <- list(
    faixa_previsao_delta = sensitivity_prediction_bands(p_linear),
    faixa_previsao_probabilidade = sensitivity_prediction_bands(p_logistic),
    sexo = as.character(cohort$sexo),
    lenke = as.character(cohort$lenke),
    risser = as.character(cohort$risser),
    flexibilidade = as.character(cohort$flexibilidade),
    escoliometro_maior_10_graus = as.character(cohort$escoliometro_maior_10_graus)
  )
  rows <- list()
  index <- 0L
  for (variable in names(groups)) {
    levels <- unique(groups[[variable]])
    levels <- levels[!is.na(levels)]
    for (level in levels) {
      take <- !is.na(groups[[variable]]) & groups[[variable]] == level
      index <- index + 1L
      y_linear <- cohort$delta[take]; p1 <- p_linear[take]
      y_logistic <- cohort$delta_cat[take]; p2 <- p_logistic[take]
      l_metrics <- sensitivity_metric_row(y_linear, p1, "linear", "principal", "estrato", length(stats::coef(main_results$models$linear)))
      b_metrics <- sensitivity_metric_row(y_logistic, p2, "logistic", "principal", "estrato", length(stats::coef(main_results$models$logistic)))
      l_cal <- sensitivity_safe_calibration(y_linear, p1, "linear")
      b_cal <- sensitivity_safe_calibration(y_logistic, p2, "logistic")
      rows[[index]] <- data.frame(
        stratum_variable = variable, stratum = level, n = sum(take),
        n_events = sum(y_logistic == 1L), n_nonevents = sum(y_logistic == 0L),
        small_stratum = sum(take) < minimum_n,
        descriptive_eligible = sum(take) >= minimum_n,
        mean_delta_observed = mean(y_linear), mean_delta_predicted = mean(p1),
        delta_rmse = l_metrics$rmse, delta_mae = l_metrics$mae,
        delta_mean_error = l_metrics$mean_error,
        delta_calibration_intercept = l_cal$calibration_intercept,
        delta_calibration_slope = l_cal$calibration_slope,
        delta_calibration_status = l_cal$calibration_status,
        probability_observed = mean(y_logistic), probability_predicted = mean(p2),
        probability_auc = b_metrics$auc, probability_brier = b_metrics$brier_score,
        probability_log_loss = b_metrics$log_loss,
        probability_calibration_intercept = b_cal$calibration_intercept,
        probability_calibration_slope = b_cal$calibration_slope,
        probability_calibration_status = b_cal$calibration_status,
        stringsAsFactors = FALSE
      )
    }
  }
  do.call(rbind, rows)
}

sensitivity_cobb_target <- function(cohort, main_results) {
  predictors <- c("cobb_inicial_maior", MODEL_PREDICTORS)
  formula <- stats::reformulate(predictors, response = "maior_curva_6_meses")
  fit <- stats::lm(formula, data = cohort, model = FALSE, x = FALSE, y = FALSE)
  p <- as.numeric(stats::fitted(fit))
  y <- cohort$maior_curva_6_meses
  alternative_metrics <- sensitivity_metric_row(y, p, "linear", "alvo_alternativo", "coorte_completa_615", length(stats::coef(fit)))
  alternative_metrics$model <- "cobb_6_meses_condicionado"
  delta_fit <- main_results$models$linear
  delta_p <- as.numeric(stats::fitted(delta_fit))
  delta_metrics <- sensitivity_metric_row(cohort$delta, delta_p, "linear", "alvo_principal", "coorte_completa_615", length(stats::coef(delta_fit)))
  delta_metrics$model <- "delta"
  alternative_cal <- sensitivity_safe_calibration(y, p, "linear")
  delta_cal <- sensitivity_safe_calibration(cohort$delta, delta_p, "linear")
  metrics <- rbind(alternative_metrics, delta_metrics)
  metrics$target_scale <- c("graus_Cobb_6_meses", "graus_delta")
  calibration <- rbind(
    data.frame(target = "cobb_6_meses_condicionado", scope = "coorte_completa_615", n = nrow(cohort), alternative_cal, stringsAsFactors = FALSE),
    data.frame(target = "delta", scope = "coorte_completa_615", n = nrow(cohort), delta_cal, stringsAsFactors = FALSE)
  )
  list(
    formula = formula, fit = fit, predictions = p, metrics = metrics,
    calibration = calibration,
    coefficients = data.frame(term = names(stats::coef(fit)), estimate = unname(stats::coef(fit)),
                               stringsAsFactors = FALSE),
    baseline_mean = mean(cohort$cobb_inicial_maior),
    six_month_mean = mean(cohort$maior_curva_6_meses),
    delta_mean = mean(cohort$delta)
  )
}

sensitivity_anatomical_region_summary <- function(cohort) {
  regions <- as.character(cohort$regiao_cobb_inicial)
  levels <- sort(unique(regions))
  data.frame(
    region_at_baseline = levels,
    n = vapply(levels, function(x) sum(regions == x), integer(1)),
    source_contains_six_month_region = FALSE,
    interpretation = "A base fornece apenas a magnitude maxima aos 6 meses; a regiao aos 6 meses nao pode ser identificada.",
    stringsAsFactors = FALSE
  )
}

run_sensitivity_analysis <- function(cohort, main_results, write_outputs = FALSE) {
  if (nrow(cohort) != 615L) stop("A análise principal da sensibilidade deve conter 615 participantes.")
  if (!identical(sort(cohort$id), sort(unique(cohort$id)))) stop("IDs repetidos na coorte principal.")
  hyper_ids <- c(81L, 174L, 401L)
  if (!all(hyper_ids %in% cohort$id) || any(cohort$correcao_colete[match(hyper_ids, cohort$id)] <= 100)) {
    stop("As hipercorreções pré-especificadas não estão intactas na coorte principal.")
  }

  diagnostics <- list(linear = main_results$residual_linear,
                      logistic = main_results$residual_logistic)
  criteria <- rbind(
    cbind(model = "linear", sensitivity_influence_criteria(nrow(cohort), length(stats::coef(main_results$models$linear)))),
    cbind(model = "logistic", sensitivity_influence_criteria(nrow(cohort), length(stats::coef(main_results$models$logistic))))
  )
  influence_summary <- rbind(
    sensitivity_influence_summary(diagnostics$linear, "linear"),
    sensitivity_influence_summary(diagnostics$logistic, "logistic")
  )
  flagged_linear <- diagnostics$linear$id[diagnostics$linear$influential_any]
  flagged_logistic <- diagnostics$logistic$id[diagnostics$logistic$influential_any]
  flagged_union <- sort(unique(c(flagged_linear, flagged_logistic)))
  exclusions <- data.frame(
    scenario = c("principal", "influential_linear", "influential_logistic", "influential_union", "hypercorrection"),
    exclusion_basis = c("nenhuma exclusao", "qualquer criterio no modelo linear",
                        "qualquer criterio no modelo logistico", "uniao dos dois modelos",
                        "IDs de hipercorrecao pre-especificados"),
    n_excluded = c(0L, length(flagged_linear), length(flagged_logistic), length(flagged_union), length(hyper_ids)),
    excluded_ids_internal = c("", paste(flagged_linear, collapse = ","), paste(flagged_logistic, collapse = ","),
                              paste(flagged_union, collapse = ","), paste(hyper_ids, collapse = ",")),
    stringsAsFactors = FALSE
  )

  scenario_ids <- list(
    principal = integer(), influential_linear = flagged_linear,
    influential_logistic = flagged_logistic, influential_union = flagged_union,
    hypercorrection = hyper_ids
  )
  model_results <- list()
  for (scenario in names(scenario_ids)) {
    for (model in c("linear", "logistic")) {
      key <- paste(scenario, model, sep = "__")
      model_results[[key]] <- if (scenario == "principal") {
        sensitivity_primary_model(cohort, main_results, model)
      } else {
        sensitivity_fit_model(cohort, model, scenario, scenario_ids[[scenario]])
      }
    }
  }

  metrics <- do.call(rbind, lapply(model_results, function(x) x$metrics))
  calibration <- do.call(rbind, lapply(model_results, function(x) x$calibration))
  comparison_scenarios <- setdiff(names(scenario_ids), "principal")
  coefficients <- do.call(rbind, lapply(comparison_scenarios, function(scenario) {
    do.call(rbind, lapply(c("linear", "logistic"), function(model) {
      sensitivity_coefficient_comparison(model_results[[paste("principal", model, sep = "__")]],
                                         model_results[[paste(scenario, model, sep = "__")]])
    }))
  }))
  prediction_comparisons <- do.call(rbind, lapply(comparison_scenarios, function(scenario) {
    do.call(rbind, lapply(c("linear", "logistic"), function(model) {
      sensitivity_prediction_comparison(cohort,
        model_results[[paste("principal", model, sep = "__")]],
        model_results[[paste(scenario, model, sep = "__")]])
    }))
  }))
  prediction_summary <- sensitivity_prediction_summary(prediction_comparisons)
  alternative <- sensitivity_cobb_target(cohort, main_results)
  result <- list(
    criteria = criteria, influence_summary = influence_summary,
    influence_diagnostics = diagnostics,
    exclusions = exclusions, flagged_linear = flagged_linear,
    flagged_logistic = flagged_logistic, flagged_union = flagged_union,
    model_results = model_results, metrics = metrics, calibration = calibration,
    coefficients = coefficients, prediction_comparisons = prediction_comparisons,
    prediction_summary = prediction_summary,
    strata = sensitivity_strata(cohort, main_results),
    cobb_target = alternative,
    anatomical_region = sensitivity_anatomical_region_summary(cohort),
    n_primary = nrow(cohort), hyper_ids = hyper_ids
  )
  if (isTRUE(write_outputs)) write_sensitivity_outputs(result, cohort)
  result
}

write_sensitivity_outputs <- function(result, cohort) {
  ensure_output_dirs()
  agg <- RESULTS_DIRS[["aggregated"]]
  log <- RESULTS_DIRS[["logs"]]
  obj <- RESULTS_DIRS[["reduced_objects"]]
  write <- function(x, filename, directory = agg) {
    utils::write.csv(x, file.path(directory, filename), row.names = FALSE, na = "")
  }
  write(result$criteria, "sensitivity_influence_criteria.csv")
  write(result$influence_summary, "sensitivity_influence_summary.csv")
  write(result$exclusions[, c("scenario", "exclusion_basis", "n_excluded")], "sensitivity_exclusion_summary.csv")
  write(result$metrics, "sensitivity_scenario_metrics.csv")
  write(result$calibration, "sensitivity_scenario_calibration.csv")
  write(result$coefficients, "sensitivity_coefficient_comparison.csv")
  write(result$prediction_summary, "sensitivity_prediction_change_summary.csv")
  write(result$strata, "sensitivity_strata_descriptive.csv")
  write(result$cobb_target$metrics, "sensitivity_cobb_target_metrics.csv")
  write(result$cobb_target$calibration, "sensitivity_cobb_target_calibration.csv")
  write(result$cobb_target$coefficients, "sensitivity_cobb_target_coefficients.csv")
  write(result$anatomical_region, "sensitivity_anatomical_region_summary.csv")

  warning_rows <- do.call(rbind, lapply(result$model_results, function(x) {
    data.frame(scenario = x$scenario, model = x$model,
               warnings = if (length(x$warnings)) paste(x$warnings, collapse = " | ") else "",
               stringsAsFactors = FALSE)
  }))
  write(warning_rows, "sensitivity_fit_warnings.csv", log)

  write(result$exclusions, "sensitivity_exclusion_summary_internal.csv", log)
  write(subset(result$influence_diagnostics$linear, influential_any),
        "sensitivity_influential_observations_linear.csv", log)
  write(subset(result$influence_diagnostics$logistic, influential_any),
        "sensitivity_influential_observations_logistic.csv", log)
  write(result$prediction_comparisons, "sensitivity_prediction_comparisons_internal.csv", log)
  write(data.frame(id = cohort$id, correcao_colete = cohort$correcao_colete,
                   in_primary = TRUE, hypercorrection_pre_specified = cohort$id %in% result$hyper_ids),
        "sensitivity_cohort_integrity_internal.csv", log)

  saveRDS(list(
    criteria = result$criteria, influence_summary = result$influence_summary,
    exclusions = result$exclusions, metrics = result$metrics,
    calibration = result$calibration, coefficients = result$coefficients,
    prediction_summary = result$prediction_summary, strata = result$strata,
    cobb_target_metrics = result$cobb_target$metrics,
    cobb_target_calibration = result$cobb_target$calibration,
    anatomical_region = result$anatomical_region, n_primary = result$n_primary
  ), file.path(obj, "sensitivity_results_reduced.rds"))

  fmt <- function(x, digits = 3) formatC(x, format = "f", digits = digits)
  linear_flags <- result$influence_summary$n_flagged[result$influence_summary$model == "linear" & result$influence_summary$criterion == "influential_any"]
  logistic_flags <- result$influence_summary$n_flagged[result$influence_summary$model == "logistic" & result$influence_summary$criterion == "influential_any"]
  alternative_metrics <- result$cobb_target$metrics
  discussion <- c(
    "# Análises de sensibilidade — texto para relatório e manuscrito",
    "",
    "As comparações foram definidas antes do reajuste: distância de Cook > 4/n, leverage > 2p/n e resíduo padronizado absoluto > 2. Os casos sinalizados foram retirados apenas nos cenários de sensibilidade; a análise principal permaneceu com todos os 615 participantes.",
    "",
    paste0("Foram sinalizados ", linear_flags, " participantes pelo critério combinado no modelo linear e ", logistic_flags, " no modelo logístico. Esses números descrevem observações a investigar e não constituem uma regra automática de exclusão.",
           " Os coeficientes, métricas, calibração e previsões foram comparados quantitativamente após cada exclusão temporária."),
    "",
    "A sensibilidade às hipercorreções foi avaliada retirando temporariamente os três casos pré-especificados. Eles permaneceram intactos na coorte e na análise principal. Assim, qualquer diferença observada pertence exclusivamente ao cenário de sensibilidade.",
    "",
    paste0("O alvo alternativo foi o Cobb aos seis meses condicionado ao Cobb basal, com a mesma estrutura de preditores. No ajuste aparente, R² = ",
           fmt(alternative_metrics$r2[alternative_metrics$model == "cobb_6_meses_condicionado"]),
           " e RMSE = ", fmt(alternative_metrics$rmse[alternative_metrics$model == "cobb_6_meses_condicionado"]),
           "; para delta, R² = ", fmt(alternative_metrics$r2[alternative_metrics$model == "delta"]),
           " e RMSE = ", fmt(alternative_metrics$rmse[alternative_metrics$model == "delta"]), "."),
    " Esses valores não selecionam retrospectivamente o desfecho: R² não é suficiente para escolher entre alvos em escalas clínicas diferentes. A decisão deve considerar a pergunta clínica, a escala do erro, a calibração e a interpretabilidade.",
    "",
    "A interpretação deve considerar regressão à média, erro de mensuração e a possibilidade de que a região anatômica da maior curva mude entre avaliações. A base disponível registra a região da maior curva basal, mas apenas a magnitude máxima aos seis meses; portanto, mudança de região não pode ser quantificada neste conjunto e permanece uma limitação.",
    "",
    paste0("As tabelas descritivas por faixa de previsão, sexo e categorias clínicas incluem contagens. Estratos com n < 20 foram marcados como pequenos e não recebem conclusões fortes nem testes de interação; não foram executados testes de subgrupo ou interações não pré-especificados."),
    "",
    "As métricas apresentadas são aparentes quando identificadas como tais. As exclusões não foram incorporadas silenciosamente ao modelo final, e a análise de sensibilidade não substitui validação externa."
  )
  writeLines(discussion, file.path(agg, "sensitivity_discussion.md"))
  writeLines(c(
    "Tarefa 10 — verificação das análises de sensibilidade",
    paste("data_execucao:", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
    paste("n_principal:", result$n_primary),
    paste("hipercorrecoes_na_principal:", paste(result$hyper_ids, collapse = ", ")),
    paste("n_influentes_linear:", length(result$flagged_linear)),
    paste("n_influentes_logistico:", length(result$flagged_logistic)),
    "casos retirados aparecem somente nos cenarios de sensibilidade e logs internos",
    "nenhuma exclusao foi incorporada ao modelo principal",
    "nenhum teste de subgrupo ou interacao nao pre-especificado foi executado",
    "regiao anatomica aos seis meses nao disponivel na fonte"
  ), file.path(log, "sensitivity_verification.txt"))
  invisible(TRUE)
}
