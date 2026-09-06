# Métricas e calibração para a avaliação interna.
#
# Todas as funções deste arquivo recebem os dados necessários como argumentos.
# Não há leitura de .GlobalEnv, restauração de .RData ou dependência de objetos
# criados por scripts de análise.

.metric_inputs <- function(observed, predicted, binary = FALSE) {
  if (length(observed) != length(predicted)) {
    stop("observed e predicted devem ter o mesmo tamanho.", call. = FALSE)
  }
  keep <- stats::complete.cases(observed, predicted)
  observed_complete <- observed[keep]
  y <- if (binary && is.factor(observed_complete)) {
    if (nlevels(observed_complete) != 2L) {
      stop("Para métricas binárias, observed fator deve ter dois níveis.", call. = FALSE)
    }
    as.integer(observed_complete) - 1L
  } else as.numeric(observed_complete)
  p <- as.numeric(predicted[keep])
  if (!length(y)) stop("Não há observações completas.", call. = FALSE)
  if (any(!is.finite(y)) || any(!is.finite(p))) {
    stop("observed e predicted devem conter apenas valores finitos.", call. = FALSE)
  }
  if (binary && any(!y %in% c(0, 1))) {
    stop("Para métricas binárias, observed deve conter somente 0 e 1.", call. = FALSE)
  }
  list(y = y, p = p, keep = keep)
}

# Limita probabilidades antes de usar log() ou log1p().
clip_probabilities <- function(probabilities, epsilon = 1e-15) {
  if (length(epsilon) != 1L || !is.finite(epsilon) || epsilon <= 0 || epsilon >= 0.5) {
    stop("epsilon deve estar no intervalo (0, 0.5).", call. = FALSE)
  }
  p <- as.numeric(probabilities)
  if (any(!is.finite(p))) stop("probabilidades devem ser finitas.", call. = FALSE)
  if (any(p < 0 | p > 1)) stop("probabilidades devem estar entre 0 e 1.", call. = FALSE)
  pmin(pmax(p, epsilon), 1 - epsilon)
}

safe_probability <- clip_probabilities

r_squared <- function(observed, predicted) {
  z <- .metric_inputs(observed, predicted)
  sst <- sum((z$y - mean(z$y))^2)
  if (sst == 0) return(NA_real_)
  1 - sum((z$y - z$p)^2) / sst
}

r2 <- r_squared
r2_score <- r_squared

rmse <- function(observed, predicted) {
  z <- .metric_inputs(observed, predicted)
  sqrt(mean((z$y - z$p)^2))
}
rmse_score <- rmse

mae <- function(observed, predicted) {
  z <- .metric_inputs(observed, predicted)
  mean(abs(z$y - z$p))
}
mae_score <- mae

mean_error <- function(observed, predicted) {
  z <- .metric_inputs(observed, predicted)
  mean(z$y - z$p)
}
mean_error_score <- mean_error

brier_score <- function(observed, predicted) {
  z <- .metric_inputs(observed, predicted, binary = TRUE)
  if (any(z$p < 0 | z$p > 1)) {
    stop("Para o Brier score, predicted deve estar entre 0 e 1.", call. = FALSE)
  }
  mean((z$y - z$p)^2)
}

brier <- brier_score

auc_rank <- function(observed, predicted) {
  z <- .metric_inputs(observed, predicted, binary = TRUE)
  n_event <- sum(z$y == 1)
  n_nonevent <- sum(z$y == 0)
  if (n_event == 0L || n_nonevent == 0L) {
    stop("AUC exige pelo menos um evento e um não evento.", call. = FALSE)
  }
  ranks <- rank(z$p, ties.method = "average")
  (sum(ranks[z$y == 1]) - n_event * (n_event + 1) / 2) /
    (n_event * n_nonevent)
}

auc <- auc_rank
roc_auc <- auc_rank

auc_wald_ci <- function(auc, n_event, n_nonevent, level = 0.95) {
  if (length(auc) != 1L || !is.finite(auc) || auc < 0 || auc > 1) {
    stop("auc deve estar entre 0 e 1.", call. = FALSE)
  }
  if (n_event < 1L || n_nonevent < 1L) {
    stop("n_event e n_nonevent devem ser positivos.", call. = FALSE)
  }
  q1 <- auc / (2 - auc)
  q2 <- 2 * auc^2 / (1 + auc)
  se <- sqrt((auc * (1 - auc) + (n_event - 1) * (q1 - auc^2) +
                (n_nonevent - 1) * (q2 - auc^2)) / (n_event * n_nonevent))
  z <- stats::qnorm(1 - (1 - level) / 2)
  c(lower = max(0, auc - z * se), upper = min(1, auc + z * se))
}

auc_reference <- function(observed, predicted) {
  z <- .metric_inputs(observed, predicted, binary = TRUE)
  event <- z$p[z$y == 1]
  nonevent <- z$p[z$y == 0]
  if (!length(event) || !length(nonevent)) {
    stop("AUC exige pelo menos um evento e um não evento.", call. = FALSE)
  }
  # P(predicted_event > predicted_nonevent) + 0.5 P(tie).
  mean(outer(event, nonevent, FUN = function(a, b) {
    (a > b) + 0.5 * (a == b)
  }))
}

log_loss <- function(observed, predicted, epsilon = 1e-15) {
  z <- .metric_inputs(observed, predicted, binary = TRUE)
  p <- clip_probabilities(z$p, epsilon = epsilon)
  -mean(z$y * log(p) + (1 - z$y) * log1p(-p))
}

safe_log_loss <- log_loss

linear_metrics <- function(observed, predicted, n_parameters = NULL) {
  z <- .metric_inputs(observed, predicted)
  n <- length(z$y)
  r2_value <- r_squared(z$y, z$p)
  adjusted <- NA_real_
  if (!is.null(n_parameters) && length(n_parameters) == 1L &&
      is.finite(n_parameters) && n > n_parameters + 1L && is.finite(r2_value)) {
    adjusted <- 1 - (1 - r2_value) * (n - 1) / (n - n_parameters - 1)
  }
  data.frame(
    n = n, r2 = r2_value, r2_adjusted = adjusted,
    rmse = rmse(z$y, z$p), mae = mae(z$y, z$p),
    mean_error = mean_error(z$y, z$p), stringsAsFactors = FALSE
  )
}

logistic_metrics <- function(observed, predicted, epsilon = 1e-15) {
  z <- .metric_inputs(observed, predicted, binary = TRUE)
  auc_value <- auc_rank(z$y, z$p)
  ci <- auc_wald_ci(auc_value, sum(z$y == 1), sum(z$y == 0))
  p <- clip_probabilities(z$p, epsilon = epsilon)
  data.frame(
    n = length(z$y), events = sum(z$y == 1), nonevents = sum(z$y == 0),
    prevalence = mean(z$y), auc = auc_value,
    auc_ci_lower = ci[["lower"]], auc_ci_upper = ci[["upper"]],
    brier_score = mean((z$y - p)^2),
    log_loss = -mean(z$y * log(p) + (1 - z$y) * log1p(-p)),
    probability_min = min(p), probability_median = median(p),
    probability_max = max(p), stringsAsFactors = FALSE
  )
}

calibration_linear <- function(observed, predicted) {
  z <- .metric_inputs(observed, predicted)
  if (length(unique(z$p)) < 2L) {
    stop("Falha na calibração linear: predições sem variação.", call. = FALSE)
  }
  fit <- stats::lm(z$y ~ z$p)
  coefficients <- stats::coef(fit)
  if (length(coefficients) < 2L || any(!is.finite(coefficients))) {
    stop("Falha na calibração linear: coeficientes não finitos.", call. = FALSE)
  }
  list(intercept = unname(coefficients[[1]]), slope = unname(coefficients[[2]]),
       n = length(z$y), fit = fit)
}

calibration_linear_intercept <- function(observed, predicted) {
  calibration_linear(observed, predicted)$intercept
}

calibration_linear_slope <- function(observed, predicted) {
  calibration_linear(observed, predicted)$slope
}

calibration_intercept <- calibration_linear_intercept
calibration_slope <- calibration_linear_slope

calibration_logistic <- function(observed, predicted, epsilon = 1e-15) {
  z <- .metric_inputs(observed, predicted, binary = TRUE)
  if (length(unique(z$y)) < 2L) {
    stop("Falha na calibração logística: desfecho sem variação.", call. = FALSE)
  }
  lp <- stats::qlogis(clip_probabilities(z$p, epsilon = epsilon))
  intercept_fit <- stats::glm(z$y ~ 1 + offset(lp), family = stats::binomial())
  slope_fit <- stats::glm(z$y ~ lp, family = stats::binomial())
  intercept <- unname(stats::coef(intercept_fit)[[1]])
  slope <- unname(stats::coef(slope_fit)[[2]])
  if (!is.finite(intercept) || !is.finite(slope) || !isTRUE(slope_fit$converged)) {
    stop("Falha na calibração logística: ajuste não finito ou não convergente.", call. = FALSE)
  }
  list(intercept = intercept, slope = slope, n = length(z$y),
       fit_intercept = intercept_fit, fit_slope = slope_fit)
}

calibration_in_the_large <- function(observed, predicted, epsilon = 1e-15) {
  calibration_logistic(observed, predicted, epsilon = epsilon)$intercept
}

calibration_slope_logistic <- function(observed, predicted, epsilon = 1e-15) {
  calibration_logistic(observed, predicted, epsilon = epsilon)$slope
}

citl <- calibration_in_the_large

calibration_summary_metrics <- function(observed, predicted, type = c("linear", "logistic"),
                                         epsilon = 1e-15) {
  type <- match.arg(type)
  result <- if (type == "linear") calibration_linear(observed, predicted) else
    calibration_logistic(observed, predicted, epsilon = epsilon)
  data.frame(
    calibration_intercept = result$intercept,
    calibration_slope = result$slope,
    n = result$n, stringsAsFactors = FALSE
  )
}

# Resumo descritivo por grupos de risco; não substitui as métricas de calibração.
calibration_summary <- function(observed, predicted, groups = 10L) {
  z <- .metric_inputs(observed, predicted)
  if (length(groups) != 1L || groups < 1L) stop("groups deve ser positivo.", call. = FALSE)
  breaks <- unique(stats::quantile(z$p, probs = seq(0, 1, length.out = groups + 1), names = FALSE))
  if (length(breaks) < 2L) {
    return(data.frame(group = 1L, n = length(z$y), mean_predicted = mean(z$p),
                      mean_observed = mean(z$y), stringsAsFactors = FALSE))
  }
  bin <- cut(z$p, breaks = breaks, include.lowest = TRUE, labels = FALSE)
  out <- lapply(sort(unique(bin)), function(g) {
    take <- bin == g
    data.frame(group = as.integer(g), n = sum(take),
               mean_predicted = mean(z$p[take]), mean_observed = mean(z$y[take]),
               stringsAsFactors = FALSE)
  })
  do.call(rbind, out)
}
