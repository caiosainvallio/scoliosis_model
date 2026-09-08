# Shrinkage, equações reproduzíveis e estabilidade das previsões.

clamp_shrinkage_factor <- function(slope) {
  if (length(slope) != 1L || !is.numeric(slope) || !is.finite(slope))
    stop("A inclinação de calibração deve ser um escalar finito.", call. = FALSE)
  min(1, max(0, as.numeric(slope)))
}

calibration_slope_corrected <- function(internal_validation, model) {
  model <- match.arg(model, c("linear", "logistic"))
  tab <- internal_validation[[model]]$summary
  row <- tab$metric == "calibration_slope"
  if (sum(row) != 1L || !is.finite(tab$corrected[row]))
    stop("Inclinação corrigida ausente para o modelo ", model, ".", call. = FALSE)
  as.numeric(tab$corrected[row])
}

.coefficient_names <- function(model) {
  beta <- stats::coef(model)
  if (is.null(names(beta)) || any(!nzchar(names(beta))))
    stop("O modelo precisa ter coeficientes nomeados.", call. = FALSE)
  beta
}

.assert_design_coefficients <- function(design, coefficients) {
  if (!identical(colnames(design), names(coefficients)))
    stop("A matriz de desenho e os coeficientes não têm a mesma ordenação.", call. = FALSE)
  if (!all(is.finite(design)) || any(!is.finite(coefficients)))
    stop("A matriz de desenho e os coeficientes devem ser finitos.", call. = FALSE)
}

recalibrate_linear_intercept <- function(observed, design, coefficients_nonintercept) {
  if (ncol(design) != length(coefficients_nonintercept) + 1L || !all(design[, 1L] == 1))
    stop("Matriz de desenho linear incompatível.", call. = FALSE)
  y <- as.numeric(observed)
  if (length(y) != nrow(design) || any(!is.finite(y))) stop("Desfecho linear inválido.", call. = FALSE)
  as.numeric(mean(y) - mean(design[, -1L, drop = FALSE] %*% coefficients_nonintercept))
}

recalibrate_logistic_intercept <- function(observed, design, coefficients_nonintercept,
                                           tolerance = 1e-12) {
  if (ncol(design) != length(coefficients_nonintercept) + 1L || !all(design[, 1L] == 1))
    stop("Matriz de desenho logística incompatível.", call. = FALSE)
  y <- as.numeric(observed)
  if (length(y) != nrow(design) || any(!is.finite(y)) || any(!y %in% c(0, 1)))
    stop("Desfecho logístico inválido.", call. = FALSE)
  prevalence <- mean(y)
  if (prevalence <= 0 || prevalence >= 1) stop("A prevalência deve estar entre 0 e 1.", call. = FALSE)
  eta_without_intercept <- as.numeric(design[, -1L, drop = FALSE] %*% coefficients_nonintercept)
  objective <- function(intercept) mean(stats::plogis(intercept + eta_without_intercept)) - prevalence
  lower <- -50; upper <- 50
  while (objective(lower) > 0) lower <- lower * 2
  while (objective(upper) < 0) upper <- upper * 2
  root <- stats::uniroot(objective, c(lower, upper), tol = tolerance)$root
  if (!is.finite(root) || abs(objective(root)) > 10 * tolerance)
    stop("Falha ao recalibrar o intercepto logístico.", call. = FALSE)
  as.numeric(root)
}

build_shrinkage_coefficient_table <- function(model, apparent_coefficients, shrunk_coefficients,
                                              factor, scale = c("linear", "logit")) {
  scale <- match.arg(scale)
  data.frame(
    model = if (scale == "linear") "linear" else "logistic", escala = scale,
    term = names(apparent_coefficients), coefficient_apparent = as.numeric(apparent_coefficients),
    shrinkage_factor = c(NA_real_, rep(factor, length(apparent_coefficients) - 1L)),
    coefficient_shrunk = as.numeric(shrunk_coefficients),
    odds_ratio_apparent = if (scale == "logit") exp(as.numeric(apparent_coefficients)) else NA_real_,
    odds_ratio_shrunk = if (scale == "logit") exp(as.numeric(shrunk_coefficients)) else NA_real_,
    stringsAsFactors = FALSE, row.names = NULL
  )
}

build_shrunk_linear_model <- function(fit, data, corrected_slope, factor_levels = NULL) {
  factor <- clamp_shrinkage_factor(corrected_slope)
  apparent <- .coefficient_names(fit)
  design <- stats::model.matrix(stats::delete.response(stats::terms(fit)), data)
  .assert_design_coefficients(design, apparent)
  shrunk <- apparent; shrunk[-1L] <- apparent[-1L] * factor
  response <- all.vars(stats::formula(fit))[[1L]]
  shrunk[[1L]] <- recalibrate_linear_intercept(data[[response]], design, shrunk[-1L])
  structure(list(model_type = "linear", formula = stats::formula(fit), coefficients = shrunk,
    apparent_coefficients = apparent, design_columns = colnames(design), shrinkage_factor = factor,
    corrected_calibration_slope = as.numeric(corrected_slope), intercept_apparent = unname(apparent[[1L]]),
    intercept_recalibrated = unname(shrunk[[1L]]), factor_levels = factor_levels,
    sigma = summary(fit)$sigma, df_residual = stats::df.residual(fit), design = design,
    observed_mean = mean(data[[response]]),
    coefficient_table = build_shrinkage_coefficient_table(fit, apparent, shrunk, factor, "linear")),
    class = c("shrunk_linear_model", "shrunk_prognostic_model"))
}

build_shrunk_logistic_model <- function(fit, data, corrected_slope, factor_levels = NULL) {
  factor <- clamp_shrinkage_factor(corrected_slope)
  apparent <- .coefficient_names(fit)
  design <- stats::model.matrix(stats::delete.response(stats::terms(fit)), data)
  .assert_design_coefficients(design, apparent)
  shrunk <- apparent; shrunk[-1L] <- apparent[-1L] * factor
  response <- all.vars(stats::formula(fit))[[1L]]
  shrunk[[1L]] <- recalibrate_logistic_intercept(data[[response]], design, shrunk[-1L])
  structure(list(model_type = "logistic", formula = stats::formula(fit), coefficients = shrunk,
    apparent_coefficients = apparent, design_columns = colnames(design), shrinkage_factor = factor,
    corrected_calibration_slope = as.numeric(corrected_slope), intercept_apparent = unname(apparent[[1L]]),
    intercept_recalibrated = unname(shrunk[[1L]]), factor_levels = factor_levels,
    observed_prevalence = mean(as.numeric(data[[response]])), design = design,
    coefficient_table = build_shrinkage_coefficient_table(fit, apparent, shrunk, factor, "logit")),
    class = c("shrunk_logistic_model", "shrunk_prognostic_model"))
}

.factorize_newdata <- function(newdata, factor_levels) {
  newdata <- as.data.frame(newdata, stringsAsFactors = FALSE)
  if (!is.null(factor_levels)) for (variable in intersect(names(factor_levels), names(newdata)))
    newdata[[variable]] <- factor(as.character(newdata[[variable]]), levels = factor_levels[[variable]])
  newdata
}

.newdata_design <- function(object, newdata) {
  newdata <- .factorize_newdata(newdata, object$factor_levels)
  terms <- stats::delete.response(stats::terms(object$formula))
  xlev <- object$factor_levels[intersect(names(object$factor_levels), all.vars(terms))]
  design <- stats::model.matrix(terms, newdata, xlev = xlev)
  if (!identical(colnames(design), object$design_columns))
    stop("newdata não reproduz as colunas da matriz de desenho.", call. = FALSE)
  design
}

predict.shrunk_linear_model <- function(object, newdata, interval = c("fit", "confidence", "prediction"),
                                        level = 0.95, ...) {
  interval <- match.arg(interval)
  if (level <= 0 || level >= 1) stop("level deve estar entre 0 e 1.", call. = FALSE)
  design <- .newdata_design(object, newdata)
  fit <- as.numeric(design %*% object$coefficients)
  if (interval == "fit") return(fit)
  warning(
    "Intervalo legado não validado: usa sigma/informação do ajuste aparente, assume homoscedasticidade e omite a incerteza do fator de shrinkage.",
    call. = FALSE
  )
  information_inverse <- solve(crossprod(object$design))
  leverage <- rowSums((design %*% information_inverse) * design)
  multiplier <- if (interval == "prediction") 1 else 0
  se <- object$sigma * sqrt(multiplier + leverage)
  critical <- stats::qt(1 - (1 - level) / 2, df = object$df_residual)
  data.frame(fit = fit, lower = fit - critical * se, upper = fit + critical * se,
             stringsAsFactors = FALSE)
}

predict.shrunk_logistic_model <- function(object, newdata, type = c("response", "link"), ...) {
  type <- match.arg(type)
  eta <- as.numeric(.newdata_design(object, newdata) %*% object$coefficients)
  if (type == "link") eta else stats::plogis(eta)
}

manual_prediction <- function(object, newdata, type = c("linear", "logistic")) {
  type <- match.arg(type)
  eta <- as.numeric(.newdata_design(object, newdata) %*% object$coefficients)
  if (type == "linear") eta else stats::plogis(eta)
}

equation_term_label <- function(term) {
  labels <- c("(Intercept)" = "1", idade = "idade", imc = "IMC", cifose_toracica = "cifose torácica",
    lordose_lombar = "lordose lombar", correcao_colete = "correção pelo colete",
    sexomasculino = "I(sexo = masculino)", lenke2 = "I(Lenke = 2)", lenke3 = "I(Lenke = 3)",
    lenke4 = "I(Lenke = 4)", lenke5 = "I(Lenke = 5)", lenke6 = "I(Lenke = 6)",
    risser1 = "I(Risser = 1)", risser2 = "I(Risser = 2)", risser3 = "I(Risser = 3)",
    risser4 = "I(Risser = 4)", flexibilidaderigido = "I(flexibilidade = rígido)",
    escoliometro_maior_10_graustoracica = "I(escoliômetro = torácica)",
    escoliometro_maior_10_grauslombar = "I(escoliômetro = lombar)",
    escoliometro_maior_10_graustoracica_lombar = "I(escoliômetro = torácica+lombar)")
  if (term %in% names(labels)) unname(labels[[term]]) else term
}

.signed_term <- function(coefficient, label, digits = 10L) {
  paste(if (coefficient >= 0) "+" else "-", formatC(abs(coefficient), format = "fg", digits = digits), "×", label)
}

equation_string <- function(object) {
  beta <- object$coefficients
  terms <- vapply(seq_along(beta)[-1L], function(i) .signed_term(beta[[i]], equation_term_label(names(beta)[[i]])), character(1))
  paste(c(formatC(beta[[1L]], format = "fg", digits = 10L), terms), collapse = " ")
}

make_equation_text <- function(linear, logistic) {
  c("Equações finais após shrinkage corrigido por otimismo", "",
    paste("Fator linear:", formatC(linear$shrinkage_factor, format = "fg", digits = 12)),
    paste("Fator logístico:", formatC(logistic$shrinkage_factor, format = "fg", digits = 12)), "",
    paste("Equação linear: delta_previsto =", equation_string(linear), "graus."),
    paste("Equação logística: eta =", equation_string(logistic), "; p(melhora) = plogis(eta)."),
    "Referências: sexo=feminino; Lenke=1; Risser=0; flexibilidade=flexível; escoliômetro=normal.",
    "Para calcular uma pessoa, use zero para a categoria de referência, multiplique cada preditor pelo coeficiente corrigido e some ao intercepto recalibrado.",
    "Shrinkage é validação interna e não substitui validação externa independente.",
    "O intervalo de confiança da média usa sigma × sqrt(h0); o intervalo de predição individual usa sigma × sqrt(1 + h0) e é mais amplo.",
    "Os intervalos lineares são expressos em graus de delta.")
}

make_synthetic_profiles <- function(cohort) {
  continuous <- list(idade = mean(cohort$idade), imc = mean(cohort$imc),
    cifose_toracica = mean(cohort$cifose_toracica), lordose_lombar = mean(cohort$lordose_lombar),
    correcao_colete = mean(cohort$correcao_colete))
  row <- function(sexo, lenke, risser, flexibilidade, escoliometro, scale = 1) data.frame(
    idade = continuous$idade + scale, imc = continuous$imc + scale / 2,
    cifose_toracica = continuous$cifose_toracica + 2 * scale,
    lordose_lombar = continuous$lordose_lombar - scale,
    correcao_colete = continuous$correcao_colete + 3 * scale,
    sexo = sexo, lenke = lenke, risser = risser, flexibilidade = flexibilidade,
    escoliometro_maior_10_graus = escoliometro, stringsAsFactors = FALSE)
  result <- rbind(row("feminino", "1", "0", "flexivel", "normal", 0),
    row("masculino", "3", "2", "rigido", "toracica", 1),
    row("feminino", "6", "4", "flexivel", "toracica_lombar", -1))
  result$case <- c("referencia_media", "perfil_masculino", "perfil_lenke6")
  result[, c("case", setdiff(names(result), "case")), drop = FALSE]
}

validate_shrinkage_recalibration <- function(linear, logistic, cohort, synthetic_profiles) {
  linear_pred <- predict(linear, cohort); logistic_pred <- predict(logistic, cohort)
  linear_manual <- manual_prediction(linear, synthetic_profiles, "linear")
  cases <- synthetic_profiles[, setdiff(names(synthetic_profiles), "case"), drop = FALSE]
  linear_function <- as.numeric(predict(linear, cases))
  logistic_manual <- manual_prediction(logistic, synthetic_profiles, "logistic")
  logistic_function <- as.numeric(predict(logistic, cases))
  data.frame(
    criterion = c("linear_mean_error", "logistic_prevalence_error", "linear_manual_max_abs_difference",
      "logistic_manual_max_abs_difference", "linear_factor_in_unit_interval", "logistic_factor_in_unit_interval"),
    value = c(mean(cohort$delta - linear_pred), mean(logistic_pred) - mean(cohort$delta_cat),
      max(abs(linear_manual - linear_function)), max(abs(logistic_manual - logistic_function)),
      as.numeric(linear$shrinkage_factor >= 0 && linear$shrinkage_factor <= 1),
      as.numeric(logistic$shrinkage_factor >= 0 && logistic$shrinkage_factor <= 1)),
    tolerance = c(1e-10, 1e-10, 1e-12, 1e-12, 0, 0),
    passed = c(abs(mean(cohort$delta - linear_pred)) <= 1e-10,
      abs(mean(logistic_pred) - mean(cohort$delta_cat)) <= 1e-10,
      max(abs(linear_manual - linear_function)) <= 1e-12,
      max(abs(logistic_manual - logistic_function)) <= 1e-12,
      linear$shrinkage_factor >= 0 && linear$shrinkage_factor <= 1,
      logistic$shrinkage_factor >= 0 && logistic$shrinkage_factor <= 1), stringsAsFactors = FALSE)
}

summarize_prediction_matrix <- function(predictions, model, threshold_quantile = 0.90) {
  predictions <- as.matrix(predictions)
  summary <- data.frame(participant_index = seq_len(ncol(predictions)), model = model,
    n_valid = colSums(is.finite(predictions)),
    prediction_mean = apply(predictions, 2L, mean, na.rm = TRUE),
    prediction_sd = apply(predictions, 2L, stats::sd, na.rm = TRUE),
    prediction_q025 = apply(predictions, 2L, stats::quantile, probs = 0.025, na.rm = TRUE, names = FALSE),
    prediction_median = apply(predictions, 2L, stats::median, na.rm = TRUE),
    prediction_q975 = apply(predictions, 2L, stats::quantile, probs = 0.975, na.rm = TRUE, names = FALSE),
    prediction_min = apply(predictions, 2L, min, na.rm = TRUE),
    prediction_max = apply(predictions, 2L, max, na.rm = TRUE), stringsAsFactors = FALSE)
  summary$instability_index_95 <- summary$prediction_q975 - summary$prediction_q025
  cutoff <- as.numeric(stats::quantile(summary$instability_index_95, threshold_quantile, names = FALSE, na.rm = TRUE))
  summary$instability_threshold_90 <- cutoff; summary$unstable_top10 <- summary$instability_index_95 >= cutoff
  summary
}

stability_distribution_summary <- function(summary) {
  pieces <- split(summary$instability_index_95, summary$model)
  do.call(rbind, lapply(names(pieces), function(model) {
    values <- pieces[[model]]; q <- stats::quantile(values, c(.05, .25, .5, .75, .95, .9))
    data.frame(model = model, index_unit = if (model == "linear") "graus de delta" else "probabilidade",
      p05 = unname(q[[1]]), p25 = unname(q[[2]]), median = unname(q[[3]]), p75 = unname(q[[4]]),
      p95 = unname(q[[5]]), maximum = max(values), threshold_90 = unname(q[[6]]),
      n_top10 = sum(values >= q[[6]]), stringsAsFactors = FALSE)
  }))
}

write_stability_figures <- function(summary, outdir) {
  linear <- summary[summary$model == "linear", , drop = FALSE]
  logistic <- summary[summary$model == "logistic", , drop = FALSE]
  grDevices::png(file.path(outdir, "frozen_stability_index.png"), 1800, 1000, res = 160)
  old <- graphics::par(mfrow = c(1, 2), mar = c(4, 4, 3, 1)); on.exit({ graphics::par(old); grDevices::dev.off() }, add = TRUE)
  graphics::hist(linear$instability_index_95, breaks = "FD", col = "#6BAED6", border = "white",
    main = "Instabilidade das previsões lineares", xlab = "Amplitude bootstrap 95% (graus)", ylab = "Participantes")
  graphics::abline(v = unique(linear$instability_threshold_90), col = "#B33A3A", lwd = 2)
  graphics::hist(logistic$instability_index_95, breaks = "FD", col = "#74C476", border = "white",
    main = "Instabilidade das probabilidades", xlab = "Amplitude bootstrap 95% (probabilidade)", ylab = "Participantes")
  graphics::abline(v = unique(logistic$instability_threshold_90), col = "#B33A3A", lwd = 2)
}

write_stability_interval_figure <- function(summary, outdir) {
  grDevices::png(file.path(outdir, "frozen_stability_intervals.png"), 1800, 1200, res = 160)
  old <- graphics::par(mfrow = c(2, 1), mar = c(4, 4, 3, 1)); on.exit({ graphics::par(old); grDevices::dev.off() }, add = TRUE)
  for (model in c("linear", "logistic")) {
    current <- summary[summary$model == model, , drop = FALSE]; current <- current[order(current$prediction_mean), , drop = FALSE]
    x <- seq_len(nrow(current)); ylab <- if (model == "linear") "delta previsto (graus)" else "Probabilidade de melhora"
    graphics::plot(x, current$prediction_mean, type = "n", xlab = "Participantes (ordenação anônima)", ylab = ylab,
      main = if (model == "linear") "Faixas bootstrap lineares" else "Faixas bootstrap logísticas")
    fill <- if (model == "linear") "#C6DBEF" else "#C7E9C0"
    graphics::polygon(c(x, rev(x)), c(current$prediction_q025, rev(current$prediction_q975)), col = fill, border = NA)
    graphics::lines(x, current$prediction_mean, col = "#2C5D7C", lwd = 1.5)
    graphics::lines(x, current$prediction_median, col = "#B33A3A", lwd = 1.2)
    graphics::legend("topleft", c("média", "mediana", "intervalo bootstrap 95%"), col = c("#2C5D7C", "#B33A3A", NA),
      lwd = c(1.5, 1.2, NA), fill = c(NA, NA, fill), bty = "n")
  }
}

write_prediction_intervals <- function(linear, cohort, output_file) {
  prediction <- predict(linear, cohort, interval = "prediction")
  confidence <- predict(linear, cohort, interval = "confidence")
  result <- data.frame(participant_index = seq_len(nrow(cohort)), fit_degrees = prediction$fit,
    confidence_mean_lower_degrees = confidence$lower, confidence_mean_upper_degrees = confidence$upper,
    prediction_lower_degrees = prediction$lower, prediction_upper_degrees = prediction$upper,
    prediction_interval_width_degrees = prediction$upper - prediction$lower, stringsAsFactors = FALSE)
  utils::write.csv(result, output_file, row.names = FALSE, na = ""); result
}

run_shrinkage_analysis <- function(frozen_results, internal_validation, cohort, factor_levels,
                                   stability_internal) {
  linear_slope <- calibration_slope_corrected(internal_validation, "linear")
  logistic_slope <- calibration_slope_corrected(internal_validation, "logistic")
  linear <- build_shrunk_linear_model(frozen_results$models$linear, cohort, linear_slope, factor_levels)
  logistic <- build_shrunk_logistic_model(frozen_results$models$logistic, cohort, logistic_slope, factor_levels)
  synthetic <- make_synthetic_profiles(cohort)
  validation <- validate_shrinkage_recalibration(linear, logistic, cohort, synthetic)
  stability <- rbind(summarize_prediction_matrix(stability_internal$linear$predictions_original, "linear"),
    summarize_prediction_matrix(stability_internal$logistic$predictions_original, "logistic"))
  shrinkage_summary <- data.frame(model = c("linear", "logistic"),
    calibration_slope_corrected = c(linear_slope, logistic_slope),
    shrinkage_factor = c(linear$shrinkage_factor, logistic$shrinkage_factor),
    intercept_apparent = c(linear$intercept_apparent, logistic$intercept_apparent),
    intercept_recalibrated = c(linear$intercept_recalibrated, logistic$intercept_recalibrated),
    target_observed = c(linear$observed_mean, logistic$observed_prevalence),
    target_predicted_after_recalibration = c(mean(predict(linear, cohort)), mean(predict(logistic, cohort))),
    stringsAsFactors = FALSE)
  list(linear = linear, logistic = logistic,
    coefficients = rbind(linear$coefficient_table, logistic$coefficient_table),
    shrinkage_summary = shrinkage_summary, synthetic_profiles = synthetic, validation = validation,
    stability = stability, stability_distribution = stability_distribution_summary(stability))
}

write_shrinkage_outputs <- function(analysis, cohort, output_root = RESULTS_DIRS) {
  agg <- output_root[["aggregated"]]; fig <- output_root[["figures"]]
  log_dir <- output_root[["logs"]]; obj <- output_root[["reduced_objects"]]
  invisible(lapply(output_root, dir.create, recursive = TRUE, showWarnings = FALSE))
  write <- function(x, file) utils::write.csv(x, file.path(agg, file), row.names = FALSE, na = "")
  write(analysis$shrinkage_summary, "frozen_shrinkage_summary.csv")
  write(analysis$coefficients, "frozen_coefficients_shrinkage.csv")
  write(analysis$linear$coefficient_table, "frozen_coefficients_linear_shrinkage.csv")
  write(analysis$logistic$coefficient_table, "frozen_coefficients_logit_shrinkage.csv")
  write(analysis$validation, "frozen_shrinkage_validation.csv")
  write(analysis$synthetic_profiles, "frozen_synthetic_profiles.csv")
  write(analysis$stability, "frozen_prediction_stability_summary.csv")
  write(analysis$stability_distribution, "frozen_prediction_stability_distribution.csv")
  write_prediction_intervals(analysis$linear, cohort, file.path(agg, "frozen_linear_prediction_intervals.csv"))
  writeLines(make_equation_text(analysis$linear, analysis$logistic), file.path(agg, "frozen_equations_shrunk.txt"))
  writeLines(c("Interpretação da Tarefa 07", "",
    "O fator de shrinkage é a inclinação de calibração corrigida por otimismo, limitada a [0, 1]. Se exceder 1, nenhum coeficiente é expandido.",
    "O intercepto linear preserva a média observada de delta; o intercepto logístico preserva a prevalência observada de melhora.",
    "A instabilidade individual é a amplitude entre os quantis 2,5% e 97,5% das previsões bootstrap aplicadas à base original. O maior décimo define a faixa mais instável.",
    "O intervalo de confiança descreve a média condicional; o intervalo de predição inclui a variabilidade de um novo desfecho individual e é mais amplo. Ambos estão em graus no modelo linear.",
    "Shrinkage é validação interna e não substitui validação externa independente antes do uso clínico."),
    file.path(agg, "frozen_shrinkage_interpretation.txt"))
  write_stability_figures(analysis$stability, fig); write_stability_interval_figure(analysis$stability, fig)
  saveRDS(list(metadata = list(n = nrow(cohort), predictor_names = MODEL_PREDICTORS),
    linear = analysis$linear, logistic = analysis$logistic, validation = analysis$validation,
    synthetic_profiles = analysis$synthetic_profiles, stability_distribution = analysis$stability_distribution),
    file.path(obj, "frozen_shrinkage_models.rds"), compress = "xz")
  saveRDS(analysis$stability, file.path(obj, "frozen_prediction_stability_reduced.rds"), compress = "xz")
  writeLines(c("Tarefa 07 — shrinkage, equações e estabilidade",
    paste("data_execucao:", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
    paste("linear_slope_corrected:", analysis$linear$corrected_calibration_slope),
    paste("linear_shrinkage_factor:", analysis$linear$shrinkage_factor),
    paste("logistic_slope_corrected:", analysis$logistic$corrected_calibration_slope),
    paste("logistic_shrinkage_factor:", analysis$logistic$shrinkage_factor),
    paste("max_validation_error:", max(abs(analysis$validation$value[seq_len(4L)]))),
    "Tabelas e gráficos públicos de estabilidade não contêm IDs clínicos.",
    "Shrinkage não substitui validação externa."), file.path(log_dir, "frozen_shrinkage_verification.txt"))
  invisible(analysis)
}
