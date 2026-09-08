# Bootstrap e estabilidade para avaliação interna.
#
# A unidade de reprodutibilidade é a réplica: cada réplica recebe uma semente
# própria e explícita. Isso permite executar as mesmas réplicas em paralelo sem
# depender da ordem em que os workers terminam.

.with_local_seed <- function(seed, code) {
  if (length(seed) != 1L || !is.numeric(seed) || !is.finite(seed)) {
    stop("seed deve ser um número finito.", call. = FALSE)
  }
  had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  old_seed <- if (had_seed) get(".Random.seed", envir = .GlobalEnv) else NULL
  on.exit({
    if (had_seed) assign(".Random.seed", old_seed, envir = .GlobalEnv)
    else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
      rm(".Random.seed", envir = .GlobalEnv)
    }
  }, add = TRUE)
  set.seed(as.integer(seed))
  force(code)
}

.normalize_family <- function(family) {
  if (is.character(family)) {
    if (length(family) != 1L || !family %in% c("gaussian", "binomial")) {
      stop("family deve ser 'gaussian', 'binomial' ou um objeto family().", call. = FALSE)
    }
    return(get(family, envir = asNamespace("stats"))())
  }
  if (is.function(family)) return(family())
  if (is.list(family) && all(c("family", "linkfun", "linkinv", "variance") %in% names(family))) {
    return(family)
  }
  stop("family deve ser 'gaussian', 'binomial' ou um objeto family().", call. = FALSE)
}

.family_type <- function(family) {
  fam <- .normalize_family(family)
  if (identical(fam$family, "gaussian")) return("linear")
  if (identical(fam$family, "binomial")) return("logistic")
  stop("A Tarefa 05 suporta somente as famílias gaussian e binomial.", call. = FALSE)
}

.failure_result <- function(seed, index, n_original, reason, detail, warnings = character(),
                            n_bootstrap = length(index), sample_size = n_bootstrap) {
  list(
    replicate = NA_integer_, seed = as.integer(seed), status = "failed",
    failure_reason = reason, failure_detail = detail, warnings = unique(warnings),
    failure = list(reason = reason, detail = detail),
    n_original = n_original, n_bootstrap = sample_size,
    n_unique_bootstrap = if (length(index)) length(unique(index)) else NA_integer_,
    index = as.integer(index), coefficients = NULL, predictions = NULL,
    metrics = NULL, optimism = NULL
  )
}

.capture_warnings <- function(expr) {
  warnings <- character()
  error <- NULL
  value <- tryCatch(
    withCallingHandlers(expr, warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }),
    error = function(e) {
      error <<- e
      NULL
    }
  )
  list(value = value, warnings = unique(warnings), error = error)
}

.missing_factor_level <- function(original_data, bootstrap_data, formula) {
  variables <- unique(setdiff(all.vars(formula), all.vars(formula[[2]])))
  for (variable in variables) {
    if (!variable %in% names(original_data) || !variable %in% names(bootstrap_data)) next
    original <- original_data[[variable]]
    sampled <- bootstrap_data[[variable]]
    if (is.factor(original) || is.character(original)) {
      original_levels <- unique(as.character(original[!is.na(original)]))
      sampled_levels <- unique(as.character(sampled[!is.na(sampled)]))
      if (length(setdiff(original_levels, sampled_levels))) return(TRUE)
    }
  }
  FALSE
}

.response_name <- function(formula) {
  response <- all.vars(formula[[2]])
  if (!length(response)) stop("Não foi possível identificar o desfecho da fórmula.", call. = FALSE)
  response[[1]]
}

.metric_values <- function(data, formula, predicted, family_type) {
  y <- data[[.response_name(formula)]]
  if (family_type == "linear") {
    cal <- calibration_linear(y, predicted)
    return(c(
      r2 = r_squared(y, predicted),
      rmse = rmse(y, predicted),
      mae = mae(y, predicted),
      mean_error = mean_error(y, predicted),
      calibration_intercept = cal$intercept,
      calibration_slope = cal$slope
    ))
  }
  cal <- calibration_logistic(y, predicted)
  c(
    auc = auc_rank(y, predicted),
    brier_score = brier_score(y, predicted),
    log_loss = log_loss(y, predicted),
    calibration_in_the_large = cal$intercept,
    calibration_slope = cal$slope
  )
}

.classify_failure <- function(error) {
  message <- conditionMessage(error)
  lowered <- tolower(message)
  if (grepl("new level|contrasts.*level|factor", lowered)) return("missing_factor_level")
  if (grepl("calibra|calibration", lowered)) return("calibration_failure")
  if (grepl("variation|evento e um não evento|event.*non.event", lowered)) {
    return("outcome_no_variation")
  }
  if (grepl("predict|prediction|probabil|finite", lowered)) return("invalid_predictions")
  if (grepl("converg|separation|separação|rank|singular|coefficients", lowered)) {
    return("separation_or_nonfinite_coefficients")
  }
  "fit_error"
}

.validate_predictions <- function(predicted, family_type) {
  p <- as.numeric(predicted)
  if (!length(p) || any(!is.finite(p))) stop("Predições inválidas: valores não finitos.", call. = FALSE)
  if (family_type == "logistic" && any(p < 0 | p > 1)) {
    stop("Predições inválidas: probabilidades fora de [0, 1].", call. = FALSE)
  }
  invisible(p)
}

.separation_detected <- function(fit) {
  if (!inherits(fit, "glm") || !identical(fit$family$family, "binomial")) return(FALSE)
  coefficients <- stats::coef(fit)
  fitted_values <- as.numeric(stats::fitted(fit))
  # glm() pode declarar convergência em separação quase completa, deixando
  # coeficientes finitos mas enormes e probabilidades numericamente 0/1.
  if (any(!is.finite(coefficients))) return(TRUE)
  if (length(coefficients) && max(abs(coefficients)) > 20 &&
      any(fitted_values < 1e-10 | fitted_values > 1 - 1e-10)) return(TRUE)
  FALSE
}

# Uma réplica completa: índices, ajuste, desempenho no bootstrap e na base
# original, otimismo orientado pela direção da métrica e previsões internas.
bootstrap_replica <- function(data, formula, family, seed, original_data = data,
                              index = NULL, sample_size = nrow(data), replicate = NA_integer_,
                              n = NULL, fit_control = NULL) {
  if (!is.data.frame(data) || !is.data.frame(original_data)) {
    stop("data e original_data devem ser data.frames.", call. = FALSE)
  }
  if (!inherits(formula, "formula")) stop("formula deve ser uma fórmula R.", call. = FALSE)
  if (nrow(data) < 2L || nrow(original_data) < 1L) stop("As bases devem conter linhas suficientes.", call. = FALSE)
  if (!is.null(n)) sample_size <- n
  if (length(sample_size) != 1L || sample_size < 1L || sample_size != as.integer(sample_size)) {
    stop("sample_size deve ser um inteiro positivo.", call. = FALSE)
  }
  family_type <- .family_type(family)
  fam <- .normalize_family(family)
  if (!is.null(fit_control) && !is.list(fit_control)) {
    stop("fit_control deve ser uma lista ou NULL.", call. = FALSE)
  }

  result <- .with_local_seed(seed, {
    indices <- if (is.null(index)) {
      sample.int(nrow(data), size = as.integer(sample_size), replace = TRUE)
    } else as.integer(index)
    if (!length(indices) || any(indices < 1L | indices > nrow(data))) {
      stop("index contém posições inválidas.", call. = FALSE)
    }
    bootstrap_data <- data[indices, , drop = FALSE]
    response <- .response_name(formula)
    if (!response %in% names(data) || !response %in% names(original_data)) {
      stop("O desfecho da fórmula não está presente nas bases.", call. = FALSE)
    }
    y_bootstrap <- bootstrap_data[[response]]
    if (family_type == "logistic" && length(unique(y_bootstrap[!is.na(y_bootstrap)])) < 2L) {
      return(.failure_result(seed, indices, nrow(original_data), "outcome_no_variation",
                             "A amostra bootstrap contém somente uma classe do desfecho.",
                             n_bootstrap = length(indices), sample_size = sample_size))
    }
    if (.missing_factor_level(original_data, bootstrap_data, formula)) {
      return(.failure_result(seed, indices, nrow(original_data), "missing_factor_level",
                             "A amostra bootstrap não contém todos os níveis observados na base original.",
                             n_bootstrap = length(indices), sample_size = sample_size))
    }

    fit_capture <- .capture_warnings(if (family_type == "linear") {
      stats::lm(formula = formula, data = bootstrap_data, model = FALSE, x = FALSE, y = FALSE)
    } else {
      glm_arguments <- list(formula = formula, data = bootstrap_data, family = fam,
                            model = FALSE, x = FALSE, y = FALSE)
      if (!is.null(fit_control)) glm_arguments$control <- do.call(stats::glm.control, fit_control)
      do.call(stats::glm, glm_arguments)
    })
    if (!is.null(fit_capture$error)) {
      return(.failure_result(seed, indices, nrow(original_data),
                             .classify_failure(fit_capture$error),
                             conditionMessage(fit_capture$error), fit_capture$warnings,
                             n_bootstrap = length(indices), sample_size = sample_size))
    }
    fit <- fit_capture$value
    coefficients <- stats::coef(fit)
    separated <- .separation_detected(fit)
    if ((family_type == "logistic" && !isTRUE(fit$converged)) ||
        any(!is.finite(coefficients)) || separated) {
      reason <- if (family_type == "logistic" && !isTRUE(fit$converged))
        "non_convergence" else "separation_or_nonfinite_coefficients"
      return(.failure_result(seed, indices, nrow(original_data), reason,
                             "O ajuste produziu coeficientes não finitos ou não convergiu.",
                             fit_capture$warnings, n_bootstrap = length(indices), sample_size = sample_size))
    }

    pred_capture <- .capture_warnings(list(
      bootstrap = stats::predict(fit, newdata = bootstrap_data, type = "response"),
      original = stats::predict(fit, newdata = original_data, type = "response")
    ))
    if (!is.null(pred_capture$error)) {
      return(.failure_result(seed, indices, nrow(original_data),
                             .classify_failure(pred_capture$error),
                             conditionMessage(pred_capture$error),
                             c(fit_capture$warnings, pred_capture$warnings),
                             n_bootstrap = length(indices), sample_size = sample_size))
    }
    predictions <- pred_capture$value
    valid_prediction <- tryCatch({
      .validate_predictions(predictions$bootstrap, family_type)
      .validate_predictions(predictions$original, family_type)
      TRUE
    }, error = function(e) e)
    if (inherits(valid_prediction, "error")) {
      return(.failure_result(seed, indices, nrow(original_data), "invalid_predictions",
                             conditionMessage(valid_prediction),
                             c(fit_capture$warnings, pred_capture$warnings),
                             n_bootstrap = length(indices), sample_size = sample_size))
    }

    metrics_capture <- .capture_warnings(list(
      bootstrap = .metric_values(bootstrap_data, formula, predictions$bootstrap, family_type),
      original = .metric_values(original_data, formula, predictions$original, family_type)
    ))
    if (!is.null(metrics_capture$error)) {
      return(.failure_result(seed, indices, nrow(original_data),
                             .classify_failure(metrics_capture$error),
                             conditionMessage(metrics_capture$error),
                             c(fit_capture$warnings, pred_capture$warnings,
                               metrics_capture$warnings),
                             n_bootstrap = length(indices), sample_size = sample_size))
    }
    train_metrics <- metrics_capture$value$bootstrap
    test_metrics <- metrics_capture$value$original
    metric_names <- names(train_metrics)
    directions <- metric_directions(family_type)
    optimism <- vapply(metric_names, function(metric) {
      if (directions[[metric]] == "error") test_metrics[[metric]] - train_metrics[[metric]]
      else train_metrics[[metric]] - test_metrics[[metric]]
    }, numeric(1))
    list(
      replicate = as.integer(replicate), seed = as.integer(seed), status = "valid",
      failure_reason = NA_character_, failure_detail = NA_character_,
      failure = list(reason = NA_character_, detail = NA_character_),
      warnings = unique(c(fit_capture$warnings, pred_capture$warnings,
                          metrics_capture$warnings)),
      n_original = nrow(original_data), n_bootstrap = length(indices),
      n_unique_bootstrap = length(unique(indices)), index = indices,
      coefficients = coefficients, predictions = predictions,
      metrics = list(train = train_metrics, test = test_metrics), optimism = optimism
    )
  })
  result
}

metric_directions <- function(model = c("linear", "logistic")) {
  model <- match.arg(model)
  if (model == "linear") {
    c(r2 = "benefit", rmse = "error", mae = "error", mean_error = "target",
      calibration_intercept = "target", calibration_slope = "target")
  } else {
    c(auc = "benefit", brier_score = "error", log_loss = "error",
      calibration_in_the_large = "target", calibration_slope = "target")
  }
}

correct_optimism <- function(apparent, mean_optimism, direction = c("benefit", "error", "target")) {
  direction <- match.arg(direction)
  if (direction == "error") apparent + mean_optimism else apparent - mean_optimism
}

derive_replica_seeds <- function(seed, times) {
  if (length(seed) != 1L || !is.finite(seed) || times < 1L) {
    stop("seed deve ser finito e times deve ser positivo.", call. = FALSE)
  }
  .with_local_seed(seed, sample.int(.Machine$integer.max - 1L, size = times, replace = FALSE))
}

bootstrap_replicates <- function(data, formula, family, times = 2000L, seed = 20260906L,
                                 original_data = data, sample_size = nrow(data),
                                 parallel = FALSE, workers = NULL, n = NULL) {
  if (!is.null(n)) sample_size <- n
  if (times < 1L || times != as.integer(times)) stop("times deve ser inteiro positivo.", call. = FALSE)
  seeds <- derive_replica_seeds(seed, as.integer(times))
  run_one <- function(i) {
    started_at <- Sys.time()
    started_clock <- proc.time()[["elapsed"]]
    result <- bootstrap_replica(
      data = data, formula = formula, family = family, seed = seeds[[i]],
      original_data = original_data, sample_size = sample_size, replicate = i
    )
    # O helper de falha preserva a réplica direta como NA; aqui a tentativa
    # recebe sempre seu número para a tabela de auditoria.
    result$replicate <- as.integer(i)
    result$started_at <- started_at
    result$finished_at <- Sys.time()
    result$elapsed_seconds <- unname(proc.time()[["elapsed"]] - started_clock)
    result
  }
  # Cada chamada recebe a própria semente; mclapply, quando solicitado, não
  # altera a sequência lógica nem os índices das réplicas.
  if (isTRUE(parallel) && .Platform$OS.type != "windows" && requireNamespace("parallel", quietly = TRUE)) {
    jobs <- if (is.null(workers)) getOption("mc.cores", 2L) else as.integer(workers)
    return(parallel::mclapply(seq_len(times), run_one, mc.cores = max(1L, jobs),
                              mc.preschedule = TRUE))
  }
  lapply(seq_len(times), run_one)
}

bootstrap_one_replica <- bootstrap_replica
run_bootstrap_replica <- bootstrap_replica

# Compatibilidade com o helper genérico anterior, agora sem semente global.
bootstrap_statistic <- function(data, statistic, times = 1000L, seeds = NULL, seed = 20260906L) {
  stopifnot(is.data.frame(data), is.function(statistic), times > 0L)
  if (is.null(seeds)) seeds <- derive_replica_seeds(seed, times)
  if (length(seeds) < times) seeds <- rep(seeds, length.out = times)
  estimates <- lapply(seq_len(times), function(i) {
    .with_local_seed(seeds[[i]], {
      index <- sample.int(nrow(data), size = nrow(data), replace = TRUE)
      statistic(data[index, , drop = FALSE])
    })
  })
  if (all(vapply(estimates, is.data.frame, logical(1)))) do.call(rbind, estimates)
  else do.call(rbind, lapply(estimates, as.data.frame))
}

bootstrap_replica_table <- function(replicas) {
  if (!is.list(replicas)) stop("replicas deve ser uma lista.", call. = FALSE)
  valid_replica <- replicas[vapply(replicas, function(x) identical(x$status, "valid"), logical(1))]
  metric_names <- if (length(valid_replica)) {
    unique(c(names(valid_replica[[1]]$metrics$train),
             names(valid_replica[[1]]$metrics$test), names(valid_replica[[1]]$optimism)))
  } else character()
  metric_columns <- c(paste0("train_", metric_names), paste0("test_", metric_names),
                      paste0("optimism_", metric_names))
  rows <- lapply(replicas, function(replica) {
    base <- data.frame(
      replicate = replica$replicate, seed = replica$seed, status = replica$status,
      failure_reason = replica$failure_reason, failure_detail = replica$failure_detail,
      n_original = replica$n_original, n_bootstrap = replica$n_bootstrap,
      n_unique_bootstrap = replica$n_unique_bootstrap, n_warnings = length(replica$warnings),
      stringsAsFactors = FALSE
    )
    values <- setNames(as.list(rep(NA_real_, length(metric_columns))), metric_columns)
    if (identical(replica$status, "valid")) {
      values[paste0("train_", names(replica$metrics$train))] <- as.list(replica$metrics$train)
      values[paste0("test_", names(replica$metrics$test))] <- as.list(replica$metrics$test)
      values[paste0("optimism_", names(replica$optimism))] <- as.list(replica$optimism)
    }
    cbind(base, as.data.frame(values, check.names = FALSE, stringsAsFactors = FALSE))
  })
  do.call(rbind, rows)
}

bootstrap_failure_summary <- function(replicas) {
  reasons <- c("non_convergence", "separation_or_nonfinite_coefficients",
               "invalid_predictions", "missing_factor_level", "calibration_failure",
               "outcome_no_variation", "fit_error")
  observed <- vapply(replicas, function(x) if (identical(x$status, "failed")) x$failure_reason else NA_character_, character(1))
  data.frame(failure_reason = reasons, n = as.integer(table(factor(observed, levels = reasons))),
             stringsAsFactors = FALSE)
}

consolidate_optimism <- function(replicas, apparent_metrics, directions = NULL) {
  if (!is.list(replicas) || !is.numeric(apparent_metrics) || is.null(names(apparent_metrics))) {
    stop("replicas e apparent_metrics nomeado são obrigatórios.", call. = FALSE)
  }
  if (is.null(directions)) {
    directions <- if (all(names(apparent_metrics) %in% names(metric_directions("linear"))))
      metric_directions("linear") else metric_directions("logistic")
  }
  if (!all(names(apparent_metrics) %in% names(directions))) {
    stop("directions não contém todas as métricas aparentes.", call. = FALSE)
  }
  valid <- replicas[vapply(replicas, function(x) identical(x$status, "valid"), logical(1))]
  n_failed_replicas <- sum(vapply(replicas, function(x) identical(x$status, "failed"), logical(1)))
  rows <- lapply(names(apparent_metrics), function(metric) {
    values <- vapply(valid, function(x) {
      if (is.null(x$optimism) || is.null(x$optimism[[metric]])) NA_real_ else x$optimism[[metric]]
    }, numeric(1))
    values <- values[is.finite(values)]
    mean_optimism <- if (length(values)) mean(values) else NA_real_
    data.frame(
      metric = metric, direction = unname(directions[[metric]]),
      apparent = unname(apparent_metrics[[metric]]),
      n_valid = length(values),
      n_failed_replicas = n_failed_replicas,
      n_metric_unavailable = length(valid) - length(values),
      mean_optimism = mean_optimism,
      corrected = if (is.finite(mean_optimism)) correct_optimism(apparent_metrics[[metric]], mean_optimism, directions[[metric]]) else NA_real_,
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

aggregate_bootstrap_results <- consolidate_optimism
consolidate_bootstrap <- consolidate_optimism
summarize_bootstrap_failures <- bootstrap_failure_summary

stability_summary <- function(estimates) {
  if (!is.matrix(estimates) && !is.data.frame(estimates)) stop("estimates deve ser matriz ou data.frame.", call. = FALSE)
  data.frame(
    parameter = colnames(estimates) %||% paste0("parameter_", seq_len(ncol(estimates))),
    mean = vapply(estimates, mean, numeric(1), na.rm = TRUE),
    sd = vapply(estimates, stats::sd, numeric(1), na.rm = TRUE),
    stringsAsFactors = FALSE
  )
}

`%||%` <- function(x, y) if (is.null(x)) y else x
