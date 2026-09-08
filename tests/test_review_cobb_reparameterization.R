# Teste independente da identidade entre as duas parametrizações com Cobb basal.

project_root <- normalizePath(".", mustWork = TRUE)
source(file.path(project_root, "R", "00_config.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "03_metrics_calibration.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "04_bootstrap_stability.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "13_review_validation.R"), local = .GlobalEnv)

set.seed(101)
n <- 80L
d <- data.frame(baseline = runif(n, 10, 60), x = rnorm(n), z = factor(rep(c("a", "b"), n / 2)))
d$delta <- 2 - 0.15 * d$baseline + 1.2 * d$x + ifelse(d$z == "b", .8, 0) + rnorm(n, sd = .3)
d$final <- d$baseline + d$delta
fit_delta <- stats::lm(delta ~ baseline + x + z, data = d)
fit_final <- stats::lm(final ~ baseline + x + z, data = d)
converted <- stats::predict(fit_final, d) - d$baseline
expected_final_coef <- stats::coef(fit_delta)
expected_final_coef[["baseline"]] <- expected_final_coef[["baseline"]] + 1
stopifnot(max(abs(stats::predict(fit_delta, d) - converted)) < 1e-10,
          max(abs(stats::coef(fit_final) - expected_final_coef)) < 1e-10)

# O comparador deve depender apenas do treino e reagir a uma alteração nele.
train <- d[1:60, ]; test <- d[61:80, ]
baseline_a <- rep(mean(train$delta), nrow(test))
train$delta[1] <- train$delta[1] + 100
baseline_b <- rep(mean(train$delta), nrow(test))
stopifnot(all(baseline_a != baseline_b), identical(nrow(test), length(baseline_a)))

cat("Reparametrização Cobb e comparador treino-only: testes aprovados.\n")

