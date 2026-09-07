# Verificação independente para o parecer de 07/09/2026.
# Executar da raiz: Rscript --vanilla scripts/review_check_flexible_objective.R
# Usa somente dados sintéticos; não regrava resultados nem reajusta a coorte.
source("R/11_flexible_modeling.R")
set.seed(71)
x <- scale(matrix(rnorm(400), ncol = 2))
y <- rbinom(nrow(x), 1, plogis(-0.5 + 1.5 * x[, 1] - 0.7 * x[, 2]))
colnames(x) <- c("x1", "x2")
lambda <- 0.08
# alpha = 0 é o caso ridge, pertencente à grade do elastic net do projeto.
fit <- flexible_fit_one(x, y, "logistic", lambda = lambda, alpha = 0,
  feature_means = c(0, 0), feature_scales = c(1, 1))
objective <- function(b) {
  eta <- b[1] + as.numeric(x %*% b[-1])
  mean(pmax(eta, 0) + log1p(exp(-abs(eta))) - y * eta) +
    lambda / 2 * sum(b[-1]^2)
}
gradient <- function(b) {
  p <- plogis(b[1] + as.numeric(x %*% b[-1]))
  c(mean(p - y), as.numeric(crossprod(x, p - y)) / nrow(x) + lambda * b[-1])
}
reference <- optim(c(0, 0, 0), objective, gr = gradient, method = "BFGS",
  control = list(reltol = 1e-12))
b <- c(fit$intercept, fit$beta)
print(data.frame(
  ajuste = c("implementacao_propria", "referencia_optim"),
  convergiu = c(fit$converged, reference$convergence == 0),
  objetivo = c(objective(b), reference$value),
  gradiente_maximo_absoluto = c(max(abs(gradient(b))), max(abs(gradient(reference$par))))),
  row.names = FALSE)
cat("Maior diferença nos coeficientes:", max(abs(b - reference$par)), "\n")
cat("O teste avalia o objetivo declarado; não estima o impacto na coorte clínica.\n")
