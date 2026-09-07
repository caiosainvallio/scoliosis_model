# Testes independentes da Tarefa 07.

project_root <- normalizePath(".", mustWork = TRUE)
source(file.path(project_root, "R", "09_shrinkage_equations.R"), local = .GlobalEnv)

design <- cbind(`(Intercept)` = 1, x = c(-1, 0, 1, 2))
y <- c(-2, -1, 1, 2)
stopifnot(clamp_shrinkage_factor(1.4) == 1, clamp_shrinkage_factor(-0.3) == 0,
  isTRUE(all.equal(recalibrate_linear_intercept(y, design, 0.5), mean(y) - mean(design[, 2] * 0.5))))

linear <- list(formula = y ~ x, coefficients = c(`(Intercept)` = mean(y), x = 0.5),
  design_columns = colnames(design), shrinkage_factor = 0.5, sigma = 1, df_residual = 2,
  design = design, factor_levels = NULL)
class(linear) <- c("shrunk_linear_model", "shrunk_prognostic_model")
stopifnot(max(abs(predict(linear, data.frame(x = c(-1, 2))) - c(mean(y) - 0.5, mean(y) + 1))) < 1e-12)
intervals <- predict(linear, data.frame(x = 0), interval = "prediction")
confidence <- predict(linear, data.frame(x = 0), interval = "confidence")
stopifnot(intervals$lower < confidence$lower, intervals$upper > confidence$upper)

yb <- c(0, 1, 0, 1)
logistic_design <- cbind(`(Intercept)` = 1, x = c(-1, 0, 1, 2))
logistic_intercept <- recalibrate_logistic_intercept(yb, logistic_design, 0.25)
stopifnot(abs(mean(plogis(logistic_intercept + logistic_design[, 2] * 0.25)) - mean(yb)) < 1e-12)

profiles <- data.frame(case = "a", x = 0, stringsAsFactors = FALSE)
stopifnot(max(abs(manual_prediction(linear, profiles, "linear") - predict(linear, profiles))) < 1e-12)

predictions <- rbind(c(0, 1, 2, 3), c(1, 2, 3, 4), c(2, 3, 4, 5))
stability <- summarize_prediction_matrix(predictions, "linear")
stopifnot(nrow(stability) == 4L, all(stability$instability_index_95 >= 0),
  all(stability$participant_index == 1:4), all(stability$n_valid == 3L))

cat("Tarefa 07: todos os testes passaram.\n")
