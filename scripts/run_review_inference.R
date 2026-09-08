#!/usr/bin/env Rscript

# Tarefa de revisão 08: diagnósticos e inferência robusta. Todas as novas
# saídas são gravadas explicitamente em results/prognostico/revisao/.

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg)) sub("^--file=", "", file_arg[[1]]) else "scripts/run_review_inference.R"
project_root <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)

source(file.path(project_root, "R", "00_config.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "01_dependencies.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "02_import_prepare.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "07_frozen_models.R"), local = .GlobalEnv)

required <- c("readxl", "car", "lmtest", "sandwich", "quadprog")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) stop("Dependencias ausentes: ", paste(missing, collapse = ", "))

raw <- import_prognostic_data()
cohort <- prepare_prognostic_data(raw)
review <- run_review_inference(cohort)
revision_root <- file.path(project_root, "results", "prognostico", "revisao")
write_review_inference_outputs(review, cohort, revision_root)

output_files <- c(
  list.files(file.path(revision_root, "aggregated"),
             pattern = "^(coefficients_linear_|diagnostics_).*[.]csv$", full.names = TRUE),
  file.path(revision_root, "logs", "diagnostics_influence_task10_internal.csv"),
  file.path(revision_root, "reduced_objects", "diagnostics_plot_data.rds")
)
output_manifest <- data.frame(
  artifact = sub(paste0("^", project_root, "/"), "", output_files),
  class = ifelse(grepl("/logs/", output_files), "log_interno",
                 ifelse(grepl("/reduced_objects/", output_files), "objeto_reduzido_interno", "resultado_agregado")),
  source = "coorte_congelada_615_e_modelos_principais_preservados",
  script = "scripts/run_review_inference.R",
  task = "08",
  sha256 = vapply(output_files, file_sha256, character(1)),
  consumption = ifelse(grepl("influence_task10", output_files), "task_10_interno",
                       ifelse(grepl("plot_data", output_files), "task_12_interno", "tasks_09_10_12_13_15")),
  stringsAsFactors = FALSE
)
utils::write.csv(output_manifest,
                 file.path(revision_root, "aggregated", "diagnostics_output_manifest.csv"),
                 row.names = FALSE, na = "")

baseline_linear <- utils::read.csv(
  file.path(project_root, "results", "prognostico", "aggregated", "frozen_coefficients_linear.csv"),
  check.names = FALSE
)
matched <- match(review$coefficients_linear_classic$term, baseline_linear$term)
max_point_change <- max(abs(review$coefficients_linear_classic$estimate - baseline_linear$estimate[matched]))
classic_decision <- with(review$coefficients_linear_classic, conf_low <= 0 & conf_high >= 0)
classic_p_decision <- review$coefficients_linear_classic$p_value >= 0.05

stopifnot(
  nrow(cohort) == 615L,
  sum(cohort$delta_cat == 1L) == 317L,
  sum(cohort$delta_cat == 0L) == 298L,
  length(unique(cohort$id)) == 615L,
  qr(review$frozen$design)$rank == ncol(review$frozen$design),
  max_point_change < 1e-12,
  max(abs(review$coefficients_linear_classic$estimate - review$coefficients_linear_hc3$estimate)) < 1e-12,
  all(classic_decision == classic_p_decision),
  review$heteroscedasticity$p_value < 0.05,
  identical(review$separation$formal_status,
            "nenhuma_separacao_completa_ou_quase-completa_detectada"),
  nrow(review$assumptions) == 8L
)

log_path <- file.path(revision_root, "logs", "review_inference.log")
lines <- c(
  "Task 08 — pressupostos, diagnosticos e inferencia robusta",
  paste("data_execucao:", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  paste("fonte_sha256:", file_sha256(DATA_FILE)),
  paste("n_eventos_nao_eventos:", nrow(cohort), sum(cohort$delta_cat == 1L), sum(cohort$delta_cat == 0L)),
  paste("matriz_colunas_posto:", ncol(review$frozen$design), qr(review$frozen$design)$rank),
  paste("max_alteracao_coeficiente_pontual_vs_baseline:", format(max_point_change, scientific = TRUE)),
  paste("bp_estatistica_gl_p_r2aux:", review$heteroscedasticity$statistic,
        review$heteroscedasticity$df, review$heteroscedasticity$p_value,
        review$heteroscedasticity$auxiliary_r_squared),
  paste("hc3_se_ratio_min_max:", min(review$inference_comparison$se_ratio_hc3_to_classic),
        max(review$inference_comparison$se_ratio_hc3_to_classic)),
  paste("gvif_ajustado_min_max:", min(review$collinearity$gvif_adjusted),
        max(review$collinearity$gvif_adjusted)),
  paste("separacao:", review$separation$formal_status),
  paste("influencia_flags_linear_logistica:", paste(review$influence$n_flag_any, collapse = " ")),
  "Convencao: inferencia linear classica e HC3 usam testes/IC t com gl residuais; logit usa Wald normal assintotico.",
  "HC3 nao corrige nao linearidade, calibracao, dependencia nem intervalos de predicao individuais.",
  "Observacoes sinalizadas permanecem na analise principal; IDs constam somente no log interno para a Task 10.",
  "Nenhum teste de normalidade de covariaveis ou autocorrelacao em ordem arbitraria foi executado.",
  paste("R:", R.version.string),
  paste("pacotes:", paste(vapply(required, function(x) paste0(x, " ", packageVersion(x)), character(1)), collapse = "; "))
)
writeLines(lines, log_path)

cat("Task 08 executada e verificada.\n")
cat("Coorte/eventos/nao eventos:", nrow(cohort), sum(cohort$delta_cat == 1L), sum(cohort$delta_cat == 0L), "\n")
cat("Mudanca maxima nos coeficientes pontuais:", format(max_point_change, scientific = TRUE), "\n")
cat("Breusch-Pagan p:", review$heteroscedasticity$p_value, "\n")
cat("Separacao:", review$separation$formal_status, "\n")
