#!/usr/bin/env Rscript

# Tarefa 04 — avaliação formal do tamanho amostral.
# Execute com: Rscript --vanilla scripts/run_sample_size_assessment.R
#
# Este script recalcula a coorte e os modelos congelados diretamente dos dados
# atuais. Não lê nem copia números do arquivo histórico de avaliação amostral.

script_args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", script_args, value = TRUE)
script_path <- if (length(file_arg)) sub("^--file=", "", file_arg[[1]]) else {
  "scripts/run_sample_size_assessment.R"
}
project_root <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)

source(file.path(project_root, "R", "00_config.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "01_dependencies.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "02_import_prepare.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "07_frozen_models.R"), local = .GlobalEnv)

# A dependência é mantida fora do relatório e pode ser instalada em r_libs/.
local_r_lib <- file.path(PROJECT_ROOT, "r_libs")
if (dir.exists(local_r_lib)) .libPaths(c(local_r_lib, .libPaths()))
if (!requireNamespace("pmsampsize", quietly = TRUE)) {
  stop(
    "Dependência ausente: pmsampsize. Instale pmsampsize antes de executar este script; ",
    "a análise não instala pacotes automaticamente."
  )
}

ensure_output_dirs()
agg <- RESULTS_DIRS[["aggregated"]]
log_dir <- RESULTS_DIRS[["logs"]]

raw <- import_prognostic_data()
cohort <- prepare_prognostic_data(raw)
results <- run_frozen_models(cohort)

# Asserções de reconciliação com a Tarefa 03.
stopifnot(
  nrow(cohort) == 615L,
  sum(cohort$delta_cat == 1L) == 317L,
  sum(cohort$delta_cat == 0L) == 298L,
  ncol(results$design) - 1L == 19L,
  results$specification$parameters_predictors[results$specification$model == "linear"] == 19L,
  results$specification$parameters_predictors[results$specification$model == "logistic"] == 19L,
  all(results$specification$p_value_selection == FALSE),
  all(results$specification$stepwise == FALSE),
  all(results$specification$splines == FALSE),
  all(results$specification$interactions == FALSE),
  isTRUE(results$input_identity$same_rows_and_columns[[1]])
)

n_available <- nrow(cohort)
p_linear <- results$specification$parameters_predictors[results$specification$model == "linear"]
p_logistic <- results$specification$parameters_predictors[results$specification$model == "logistic"]
n_events <- sum(cohort$delta_cat == 1L)
n_nonevents <- sum(cohort$delta_cat == 0L)
prevalence <- mean(cohort$delta_cat == 1L)
mean_delta <- mean(cohort$delta)
sd_delta <- stats::sd(cohort$delta)
r2_linear_apparent <- results$metrics_linear$r2[[1]]
r2_linear_adjusted <- results$metrics_linear$r2_adjusted[[1]]

logistic_model <- results$models$logistic
null_logistic <- stats::glm(delta_cat ~ 1, data = cohort, family = stats::binomial())
n_logistic <- stats::nobs(logistic_model)
loglik_model <- as.numeric(stats::logLik(logistic_model))
loglik_null <- as.numeric(stats::logLik(null_logistic))
cox_snell_apparent <- 1 - exp((2 / n_logistic) * (loglik_null - loglik_model))
cox_snell_maximum <- 1 - exp((2 / n_logistic) * loglik_null)
nagelkerke_apparent <- cox_snell_apparent / cox_snell_maximum
auc_apparent <- results$metrics_logistic$auc[[1]]

# Reconciliação explícita com os artefatos agregados da Tarefa 03.
t3_cohort <- utils::read.csv(file.path(RESULTS_DIRS[["aggregated"]], "cohort_summary.csv"),
                             check.names = FALSE)
t3_linear <- utils::read.csv(file.path(RESULTS_DIRS[["aggregated"]], "frozen_metrics_linear_apparent.csv"),
                             check.names = FALSE)
t3_logistic <- utils::read.csv(file.path(RESULTS_DIRS[["aggregated"]], "frozen_metrics_logistic_apparent.csv"),
                                check.names = FALSE)
t3_spec <- utils::read.csv(file.path(RESULTS_DIRS[["aggregated"]], "frozen_specification_audit.csv"),
                            check.names = FALSE)
reconciliation <- data.frame(
  item = c(
    "cohort_summary.n_final", "cohort_summary.eventos_melhora", "cohort_summary.nao_eventos",
    "frozen_metrics_linear.n", "frozen_metrics_linear.r2_adjusted",
    "frozen_metrics_logistic.n", "frozen_metrics_logistic.events",
    "frozen_metrics_logistic.nonevents", "frozen_metrics_logistic.prevalence",
    "frozen_specification_audit.parameters_predictors.linear",
    "frozen_specification_audit.parameters_predictors.logistic"
  ),
  tarefa03 = c(
    t3_cohort$n_final[[1]], t3_cohort$eventos_melhora[[1]], t3_cohort$nao_eventos[[1]],
    t3_linear$n[[1]], t3_linear$r2_adjusted[[1]], t3_logistic$n[[1]], t3_logistic$events[[1]],
    t3_logistic$nonevents[[1]], t3_logistic$prevalence[[1]],
    t3_spec$parameters_predictors[t3_spec$model == "linear"],
    t3_spec$parameters_predictors[t3_spec$model == "logistic"]
  ),
  recalculado_tarefa04 = c(
    n_available, n_events, n_nonevents, nobs(results$models$linear), r2_linear_adjusted,
    nobs(results$models$logistic), n_events, n_nonevents, prevalence, p_linear, p_logistic
  ),
  stringsAsFactors = FALSE
)
reconciliation$diferenca_absoluta <- abs(reconciliation$tarefa03 - reconciliation$recalculado_tarefa04)
stopifnot(all(reconciliation$diferenca_absoluta <= 1e-12))
utils::write.csv(reconciliation, file.path(log_dir, "sample_size_tarefa03_reconciliation.csv"),
                 row.names = FALSE, na = "")

SHRINKAGE <- 0.90
AUC_SEED <- 20260906L
AUC_RNG_KIND <- "Mersenne-Twister"

run_pmsampsize <- function(type, rsquared = NA_real_, csrsquared = NA_real_,
                            cstatistic = NA_real_, parameters, prevalence = NA_real_,
                            intercept = NA_real_, sd = NA_real_) {
  pmsampsize::pmsampsize(
    type = type,
    rsquared = rsquared,
    csrsquared = csrsquared,
    cstatistic = cstatistic,
    parameters = parameters,
    prevalence = prevalence,
    intercept = intercept,
    sd = sd,
    shrinkage = SHRINKAGE,
    seed = AUC_SEED
  )
}

scenario_specs <- list(
  linear_r2_adjusted = list(
    model = "linear", class = "referencia_principal", label = "R² ajustado recalculado",
    performance = r2_linear_adjusted, performance_name = "R² esperado",
    call = function() run_pmsampsize(
      type = "c", rsquared = r2_linear_adjusted, parameters = p_linear,
      intercept = mean_delta, sd = sd_delta
    )
  ),
  linear_r2_035 = list(
    model = "linear", class = "conservador", label = "R² esperado 0,35",
    performance = 0.35, performance_name = "R² esperado",
    call = function() run_pmsampsize(
      type = "c", rsquared = 0.35, parameters = p_linear,
      intercept = mean_delta, sd = sd_delta
    )
  ),
  linear_r2_030 = list(
    model = "linear", class = "conservador", label = "R² esperado 0,30",
    performance = 0.30, performance_name = "R² esperado",
    call = function() run_pmsampsize(
      type = "c", rsquared = 0.30, parameters = p_linear,
      intercept = mean_delta, sd = sd_delta
    )
  ),
  linear_r2_025 = list(
    model = "linear", class = "conservador", label = "R² esperado 0,25",
    performance = 0.25, performance_name = "R² esperado",
    call = function() run_pmsampsize(
      type = "c", rsquared = 0.25, parameters = p_linear,
      intercept = mean_delta, sd = sd_delta
    )
  ),
  linear_r2_020 = list(
    model = "linear", class = "conservador", label = "R² esperado 0,20",
    performance = 0.20, performance_name = "R² esperado",
    call = function() run_pmsampsize(
      type = "c", rsquared = 0.20, parameters = p_linear,
      intercept = mean_delta, sd = sd_delta
    )
  ),
  logistic_cs_100 = list(
    model = "logistic", class = "referencia_otimista", label = "Cox–Snell aparente (100%)",
    performance = cox_snell_apparent, performance_name = "Cox–Snell esperado",
    call = function() run_pmsampsize(
      type = "b", csrsquared = cox_snell_apparent, parameters = p_logistic,
      prevalence = prevalence
    )
  ),
  logistic_cs_080 = list(
    model = "logistic", class = "conservador", label = "80% do Cox–Snell aparente",
    performance = 0.80 * cox_snell_apparent, performance_name = "Cox–Snell esperado",
    call = function() run_pmsampsize(
      type = "b", csrsquared = 0.80 * cox_snell_apparent, parameters = p_logistic,
      prevalence = prevalence
    )
  ),
  logistic_cs_070 = list(
    model = "logistic", class = "conservador", label = "70% do Cox–Snell aparente",
    performance = 0.70 * cox_snell_apparent, performance_name = "Cox–Snell esperado",
    call = function() run_pmsampsize(
      type = "b", csrsquared = 0.70 * cox_snell_apparent, parameters = p_logistic,
      prevalence = prevalence
    )
  ),
  logistic_cs_060 = list(
    model = "logistic", class = "conservador", label = "60% do Cox–Snell aparente",
    performance = 0.60 * cox_snell_apparent, performance_name = "Cox–Snell esperado",
    call = function() run_pmsampsize(
      type = "b", csrsquared = 0.60 * cox_snell_apparent, parameters = p_logistic,
      prevalence = prevalence
    )
  ),
  logistic_cs_050 = list(
    model = "logistic", class = "conservador", label = "50% do Cox–Snell aparente",
    performance = 0.50 * cox_snell_apparent, performance_name = "Cox–Snell esperado",
    call = function() run_pmsampsize(
      type = "b", csrsquared = 0.50 * cox_snell_apparent, parameters = p_logistic,
      prevalence = prevalence
    )
  ),
  logistic_auc_apparent = list(
    model = "logistic", class = "sensibilidade_auc", label = "AUC aparente atual",
    performance = auc_apparent, performance_name = "AUC / C-statistic",
    seed = AUC_SEED,
    call = function() run_pmsampsize(
      type = "b", cstatistic = auc_apparent, parameters = p_logistic,
      prevalence = prevalence
    )
  ),
  logistic_auc_082 = list(
    model = "logistic", class = "sensibilidade_auc", label = "AUC 0,82",
    performance = 0.82, performance_name = "AUC / C-statistic",
    seed = AUC_SEED,
    call = function() run_pmsampsize(
      type = "b", cstatistic = 0.82, parameters = p_logistic,
      prevalence = prevalence
    )
  ),
  logistic_auc_078 = list(
    model = "logistic", class = "sensibilidade_auc", label = "AUC 0,78",
    performance = 0.78, performance_name = "AUC / C-statistic",
    seed = AUC_SEED,
    call = function() run_pmsampsize(
      type = "b", cstatistic = 0.78, parameters = p_logistic,
      prevalence = prevalence
    )
  )
)

# Fixar também o tipo de RNG torna a semente suficiente para reproduzir a
# aproximação aleatória usada pelo pmsampsize nos cenários baseados em AUC.
RNGkind(AUC_RNG_KIND)
scenario_results <- lapply(scenario_specs, function(spec) spec$call())
names(scenario_results) <- names(scenario_specs)

auc_ids <- names(scenario_specs)[vapply(scenario_specs, function(x) x$class == "sensibilidade_auc", logical(1))]
auc_reproducible <- vapply(auc_ids, function(id) {
  identical(scenario_results[[id]], scenario_specs[[id]]$call())
}, logical(1))
stopifnot(all(auc_reproducible))

get_sample_size <- function(x) as.integer(x$sample_size[[1]])
get_spp <- function(x) if (is.null(x$SPP)) NA_real_ else as.numeric(x$SPP[[1]])
get_epp <- function(x) if (is.null(x$EPP)) NA_real_ else as.numeric(x$EPP[[1]])

scenario_table <- do.call(rbind, Map(function(id, spec, result) {
  n_min <- get_sample_size(result)
  is_binary <- identical(spec$model, "logistic")
  data.frame(
    scenario_id = id,
    modelo = spec$model,
    classe = spec$class,
    cenario = spec$label,
    medida_desempenho = spec$performance_name,
    valor_desempenho = spec$performance,
    parametros = if (is_binary) p_logistic else p_linear,
    prevalencia = if (is_binary) prevalence else NA_real_,
    shrinkage = SHRINKAGE,
    semente_auc = if (!is.null(spec$seed)) spec$seed else NA_integer_,
    n_minimo = n_min,
    participantes_disponiveis = n_available,
    margem_n = n_available - n_min,
    suficiente = n_min <= n_available,
    pmsampsize_spp = if (is_binary) NA_real_ else get_spp(result),
    pmsampsize_epp = if (is_binary) get_epp(result) else NA_real_,
    eventos_estimados_no_n_minimo = if (is_binary) n_min * prevalence else NA_real_,
    eventos_por_parametro_descritivo = if (is_binary) n_min * prevalence / p_logistic else NA_real_,
    stringsAsFactors = FALSE
  )
}, names(scenario_specs), scenario_specs, scenario_results))
rownames(scenario_table) <- NULL

input_table <- data.frame(
  medida = c(
    "Participantes na coorte analítica",
    "Participantes no modelo linear",
    "Participantes no modelo logístico",
    "Parâmetros candidatos — modelo linear",
    "Parâmetros candidatos — modelo logístico",
    "Eventos de melhora",
    "Não eventos",
    "Prevalência de melhora",
    "Média de delta",
    "DP de delta",
    "R² linear aparente",
    "R² linear ajustado",
    "Cox–Snell aparente",
    "Cox–Snell máximo",
    "Nagelkerke aparente",
    "AUC aparente (somente sensibilidade)",
    "Eventos por parâmetro observado (descritivo)",
    "Não eventos por parâmetro observado (descritivo)",
    "Shrinkage desejado",
    "Semente comum dos cenários AUC"
  ),
  valor = c(
    n_available, nobs(results$models$linear), nobs(results$models$logistic),
    p_linear, p_logistic, n_events, n_nonevents, prevalence, mean_delta, sd_delta,
    r2_linear_apparent, r2_linear_adjusted, cox_snell_apparent, cox_snell_maximum,
    nagelkerke_apparent, auc_apparent, n_events / p_logistic, n_nonevents / p_logistic,
    SHRINKAGE, AUC_SEED
  ),
  fonte = c(
    rep("coorte/modelos recalculados — Tarefa 03", 18L),
    "premissa dos cenários", "controle de reprodutibilidade"
  ),
  stringsAsFactors = FALSE
)

utils::write.csv(input_table, file.path(agg, "sample_size_inputs.csv"), row.names = FALSE, na = "")
utils::write.csv(scenario_table, file.path(agg, "sample_size_scenarios.csv"), row.names = FALSE, na = "")

format_num <- function(x, digits = 3) formatC(x, format = "f", digits = digits, decimal.mark = ",")
format_n <- function(x) formatC(as.integer(x), format = "d", big.mark = ".", decimal.mark = ",")

linear_rows <- scenario_table$modelo == "linear"
logistic_rows <- scenario_table$modelo == "logistic" & scenario_table$classe != "sensibilidade_auc"
auc_rows <- scenario_table$classe == "sensibilidade_auc"
scenario_sentence <- function(rows) {
  paste(sprintf(
    "%s: n mínimo %s, margem %s, %s",
    scenario_table$cenario[rows], format_n(scenario_table$n_minimo[rows]),
    format_n(scenario_table$margem_n[rows]),
    ifelse(scenario_table$suficiente[rows], "suficiente", "insuficiente")
  ), collapse = "; ")
}

manuscript_text <- c(
  "Sugestão para o manuscrito",
  "",
  sprintf(
    "A coorte analítica compreendeu %s participantes, após deduplicação explícita e exclusão de casos incompletos. O desfecho contínuo delta apresentou média de %s° (DP %s°), e o desfecho binário de melhora ocorreu em %s/%s participantes (prevalência %s). Os modelos linear e logístico tiveram especificação congelada com %s parâmetros candidatos cada.",
    format_n(n_available), format_num(mean_delta), format_num(sd_delta),
    format_n(n_events), format_n(n_available), format_num(prevalence),
    format_n(p_linear)
  ),
  sprintf(
    "Para o modelo contínuo, o R² ajustado aparente recalculado foi %s (R² aparente %s). Com shrinkage desejado de %s, o pmsampsize estimou n mínimo de %s para a referência pelo R² ajustado; os cenários de R² esperado 0,35, 0,30, 0,25 e 0,20 exigiram, respectivamente, %s, %s, %s e %s participantes.",
    format_num(r2_linear_adjusted), format_num(r2_linear_apparent), format_num(SHRINKAGE),
    format_n(scenario_table$n_minimo[scenario_table$scenario_id == "linear_r2_adjusted"]),
    format_n(scenario_table$n_minimo[scenario_table$scenario_id == "linear_r2_035"]),
    format_n(scenario_table$n_minimo[scenario_table$scenario_id == "linear_r2_030"]),
    format_n(scenario_table$n_minimo[scenario_table$scenario_id == "linear_r2_025"]),
    format_n(scenario_table$n_minimo[scenario_table$scenario_id == "linear_r2_020"])
  ),
  sprintf(
    "Para o modelo binário, o Cox–Snell aparente foi %s, seu máximo sob a prevalência observada foi %s e o Nagelkerke aparente foi %s. Os n mínimos foram %s para o Cox–Snell aparente e %s, %s, %s e %s para 80%%, 70%%, 60%% e 50%% desse valor, respectivamente.",
    format_num(cox_snell_apparent), format_num(cox_snell_maximum), format_num(nagelkerke_apparent),
    format_n(scenario_table$n_minimo[scenario_table$scenario_id == "logistic_cs_100"]),
    format_n(scenario_table$n_minimo[scenario_table$scenario_id == "logistic_cs_080"]),
    format_n(scenario_table$n_minimo[scenario_table$scenario_id == "logistic_cs_070"]),
    format_n(scenario_table$n_minimo[scenario_table$scenario_id == "logistic_cs_060"]),
    format_n(scenario_table$n_minimo[scenario_table$scenario_id == "logistic_cs_050"])
  ),
  sprintf(
    "Cada n mínimo foi comparado diretamente com os %s participantes disponíveis: %s.",
    format_n(n_available), scenario_sentence(seq_len(nrow(scenario_table)))
  ),
  "",
  "Métodos",
  "",
  sprintf(
    "A avaliação foi executada com pmsampsize %s, usando a especificação congelada de %s parâmetros candidatos, shrinkage desejado de %s e os parâmetros recalculados da coorte analítica. Para o desfecho contínuo, foram avaliados o R² ajustado recalculado como referência e R² esperados de 0,35, 0,30, 0,25 e 0,20, com média e DP de delta recalculados. Para o desfecho binário, foram avaliados o Cox–Snell aparente como referência otimista e 80%%, 70%%, 60%% e 50%% desse valor, usando a prevalência recalculada.",
    as.character(packageVersion("pmsampsize")), format_n(p_linear), format_num(SHRINKAGE)
  ),
  "Os cenários baseados em AUC foram mantidos exclusivamente como análise de sensibilidade. AUC aparente atual e AUC de 0,82 e 0,78 foram processadas com a mesma semente explícita, registrada nas tabelas e no log.",
  "",
  "Resultados e limitações",
  "",
  "A suficiência é condicional ao desempenho esperado e às demais premissas do pmsampsize; não foi selecionado retrospectivamente um cenário favorável. O R² e o Cox–Snell derivados do ajuste na própria coorte são aparentes e, portanto, otimistas. Os eventos por parâmetro são apresentados apenas como descrição complementar e não constituem a justificativa principal.",
  "Este cálculo se aplica somente à especificação congelada de 19 parâmetros. Não justifica a complexidade de modelagem flexível exploratória, que requer avaliação própria e validação interna por reamostragem. A avaliação de tamanho amostral também não substitui a avaliação de desempenho, calibração, incerteza e transportabilidade.",
  "",
  "Tabela resumida",
  "",
  "| Modelo | Cenário | n mínimo | Margem para 615 | Suficiente |",
  "|---|---|---:|---:|:---:|",
  vapply(seq_len(nrow(scenario_table)), function(i) sprintf(
    "| %s | %s | %s | %s | %s |",
    scenario_table$modelo[[i]], scenario_table$cenario[[i]], format_n(scenario_table$n_minimo[[i]]),
    format_n(scenario_table$margem_n[[i]]), ifelse(scenario_table$suficiente[[i]], "sim", "não")
  ), character(1))
)

writeLines(manuscript_text, file.path(agg, "sample_size_assessment.md"))

detail_lines <- c(
  "========================================",
  "AVALIAÇÃO FORMAL DO TAMANHO AMOSTRAL — TAREFA 04",
  "========================================",
  "",
  "ENTRADAS RECALCULADAS:",
  capture.output(print(input_table, row.names = FALSE)),
  "",
  "RESULTADOS CONSOLIDADOS:",
  capture.output(print(scenario_table, row.names = FALSE)),
  "",
  "DETALHES DO PMSAMPSIZE:",
  unlist(Map(function(id, spec, result) {
    c(
      "",
      paste0("===== ", id, " — ", spec$label, " ====="),
      paste0("tipo: ", ifelse(spec$model == "linear", "continuous", "binary")),
      paste0("classe: ", spec$class),
      paste0("medida: ", spec$performance_name),
      paste0("valor: ", format(spec$performance, digits = 12, decimal.mark = ".")),
      paste0("parâmetros: ", ifelse(spec$model == "linear", p_linear, p_logistic)),
      paste0("prevalência: ", ifelse(spec$model == "linear", "NA", format(prevalence, digits = 12, decimal.mark = "."))),
      paste0("shrinkage: ", format(SHRINKAGE, digits = 12, decimal.mark = ".")),
      paste0("seed: ", AUC_SEED, " (explicit seed; relevant to AUC scenarios)"),
      capture.output(print(result))
    )
  }, names(scenario_specs), scenario_specs, scenario_results), use.names = FALSE),
  "",
  "REGRAS DE LEITURA:",
  paste0("participantes disponíveis: ", n_available),
  "suficiente = n mínimo <= participantes disponíveis",
  "eventos por parâmetro são descritivos e não foram usados como critério único",
  "cenários AUC são sensibilidades, não a análise principal",
  "",
  "INFORMAÇÕES DE REPRODUTIBILIDADE:",
  paste0("pmsampsize_version: ", as.character(packageVersion("pmsampsize"))),
  paste0("R_version: ", R.version.string),
  paste0("global_seed_config: ", GLOBAL_SEED),
  paste0("auc_seed: ", AUC_SEED),
  paste0("auc_rng_kind: ", AUC_RNG_KIND),
  paste0("auc_reproducibility_same_seed: ", all(auc_reproducible)),
  paste0("data_source: ", DATA_FILE),
  paste0("data_sha256: ", file_sha256(DATA_FILE))
)
writeLines(detail_lines, file.path(agg, "sample_size_pmsampsize_outputs.txt"))
writeLines(capture.output(sessionInfo()), file.path(log_dir, "sample_size_session_info.txt"))
writeLines(c(
  "Tarefa 04 — avaliação formal do tamanho amostral",
  paste("data_execucao:", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  paste("pmsampsize_version:", as.character(packageVersion("pmsampsize"))),
  paste("n:", n_available),
  paste("eventos / não eventos:", n_events, "/", n_nonevents),
  paste("parâmetros linear / logístico:", p_linear, "/", p_logistic),
  paste("prevalência:", format(prevalence, digits = 12, decimal.mark = ".")),
  paste("média_delta:", format(mean_delta, digits = 12, decimal.mark = ".")),
  paste("dp_delta:", format(sd_delta, digits = 12, decimal.mark = ".")),
  paste("r2_linear_aparente:", format(r2_linear_apparent, digits = 12, decimal.mark = ".")),
  paste("r2_linear_ajustado:", format(r2_linear_adjusted, digits = 12, decimal.mark = ".")),
  paste("cox_snell_aparente:", format(cox_snell_apparent, digits = 12, decimal.mark = ".")),
  paste("cox_snell_maximo:", format(cox_snell_maximum, digits = 12, decimal.mark = ".")),
  paste("nagelkerke_aparente:", format(nagelkerke_apparent, digits = 12, decimal.mark = ".")),
  paste("shrinkage:", SHRINKAGE),
  paste("auc_seed:", AUC_SEED),
  paste("auc_rng_kind:", AUC_RNG_KIND),
  paste("auc_reproducibility_same_seed:", all(auc_reproducible)),
  paste("tarefa03_reconciliation:", all(reconciliation$diferenca_absoluta <= 1e-12)),
  "A Tarefa 04 usa somente a especificação congelada; nenhuma justificativa foi estendida à modelagem flexível exploratória.",
  "Eventos por parâmetro foram mantidos como descrição complementar, não como critério único."
), file.path(log_dir, "sample_size_verification.txt"))

# Arquivo legado é substituído por uma saída atual, com título e data da Tarefa 04.
writeLines(c(
  detail_lines,
  "",
  "INTERPRETAÇÃO E SUGESTÃO PARA O MANUSCRITO:",
  manuscript_text
), file.path(PROJECT_ROOT, "avaliacao_tamanho_amostral.txt"))

cat("Tarefa 04 concluída. Resultados em:", agg, "\n")
cat("pmsampsize", as.character(packageVersion("pmsampsize")), "com", nrow(scenario_table), "cenários.\n")
