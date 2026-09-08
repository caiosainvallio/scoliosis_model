# Testes independentes da Tarefa 09.

project_root <- normalizePath(".", mustWork = TRUE)
source(file.path(project_root, "R", "00_config.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "02_import_prepare.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "03_metrics_calibration.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "11_flexible_modeling.R"), local = .GlobalEnv)

set.seed(9)
n <- 100L
toy <- data.frame(
  id = seq_len(n), idade = rnorm(n, 13, 1), imc = rnorm(n, 20, 2),
  cifose_toracica = rnorm(n, 30, 5), lordose_lombar = rnorm(n, 40, 5),
  correcao_colete = runif(n, 0, 80), cobb_inicial_maior = rnorm(n, 45, 10),
  sexo = factor(sample(FACTOR_LEVELS$sexo, n, TRUE), levels = FACTOR_LEVELS$sexo),
  lenke = factor(sample(FACTOR_LEVELS$lenke[1:3], n, TRUE), levels = FACTOR_LEVELS$lenke),
  risser = factor(sample(FACTOR_LEVELS$risser[1:3], n, TRUE), levels = FACTOR_LEVELS$risser),
  flexibilidade = factor(sample(FACTOR_LEVELS$flexibilidade, n, TRUE), levels = FACTOR_LEVELS$flexibilidade),
  escoliometro_maior_10_graus = factor(sample(FACTOR_LEVELS$escoliometro_maior_10_graus[1:3], n, TRUE),
                                       levels = FACTOR_LEVELS$escoliometro_maior_10_graus)
)
toy$delta <- 2 * toy$correcao_colete / 20 - toy$idade + rnorm(n)
toy$delta_cat <- as.integer(toy$delta < median(toy$delta))

indices_a <- flexible_nested_resample_indices(n, toy$delta_cat, outer = 5L, repeats = 2L, inner = 3L, seed = 909L)
indices_b <- flexible_nested_resample_indices(n, toy$delta_cat, outer = 5L, repeats = 2L, inner = 3L, seed = 909L)
stopifnot(identical(indices_a, indices_b), length(indices_a) == 10L)
flexible_validate_nested_indices(indices_a, toy$delta_cat, n)

recipe_a <- flexible_preprocess_fit(toy[1:70, , drop = FALSE])
recipe_b <- flexible_preprocess_fit(toy[31:100, , drop = FALSE])
stopifnot(length(recipe_a$splines$idade$knots) >= 1L,
          !identical(recipe_a$numeric_means, recipe_b$numeric_means),
          all(flexible_hierarchy_audit(recipe_a$feature_names)$parents_present))
x_train <- flexible_preprocess_apply(toy[1:70, , drop = FALSE], recipe_a)
x_test <- flexible_preprocess_apply(toy[71:100, , drop = FALSE], recipe_a)
stopifnot(identical(colnames(x_train), colnames(x_test)),
          max(abs(colMeans(x_train))) < 1e-10,
          all(is.finite(x_test)))

grid <- data.frame(
  config_id = 1:6,
  alpha = c(0, .5, 1, 0, .5, 1),
  lambda_fraction = c(1, 1, 1, .01, .01, .01)
)
tuning <- flexible_tuning_one(toy[1:70, , drop = FALSE], toy$delta[1:70],
  lapply(seq_len(3), function(f) list(fold = f, train = setdiff(seq_len(70), ((f - 1) * 23 + 1):min(f * 23, 70)),
                                      validation = ((f - 1) * 23 + 1):min(f * 23, 70))),
  "continuous", grid)
stopifnot(nrow(tuning$summary) == nrow(grid), is.finite(tuning$threshold),
          tuning$selected$mean_metric <= tuning$threshold,
          tuning$selected$lambda_fraction == max(
            tuning$summary$lambda_fraction[tuning$summary$eligible_one_se]
          ))

continuous <- flexible_fit_selected(toy[1:70, , drop = FALSE], toy$delta[1:70],
                                    "continuous", tuning$selected)
log_grid <- data.frame(config_id = 1:4, alpha = c(0, .5, 1, 0.5),
                       lambda_fraction = c(1, 1, .1, .01))
log_tuning <- flexible_tuning_one(toy[1:70, , drop = FALSE], toy$delta_cat[1:70],
  lapply(seq_len(3), function(f) list(fold = f, train = setdiff(seq_len(70), ((f - 1) * 23 + 1):min(f * 23, 70)),
                                      validation = ((f - 1) * 23 + 1):min(f * 23, 70))),
  "logistic", log_grid)
logistic <- flexible_fit_selected(toy[1:70, , drop = FALSE], toy$delta_cat[1:70],
                                 "logistic", log_tuning$selected)
stopifnot(continuous$model$converged, logistic$model$converged,
          all(is.finite(flexible_predict(continuous$model, x_test))),
          all(flexible_predict(logistic$model, x_test) > 0 & flexible_predict(logistic$model, x_test) < 1))

small_result <- run_flexible_analysis(toy, ids = toy$id, seed = 910L, grid = grid,
                                      outer = 5L, repeats = 1L, inner = 3L, write_outputs = FALSE)
stopifnot(nrow(small_result$predictions) == 2L * n,
          nrow(small_result$selected) == 2L * 5L,
          all(small_result$preprocessing_audit$approved),
          all(small_result$hierarchy$parents_present),
          all(small_result$metrics$scope %in% c("outer_fold", "repeat_pooled", "pooled_external_repeated")),
          all(is.finite(small_result$metrics$rmse[small_result$metrics$family == "continuous"])),
          all(is.finite(small_result$metrics$log_loss[small_result$metrics$family == "logistic"])))

cat("Tarefa 09: todos os testes passaram.\n")
