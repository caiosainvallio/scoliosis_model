# Métricas e calibração; funções genéricas, sem execução de modelos nesta tarefa.

brier_score <- function(observed, predicted) {
  if (length(observed) != length(predicted)) stop("observed e predicted devem ter o mesmo tamanho.")
  mean((as.numeric(observed) - as.numeric(predicted))^2, na.rm = TRUE)
}

calibration_summary <- function(observed, predicted, groups = 10L) {
  keep <- stats::complete.cases(observed, predicted)
  observed <- as.numeric(observed[keep])
  predicted <- as.numeric(predicted[keep])
  if (!length(observed)) return(data.frame())
  breaks <- unique(stats::quantile(predicted, probs = seq(0, 1, length.out = groups + 1), na.rm = TRUE))
  if (length(breaks) < 2L) {
    return(data.frame(group = 1L, n = length(observed), mean_predicted = mean(predicted), mean_observed = mean(observed)))
  }
  bin <- cut(predicted, breaks = breaks, include.lowest = TRUE, labels = FALSE)
  out <- lapply(split(seq_along(bin), bin), function(i) {
    data.frame(
      n = length(i),
      mean_predicted = mean(predicted[i]),
      mean_observed = mean(observed[i])
    )
  })
  result <- do.call(rbind, out)
  result$group <- seq_len(nrow(result))
  result[c("group", "n", "mean_predicted", "mean_observed")]
}
