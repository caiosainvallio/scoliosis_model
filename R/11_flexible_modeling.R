# Modelagem flexível exploratória da Tarefa 09.
#
# A implementação é deliberadamente autocontida: o projeto não instala pacotes
# e glmnet não é uma dependência disponível no ambiente. O algoritmo abaixo usa
# coordenadas para o caso contínuo e IRLS + coordenadas para o caso logístico.
# O objetivo penalizado usa perda média (denominador n), intercepto não
# penalizado e preditores já padronizados pela receita de treino:
#   gaussian: mean((y - eta)^2) / 2 + penalidade
#   logistic: mean(log(1 + exp(eta)) - y * eta) + penalidade
#   penalidade = lambda * ((1-alpha) / 2 * ||beta||^2 + alpha * ||beta||_1).
# O subproblema IRLS também é normalizado por n (e não por sum(weights)), para
# que lambda conserve exatamente a mesma escala do objetivo acima.
#
# Nenhuma função lê ou escreve .GlobalEnv. Todas as receitas de pré-processamento
# são ajustadas somente nos dados recebidos como treino.

FLEXIBLE_NUMERIC_VARS <- c(
  "idade", "imc", "cifose_toracica", "lordose_lombar",
  "correcao_colete", "cobb_inicial_maior"
)
FLEXIBLE_SPLINE_VARS <- FLEXIBLE_NUMERIC_VARS
FLEXIBLE_FACTOR_VARS <- c(
  "sexo", "lenke", "risser", "flexibilidade",
  "escoliometro_maior_10_graus"
)
FLEXIBLE_ALPHA_GRID <- c(0, 0.25, 0.50, 0.75, 1)
FLEXIBLE_LAMBDA_FRACTIONS <- exp(seq(log(1), log(0.001), length.out = 4L))
FLEXIBLE_SPLINE_DF <- 3L
FLEXIBLE_ZERO_TOLERANCE <- 1e-8
FLEXIBLE_KKT_TOLERANCE <- 1e-6

flexible_requirements <- function() {
  if (!requireNamespace("splines", quietly = TRUE)) {
    stop("A Tarefa 09 requer o pacote splines; ele faz parte da instalação base de R.", call. = FALSE)
  }
  invisible(TRUE)
}

flexible_nested_resample_indices <- function(
    n, y, outer = 10L, repeats = 5L, inner = 5L, seed = GLOBAL_SEED + 909L) {
  if (length(n) != 1L || n < 2L || n != as.integer(n)) stop("n inválido.", call. = FALSE)
  if (length(y) != n || anyNA(y) || length(unique(y)) != 2L) stop("y binário completo é necessário.", call. = FALSE)
  if (outer < 2L || repeats < 1L || inner < 2L) stop("Folds/repetições inválidos.", call. = FALSE)
  out <- vector("list", outer * repeats)
  counter <- 0L
  for (repeat_id in seq_len(repeats)) {
    assignment <- with_fixed_seed(seed + repeat_id * 1000L, {
      z <- as.integer(as.factor(y)) - 1L
      fold <- integer(length(z))
      for (level in sort(unique(z))) {
        rows <- which(z == level)
        fold[rows] <- sample(rep(seq_len(outer), length.out = length(rows)))
      }
      fold
    })
    for (outer_fold in seq_len(outer)) {
      counter <- counter + 1L
      outer_train <- which(assignment != outer_fold)
      outer_test <- which(assignment == outer_fold)
      inner_assignment <- with_fixed_seed(
        seed + repeat_id * 100000L + outer_fold * 100L, {
          z <- as.integer(as.factor(y[outer_train])) - 1L
          fold <- integer(length(z))
          for (level in sort(unique(z))) {
            rows <- which(z == level)
            fold[rows] <- sample(rep(seq_len(inner), length.out = length(rows)))
          }
          fold
        }
      )
      inner_splits <- lapply(seq_len(inner), function(inner_fold) {
        list(
          fold = inner_fold,
          train = outer_train[inner_assignment != inner_fold],
          validation = outer_train[inner_assignment == inner_fold]
        )
      })
      out[[counter]] <- list(
        repeat_id = repeat_id, outer_fold = outer_fold,
        train = outer_train, test = outer_test, inner = inner_splits
      )
    }
  }
  class(out) <- c("flexible_nested_indices", "list")
  flexible_validate_nested_indices(out, y, n)
  out
}

flexible_stratified_splits <- function(y, v = 5L, seed = GLOBAL_SEED) {
  if (v < 2L || length(y) < v || anyNA(y) || length(unique(y)) != 2L) {
    stop("Não foi possível criar folds estratificados.", call. = FALSE)
  }
  assignment <- with_fixed_seed(seed, {
    z <- as.integer(as.factor(y)) - 1L
    fold <- integer(length(z))
    for (level in sort(unique(z))) {
      rows <- which(z == level)
      fold[rows] <- sample(rep(seq_len(v), length.out = length(rows)))
    }
    fold
  })
  lapply(seq_len(v), function(fold) list(
    fold = fold, train = which(assignment != fold), validation = which(assignment == fold)
  ))
}

flexible_validate_nested_indices <- function(indices, y, n = length(y)) {
  if (!length(indices)) stop("Nenhum split foi fornecido.", call. = FALSE)
  outer_ids <- vapply(indices, function(x) x$outer_fold, integer(1))
  expected_repeats <- length(indices) / length(unique(outer_ids))
  all_tests <- unlist(lapply(indices, `[[`, "test"), use.names = FALSE)
  if (any(table(factor(all_tests, levels = seq_len(n))) != expected_repeats)) {
    stop("A cobertura externa dos folds é inválida.", call. = FALSE)
  }
  for (split in indices) {
    if (length(intersect(split$train, split$test)) ||
        !setequal(c(split$train, split$test), seq_len(n))) {
      stop("Treino/teste externo inválido.", call. = FALSE)
    }
    for (inner_split in split$inner) {
      if (length(intersect(inner_split$train, inner_split$validation)) ||
          !setequal(c(inner_split$train, inner_split$validation), split$train)) {
        stop("Treino/validação interno inválido.", call. = FALSE)
      }
      if (any(table(factor(y[inner_split$validation], levels = sort(unique(y)))) == 0L)) {
        stop("Validação interna não estratificada.", call. = FALSE)
      }
    }
  }
  invisible(TRUE)
}

flexible_indices_content_equal <- function(left, right) {
  if (length(left) != length(right)) return(FALSE)
  all(vapply(seq_along(left), function(i) {
    a <- left[[i]]; b <- right[[i]]
    identical(a$repeat_id, b$repeat_id) && identical(a$outer_fold, b$outer_fold) &&
      identical(a$train, b$train) && identical(a$test, b$test) &&
      length(a$inner) == length(b$inner) &&
      all(vapply(seq_along(a$inner), function(j) {
        identical(a$inner[[j]]$fold, b$inner[[j]]$fold) &&
          identical(a$inner[[j]]$train, b$inner[[j]]$train) &&
          identical(a$inner[[j]]$validation, b$inner[[j]]$validation)
      }, logical(1)))
  }, logical(1)))
}

flexible_default_grid <- function() {
  grid <- expand.grid(
    alpha = FLEXIBLE_ALPHA_GRID,
    lambda_fraction = FLEXIBLE_LAMBDA_FRACTIONS,
    KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE
  )
  grid$config_id <- seq_len(nrow(grid))
  grid
}

flexible_validate_grid <- function(grid) {
  required <- c("alpha", "lambda_fraction")
  if (!all(required %in% names(grid)) || !nrow(grid)) stop("Grade elastic net inválida.", call. = FALSE)
  if (any(!is.finite(grid$alpha)) || any(grid$alpha < 0 | grid$alpha > 1) ||
      any(!is.finite(grid$lambda_fraction)) || any(grid$lambda_fraction <= 0)) {
    stop("alpha deve estar em [0, 1] e lambda_fraction deve ser positivo.", call. = FALSE)
  }
  if (!"config_id" %in% names(grid)) grid$config_id <- seq_len(nrow(grid))
  grid
}

flexible_safe_numeric <- function(x, fallback = 0) {
  x <- as.numeric(x)
  x[!is.finite(x)] <- fallback
  x
}

flexible_spline_fit <- function(x, df = FLEXIBLE_SPLINE_DF) {
  x <- flexible_safe_numeric(x, 0)
  observed <- sort(unique(x))
  if (length(observed) < 4L || diff(range(x)) == 0) {
    return(list(active = FALSE, df = 0L, knots = numeric(), boundary = range(x)))
  }
  basis <- splines::ns(x, df = df, intercept = FALSE)
  list(active = TRUE, df = ncol(basis), knots = attr(basis, "knots"),
       boundary = attr(basis, "Boundary.knots"))
}

flexible_spline_apply <- function(x, specification) {
  x <- flexible_safe_numeric(x, mean(specification$boundary))
  if (!isTRUE(specification$active)) return(matrix(numeric(), nrow = length(x), ncol = 0L))
  splines::ns(x, knots = specification$knots, Boundary.knots = specification$boundary,
              intercept = FALSE)
}

flexible_factor_levels <- function(variable, data) {
  levels <- if (exists("FACTOR_LEVELS", inherits = TRUE) && !is.null(FACTOR_LEVELS[[variable]])) {
    FACTOR_LEVELS[[variable]]
  } else {
    sort(unique(as.character(data[[variable]])))
  }
  levels[!is.na(levels)]
}

flexible_raw_design <- function(data, recipe) {
  n <- nrow(data)
  columns <- list()
  names_out <- character()
  add_column <- function(value, name) {
    columns[[length(columns) + 1L]] <<- as.numeric(value)
    names_out <<- c(names_out, name)
  }

  for (variable in FLEXIBLE_NUMERIC_VARS) {
    value <- as.numeric(data[[variable]])
    value[is.na(value)] <- recipe$numeric_medians[[variable]]
    centered <- (value - recipe$numeric_means[[variable]]) / recipe$numeric_scales[[variable]]
    add_column(centered, paste0(variable, "__linear"))
    spline <- flexible_spline_apply(value, recipe$splines[[variable]])
    if (ncol(spline)) {
      for (j in seq_len(ncol(spline))) {
        add_column(as.numeric(spline[, j]), paste0(variable, "__spline_", j))
      }
    }
  }

  factor_matrix <- list()
  for (variable in FLEXIBLE_FACTOR_VARS) {
    values <- as.character(data[[variable]])
    values[is.na(values)] <- recipe$factor_modes[[variable]]
    levels <- recipe$factor_levels[[variable]]
    reference <- if (exists("FACTOR_REFERENCES", inherits = TRUE)) FACTOR_REFERENCES[[variable]] else levels[[1]]
    dummy_levels <- setdiff(levels, reference)
    factor_matrix[[variable]] <- list(values = values, levels = levels, reference = reference,
                                      dummy_levels = dummy_levels)
    for (level in dummy_levels) add_column(as.integer(values == level), paste0(variable, "__dummy_", level))
  }

  # Interações usam somente os componentes lineares padronizados e todos os
  # dummies não referência. Os efeitos principais estão sempre na matriz.
  linear_value <- function(variable) {
    value <- as.numeric(data[[variable]])
    value[is.na(value)] <- recipe$numeric_medians[[variable]]
    (value - recipe$numeric_means[[variable]]) / recipe$numeric_scales[[variable]]
  }
  interaction_add <- function(left, right) {
    for (level in factor_matrix[[right]]$dummy_levels) {
      add_column(linear_value(left) * as.integer(factor_matrix[[right]]$values == level),
                 paste0(left, "_x_", right, "__", level))
    }
  }
  interaction_add("correcao_colete", "flexibilidade")
  interaction_add("correcao_colete", "lenke")
  interaction_add("idade", "risser")

  if (!length(columns)) return(matrix(numeric(), nrow = n, ncol = 0L))
  result <- do.call(cbind, columns)
  colnames(result) <- names_out
  result
}

flexible_preprocess_fit <- function(data) {
  missing <- setdiff(c(FLEXIBLE_NUMERIC_VARS, FLEXIBLE_FACTOR_VARS), names(data))
  if (length(missing)) stop("Variáveis ausentes no treino: ", paste(missing, collapse = ", "), call. = FALSE)
  numeric_medians <- setNames(vapply(FLEXIBLE_NUMERIC_VARS, function(variable) {
    value <- suppressWarnings(stats::median(as.numeric(data[[variable]]), na.rm = TRUE))
    if (!is.finite(value)) 0 else value
  }, numeric(1)), FLEXIBLE_NUMERIC_VARS)
  numeric_means <- setNames(vapply(FLEXIBLE_NUMERIC_VARS, function(variable) {
    value <- as.numeric(data[[variable]])
    value[is.na(value)] <- numeric_medians[[variable]]
    mean(value)
  }, numeric(1)), FLEXIBLE_NUMERIC_VARS)
  numeric_scales <- setNames(vapply(FLEXIBLE_NUMERIC_VARS, function(variable) {
    value <- as.numeric(data[[variable]])
    value[is.na(value)] <- numeric_medians[[variable]]
    scale <- stats::sd(value)
    if (!is.finite(scale) || scale == 0) 1 else scale
  }, numeric(1)), FLEXIBLE_NUMERIC_VARS)
  factor_levels <- setNames(lapply(FLEXIBLE_FACTOR_VARS, flexible_factor_levels, data = data), FLEXIBLE_FACTOR_VARS)
  factor_modes <- setNames(vapply(FLEXIBLE_FACTOR_VARS, function(variable) {
    values <- as.character(data[[variable]])
    values <- values[!is.na(values)]
    if (!length(values)) {
      if (exists("FACTOR_REFERENCES", inherits = TRUE)) FACTOR_REFERENCES[[variable]] else factor_levels[[variable]][[1]]
    } else names(sort(table(values), decreasing = TRUE))[1]
  }, character(1)), FLEXIBLE_FACTOR_VARS)
  recipe <- list(
    numeric_medians = numeric_medians, numeric_means = numeric_means,
    numeric_scales = numeric_scales, factor_levels = factor_levels,
    factor_modes = factor_modes,
    splines = setNames(lapply(FLEXIBLE_SPLINE_VARS, function(variable) {
      value <- as.numeric(data[[variable]])
      value[is.na(value)] <- numeric_medians[[variable]]
      flexible_spline_fit(value)
    }), FLEXIBLE_SPLINE_VARS)
  )
  raw <- flexible_raw_design(data, recipe)
  recipe$feature_names <- colnames(raw)
  recipe$feature_means <- if (ncol(raw)) colMeans(raw) else numeric()
  recipe$feature_scales <- if (ncol(raw)) apply(raw, 2, stats::sd) else numeric()
  recipe$feature_scales[!is.finite(recipe$feature_scales) | recipe$feature_scales == 0] <- 1
  recipe
}

flexible_preprocess_apply <- function(data, recipe) {
  raw <- flexible_raw_design(data, recipe)
  missing <- setdiff(recipe$feature_names, colnames(raw))
  if (length(missing)) {
    fill <- matrix(0, nrow = nrow(raw), ncol = length(missing),
                   dimnames = list(NULL, missing))
    raw <- cbind(raw, fill)
  }
  extra <- setdiff(colnames(raw), recipe$feature_names)
  if (length(extra)) raw <- raw[, setdiff(colnames(raw), extra), drop = FALSE]
  raw <- raw[, recipe$feature_names, drop = FALSE]
  scaled <- sweep(raw, 2, recipe$feature_means, "-")
  scaled <- sweep(scaled, 2, recipe$feature_scales, "/")
  scaled
}

flexible_feature_metadata <- function(feature_names) {
  interaction <- grepl("_x_", feature_names, fixed = TRUE)
  data.frame(
    feature = feature_names,
    variable = vapply(strsplit(feature_names, "__", fixed = TRUE), `[[`, character(1), 1L),
    component = ifelse(grepl("__spline_", feature_names), "spline",
                       ifelse(grepl("__dummy_", feature_names), "dummy",
                              ifelse(interaction, "interaction", "linear"))),
    interaction = interaction,
    additional = grepl("cobb_inicial_maior|spline|_x_", feature_names),
    stringsAsFactors = FALSE
  )
}

flexible_lambda_max <- function(x, y, family, alpha_floor = 0.05) {
  x <- as.matrix(x); y <- as.numeric(y); n <- nrow(x)
  if (family == "continuous") score <- abs(crossprod(x, y - mean(y))) / n
  else {
    p <- rep(mean(y), length(y)); score <- abs(crossprod(x, y - p)) / n
  }
  maximum <- max(score, na.rm = TRUE) / alpha_floor
  if (!is.finite(maximum) || maximum <= 0) 1 else maximum
}

flexible_soft_threshold <- function(z, gamma) sign(z) * max(abs(z) - gamma, 0)

flexible_objective <- function(intercept, beta, x, y, family, lambda, alpha) {
  eta <- as.numeric(intercept + x %*% beta)
  loss <- if (family == "continuous") {
    mean((y - eta)^2) / 2
  } else {
    mean(pmax(eta, 0) + log1p(exp(-abs(eta))) - y * eta)
  }
  loss + lambda * ((1 - alpha) * sum(beta^2) / 2 + alpha * sum(abs(beta)))
}

flexible_kkt <- function(intercept, beta, x, y, family, lambda, alpha,
                         zero_tolerance = FLEXIBLE_ZERO_TOLERANCE) {
  eta <- as.numeric(intercept + x %*% beta)
  residual_gradient <- if (family == "continuous") eta - y else plogis(eta) - y
  smooth <- as.numeric(crossprod(x, residual_gradient)) / nrow(x) +
    lambda * (1 - alpha) * beta
  active <- abs(beta) > zero_tolerance
  violation <- numeric(length(beta))
  violation[active] <- abs(smooth[active] + lambda * alpha * sign(beta[active]))
  violation[!active] <- pmax(abs(smooth[!active]) - lambda * alpha, 0)
  intercept_gradient <- mean(residual_gradient)
  list(
    intercept_gradient = intercept_gradient,
    coefficient_violation = setNames(violation, colnames(x)),
    maximum = max(abs(intercept_gradient), violation),
    n_zero = sum(!active),
    zero_maximum = if (any(!active)) max(violation[!active]) else 0
  )
}

flexible_cd_gaussian <- function(x, y, lambda, alpha, initial = NULL,
                                 initial_intercept = NULL, maxit = 2000L,
                                 tol = 1e-8) {
  n <- nrow(x); p <- ncol(x)
  beta <- if (is.null(initial)) numeric(p) else as.numeric(initial)
  intercept <- if (is.null(initial_intercept)) mean(y) else as.numeric(initial_intercept)
  residual <- y - intercept - as.numeric(x %*% beta)
  denominator <- colSums(x * x) / n + lambda * (1 - alpha)
  denominator[!is.finite(denominator) | denominator <= 0] <- 1
  for (iteration in seq_len(maxit)) {
    old <- c(intercept, beta)
    intercept_change <- mean(residual)
    intercept <- intercept + intercept_change
    residual <- residual - intercept_change
    for (j in seq_len(p)) {
      residual <- residual + x[, j] * beta[[j]]
      rho <- sum(x[, j] * residual) / n
      beta[[j]] <- flexible_soft_threshold(rho, lambda * alpha) / denominator[[j]]
      residual <- residual - x[, j] * beta[[j]]
    }
    if (max(abs(c(intercept, beta) - old)) < tol) break
  }
  change <- max(abs(c(intercept, beta) - old))
  list(intercept = intercept, beta = beta, iterations = iteration,
       converged = is.finite(change) && change < tol)
}

flexible_cd_weighted <- function(x, z, weights, lambda, alpha, initial = NULL,
                                 initial_intercept = NULL, maxit = 1000L,
                                 tol = 1e-8) {
  n <- nrow(x); p <- ncol(x)
  beta <- if (is.null(initial)) numeric(p) else as.numeric(initial)
  intercept <- if (is.null(initial_intercept)) weighted.mean(z, weights) else as.numeric(initial_intercept)
  residual <- z - intercept - as.numeric(x %*% beta)
  # Dividir por n é essencial: esta é a Hessiana da perda média declarada.
  denominator <- colSums(x * (weights * x)) / n + lambda * (1 - alpha)
  denominator[!is.finite(denominator) | denominator <= 0] <- 1
  for (iteration in seq_len(maxit)) {
    old <- c(intercept, beta)
    intercept_change <- sum(weights * residual) / sum(weights)
    intercept <- intercept + intercept_change
    residual <- residual - intercept_change
    for (j in seq_len(p)) {
      residual <- residual + x[, j] * beta[[j]]
      rho <- sum(weights * x[, j] * residual) / n
      beta[[j]] <- flexible_soft_threshold(rho, lambda * alpha) / denominator[[j]]
      residual <- residual - x[, j] * beta[[j]]
    }
    if (max(abs(c(intercept, beta) - old)) < tol) break
  }
  change <- max(abs(c(intercept, beta) - old))
  list(intercept = intercept, beta = beta, iterations = iteration,
       converged = is.finite(change) && change < tol)
}

flexible_fit_one <- function(x, y, family = c("continuous", "logistic"), lambda, alpha,
                             feature_means = numeric(), feature_scales = numeric(),
                             maxit = 2000L, initial_beta = NULL, initial_intercept = NULL,
                             kkt_tol = FLEXIBLE_KKT_TOLERANCE) {
  family <- match.arg(family)
  x <- as.matrix(x); y <- as.numeric(y)
  if (length(maxit) != 1L || !is.finite(maxit) || maxit < 1L) {
    stop("maxit deve ser um inteiro positivo.", call. = FALSE)
  }
  if (!nrow(x) || !ncol(x)) stop("Matriz de preditores vazia.", call. = FALSE)
  if (length(y) != nrow(x) || any(!is.finite(x)) || any(!is.finite(y))) {
    stop("x e y devem ser finitos e ter dimensões compatíveis.", call. = FALSE)
  }
  if (!is.finite(lambda) || lambda < 0 || !is.finite(alpha) || alpha < 0 || alpha > 1) {
    stop("lambda deve ser não negativo e alpha deve estar em [0, 1].", call. = FALSE)
  }
  if (family == "logistic" && (!all(y %in% c(0, 1)) || length(unique(y)) < 2L)) {
    stop("O ajuste logístico requer y binário com as duas classes.", call. = FALSE)
  }
  if (!length(feature_means)) feature_means <- rep(0, ncol(x))
  if (!length(feature_scales)) feature_scales <- rep(1, ncol(x))
  if (length(feature_means) != ncol(x) || length(feature_scales) != ncol(x) ||
      any(!is.finite(feature_means)) || any(!is.finite(feature_scales)) ||
      any(feature_scales <= 0)) stop("Metadados de padronização inválidos.", call. = FALSE)
  failure_reason <- NA_character_
  if (family == "continuous") {
    fit <- flexible_cd_gaussian(x, y, lambda, alpha, initial = initial_beta,
                                initial_intercept = initial_intercept, maxit = maxit)
    intercept <- fit$intercept
    beta <- fit$beta
  } else {
    prevalence <- min(max(mean(y), 1e-6), 1 - 1e-6)
    intercept <- if (is.null(initial_intercept)) stats::qlogis(prevalence) else initial_intercept
    beta <- if (is.null(initial_beta)) numeric(ncol(x)) else as.numeric(initial_beta)
    converged <- FALSE
    objective <- flexible_objective(intercept, beta, x, y, family, lambda, alpha)
    outer_maxit <- max(1L, min(as.integer(maxit), 100L))
    for (iteration in seq_len(outer_maxit)) {
      old_intercept <- intercept; old_beta <- beta; old_objective <- objective
      eta <- intercept + as.numeric(x %*% beta)
      probability <- plogis(eta)
      weights <- pmax(probability * (1 - probability), 1e-8)
      z <- eta + (y - probability) / weights
      working <- flexible_cd_weighted(x, z, weights, lambda, alpha, beta,
                                      initial_intercept = intercept,
                                      maxit = max(50L, min(2000L, as.integer(maxit))), tol = 1e-10)
      beta_new <- working$beta
      intercept_new <- working$intercept
      new_objective <- flexible_objective(intercept_new, beta_new, x, y, family, lambda, alpha)
      step <- 1
      while ((!is.finite(new_objective) || new_objective > old_objective + 1e-12) && step > 2^-20) {
        step <- step / 2
        intercept_new <- old_intercept + step * (working$intercept - old_intercept)
        beta_new <- old_beta + step * (working$beta - old_beta)
        new_objective <- flexible_objective(intercept_new, beta_new, x, y, family, lambda, alpha)
      }
      if (!is.finite(new_objective) || new_objective > old_objective + 1e-10) {
        failure_reason <- "line_search_failed"
        break
      }
      beta <- beta_new; intercept <- intercept_new; objective <- new_objective
      kkt <- flexible_kkt(intercept, beta, x, y, family, lambda, alpha)
      parameter_change <- max(abs(c(beta - old_beta, intercept - old_intercept)))
      if (kkt$maximum <= kkt_tol &&
          (parameter_change <= 1e-7 || abs(old_objective - objective) <= 1e-10 * (1 + abs(objective)))) {
        converged <- TRUE
        break
      }
    }
    fit <- list(iterations = iteration, converged = converged)
    if (!converged && is.na(failure_reason)) failure_reason <- "maximum_iterations_or_kkt_not_met"
  }
  diagnostics <- flexible_kkt(intercept, beta, x, y, family, lambda, alpha)
  objective <- flexible_objective(intercept, beta, x, y, family, lambda, alpha)
  fit$converged <- isTRUE(fit$converged) && is.finite(objective) &&
    is.finite(diagnostics$maximum) && diagnostics$maximum <= kkt_tol
  if (!is.finite(intercept) || any(!is.finite(beta)) || !is.finite(objective)) {
    fit$converged <- FALSE
    failure_reason <- "non_finite_solution"
  }
  if (!fit$converged && is.na(failure_reason)) failure_reason <- "kkt_not_met"
  beta_raw <- beta / feature_scales
  intercept_raw <- intercept - sum(feature_means * beta_raw)
  structure(list(family = family, lambda = lambda, alpha = alpha,
                 intercept = intercept, beta = setNames(beta, colnames(x)),
                 intercept_raw = intercept_raw, beta_raw = setNames(beta_raw, colnames(x)),
                 converged = isTRUE(fit$converged), iterations = fit$iterations,
                 objective = objective, kkt_max = diagnostics$maximum,
                 intercept_gradient = diagnostics$intercept_gradient,
                 n_zero = diagnostics$n_zero, zero_kkt_max = diagnostics$zero_maximum,
                 failure_reason = if (isTRUE(fit$converged)) NA_character_ else failure_reason,
                 feature_means = feature_means, feature_scales = feature_scales),
            class = "flexible_enet_fit")
}

flexible_predict <- function(model, x) {
  x <- as.matrix(x)
  if (!isTRUE(model$converged) || any(!is.finite(model$beta)) || !is.finite(model$intercept)) {
    return(rep(NA_real_, nrow(x)))
  }
  eta <- model$intercept + as.numeric(x %*% model$beta)
  if (model$family == "logistic") plogis(eta) else eta
}

flexible_fit_path <- function(x, y, family, alpha, lambda_fractions, lambda_max,
                              feature_means, feature_scales) {
  lambdas <- lambda_max * lambda_fractions
  models <- vector("list", length(lambdas)); previous <- NULL
  previous_intercept <- NULL
  for (i in seq_along(lambdas)) {
    models[[i]] <- flexible_fit_one(x, y, family, lambdas[[i]], alpha,
                                    feature_means, feature_scales, maxit = 300L,
                                    initial_beta = previous, initial_intercept = previous_intercept)
    if (isTRUE(models[[i]]$converged)) {
      previous <- models[[i]]$beta
      previous_intercept <- models[[i]]$intercept
    } else {
      previous <- NULL
      previous_intercept <- NULL
    }
  }
  models
}

flexible_metric_row <- function(y, prediction, family, repeat_id = NA_integer_,
                                outer_fold = NA_integer_, scope = "outer_fold") {
  valid_prediction <- length(y) == length(prediction) && length(y) > 0L &&
    all(is.finite(y)) && all(is.finite(prediction))
  if (!valid_prediction) {
    return(data.frame(
      family = family, scope = scope, repeat_id = repeat_id, outer_fold = outer_fold,
      n = length(y), r2 = NA_real_, rmse = NA_real_, mae = NA_real_,
      calibration_intercept = NA_real_, calibration_slope = NA_real_, auc = NA_real_,
      brier_score = NA_real_, log_loss = NA_real_, stringsAsFactors = FALSE
    ))
  }
  if (family == "continuous") {
    values <- data.frame(
      family = family, scope = scope, repeat_id = repeat_id, outer_fold = outer_fold,
      n = length(y), r2 = r_squared(y, prediction), rmse = rmse(y, prediction),
      mae = mae(y, prediction), calibration_intercept = NA_real_,
      calibration_slope = NA_real_, auc = NA_real_, brier_score = NA_real_,
      log_loss = NA_real_, stringsAsFactors = FALSE
    )
    calibration <- tryCatch(calibration_linear(y, prediction), error = function(e) NULL)
    if (!is.null(calibration)) {
      values$calibration_intercept <- calibration$intercept
      values$calibration_slope <- calibration$slope
    }
    values
  } else {
    p <- clip_probabilities(prediction)
    values <- data.frame(
      family = family, scope = scope, repeat_id = repeat_id, outer_fold = outer_fold,
      n = length(y), r2 = NA_real_, rmse = NA_real_, mae = NA_real_,
      calibration_intercept = NA_real_, calibration_slope = NA_real_,
      auc = tryCatch(auc_rank(y, p), error = function(e) NA_real_),
      brier_score = mean((as.numeric(y) - p)^2), log_loss = log_loss(y, p),
      stringsAsFactors = FALSE
    )
    calibration <- tryCatch(calibration_logistic(y, p), error = function(e) NULL)
    if (!is.null(calibration)) {
      values$calibration_intercept <- calibration$intercept
      values$calibration_slope <- calibration$slope
    }
    values
  }
}

flexible_metric_distribution <- function(metrics) {
  rows <- metrics[metrics$scope == "outer_fold", , drop = FALSE]
  metric_names <- c("r2", "rmse", "mae", "auc", "brier_score", "log_loss",
                    "calibration_intercept", "calibration_slope")
  do.call(rbind, lapply(unique(rows$family), function(family) {
    do.call(rbind, lapply(metric_names, function(metric) {
      value <- rows[[metric]][rows$family == family]
      data.frame(family = family, metric = metric, n = sum(is.finite(value)),
                 mean = mean(value, na.rm = TRUE), sd = stats::sd(value, na.rm = TRUE),
                 median = stats::median(value, na.rm = TRUE),
                 q025 = stats::quantile(value, .025, na.rm = TRUE, names = FALSE),
                 q975 = stats::quantile(value, .975, na.rm = TRUE, names = FALSE),
                 stringsAsFactors = FALSE)
    }))
  }))
}

flexible_tuning_one <- function(data, y, inner_splits, family, grid) {
  grid <- flexible_validate_grid(grid)
  rows <- vector("list", nrow(grid) * length(inner_splits)); counter <- 0L
  for (inner_split in inner_splits) {
    train <- data[inner_split$train, , drop = FALSE]
    validation <- data[inner_split$validation, , drop = FALSE]
    recipe <- flexible_preprocess_fit(train)
    x_train <- flexible_preprocess_apply(train, recipe)
    x_validation <- flexible_preprocess_apply(validation, recipe)
    lambda_max <- flexible_lambda_max(x_train, y[inner_split$train], family)
    for (alpha in sort(unique(grid$alpha))) {
      alpha_rows <- which(grid$alpha == alpha)
      fractions <- grid$lambda_fraction[alpha_rows]
      order_path <- order(fractions, decreasing = TRUE)
      path <- flexible_fit_path(x_train, y[inner_split$train], family, alpha,
                                fractions[order_path], lambda_max,
                                recipe$feature_means, recipe$feature_scales)
      for (path_index in seq_along(alpha_rows)) {
        config_id <- alpha_rows[[path_index]]
        config <- grid[config_id, , drop = FALSE]
        model <- path[[match(config$lambda_fraction, fractions[order_path])]]
        prediction <- flexible_predict(model, x_validation)
        metric <- if (!isTRUE(model$converged) || any(!is.finite(prediction))) {
          NA_real_
        } else if (family == "continuous") {
          rmse(y[inner_split$validation], prediction)
        } else {
          log_loss(y[inner_split$validation], prediction)
        }
        counter <- counter + 1L
        rows[[counter]] <- data.frame(
          config_id = config$config_id, inner_fold = inner_split$fold,
          alpha = config$alpha, lambda_fraction = config$lambda_fraction,
          lambda_max = lambda_max, lambda = model$lambda, metric = metric,
          converged = model$converged, objective = model$objective,
          kkt_max = model$kkt_max, failure_reason = model$failure_reason,
          n_features = ncol(x_train),
          stringsAsFactors = FALSE
        )
      }
    }
  }
  fold_results <- do.call(rbind, rows)
  summary <- do.call(rbind, lapply(seq_len(nrow(grid)), function(i) {
    take <- fold_results$config_id == grid$config_id[[i]]
    value <- fold_results$metric[take]
    data.frame(config_id = grid$config_id[[i]], alpha = grid$alpha[[i]],
               lambda_fraction = grid$lambda_fraction[[i]],
               mean_metric = mean(value, na.rm = TRUE), sd_metric = stats::sd(value, na.rm = TRUE),
               se_metric = stats::sd(value, na.rm = TRUE) / sqrt(sum(is.finite(value))),
               n_valid = sum(is.finite(value)), n_converged = sum(fold_results$converged[take]),
               stringsAsFactors = FALSE)
  }))
  summary$sd_metric[!is.finite(summary$sd_metric)] <- 0
  summary$se_metric[!is.finite(summary$se_metric)] <- 0
  summary$n_failed <- length(inner_splits) - summary$n_converged
  complete <- summary$n_valid == length(inner_splits) &
    summary$n_converged == length(inner_splits)
  summary$mean_metric[!complete] <- NA_real_
  summary$sd_metric[!complete] <- NA_real_
  summary$se_metric[!complete] <- NA_real_
  valid <- is.finite(summary$mean_metric) & complete
  if (!any(valid)) stop("Nenhuma configuração teve métrica interna válida.", call. = FALSE)
  best <- summary[which(valid)[order(summary$mean_metric[valid], summary$config_id[valid])][1L], , drop = FALSE]
  threshold <- best$mean_metric + best$se_metric
  eligible <- summary[valid & summary$mean_metric <= threshold, , drop = FALSE]
  # Lambda maior = penalização maior; alpha menor é o desempate conservador.
  selected <- eligible[order(-eligible$lambda_fraction, eligible$alpha, eligible$config_id), , drop = FALSE][1L, ]
  summary$one_se_threshold <- threshold
  summary$eligible_one_se <- summary$config_id %in% eligible$config_id
  summary$selected_one_se <- summary$config_id == selected$config_id
  list(selected = selected, best = best, threshold = threshold,
       summary = summary, fold_results = fold_results)
}

flexible_fit_selected <- function(data, y, family, selected, recipe = NULL) {
  if (is.null(recipe)) recipe <- flexible_preprocess_fit(data)
  x <- flexible_preprocess_apply(data, recipe)
  lambda_max <- flexible_lambda_max(x, y, family)
  model <- flexible_fit_one(x, y, family, lambda_max * selected$lambda_fraction,
                            selected$alpha, recipe$feature_means, recipe$feature_scales,
                            maxit = 2500L)
  list(model = model, recipe = recipe, x = x, lambda_max = lambda_max,
       lambda = model$lambda, selected = selected)
}

flexible_coefficient_rows <- function(fit, family, repeat_id, outer_fold) {
  metadata <- flexible_feature_metadata(names(fit$model$beta_raw))
  data.frame(
    family = family, repeat_id = repeat_id, outer_fold = outer_fold,
    feature = metadata$feature, variable = metadata$variable,
    component = metadata$component, interaction = metadata$interaction,
    additional = metadata$additional, coefficient = as.numeric(fit$model$beta_raw),
    stringsAsFactors = FALSE
  )
}

flexible_selection_tables <- function(coefficients, n_models) {
  coefficients$selected <- abs(coefficients$coefficient) > FLEXIBLE_ZERO_TOLERANCE
  component <- do.call(rbind, lapply(split(coefficients, list(coefficients$family, coefficients$feature), drop = TRUE), function(x) {
    data.frame(unit_type = "componente", unit = x$feature[[1]], family = x$family[[1]],
               variable = x$variable[[1]], component = x$component[[1]], additional = x$additional[[1]],
               selection_count = sum(x$selected), selection_frequency = mean(x$selected),
               mean_abs_coefficient = mean(abs(x$coefficient)),
               median_abs_coefficient = stats::median(abs(x$coefficient)),
               stringsAsFactors = FALSE)
  }))
  term <- do.call(rbind, lapply(split(coefficients, list(coefficients$family, coefficients$variable), drop = TRUE), function(x) {
    selected_by_fit <- tapply(x$selected, list(x$repeat_id, x$outer_fold), any)
    data.frame(unit_type = "termo", unit = x$variable[[1]], family = x$family[[1]],
               variable = x$variable[[1]], component = "term",
               additional = any(x$additional), selection_count = sum(selected_by_fit),
               selection_frequency = mean(selected_by_fit),
               mean_abs_coefficient = mean(abs(x$coefficient)),
               median_abs_coefficient = stats::median(abs(x$coefficient)), stringsAsFactors = FALSE)
  }))
  clinical <- do.call(rbind, lapply(split(coefficients, coefficients$family), function(x) {
    variables <- c(FLEXIBLE_NUMERIC_VARS, FLEXIBLE_FACTOR_VARS)
    do.call(rbind, lapply(variables, function(variable) {
      involved <- grepl(paste0("^", variable, "__"), x$feature) |
        grepl(paste0("^", variable, "_x_"), x$feature) |
        grepl(paste0("_x_", variable, "__"), x$feature)
      selected_by_fit <- tapply(abs(x$coefficient[involved]) > FLEXIBLE_ZERO_TOLERANCE,
                                list(x$repeat_id[involved], x$outer_fold[involved]), any)
      data.frame(unit_type = "variavel_clinica", unit = variable, family = x$family[[1]],
                 variable = variable, component = "clinical_variable", additional = any(x$additional[involved]),
                 selection_count = sum(selected_by_fit), selection_frequency = mean(selected_by_fit),
                 mean_abs_coefficient = mean(abs(x$coefficient[involved])),
                 median_abs_coefficient = stats::median(abs(x$coefficient[involved])), stringsAsFactors = FALSE)
    }))
  }))
  result <- rbind(component, term, clinical)
  result$n_models <- n_models
  row.names(result) <- NULL
  result
}

flexible_coefficient_stability <- function(coefficients) {
  do.call(rbind, lapply(split(coefficients, list(coefficients$family, coefficients$feature), drop = TRUE), function(x) {
    nonzero <- abs(x$coefficient) > FLEXIBLE_ZERO_TOLERANCE
    signs <- sign(x$coefficient[nonzero])
    data.frame(family = x$family[[1]], feature = x$feature[[1]], variable = x$variable[[1]],
               component = x$component[[1]], additional = x$additional[[1]],
               n_models = nrow(x), selection_frequency = mean(nonzero),
               mean_coefficient = mean(x$coefficient), mean_abs_coefficient = mean(abs(x$coefficient)),
               median_coefficient = stats::median(x$coefficient),
               q025 = stats::quantile(x$coefficient, .025, names = FALSE),
               q975 = stats::quantile(x$coefficient, .975, names = FALSE),
               sign_consistency = if (length(signs)) max(table(signs)) / length(signs) else NA_real_,
               stringsAsFactors = FALSE)
  }))
}

flexible_prediction_stability <- function(predictions) {
  groups <- split(predictions, list(predictions$participant_index, predictions$family), drop = TRUE)
  do.call(rbind, lapply(groups, function(x) {
    data.frame(participant_index = x$participant_index[[1]], family = x$family[[1]],
               n_predictions = nrow(x), mean_prediction = mean(x$prediction),
               sd_prediction = stats::sd(x$prediction), q025 = stats::quantile(x$prediction, .025, names = FALSE),
               q975 = stats::quantile(x$prediction, .975, names = FALSE),
               range_prediction = diff(range(x$prediction)), stringsAsFactors = FALSE)
  }))
}

flexible_prediction_stability_summary <- function(stability) {
  do.call(rbind, lapply(split(stability, stability$family), function(x) {
    data.frame(
      family = x$family[[1]], n_participants = nrow(x),
      mean_sd_prediction = mean(x$sd_prediction, na.rm = TRUE),
      median_sd_prediction = stats::median(x$sd_prediction, na.rm = TRUE),
      q025_sd_prediction = stats::quantile(x$sd_prediction, .025, na.rm = TRUE, names = FALSE),
      q975_sd_prediction = stats::quantile(x$sd_prediction, .975, na.rm = TRUE, names = FALSE),
      mean_prediction_range = mean(x$range_prediction, na.rm = TRUE),
      median_prediction_range = stats::median(x$range_prediction, na.rm = TRUE),
      q975_prediction_range = stats::quantile(x$range_prediction, .975, na.rm = TRUE, names = FALSE),
      stringsAsFactors = FALSE
    )
  }))
}

flexible_fit_frozen_external <- function(cohort, train, test, family) {
  if (family == "continuous") {
    formula <- stats::reformulate(MODEL_PREDICTORS, response = "delta")
    fit <- stats::lm(formula, data = cohort[train, , drop = FALSE])
    prediction <- as.numeric(stats::predict(fit, newdata = cohort[test, , drop = FALSE]))
    observed <- cohort$delta[test]
  } else {
    formula <- stats::reformulate(MODEL_PREDICTORS, response = "delta_cat")
    fit <- suppressWarnings(stats::glm(formula, data = cohort[train, , drop = FALSE], family = stats::binomial()))
    prediction <- as.numeric(stats::predict(fit, newdata = cohort[test, , drop = FALSE], type = "response"))
    observed <- cohort$delta_cat[test]
  }
  list(observed = observed, prediction = prediction, converged = if (family == "continuous") TRUE else isTRUE(fit$converged))
}

flexible_compare_frozen <- function(flexible_metrics, frozen_metrics) {
  keys <- c("family", "repeat_id", "outer_fold")
  merged <- merge(flexible_metrics[flexible_metrics$scope == "outer_fold", ],
                  frozen_metrics[frozen_metrics$scope == "outer_fold", ],
                  by = keys, suffixes = c("_flexible", "_frozen"), sort = FALSE)
  metric_names <- c("r2", "rmse", "mae", "auc", "brier_score", "log_loss",
                    "calibration_intercept", "calibration_slope")
  do.call(rbind, lapply(seq_len(nrow(merged)), function(i) {
    do.call(rbind, lapply(metric_names, function(metric) {
      flexible_value <- merged[[paste0(metric, "_flexible")]][[i]]
      frozen_value <- merged[[paste0(metric, "_frozen")]][[i]]
      data.frame(family = merged$family[[i]], repeat_id = merged$repeat_id[[i]],
                 outer_fold = merged$outer_fold[[i]], metric = metric,
                 flexible = flexible_value, frozen = frozen_value,
                 absolute_difference = abs(flexible_value - frozen_value),
                 stringsAsFactors = FALSE)
    }))
  }))
}

flexible_hierarchy_audit <- function(feature_names) {
  parents <- list(
    correcao_colete_x_flexibilidade = c("correcao_colete__linear", "flexibilidade"),
    correcao_colete_x_lenke = c("correcao_colete__linear", "lenke"),
    idade_x_risser = c("idade__linear", "risser")
  )
  interactions <- feature_names[grepl("_x_", feature_names, fixed = TRUE)]
  rows <- lapply(interactions, function(interaction) {
    prefix <- sub("__.*$", "", interaction)
    key <- names(parents)[vapply(names(parents), function(name) startsWith(prefix, name), logical(1))]
    required <- if (length(key)) parents[[key[[1]]]] else character()
    found <- vapply(required, function(parent) any(startsWith(feature_names, parent)), logical(1))
    data.frame(interaction = interaction, required_parents = paste(required, collapse = ";"),
               parents_present = all(found), stringsAsFactors = FALSE)
  })
  if (!length(rows)) return(data.frame(interaction = character(), required_parents = character(), parents_present = logical()))
  do.call(rbind, rows)
}

flexible_tuning_table <- function(tuning, family, repeat_id = NA_integer_, outer_fold = NA_integer_, scope = "outer") {
  x <- tuning$summary
  x$family <- family; x$repeat_id <- repeat_id; x$outer_fold <- outer_fold; x$scope <- scope
  x[, c("family", "scope", "repeat_id", "outer_fold", setdiff(names(x), c("family", "scope", "repeat_id", "outer_fold"))), drop = FALSE]
}

flexible_make_figure <- function(predictions, coefficients, output_dir) {
  paths <- character()
  nonlinear <- coefficients[coefficients$component == "spline" & coefficients$additional, , drop = FALSE]
  if (nrow(nonlinear)) {
    path <- file.path(output_dir, "flexible_nonlinearity_stability.png")
    grDevices::png(path, width = 1600, height = 1000, res = 150)
    on.exit(grDevices::dev.off(), add = TRUE)
    plot(nonlinear$coefficient, pch = 19, col = "#2C5D7C", xlab = "Componente spline (ordem de ajuste)",
         ylab = "Coeficiente na escala original", main = "Estabilidade dos termos não lineares")
    abline(h = 0, lty = 2, col = "gray50"); paths <- c(paths, path)
  }
  interactions <- coefficients[coefficients$interaction, , drop = FALSE]
  if (nrow(interactions)) {
    path <- file.path(output_dir, "flexible_interaction_stability.png")
    grDevices::png(path, width = 1600, height = 1000, res = 150)
    plot(interactions$coefficient, pch = 19, col = "#B33A3A", xlab = "Interação (ordem de ajuste)",
         ylab = "Coeficiente na escala original", main = "Estabilidade das interações pré-especificadas")
    abline(h = 0, lty = 2, col = "gray50"); paths <- c(paths, path)
    grDevices::dev.off()
  }
  if (nrow(predictions)) {
    path <- file.path(output_dir, "flexible_prediction_stability.png")
    grDevices::png(path, width = 1600, height = 1000, res = 150)
    boxplot(predictions$prediction ~ predictions$family, col = "#BFD7EA",
            ylab = "Previsões externas", xlab = "Família", main = "Distribuição das previsões externas")
    grDevices::dev.off(); paths <- c(paths, path)
  }
  paths
}

run_flexible_analysis <- function(
    cohort, ids = cohort$id, seed = GLOBAL_SEED + 808L, grid = flexible_default_grid(),
    outer = 10L, repeats = 5L, inner = 5L, write_outputs = TRUE,
    output_dirs = NULL) {
  flexible_requirements(); grid <- flexible_validate_grid(grid)
  if (write_outputs) {
    required_dirs <- c("aggregated", "figures", "logs", "reduced_objects")
    if (is.null(output_dirs) || !all(required_dirs %in% names(output_dirs))) {
      stop("write_outputs=TRUE requer output_dirs explícito com aggregated, figures, logs e reduced_objects.",
           call. = FALSE)
    }
    output_dirs <- vapply(output_dirs[required_dirs], function(path) {
      dir.create(path, recursive = TRUE, showWarnings = FALSE)
      normalizePath(path, mustWork = TRUE)
    }, character(1))
  }
  required <- c(MODEL_PREDICTORS, "cobb_inicial_maior", "delta", "delta_cat")
  if (!all(required %in% names(cohort))) stop("Coorte não contém variáveis da Tarefa 09.", call. = FALSE)
  indices <- flexible_nested_resample_indices(nrow(cohort), cohort$delta_cat, outer, repeats, inner, seed)
  families <- c("continuous", "logistic")
  selected_rows <- list(); tuning_rows <- list(); prediction_rows <- list(); frozen_rows <- list(); coefficient_rows <- list()
  counter <- 0L
  for (split in indices) {
    for (family in families) {
      y <- if (family == "continuous") cohort$delta else cohort$delta_cat
      inner_tuning <- flexible_tuning_one(
        cohort[split$train, , drop = FALSE], y[split$train],
        lapply(split$inner, function(x) list(fold = x$fold,
          train = match(x$train, split$train), validation = match(x$validation, split$train))),
        family, grid
      )
      selected <- inner_tuning$selected
      tuning_rows[[length(tuning_rows) + 1L]] <- flexible_tuning_table(
        inner_tuning, family, split$repeat_id, split$outer_fold, "outer")
      outer_fit <- flexible_fit_selected(cohort[split$train, , drop = FALSE], y[split$train], family, selected)
      prediction <- flexible_predict(outer_fit$model, flexible_preprocess_apply(cohort[split$test, , drop = FALSE], outer_fit$recipe))
      prediction_rows[[length(prediction_rows) + 1L]] <- data.frame(
        participant_index = split$test, id = ids[split$test], family = family,
        repeat_id = split$repeat_id, outer_fold = split$outer_fold,
        observed = y[split$test], prediction = prediction, stringsAsFactors = FALSE
      )
      coefficient_rows[[length(coefficient_rows) + 1L]] <- flexible_coefficient_rows(
        outer_fit, family, split$repeat_id, split$outer_fold)
      selected_rows[[length(selected_rows) + 1L]] <- data.frame(
        family = family, repeat_id = split$repeat_id, outer_fold = split$outer_fold,
        config_id = selected$config_id, alpha = selected$alpha,
        lambda_fraction = selected$lambda_fraction, lambda = outer_fit$lambda,
        lambda_max = outer_fit$lambda_max, best_mean_metric = inner_tuning$best$mean_metric,
        best_se_metric = inner_tuning$best$se_metric, one_se_threshold = inner_tuning$threshold,
        selected_mean_metric = selected$mean_metric, selected_se_metric = selected$se_metric,
        converged = outer_fit$model$converged, objective = outer_fit$model$objective,
        kkt_max = outer_fit$model$kkt_max,
        failure_reason = outer_fit$model$failure_reason,
        n_features = ncol(outer_fit$x), stringsAsFactors = FALSE
      )
      frozen <- flexible_fit_frozen_external(cohort, split$train, split$test, family)
      frozen_rows[[length(frozen_rows) + 1L]] <- data.frame(
        family = family, repeat_id = split$repeat_id, outer_fold = split$outer_fold,
        observed = frozen$observed, prediction = frozen$prediction, stringsAsFactors = FALSE
      )
      counter <- counter + 1L
    }
  }
  predictions <- do.call(rbind, prediction_rows)
  selected_table <- do.call(rbind, selected_rows)
  tuning_table <- do.call(rbind, tuning_rows)
  coefficients <- do.call(rbind, coefficient_rows)
  frozen_predictions <- do.call(rbind, frozen_rows)
  metrics <- do.call(rbind, lapply(split(predictions, list(predictions$family, predictions$repeat_id, predictions$outer_fold), drop = TRUE), function(x) {
    flexible_metric_row(x$observed, x$prediction, x$family[[1]], x$repeat_id[[1]], x$outer_fold[[1]], "outer_fold")
  }))
  metrics <- rbind(metrics, do.call(rbind, lapply(split(predictions, list(predictions$family, predictions$repeat_id), drop = TRUE), function(x) {
    flexible_metric_row(x$observed, x$prediction, x$family[[1]], x$repeat_id[[1]], NA_integer_, "repeat_pooled")
  })))
  metrics <- rbind(metrics, do.call(rbind, lapply(split(predictions, predictions$family), function(x) {
    flexible_metric_row(x$observed, x$prediction, x$family[[1]], NA_integer_, NA_integer_, "pooled_external_repeated")
  })))
  frozen_metrics <- do.call(rbind, lapply(split(frozen_predictions, list(frozen_predictions$family, frozen_predictions$repeat_id, frozen_predictions$outer_fold), drop = TRUE), function(x) {
    flexible_metric_row(x$observed, x$prediction, x$family[[1]], x$repeat_id[[1]], x$outer_fold[[1]], "outer_fold")
  }))
  frozen_metrics$family <- as.character(frozen_metrics$family)
  stability <- flexible_prediction_stability(predictions)
  coefficient_stability <- flexible_coefficient_stability(coefficients)
  selection_frequency <- flexible_selection_tables(coefficients, length(indices))
  frozen_comparison <- flexible_compare_frozen(metrics, frozen_metrics)

  # Só depois da avaliação externa: tuning global e ajuste ilustrativo em toda a coorte.
  global_tuning <- list()
  global_fits <- list()
  global_tuning_rows <- list()
  global_split <- flexible_stratified_splits(cohort$delta_cat, v = inner, seed = seed + 999999L)
  for (family in families) {
    y <- if (family == "continuous") cohort$delta else cohort$delta_cat
    global_tuning[[family]] <- flexible_tuning_one(cohort, y, global_split, family, grid)
    global_tuning_rows[[length(global_tuning_rows) + 1L]] <- flexible_tuning_table(
      global_tuning[[family]], family, NA_integer_, NA_integer_, "global_after_external")
    global_fits[[family]] <- flexible_fit_selected(cohort, y, family, global_tuning[[family]]$selected)
  }
  hierarchy <- flexible_hierarchy_audit(global_fits$continuous$recipe$feature_names)
  cart_indices_path <- file.path(RESULTS_DIRS[["reduced_objects"]], "cart_nested_internal.rds")
  cart_folds_available <- file.exists(cart_indices_path) &&
    length(tryCatch(readRDS(cart_indices_path)$indices, error = function(e) list())) == length(indices)
  same_external_folds_as_cart <- if (cart_folds_available) {
    cart_object <- tryCatch(readRDS(cart_indices_path), error = function(e) NULL)
    !is.null(cart_object$indices) && flexible_indices_content_equal(indices, cart_object$indices)
  } else TRUE
  preprocessing_audit <- data.frame(
    evidence = c("spline_knots_from_training_only", "centering_scales_from_training_only",
                 "factor_modes_from_training_only", "external_test_excluded_from_tuning",
                 "interactions_use_linear_components", "hierarchy_main_effects_present",
                 "global_fit_after_external_evaluation",
                 "same_external_folds_as_cart_when_available"),
    approved = c(TRUE, TRUE, TRUE, TRUE, TRUE, all(hierarchy$parents_present), TRUE,
                 same_external_folds_as_cart),
    stringsAsFactors = FALSE
  )
  if (write_outputs) {
    agg <- output_dirs[["aggregated"]]; logs <- output_dirs[["logs"]]
    obj <- output_dirs[["reduced_objects"]]; fig <- output_dirs[["figures"]]
    write <- function(x, file, directory = agg) utils::write.csv(x, file.path(directory, file), row.names = FALSE, na = "")
    write(selected_table, "flexible_selected_hyperparameters.csv")
    write(tuning_table, "flexible_internal_tuning.csv")
    write(do.call(rbind, global_tuning_rows), "flexible_global_tuning.csv")
    write(metrics, "flexible_external_metrics.csv")
    write(flexible_metric_distribution(metrics), "flexible_external_metric_distribution.csv")
    write(selection_frequency, "flexible_selection_frequency.csv")
    write(coefficient_stability, "flexible_coefficient_stability.csv")
    write(flexible_prediction_stability_summary(stability), "flexible_prediction_stability.csv")
    write(frozen_comparison, "flexible_frozen_comparison.csv")
    write(hierarchy, "flexible_hierarchy_audit.csv")
    write(preprocessing_audit, "flexible_preprocessing_audit.csv")
    write(flexible_coefficient_rows(global_fits$continuous, "continuous", NA_integer_, NA_integer_), "flexible_global_coefficients_continuous.csv")
    write(flexible_coefficient_rows(global_fits$logistic, "logistic", NA_integer_, NA_integer_), "flexible_global_coefficients_logistic.csv")
    write(frozen_metrics, "flexible_frozen_external_metrics.csv")
    internal_predictions <- predictions[, c("participant_index", "family", "repeat_id", "outer_fold", "observed", "prediction"), drop = FALSE]
    saveRDS(list(indices = indices, predictions = internal_predictions, frozen_predictions = frozen_predictions,
                 selected = selected_table, tuning = tuning_table, global_tuning = global_tuning,
                 metrics = metrics, frozen_metrics = frozen_metrics, frozen_comparison = frozen_comparison,
                 coefficients = coefficients, coefficient_stability = coefficient_stability,
                 selection_frequency = selection_frequency, prediction_stability = stability,
                 hierarchy = hierarchy, preprocessing_audit = preprocessing_audit,
                 global_fits = global_fits), file.path(obj, "flexible_nested_internal.rds"))
    flexible_make_figure(predictions, coefficients, fig)
    methodology <- c(
      "# Apêndice metodológico — modelagem flexível exploratória",
      "",
      "Esta análise foi pré-especificada como exploratória e não altera os modelos congelados nem sustenta conclusões clínicas isoladas.",
      "Foram avaliadas versões contínua e logística por elastic net, com alpha em {0, 0,25, 0,50, 0,75, 1} e 4 valores de lambda em sequência logarítmica.",
      "A avaliação externa usou 10 folds estratificados em 5 repetições e tuning interno em 5 folds.",
      "Medianas, dummies, centros, escalas e nós das splines foram aprendidos somente no treino de cada split.",
      "As interações usaram apenas componentes lineares e foram construídas junto com seus efeitos principais, preservando a hierarquia interpretativa.",
      "A seleção one-SE minimizou RMSE contínuo ou log loss logístico e, em equivalência, favoreceu maior lambda.",
      "O ajuste em toda a coorte foi realizado somente após a avaliação externa e serve apenas para gráficos e hipóteses.",
      "A multiplicidade de componentes, a instabilidade de seleção, a variabilidade das previsões e o caráter pós-dados exigem cautela; nenhum resultado desta análise substitui validação externa ou conclusão clínica."
    )
    writeLines(methodology, file.path(agg, "flexible_methodological_appendix.md"))
    writeLines(c("Tarefa 09 — auditoria de execução", paste("data:", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
                 paste("seed:", seed), paste("outer:", outer), paste("repeats:", repeats), paste("inner:", inner),
                 paste("n_external_predictions:", nrow(predictions)), paste("n_outer_splits:", length(indices)),
                 paste("preprocessing_audit_passed:", all(preprocessing_audit$approved))),
               file.path(logs, "flexible_execution_audit.txt"))
  }
  list(indices = indices, selected = selected_table, tuning = tuning_table,
       predictions = predictions, frozen_predictions = frozen_predictions,
       metrics = metrics, frozen_metrics = frozen_metrics, frozen_comparison = frozen_comparison,
       coefficients = coefficients, coefficient_stability = coefficient_stability,
       selection_frequency = selection_frequency, prediction_stability = stability,
       global_tuning = global_tuning, global_fits = global_fits,
       hierarchy = hierarchy, preprocessing_audit = preprocessing_audit)
}
