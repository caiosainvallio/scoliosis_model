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

wald_coefficient_table <- function(model, scale = c("linear", "logit"), level = 0.95) {
  scale <- match.arg(scale)
  s <- summary(model)$coefficients
  alpha <- 1 - level
  if (inherits(model, "lm")) {
    # Para lm, summary() usa testes t. O IC deve usar a mesma distribuição e os
    # mesmos graus de liberdade, em vez do IC normal de confint.default().
    degrees_freedom <- stats::df.residual(model)
    critical <- stats::qt(1 - alpha / 2, df = degrees_freedom)
    reference_distribution <- "t"
  } else {
    degrees_freedom <- Inf
    critical <- stats::qnorm(1 - alpha / 2)
    reference_distribution <- "normal_assintotica"
  }
  conf_low <- unname(s[, 1] - critical * s[, 2])
  conf_high <- unname(s[, 1] + critical * s[, 2])
  result <- data.frame(
    term = rownames(s), estimate = unname(s[, 1]), std_error = unname(s[, 2]),
    statistic = unname(s[, 3]), p_value = unname(s[, 4]),
    conf_low = conf_low, conf_high = conf_high,
    escala = scale, covariance = "classica_modelo",
    reference_distribution = reference_distribution,
    degrees_freedom = degrees_freedom, confidence_level = level,
    stringsAsFactors = FALSE, row.names = NULL
  )
  result
}

linear_hc3_coefficient_table <- function(model, level = 0.95) {
  if (!inherits(model, "lm")) stop("HC3 desta rotina requer um modelo lm.")
  if (!requireNamespace("sandwich", quietly = TRUE)) {
    stop("O pacote sandwich é necessário para a sensibilidade HC3.")
  }
  covariance <- sandwich::vcovHC(model, type = "HC3")
  estimates <- stats::coef(model)
  standard_errors <- sqrt(diag(covariance))
  degrees_freedom <- stats::df.residual(model)
  statistic <- estimates / standard_errors
  p_value <- 2 * stats::pt(abs(statistic), df = degrees_freedom, lower.tail = FALSE)
  critical <- stats::qt(1 - (1 - level) / 2, df = degrees_freedom)
  data.frame(
    term = names(estimates), estimate = unname(estimates),
    std_error = unname(standard_errors), statistic = unname(statistic),
    p_value = unname(p_value),
    conf_low = unname(estimates - critical * standard_errors),
    conf_high = unname(estimates + critical * standard_errors),
    escala = "linear", covariance = "HC3",
    reference_distribution = "t", degrees_freedom = degrees_freedom,
    confidence_level = level, stringsAsFactors = FALSE, row.names = NULL
  )
}

compare_linear_inference <- function(classic, hc3) {
  stopifnot(identical(classic$term, hc3$term),
            max(abs(classic$estimate - hc3$estimate)) < 1e-12)
  data.frame(
    term = classic$term, estimate = classic$estimate,
    std_error_classic = classic$std_error, std_error_hc3 = hc3$std_error,
    se_ratio_hc3_to_classic = hc3$std_error / classic$std_error,
    p_value_classic = classic$p_value, p_value_hc3 = hc3$p_value,
    conf_low_classic = classic$conf_low, conf_high_classic = classic$conf_high,
    conf_low_hc3 = hc3$conf_low, conf_high_hc3 = hc3$conf_high,
    crosses_zero_classic = classic$conf_low <= 0 & classic$conf_high >= 0,
    crosses_zero_hc3 = hc3$conf_low <= 0 & hc3$conf_high >= 0,
    stringsAsFactors = FALSE
  )
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
                      n = stats::nobs(linear),
                      auxiliary_r_squared = unname(test$statistic) / stats::nobs(linear),
                      studentized = TRUE,
                      stringsAsFactors = FALSE))
  }
  data.frame(test = "Breusch-Pagan", statistic = NA_real_, df = NA_real_,
             p_value = NA_real_, n = stats::nobs(linear),
             auxiliary_r_squared = NA_real_, studentized = TRUE,
             stringsAsFactors = FALSE)
}

diagnostic_variance_pattern <- function(linear, groups = 5L) {
  fitted <- as.numeric(stats::fitted(linear))
  residual <- as.numeric(stats::residuals(linear))
  breaks <- unique(stats::quantile(fitted, probs = seq(0, 1, length.out = groups + 1L),
                                   names = FALSE))
  band <- cut(fitted, breaks = breaks, include.lowest = TRUE, labels = FALSE)
  do.call(rbind, lapply(sort(unique(band)), function(g) {
    take <- band == g
    data.frame(
      fitted_band = as.integer(g), n = sum(take),
      fitted_min = min(fitted[take]), fitted_max = max(fitted[take]),
      fitted_mean = mean(fitted[take]), residual_mean = mean(residual[take]),
      residual_sd = stats::sd(residual[take]),
      residual_mean_absolute = mean(abs(residual[take])),
      residual_rmse = sqrt(mean(residual[take]^2)), stringsAsFactors = FALSE
    )
  }))
}

diagnostic_residual_tail_summary <- function(linear) {
  raw <- as.numeric(stats::residuals(linear))
  standardized <- as.numeric(stats::rstandard(linear))
  q <- stats::quantile(raw, c(0, .01, .05, .25, .5, .75, .95, .99, 1), names = FALSE)
  data.frame(
    n = length(raw), residual_min = q[[1]], residual_p01 = q[[2]],
    residual_p05 = q[[3]], residual_p25 = q[[4]], residual_median = q[[5]],
    residual_p75 = q[[6]], residual_p95 = q[[7]], residual_p99 = q[[8]],
    residual_max = q[[9]], standardized_abs_gt_2 = sum(abs(standardized) > 2),
    standardized_abs_gt_3 = sum(abs(standardized) > 3),
    skewness_moment = mean((raw - mean(raw))^3) / stats::sd(raw)^3,
    excess_kurtosis_moment = mean((raw - mean(raw))^4) / stats::var(raw)^2 - 3,
    stringsAsFactors = FALSE
  )
}

diagnostic_qq_data <- function(linear) {
  standardized <- sort(as.numeric(stats::rstandard(linear)))
  n <- length(standardized)
  data.frame(
    order = seq_len(n),
    theoretical_quantile = stats::qnorm(stats::ppoints(n)),
    standardized_residual_quantile = standardized,
    stringsAsFactors = FALSE
  )
}

diagnostic_smooth_data <- function(linear) {
  fitted <- as.numeric(stats::fitted(linear))
  residual <- as.numeric(stats::residuals(linear))
  standardized <- as.numeric(stats::rstandard(linear))
  make_lowess <- function(x, y, panel) {
    sm <- stats::lowess(x, y, f = 2 / 3, iter = 3)
    data.frame(panel = panel, x = sm$x, smooth = sm$y, stringsAsFactors = FALSE)
  }
  rbind(
    make_lowess(fitted, residual, "residuo_vs_ajustado"),
    make_lowess(fitted, sqrt(abs(standardized)), "escala_localizacao")
  )
}

diagnostic_component_smooths <- function(model, cohort, model_name) {
  numeric_terms <- intersect(c("idade", "imc", "cifose_toracica", "lordose_lombar",
                               "correcao_colete"), names(stats::coef(model)))
  if (model_name == "linear") {
    base_residual <- as.numeric(stats::residuals(model))
  } else {
    probability <- pmin(pmax(as.numeric(stats::fitted(model)), 1e-8), 1 - 1e-8)
    base_residual <- (as.numeric(cohort$delta_cat) - probability) /
      (probability * (1 - probability))
  }
  do.call(rbind, lapply(numeric_terms, function(term) {
    x <- as.numeric(cohort[[term]])
    component_residual <- unname(stats::coef(model)[[term]]) * x + base_residual
    sm <- stats::lowess(x, component_residual, f = 2 / 3, iter = 3)
    data.frame(model = model_name, term = term, x = sm$x,
               component_residual_smooth = sm$y, stringsAsFactors = FALSE)
  }))
}

diagnostic_condition_indices <- function(design) {
  predictors <- design[, colnames(design) != "(Intercept)", drop = FALSE]
  scaled <- scale(predictors, center = TRUE, scale = TRUE)
  singular_values <- svd(scaled, nu = 0, nv = 0)$d
  data.frame(
    dimension = seq_along(singular_values), singular_value = singular_values,
    condition_index = max(singular_values) / singular_values,
    design = "preditores_centrados_e_padronizados_sem_intercepto",
    stringsAsFactors = FALSE
  )
}

diagnostic_separation_qp <- function(design, outcome, tolerance = 1e-7) {
  if (!requireNamespace("quadprog", quietly = TRUE)) {
    return(data.frame(method = "programacao_quadratica_Albert-Anderson",
      complete_separation = NA, quasi_complete_separation = NA,
      status = "nao_avaliado: pacote quadprog ausente", tolerance = tolerance,
      stringsAsFactors = FALSE))
  }
  signed_design <- design * (2 * as.numeric(outcome) - 1)
  feasible <- function(constraint_matrix, bounds) {
    p <- ncol(signed_design)
    value <- tryCatch(
      quadprog::solve.QP(diag(p), rep(0, p), t(constraint_matrix), bounds),
      error = function(e) NULL
    )
    !is.null(value) && all(as.numeric(constraint_matrix %*% value$solution) >= bounds - tolerance)
  }
  complete <- feasible(signed_design, rep(1, nrow(signed_design)))
  quasi_constraints <- rbind(signed_design, colSums(signed_design))
  quasi <- feasible(quasi_constraints, c(rep(0, nrow(signed_design)), 1))
  data.frame(
    method = "programacao_quadratica_Albert-Anderson",
    complete_separation = complete,
    quasi_complete_separation = !complete && quasi,
    status = if (complete) "separacao_completa_detectada" else if (quasi) {
      "separacao_quase-completa_detectada"
    } else "nenhuma_separacao_completa_ou_quase-completa_detectada",
    tolerance = tolerance, stringsAsFactors = FALSE
  )
}

diagnostic_influence_summary <- function(residual_table, model_name, n_parameters) {
  n <- nrow(residual_table)
  data.frame(
    model = model_name, n = n, parameters_including_intercept = n_parameters,
    cook_threshold = 4 / n, leverage_threshold = 2 * n_parameters / n,
    standardized_residual_threshold = 2,
    n_flag_cook = sum(residual_table$flag_cook),
    n_flag_leverage = sum(residual_table$flag_leverage),
    n_flag_standardized_residual = sum(residual_table$flag_standardized_residual),
    n_flag_any = sum(residual_table$influential_any),
    max_cooks_distance = max(residual_table$cooks_distance),
    max_leverage = max(residual_table$leverage),
    max_abs_standardized_residual = max(abs(residual_table$standardized_residual)),
    action = "investigar_em_sensibilidade_task_10_sem_excluir_da_principal",
    stringsAsFactors = FALSE
  )
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

# Complemento da revisão: mantém a especificação e os coeficientes pontuais dos
# modelos principais, mas torna coerente a inferência clássica e acrescenta HC3.
run_review_inference <- function(cohort) {
  results <- run_frozen_models(cohort)
  linear <- results$models$linear
  logistic <- results$models$logistic
  classic <- wald_coefficient_table(linear, "linear")
  hc3 <- linear_hc3_coefficient_table(linear)
  comparison <- compare_linear_inference(classic, hc3)
  variance_pattern <- diagnostic_variance_pattern(linear)
  tails <- diagnostic_residual_tail_summary(linear)
  smooth <- diagnostic_smooth_data(linear)
  component_smooths <- rbind(
    diagnostic_component_smooths(linear, cohort, "linear"),
    diagnostic_component_smooths(logistic, cohort, "logistic")
  )
  condition_indices <- diagnostic_condition_indices(results$design)
  separation_formal <- diagnostic_separation_qp(results$design, cohort$delta_cat)
  categories <- results$categories
  warnings <- attr(logistic, "fit_warnings")
  separation <- data.frame(
    method = separation_formal$method,
    complete_separation = separation_formal$complete_separation,
    quasi_complete_separation = separation_formal$quasi_complete_separation,
    formal_status = separation_formal$status,
    tolerance = separation_formal$tolerance,
    glm_converged = isTRUE(logistic$converged),
    coefficients_finite = all(is.finite(stats::coef(logistic))),
    fit_warning_count = length(warnings),
    factor_cells_with_single_outcome = sum(categories$celula_problematic),
    minimum_category_n = min(categories$n),
    minimum_category_events = min(categories$eventos),
    minimum_category_nonevents = min(categories$nao_eventos),
    interpretation = paste(
      "A programação quadrática avalia separação completa/quase-completa no desenho multivariável;",
      "convergência, estimabilidade e células marginais são evidências complementares, não substitutos."
    ), stringsAsFactors = FALSE
  )
  influence <- rbind(
    diagnostic_influence_summary(results$residual_linear, "linear", length(stats::coef(linear))),
    diagnostic_influence_summary(results$residual_logistic, "logistic", length(stats::coef(logistic)))
  )
  max_gvif <- max(results$vif$gvif_adjusted)
  max_condition <- max(condition_indices$condition_index)
  bp <- results$heteroscedasticity
  sd_ratio <- max(variance_pattern$residual_sd) / min(variance_pattern$residual_sd)
  assumptions <- data.frame(
    assumption = c(
      "independencia", "media_condicional_linear", "linearidade_no_logit",
      "variancia_constante", "caudas_dos_residuos", "colinearidade",
      "influencia", "separacao_logistica"
    ),
    evidence = c(
      paste0(nrow(cohort), " IDs unicos; duplicatas conhecidas removidas antes do ajuste"),
      "suavizacao robusta de residuos versus ajustado e residuos componentes dos cinco termos numericos",
      "suavizacao de residuos componentes na escala do preditor linear para os cinco termos numericos",
      paste0("Breusch-Pagan = ", signif(bp$statistic, 5), ", gl = ", bp$df,
             ", p = ", signif(bp$p_value, 5), ", R2 auxiliar = ",
             signif(bp$auxiliary_r_squared, 4), "; razao entre DP por quintil = ", signif(sd_ratio, 4)),
      paste0(sum(abs(results$residual_linear$standardized_residual) > 2),
             " residuos padronizados com |r| > 2 e ",
             sum(abs(results$residual_linear$standardized_residual) > 3), " com |r| > 3; dados Q-Q preparados"),
      paste0("posto ", qr(results$design)$rank, "/", ncol(results$design),
             "; maior GVIF^(1/(2*gl)) = ", signif(max_gvif, 4),
             "; maior indice de condicao padronizado = ", signif(max_condition, 4)),
      paste0(influence$n_flag_any[influence$model == "linear"], " sinais no linear e ",
             influence$n_flag_any[influence$model == "logistic"], " no logistico pelos criterios de triagem"),
      paste0(separation$formal_status, "; glm convergiu = ", separation$glm_converged,
             "; coeficientes finitos = ", separation$coefficients_finite,
             "; menor categoria n = ", separation$minimum_category_n)
    ),
    interpretation = c(
      "Uma linha por participante sustenta a unidade analitica; centro, avaliador e outras estruturas de agrupamento nao existem na fonte e nao puderam ser testados.",
      "Diagnostico grafico de forma, sem teste binario de aprovacao; desvios devem orientar as sensibilidades flexiveis, nao alterar silenciosamente o principal.",
      "Diagnostico grafico do componente sistematico no logit; a forma nao e aprovada apenas por convergencia.",
      "Ha evidencia contra homoscedasticidade, de magnitude auxiliar modesta; a variacao por faixa mostra o padrao observado.",
      "Caudas e Q-Q informam a adequacao aproximada dos intervalos classicos; normalidade nao e exigida para covariaveis nem decidida por teste omnibus.",
      "Posto, GVIF com gl e indices de condicao descrevem estimabilidade e redundancia; nenhum limiar isolado prova validade.",
      "Flags sao sinais de investigacao, podem se sobrepor e nao constituem regra automatica de exclusao.",
      "A avaliacao formal cobre separacao completa e quase-completa multivariavel; nao garante boa forma funcional, calibracao ou estabilidade."
    ),
    action = c(
      "explicitar ausencia de variaveis de agrupamento; nao usar teste de autocorrelacao em ordem arbitraria",
      "usar graficos na task 12 e confrontar com analise flexivel sem substituir o modelo congelado",
      "usar graficos na task 12 e resultados de calibracao; manter logit principal congelado",
      "relatar inferencia classica t e sensibilidade HC3 t; nao atribuir a HC3 correcao de nao linearidade ou previsao individual",
      "usar Q-Q e resumo de caudas; interpretar em conjunto com influencia e HC3",
      "relatar todos os componentes, sem corte arbitrario de aprovacao",
      "vincular IDs internos e criterios as sensibilidades da task 10; manter todos os casos na principal",
      "relatar metodo formal junto de convergencia, estimabilidade e categorias raras"
    ),
    limitation = c(
      "independencia entre centros/avaliadores/medidas nao e identificavel com as colunas disponiveis",
      "suavizacao e exploratoria e nao estima impacto externo na predicao",
      "dados binarios limitam a leitura local, especialmente em extremos de probabilidade",
      "HC3 corrige a matriz de covariancia dos coeficientes, nao a media, a calibracao nem intervalos individuais",
      "a avaliacao visual nao demonstra normalidade exata nem cobertura em nova populacao",
      "indices dependem da codificacao e escala; valores baixos nao validam a especificacao",
      "a sensibilidade sem casos sera executada pela task 10 e nao redefine a coorte",
      "o resultado e numerico para este desenho; categorias pequenas ainda podem gerar imprecisao"
    ), stringsAsFactors = FALSE
  )
  list(
    frozen = results, coefficients_linear_classic = classic,
    coefficients_linear_hc3 = hc3, inference_comparison = comparison,
    heteroscedasticity = bp, variance_pattern = variance_pattern,
    residual_tails = tails, residual_smooth = smooth,
    component_smooths = component_smooths, qq = diagnostic_qq_data(linear),
    collinearity = results$vif, rank = results$rank,
    condition_indices = condition_indices, categories = categories,
    separation = separation, influence = influence, assumptions = assumptions,
    cohort_identity = data.frame(
      n = nrow(cohort), events = sum(cohort$delta_cat == 1L),
      nonevents = sum(cohort$delta_cat == 0L), unique_ids = length(unique(cohort$id)),
      design_columns = ncol(results$design), design_rank = qr(results$design)$rank,
      source_sha256 = file_sha256(DATA_FILE), stringsAsFactors = FALSE
    )
  )
}

write_review_inference_outputs <- function(review, cohort, output_root) {
  dirs <- c(
    aggregated = file.path(output_root, "aggregated"),
    logs = file.path(output_root, "logs"),
    reduced_objects = file.path(output_root, "reduced_objects")
  )
  invisible(lapply(dirs, dir.create, recursive = TRUE, showWarnings = FALSE))
  write <- function(x, filename, directory = dirs[["aggregated"]]) {
    utils::write.csv(x, file.path(directory, filename), row.names = FALSE, na = "")
  }
  write(review$coefficients_linear_classic, "coefficients_linear_classic_corrected.csv")
  write(review$coefficients_linear_hc3, "coefficients_linear_hc3.csv")
  write(review$inference_comparison, "diagnostics_inference_comparison.csv")
  write(review$heteroscedasticity, "diagnostics_heteroscedasticity.csv")
  write(review$variance_pattern, "diagnostics_variance_pattern.csv")
  write(review$residual_tails, "diagnostics_residual_tails.csv")
  write(review$residual_smooth, "diagnostics_residual_smooth.csv")
  write(review$component_smooths, "diagnostics_component_smooths.csv")
  write(review$qq, "diagnostics_qq_linear.csv")
  write(review$collinearity, "diagnostics_collinearity.csv")
  write(review$rank, "diagnostics_rank.csv")
  write(review$condition_indices, "diagnostics_condition_indices.csv")
  write(review$categories, "diagnostics_logistic_categories.csv")
  write(review$separation, "diagnostics_logistic_separation.csv")
  write(review$influence, "diagnostics_influence_summary.csv")
  write(review$assumptions, "diagnostics_assumption_evidence.csv")
  write(review$cohort_identity, "diagnostics_cohort_model_identity.csv")
  influence_internal <- rbind(
    cbind(model = "linear", review$frozen$residual_linear),
    cbind(model = "logistic", review$frozen$residual_logistic)
  )
  write(influence_internal, "diagnostics_influence_task10_internal.csv", dirs[["logs"]])
  saveRDS(list(
    residual_smooth = review$residual_smooth,
    component_smooths = review$component_smooths,
    qq = review$qq,
    variance_pattern = review$variance_pattern,
    influence = influence_internal[, setdiff(names(influence_internal), "id"), drop = FALSE]
  ), file.path(dirs[["reduced_objects"]], "diagnostics_plot_data.rds"))
  invisible(dirs)
}
