# Testes independentes da Tarefa 05. Execute com Rscript --vanilla tests/run_tests.R.

project_root <- normalizePath(".", mustWork = TRUE)
source(file.path(project_root, "R", "03_metrics_calibration.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "04_bootstrap_stability.R"), local = .GlobalEnv)

expect_error <- function(expr, pattern = NULL) {
  error <- tryCatch({ force(expr); NULL }, error = identity)
  stopifnot(!is.null(error))
  if (!is.null(pattern)) stopifnot(grepl(pattern, conditionMessage(error), ignore.case = TRUE))
  invisible(error)
}

# Métricas contínuas e binárias contra cálculos diretos.
y <- c(1, 2, 3, 4)
p <- c(1, 2, 3, 4)
stopifnot(identical(r_squared(y, p), 1), rmse(y, p) == 0, mae(y, p) == 0,
          mean_error(y, p) == 0)
stopifnot(all.equal(rmse(y, c(0, 2, 4, 6)), sqrt(mean(c(1, 0, 1, 4)))))
yb <- c(0, 1, 0, 1)
pb <- c(0.2, 0.8, 0.4, 0.9)
stopifnot(all.equal(brier_score(yb, pb), mean((yb - pb)^2)))
stopifnot(all.equal(auc_rank(yb, pb), auc_reference(yb, pb)))
stopifnot(all.equal(log_loss(yb, pb), -mean(yb * log(pb) + (1 - yb) * log1p(-pb))))
stopifnot(is.finite(log_loss(c(0, 1), c(0, 1))), log_loss(c(0, 1), c(0, 1)) > 0)

# Previsão perfeita, invertida, constante e com extremos.
stopifnot(auc_rank(c(0, 1), c(0, 1)) == 1,
          auc_rank(c(0, 1), c(1, 0)) == 0,
          auc_rank(c(0, 0, 1, 1), c(0.5, 0.5, 0.5, 0.5)) == 0.5)
stopifnot(is.finite(log_loss(c(0, 1, 1, 0), c(0, 1, 1, 0))))
stopifnot(all(clip_probabilities(c(0, 1)) > 0 & clip_probabilities(c(0, 1)) < 1))

linear_cal <- calibration_linear(c(2, 4, 6, 8), c(1, 2, 3, 4))
stopifnot(all.equal(linear_cal$intercept, 0), all.equal(linear_cal$slope, 2))
logistic_cal <- calibration_logistic(c(0, 1, 0, 1), c(0.2, 0.8, 0.2, 0.8))
stopifnot(is.finite(logistic_cal$intercept), is.finite(logistic_cal$slope))

# Correção: maior é melhor subtrai otimismo; erro menor é melhor soma a diferença.
stopifnot(isTRUE(all.equal(correct_optimism(0.8, 0.1, "benefit"), 0.7)),
          isTRUE(all.equal(correct_optimism(0.2, 0.05, "error"), 0.25)))

# Réplica válida e reprodutibilidade completa.
data <- data.frame(y = c(0, 1, 0, 1, 1, 0, 1, 0), x = c(0, 1, 2, 3, 4, 5, 6, 7))
replica_a <- bootstrap_replica(data, y ~ x, "binomial", seed = 1234)
replica_b <- bootstrap_replica(data, y ~ x, "binomial", seed = 1234)
stopifnot(replica_a$status == "valid", identical(replica_a$index, replica_b$index),
          identical(replica_a$optimism, replica_b$optimism),
          length(replica_a$index) == nrow(data))

replicas_a <- bootstrap_replicates(data, y ~ x, "binomial", times = 6, seed = 77)
replicas_b <- bootstrap_replicates(data, y ~ x, "binomial", times = 6, seed = 77)
stopifnot(identical(lapply(replicas_a, `[[`, "index"), lapply(replicas_b, `[[`, "index")))
stopifnot(identical(vapply(replicas_a, `[[`, character(1), "status"),
                  vapply(replicas_b, `[[`, character(1), "status")))

# Cada classe de falha exigida tem motivo estruturado e não interrompe a suíte.
no_variation <- bootstrap_replica(data.frame(y = rep(0, 8), x = 1:8), y ~ x,
                                  "binomial", seed = 1)
stopifnot(no_variation$status == "failed", no_variation$failure_reason == "outcome_no_variation")
missing_factor <- bootstrap_replica(
  data.frame(y = c(0, 1, 0, 1), x = factor(c("a", "a", "b", "b"))),
  y ~ x, "binomial", seed = 1, index = c(1L, 2L, 1L, 2L)
)
stopifnot(missing_factor$status == "failed", missing_factor$failure_reason == "missing_factor_level")
separated <- bootstrap_replica(
  data.frame(y = c(0, 0, 1, 1), x = c(0, 0, 1, 1)), y ~ x, "binomial",
  seed = 1, index = 1:4
)
stopifnot(separated$status == "failed",
          separated$failure_reason == "separation_or_nonfinite_coefficients")
non_converged <- bootstrap_replica(
  data.frame(y = c(0, 0, 1, 1), x = c(0, 0, 1, 1)), y ~ x, "binomial",
  seed = 1, index = 1:4, fit_control = list(maxit = 1)
)
stopifnot(non_converged$status == "failed", non_converged$failure_reason == "non_convergence")
invalid_predictions <- bootstrap_replica(
  data, y ~ x, "binomial", seed = 1,
  original_data = data.frame(y = data$y, x = c(NA, data$x[-1]))
)
stopifnot(invalid_predictions$status == "failed",
          invalid_predictions$failure_reason == "invalid_predictions")
calibration_failure <- bootstrap_replica(data, y ~ 1, "gaussian", seed = 1)
stopifnot(calibration_failure$status == "failed", calibration_failure$failure_reason == "calibration_failure")

apparent <- c(auc = 0.75, brier_score = 0.2, log_loss = 0.6)
summary <- consolidate_optimism(replicas_a, apparent)
stopifnot(identical(summary$metric, names(apparent)),
          all(summary$direction %in% c("benefit", "error", "target")))
stopifnot(is.data.frame(bootstrap_replica_table(replicas_a)),
          nrow(bootstrap_failure_summary(replicas_a)) == 7L)

cat("Tarefa 05: todos os testes passaram.\n")
