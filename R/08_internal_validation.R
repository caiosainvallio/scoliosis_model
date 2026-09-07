# Saídas agregadas e auditoria da avaliação interna por bootstrap.
#
# Este arquivo não reajusta modelos por conta própria: ele organiza as réplicas
# produzidas por bootstrap_replicates(), valida o contrato da Tarefa 06 e grava
# tabelas públicas e objetos internos para a Tarefa 07.

apparent_metrics_from_frozen <- function(results, model = c("linear", "logistic")) {
  model <- match.arg(model)
  if (model == "linear") {
    metrics <- results$metrics_linear[1, , drop = FALSE]
    calibration <- results$calibration$summary
    slope <- calibration$calibration_slope[calibration$model == "linear"]
    intercept <- calibration$calibration_intercept[calibration$model == "linear"]
    return(c(r2 = metrics$r2, rmse = metrics$rmse, mae = metrics$mae,
             mean_error = metrics$mean_error,
             calibration_intercept = intercept, calibration_slope = slope))
  }
  metrics <- results$metrics_logistic[1, , drop = FALSE]
  calibration <- results$calibration$summary
  slope <- calibration$calibration_slope[calibration$model == "logistic"]
  intercept <- calibration$calibration_intercept[calibration$model == "logistic"]
  c(auc = metrics$auc, brier_score = metrics$brier_score, log_loss = metrics$log_loss,
    calibration_in_the_large = intercept, calibration_slope = slope)
}

bootstrap_warning_table <- function(replicas, model) {
  rows <- lapply(replicas, function(replica) {
    if (!length(replica$warnings)) return(NULL)
    data.frame(model = model, replicate = replica$replicate, seed = replica$seed,
               warning = replica$warnings, stringsAsFactors = FALSE)
  })
  rows <- Filter(Negate(is.null), rows)
  if (length(rows)) return(do.call(rbind, rows))
  data.frame(model = character(), replicate = integer(), seed = integer(),
             warning = character(), stringsAsFactors = FALSE)
}

bootstrap_failure_log <- function(replicas, model) {
  failed <- replicas[vapply(replicas, function(x) identical(x$status, "failed"), logical(1))]
  if (!length(failed)) {
    return(data.frame(model = character(), replicate = integer(), seed = integer(),
                      failure_reason = character(), failure_detail = character(),
                      stringsAsFactors = FALSE))
  }
  do.call(rbind, lapply(failed, function(replica) {
    data.frame(model = model, replicate = replica$replicate, seed = replica$seed,
               failure_reason = replica$failure_reason,
               failure_detail = replica$failure_detail, stringsAsFactors = FALSE)
  }))
}

bootstrap_prediction_matrix <- function(replicas, n_original) {
  predictions <- matrix(NA_real_, nrow = length(replicas), ncol = n_original)
  for (i in seq_along(replicas)) {
    replica <- replicas[[i]]
    if (identical(replica$status, "valid") && length(replica$predictions$original) == n_original) {
      predictions[i, ] <- as.numeric(replica$predictions$original)
    }
  }
  colnames(predictions) <- paste0("row_", seq_len(n_original))
  predictions
}

bootstrap_index_matrix <- function(replicas, sample_size) {
  indices <- matrix(NA_integer_, nrow = length(replicas), ncol = sample_size)
  for (i in seq_along(replicas)) {
    index <- replicas[[i]]$index
    if (length(index) == sample_size) indices[i, ] <- as.integer(index)
  }
  colnames(indices) <- paste0("draw_", seq_len(sample_size))
  indices
}

validate_bootstrap_contract <- function(replicas, times = 2000L, sample_size = 615L,
                                         min_valid = 1980L, n_original = 615L) {
  if (!is.list(replicas) || length(replicas) != times) {
    stop("A execução não registrou exatamente ", times, " tentativas.", call. = FALSE)
  }
  replicate_ids <- vapply(replicas, function(x) as.integer(x$replicate), integer(1))
  if (!identical(replicate_ids, seq_len(times))) {
    stop("Os índices das réplicas não são exatamente 1:", times, ".", call. = FALSE)
  }
  if (anyDuplicated(vapply(replicas, function(x) as.integer(x$seed), integer(1)))) {
    stop("Foram encontradas sementes repetidas entre réplicas.", call. = FALSE)
  }
  n_bootstrap <- vapply(replicas, function(x) as.integer(x$n_bootstrap), integer(1))
  n_originals <- vapply(replicas, function(x) as.integer(x$n_original), integer(1))
  index_lengths <- vapply(replicas, function(x) length(x$index), integer(1))
  if (any(n_bootstrap != sample_size) || any(index_lengths != sample_size) ||
      any(n_originals != n_original)) {
    stop("Alguma réplica não usou amostra de tamanho ", sample_size,
         " ou não avaliou a base original completa.", call. = FALSE)
  }
  statuses <- vapply(replicas, function(x) x$status, character(1))
  n_valid <- sum(statuses == "valid")
  if (n_valid < min_valid) {
    stop("Somente ", n_valid, " de ", times,
         " réplicas válidas; mínimo exigido: ", min_valid, ".", call. = FALSE)
  }
  if (any(!statuses %in% c("valid", "failed"))) {
    stop("Há status de réplica não reconhecido.", call. = FALSE)
  }
  data.frame(
    attempts = times, valid = n_valid, failed = times - n_valid,
    validity_rate = n_valid / times, sample_size = sample_size,
    n_original = n_original, minimum_valid = min_valid,
    criterion_met = n_valid >= min_valid, stringsAsFactors = FALSE
  )
}

bootstrap_replicate_table_with_model <- function(replicas, model) {
  table <- bootstrap_replica_table(replicas)
  table$model <- model
  table <- table[, c("model", setdiff(names(table), "model")), drop = FALSE]
  if ("started_at" %in% names(replicas[[1]])) {
    table$started_at <- as.character(vapply(replicas, function(x) format(x$started_at, "%Y-%m-%d %H:%M:%OS3 %Z"), character(1)))
    table$finished_at <- as.character(vapply(replicas, function(x) format(x$finished_at, "%Y-%m-%d %H:%M:%OS3 %Z"), character(1)))
    table$elapsed_seconds <- vapply(replicas, function(x) as.numeric(x$elapsed_seconds), numeric(1))
  }
  table
}

plot_bootstrap_optimism <- function(summary_table, file, main_prefix) {
  metrics <- unique(summary_table$metric)
  grDevices::png(file, width = 1800, height = 1200, res = 160)
  old <- graphics::par(mfrow = c(ceiling(length(metrics) / 3), 3), mar = c(4, 4, 3, 1))
  on.exit({graphics::par(old); grDevices::dev.off()}, add = TRUE)
  for (metric in metrics) {
    values <- summary_table$optimism_values[[match(metric, summary_table$metric)]]
    values <- values[is.finite(values)]
    if (!length(values)) {
      graphics::plot.new(); graphics::title(main = paste(main_prefix, metric, sep = " — "))
      graphics::text(0.5, 0.5, "sem réplicas válidas")
      next
    }
    graphics::hist(values, breaks = "FD", col = "#6BAED6", border = "white",
                   main = paste(main_prefix, metric, sep = " — "),
                   xlab = "Otimismo", ylab = "Número de réplicas")
    graphics::abline(v = mean(values), col = "#B33A3A", lwd = 2)
  }
  invisible(file)
}

consolidated_with_values <- function(replicas, apparent, directions) {
  summary <- consolidate_optimism(replicas, apparent, directions)
  summary$optimism_values <- lapply(names(apparent), function(metric) {
    values <- vapply(replicas, function(x) {
      if (identical(x$status, "valid") && is.finite(x$optimism[[metric]])) x$optimism[[metric]] else NA_real_
    }, numeric(1))
    values
  })
  summary
}

write_internal_validation_outputs <- function(linear_replicas, logistic_replicas, frozen_results,
                                              seed, times = 2000L, sample_size = 615L) {
  ensure_output_dirs()
  agg <- RESULTS_DIRS[["aggregated"]]
  fig <- RESULTS_DIRS[["figures"]]
  log_dir <- RESULTS_DIRS[["logs"]]
  obj <- RESULTS_DIRS[["reduced_objects"]]

  linear_apparent <- apparent_metrics_from_frozen(frozen_results, "linear")
  logistic_apparent <- apparent_metrics_from_frozen(frozen_results, "logistic")
  linear_summary <- consolidated_with_values(linear_replicas, linear_apparent,
                                             metric_directions("linear"))
  logistic_summary <- consolidated_with_values(logistic_replicas, logistic_apparent,
                                               metric_directions("logistic"))
  linear_summary_public <- linear_summary[, setdiff(names(linear_summary), "optimism_values"), drop = FALSE]
  logistic_summary_public <- logistic_summary[, setdiff(names(logistic_summary), "optimism_values"), drop = FALSE]
  linear_summary_public$model <- "linear"
  logistic_summary_public$model <- "logistic"
  summary_public <- rbind(linear_summary_public, logistic_summary_public)

  linear_table <- bootstrap_replicate_table_with_model(linear_replicas, "linear")
  logistic_table <- bootstrap_replicate_table_with_model(logistic_replicas, "logistic")
  bind_fill <- function(...) {
    tables <- list(...)
    columns <- unique(unlist(lapply(tables, names)))
    tables <- lapply(tables, function(table) {
      missing <- setdiff(columns, names(table))
      for (column in missing) table[[column]] <- NA
      table[, columns, drop = FALSE]
    })
    do.call(rbind, tables)
  }
  replicate_table <- bind_fill(linear_table, logistic_table)
  failure_log <- bind_fill(bootstrap_failure_log(linear_replicas, "linear"),
                           bootstrap_failure_log(logistic_replicas, "logistic"))
  warning_log <- bind_fill(bootstrap_warning_table(linear_replicas, "linear"),
                           bootstrap_warning_table(logistic_replicas, "logistic"))
  failure_summary <- rbind(
    transform(bootstrap_failure_summary(linear_replicas), model = "linear"),
    transform(bootstrap_failure_summary(logistic_replicas), model = "logistic")
  )
  validation <- rbind(
    transform(validate_bootstrap_contract(linear_replicas, times, sample_size), model = "linear"),
    transform(validate_bootstrap_contract(logistic_replicas, times, sample_size), model = "logistic")
  )

  utils::write.csv(replicate_table, file.path(agg, "frozen_bootstrap_replicates.csv"), row.names = FALSE, na = "")
  utils::write.csv(summary_public, file.path(agg, "frozen_bootstrap_optimism_summary.csv"), row.names = FALSE, na = "")
  utils::write.csv(failure_summary, file.path(agg, "frozen_bootstrap_failure_summary.csv"), row.names = FALSE, na = "")
  utils::write.csv(validation, file.path(agg, "frozen_bootstrap_validation.csv"), row.names = FALSE, na = "")
  utils::write.csv(failure_log, file.path(log_dir, "frozen_bootstrap_failures.csv"), row.names = FALSE, na = "")
  utils::write.csv(warning_log, file.path(log_dir, "frozen_bootstrap_warnings.csv"), row.names = FALSE, na = "")

  plot_bootstrap_optimism(linear_summary, file.path(fig, "frozen_bootstrap_optimism_linear.png"), "Linear")
  plot_bootstrap_optimism(logistic_summary, file.path(fig, "frozen_bootstrap_optimism_logistic.png"), "Logístico")

  internal <- list(
    metadata = list(seed = seed, times = times, sample_size = sample_size,
                    n_original = nrow(frozen_results$design),
                    predictor_names = MODEL_PREDICTORS,
                    formula_linear = frozen_results$models$formulas$linear,
                    formula_logistic = frozen_results$models$formulas$logistic,
                    source_sha256 = file_sha256(DATA_FILE)),
    linear = list(
      replicate = vapply(linear_replicas, `[[`, integer(1), "replicate"),
      seed = vapply(linear_replicas, `[[`, integer(1), "seed"),
      status = vapply(linear_replicas, `[[`, character(1), "status"),
      coefficients = lapply(linear_replicas, `[[`, "coefficients"),
      predictions_original = bootstrap_prediction_matrix(linear_replicas, n_original = nrow(frozen_results$design)),
      indices = bootstrap_index_matrix(linear_replicas, sample_size),
      table = linear_table,
      summary = linear_summary_public),
    logistic = list(
      replicate = vapply(logistic_replicas, `[[`, integer(1), "replicate"),
      seed = vapply(logistic_replicas, `[[`, integer(1), "seed"),
      status = vapply(logistic_replicas, `[[`, character(1), "status"),
      coefficients = lapply(logistic_replicas, `[[`, "coefficients"),
      predictions_original = bootstrap_prediction_matrix(logistic_replicas, n_original = nrow(frozen_results$design)),
      indices = bootstrap_index_matrix(logistic_replicas, sample_size),
      table = logistic_table,
      summary = logistic_summary_public)
  )
  saveRDS(internal, file.path(obj, "frozen_bootstrap_internal.rds"), compress = "xz")

  reduced <- list(metadata = internal$metadata, validation = validation,
                  apparent = rbind(data.frame(model = "linear", metric = names(linear_apparent),
                                              apparent = unname(linear_apparent)),
                                   data.frame(model = "logistic", metric = names(logistic_apparent),
                                              apparent = unname(logistic_apparent))),
                  optimism_summary = summary_public, failure_summary = failure_summary)
  saveRDS(reduced, file.path(obj, "frozen_internal_validation_reduced.rds"), compress = "xz")

  verification <- c(
    "Tarefa 06 — avaliação interna por bootstrap",
    paste("data_execucao:", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
    paste("seed:", seed), paste("tentativas_por_modelo:", times),
    paste("tamanho_amostra_bootstrap:", sample_size),
    paste("n_original:", nrow(frozen_results$design)),
    paste("linear_validas:", validation$valid[validation$model == "linear"]),
    paste("logistico_validas:", validation$valid[validation$model == "logistic"]),
    paste("linear_taxa_validade:", validation$validity_rate[validation$model == "linear"]),
    paste("logistico_taxa_validade:", validation$validity_rate[validation$model == "logistic"]),
    paste("linear_criterio_99_porcento:", validation$criterion_met[validation$model == "linear"]),
    paste("logistico_criterio_99_porcento:", validation$criterion_met[validation$model == "logistic"]),
    "Cada réplica reajusta a fórmula congelada sem seleção ou alteração de variáveis.",
    "Treino = desempenho na amostra bootstrap; teste = desempenho do mesmo ajuste na base original.",
    "As métricas corrigidas são avaliação interna por bootstrap e não validação externa.",
    "O objeto interno contém previsões e índices por réplica; tabelas agregadas não contêm IDs clínicos."
  )
  writeLines(verification, file.path(log_dir, "frozen_bootstrap_verification.txt"))
  invisible(list(linear = linear_summary_public, logistic = logistic_summary_public,
                 validation = validation, failures = failure_log, warnings = warning_log))
}
