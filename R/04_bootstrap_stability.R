# Bootstrap e estabilidade. As sementes são sempre fornecidas explicitamente.

bootstrap_statistic <- function(data, statistic, times = 1000L, seeds = PARALLEL_SEEDS) {
  stopifnot(is.data.frame(data), is.function(statistic), times > 0L)
  if (length(seeds) < times) {
    seeds <- rep(seeds, length.out = times)
  }
  estimates <- lapply(seq_len(times), function(i) {
    with_fixed_seed(seeds[[i]], {
      index <- sample.int(nrow(data), size = nrow(data), replace = TRUE)
      statistic(data[index, , drop = FALSE])
    })
  })
  do.call(rbind, estimates)
}

stability_summary <- function(estimates) {
  if (!is.matrix(estimates) && !is.data.frame(estimates)) stop("estimates deve ser matriz ou data.frame.")
  data.frame(
    parameter = colnames(estimates) %||% paste0("parameter_", seq_len(ncol(estimates))),
    mean = vapply(estimates, mean, numeric(1), na.rm = TRUE),
    sd = vapply(estimates, stats::sd, numeric(1), na.rm = TRUE),
    stringsAsFactors = FALSE
  )
}

`%||%` <- function(x, y) if (is.null(x)) y else x
