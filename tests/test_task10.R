# Testes independentes da Tarefa 10.

project_root <- normalizePath(".", mustWork = TRUE)
source(file.path(project_root, "R", "00_config.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "02_import_prepare.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "03_metrics_calibration.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "07_frozen_models.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "12_sensitivity_analysis.R"), local = .GlobalEnv)

criteria <- sensitivity_influence_criteria(615L, 20L)
stopifnot(
  nrow(criteria) == 3L,
  criteria$threshold[criteria$criterion == "distancia_de_cook"] == 4 / 615,
  criteria$threshold[criteria$criterion == "leverage"] == 2 * 20 / 615,
  criteria$threshold[criteria$criterion == "residuo_padronizado"] == 2
)

raw <- import_prognostic_data()
cohort <- prepare_prognostic_data(raw)
main <- run_frozen_models(cohort)
result <- run_sensitivity_analysis(cohort, main, write_outputs = FALSE)

stopifnot(
  result$n_primary == 615L,
  nrow(cohort) == 615L,
  all(c(81L, 174L, 401L) %in% cohort$id),
  all(cohort$correcao_colete[match(c(81L, 174L, 401L), cohort$id)] > 100),
  all(result$metrics$n[result$metrics$scope == "coorte_completa_615"] == 615L),
  all(result$exclusions$n_excluded[result$exclusions$scenario == "hypercorrection"] == 3L),
  nrow(result$coefficients) > 0L,
  nrow(result$prediction_summary) == 8L,
  all(result$strata$n > 0L),
  all(result$cobb_target$metrics$model %in% c("delta", "cobb_6_meses_condicionado")),
  nrow(result$cobb_target$coefficients) == length(stats::coef(result$cobb_target$fit))
)

cat("Tarefa 10: todos os testes passaram.\n")
