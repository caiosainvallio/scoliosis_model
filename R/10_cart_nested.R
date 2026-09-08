# CART exploratória com validação cruzada aninhada.
#
# A camada externa é usada somente para avaliação. Todo pré-processamento e
# todo tuning ocorre novamente dentro do treinamento externo correspondente.
# A implementação usa rpart diretamente para manter a grade e a seleção
# explícitas e auditáveis.

cart_requirements <- function() {
  if (!requireNamespace("rpart", quietly = TRUE)) {
    stop("A Tarefa 08 requer o pacote rpart; nenhuma instalação é feita automaticamente.", call. = FALSE)
  }
  invisible(TRUE)
}

cart_stratified_fold_assignment <- function(y, v = 10L, seed = GLOBAL_SEED) {
  y <- as.integer(as.factor(y)) - 1L
  if (length(y) < v || v < 2L) stop("É necessário haver pelo menos v observações.", call. = FALSE)
  if (anyNA(y) || length(unique(y)) != 2L) {
    stop("A estratificação da CART exige um desfecho binário completo.", call. = FALSE)
  }
  with_fixed_seed(seed, {
    assignment <- integer(length(y))
    for (level in sort(unique(y))) {
      rows <- which(y == level)
      # Cada classe é distribuída de forma balanceada entre os folds.
      assignment[rows] <- sample(rep(seq_len(v), length.out = length(rows)))
    }
    assignment
  })
}

cart_inner_splits <- function(rows, y, v = 5L, seed = GLOBAL_SEED) {
  assignment <- cart_stratified_fold_assignment(y[rows], v = v, seed = seed)
  lapply(seq_len(v), function(fold) {
    list(
      fold = fold,
      train = rows[assignment != fold],
      validation = rows[assignment == fold]
    )
  })
}

cart_nested_resample_indices <- function(
    n,
    y,
    outer = 10L,
    repeats = 5L,
    inner = 5L,
    seed = GLOBAL_SEED) {
  if (length(n) != 1L || n < 2L || n != as.integer(n)) stop("n deve ser um inteiro positivo.", call. = FALSE)
  if (length(y) != n) stop("y deve ter n observações.", call. = FALSE)
  if (outer < 2L || repeats < 1L || inner < 2L) stop("Número de folds/repetições inválido.", call. = FALSE)
  out <- vector("list", outer * repeats)
  counter <- 0L
  for (repeat_id in seq_len(repeats)) {
    outer_assignment <- cart_stratified_fold_assignment(
      y, v = outer, seed = seed + repeat_id * 1000L
    )
    for (outer_fold in seq_len(outer)) {
      counter <- counter + 1L
      outer_train <- which(outer_assignment != outer_fold)
      outer_test <- which(outer_assignment == outer_fold)
      inner_splits <- cart_inner_splits(
        outer_train, y, v = inner,
        seed = seed + repeat_id * 100000L + outer_fold * 100L
      )
      out[[counter]] <- list(
        repeat_id = repeat_id,
        outer_fold = outer_fold,
        train = outer_train,
        test = outer_test,
        inner = inner_splits
      )
    }
  }
  class(out) <- c("cart_nested_indices", "list")
  validate_cart_nested_indices(out, y = y, n = n)
  out
}

validate_cart_nested_indices <- function(indices, y, n = length(y)) {
  if (length(indices) == 0L) stop("Nenhum fold foi fornecido.", call. = FALSE)
  all_test <- integer(0)
  for (split in indices) {
    if (length(intersect(split$train, split$test)) > 0L) stop("Treino e teste externos se sobrepõem.", call. = FALSE)
    if (!setequal(c(split$train, split$test), seq_len(n))) stop("O fold externo não cobre toda a coorte.", call. = FALSE)
    if (any(tabulate(y[split$test] + 1L, nbins = 2L) < 1L)) stop("Fold externo não estratificado.", call. = FALSE)
    if (length(split$inner) < 2L) stop("Folds internos insuficientes.", call. = FALSE)
    inner_seen <- integer(0)
    for (inner_split in split$inner) {
      if (length(intersect(inner_split$train, inner_split$validation)) > 0L) {
        stop("Treino e validação internos se sobrepõem.", call. = FALSE)
      }
      if (!setequal(c(inner_split$train, inner_split$validation), split$train)) {
        stop("O fold interno não está contido no treinamento externo.", call. = FALSE)
      }
      if (any(tabulate(y[inner_split$validation] + 1L, nbins = 2L) < 1L)) stop("Fold interno não estratificado.", call. = FALSE)
      inner_seen <- c(inner_seen, inner_split$validation)
    }
    if (!setequal(inner_seen, rep(split$train, length(split$inner) / length(split$train)))) {
      # A checagem acima não depende da ordem: cada linha deve aparecer uma vez
      # por fold interno, portanto a tabela de frequências é a forma robusta.
      counts <- table(factor(inner_seen, levels = split$train))
      if (any(counts != 1L)) stop("A cobertura dos folds internos é inválida.", call. = FALSE)
    }
    all_test <- c(all_test, split$test)
  }
  expected_repeats <- length(indices) / max(vapply(indices, `[[`, integer(1), "outer_fold"))
  counts <- table(factor(all_test, levels = seq_len(n)))
  if (any(counts != expected_repeats)) stop("A cobertura externa por repetição é inválida.", call. = FALSE)
  invisible(TRUE)
}

cart_fold_summary_tables <- function(indices, y) {
  external <- do.call(rbind, lapply(indices, function(split) {
    data.frame(
      repeat_id = split$repeat_id, outer_fold = split$outer_fold,
      n_train = length(split$train), n_test = length(split$test),
      events_train = sum(y[split$train] == 1L), nonevents_train = sum(y[split$train] == 0L),
      events_test = sum(y[split$test] == 1L), nonevents_test = sum(y[split$test] == 0L),
      stringsAsFactors = FALSE
    )
  }))
  internal <- do.call(rbind, lapply(indices, function(split) {
    do.call(rbind, lapply(split$inner, function(inner_split) {
      data.frame(
        repeat_id = split$repeat_id, outer_fold = split$outer_fold,
        inner_fold = inner_split$fold,
        n_train = length(inner_split$train), n_validation = length(inner_split$validation),
        events_train = sum(y[inner_split$train] == 1L),
        nonevents_train = sum(y[inner_split$train] == 0L),
        events_validation = sum(y[inner_split$validation] == 1L),
        nonevents_validation = sum(y[inner_split$validation] == 0L),
        stringsAsFactors = FALSE
      )
    }))
  }))
  list(external = external, internal = internal)
}

cart_default_grid <- function() {
  grid <- expand.grid(
    cost_complexity = c(0.001, 0.005, 0.01, 0.02),
    tree_depth = 1L:5L,
    min_n = c(10L, 20L, 40L),
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  grid$config_id <- seq_len(nrow(grid))
  grid
}

cart_validate_grid <- function(grid) {
  required <- c("cost_complexity", "tree_depth", "min_n")
  if (!all(required %in% names(grid)) || !nrow(grid)) stop("Grade CART inválida.", call. = FALSE)
  if (any(!is.finite(grid$cost_complexity)) || any(grid$cost_complexity < 0) ||
      any(grid$tree_depth < 1) || any(grid$min_n < 2)) {
    stop("A grade CART contém hiperparâmetros inválidos.", call. = FALSE)
  }
  if (!"config_id" %in% names(grid)) grid$config_id <- seq_len(nrow(grid))
  grid
}

cart_preprocess_fit <- function(data, predictors = MODEL_PREDICTORS) {
  numeric_vars <- predictors[vapply(data[predictors], is.numeric, logical(1))]
  factor_vars <- setdiff(predictors, numeric_vars)
  medians <- setNames(vapply(numeric_vars, function(v) {
    value <- stats::median(data[[v]], na.rm = TRUE)
    if (!is.finite(value)) 0 else value
  }, numeric(1)), numeric_vars)
  modes <- setNames(vapply(factor_vars, function(v) {
    values <- as.character(data[[v]])
    values <- values[!is.na(values)]
    if (!length(values)) FACTOR_REFERENCES[[v]] else names(sort(table(values), decreasing = TRUE))[1]
  }, character(1)), factor_vars)
  list(predictors = predictors, numeric_vars = numeric_vars, factor_vars = factor_vars,
       medians = medians, modes = modes)
}

cart_preprocess_apply <- function(data, recipe) {
  out <- data[, recipe$predictors, drop = FALSE]
  for (v in recipe$numeric_vars) {
    out[[v]] <- as.numeric(out[[v]])
    out[[v]][is.na(out[[v]])] <- recipe$medians[[v]]
  }
  for (v in recipe$factor_vars) {
    values <- as.character(out[[v]])
    values[is.na(values)] <- recipe$modes[[v]]
    levels <- FACTOR_LEVELS[[v]]
    if (is.null(levels)) levels <- sort(unique(c(values, recipe$modes[[v]])))
    out[[v]] <- factor(values, levels = levels)
  }
  out
}

cart_outcome_factor <- function(y) {
  factor(ifelse(as.integer(y) == 1L, "melhora", "nao_melhora"),
         levels = c("nao_melhora", "melhora"))
}

cart_fit <- function(x, y, configuration) {
  cart_requirements()
  training <- x
  training$.cart_y <- cart_outcome_factor(y)
  control <- rpart::rpart.control(
    cp = configuration$cost_complexity,
    maxdepth = as.integer(configuration$tree_depth),
    minsplit = as.integer(configuration$min_n),
    xval = 0
  )
  suppressWarnings(rpart::rpart(.cart_y ~ ., data = training, method = "class",
                                control = control, model = TRUE))
}

cart_predict_probability <- function(model, x) {
  probabilities <- stats::predict(model, newdata = x, type = "prob")
  if (is.null(dim(probabilities))) {
    probabilities <- matrix(probabilities, ncol = 1L,
                            dimnames = list(NULL, names(probabilities)))
  }
  if (!"melhora" %in% colnames(probabilities)) {
    return(rep(mean(model$y == 2L), nrow(x)))
  }
  as.numeric(probabilities[, "melhora"])
}

cart_auc_value <- function(y, p) {
  if (exists("auc_rank", mode = "function")) return(auc_rank(y, p))
  event <- p[as.integer(y) == 1L]
  nonevent <- p[as.integer(y) == 0L]
  if (!length(event) || !length(nonevent)) return(NA_real_)
  mean(outer(event, nonevent, function(a, b) (a > b) + 0.5 * (a == b)))
}

cart_inner_tune <- function(training_data, y, inner_splits, grid = cart_default_grid()) {
  grid <- cart_validate_grid(grid)
  results <- vector("list", nrow(grid) * length(inner_splits))
  counter <- 0L
  for (g in seq_len(nrow(grid))) {
    configuration <- grid[g, , drop = FALSE]
    for (inner_split in inner_splits) {
      counter <- counter + 1L
      recipe <- cart_preprocess_fit(training_data[inner_split$train, , drop = FALSE])
      x_train <- cart_preprocess_apply(training_data[inner_split$train, , drop = FALSE], recipe)
      x_validation <- cart_preprocess_apply(training_data[inner_split$validation, , drop = FALSE], recipe)
      model <- cart_fit(x_train, y[inner_split$train], configuration)
      prediction <- cart_predict_probability(model, x_validation)
      results[[counter]] <- data.frame(
        config_id = configuration$config_id,
        inner_fold = inner_split$fold,
        auc = cart_auc_value(y[inner_split$validation], prediction),
        n_terminal = sum(model$frame$var == "<leaf>"),
        stringsAsFactors = FALSE
      )
    }
  }
  fold_results <- do.call(rbind, results)
  summary <- do.call(rbind, lapply(seq_len(nrow(grid)), function(g) {
    take <- fold_results$config_id == grid$config_id[[g]]
    aucs <- fold_results$auc[take]
    data.frame(
      config_id = grid$config_id[[g]],
      cost_complexity = grid$cost_complexity[[g]],
      tree_depth = grid$tree_depth[[g]],
      min_n = grid$min_n[[g]],
      mean_auc = mean(aucs, na.rm = TRUE),
      sd_auc = stats::sd(aucs, na.rm = TRUE),
      se_auc = stats::sd(aucs, na.rm = TRUE) / sqrt(sum(is.finite(aucs))),
      n_valid = sum(is.finite(aucs)),
      mean_terminal_nodes = mean(fold_results$n_terminal[take], na.rm = TRUE),
      stringsAsFactors = FALSE
    )
  }))
  summary$sd_auc[!is.finite(summary$sd_auc)] <- 0
  summary$se_auc[!is.finite(summary$se_auc)] <- 0
  selection <- cart_select_one_se(summary)
  list(selected = selection$selected, best = selection$best, threshold = selection$threshold,
       summary = selection$summary, fold_results = fold_results)
}

cart_select_one_se <- function(summary) {
  required <- c("config_id", "cost_complexity", "tree_depth", "min_n", "mean_auc", "se_auc", "n_valid")
  if (!all(required %in% names(summary)) || !nrow(summary)) stop("Resumo de tuning inválido.", call. = FALSE)
  simplicity_index <- order(summary$tree_depth, -summary$min_n,
                            -summary$cost_complexity, summary$config_id)
  summary$simplicity_order <- match(seq_len(nrow(summary)), simplicity_index)
  valid <- is.finite(summary$mean_auc) & summary$n_valid > 0L
  if (!any(valid)) stop("Nenhuma configuração CART teve AUC interna válida.", call. = FALSE)
  best <- summary[which(valid)[order(-summary$mean_auc[valid], summary$config_id[valid])][1L], , drop = FALSE]
  threshold <- best$mean_auc - best$se_auc
  eligible <- summary[valid & summary$mean_auc >= threshold, , drop = FALSE]
  selected <- eligible[order(eligible$simplicity_order, eligible$config_id), , drop = FALSE][1L, ]
  summary$best_mean_threshold <- threshold
  summary$eligible_one_se <- summary$config_id %in% eligible$config_id
  summary$selected_one_se <- summary$config_id == selected$config_id
  list(selected = selected, best = best, threshold = threshold, summary = summary)
}

cart_make_global_inner_splits <- function(y, v = 5L, seed = GLOBAL_SEED) {
  rows <- seq_along(y)
  cart_inner_splits(rows, y, v = v, seed = seed)
}

cart_safe_calibration <- function(y, p) {
  p <- pmin(pmax(as.numeric(p), 1e-15), 1 - 1e-15)
  lp <- stats::qlogis(p)
  intercept_fit <- tryCatch(
    suppressWarnings(stats::glm(y ~ 1 + offset(lp), family = stats::binomial())),
    error = function(e) NULL
  )
  slope_fit <- tryCatch(
    suppressWarnings(stats::glm(y ~ lp, family = stats::binomial())),
    error = function(e) NULL
  )
  intercept_value <- if (is.null(intercept_fit)) NA_real_ else {
    coefficient <- stats::coef(intercept_fit)
    if (length(coefficient) && is.finite(coefficient[[1]]) && abs(coefficient[[1]]) <= 100) coefficient[[1]] else NA_real_
  }
  slope_value <- if (is.null(slope_fit)) NA_real_ else {
    coefficient <- stats::coef(slope_fit)
    if (length(coefficient) >= 2L && is.finite(coefficient[[2]]) && abs(coefficient[[2]]) <= 100) coefficient[[2]] else NA_real_
  }
  c(
    calibration_intercept = unname(intercept_value),
    calibration_slope = unname(slope_value)
  )
}

cart_metric_row <- function(y, p, repeat_id = NA_integer_, outer_fold = NA_integer_, scope = "outer_fold") {
  calibration <- cart_safe_calibration(y, p)
  data.frame(
    scope = scope, repeat_id = repeat_id, outer_fold = outer_fold,
    n = length(y), events = sum(as.integer(y) == 1L), nonevents = sum(as.integer(y) == 0L),
    auc = cart_auc_value(y, p),
    brier_score = mean((as.integer(y) - p)^2),
    log_loss = -mean(as.integer(y) * log(pmin(pmax(p, 1e-15), 1 - 1e-15)) +
                       (1 - as.integer(y)) * log1p(-pmin(pmax(p, 1e-15), 1 - 1e-15))),
    calibration_intercept = calibration[["calibration_intercept"]],
    calibration_slope = calibration[["calibration_slope"]],
    stringsAsFactors = FALSE
  )
}

cart_external_metrics <- function(predictions) {
  groups <- split(predictions, list(predictions$repeat_id, predictions$outer_fold), drop = TRUE)
  by_fold <- do.call(rbind, lapply(groups, function(x) {
    cart_metric_row(x$observed, x$predicted, x$repeat_id[[1]], x$outer_fold[[1]], "outer_fold")
  }))
  by_repeat <- do.call(rbind, lapply(split(predictions, predictions$repeat_id), function(x) {
    cart_metric_row(x$observed, x$predicted, x$repeat_id[[1]], NA_integer_, "repeat_pooled")
  }))
  pooled <- cart_metric_row(predictions$observed, predictions$predicted,
                            NA_integer_, NA_integer_, "pooled_external_repeated")
  rbind(by_fold, by_repeat, pooled)
}

cart_metric_distribution <- function(metrics) {
  rows <- metrics[metrics$scope == "outer_fold", , drop = FALSE]
  do.call(rbind, lapply(c("auc", "brier_score", "log_loss", "calibration_intercept", "calibration_slope"), function(metric) {
    values <- rows[[metric]]
    data.frame(metric = metric, n = sum(is.finite(values)), mean = mean(values, na.rm = TRUE),
               sd = stats::sd(values, na.rm = TRUE), median = stats::median(values, na.rm = TRUE),
               q025 = stats::quantile(values, 0.025, na.rm = TRUE, names = FALSE),
               q975 = stats::quantile(values, 0.975, na.rm = TRUE, names = FALSE),
               stringsAsFactors = FALSE)
  }))
}

cart_calibration_curve <- function(predictions, groups = 10L) {
  order_rows <- order(predictions$predicted, predictions$id, predictions$repeat_id, predictions$outer_fold)
  bins <- integer(nrow(predictions)); bins[order_rows] <- ceiling(seq_along(order_rows) / (nrow(predictions) / groups))
  bins <- pmin(bins, groups)
  do.call(rbind, lapply(sort(unique(bins)), function(g) {
    take <- bins == g
    data.frame(group = g, n = sum(take), mean_predicted = mean(predictions$predicted[take]),
               mean_observed = mean(predictions$observed[take]), stringsAsFactors = FALSE)
  }))
}

cart_tree_summary <- function(model, tree_id, repeat_id = NA_integer_, outer_fold = NA_integer_) {
  frame <- model$frame
  nodes <- as.integer(row.names(frame))
  depth <- floor(log2(nodes))
  split_nodes <- frame$var != "<leaf>"
  data.frame(
    tree_id = tree_id, repeat_id = repeat_id, outer_fold = outer_fold,
    n_splits = sum(split_nodes), n_leaves = sum(!split_nodes),
    max_depth = if (any(split_nodes)) max(depth[split_nodes]) else 0L,
    root_variable = if (isTRUE(split_nodes[[1]])) as.character(frame$var[[1]]) else "<leaf>",
    no_split = !any(split_nodes), stringsAsFactors = FALSE
  )
}

cart_empty_split_table <- function() {
  data.frame(
    tree_id = integer(), repeat_id = integer(), outer_fold = integer(),
    fit_origin = character(), node = integer(), depth = integer(), node_n = integer(),
    variable = character(), split_role = character(), split_rank = integer(),
    count = numeric(), ncat = numeric(), improve = numeric(), index = numeric(),
    adjusted_agreement = numeric(), split_type = character(), cutpoint = numeric(),
    left_levels = character(), right_levels = character(),
    left_rule = character(), right_rule = character(), stringsAsFactors = FALSE
  )
}

cart_decode_split <- function(model, split_row, variable) {
  ncat <- as.numeric(split_row[["ncat"]])
  index <- as.numeric(split_row[["index"]])
  if (ncat < 2L) {
    left_operator <- if (ncat < 0) "<" else ">="
    right_operator <- if (ncat < 0) ">=" else "<"
    return(list(
      split_type = "continuous", cutpoint = index,
      left_levels = NA_character_, right_levels = NA_character_,
      left_rule = paste(variable, left_operator, format(index, digits = 17, trim = TRUE)),
      right_rule = paste(variable, right_operator, format(index, digits = 17, trim = TRUE))
    ))
  }
  csplit_row <- as.integer(index)
  if (is.null(model$csplit) || csplit_row < 1L || csplit_row > nrow(model$csplit)) {
    stop("Índice csplit inválido para a variável ", variable, ".", call. = FALSE)
  }
  xlevels <- attr(model, "xlevels")[[variable]]
  if (is.null(xlevels) && !is.null(model$model[[variable]]) && is.factor(model$model[[variable]])) {
    xlevels <- levels(model$model[[variable]])
  }
  codes <- model$csplit[csplit_row, seq_len(min(length(xlevels), ncol(model$csplit)))]
  left <- xlevels[codes == 1L]
  right <- xlevels[codes == 3L]
  left_text <- paste(left, collapse = " | ")
  right_text <- paste(right, collapse = " | ")
  list(
    split_type = "categorical", cutpoint = NA_real_,
    left_levels = left_text, right_levels = right_text,
    left_rule = paste0(variable, " in {", left_text, "}"),
    right_rule = paste0(variable, " in {", right_text, "}")
  )
}

cart_split_rows <- function(model, model_info,
                            fit_origin = "outer_training_saved_hyperparameters") {
  frame <- model$frame
  if (is.null(model$splits) || !nrow(model$splits) || all(frame$var == "<leaf>")) {
    return(cart_empty_split_table())
  }
  nodes <- as.integer(row.names(frame))
  is_leaf <- frame$var == "<leaf>"
  # Este é o mesmo índice documentado/usado por labels.rpart e summary.rpart:
  # para cada nó interno, primário, concorrentes e substitutos são consecutivos.
  starts <- cumsum(c(1L, frame$ncompete + frame$nsurrogate + !is_leaf))
  starts <- starts[seq_len(nrow(frame))]
  rows <- list()
  for (frame_row in which(!is_leaf)) {
    n_compete <- as.integer(frame$ncompete[[frame_row]])
    n_surrogate <- as.integer(frame$nsurrogate[[frame_row]])
    split_indices <- seq.int(starts[[frame_row]], length.out = 1L + n_compete + n_surrogate)
    roles <- c("primary", rep("competitor", n_compete), rep("surrogate", n_surrogate))
    ranks <- c(1L, seq_len(n_compete), seq_len(n_surrogate))
    for (j in seq_along(split_indices)) {
      matrix_row <- split_indices[[j]]
      variable <- row.names(model$splits)[[matrix_row]]
      decoded <- cart_decode_split(model, model$splits[matrix_row, ], variable)
      rows[[length(rows) + 1L]] <- data.frame(
        tree_id = model_info$tree_id, repeat_id = model_info$repeat_id,
        outer_fold = model_info$outer_fold, fit_origin = fit_origin,
        node = nodes[[frame_row]], depth = floor(log2(nodes[[frame_row]])),
        node_n = frame$n[[frame_row]], variable = variable,
        split_role = roles[[j]], split_rank = ranks[[j]],
        count = model$splits[matrix_row, "count"], ncat = model$splits[matrix_row, "ncat"],
        improve = model$splits[matrix_row, "improve"], index = model$splits[matrix_row, "index"],
        adjusted_agreement = model$splits[matrix_row, "adj"],
        split_type = decoded$split_type, cutpoint = decoded$cutpoint,
        left_levels = decoded$left_levels, right_levels = decoded$right_levels,
        left_rule = decoded$left_rule, right_rule = decoded$right_rule,
        stringsAsFactors = FALSE
      )
    }
  }
  out <- if (length(rows)) do.call(rbind, rows) else cart_empty_split_table()
  expected <- sum(!is_leaf) + sum(frame$ncompete[!is_leaf]) + sum(frame$nsurrogate[!is_leaf])
  if (nrow(out) != expected || nrow(out) != nrow(model$splits)) {
    stop("A travessia de model$splits não consumiu exatamente as linhas esperadas.", call. = FALSE)
  }
  out
}

cart_leaf_rules <- function(model, model_info, primary_splits,
                            fit_origin = "outer_training_saved_hyperparameters") {
  frame <- model$frame
  nodes <- as.integer(row.names(frame))
  leaf_rows <- which(frame$var == "<leaf>")
  ylevels <- attr(model, "ylevels")
  do.call(rbind, lapply(leaf_rows, function(frame_row) {
    leaf_node <- nodes[[frame_row]]
    current <- leaf_node
    rule_parts <- character()
    while (current > 1L) {
      parent <- current %/% 2L
      parent_split <- primary_splits[primary_splits$node == parent, , drop = FALSE]
      if (nrow(parent_split) != 1L) stop("Corte primário ausente ou duplicado no caminho da folha.", call. = FALSE)
      rule_parts <- c(if (current %% 2L == 0L) parent_split$left_rule else parent_split$right_rule, rule_parts)
      current <- parent
    }
    yval2 <- frame$yval2[frame_row, ]
    n_classes <- length(ylevels)
    class_counts <- if (n_classes) yval2[seq.int(2L, 1L + n_classes)] else numeric()
    class_probabilities <- if (n_classes) yval2[seq.int(2L + n_classes, 1L + 2L * n_classes)] else numeric()
    event_index <- if ("melhora" %in% ylevels) match("melhora", ylevels) else NA_integer_
    data.frame(
      tree_id = model_info$tree_id, repeat_id = model_info$repeat_id,
      outer_fold = model_info$outer_fold, fit_origin = fit_origin,
      leaf_node = leaf_node, depth = floor(log2(leaf_node)), node_n = frame$n[[frame_row]],
      predicted_class = if (length(ylevels)) ylevels[[as.integer(frame$yval[[frame_row]])]] else as.character(frame$yval[[frame_row]]),
      event_n = if (is.finite(event_index)) class_counts[[event_index]] else NA_real_,
      event_probability = if (is.finite(event_index)) class_probabilities[[event_index]] else NA_real_,
      rule = if (length(rule_parts)) paste(rule_parts, collapse = " & ") else "<root leaf>",
      stringsAsFactors = FALSE
    )
  }))
}

cart_structure_tables <- function(models, fit_origin = "outer_training_saved_hyperparameters") {
  split_rows <- list(); node_rows <- list(); leaf_rows <- list()
  for (i in seq_along(models)) {
    model_info <- models[[i]]
    model <- model_info$model
    frame <- model$frame
    nodes <- as.integer(row.names(frame))
    depths <- floor(log2(nodes))
    node_rows[[length(node_rows) + 1L]] <- data.frame(
      tree_id = model_info$tree_id, repeat_id = model_info$repeat_id, outer_fold = model_info$outer_fold,
      fit_origin = fit_origin, node = nodes, depth = depths, variable = as.character(frame$var),
      terminal = frame$var == "<leaf>", node_n = frame$n,
      stringsAsFactors = FALSE
    )
    all_splits <- cart_split_rows(model, model_info, fit_origin)
    split_rows[[length(split_rows) + 1L]] <- all_splits
    primary <- all_splits[all_splits$split_role == "primary", , drop = FALSE]
    leaf_rows[[length(leaf_rows) + 1L]] <- cart_leaf_rules(model, model_info, primary, fit_origin)
  }
  all_splits <- if (length(split_rows)) do.call(rbind, split_rows) else cart_empty_split_table()
  primary_splits <- all_splits[all_splits$split_role == "primary", , drop = FALSE]
  competitor_splits <- all_splits[all_splits$split_role == "competitor", , drop = FALSE]
  surrogate_splits <- all_splits[all_splits$split_role == "surrogate", , drop = FALSE]
  node_sizes <- do.call(rbind, node_rows)
  leaves <- do.call(rbind, leaf_rows)
  if (nrow(primary_splits) != sum(!node_sizes$terminal)) {
    stop("A contagem de cortes primários difere da contagem de nós internos.", call. = FALSE)
  }
  list(primary_splits = primary_splits, competitor_splits = competitor_splits,
       surrogate_splits = surrogate_splits, leaf_rules = leaves,
       variable_frequency = primary_splits, cutpoints = primary_splits[primary_splits$split_type == "continuous", , drop = FALSE],
       node_sizes = node_sizes)
}

cart_stability_summary <- function(tree_summaries, variable_frequency) {
  metrics <- data.frame(
    metric = c("trees", "trees_without_split", "trees_with_split", "root_variable_mode", "root_variable_mode_frequency"),
    value = c(nrow(tree_summaries), sum(tree_summaries$no_split), sum(!tree_summaries$no_split), NA, NA),
    stringsAsFactors = FALSE
  )
  roots <- tree_summaries$root_variable[tree_summaries$root_variable != "<leaf>"]
  if (length(roots)) {
    mode_root <- names(sort(table(roots), decreasing = TRUE))[1]
    metrics$value[metrics$metric == "root_variable_mode"] <- mode_root
    metrics$value[metrics$metric == "root_variable_mode_frequency"] <- sum(roots == mode_root)
  }
  root_frequency <- if (nrow(variable_frequency)) {
    as.data.frame(table(variable_frequency$variable[variable_frequency$depth == 0L]), stringsAsFactors = FALSE)
  } else data.frame(Var1 = character(), Freq = integer())
  if (nrow(root_frequency)) {
    names(root_frequency) <- c("variable", "frequency")
    root_frequency$relative_frequency <- root_frequency$frequency / nrow(tree_summaries)
  }
  list(summary = metrics, root_frequency = root_frequency)
}

cart_categorical_split_summary <- function(primary_splits, n_trees) {
  x <- primary_splits[primary_splits$split_type == "categorical", , drop = FALSE]
  if (!nrow(x)) return(data.frame(
    scope = character(), variable = character(), left_levels = character(), right_levels = character(),
    n_splits = integer(), trees_with_rule = integer(), denominator_trees = integer(),
    relative_trees = numeric(), stringsAsFactors = FALSE))
  x$scope <- ifelse(x$depth == 0L, "root", "non_root")
  x_all <- x; x_all$scope <- "all_levels"
  x <- rbind(x, x_all)
  groups <- split(x, list(x$scope, x$variable, x$left_levels, x$right_levels), drop = TRUE)
  out <- do.call(rbind, lapply(groups, function(g) data.frame(
    scope = g$scope[[1]], variable = g$variable[[1]], left_levels = g$left_levels[[1]],
    right_levels = g$right_levels[[1]], n_splits = nrow(g),
    trees_with_rule = length(unique(g$tree_id)), denominator_trees = n_trees,
    relative_trees = length(unique(g$tree_id)) / n_trees, stringsAsFactors = FALSE
  )))
  row.names(out) <- NULL
  out
}

cart_calibration_validity <- function(metrics, predictions = NULL) {
  folds <- metrics[metrics$scope == "outer_fold", , drop = FALSE]
  long <- do.call(rbind, lapply(c("calibration_intercept", "calibration_slope"), function(metric) {
    values <- folds[[metric]]
    data.frame(
      metric = metric, total_outer_folds = nrow(folds), valid_folds = sum(is.finite(values)),
      invalid_folds = sum(!is.finite(values)), denominator_summary = sum(is.finite(values)),
      treatment = "invalid excluded only from this metric summary",
      stringsAsFactors = FALSE
    )
  }))
  invalid <- do.call(rbind, lapply(seq_len(nrow(folds)), function(i) {
    bad <- c("calibration_intercept", "calibration_slope")[
      !is.finite(as.numeric(folds[i, c("calibration_intercept", "calibration_slope")]))
    ]
    if (!length(bad)) return(NULL)
    fold_predictions <- if (is.null(predictions)) NULL else predictions[
      predictions$repeat_id == folds$repeat_id[[i]] & predictions$outer_fold == folds$outer_fold[[i]], , drop = FALSE
    ]
    at_boundary <- if (is.null(fold_predictions)) NA_integer_ else sum(
      fold_predictions$predicted <= 1e-15 | fold_predictions$predicted >= 1 - 1e-15
    )
    data.frame(
      repeat_id = folds$repeat_id[[i]], outer_fold = folds$outer_fold[[i]],
      metric = bad,
      reason = ifelse(
        bad == "calibration_intercept" && is.finite(at_boundary) && at_boundary > 0L,
        "original glm offset fit returned an implausible coefficient (>100) after boundary predictions were clipped; numerical fit failure, not evidence that a finite intercept does not exist",
        "non-finite or implausible absolute coefficient (>100) in original glm fit"
      ),
      n_predictions = if (is.null(fold_predictions)) NA_integer_ else nrow(fold_predictions),
      n_at_boundary = at_boundary,
      min_predicted = if (is.null(fold_predictions)) NA_real_ else min(fold_predictions$predicted),
      max_predicted = if (is.null(fold_predictions)) NA_real_ else max(fold_predictions$predicted),
      stringsAsFactors = FALSE
    )
  }))
  if (is.null(invalid)) invalid <- data.frame(
    repeat_id = integer(), outer_fold = integer(), metric = character(), reason = character(),
    n_predictions = integer(), n_at_boundary = integer(), min_predicted = numeric(), max_predicted = numeric()
  )
  list(summary = long, invalid = invalid)
}

cart_refit_saved_outer_models <- function(cohort, saved) {
  if (length(saved$indices) != nrow(saved$selected)) {
    stop("O número de índices difere do número de hiperparâmetros salvos.", call. = FALSE)
  }
  models <- vector("list", length(saved$indices))
  summaries <- vector("list", length(saved$indices))
  for (i in seq_along(saved$indices)) {
    split <- saved$indices[[i]]
    selected <- saved$selected[
      saved$selected$repeat_id == split$repeat_id & saved$selected$outer_fold == split$outer_fold,
      , drop = FALSE
    ]
    if (nrow(selected) != 1L) stop("Hiperparâmetros salvos ausentes ou duplicados para um fold.", call. = FALSE)
    recipe <- cart_preprocess_fit(cohort[split$train, , drop = FALSE])
    x_train <- cart_preprocess_apply(cohort[split$train, , drop = FALSE], recipe)
    model <- cart_fit(x_train, as.integer(cohort$delta_cat[split$train]), selected)
    model_info <- list(model = model, tree_id = i, repeat_id = split$repeat_id, outer_fold = split$outer_fold)
    models[[i]] <- model_info
    summaries[[i]] <- cart_tree_summary(model, i, split$repeat_id, split$outer_fold)
  }
  tree_summaries <- do.call(rbind, summaries)
  if (!identical(tree_summaries[, c("tree_id", "repeat_id", "outer_fold", "n_splits", "n_leaves", "max_depth", "root_variable", "no_split")],
                 saved$tree_summaries[, c("tree_id", "repeat_id", "outer_fold", "n_splits", "n_leaves", "max_depth", "root_variable", "no_split")])) {
    stop("As árvores reconstruídas não reproduzem os resumos estruturais salvos.", call. = FALSE)
  }
  models
}

cart_review_structure_outputs <- function(models, saved, output_dir) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  tree_summaries <- do.call(rbind, lapply(models, function(x) cart_tree_summary(x$model, x$tree_id, x$repeat_id, x$outer_fold)))
  structures <- cart_structure_tables(models)
  n_trees <- nrow(tree_summaries)
  variable_summary <- cart_variable_frequency_summary(structures$primary_splits, n_trees)
  cutpoint_summary <- cart_cutpoint_summary(structures$cutpoints, n_trees)
  categorical_summary <- cart_categorical_split_summary(structures$primary_splits, n_trees)
  node_summary <- cart_node_size_summary(structures$node_sizes)
  stability <- cart_stability_summary(tree_summaries, structures$primary_splits)
  calibration_validity <- cart_calibration_validity(saved$metrics, saved$predictions)
  outputs <- list(
    cart_tree_summaries = tree_summaries,
    cart_primary_splits = structures$primary_splits,
    cart_competing_splits = structures$competitor_splits,
    cart_surrogate_splits = structures$surrogate_splits,
    cart_leaf_rules = structures$leaf_rules,
    cart_variable_frequency_summary = variable_summary,
    cart_cutpoint_summary = cutpoint_summary,
    cart_categorical_split_summary = categorical_summary,
    cart_node_size_summary = node_summary,
    cart_stability_summary = stability$summary,
    cart_root_frequency = stability$root_frequency,
    cart_calibration_validity_summary = calibration_validity$summary,
    cart_calibration_invalid_folds = calibration_validity$invalid
  )
  for (name in names(outputs)) {
    utils::write.csv(outputs[[name]], file.path(output_dir, paste0(name, ".csv")), row.names = FALSE, na = "")
  }
  list(structures = structures, outputs = outputs)
}

cart_variable_frequency_summary <- function(variable_frequency, n_trees = NULL) {
  if (is.null(n_trees)) n_trees <- length(unique(variable_frequency$tree_id))
  if (!nrow(variable_frequency)) return(data.frame(
    scope = character(), variable = character(), n_primary_splits = integer(),
    trees_with_variable = integer(), denominator_trees = integer(), relative_frequency = numeric(),
    stringsAsFactors = FALSE))
  scopes <- list(
    root = variable_frequency$depth == 0L,
    depths_1_2 = variable_frequency$depth %in% 1:2,
    deeper_than_2 = variable_frequency$depth > 2L,
    all_levels = rep(TRUE, nrow(variable_frequency))
  )
  out <- do.call(rbind, lapply(names(scopes), function(scope_name) {
    x <- variable_frequency[scopes[[scope_name]], , drop = FALSE]
    if (!nrow(x)) return(NULL)
    variables <- names(sort(table(x$variable), decreasing = TRUE))
    data.frame(
      scope = scope_name, variable = variables,
      n_primary_splits = as.integer(table(x$variable)[variables]),
      trees_with_variable = vapply(variables, function(variable) length(unique(x$tree_id[x$variable == variable])), integer(1)),
      denominator_trees = n_trees,
      relative_frequency = vapply(variables, function(variable) length(unique(x$tree_id[x$variable == variable])), integer(1)) / n_trees,
      stringsAsFactors = FALSE
    )
  }))
  row.names(out) <- NULL
  out
}

cart_cutpoint_summary <- function(cutpoints, n_trees) {
  if (!nrow(cutpoints)) {
    return(data.frame(scope = character(), variable = character(), n_splits = integer(), trees_with_cutpoint = integer(),
                      denominator_trees = integer(), relative_trees = numeric(), min = numeric(), median = numeric(),
                      q25 = numeric(), q75 = numeric(), max = numeric(), stringsAsFactors = FALSE))
  }
  scopes <- list(root = cutpoints$depth == 0L, non_root = cutpoints$depth > 0L,
                 all_levels = rep(TRUE, nrow(cutpoints)))
  do.call(rbind, lapply(names(scopes), function(scope_name) {
    scoped <- cutpoints[scopes[[scope_name]], , drop = FALSE]
    if (!nrow(scoped)) return(NULL)
    do.call(rbind, lapply(split(scoped, scoped$variable), function(x) data.frame(
      scope = scope_name, variable = x$variable[[1]], n_splits = nrow(x),
      trees_with_cutpoint = length(unique(x$tree_id)), denominator_trees = n_trees,
      relative_trees = length(unique(x$tree_id)) / n_trees,
      min = min(x$cutpoint), median = stats::median(x$cutpoint),
      q25 = stats::quantile(x$cutpoint, .25, names = FALSE),
      q75 = stats::quantile(x$cutpoint, .75, names = FALSE), max = max(x$cutpoint),
      stringsAsFactors = FALSE
    )))
  }))
}

cart_node_size_summary <- function(node_sizes) {
  do.call(rbind, lapply(split(node_sizes, list(node_sizes$terminal, node_sizes$depth), drop = TRUE), function(x) {
    data.frame(terminal = x$terminal[[1]], depth = x$depth[[1]], n_nodes = nrow(x),
               n_trees = length(unique(x$tree_id)), mean_node_n = mean(x$node_n),
               median_node_n = stats::median(x$node_n), min_node_n = min(x$node_n),
               max_node_n = max(x$node_n), stringsAsFactors = FALSE)
  }))
}

cart_write_figure <- function(calibration, path, title) {
  grDevices::png(path, width = 1500, height = 1100, res = 150)
  on.exit(grDevices::dev.off(), add = TRUE)
  graphics::plot(calibration$mean_predicted, calibration$mean_observed, type = "b",
                 pch = 19, xlim = c(0, 1), ylim = c(0, 1), xlab = "Probabilidade prevista",
                 ylab = "Frequência observada", main = title)
  graphics::abline(0, 1, lty = 2, col = "gray40")
  invisible(path)
}

cart_write_tree_figure <- function(model, path) {
  grDevices::png(path, width = 1800, height = 1400, res = 150)
  on.exit(grDevices::dev.off(), add = TRUE)
  graphics::plot(model, uniform = TRUE, main = "CART ilustrativa — regras exploratórias")
  graphics::text(model, use.n = TRUE, all = TRUE, cex = 0.8)
  invisible(path)
}

run_cart_nested_analysis <- function(
    cohort,
    ids = cohort$id,
    seed = GLOBAL_SEED + 808L,
    grid = cart_default_grid(),
    outer = 10L,
    repeats = 5L,
    inner = 5L,
    write_outputs = TRUE) {
  cart_requirements()
  if (!all(MODEL_PREDICTORS %in% names(cohort))) stop("Preditores congelados ausentes da coorte.", call. = FALSE)
  y <- as.integer(cohort$delta_cat)
  if (anyNA(y) || length(unique(y)) != 2L) stop("delta_cat inválido para CART.", call. = FALSE)
  indices <- cart_nested_resample_indices(nrow(cohort), y, outer, repeats, inner, seed)
  fold_summaries <- cart_fold_summary_tables(indices, y)
  selected_rows <- list(); prediction_rows <- list(); fitted_models <- list(); tree_info <- list()
  for (split in indices) {
    tuning <- cart_inner_tune(cohort[split$train, , drop = FALSE], y[split$train],
                              lapply(split$inner, function(x) list(
                                fold = x$fold,
                                train = match(x$train, split$train),
                                validation = match(x$validation, split$train)
                              )), grid)
    selected <- tuning$selected
    selected_rows[[length(selected_rows) + 1L]] <- data.frame(
      repeat_id = split$repeat_id, outer_fold = split$outer_fold,
      config_id = selected$config_id, cost_complexity = selected$cost_complexity,
      tree_depth = selected$tree_depth, min_n = selected$min_n,
      best_mean_auc = tuning$best$mean_auc, best_se_auc = tuning$best$se_auc,
      one_se_threshold = tuning$threshold, selected_mean_auc = selected$mean_auc,
      selected_se_auc = selected$se_auc, selected_mean_terminal_nodes = selected$mean_terminal_nodes,
      stringsAsFactors = FALSE
    )
    outer_recipe <- cart_preprocess_fit(cohort[split$train, , drop = FALSE])
    x_outer_train <- cart_preprocess_apply(cohort[split$train, , drop = FALSE], outer_recipe)
    x_outer_test <- cart_preprocess_apply(cohort[split$test, , drop = FALSE], outer_recipe)
    model <- cart_fit(x_outer_train, y[split$train], selected)
    prediction <- cart_predict_probability(model, x_outer_test)
    prediction_rows[[length(prediction_rows) + 1L]] <- data.frame(
      id = ids[split$test], observed = y[split$test], predicted = prediction,
      repeat_id = split$repeat_id, outer_fold = split$outer_fold,
      stringsAsFactors = FALSE
    )
    tree_id <- length(fitted_models) + 1L
    fitted_models[[tree_id]] <- list(model = model, tree_id = tree_id,
                                     repeat_id = split$repeat_id, outer_fold = split$outer_fold)
    tree_info[[tree_id]] <- cart_tree_summary(model, tree_id, split$repeat_id, split$outer_fold)
  }
  predictions <- do.call(rbind, prediction_rows)
  selected_table <- do.call(rbind, selected_rows)
  tree_summaries <- do.call(rbind, tree_info)
  structures <- cart_structure_tables(fitted_models)
  variable_frequency_summary <- cart_variable_frequency_summary(structures$variable_frequency, nrow(tree_summaries))
  cutpoint_summary <- cart_cutpoint_summary(structures$cutpoints, nrow(tree_summaries))
  node_size_summary <- cart_node_size_summary(structures$node_sizes)
  stability <- cart_stability_summary(tree_summaries, structures$variable_frequency)
  global_tuning <- cart_inner_tune(
    cohort, y, cart_make_global_inner_splits(y, v = inner, seed = seed + 999999L), grid
  )
  illustrative_configuration <- data.frame(
    uso = "somente_visualizacao_de_regras",
    config_id = global_tuning$selected$config_id,
    cost_complexity = global_tuning$selected$cost_complexity,
    tree_depth = global_tuning$selected$tree_depth,
    min_n = global_tuning$selected$min_n,
    stringsAsFactors = FALSE
  )
  final_recipe <- cart_preprocess_fit(cohort)
  final_x <- cart_preprocess_apply(cohort, final_recipe)
  illustrative_model <- cart_fit(final_x, y, global_tuning$selected)
  metrics <- cart_external_metrics(predictions)
  distribution <- cart_metric_distribution(metrics)
  calibration <- cart_calibration_curve(predictions)
  expected_prediction_keys <- do.call(rbind, lapply(indices, function(split) {
    data.frame(id = ids[split$test], repeat_id = split$repeat_id,
               outer_fold = split$outer_fold, stringsAsFactors = FALSE)
  }))
  observed_prediction_keys <- predictions[, c("id", "repeat_id", "outer_fold"), drop = FALSE]
  key_text <- function(x) paste(x$id, x$repeat_id, x$outer_fold, sep = "|")
  prediction_keys_match <- nrow(expected_prediction_keys) == nrow(observed_prediction_keys) &&
    identical(sort(key_text(expected_prediction_keys)), sort(key_text(observed_prediction_keys)))
  audit <- data.frame(
    evidencia = c(
      "external_test_disjoint_external_train", "inner_folds_contained_in_external_train",
      "one_se_rule_deterministic", "external_predictions_only_for_outer_test",
      "metrics_from_external_predictions", "illustrative_tree_not_external_evaluation",
      "no_progression_model"
    ),
    aprovado = c(TRUE, TRUE, TRUE,
                 prediction_keys_match,
                 all(metrics$scope %in% c("outer_fold", "repeat_pooled", "pooled_external_repeated")),
                 TRUE, TRUE),
    stringsAsFactors = FALSE
  )
  if (write_outputs) {
    ensure_output_dirs()
    utils::write.csv(fold_summaries$external, file.path(RESULTS_DIRS[["logs"]], "cart_external_fold_summary.csv"), row.names = FALSE, na = "")
    utils::write.csv(fold_summaries$internal, file.path(RESULTS_DIRS[["logs"]], "cart_internal_fold_summary.csv"), row.names = FALSE, na = "")
    utils::write.csv(selected_table, file.path(RESULTS_DIRS[["aggregated"]], "cart_selected_hyperparameters.csv"), row.names = FALSE, na = "")
    utils::write.csv(metrics, file.path(RESULTS_DIRS[["aggregated"]], "cart_external_metrics.csv"), row.names = FALSE, na = "")
    utils::write.csv(distribution, file.path(RESULTS_DIRS[["aggregated"]], "cart_external_metric_distribution.csv"), row.names = FALSE, na = "")
    utils::write.csv(calibration, file.path(RESULTS_DIRS[["aggregated"]], "cart_external_calibration.csv"), row.names = FALSE, na = "")
    utils::write.csv(tuning_to_table(global_tuning), file.path(RESULTS_DIRS[["aggregated"]], "cart_global_tuning.csv"), row.names = FALSE, na = "")
    utils::write.csv(illustrative_configuration, file.path(RESULTS_DIRS[["aggregated"]], "cart_illustrative_configuration.csv"), row.names = FALSE, na = "")
    utils::write.csv(tree_summaries, file.path(RESULTS_DIRS[["aggregated"]], "cart_tree_summaries.csv"), row.names = FALSE, na = "")
    utils::write.csv(variable_frequency_summary, file.path(RESULTS_DIRS[["aggregated"]], "cart_variable_frequency_summary.csv"), row.names = FALSE, na = "")
    utils::write.csv(cutpoint_summary, file.path(RESULTS_DIRS[["aggregated"]], "cart_cutpoint_summary.csv"), row.names = FALSE, na = "")
    utils::write.csv(node_size_summary, file.path(RESULTS_DIRS[["aggregated"]], "cart_node_size_summary.csv"), row.names = FALSE, na = "")
    utils::write.csv(stability$summary, file.path(RESULTS_DIRS[["aggregated"]], "cart_stability_summary.csv"), row.names = FALSE, na = "")
    utils::write.csv(stability$root_frequency, file.path(RESULTS_DIRS[["aggregated"]], "cart_root_frequency.csv"), row.names = FALSE, na = "")
    utils::write.csv(audit, file.path(RESULTS_DIRS[["logs"]], "cart_nested_audit.csv"), row.names = FALSE, na = "")
    internal_predictions <- predictions[, c("observed", "predicted", "repeat_id", "outer_fold"), drop = FALSE]
    internal_predictions$participant_index <- match(predictions$id, ids)
    saveRDS(list(indices = indices, predictions = internal_predictions, selected = selected_table, metrics = metrics,
                 distribution = distribution, calibration = calibration, global_tuning = global_tuning,
                 illustrative_configuration = illustrative_configuration,
                 tree_summaries = tree_summaries, structures = structures,
                 variable_frequency_summary = variable_frequency_summary,
                 cutpoint_summary = cutpoint_summary, node_size_summary = node_size_summary,
                 stability = stability, audit = audit),
            file.path(RESULTS_DIRS[["reduced_objects"]], "cart_nested_internal.rds"))
    cart_write_figure(calibration, file.path(RESULTS_DIRS[["figures"]], "cart_external_calibration.png"),
                      "Calibração exploratória externa da CART")
    cart_write_tree_figure(illustrative_model, file.path(RESULTS_DIRS[["figures"]], "cart_illustrative_tree.png"))
  }
  list(indices = indices, fold_summaries = fold_summaries, selected = selected_table, predictions = predictions,
       metrics = metrics, distribution = distribution, calibration = calibration,
       tuning = global_tuning, illustrative_configuration = illustrative_configuration,
       illustrative_model = illustrative_model,
       tree_summaries = tree_summaries, structures = structures,
       variable_frequency_summary = variable_frequency_summary, cutpoint_summary = cutpoint_summary,
       node_size_summary = node_size_summary, stability = stability, audit = audit)
}

tuning_to_table <- function(tuning) {
  tuning$summary
}
