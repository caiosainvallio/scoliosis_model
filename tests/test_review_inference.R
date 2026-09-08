# Testes numericos independentes da Tarefa de revisão 08.

project_root <- normalizePath(".", mustWork = TRUE)
source(file.path(project_root, "R", "00_config.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "02_import_prepare.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "07_frozen_models.R"), local = .GlobalEnv)

set.seed(808)
n <- 90L
x <- seq(-2, 2, length.out = n)
y <- 1 + 0.7 * x + rnorm(n, sd = 0.4 + 0.6 * abs(x))
fit <- stats::lm(y ~ x)

# Referência independente: confint.lm usa quantis t e deve coincidir com a
# tabela clássica. Este teste falha para a implementação antiga normal+t.
classic <- wald_coefficient_table(fit, "linear", level = 0.95)
reference_ci <- stats::confint(fit, level = 0.95)
stopifnot(
  max(abs(classic$conf_low - reference_ci[, 1])) < 1e-12,
  max(abs(classic$conf_high - reference_ci[, 2])) < 1e-12,
  all(classic$reference_distribution == "t"),
  all(classic$degrees_freedom == stats::df.residual(fit)),
  all((classic$conf_low <= 0 & classic$conf_high >= 0) == (classic$p_value >= .05))
)

# Referência HC3 por fórmula matricial, sem chamar sandwich na construção.
X <- stats::model.matrix(fit)
e <- stats::residuals(fit)
h <- stats::hatvalues(fit)
xtx_inv <- solve(crossprod(X))
manual_vcov_hc3 <- xtx_inv %*% crossprod(X, X * as.numeric(e^2 / (1 - h)^2)) %*% xtx_inv
manual_se <- sqrt(diag(manual_vcov_hc3))
hc3 <- linear_hc3_coefficient_table(fit)
stopifnot(
  max(abs(hc3$std_error - manual_se)) < 1e-10,
  max(abs(hc3$estimate - stats::coef(fit))) < 1e-12,
  all(hc3$reference_distribution == "t"),
  all((hc3$conf_low <= 0 & hc3$conf_high >= 0) == (hc3$p_value >= .05))
)

# Separação completa, quase-completa e ausência de separação são verificadas
# em desenhos sintéticos conhecidos, independentemente do glm.
complete_x <- cbind(`(Intercept)` = 1, x = c(-2, -1, 1, 2))
complete_y <- c(0, 0, 1, 1)
complete <- diagnostic_separation_qp(complete_x, complete_y)
stopifnot(isTRUE(complete$complete_separation), !isTRUE(complete$quasi_complete_separation))

quasi_x <- cbind(`(Intercept)` = 1, x = c(-1, 0, 0, 1))
quasi_y <- c(0, 0, 1, 1)
quasi <- diagnostic_separation_qp(quasi_x, quasi_y)
stopifnot(!isTRUE(quasi$complete_separation), isTRUE(quasi$quasi_complete_separation))

overlap_x <- cbind(`(Intercept)` = 1, x = c(-2, -1, 1, 2))
overlap_y <- c(0, 1, 0, 1)
overlap <- diagnostic_separation_qp(overlap_x, overlap_y)
stopifnot(!isTRUE(overlap$complete_separation), !isTRUE(overlap$quasi_complete_separation))

# Integração na coorte: identidade, invariância pontual e entregáveis.
raw <- import_prognostic_data()
cohort <- prepare_prognostic_data(raw)
review <- run_review_inference(cohort)
baseline <- utils::read.csv(file.path(project_root, "results", "prognostico", "aggregated",
                                      "frozen_coefficients_linear.csv"), check.names = FALSE)
matched <- match(review$coefficients_linear_classic$term, baseline$term)
stopifnot(
  nrow(cohort) == 615L,
  length(unique(cohort$id)) == 615L,
  sum(cohort$delta_cat) == 317L,
  max(abs(review$coefficients_linear_classic$estimate - baseline$estimate[matched])) < 1e-12,
  max(abs(review$coefficients_linear_hc3$estimate - baseline$estimate[matched])) < 1e-12,
  nrow(review$assumptions) == 8L,
  all(c("assumption", "evidence", "interpretation", "action", "limitation") %in% names(review$assumptions)),
  review$separation$formal_status == "nenhuma_separacao_completa_ou_quase-completa_detectada"
)

cat("Revisao 08: testes de inferencia e diagnosticos passaram.\n")
