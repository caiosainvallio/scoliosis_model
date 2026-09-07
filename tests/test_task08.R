# Testes independentes da Tarefa 08.

project_root <- normalizePath(".", mustWork = TRUE)
source(file.path(project_root, "R", "00_config.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "02_import_prepare.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "03_metrics_calibration.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "10_cart_nested.R"), local = .GlobalEnv)

set.seed(1)
n <- 60L
toy <- data.frame(
  id = seq_len(n), idade = rnorm(n, 13, 1), imc = rnorm(n, 20, 2),
  cifose_toracica = rnorm(n, 30, 5), lordose_lombar = rnorm(n, 40, 5),
  correcao_colete = runif(n, 0, 80), sexo = factor(rep(c("feminino", "masculino"), length.out = n), levels = FACTOR_LEVELS$sexo),
  lenke = factor(sample(1:2, n, TRUE), levels = FACTOR_LEVELS$lenke),
  risser = factor(sample(0:2, n, TRUE), levels = FACTOR_LEVELS$risser),
  flexibilidade = factor(sample(c("flexivel", "rigido"), n, TRUE), levels = FACTOR_LEVELS$flexibilidade),
  escoliometro_maior_10_graus = factor(sample(c("normal", "toracica"), n, TRUE), levels = FACTOR_LEVELS$escoliometro_maior_10_graus),
  delta_cat = rep(c(0L, 1L), length.out = n)
)

a <- cart_nested_resample_indices(n, toy$delta_cat, outer = 5L, repeats = 2L, inner = 3L, seed = 88L)
b <- cart_nested_resample_indices(n, toy$delta_cat, outer = 5L, repeats = 2L, inner = 3L, seed = 88L)
stopifnot(identical(a, b), inherits(a, "cart_nested_indices"))
tables <- cart_fold_summary_tables(a, toy$delta_cat)
stopifnot(nrow(tables$external) == 5L * 2L,
          all(tables$external$n_test == 12L),
          nrow(tables$internal) == 3L * 5L * 2L,
          all(tables$internal$n_validation == 16L))

grid <- data.frame(
  config_id = 1:3, cost_complexity = c(.001, .02, .01),
  tree_depth = c(5L, 1L, 2L), min_n = c(10L, 40L, 20L)
)
summary <- grid
summary$mean_auc <- c(.80, .70, .80)
summary$sd_auc <- c(.10, .01, .10)
summary$se_auc <- c(.05, .005, .05)
summary$n_valid <- 3L
summary$mean_terminal_nodes <- c(8, 1, 3)
summary$simplicity_order <- c(3L, 1L, 2L)
best_mean <- max(summary$mean_auc)
eligible <- summary$mean_auc >= best_mean - .05
stopifnot(all(eligible == c(TRUE, FALSE, TRUE)))
selection_check <- cart_select_one_se(summary)
stopifnot(selection_check$selected$config_id == 3L,
          selection_check$threshold == .75)

toy_result <- run_cart_nested_analysis(toy, ids = toy$id, seed = 99L,
                                        grid = grid, outer = 5L, repeats = 1L, inner = 3L,
                                        write_outputs = FALSE)
stopifnot(nrow(toy_result$predictions) == n,
          all(!duplicated(toy_result$predictions[c("id", "repeat_id", "outer_fold")])),
          all(toy_result$metrics$scope %in% c("outer_fold", "repeat_pooled", "pooled_external_repeated")),
          all(toy_result$audit$aprovado),
          nrow(toy_result$tree_summaries) == 5L)

cat("Tarefa 08: todos os testes passaram.\n")
