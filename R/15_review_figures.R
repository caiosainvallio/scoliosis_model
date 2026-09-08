# Figuras da revisão (Task 12). Consome apenas objetos e agregados já auditados.
# Não reestima modelos nem transforma as cinco previsões repetidas por pessoa em
# cinco pessoas independentes. Execute com: Rscript --vanilla R/15_review_figures.R

root <- normalizePath(getwd())
source(file.path(root, "R", "02_import_prepare.R"))
source(file.path(root, "R", "11_flexible_modeling.R"))
review_root <- file.path(root, "results", "prognostico", "revisao")
agg <- file.path(review_root, "aggregated")
fig <- file.path(review_root, "figures")
dir.create(fig, recursive = TRUE, showWarnings = FALSE)

cols <- c(blue = "#0072B2", orange = "#D55E00", green = "#009E73", purple = "#CC79A7", grey = "#666666")
theme_review <- function() graphics::par(family = "sans", las = 1, bty = "l", col.axis = "#333333", col.lab = "#333333")
save_both <- function(name, draw, width = 1800, height = 1200, res = 180) {
  png_path <- file.path(fig, paste0(name, ".png")); svg_path <- file.path(fig, paste0(name, ".svg"))
  grDevices::png(png_path, width = width, height = height, res = res); theme_review(); draw(); grDevices::dev.off()
  grDevices::svg(svg_path, width = width / res, height = height / res); theme_review(); draw(); grDevices::dev.off()
  data.frame(file = basename(c(png_path, svg_path)), width_px = c(width, NA), height_px = c(height, NA), stringsAsFactors = FALSE)
}
read_csv <- function(name) utils::read.csv(file.path(agg, name), check.names = FALSE)
diag <- readRDS(file.path(review_root, "reduced_objects", "diagnostics_plot_data.rds"))
validation <- readRDS(file.path(review_root, "reduced_objects", "validation_review_reduced.rds"))
flex <- readRDS(file.path(review_root, "reduced_objects", "flexible_nested_internal.rds"))
coef_shrunk <- read_csv("validation_final_shrinkage_coefficients.csv")
coef_hc3 <- read_csv("coefficients_linear_hc3.csv")
sensitivity <- read_csv("sensitivity_resampling_metrics_summary.csv")

# A distribuição e os gráficos aparentes usam exatamente 615 linhas por modelo.
lin <- diag$influence[diag$influence$model == "linear", ]
logi <- diag$influence[diag$influence$model == "logistic", ]
stopifnot(nrow(lin) == 615L, nrow(logi) == 615L)
manifest <- list()

manifest[[length(manifest) + 1L]] <- save_both("linear_delta_distribution", function() {
  old <- graphics::par(mar = c(4.5, 4.8, 3.5, 1)); on.exit(graphics::par(old))
  graphics::hist(lin$observed, breaks = "FD", col = cols[["blue"]], border = "white", main = "Distribuição de delta", xlab = "Delta: maior Cobb aos 6 meses − basal (graus)", ylab = "Participantes (n=615)")
  graphics::abline(v = c(-5, 0, 5), lty = c(2, 3, 2), col = c(cols[["orange"]], cols[["grey"]], cols[["grey"]]), lwd = 2)
  graphics::legend("topright", c("melhora ≥5°", "sem mudança", "+5°"), lty = c(2, 3, 2), col = c(cols[["orange"]], cols[["grey"]], cols[["grey"]]), bty = "n")
})

manifest[[length(manifest) + 1L]] <- save_both("linear_observed_predicted", function() {
  old <- graphics::par(mar = c(4.5, 4.8, 3.5, 1)); on.exit(graphics::par(old))
  graphics::plot(lin$predicted, lin$observed, pch = 16, cex = .55, col = grDevices::adjustcolor(cols[["blue"]], .45), xlab = "Delta previsto (graus)", ylab = "Delta observado (graus)", main = "Modelo linear: observado versus previsto (aparente; n=615)")
  graphics::abline(0, 1, lty = 2, lwd = 2, col = cols[["orange"]]); graphics::abline(stats::lm(observed ~ predicted, lin), lwd = 2, col = cols[["green"]])
  graphics::legend("topleft", c("identidade", "calibração aparente"), lty = c(2, 1), lwd = 2, col = c(cols[["orange"]], cols[["green"]]), bty = "n")
})

manifest[[length(manifest) + 1L]] <- save_both("linear_diagnostics", function() {
  old <- graphics::par(mfrow = c(2, 2), mar = c(4, 4.4, 2.5, .8)); on.exit(graphics::par(old))
  graphics::plot(lin$predicted, lin$residual, pch = 16, cex = .45, col = grDevices::adjustcolor(cols[["blue"]], .4), xlab = "Ajustado (graus)", ylab = "Resíduo (graus)", main = "Resíduos")
  rs <- diag$residual_smooth[diag$residual_smooth$panel == "residuo_vs_ajustado", ]; graphics::lines(rs$x, rs$smooth, col = cols[["orange"]], lwd = 2); graphics::abline(h = 0, lty = 2)
  graphics::plot(diag$qq$theoretical_quantile, diag$qq$standardized_residual_quantile, pch = 16, cex = .45, col = grDevices::adjustcolor(cols[["blue"]], .5), xlab = "Quantil normal teórico", ylab = "Resíduo padronizado", main = "Q–Q linear"); graphics::abline(0, 1, lty = 2, col = cols[["orange"]], lwd = 2)
  graphics::plot(lin$leverage, lin$standardized_residual, pch = 16, cex = .45, col = ifelse(lin$influential_any, cols[["orange"]], grDevices::adjustcolor(cols[["blue"]], .45)), xlab = "Alavancagem", ylab = "Resíduo padronizado", main = "Influência (aparente)"); graphics::abline(h = c(-2, 2), lty = 2)
  graphics::plot(diag$variance_pattern$fitted_mean, diag$variance_pattern$residual_sd, type = "b", pch = 16, col = cols[["purple"]], xlab = "Ajustado médio por quintil", ylab = "DP residual (graus)", main = "Dispersão por quintil")
})

# HC3 é o único IC linear apresentado; shrinkage final não recebe IC aparente.
manifest[[length(manifest) + 1L]] <- save_both("linear_coefficients_hc3", function() {
  d <- coef_hc3[coef_hc3$term != "(Intercept)", ]; d <- d[order(d$estimate), ]; y <- seq_len(nrow(d))
  old <- graphics::par(mar = c(5, 10, 3, 1)); on.exit(graphics::par(old))
  graphics::plot(d$estimate, y, xlim = range(c(d$conf_low, d$conf_high)), ylim = c(.5, nrow(d) + .5), yaxt = "n", pch = 16, col = cols[["blue"]], xlab = "Coeficiente (graus de delta; IC 95% HC3)", ylab = "", main = "Coeficientes lineares aparentes com inferência HC3")
  graphics::segments(d$conf_low, y, d$conf_high, y, col = cols[["blue"]], lwd = 2); graphics::axis(2, y, labels = d$term, las = 2, cex.axis = .75); graphics::abline(v = 0, lty = 2, col = cols[["orange"]])
})

manifest[[length(manifest) + 1L]] <- save_both("logistic_roc_calibration", function() {
  old <- graphics::par(mfrow = c(1, 2), mar = c(4.5, 4.8, 3.5, 1)); on.exit(graphics::par(old))
  ord <- order(logi$predicted, decreasing = TRUE); y <- as.integer(logi$observed[ord]); tpr <- c(0, cumsum(y) / sum(y)); fpr <- c(0, cumsum(1-y) / sum(1-y))
  graphics::plot(fpr, tpr, type = "l", lwd = 2.5, col = cols[["blue"]], xlab = "1 − especificidade", ylab = "Sensibilidade", main = "ROC aparente (n=615)"); graphics::abline(0, 1, lty = 2, col = cols[["grey"]])
  groups <- cut(logi$predicted, breaks = unique(stats::quantile(logi$predicted, seq(0, 1, .1))), include.lowest = TRUE); gp <- aggregate(cbind(predicted, observed) ~ groups, logi, mean)
  graphics::plot(gp$predicted, gp$observed, xlim = 0:1, ylim = 0:1, pch = 16, col = cols[["blue"]], xlab = "Probabilidade prevista", ylab = "Frequência observada", main = "Calibração aparente (sem banda)"); graphics::lines(stats::lowess(logi$predicted, logi$observed, f = 2/3), col = cols[["green"]], lwd = 2); graphics::abline(0, 1, lty = 2, col = cols[["orange"]]); graphics::rug(logi$predicted, col = grDevices::adjustcolor(cols[["blue"]], .35))
})

manifest[[length(manifest) + 1L]] <- save_both("logistic_coefficients_shrunk", function() {
  d <- coef_shrunk[coef_shrunk$model == "logistic" & coef_shrunk$term != "(Intercept)", ]
  continuous <- c("idade", "imc", "cifose_toracica", "lordose_lombar", "correcao_colete")
  d$contrast_units <- ifelse(d$term %in% continuous, 10, 1)
  d$or_contrast <- exp(d$coefficient_shrunk * d$contrast_units); d <- d[order(d$or_contrast), ]; y <- seq_len(nrow(d))
  old <- graphics::par(mar = c(5, 10, 3, 1)); on.exit(graphics::par(old))
  graphics::plot(d$or_contrast, y, log = "x", xlim = range(d$or_contrast), ylim = c(.5, nrow(d) + .5), yaxt = "n", pch = 16, col = cols[["green"]], xlab = "OR pós-shrinkage; contínuos por +10 unidades (correção: +10 p.p.)", ylab = "", main = "Contrastes logísticos pós-shrinkage (sem IC)")
  graphics::axis(2, y, labels = d$term, las = 2, cex.axis = .75); graphics::abline(v = 1, lty = 2, col = cols[["orange"]])
})

manifest[[length(manifest) + 1L]] <- save_both("stability_repeated_predictions", function() {
  d <- flex$prediction_stability; a <- d[d$family == "continuous", ]; b <- d[d$family == "logistic", ]; old <- graphics::par(mfrow = c(1, 2), mar = c(4.5, 4.6, 3.5, 1)); on.exit(graphics::par(old))
  graphics::hist(a$range_prediction, breaks = "FD", col = cols[["blue"]], border = "white", main = "Estabilidade linear", xlab = "Amplitude entre 5 previsões (graus)", ylab = "Participantes (n=615)")
  graphics::hist(100*b$range_prediction, breaks = "FD", col = cols[["green"]], border = "white", main = "Estabilidade logística", xlab = "Amplitude entre 5 previsões (pontos percentuais)", ylab = "Participantes (n=615)")
})

manifest[[length(manifest) + 1L]] <- save_both("flexible_selection_stability", function() {
  d <- flex$selection_frequency; d <- d[d$additional & d$unit_type == "variavel_clinica", ]; d <- d[order(d$selection_frequency), ]; old <- graphics::par(mfrow = c(1,2), mar = c(5, 8, 3.5, 1)); on.exit(graphics::par(old))
  for (fam in c("continuous", "logistic")) { z <- d[d$family == fam, ]; graphics::barplot(z$selection_frequency, names.arg = z$variable, horiz = TRUE, xlim = c(0,1), col = if(fam == "continuous") cols[["blue"]] else cols[["green"]], xlab = "Frequência nos 50 ajustes externos", main = if(fam == "continuous") "Componentes flexíveis: delta" else "Componentes flexíveis: melhora") }
})

# Relações do ajuste global ilustrativo (feito após a CV): escala clínica e
# suporte limitado às fronteiras observadas. Não são curvas de efeito causal.
manifest[[length(manifest) + 1L]] <- save_both("flexible_clinical_relations", function() {
  make_curve <- function(family, variable) {
    fit <- flex$global_fits[[family]]; recipe <- fit$recipe
    base <- as.data.frame(as.list(recipe$numeric_means), stringsAsFactors = FALSE)
    for (v in names(recipe$factor_modes)) base[[v]] <- recipe$factor_modes[[v]]
    spec <- recipe$splines[[variable]]; grid <- seq(spec$boundary[1], spec$boundary[2], length.out = 200)
    new <- base[rep(1, length(grid)), , drop = FALSE]; new[[variable]] <- grid
    p <- flexible_predict(fit$model, flexible_preprocess_apply(new, recipe))
    data.frame(x = grid, prediction = p)
  }
  old <- graphics::par(mfrow = c(2, 2), mar = c(4.2, 4.5, 2.8, .8)); on.exit(graphics::par(old))
  for (variable in c("correcao_colete", "cobb_inicial_maior")) for (family in c("continuous", "logistic")) {
    d <- make_curve(family, variable); ylab <- if (family == "continuous") "Delta previsto (graus)" else "Probabilidade prevista"
    main <- paste(if (family == "continuous") "Delta" else "Melhora", "—", if (variable == "correcao_colete") "correção pelo colete (%)" else "Cobb basal (graus)")
    graphics::plot(d$x, d$prediction, type = "l", lwd = 2.5, col = if (family == "continuous") cols[["blue"]] else cols[["green"]], xlab = if (variable == "correcao_colete") "Correção pelo colete (%)" else "Maior Cobb basal (graus)", ylab = ylab, main = main)
    graphics::abline(v = range(d$x), lty = 3, col = grDevices::adjustcolor(cols[["grey"]], .6))
  }
})

manifest[[length(manifest) + 1L]] <- save_both("sensitivity_comparisons", function() {
  d <- sensitivity[sensitivity$metric %in% c("rmse", "brier_score") & sensitivity$scenario %in% c("primary", "influence_excluded_train_only", "hypercorrection_excluded_train_only", "cobb_baseline_augmented", "training_mean_delta", "training_prevalence"), ]; old <- graphics::par(mfrow = c(1,2), mar = c(5, 11, 3.5, 1)); on.exit(graphics::par(old))
  for (metric in c("rmse", "brier_score")) { z <- d[d$metric == metric, ]; z <- z[order(z$mean_across_repeats), ]; graphics::plot(z$mean_across_repeats, seq_len(nrow(z)), xlim = range(c(z$minimum_across_repeats,z$maximum_across_repeats)), ylim = c(.5,nrow(z)+.5), yaxt = "n", pch = 16, col = cols[["purple"]], xlab = if(metric == "rmse") "RMSE (graus de delta)" else "Brier", ylab = "", main = if(metric == "rmse") "Sensibilidades lineares" else "Sensibilidades logísticas"); graphics::segments(z$minimum_across_repeats, seq_len(nrow(z)), z$maximum_across_repeats, seq_len(nrow(z)), col = cols[["purple"]], lwd = 2); graphics::axis(2, seq_len(nrow(z)), z$scenario, las = 2, cex.axis=.7) }
})

manifest <- do.call(rbind, manifest)
# CART é reutilizada exatamente como entregue pela Task 07; não é reexportada.
cart_files <- file.path(fig, c("cart_illustrative_tree.png", "cart_illustrative_tree.svg", "cart_stability.png", "cart_stability.svg"))
stopifnot(all(file.exists(cart_files)), all(file.info(cart_files)$size > 0))
manifest <- rbind(manifest, data.frame(file = basename(cart_files), width_px = NA, height_px = NA))
manifest$sha256 <- unname(tools::md5sum(file.path(fig, manifest$file)))
manifest$assessment <- ifelse(grepl("observed|roc|diagnostics", manifest$file), "apparent_full_cohort_n615", "internal_resampling_or_descriptive")
utils::write.csv(manifest, file.path(agg, "figures_task12_manifest.csv"), row.names = FALSE)
writeLines(capture.output(sessionInfo()), file.path(review_root, "logs", "figures_task12_sessioninfo.txt"))
