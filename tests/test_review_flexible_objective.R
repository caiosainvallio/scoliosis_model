# Testes numéricos independentes do solver flexível corrigido (Task 04).

source(file.path("R", "11_flexible_modeling.R"))

direct_ridge <- function(x, y, lambda) {
  objective <- function(b) flexible_objective(b[1], b[-1], x, y, "logistic", lambda, 0)
  gradient <- function(b) {
    p <- plogis(b[1] + as.numeric(x %*% b[-1]))
    c(mean(p - y), as.numeric(crossprod(x, p - y)) / nrow(x) + lambda * b[-1])
  }
  optim(c(qlogis(mean(y)), numeric(ncol(x))), objective, gr = gradient,
        method = "BFGS", control = list(reltol = 1e-13, maxit = 5000L))
}

# Reprodução exata do caso que revelou o erro.
set.seed(71)
x <- scale(matrix(rnorm(400), ncol = 2)); colnames(x) <- c("x1", "x2")
y <- rbinom(nrow(x), 1, plogis(-0.5 + 1.5 * x[, 1] - 0.7 * x[, 2]))
fit <- flexible_fit_one(x, y, "logistic", lambda = 0.08, alpha = 0)
reference <- direct_ridge(x, y, 0.08)
stopifnot(
  fit$converged, fit$kkt_max < 1e-6,
  max(abs(c(fit$intercept, fit$beta) - reference$par)) < 1e-5,
  abs(fit$objective - reference$value) < 1e-8,
  max(abs(flexible_predict(fit, x) - plogis(reference$par[1] + x %*% reference$par[-1]))) < 1e-6
)

# Ridge em múltiplas sementes/penalizações e colinearidade forte.
for (seed in c(7L, 71L, 193L)) {
  set.seed(seed)
  n <- 160L; common <- rnorm(n)
  x <- scale(cbind(common + rnorm(n, sd = .05), common + rnorm(n, sd = .05), rnorm(n)))
  colnames(x) <- c("x1", "x2", "x3")
  y <- rbinom(n, 1, plogis(-.2 + .8 * x[, 1] - .5 * x[, 2] + .3 * x[, 3]))
  for (lambda in c(.005, .08, .5)) {
    fit <- flexible_fit_one(x, y, "logistic", lambda = lambda, alpha = 0)
    reference <- direct_ridge(x, y, lambda)
    stopifnot(fit$converged, fit$kkt_max < 1e-6,
              abs(fit$objective - reference$value) < 1e-8,
              max(abs(c(fit$intercept, fit$beta) - reference$par)) < 2e-5)
  }
}

# Elastic net/lasso: KKT inclui explicitamente coeficientes zerados.
set.seed(404)
n <- 220L; latent <- rnorm(n)
x <- scale(cbind(latent, latent + rnorm(n, sd = .1), matrix(rnorm(n * 6), ncol = 6)))
colnames(x) <- paste0("x", seq_len(ncol(x)))
y <- rbinom(n, 1, plogis(-.4 + 1.2 * x[, 1] - .8 * x[, 3]))
for (alpha in c(.5, 1)) {
  for (lambda in c(.02, .2, .8)) {
    fit <- flexible_fit_one(x, y, "logistic", lambda = lambda, alpha = alpha)
    diagnostic <- flexible_kkt(fit$intercept, fit$beta, x, y, "logistic", lambda, alpha)
    stopifnot(fit$converged, diagnostic$maximum < 1e-6,
              abs(diagnostic$intercept_gradient) < 1e-6,
              fit$objective <= flexible_objective(qlogis(mean(y)), numeric(ncol(x)), x, y,
                                                  "logistic", lambda, alpha) + 1e-10)
    if (lambda >= .2) stopifnot(diagnostic$n_zero > 0L, diagnostic$zero_maximum < 1e-6)
  }
}

# Intercepto e transformação de volta à escala bruta.
set.seed(505)
raw_x <- cbind(a = rnorm(180, 10, 2), b = rnorm(180, -3, .5))
means <- colMeans(raw_x); scales <- apply(raw_x, 2, sd)
x <- sweep(sweep(raw_x, 2, means, "-"), 2, scales, "/")
y <- rbinom(nrow(x), 1, plogis(.25 + .9 * x[, 1] - .4 * x[, 2]))
fit <- flexible_fit_one(x, y, "logistic", lambda = .05, alpha = .5,
                        feature_means = means, feature_scales = scales)
eta_scaled <- fit$intercept + as.numeric(x %*% fit$beta)
eta_raw <- fit$intercept_raw + as.numeric(raw_x %*% fit$beta_raw)
stopifnot(fit$converged, max(abs(eta_scaled - eta_raw)) < 1e-10,
          max(abs(plogis(eta_raw) - flexible_predict(fit, x))) < 1e-10)

# Caminho gaussiano compartilhado também satisfaz gradiente/KKT.
set.seed(606)
x <- scale(matrix(rnorm(600), ncol = 3)); colnames(x) <- paste0("g", 1:3)
y <- 1.7 + x[, 1] - .5 * x[, 2] + rnorm(nrow(x), sd = .4)
fit <- flexible_fit_one(x, y, "continuous", lambda = .1, alpha = .5)
stopifnot(fit$converged, fit$kkt_max < 1e-6, abs(fit$intercept_gradient) < 1e-8,
          all(is.finite(flexible_predict(fit, x))))

# Não convergência é explícita e bloqueia previsões/métricas válidas.
set.seed(707)
x <- scale(matrix(rnorm(300), ncol = 3)); colnames(x) <- paste0("f", 1:3)
y <- rbinom(nrow(x), 1, plogis(2 * x[, 1] - x[, 2]))
failed <- flexible_fit_one(x, y, "logistic", lambda = 1e-5, alpha = 1, maxit = 1L)
failed_prediction <- flexible_predict(failed, x)
failed_metric <- flexible_metric_row(y, failed_prediction, "logistic")
stopifnot(!failed$converged, !is.na(failed$failure_reason), all(is.na(failed_prediction)),
          is.na(failed_metric$auc), is.na(failed_metric$brier_score), is.na(failed_metric$log_loss))

cat("Task 04: objetivo, gradiente/KKT, intercepto, previsões e falhas verificados.\n")
