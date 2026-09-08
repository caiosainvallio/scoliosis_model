#!/usr/bin/env Rscript

# Task 07: produz uma árvore CART ilustrativa legível e um resumo de
# estabilidade a partir dos insumos estruturais corrigidos da Task 06.
# Não executa tuning, validação cruzada ou qualquer ajuste de desempenho.

script_args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", script_args, value = TRUE)
script_path <- if (length(file_arg)) sub("^--file=", "", file_arg[[1]]) else "scripts/render_cart_revision.R"
project_root <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)

source(file.path(project_root, "R", "00_config.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "02_import_prepare.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "10_cart_nested.R"), local = .GlobalEnv)

if (!requireNamespace("readxl", quietly = TRUE) || !requireNamespace("rpart", quietly = TRUE)) {
  stop("A renderização CART requer readxl e rpart já instalados.", call. = FALSE)
}

review_root <- file.path(RESULTS_ROOT, "revisao")
aggregate_dir <- file.path(review_root, "aggregated")
figure_dir <- file.path(review_root, "figures")
dir.create(aggregate_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)

split_path <- file.path(aggregate_dir, "cart_illustrative_primary_splits.csv")
leaf_path <- file.path(aggregate_dir, "cart_illustrative_leaf_rules.csv")
frequency_path <- file.path(aggregate_dir, "cart_variable_frequency_summary.csv")
cutpoint_path <- file.path(aggregate_dir, "cart_cutpoint_summary.csv")
required <- c(split_path, leaf_path, frequency_path, cutpoint_path)
if (!all(file.exists(required))) stop("Insumos estruturais corrigidos da Task 06 ausentes.", call. = FALSE)

splits <- utils::read.csv(split_path, stringsAsFactors = FALSE, check.names = FALSE)
leaves <- utils::read.csv(leaf_path, stringsAsFactors = FALSE, check.names = FALSE)
frequency <- utils::read.csv(frequency_path, stringsAsFactors = FALSE, check.names = FALSE)
cutpoints <- utils::read.csv(cutpoint_path, stringsAsFactors = FALSE, check.names = FALSE)

pretty_variable <- c(
  correcao_colete = "Correção pelo colete (%)", risser = "Risser",
  lenke = "Classificação de Lenke", sexo = "Sexo",
  lordose_lombar = "Lordose lombar (°)", imc = "IMC (kg/m²)",
  cifose_toracica = "Cifose torácica (°)", idade = "Idade (anos)",
  escoliometro_maior_10_graus = "Escoliose no escoliômetro"
)
label_variable <- function(x) unname(ifelse(x %in% names(pretty_variable), pretty_variable[x], x))
format_number <- function(x, digits = 2L) format(round(as.numeric(x), digits), nsmall = digits, decimal.mark = ",", trim = TRUE)
format_levels <- function(x) gsub(" \\| ", ", ", x)
split_label <- function(row) {
  variable <- label_variable(row$variable)
  if (row$split_type == "continuous") {
    paste0(variable, " < ", format_number(row$cutpoint), if (row$variable == "correcao_colete") "%" else "")
  } else {
    paste0(variable, " em {", format_levels(row$left_levels), "}")
  }
}

# Reajuste único e determinístico com a configuração global já salva: apenas
# checa que as regras ilustrativas representam a árvore selecionada na coorte completa.
saved <- readRDS(file.path(RESULTS_DIRS[["reduced_objects"]], "cart_nested_internal.rds"))
cohort <- prepare_prognostic_data(import_prognostic_data())
recipe <- cart_preprocess_fit(cohort)
model <- cart_fit(cart_preprocess_apply(cohort, recipe), as.integer(cohort$delta_cat), saved$global_tuning$selected)
rebuilt <- cart_structure_tables(list(list(model = model, tree_id = 0L, repeat_id = NA_integer_, outer_fold = NA_integer_)),
                                 fit_origin = "full_cohort_illustrative_saved_hyperparameters")
if (!identical(splits$node, rebuilt$primary_splits$node) || !identical(leaves$leaf_node, rebuilt$leaf_rules$leaf_node)) {
  stop("A árvore ilustrativa reconstruída não coincide com os insumos estruturais da Task 06.", call. = FALSE)
}
if (sum(leaves$node_n) != nrow(cohort) || sum(leaves$event_n) != sum(cohort$delta_cat == 1L)) {
  stop("As contagens das folhas não coincidem com a coorte ilustrativa.", call. = FALSE)
}

cart_leaves <- data.frame(
  folha = paste0("Folha ", leaves$leaf_node),
  caminho_completo = vapply(seq_len(nrow(leaves)), function(i) {
    parts <- strsplit(leaves$rule[[i]], " & ", fixed = TRUE)[[1]]
    parts <- vapply(parts, function(part) {
      part <- sub("^correcao_colete", "Correção pelo colete (%)", part)
      part <- sub("^lordose_lombar", "Lordose lombar (°)", part)
      part <- sub("^risser", "Risser", part)
      part <- sub("^lenke", "Classificação de Lenke", part)
      sub("^sexo", "Sexo", part)
    }, character(1))
    paste(parts, collapse = " E ")
  }, character(1)),
  n = leaves$node_n,
  eventos_melhora = leaves$event_n,
  proporcao_aparente_melhora = leaves$event_probability,
  grupo_pequeno_n_menor_30 = ifelse(leaves$node_n < 30L, "sim", "não"),
  stringsAsFactors = FALSE
)
utils::write.csv(cart_leaves, file.path(aggregate_dir, "cart_leaves.csv"), row.names = FALSE, na = "")

tree_draw <- function() {
  all_nodes <- sort(unique(c(splits$node, leaves$leaf_node)))
  leaf_nodes <- leaves$leaf_node
  x <- setNames(numeric(length(all_nodes)), all_nodes)
  y <- setNames(-floor(log2(all_nodes)), all_nodes)
  x[as.character(leaf_nodes)] <- seq_along(leaf_nodes)
  internal <- rev(splits$node)
  for (node in internal) {
    child_x <- x[as.character(c(node * 2L, node * 2L + 1L))]
    child_x <- child_x[is.finite(child_x)]
    x[as.character(node)] <- mean(child_x)
  }
  graphics::plot.new()
  graphics::plot.window(xlim = c(0.35, length(leaf_nodes) + .65), ylim = c(-5.8, .7), xaxs = "i", yaxs = "i")
  graphics::title(main = "Árvore CART ilustrativa: melhora radiográfica ≥5°", cex.main = 1.35, line = 0.2)
  graphics::mtext("Ajustada na coorte completa (n=615); proporções nas folhas são aparentes.", side = 3, line = -1.1, cex = .88)
  for (node in splits$node) {
    for (child in c(node * 2L, node * 2L + 1L)) {
      if (as.character(child) %in% names(x) && is.finite(x[as.character(child)])) {
        graphics::segments(x[as.character(node)], y[as.character(node)] - .22, x[as.character(child)], y[as.character(child)] + .22, col = "gray45", lwd = 1.2)
      }
    }
  }
  for (i in seq_len(nrow(splits))) {
    node <- splits$node[[i]]
    graphics::rect(x[as.character(node)] - .62, y[as.character(node)] - .22, x[as.character(node)] + .62, y[as.character(node)] + .22,
                   col = "#E7F0F7", border = "#39729B", lwd = 1.1)
    graphics::text(x[as.character(node)], y[as.character(node)], split_label(splits[i, ]), cex = .72)
    for (side in 0:1) {
      child <- node * 2L + side
      if (as.character(child) %in% names(x)) {
        lx <- (x[as.character(node)] + x[as.character(child)]) / 2
        ly <- (y[as.character(node)] + y[as.character(child)]) / 2 + .08
        graphics::text(lx, ly, if (side == 0) "sim" else "não", cex = .60, col = "gray25")
      }
    }
  }
  for (i in seq_len(nrow(leaves))) {
    node <- leaves$leaf_node[[i]]
    small <- leaves$node_n[[i]] < 30L
    graphics::rect(x[as.character(node)] - .57, y[as.character(node)] - .24, x[as.character(node)] + .57, y[as.character(node)] + .24,
                   col = if (small) "#FFF1D5" else "#EAF5EA", border = if (small) "#B7791F" else "#477A47", lwd = 1.1)
    text <- paste0("Folha ", node, "\nMelhora: ", format_number(100 * leaves$event_probability[[i]], 1), "%\n",
                   leaves$event_n[[i]], "/", leaves$node_n[[i]], " eventos", if (small) " *" else "")
    graphics::text(x[as.character(node)], y[as.character(node)], text, cex = .63)
  }
  graphics::mtext("* grupo pequeno: n < 30; interpretar a proporção aparente com cautela.", side = 1, line = 1.1, cex = .75, adj = 0)
}

stability_draw <- function() {
  graphics::par(mfrow = c(1, 3), mar = c(5, 11, 3.8, 2), oma = c(0, 0, 0, 0))
  root <- frequency[frequency$scope == "root", , drop = FALSE]
  root <- root[order(root$relative_frequency), , drop = FALSE]
  graphics::barplot(root$relative_frequency, horiz = TRUE, names.arg = label_variable(root$variable), las = 1,
                    xlim = c(0, 1), col = "#39729B", border = NA, xlab = "Proporção das 50 árvores", main = "Variável na raiz")
  graphics::text(root$relative_frequency, seq_along(root$relative_frequency), labels = paste0(root$trees_with_variable, "/", root$denominator_trees), pos = 4, cex = .85)
  all <- frequency[frequency$scope == "all_levels", , drop = FALSE]
  all <- all[order(all$relative_frequency), , drop = FALSE]
  graphics::barplot(all$relative_frequency, horiz = TRUE, names.arg = label_variable(all$variable), las = 1,
                    xlim = c(0, 1), col = "#6A9E6A", border = NA, xlab = "Proporção das 50 árvores", main = "Variáveis em todos os níveis")
  graphics::text(all$relative_frequency, seq_along(all$relative_frequency), labels = paste0(all$trees_with_variable, "/", all$denominator_trees), pos = 4, cex = .78)
  root_cut <- cutpoints[cutpoints$scope == "root" & cutpoints$variable == "correcao_colete", , drop = FALSE]
  if (nrow(root_cut) != 1L) stop("Resumo corrigido do corte da raiz ausente ou duplicado.", call. = FALSE)
  graphics::plot(NA, xlim = c(root_cut$min - 1, root_cut$max + 1), ylim = c(.65, 1.35), yaxt = "n",
                 xlab = "Correção pelo colete (%)", ylab = "", main = "Corte primário na raiz",
                 sub = "amplitude, IQR e mediana; 50/50 árvores", cex.sub = .72)
  graphics::segments(root_cut$min, 1, root_cut$max, 1, lwd = 2, col = "gray45")
  graphics::segments(root_cut$q25, 1, root_cut$q75, 1, lwd = 8, col = "#C98B33")
  graphics::points(root_cut$median, 1, pch = 21, bg = "#B45520", cex = 1.8)
  graphics::text(root_cut$min, .78, paste0("mín. ", format_number(root_cut$min)), cex = .76, pos = 4)
  graphics::text(root_cut$median, 1.22, paste0("mediana ", format_number(root_cut$median)), cex = .76)
  graphics::text(root_cut$max, .78, paste0("máx. ", format_number(root_cut$max)), cex = .76, pos = 2)
  graphics::mtext("Estabilidade estrutural em 50 árvores externas; apenas cortes primários. Frequência não mede efeito causal.", side = 3, outer = TRUE, line = .2, cex = .88)
}

write_plot <- function(draw, png_path, svg_path, width, height) {
  grDevices::png(png_path, width = width, height = height, res = 300)
  draw(); grDevices::dev.off()
  grDevices::svg(svg_path, width = width / 300, height = height / 300, pointsize = 10)
  draw(); grDevices::dev.off()
}
write_plot(tree_draw, file.path(figure_dir, "cart_illustrative_tree.png"), file.path(figure_dir, "cart_illustrative_tree.svg"), 4200, 3000)
write_plot(stability_draw, file.path(figure_dir, "cart_stability.png"), file.path(figure_dir, "cart_stability.svg"), 4800, 1800)

checks <- c(
  leaves_sum_to_cohort = sum(cart_leaves$n) == 615L,
  leaf_events_sum_to_cohort_events = sum(cart_leaves$eventos_melhora) == 317L,
  probabilities_are_melhora = isTRUE(all.equal(leaves$event_probability, rebuilt$leaf_rules$event_probability, tolerance = 1e-12)),
  only_corrected_primary_summaries = all(frequency$denominator_trees == 50L),
  output_files_exist = all(file.exists(c(file.path(aggregate_dir, "cart_leaves.csv"), file.path(figure_dir, "cart_illustrative_tree.png"), file.path(figure_dir, "cart_illustrative_tree.svg"), file.path(figure_dir, "cart_stability.png"), file.path(figure_dir, "cart_stability.svg"))))
)
if (!all(checks)) stop("Falhou uma verificação da visualização CART.", call. = FALSE)
cat(paste(names(checks), checks, sep = ": "), sep = "\n")
