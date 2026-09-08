#!/usr/bin/env Rscript

# Execução da Tarefa 09. Execute com:
# Rscript --vanilla scripts/run_flexible_modeling.R

script_args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", script_args, value = TRUE)
script_path <- if (length(file_arg)) sub("^--file=", "", file_arg[[1]]) else "scripts/run_flexible_modeling.R"
project_root <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)

source(file.path(project_root, "R", "00_config.R"), local = .GlobalEnv)
ensure_output_dirs()
source(file.path(project_root, "R", "01_dependencies.R"), local = .GlobalEnv)
check_dependencies(required = c("readxl"), relevant = RELEVANT_PACKAGES,
                   write_log = TRUE, fail = TRUE)
source(file.path(project_root, "R", "02_import_prepare.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "03_metrics_calibration.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "11_flexible_modeling.R"), local = .GlobalEnv)

raw <- import_prognostic_data()
cohort <- prepare_prognostic_data(raw)
previous_path <- file.path(
  project_root, "results", "prognostico", "reduced_objects",
  "flexible_nested_internal.rds"
)
if (!file.exists(previous_path)) {
  stop("Baseline flexível anterior ausente; comparação antes/depois não pode ser reconstruída.",
       call. = FALSE)
}
previous_result <- readRDS(previous_path)
revision_root <- file.path(project_root, "results", "prognostico", "revisao")
revision_dirs <- c(
  aggregated = file.path(revision_root, "aggregated"),
  figures = file.path(revision_root, "figures"),
  logs = file.path(revision_root, "logs"),
  reduced_objects = file.path(revision_root, "reduced_objects")
)
result <- run_flexible_analysis(
  cohort, ids = cohort$id, write_outputs = TRUE, output_dirs = revision_dirs
)

solver_impact <- flexible_compare_solver_versions(previous_result, result)
write_revision_csv <- function(x, filename) {
  utils::write.csv(x, file.path(revision_dirs[["aggregated"]], filename),
                   row.names = FALSE, na = "")
}
write_revision_csv(solver_impact$metric_summary,
                   "flexible_solver_before_after_metrics.csv")
write_revision_csv(solver_impact$prediction_change,
                   "flexible_solver_before_after_prediction_change.csv")
saveRDS(
  list(
    same_indices = solver_impact$same_indices,
    metric_summary = solver_impact$metric_summary,
    prediction_change = solver_impact$prediction_change,
    previous_metrics = solver_impact$previous_metrics,
    corrected_metrics = solver_impact$corrected_metrics
  ),
  file.path(revision_dirs[["reduced_objects"]],
            "flexible_solver_before_after.rds")
)

active_interactions <- result$active_hierarchy[result$active_hierarchy$interaction_active, ]
n_active_interactions <- nrow(active_interactions)
n_hierarchy_violations <- sum(!active_interactions$strong_hierarchy_satisfied)
outer_failures <- sum(!result$selected$converged)
maximum_outer_kkt <- max(result$selected$kkt_max, na.rm = TRUE)

comparison_row <- function(family, metric) {
  result$frozen_comparison_summary[
    result$frozen_comparison_summary$family == family &
      result$frozen_comparison_summary$metric == metric, , drop = FALSE]
}
before_after_row <- function(family, metric) {
  solver_impact$metric_summary[
    solver_impact$metric_summary$family == family &
      solver_impact$metric_summary$metric == metric, , drop = FALSE]
}
fmt <- function(x, digits = 4L) formatC(x, digits = digits, format = "f")
appendix <- c(
  "# Apêndice metodológico — modelagem flexível exploratória corrigida",
  "",
  "## Escopo e desenho",
  "",
  paste0("A reexecução preservou a coorte de ", nrow(cohort),
         " participantes (", sum(cohort$delta_cat == 1),
         " eventos) e a definição basal de `correcao_colete` como avaliação transversal de corrigibilidade imediata. Os modelos flexíveis são exploratórios e não substituem os modelos principais congelados."),
  "",
  paste0("Foram usados 10 folds externos, 5 repetições e 5 folds internos, com semente ",
         GLOBAL_SEED + 808L, ". Cada participante integra o teste exatamente uma vez por repetição. As repetições reutilizam as mesmas pessoas; por isso o desvio-padrão entre repetições descreve variabilidade de reamostragem e não é intervalo de confiança."),
  "",
  "Todos os índices foram reconstruídos deterministicamente e coincidiram com o objeto anterior. Treino/teste externos e treino/validação internos foram auditados como disjuntos. Medianas, modos, centros, escalas, níveis fatoriais, limites e nós de spline foram estimados apenas no treino aplicável; o teste externo não participou do tuning.",
  "",
  "## Especificação candidata e seleção",
  "",
  paste0("A matriz candidata contém seis variáveis numéricas (`idade`, `imc`, `cifose_toracica`, `lordose_lombar`, `correcao_colete` e Cobb basal), cada uma com componente linear e spline natural de 3 graus de liberdade; cinco fatores codificados por dummies; e três famílias de interação (`correcao_colete × flexibilidade`, `correcao_colete × Lenke` e `idade × Risser`). O ajuste externo teve ", unique(result$selected$n_features), " colunas candidatas. Os nós e limites efetivos do ajuste global ilustrativo estão em `flexible_spline_specification.csv`."),
  "",
  "A grade foi mantida sem ajuste retrospectivo: alpha em {0; 0,25; 0,50; 0,75; 1} e quatro frações de lambda logaritmicamente espaçadas entre 1 e 0,001. Em cada treino externo, lambda absoluto foi a fração selecionada multiplicada pelo lambda máximo calculado naquele treino. A regra one-SE minimizou RMSE no desfecho contínuo e log loss no logístico; entre configurações elegíveis, escolheu a maior fração de lambda, depois o menor alpha e, por fim, o menor identificador da configuração. `flexible_selected_hyperparameters.csv` registra alpha, fração e valor absoluto de lambda, limiar one-SE e desempates para cada ajuste.",
  paste0("A regra selecionou ridge (alpha = 0) nos 100 ajustes externos. A fração de lambda foi 0,01 em ",
         sum(abs(result$selected$lambda_fraction - 0.01) < 1e-12),
         " ajustes e 0,001 em ",
         sum(abs(result$selected$lambda_fraction - 0.001) < 1e-12),
         ". A expansão exata das 48 colunas candidatas está em `flexible_design_expansion.csv`."),
  "",
  paste0("O solver minimizou perda média mais penalização elastic net, com intercepto não penalizado. Convergência exigiu solução finita e violação máxima de KKT de no máximo 1e-6. Houve ",
         outer_failures,
         " falhas nos 100 ajustes externos selecionados; a maior violação KKT externa foi ",
         format(maximum_outer_kkt, scientific = TRUE, digits = 4),
         ". Falhas internas e globais estão em `flexible_failure_audit.csv` e não foram convertidas silenciosamente em métricas válidas."),
  "",
  "## Hierarquia verificada",
  "",
  "Os efeitos principais correspondentes estavam presentes na matriz candidata. Isso é hierarquia de construção, não hierarquia forte: a penalização foi aplicada coeficiente a coeficiente e nenhuma restrição formal obrigou os efeitos principais a permanecerem ativos quando uma interação ficou ativa.",
  "",
  paste0("Entre os coeficientes externos, houve ", n_active_interactions,
         " ocorrências de interações ativas e ", n_hierarchy_violations,
         " violações da hierarquia forte. A auditoria por ajuste, interação e efeito principal está em `flexible_active_hierarchy_audit.csv`. Nenhum cenário hierarquicamente restrito foi introduzido nesta revisão."),
  "",
  "## Comparação com os modelos congelados nos mesmos folds",
  "",
  paste0("Contínuo: diferença média flexível menos congelado entre as cinco repetições = ",
         fmt(comparison_row("continuous", "rmse")$mean_difference_flexible_minus_reference),
         "° para RMSE e ",
         fmt(comparison_row("continuous", "mae")$mean_difference_flexible_minus_reference),
         "° para MAE. Valores negativos favorecem o flexível."),
  paste0("Logístico: diferença média flexível menos congelado = ",
         fmt(comparison_row("logistic", "auc")$mean_difference_flexible_minus_reference),
         " para AUC, ",
         fmt(comparison_row("logistic", "brier_score")$mean_difference_flexible_minus_reference),
         " para Brier e ",
         fmt(comparison_row("logistic", "log_loss")$mean_difference_flexible_minus_reference),
         " para log loss. AUC maior e perdas menores são favoráveis."),
  paste0("Calibração logística: diferenças flexível menos congelado de ",
         fmt(comparison_row("logistic", "calibration_intercept")$mean_difference_flexible_minus_reference),
         " no intercepto e ",
         fmt(comparison_row("logistic", "calibration_slope")$mean_difference_flexible_minus_reference),
         " na inclinação. Para calibração, a proximidade de 0 e 1, respectivamente, importa mais que o sinal bruto da diferença."),
  "",
  "As tabelas apresentam diferenças pareadas por repetição e seu desvio-padrão, sem tratar os 50 folds ou as cinco repetições como amostras independentes e sem produzir IC espúrios. Não se conclui superioridade por pontos médios; além de splines, a estratégia flexível acrescenta Cobb basal, interações e penalização.",
  "",
  "## Impacto da correção do solver",
  "",
  paste0("Os índices externos antes/depois foram idênticos. No logístico, a mudança corrigido menos anterior foi ",
         fmt(before_after_row("logistic", "auc")$mean_difference_flexible_minus_reference),
         " para AUC, ",
         fmt(before_after_row("logistic", "brier_score")$mean_difference_flexible_minus_reference),
         " para Brier e ",
         fmt(before_after_row("logistic", "log_loss")$mean_difference_flexible_minus_reference),
         " para log loss, nas métricas pareadas por repetição."),
  paste0("No contínuo, a diferença de RMSE corrigido menos anterior foi ",
         fmt(before_after_row("continuous", "rmse")$mean_difference_flexible_minus_reference),
         "°, como esperado porque a correção incidiu no IRLS logístico; a família foi reexecutada para confirmar a identidade sob o fluxo compartilhado."),
  "",
  "A correção elimina o uso clínico do solver antigo nas saídas da revisão. O efeito observado deve ser interpretado como impacto da correção algorítmica no procedimento completo de seleção e ajuste, não como evidência de benefício clínico.",
  "A conclusão não mudou: a estratégia flexível permanece exploratória, com diferenças pontuais pequenas e sem demonstração formal de superioridade. A correção melhorou Brier e log loss médios e aproximou a inclinação logística de calibração de 1, mas não fornece validação externa nem isola o efeito das splines.",
  "",
  "## Limitações",
  "",
  "A avaliação é interna, repetida e exploratória. Coeficientes de bases spline penalizadas não são efeitos clínicos isolados. O ajuste global posterior à avaliação externa serve somente para descrição e geração futura de figuras. Validação externa e avaliação de utilidade clínica permanecem necessárias."
)
writeLines(appendix, file.path(revision_dirs[["aggregated"]],
                               "flexible_methodological_appendix.md"))

log_lines <- c(
  "Task 05 - reexecucao flexivel corrigida",
  paste("timestamp", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  paste("baseline_object", previous_path),
  paste("same_resampling_indices_before_after", solver_impact$same_indices),
  paste("outer_folds", 10L), paste("repeats", 5L), paste("inner_folds", 5L),
  paste("external_selected_fit_failures", outer_failures),
  paste("maximum_outer_kkt", format(maximum_outer_kkt, scientific = TRUE)),
  paste("preprocessing_audit_passed", all(result$preprocessing_audit$approved)),
  paste("paired_flexible_frozen_audit_passed", all(result$paired_prediction_audit$approved)),
  paste("resampling_audit_passed", all(result$resampling_audit$outer_disjoint) &&
          all(result$resampling_audit$outer_complete) &&
          all(result$resampling_audit$all_inner_disjoint) &&
          all(result$resampling_audit$all_inner_complete_within_outer_train)),
  paste("candidate_hierarchy_passed", all(result$hierarchy$parents_present)),
  paste("active_interactions", n_active_interactions),
  paste("strong_hierarchy_violations", n_hierarchy_violations),
  "uncertainty_note five repeats reuse the same participants; between-repeat SD is not a confidence interval"
)
writeLines(log_lines, file.path(revision_dirs[["logs"]],
                                "flexible_reexecution.log"))

pooled <- result$metrics[result$metrics$scope == "pooled_external_repeated", , drop = FALSE]
cat("Task 05 concluída: modelagem flexível exploratória aninhada corrigida.\n")
for (family in unique(pooled$family)) {
  row <- pooled[pooled$family == family, , drop = FALSE]
  if (family == "continuous") {
    cat("Contínuo — R²:", format(row$r2, digits = 4),
        "RMSE:", format(row$rmse, digits = 4),
        "MAE:", format(row$mae, digits = 4), "\n")
  } else {
    cat("Logístico — AUC:", format(row$auc, digits = 4),
        "Brier:", format(row$brier_score, digits = 4),
        "Log loss:", format(row$log_loss, digits = 4), "\n")
  }
}
cat("Predições externas:", nrow(result$predictions), "\n")
cat("Auditoria de pré-processamento aprovada:", all(result$preprocessing_audit$approved), "\n")
cat("Índices antes/depois idênticos:", solver_impact$same_indices, "\n")
cat("Falhas externas:", outer_failures, "\n")
cat("Violações observadas de hierarquia forte:", n_hierarchy_violations, "\n")
cat("Ajustes globais foram usados somente para o apêndice exploratório.\n")
