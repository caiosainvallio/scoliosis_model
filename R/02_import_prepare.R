# Importação e preparação da coorte analítica, sem ajuste de modelo ou resultado
# inferencial. A planilha bruta é somente lida; nenhuma coluna é escrita nela.

MODEL_PREDICTORS <- c(
  "idade", "imc", "cifose_toracica", "lordose_lombar", "correcao_colete",
  "sexo", "lenke", "risser", "flexibilidade",
  "escoliometro_maior_10_graus"
)

MODEL_COMPLETE_VARS <- c("delta", "delta_cat", MODEL_PREDICTORS)

EXPECTED_SOURCE_COLUMNS <- c(
  "id", "idade", "sexo", "altura", "peso", "cobb_toracico_proximal",
  "cobb_toracica", "cobb_lombar", "lenke", "risser", "cifose_toracica",
  "lordose_lombar", "escoliometro_cervical", "escoliometro_torarica",
  "escoliometro_lombar", "flexibilidade", "dif_colete", "correcao_colete",
  "maior_curva_6_meses"
)

DUPLICATE_PAIRS <- data.frame(
  par = c("17 / 46", "21 / 162", "16 / 248"),
  id_mantido = c(17, 21, 16),
  id_excluido = c(46, 162, 248),
  stringsAsFactors = FALSE
)

INCOMPLETE_LENKE_IDS <- c(390, 535, 628)

FACTOR_REFERENCES <- c(
  sexo = "feminino",
  lenke = "1",
  risser = "0",
  flexibilidade = "flexivel",
  escoliometro_maior_10_graus = "normal"
)

FACTOR_LEVELS <- list(
  sexo = c("feminino", "masculino"),
  lenke = as.character(1:6),
  risser = as.character(0:4),
  flexibilidade = c("flexivel", "rigido"),
  escoliometro_maior_10_graus = c("normal", "toracica", "lombar", "toracica_lombar")
)

clean_names_basic <- function(x) {
  x <- iconv(x, from = "", to = "ASCII//TRANSLIT")
  x <- tolower(x)
  x <- gsub("[^a-z0-9]+", "_", x)
  x <- gsub("^_+|_+$", "", x)
  make.unique(x, sep = "_")
}

import_prognostic_data <- function(path = DATA_FILE, sheet = DATA_SHEET) {
  if (!file.exists(path)) {
    stop("Base documentada não encontrada: ", path)
  }
  available_sheets <- readxl::excel_sheets(path)
  if (!sheet %in% available_sheets) {
    stop(
      "A aba '", sheet, "' não existe em ", path,
      ". Abas disponíveis: ", paste(available_sheets, collapse = ", ")
    )
  }
  raw <- readxl::read_excel(path, sheet = sheet, na = "")
  names(raw) <- clean_names_basic(names(raw))
  as.data.frame(raw, stringsAsFactors = FALSE)
}

assert_expected_source <- function(data) {
  stopifnot(is.data.frame(data))
  missing_columns <- setdiff(EXPECTED_SOURCE_COLUMNS, names(data))
  extra_columns <- setdiff(names(data), EXPECTED_SOURCE_COLUMNS)
  if (length(missing_columns) > 0 || length(extra_columns) > 0) {
    stop(
      "Colunas da fonte divergentes. Ausentes: ",
      if (length(missing_columns)) paste(missing_columns, collapse = ", ") else "nenhuma",
      "; extras: ",
      if (length(extra_columns)) paste(extra_columns, collapse = ", ") else "nenhuma"
    )
  }
  invisible(TRUE)
}

same_value <- function(x, y) {
  if (length(x) != length(y)) return(FALSE)
  if (all(is.na(x)) && all(is.na(y))) return(TRUE)
  identical(as.character(x), as.character(y))
}

compare_duplicate_pair <- function(data, kept_id, excluded_id) {
  if (sum(data$id == kept_id, na.rm = TRUE) != 1L ||
      sum(data$id == excluded_id, na.rm = TRUE) != 1L) {
    stop("Par duplicado não encontrado exatamente uma vez: ", kept_id, " / ", excluded_id)
  }
  kept <- data[data$id == kept_id, , drop = FALSE]
  excluded <- data[data$id == excluded_id, , drop = FALSE]
  compared <- setdiff(names(data), "id")
  equal_by_variable <- vapply(
    compared,
    function(variable) same_value(kept[[variable]], excluded[[variable]]),
    logical(1)
  )
  if (!all(equal_by_variable)) {
    stop(
      "Par duplicado não é idêntico nas variáveis clínicas/radiográficas/desfecho: ",
      kept_id, " / ", excluded_id, ". Divergências: ",
      paste(names(equal_by_variable)[!equal_by_variable], collapse = ", ")
    )
  }
  data.frame(
    par = paste(kept_id, "/", excluded_id),
    id_mantido = kept_id,
    id_excluido = excluded_id,
    n_variaveis_comparadas = length(compared),
    identico = TRUE,
    stringsAsFactors = FALSE
  )
}

safe_row_max <- function(x) {
  if (all(is.na(x))) NA_real_ else max(x, na.rm = TRUE)
}

derive_cobb_region <- function(data) {
  cobb_columns <- c("cobb_toracico_proximal", "cobb_toracica", "cobb_lombar")
  region_labels <- c("toracico_proximal", "toracica", "lombar")
  values <- as.matrix(data[cobb_columns])
  maxima <- apply(values, 1L, safe_row_max)
  regions <- vapply(seq_len(nrow(data)), function(i) {
    if (is.na(maxima[[i]])) return(NA_character_)
    paste(region_labels[!is.na(values[i, ]) & values[i, ] == maxima[[i]]], collapse = "|")
  }, character(1))
  data$cobb_inicial_maior <- as.numeric(maxima)
  data$regiao_cobb_inicial <- regions
  data$empate_cobb_inicial <- grepl("|", regions, fixed = TRUE)
  data$regioes_cobb_inicial_empate <- ifelse(
    data$empate_cobb_inicial, regions, NA_character_
  )
  data
}

derive_scoliometer_class <- function(data) {
  values <- as.matrix(data[c(
    "escoliometro_cervical", "escoliometro_torarica", "escoliometro_lombar"
  )])
  labels <- c("cervical", "toracica", "lombar")
  data$escoliometro_maior_10_graus <- vapply(seq_len(nrow(data)), function(i) {
    above <- !is.na(values[i, ]) & values[i, ] > 10
    if (!any(above)) "normal" else paste(labels[above], collapse = "_")
  }, character(1))
  data
}

set_model_factors <- function(data) {
  for (variable in names(FACTOR_LEVELS)) {
    data[[variable]] <- factor(
      as.character(data[[variable]]),
      levels = FACTOR_LEVELS[[variable]]
    )
  }
  data
}

file_sha256 <- function(path) {
  if (!file.exists(path)) stop("Arquivo para hash não encontrado: ", path)
  if (requireNamespace("digest", quietly = TRUE)) {
    return(digest::digest(file = path, algo = "sha256"))
  }
  shasum <- Sys.which("shasum")
  if (!nzchar(shasum)) stop("Não foi possível calcular SHA-256: digest e shasum ausentes.")
  result <- system2(shasum, c("-a", "256", path), stdout = TRUE, stderr = TRUE)
  if (!length(result) || !grepl("^[0-9a-fA-F]{64}", result[[1]])) {
    stop("Falha ao calcular SHA-256 de: ", path)
  }
  sub("[[:space:]].*$", "", result[[1]])
}

prepare_prognostic_data <- function(data) {
  assert_expected_source(data)
  if (nrow(data) != 621L) stop("A base bruta deveria conter 621 linhas; encontrou ", nrow(data), ".")
  if (anyDuplicated(data$id)) stop("A base bruta contém IDs repetidos antes da deduplicação explícita.")

  pair_audit <- do.call(
    rbind,
    lapply(seq_len(nrow(DUPLICATE_PAIRS)), function(i) {
      compare_duplicate_pair(data, DUPLICATE_PAIRS$id_mantido[[i]], DUPLICATE_PAIRS$id_excluido[[i]])
    })
  )

  excluded_duplicate_ids <- DUPLICATE_PAIRS$id_excluido
  deduplicated <- data[!(data$id %in% excluded_duplicate_ids), , drop = FALSE]
  if (nrow(deduplicated) != 618L || length(unique(deduplicated$id)) != 618L) {
    stop("Deduplicação explícita não resultou em 618 IDs únicos.")
  }

  prepared <- derive_scoliometer_class(deduplicated)
  prepared$imc <- prepared$peso / (prepared$altura ^ 2)
  prepared <- derive_cobb_region(prepared)
  prepared$delta <- prepared$maior_curva_6_meses - prepared$cobb_inicial_maior
  prepared$delta_cat <- as.integer(prepared$delta <= -5)
  prepared$delta_cat_f <- factor(prepared$delta_cat, levels = c(0, 1), labels = c("nao_melhora", "melhora"))
  prepared <- set_model_factors(prepared)

  complete_mask <- stats::complete.cases(prepared[MODEL_COMPLETE_VARS])
  incomplete_ids <- prepared$id[!complete_mask]
  if (!identical(sort(incomplete_ids), sort(INCOMPLETE_LENKE_IDS))) {
    stop(
      "Os casos incompletos esperados não coincidem. Esperados: ",
      paste(sort(INCOMPLETE_LENKE_IDS), collapse = ", "), "; encontrados: ",
      paste(sort(incomplete_ids), collapse = ", ")
    )
  }
  cohort <- prepared[complete_mask, , drop = FALSE]
  if (nrow(cohort) != 615L || length(unique(cohort$id)) != 615L) {
    stop("A coorte final deveria conter 615 IDs únicos.")
  }
  if (sum(cohort$delta_cat == 1L) != 317L || sum(cohort$delta_cat == 0L) != 298L) {
    stop("A contagem final esperada é 317 eventos e 298 não eventos.")
  }

  hyper_ids <- c(81, 174, 401)
  hyper <- cohort[cohort$id %in% hyper_ids, c("id", "correcao_colete"), drop = FALSE]
  if (nrow(hyper) != 3L || any(hyper$correcao_colete <= 100)) {
    stop("Os IDs 81, 174 e 401 não foram preservados com correção acima de 100%.")
  }

  audit <- list(
    pair_audit = pair_audit,
    duplicate_ids = excluded_duplicate_ids,
    incomplete_ids = INCOMPLETE_LENKE_IDS,
    hypercorrection = hyper,
    complete_mask = complete_mask,
    complete_variables = MODEL_COMPLETE_VARS,
    source_rows = nrow(data),
    deduplicated_rows = nrow(deduplicated),
    final_rows = nrow(cohort)
  )
  attr(cohort, "cohort_audit") <- audit
  cohort
}

cohort_flow_table <- function(cohort) {
  audit <- attr(cohort, "cohort_audit")
  if (is.null(audit)) stop("A coorte não contém a auditoria gerada por prepare_prognostic_data().")
  data.frame(
    etapa = c("Leitura bruta", "Após deduplicação explícita", "Coorte analítica por caso completo"),
    n_antes = c(audit$source_rows, audit$source_rows, audit$deduplicated_rows),
    n_excluidos = c(0L, length(audit$duplicate_ids), length(audit$incomplete_ids)),
    n_restante = c(audit$source_rows, audit$deduplicated_rows, audit$final_rows),
    motivo = c("registros lidos", "duplicatas confirmadas por pares pré-especificados", "Lenke ausente"),
    stringsAsFactors = FALSE
  )
}

exclusion_table_internal <- function(cohort) {
  audit <- attr(cohort, "cohort_audit")
  data.frame(
    id = c(audit$duplicate_ids, audit$incomplete_ids),
    motivo = c(
      rep("duplicata explícita; par clínico/radiográfico/desfecho idêntico", length(audit$duplicate_ids)),
      rep("caso completo: Lenke ausente", length(audit$incomplete_ids))
    ),
    stringsAsFactors = FALSE
  )
}

missing_report <- function(data, cohort = NULL) {
  derive_all <- function(x) {
    x <- derive_scoliometer_class(x)
    x$imc <- x$peso / (x$altura ^ 2)
    x <- derive_cobb_region(x)
    x$delta <- x$maior_curva_6_meses - x$cobb_inicial_maior
    x$delta_cat <- as.integer(x$delta <= -5)
    set_model_factors(x)
  }
  raw_prepared <- derive_all(data)
  deduplicated <- raw_prepared[!(raw_prepared$id %in% DUPLICATE_PAIRS$id_excluido), , drop = FALSE]
  final_data <- if (is.null(cohort)) deduplicated else cohort
  variables <- unique(c(names(raw_prepared), MODEL_COMPLETE_VARS, "cobb_inicial_maior", "regiao_cobb_inicial"))
  variables <- setdiff(variables, "id")
  variables <- intersect(variables, names(final_data))
  count_stage <- function(x, stage) {
    data.frame(
      etapa = stage,
      variavel = variables,
      n = nrow(x),
      n_ausentes = vapply(variables, function(v) sum(is.na(x[[v]])), integer(1)),
      pct_ausentes = vapply(variables, function(v) mean(is.na(x[[v]])) * 100, numeric(1)),
      stringsAsFactors = FALSE
    )
  }
  rbind(
    count_stage(raw_prepared, "base bruta após derivação"),
    count_stage(deduplicated, "após deduplicação explícita"),
    count_stage(final_data, "coorte analítica por caso completo")
  )
}

factor_levels_table <- function(cohort) {
  do.call(rbind, lapply(names(FACTOR_LEVELS), function(variable) {
    data.frame(
      variavel = variable,
      nivel = FACTOR_LEVELS[[variable]],
      referencia = FACTOR_REFERENCES[[variable]],
      n = as.integer(table(cohort[[variable]])[FACTOR_LEVELS[[variable]]]),
      stringsAsFactors = FALSE
    )
  }))
}

independent_derivation_check <- function(raw_data, cohort) {
  source <- raw_data[!(raw_data$id %in% DUPLICATE_PAIRS$id_excluido), , drop = FALSE]
  cobb_matrix <- as.matrix(source[c("cobb_toracico_proximal", "cobb_toracica", "cobb_lombar")])
  independent_cobb <- apply(cobb_matrix, 1L, function(x) {
    if (all(is.na(x))) NA_real_ else max(x, na.rm = TRUE)
  })
  independent_imc <- source$peso / (source$altura * source$altura)
  independent_delta <- source$maior_curva_6_meses - independent_cobb
  independent_delta_cat <- as.integer(independent_delta <= -5)
  final_rows <- match(cohort$id, source$id)
  comparisons <- list(
    imc = list(expected = independent_imc[final_rows], observed = cohort$imc),
    cobb_inicial_maior = list(expected = independent_cobb[final_rows], observed = cohort$cobb_inicial_maior),
    delta = list(expected = independent_delta[final_rows], observed = cohort$delta),
    delta_cat = list(expected = independent_delta_cat[final_rows], observed = cohort$delta_cat)
  )
  result <- do.call(rbind, lapply(names(comparisons), function(variable) {
    expected <- comparisons[[variable]]$expected
    observed <- comparisons[[variable]]$observed
    difference <- abs(as.numeric(expected) - as.numeric(observed))
    data.frame(
      variavel = variable,
      n_comparado = length(expected),
      n_igual = sum(difference == 0),
      max_diferenca_absoluta = max(difference),
      aprovado = all(difference == 0),
      stringsAsFactors = FALSE
    )
  }))
  if (!all(result$aprovado)) stop("A verificação independente das derivações falhou.")
  result
}

model_cohort_identity <- function(cohort) {
  linear_vars <- c("delta", MODEL_PREDICTORS)
  logistic_vars <- c("delta_cat", MODEL_PREDICTORS)
  linear_ids <- cohort$id[stats::complete.cases(cohort[linear_vars])]
  logistic_ids <- cohort$id[stats::complete.cases(cohort[logistic_vars])]
  same_ids <- identical(linear_ids, logistic_ids)
  result <- data.frame(
    n_modelo_linear = length(linear_ids),
    n_modelo_logistico = length(logistic_ids),
    mesmas_linhas = same_ids,
    stringsAsFactors = FALSE
  )
  if (!same_ids) stop("Os modelos linear e logístico não recebem as mesmas linhas.")
  result
}

write_cohort_audit_outputs <- function(
    cohort,
    source_path = DATA_FILE,
    source_sheet = DATA_SHEET,
    raw_data = NULL) {
  ensure_output_dirs()
  audit <- attr(cohort, "cohort_audit")
  flow <- cohort_flow_table(cohort)
  exclusions <- exclusion_table_internal(cohort)
  missing <- missing_report(if (is.null(raw_data)) cohort else raw_data, cohort)
  factors <- factor_levels_table(cohort)
  derivation_check <- if (is.null(raw_data)) NULL else independent_derivation_check(raw_data, cohort)
  model_identity <- model_cohort_identity(cohort)
  summary <- data.frame(
    n_bruto = audit$source_rows,
    n_unicos_pos_deduplicacao = audit$deduplicated_rows,
    n_final = audit$final_rows,
    eventos_melhora = sum(cohort$delta_cat == 1L),
    nao_eventos = sum(cohort$delta_cat == 0L),
    n_empates_cobb_basal = sum(cohort$empate_cobb_inicial),
    n_modelo_linear = model_identity$n_modelo_linear,
    n_modelo_logistico = model_identity$n_modelo_logistico,
    mesmas_linhas_nos_modelos = model_identity$mesmas_linhas,
    stringsAsFactors = FALSE
  )
  metadata <- data.frame(
    arquivo = normalizePath(source_path, mustWork = TRUE),
    aba = source_sheet,
    sha256 = file_sha256(source_path),
    data_modificacao = format(file.info(source_path)$mtime, "%Y-%m-%d %H:%M:%S %Z"),
    stringsAsFactors = FALSE
  )

  utils::write.csv(flow, file.path(RESULTS_DIRS[["aggregated"]], "cohort_flow.csv"), row.names = FALSE, na = "")
  utils::write.csv(exclusions, file.path(RESULTS_DIRS[["logs"]], "cohort_exclusions_internal.csv"), row.names = FALSE, na = "")
  utils::write.csv(audit$pair_audit, file.path(RESULTS_DIRS[["logs"]], "duplicate_pair_audit.csv"), row.names = FALSE, na = "")
  utils::write.csv(audit$hypercorrection, file.path(RESULTS_DIRS[["logs"]], "hypercorrection_audit_internal.csv"), row.names = FALSE, na = "")
  if (!is.null(derivation_check)) {
    utils::write.csv(derivation_check, file.path(RESULTS_DIRS[["logs"]], "independent_derivation_check.csv"), row.names = FALSE, na = "")
  }
  utils::write.csv(model_identity, file.path(RESULTS_DIRS[["logs"]], "model_cohort_identity.csv"), row.names = FALSE, na = "")
  utils::write.csv(missing, file.path(RESULTS_DIRS[["aggregated"]], "missing_report.csv"), row.names = FALSE, na = "")
  utils::write.csv(factors, file.path(RESULTS_DIRS[["aggregated"]], "factor_levels_and_references.csv"), row.names = FALSE, na = "")
  utils::write.csv(summary, file.path(RESULTS_DIRS[["aggregated"]], "cohort_summary.csv"), row.names = FALSE, na = "")
  utils::write.csv(metadata, file.path(RESULTS_DIRS[["logs"]], "source_metadata.csv"), row.names = FALSE, na = "")

  figure_path <- file.path(RESULTS_DIRS[["figures"]], "cohort_flow.png")
  grDevices::png(figure_path, width = 1500, height = 850, res = 150)
  on.exit(grDevices::dev.off(), add = TRUE)
  graphics::plot.new()
  graphics::plot.window(xlim = c(0, 10), ylim = c(0, 10), asp = 1)
  boxes <- list(
    c(0.8, 6.3, 9.2, 8.8), c(0.8, 3.7, 9.2, 6.2), c(0.8, 1.1, 9.2, 3.6)
  )
  labels <- c(
    "Leitura bruta\n621 registros",
    "Deduplicação explícita\n618 IDs únicos",
    "Coorte analítica\n615 casos completos"
  )
  for (i in seq_along(boxes)) {
    b <- boxes[[i]]
    graphics::rect(b[1], b[2], b[3], b[4], col = "#E8F1F8", border = "#2C5D7C", lwd = 2)
    graphics::text(5, mean(c(b[2], b[4])), labels[[i]], cex = 1.25)
  }
  graphics::arrows(5, 6.25, 5, 6.18, length = 0.12, lwd = 2)
  graphics::arrows(5, 3.65, 5, 3.58, length = 0.12, lwd = 2)
  graphics::text(9.5, 4.95, "3 duplicatas\nexcluídas", adj = c(0, 0.5), cex = 1)
  graphics::text(9.5, 2.35, "3 Lenke ausentes\nexcluídos", adj = c(0, 0.5), cex = 1)
  graphics::title("Formação agregada da coorte analítica", cex.main = 1.35)
  invisible(list(
    flow = flow, exclusions = exclusions, pair_audit = audit$pair_audit,
    missing = missing, factors = factors, derivation_check = derivation_check,
    model_identity = model_identity, summary = summary, metadata = metadata
  ))
}

source_description <- function() {
  paste0(
    "Fonte documentada: ", DATA_FILE, "; aba: ", DATA_SHEET,
    ". A base bruta não é sobrescrita pelo relatório."
  )
}
