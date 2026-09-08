#!/usr/bin/env Rscript

# Tarefa 11 — descrição agregada da coorte e apresentação do tamanho amostral.
# Execute com: Rscript --vanilla scripts/run_review_cohort_description.R
# A fonte permanece somente leitura; não são escritos IDs ou linhas individuais.

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg)) sub("^--file=", "", file_arg[[1]]) else {
  "scripts/run_review_cohort_description.R"
}
project_root <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)

source(file.path(project_root, "R", "00_config.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "02_import_prepare.R"), local = .GlobalEnv)

review_root <- file.path(PROJECT_ROOT, "results", "prognostico", "revisao")
review_aggregated <- file.path(review_root, "aggregated")
review_logs <- file.path(review_root, "logs")
dir.create(review_aggregated, recursive = TRUE, showWarnings = FALSE)
dir.create(review_logs, recursive = TRUE, showWarnings = FALSE)

raw <- import_prognostic_data()
cohort <- prepare_prognostic_data(raw)
audit <- attr(cohort, "cohort_audit")
deduplicated <- raw[!(raw$id %in% audit$duplicate_ids), , drop = FALSE]
deduplicated <- derive_scoliometer_class(deduplicated)
deduplicated$imc <- deduplicated$peso / deduplicated$altura^2
deduplicated <- derive_cobb_region(deduplicated)
deduplicated$delta <- deduplicated$maior_curva_6_meses - deduplicated$cobb_inicial_maior
deduplicated$delta_cat <- as.integer(deduplicated$delta <= -5)
deduplicated <- set_model_factors(deduplicated)

numeric_variables <- c(
  "idade", "imc", "cifose_toracica", "lordose_lombar", "correcao_colete",
  "cobb_inicial_maior", "maior_curva_6_meses", "delta"
)
factor_variables <- c("sexo", "lenke", "risser", "flexibilidade", "escoliometro_maior_10_graus")
labels <- c(
  idade = "Idade (anos)", imc = "IMC (kg/m²)", cifose_toracica = "Cifose torácica (graus)",
  lordose_lombar = "Lordose lombar (graus)", correcao_colete = "Correção pelo colete (%)",
  cobb_inicial_maior = "Maior Cobb basal (graus)", maior_curva_6_meses = "Maior Cobb aos 6 meses (graus)",
  delta = "Delta: maior Cobb aos 6 meses − maior Cobb basal (graus)",
  sexo = "Sexo", lenke = "Classificação Lenke", risser = "Risser", flexibilidade = "Flexibilidade",
  escoliometro_maior_10_graus = "Classe do escoliômetro", delta_cat = "Melhora radiográfica ≥5°"
)

numeric_summary <- do.call(rbind, lapply(numeric_variables, function(v) {
  x <- cohort[[v]]
  data.frame(
    secao = if (v %in% MODEL_PREDICTORS) "preditor" else "desfecho_ou_magnitude",
    variavel = v, rotulo = labels[[v]], nivel = NA_character_, tipo = "numerica",
    n = sum(!is.na(x)), ausentes = sum(is.na(x)), pct_ausentes = mean(is.na(x)) * 100,
    media = mean(x, na.rm = TRUE), dp = stats::sd(x, na.rm = TRUE), mediana = stats::median(x, na.rm = TRUE),
    q1 = stats::quantile(x, .25, na.rm = TRUE, names = FALSE), q3 = stats::quantile(x, .75, na.rm = TRUE, names = FALSE),
    minimo = min(x, na.rm = TRUE), maximo = max(x, na.rm = TRUE), contagem = NA_integer_, proporcao = NA_real_,
    stringsAsFactors = FALSE
  )
}))

factor_summary <- do.call(rbind, lapply(factor_variables, function(v) {
  x <- factor(cohort[[v]], levels = if (v %in% names(FACTOR_LEVELS)) FACTOR_LEVELS[[v]] else NULL)
  tab <- table(x, useNA = "no")
  data.frame(
    secao = "preditor", variavel = v, rotulo = labels[[v]], nivel = names(tab), tipo = "categorica",
    n = length(x), ausentes = sum(is.na(x)), pct_ausentes = mean(is.na(x)) * 100,
    media = NA_real_, dp = NA_real_, mediana = NA_real_, q1 = NA_real_, q3 = NA_real_, minimo = NA_real_, maximo = NA_real_,
    contagem = as.integer(tab), proporcao = as.integer(tab) / length(x), stringsAsFactors = FALSE
  )
}))
event_tab <- table(factor(cohort$delta_cat, levels = c(0, 1), labels = c("não melhora", "melhora")))
event_summary <- data.frame(
  secao = "desfecho", variavel = "delta_cat", rotulo = labels[["delta_cat"]], nivel = names(event_tab), tipo = "categorica",
  n = nrow(cohort), ausentes = 0L, pct_ausentes = 0, media = NA_real_, dp = NA_real_, mediana = NA_real_,
  q1 = NA_real_, q3 = NA_real_, minimo = NA_real_, maximo = NA_real_, contagem = as.integer(event_tab),
  proporcao = as.integer(event_tab) / nrow(cohort), stringsAsFactors = FALSE
)
cohort_descriptive <- rbind(numeric_summary, factor_summary, event_summary)
utils::write.csv(cohort_descriptive, file.path(review_aggregated, "cohort_descriptive.csv"), row.names = FALSE, na = "")

all_missing <- missing_report(raw, cohort)
missing_selected <- all_missing[all_missing$etapa %in% c("após deduplicação explícita", "coorte analítica por caso completo"), ]
missing_wide <- reshape(missing_selected, idvar = "variavel", timevar = "etapa", direction = "wide")
names(missing_wide) <- sub("n\\.após deduplicação explícita", "n_deduplicados", names(missing_wide), fixed = FALSE)
names(missing_wide) <- sub("n_ausentes\\.após deduplicação explícita", "ausentes_deduplicados", names(missing_wide), fixed = FALSE)
names(missing_wide) <- sub("pct_ausentes\\.após deduplicação explícita", "pct_ausentes_deduplicados", names(missing_wide), fixed = FALSE)
names(missing_wide) <- sub("n\\.coorte analítica por caso completo", "n_analitico", names(missing_wide), fixed = FALSE)
names(missing_wide) <- sub("n_ausentes\\.coorte analítica por caso completo", "ausentes_analitico", names(missing_wide), fixed = FALSE)
names(missing_wide) <- sub("pct_ausentes\\.coorte analítica por caso completo", "pct_ausentes_analitico", names(missing_wide), fixed = FALSE)
flow <- data.frame(
  componente = c("fluxo", "fluxo", "fluxo", "casos_incompletos"),
  variavel = c("registros brutos", "após deduplicação", "coorte analítica", "variáveis do modelo"),
  n_bruto = c(nrow(raw), NA, NA, NA),
  n_deduplicados = c(NA, nrow(deduplicated), NA, nrow(deduplicated)),
  ausentes_deduplicados = c(NA, NA, NA, sum(!stats::complete.cases(deduplicated[MODEL_COMPLETE_VARS]))),
  pct_ausentes_deduplicados = c(NA, NA, NA, mean(!stats::complete.cases(deduplicated[MODEL_COMPLETE_VARS])) * 100),
  n_analitico = c(NA, NA, nrow(cohort), nrow(cohort)),
  ausentes_analitico = c(NA, NA, NA, 0), pct_ausentes_analitico = c(NA, NA, NA, 0),
  stringsAsFactors = FALSE
)
missing_before_after <- rbind(
  transform(missing_wide, componente = "ausencia_por_variavel", n_bruto = NA_integer_)[, names(flow)], flow
)
utils::write.csv(missing_before_after, file.path(review_aggregated, "missing_before_after.csv"), row.names = FALSE, na = "")

sample_size <- utils::read.csv(file.path(RESULTS_ROOT, "aggregated", "sample_size_scenarios.csv"), check.names = FALSE)
keep <- sample_size$classe != "sensibilidade_auc"
sample_size_display <- sample_size[keep, c(
  "scenario_id", "modelo", "classe", "cenario", "medida_desempenho", "valor_desempenho", "parametros",
  "prevalencia", "shrinkage", "n_minimo", "participantes_disponiveis", "margem_n", "suficiente"
)]
sample_size_display$base_do_cenario <- ifelse(
  sample_size_display$classe == "referencia_otimista", "aparente da própria coorte; otimista",
  ifelse(sample_size_display$classe == "referencia_principal", "aparente da própria coorte; referência", "premissa conservadora"))
sample_size_display$aplicabilidade <- "Somente modelos principais lineares/logísticos de 19 parâmetros; não justifica complexidade flexível exploratória."
utils::write.csv(sample_size_display, file.path(review_aggregated, "sample_size_display.csv"), row.names = FALSE, na = "")

# Comparação apenas descritiva e agregada; não há testes para o grupo de três excluídos.
excluded <- deduplicated[!stats::complete.cases(deduplicated[MODEL_COMPLETE_VARS]), , drop = FALSE]
compare_num <- do.call(rbind, lapply(numeric_variables, function(v) data.frame(
  variavel = labels[[v]], incluido_n = nrow(cohort), excluido_n = nrow(excluded),
  media_incluidos = mean(cohort[[v]], na.rm = TRUE), media_excluidos = mean(excluded[[v]], na.rm = TRUE),
  stringsAsFactors = FALSE
)))
compare_cat <- do.call(rbind, lapply(c(factor_variables, "delta_cat"), function(v) {
  data.frame(variavel = labels[[v]], incluido_n = nrow(cohort), excluido_n = nrow(excluded),
             media_incluidos = NA_real_, media_excluidos = NA_real_, stringsAsFactors = FALSE)
}))
comparison <- rbind(compare_num, compare_cat)

delta_marks <- sapply(c(-5, 0, 5), function(cut) c(n = sum(cohort$delta <= cut), prop = mean(cohort$delta <= cut)))
log_lines <- c(
  "Tarefa 11 — descrição da coorte e tamanho amostral",
  paste("fonte_sha256:", file_sha256(DATA_FILE)), paste("n_bruto:", nrow(raw)),
  paste("n_deduplicado:", nrow(deduplicated)), paste("n_analitico:", nrow(cohort)),
  paste("eventos_nao_eventos:", sum(cohort$delta_cat == 1L), "/", sum(cohort$delta_cat == 0L)),
  paste("incompletos_deduplicados:", nrow(excluded), sprintf("(%.3f%%)", 100 * nrow(excluded) / nrow(deduplicated))),
  paste("empates_cobb_basal:", sum(cohort$empate_cobb_inicial)),
  paste("delta_media_dp:", sprintf("%.6f / %.6f", mean(cohort$delta), stats::sd(cohort$delta))),
  paste("delta_leq_-5_0_5:", paste(sprintf("%s:%d (%.4f)", c(-5, 0, 5), delta_marks["n", ], delta_marks["prop", ]), collapse = "; ")),
  "parametros_preditores: 19; intercepto: 1; shrinkage_desejado: 0.90",
  "comparacao_incluidos_excluidos: descritiva agregada; sem testes de hipótese",
  "limitacao: entradas de desempenho aparentes são retrospectivas e otimistas; cálculo não cobre complexidade flexível."
)
writeLines(log_lines, file.path(review_logs, "cohort_task11.log"))
utils::write.csv(comparison, file.path(review_logs, "cohort_included_excluded_aggregate.csv"), row.names = FALSE, na = "")

stopifnot(
  nrow(raw) == 621L, nrow(deduplicated) == 618L, nrow(cohort) == 615L,
  nrow(excluded) == 3L, sum(cohort$delta_cat == 1L) == 317L, sum(cohort$delta_cat == 0L) == 298L,
  sum(cohort$empate_cobb_inicial) == 10L, all(sample_size_display$parametros == 19L),
  all(sample_size_display$shrinkage == 0.9), any(!sample_size_display$suficiente),
  !any(grepl("(^|,)id(,|$)", names(cohort_descriptive))),
  !any(grepl("(^|,)id(,|$)", names(missing_before_after)))
)
cat("Tarefa 11 concluída: tabelas agregadas e log verificados.\n")
