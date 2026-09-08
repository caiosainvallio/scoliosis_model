# Verificação independente da correção do solver flexível (Task 04).
# Executar da raiz: Rscript --vanilla scripts/review_check_flexible_objective.R
# Usa somente dados sintéticos e grava exclusivamente o log da revisão.

source("R/11_flexible_modeling.R")

output_path <- file.path("results", "prognostico", "revisao", "logs",
                         "solver_verificacao.csv")
dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)

ridge_reference <- function(x, y, lambda) {
  objective <- function(b) flexible_objective(b[[1]], b[-1], x, y, "logistic", lambda, 0)
  gradient <- function(b) {
    p <- plogis(b[[1]] + as.numeric(x %*% b[-1]))
    c(mean(p - y), as.numeric(crossprod(x, p - y)) / nrow(x) + lambda * b[-1])
  }
  stats::optim(c(stats::qlogis(mean(y)), numeric(ncol(x))), objective, gr = gradient,
               method = "BFGS", control = list(reltol = 1e-13, maxit = 5000L))
}

verification_row <- function(scenario, seed, family, alpha, lambda, fit,
                             reference = NULL, expected_convergence = TRUE) {
  reference_objective <- if (is.null(reference)) NA_real_ else reference$value
  coefficient_difference <- if (is.null(reference)) NA_real_ else
    max(abs(c(fit$intercept, fit$beta) - reference$par))
  objective_difference <- if (is.null(reference)) NA_real_ else
    abs(fit$objective - reference$value)
  passed <- identical(isTRUE(fit$converged), expected_convergence)
  if (expected_convergence) {
    passed <- passed && is.finite(fit$objective) && fit$kkt_max <= 1e-6 &&
      (is.null(reference) || (reference$convergence == 0L &&
        objective_difference <= 1e-8 && coefficient_difference <= 2e-5))
  } else {
    passed <- passed && !is.na(fit$failure_reason)
  }
  data.frame(
    scenario = scenario, seed = seed, family = family, alpha = alpha,
    lambda = lambda, expected_convergence = expected_convergence,
    converged = fit$converged, objective = fit$objective,
    kkt_max = fit$kkt_max, intercept_gradient = fit$intercept_gradient,
    n_zero = fit$n_zero, zero_kkt_max = fit$zero_kkt_max,
    reference_objective = reference_objective,
    objective_difference = objective_difference,
    coefficient_max_difference = coefficient_difference,
    failure_reason = ifelse(is.na(fit$failure_reason), "", fit$failure_reason),
    passed = passed, stringsAsFactors = FALSE
  )
}

rows <- list()

# Caso original do parecer: ridge, alpha=0, lambda=0,08, semente 71.
set.seed(71)
x <- scale(matrix(rnorm(400), ncol = 2))
y <- rbinom(nrow(x), 1, plogis(-0.5 + 1.5 * x[, 1] - 0.7 * x[, 2]))
colnames(x) <- c("x1", "x2")
fit <- flexible_fit_one(x, y, "logistic", lambda = 0.08, alpha = 0)
reference <- ridge_reference(x, y, 0.08)
rows[[length(rows) + 1L]] <- verification_row(
  "parecer_seed71_ridge", 71L, "logistic", 0, 0.08, fit, reference
)

# Múltiplas sementes, níveis de penalização e preditores correlacionados.
for (seed in c(7L, 71L, 193L)) {
  set.seed(seed)
  n <- 180L
  latent <- rnorm(n)
  x <- scale(cbind(
    x1 = latent + rnorm(n, sd = 0.08), x2 = latent + rnorm(n, sd = 0.08),
    x3 = rnorm(n), x4 = rnorm(n)
  ))
  y <- rbinom(n, 1, plogis(-0.35 + 1.1 * x[, 1] - 0.8 * x[, 2] + 0.45 * x[, 3]))
  for (lambda in c(0.005, 0.08, 0.5)) {
    fit <- flexible_fit_one(x, y, "logistic", lambda = lambda, alpha = 0)
    rows[[length(rows) + 1L]] <- verification_row(
      "correlated_ridge", seed, "logistic", 0, lambda, fit,
      ridge_reference(x, y, lambda)
    )
  }
  for (alpha in c(0.5, 1)) {
    for (lambda in c(0.02, 0.2, 0.8)) {
      fit <- flexible_fit_one(x, y, "logistic", lambda = lambda, alpha = alpha)
      rows[[length(rows) + 1L]] <- verification_row(
        "correlated_elastic_kkt", seed, "logistic", alpha, lambda, fit
      )
    }
  }
}

# Caso gaussiano cobre intercepto não penalizado e o caminho compartilhado.
set.seed(311)
x <- scale(matrix(rnorm(600), ncol = 3)); colnames(x) <- paste0("g", 1:3)
y <- 2.2 + x[, 1] - 0.4 * x[, 2] + rnorm(nrow(x), sd = 0.5)
fit <- flexible_fit_one(x, y, "continuous", lambda = 0.15, alpha = 0.5)
rows[[length(rows) + 1L]] <- verification_row(
  "gaussian_shared_path", 311L, "continuous", 0.5, 0.15, fit
)

# Falha deliberada: não pode produzir previsões aparentemente válidas.
set.seed(991)
x <- scale(matrix(rnorm(300), ncol = 3)); colnames(x) <- paste0("f", 1:3)
y <- rbinom(nrow(x), 1, plogis(2 * x[, 1] - x[, 2]))
fit <- flexible_fit_one(x, y, "logistic", lambda = 1e-5, alpha = 1, maxit = 1L)
failure_predictions <- flexible_predict(fit, x)
failure_row <- verification_row(
  "forced_nonconvergence", 991L, "logistic", 1, 1e-5, fit,
  expected_convergence = FALSE
)
failure_row$passed <- failure_row$passed && all(is.na(failure_predictions))
rows[[length(rows) + 1L]] <- failure_row

verification <- do.call(rbind, rows)
utils::write.csv(verification, output_path, row.names = FALSE, na = "")
print(verification, row.names = FALSE)
if (!all(verification$passed)) stop("Uma ou mais verificações do solver falharam.", call. = FALSE)
cat("Todas as verificações passaram. Log:", output_path, "\n")
