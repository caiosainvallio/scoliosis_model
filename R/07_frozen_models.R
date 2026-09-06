# Ajuste e diagnóstico dos modelos prognósticos congelados.
# Este arquivo não faz seleção de variáveis, transformação não pré-especificada,
# splines ou interações. Todos os objetos individuais permanecem fora das tabelas.

frozen_model_formulas <- function() {
  list(
    linear = stats::reformulate(MODEL_PREDICTORS, response = "delta"),
    logistic = stats::reformulate(MODEL_PREDICTORS, response = "delta_cat")
  )
}

assert_frozen_specification <- function(cohort) {
  formulas <- frozen_model_formulas()
  x <- stats::model.matrix(stats::delete.response(stats::terms(formulas$linear)), cohort)
  expected_terms <- c("idade", "imc", "cifose_toracica", "lordose_lombar",
                      "correcao_colete", "sexo", "lenke", "risser",
                      "flexibilidade", "escoliometro_maior_10_graus")
  stopifnot(identical(MODEL_PREDICTORS, expected_terms), ncol(x) == 20L)
  stopifnot(qr(x)$rank == ncol(x), nrow(x) == 615L)
  stopifnot(identical(as.character(cohort$delta_cat), as.character(as.integer(cohort$delta_cat))))
  invisible(list(formulas = formulas, design = x))
}

fit_frozen_models <- function(cohort) {
  specification <- assert_frozen_specification(cohort)
  linear_formula <- specification$formulas$linear
  logistic_formula <- specification$formulas$logistic
  warnings <- character()
  logistic <- withCallingHandlers(
    do.call(stats::glm, list(formula = logistic_formula, data = cohort,
                             family = stats::binomial(), model = FALSE, x = FALSE, y = FALSE)),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  linear <- do.call(stats::lm, list(formula = linear_formula, data = cohort,
                                    model = FALSE, x = FALSE, y = FALSE))
  logistic_design <- stats::model.matrix(stats::delete.response(stats::terms(logistic_formula)), cohort)
  if (!identical(colnames(specification$design), colnames(logistic_design)) ||
      !identical(specification$design, logistic_design)) {
    stop("Os modelos não recebem a mesma matriz de preditores na mesma ordenação.")
  }
  if (length(warnings)) attr(logistic, "fit_warnings") <- unique(warnings)
  if (!isTRUE(logistic$converged)) stop("O modelo logístico não convergiu.")
  if (any(!is.finite(stats::coef(logistic))) || any(!is.finite(stats::coef(linear)))) {
    stop("Há coeficientes não finitos no ajuste final.")
  }
  list(linear = linear, logistic = logistic, design = specification$design,
       design_logistic = logistic_design,
       formulas = specification$formulas)
}

wald_coefficient_table <- function(model, scale = c("linear", "logit")) {
  scale <- match.arg(scale)
  s <- summary(model)$coefficients
  ci <- suppressWarnings(stats::confint.default(model))
  result <- data.frame(
    term = rownames(s), estimate = unname(s[, 1]), std_error = unname(s[, 2]),
    statistic = unname(s[, 3]), p_value = unname(s[, 4]),
    conf_low = ci[, 1], conf_high = ci[, 2],
    escala = scale, stringsAsFactors = FALSE, row.names = NULL
  )
  result
}

odds_ratio_table <- function(logistic) {
  coefficients <- wald_coefficient_table(logistic, "logit")
  result <- data.frame(
    term = coefficients$term,
    odds_ratio = exp(coefficients$estimate),
    conf_low = exp(coefficients$conf_low),
    conf_high = exp(coefficients$conf_high),
    stringsAsFactors = FALSE
  )
}

linear_metrics <- function(observed, predicted, n_parameters) {
  keep <- stats::complete.cases(observed, predicted)
  y <- as.numeric(observed[keep]); p <- as.numeric(predicted[keep])
  residual <- y - p
  sst <- sum((y - mean(y))^2)
  sse <- sum(residual^2)
  r2 <- 1 - sse / sst
  n <- length(y)
  data.frame(
    n = n, r2 = r2, r2_adjusted = 1 - (1 - r2) * (n - 1) / (n - n_parameters - 1),
    rmse = sqrt(mean(residual^2)), mae = mean(abs(residual)),
    mean_error = mean(residual), stringsAsFactors = FALSE
  )
}

auc_rank <- function(observed, predicted) {
  keep <- stats::complete.cases(observed, predicted)
  y <- as.integer(observed[keep]); p <- as.numeric(predicted[keep])
  n_event <- sum(y == 1L); n_nonevent <- sum(y == 0L)
  if (n_event == 0L || n_nonevent == 0L) stop("AUC exige eventos e não eventos.")
  ranks <- rank(p, ties.method = "average")
  (sum(ranks[y == 1L]) - n_event * (n_event + 1) / 2) / (n_event * n_nonevent)
}

auc_wald_ci <- function(auc, n_event, n_nonevent, level = 0.95) {
  q1 <- auc / (2 - auc)
  q2 <- 2 * auc^2 / (1 + auc)
  se <- sqrt((auc * (1 - auc) + (n_event - 1) * (q1 - auc^2) +
                (n_nonevent - 1) * (q2 - auc^2)) / (n_event * n_nonevent))
  z <- stats::qnorm(1 - (1 - level) / 2)
  pmax(0, auc - z * se) |> c(pmin(1, auc + z * se))
}

auc_reference <- function(observed, predicted) {
  if (requireNamespace("pROC", quietly = TRUE)) {
    return(as.numeric(pROC::auc(pROC::roc(observed, predicted, quiet = TRUE,
                                           direction = "<"))))
  }
  # Wilcoxon-Mann-Whitney é a formulação de referência da AUC, inclusive para empates.
  y <- as.integer(observed)
  event <- predicted[y == 1L]; nonevent <- predicted[y == 0L]
  test <- stats::wilcox.test(event, nonevent, exact = FALSE, correct = FALSE)
  as.numeric(test$statistic) / (length(event) * length(nonevent))
}

logistic_metrics <- function(observed, predicted) {
  keep <- stats::complete.cases(observed, predicted)
  y <- as.numeric(observed[keep]); p <- pmin(pmax(as.numeric(predicted[keep]), 1e-15), 1 - 1e-15)
  auc <- auc_rank(y, p)
  auc_ci <- auc_wald_ci(auc, sum(y == 1), sum(y == 0))
  data.frame(
    n = length(y), events = sum(y == 1), nonevents = sum(y == 0), prevalence = mean(y),
    auc = auc, auc_ci_lower = auc_ci[[1]], auc_ci_upper = auc_ci[[2]],
    brier_score = mean((y - p)^2),
    log_loss = -mean(y * log(p) + (1 - y) * log1p(-p)),
    probability_min = min(p), probability_median = median(p), probability_max = max(p),
    stringsAsFactors = FALSE
  )
}

metric_equivalence <- function(y, p, logistic_model) {
  own <- logistic_metrics(y, p)
  ref_auc <- auc_reference(y, p)
  result <- data.frame(
    metric = c("auc", "brier_score", "log_loss"),
    own = c(own$auc, own$brier_score, own$log_loss),
    reference = c(ref_auc, mean((as.numeric(y) - p)^2),
                  -mean(as.numeric(y) * log(pmin(pmax(p, 1e-15), 1 - 1e-15)) +
                          (1 - as.numeric(y)) * log1p(-pmin(pmax(p, 1e-15), 1 - 1e-15)))),
    tolerance = c(1e-12, 1e-12, 1e-12),
    stringsAsFactors = FALSE
  )
  result$abs_difference <- abs(result$own - result$reference)
  result$equivalent <- result$abs_difference <= result$tolerance
  result$reference_method <- if (requireNamespace("pROC", quietly = TRUE)) "pROC" else "Wilcoxon-Mann-Whitney"
  result
}

calibration_apparent <- function(y_linear, p_linear, y_logistic, p_logistic) {
  linear <- stats::lm(y_linear ~ p_linear)
  lp <- stats::qlogis(pmin(pmax(p_logistic, 1e-15), 1 - 1e-15))
  intercept <- stats::glm(y_logistic ~ 1 + offset(lp), family = stats::binomial())
  slope <- stats::glm(y_logistic ~ lp, family = stats::binomial())
  summary <- data.frame(
    model = c("linear", "logistic"),
    calibration_intercept = c(unname(stats::coef(linear)[1]), unname(stats::coef(intercept)[1])),
    calibration_slope = c(unname(stats::coef(linear)[2]), unname(stats::coef(slope)[2])),
    intercept_expected_by_construction = TRUE, slope_expected_by_construction = TRUE,
    stringsAsFactors = FALSE
  )
  list(summary = summary, linear_coefficients = wald_coefficient_table(linear, "linear"),
       groups = calibration_groups(y_logistic, p_logistic))
}

calibration_groups <- function(observed, predicted, groups = 10L) {
  keep <- stats::complete.cases(observed, predicted)
  y <- as.numeric(observed[keep]); p <- as.numeric(predicted[keep])
  breaks <- unique(stats::quantile(p, probs = seq(0, 1, length.out = groups + 1), names = FALSE))
  if (length(breaks) < 2L) {
    return(data.frame(group = 1L, n = length(y), mean_predicted = mean(p),
                      mean_observed = mean(y), stringsAsFactors = FALSE))
  }
  bin <- cut(p, breaks = breaks, include.lowest = TRUE, labels = FALSE)
  groups_out <- lapply(sort(unique(bin)), function(g) {
    take <- bin == g
    data.frame(group = as.integer(g), n = sum(take), mean_predicted = mean(p[take]),
               mean_observed = mean(y[take]), stringsAsFactors = FALSE)
  })
  do.call(rbind, groups_out)
}

design_and_collinearity <- function(design, linear, logistic, cohort) {
  p <- ncol(design)
  rank <- data.frame(
    model = c("linear", "logistic"), number_columns = c(p, p),
    rank = c(qr(design)$rank, qr(design)$rank),
    full_rank = c(qr(design)$rank == p, qr(design)$rank == p),
    condition_number = c(kappa(design, exact = TRUE), kappa(design, exact = TRUE)),
    stringsAsFactors = FALSE
  )
  vif_rows <- list()
  if (requireNamespace("car", quietly = TRUE)) {
    for (model_name in c("linear", "logistic")) {
      v <- car::vif(if (model_name == "linear") linear else logistic)
      if (is.matrix(v)) {
        vif_rows[[model_name]] <- data.frame(
          model = model_name, term = rownames(v), gvif = v[, 1], df = v[, 2],
          gvif_adjusted = v[, 3], stringsAsFactors = FALSE
        )
      } else {
        vif_rows[[model_name]] <- data.frame(
          model = model_name, term = names(v), gvif = as.numeric(v), df = 1,
          gvif_adjusted = sqrt(as.numeric(v)), stringsAsFactors = FALSE
        )
      }
    }
  }
  list(rank = rank, vif = do.call(rbind, vif_rows))
}

category_diagnostics <- function(cohort) {
  vars <- names(FACTOR_LEVELS)
  rows <- lapply(vars, function(variable) {
    lev <- FACTOR_LEVELS[[variable]]
    do.call(rbind, lapply(lev, function(level) {
      take <- !is.na(cohort[[variable]]) & as.character(cohort[[variable]]) == level
      data.frame(variavel = variable, categoria = level, n = sum(take),
                 eventos = sum(cohort$delta_cat[take] == 1L),
                 nao_eventos = sum(cohort$delta_cat[take] == 0L),
                 celula_problematic = sum(take) > 0L &&
                   (sum(cohort$delta_cat[take] == 1L) == 0L || sum(cohort$delta_cat[take] == 0L) == 0L),
                 stringsAsFactors = FALSE)
    }))
  })
  do.call(rbind, rows)
}

residual_diagnostics <- function(model, cohort, type) {
  if (type == "linear") {
    fitted <- as.numeric(stats::fitted(model)); residual <- as.numeric(stats::residuals(model))
    standardized <- as.numeric(stats::rstandard(model))
  } else {
    fitted <- as.numeric(stats::fitted(model)); residual <- as.numeric(stats::residuals(model, type = "pearson"))
    standardized <- as.numeric(stats::rstandard(model, type = "pearson"))
  }
  leverage <- as.numeric(stats::hatvalues(model)); cook <- as.numeric(stats::cooks.distance(model))
  n <- nrow(cohort); p <- length(stats::coef(model))
  flag <- cook > 4 / n | leverage > 2 * p / n | abs(standardized) > 2
  data.frame(
    id = cohort$id, observed = if (type == "linear") cohort$delta else cohort$delta_cat,
    predicted = fitted, residual = residual, standardized_residual = standardized,
    leverage = leverage, cooks_distance = cook,
    flag_cook = cook > 4 / n, flag_leverage = leverage > 2 * p / n,
    flag_standardized_residual = abs(standardized) > 2, influential_any = flag,
    stringsAsFactors = FALSE
  )
}

heteroscedasticity_diagnostic <- function(linear) {
  if (requireNamespace("lmtest", quietly = TRUE)) {
    test <- lmtest::bptest(linear)
    return(data.frame(test = "Breusch-Pagan", statistic = unname(test$statistic),
                      df = unname(test$parameter), p_value = unname(test$p.value),
                      stringsAsFactors = FALSE))
  }
  data.frame(test = "Breusch-Pagan", statistic = NA_real_, df = NA_real_,
             p_value = NA_real_, stringsAsFactors = FALSE)
}

roc_curve_data <- function(y, p) {
  thresholds <- c(Inf, sort(unique(p), decreasing = TRUE), -Inf)
  do.call(rbind, lapply(thresholds, function(threshold) {
    predicted <- p >= threshold
    tp <- sum(predicted & y == 1); fp <- sum(predicted & y == 0)
    tn <- sum(!predicted & y == 0); fn <- sum(!predicted & y == 1)
    data.frame(threshold = threshold, false_positive_rate = fp / (fp + tn),
               true_positive_rate = tp / (tp + fn), stringsAsFactors = FALSE)
  }))
}

write_pngs_frozen <- function(cohort, linear, logistic, calibration, outdir) {
  y <- cohort$delta; p <- as.numeric(stats::fitted(linear));
  grDevices::png(file.path(outdir, "frozen_linear_observed_vs_predicted.png"), 1500, 1000, res = 150)
  graphics::plot(p, y, pch = 19, col = "#2C5D7C", xlab = "Previsto (graus)", ylab = "Observado delta (graus)",
                main = "Modelo linear: observado versus previsto")
  graphics::abline(0, 1, lty = 2, lwd = 2); graphics::lines(stats::lowess(p, y), col = "#B33A3A", lwd = 2)
  grDevices::dev.off()

  residual <- residual_diagnostics(linear, cohort, "linear")
  grDevices::png(file.path(outdir, "frozen_linear_residuals.png"), 1500, 1000, res = 150)
  graphics::par(mfrow = c(2, 2)); graphics::plot(p, residual$residual, pch = 19, col = "#2C5D7C",
    xlab = "Previsto", ylab = "Resíduo", main = "Resíduos versus previsto"); graphics::abline(h = 0, lty = 2)
  graphics::hist(residual$residual, breaks = 20, col = "#BFD7EA", border = "white", main = "Distribuição dos resíduos", xlab = "Resíduo")
  stats::qqnorm(residual$residual, main = "QQ plot dos resíduos"); stats::qqline(residual$residual)
  graphics::plot(residual$leverage, residual$cooks_distance, pch = 19, col = "#2C5D7C",
    xlab = "Leverage", ylab = "Distância de Cook", main = "Influência")
  grDevices::dev.off()

  yb <- cohort$delta_cat; pb <- as.numeric(stats::fitted(logistic))
  grDevices::png(file.path(outdir, "frozen_logistic_probabilities.png"), 1500, 1000, res = 150)
  graphics::hist(pb[yb == 0], breaks = seq(0, 1, by = .05), col = "#BFD7EA", border = "white",
    xlim = c(0, 1), ylim = c(0, max(table(cut(pb, breaks = seq(0, 1, by = .05), include.lowest = TRUE)))),
    main = "Probabilidades previstas", xlab = "Probabilidade de melhora", ylab = "Frequência")
  graphics::hist(pb[yb == 1], breaks = seq(0, 1, by = .05), col = rgb(0.7, .2, .2, .45), border = NA, add = TRUE)
  graphics::legend("top", legend = c("Não evento", "Evento"), fill = c("#BFD7EA", "#B33A3A"), bty = "n")
  grDevices::dev.off()

  roc <- roc_curve_data(yb, pb)
  grDevices::png(file.path(outdir, "frozen_logistic_roc.png"), 1500, 1000, res = 150)
  graphics::plot(roc$false_positive_rate, roc$true_positive_rate, type = "l", lwd = 2, col = "#2C5D7C",
    xlab = "1 - especificidade", ylab = "Sensibilidade", main = "Curva ROC aparente", xlim = c(0, 1), ylim = c(0, 1))
  graphics::abline(0, 1, lty = 2); grDevices::dev.off()

  grDevices::png(file.path(outdir, "frozen_logistic_calibration.png"), 1500, 1000, res = 150)
  graphics::plot(calibration$groups$mean_predicted, calibration$groups$mean_observed, pch = 19,
    col = "#2C5D7C", xlim = c(0, 1), ylim = c(0, 1), xlab = "Probabilidade média prevista",
    ylab = "Proporção observada", main = "Calibração aparente por decis")
  graphics::abline(0, 1, lty = 2); graphics::lines(stats::lowess(calibration$groups$mean_predicted,
    calibration$groups$mean_observed), col = "#B33A3A", lwd = 2); grDevices::dev.off()
  invisible(TRUE)
}

compare_historical_frozen <- function(current_linear, current_logistic, current_metrics_linear,
                                      current_metrics_logistic, current_calibration) {
  old_linear <- utils::read.csv(file.path(PROJECT_ROOT, "diagnostico_modelos", "34_metricas_lineares_aparentes.csv"),
                                check.names = FALSE)
  old_logistic <- utils::read.csv(file.path(PROJECT_ROOT, "diagnostico_modelos", "37_metricas_logisticas_aparentes.csv"),
                                  check.names = FALSE)
  old_linear_cal <- utils::read.csv(file.path(PROJECT_ROOT, "diagnostico_modelos", "35_calibracao_linear_aparente.csv"),
                                    check.names = FALSE)
  old_logistic_cal <- utils::read.csv(file.path(PROJECT_ROOT, "diagnostico_modelos", "39_calibracao_logistica_resumo.csv"),
                                      check.names = FALSE)
  old_linear_coef <- utils::read.csv(file.path(PROJECT_ROOT, "diagnostico_modelos", "22_coeficientes_modelo_linear.csv"),
                                     check.names = FALSE)
  old_logistic_coef <- utils::read.csv(file.path(PROJECT_ROOT, "diagnostico_modelos", "23_coeficientes_logit.csv"),
                                       check.names = FALSE)
  max_coefficient_change <- function(current, old) {
    matched <- match(names(current), old$term)
    if (anyNA(matched)) return(NA_real_)
    max(abs(unname(current) - old$estimate[matched]))
  }
  coefficient_difference_linear <- max_coefficient_change(stats::coef(current_linear), old_linear_coef)
  coefficient_difference_logistic <- max_coefficient_change(stats::coef(current_logistic), old_logistic_coef)
  rows <- data.frame(
    resultado = c("n_linear", "r2_linear", "rmse_linear", "mae_linear", "calibration_intercept_linear",
                  "calibration_slope_linear", "max_abs_coefficient_difference_linear", "n_logistico",
                  "eventos_logistico", "auc_logistico", "brier_logistico", "log_loss_logistico",
                  "calibration_intercept_logistic", "calibration_slope_logistic",
                  "max_abs_coefficient_difference_logistic"),
    preliminar_20260721 = c(old_linear$n[1], old_linear$r2[1], old_linear$rmse[1], old_linear$mae[1],
                            old_linear_cal$estimate[old_linear_cal$term == "(Intercept)"],
                            old_linear_cal$estimate[old_linear_cal$term == "previsto"],
                            NA_real_,
                            old_logistic$n[1], old_logistic$eventos[1], old_logistic$auc[1],
                            old_logistic$brier[1], old_logistic$log_loss[1],
                            old_logistic_cal$calibration_intercept[1], old_logistic_cal$calibration_slope[1],
                            NA_real_),
    atual = c(current_metrics_linear$n[1], current_metrics_linear$r2[1], current_metrics_linear$rmse[1],
              current_metrics_linear$mae[1], current_calibration$calibration_intercept[current_calibration$model == "linear"],
              current_calibration$calibration_slope[current_calibration$model == "linear"],
              coefficient_difference_linear, current_metrics_logistic$n[1],
              current_metrics_logistic$events[1], current_metrics_logistic$auc[1], current_metrics_logistic$brier_score[1],
              current_metrics_logistic$log_loss[1],
              current_calibration$calibration_intercept[current_calibration$model == "logistic"],
              current_calibration$calibration_slope[current_calibration$model == "logistic"],
              coefficient_difference_logistic),
    stringsAsFactors = FALSE
  )
  rows$diferenca <- rows$atual - rows$preliminar_20260721
  rows$interpretacao <- ifelse(rows$resultado %in% c("n_linear", "n_logistico", "eventos_logistico"),
    "mudança esperada após deduplicação e casos completos", "recalcular; diferença decorre da nova coorte")
  rows$interpretacao[rows$resultado %in% c("max_abs_coefficient_difference_linear", "max_abs_coefficient_difference_logistic")] <- "diferença absoluta máxima dos coeficientes entre o ajuste atual e 21/07/2026"
  rows
}

run_frozen_models <- function(cohort) {
  fits <- fit_frozen_models(cohort)
  linear <- fits$linear; logistic <- fits$logistic; design <- fits$design
  p_linear <- as.numeric(stats::fitted(linear)); p_logistic <- as.numeric(stats::fitted(logistic))
  metrics_linear <- linear_metrics(cohort$delta, p_linear, length(stats::coef(linear)))
  metrics_logistic <- logistic_metrics(cohort$delta_cat, p_logistic)
  calibration <- calibration_apparent(cohort$delta, p_linear, cohort$delta_cat, p_logistic)
  diagnostics <- design_and_collinearity(design, linear, logistic, cohort)
  input_identity <- data.frame(
    n_linear = nrow(design), n_logistic = nrow(fits$design_logistic),
    same_rows_and_columns = identical(design, fits$design_logistic),
    stringsAsFactors = FALSE
  )
  categories <- category_diagnostics(cohort)
  residual_linear <- residual_diagnostics(linear, cohort, "linear")
  residual_logistic <- residual_diagnostics(logistic, cohort, "logistic")
  equivalence <- metric_equivalence(cohort$delta_cat, p_logistic, logistic)
  separation <- data.frame(
    diagnostic = c("glm_converged", "all_logistic_coefficients_finite", "warning_during_fit",
                   "problematic_factor_cells"),
    result = c(isTRUE(logistic$converged), all(is.finite(stats::coef(logistic))),
               length(attr(logistic, "fit_warnings")) > 0L, sum(categories$celula_problematic)),
    expected = c(TRUE, TRUE, FALSE, 0L), stringsAsFactors = FALSE
  )
  list(
    models = fits, input_identity = input_identity,
    coefficients_linear = wald_coefficient_table(linear, "linear"),
    coefficients_logit = wald_coefficient_table(logistic, "logit"),
    odds_ratios = odds_ratio_table(logistic), metrics_linear = metrics_linear,
    metrics_logistic = metrics_logistic, calibration = calibration,
    design = design, rank = diagnostics$rank, vif = diagnostics$vif,
    categories = categories, separation = separation, residual_linear = residual_linear,
    residual_logistic = residual_logistic, heteroscedasticity = heteroscedasticity_diagnostic(linear),
    equivalence = equivalence, roc = roc_curve_data(cohort$delta_cat, p_logistic),
    specification = data.frame(
      model = c("linear", "logistic"), formula = vapply(fits$formulas, function(x) paste(deparse(x), collapse = ""), character(1)),
      p_value_selection = FALSE, stepwise = FALSE, splines = FALSE, interactions = FALSE,
      parameters_predictors = ncol(design) - 1L, stringsAsFactors = FALSE
    ),
    comparison = compare_historical_frozen(linear, logistic, metrics_linear, metrics_logistic, calibration$summary)
  )
}

write_frozen_outputs <- function(results, cohort) {
  ensure_output_dirs()
  agg <- RESULTS_DIRS[["aggregated"]]; fig <- RESULTS_DIRS[["figures"]]; log <- RESULTS_DIRS[["logs"]]; obj <- RESULTS_DIRS[["reduced_objects"]]
  write <- function(x, filename, directory = agg) utils::write.csv(x, file.path(directory, filename), row.names = FALSE, na = "")
  write(results$coefficients_linear, "frozen_coefficients_linear.csv")
  write(results$coefficients_logit, "frozen_coefficients_logit.csv")
  write(results$odds_ratios, "frozen_odds_ratios.csv")
  write(results$metrics_linear, "frozen_metrics_linear_apparent.csv")
  write(results$metrics_logistic, "frozen_metrics_logistic_apparent.csv")
  write(results$calibration$summary, "frozen_calibration_apparent_summary.csv")
  write(results$calibration$linear_coefficients, "frozen_calibration_linear_coefficients.csv")
  write(results$calibration$groups, "frozen_calibration_logistic_groups.csv")
  write(results$design, "frozen_design_matrix.csv", log)
  write(results$input_identity, "frozen_model_input_identity.csv", log)
  write(data.frame(id = cohort$id, results$design, check.names = FALSE), "frozen_design_matrix_with_id.csv", log)
  write(results$rank, "frozen_matrix_rank.csv")
  write(results$vif, "frozen_collinearity.csv")
  write(results$categories, "frozen_category_diagnostics.csv")
  write(results$separation, "frozen_separation_diagnostics.csv")
  write(results$residual_linear, "frozen_residuals_influence_linear.csv", log)
  write(results$residual_logistic, "frozen_residuals_influence_logistic.csv", log)
  write(subset(results$residual_linear, influential_any), "frozen_influential_observations_linear.csv", log)
  write(subset(results$residual_logistic, influential_any), "frozen_influential_observations_logistic.csv", log)
  write(results$heteroscedasticity, "frozen_heteroscedasticity.csv")
  write(results$equivalence, "frozen_metric_equivalence.csv")
  write(results$roc, "frozen_roc_coordinates.csv")
  write(results$specification, "frozen_specification_audit.csv")
  write(results$comparison, "frozen_comparison_20260721.csv")
  write_pngs_frozen(cohort, results$models$linear, results$models$logistic, results$calibration, fig)

  equations <- c(
    "Equações aparentes dos modelos congelados",
    paste("Linear:", paste(deparse(results$models$formulas$linear), collapse = "")),
    "Previsão linear: aplicar os coeficientes da tabela frozen_coefficients_linear.csv às colunas da matriz de desenho.",
    paste("Logístico:", paste(deparse(results$models$formulas$logistic), collapse = "")),
    "Probabilidade: p = 1 / (1 + exp(-eta)); eta é a soma do intercepto e dos produtos coeficiente × preditor.",
    "Referências dos fatores: feminino, Lenke 1, Risser 0, flexível e escoliômetro normal.",
    paste("Parâmetros preditores:", ncol(results$design) - 1L),
    paste("Intercepto incluído:", ncol(results$design)),
    "Resultados de calibração aparente com intercepto 0 e slope 1 são esperados por construção e não constituem validação externa."
  )
  writeLines(equations, file.path(agg, "frozen_equations_apparent.txt"))
  warnings <- attr(results$models$logistic, "fit_warnings")
  writeLines(c("Diagnóstico de ajuste logístico", paste("converged:", results$models$logistic$converged),
               paste("coeficientes_finitos:", all(is.finite(stats::coef(results$models$logistic)))),
               paste("warnings:", if (length(warnings)) paste(warnings, collapse = " | ") else "nenhum"),
               paste("celulas_problematicas:", sum(results$categories$celula_problematic))),
             file.path(log, "frozen_logistic_fit_diagnostics.txt"))
  saveRDS(list(model_linear = results$models$linear, model_logistic = results$models$logistic,
               predictor_names = MODEL_PREDICTORS, factor_references = FACTOR_REFERENCES,
               formula_linear = results$models$formulas$linear, formula_logistic = results$models$formulas$logistic,
               source_sha256 = file_sha256(DATA_FILE), n = nrow(cohort)),
          file.path(obj, "frozen_models_reduced.rds"))
  saveRDS(list(metrics_linear = results$metrics_linear, metrics_logistic = results$metrics_logistic,
               calibration = results$calibration$summary, rank = results$rank, equivalence = results$equivalence),
          file.path(obj, "frozen_results_reduced.rds"))
  invisible(TRUE)
}
