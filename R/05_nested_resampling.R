# Reamostragem aninhada; gera índices reproduzíveis e não ajusta modelos.

nested_resample_indices <- function(n, outer = 10L, inner = 5L, seed = GLOBAL_SEED) {
  stopifnot(length(n) == 1L, n >= 2L, outer >= 1L, inner >= 2L)
  with_fixed_seed(seed, {
    lapply(seq_len(outer), function(i) {
      outer_train <- sample.int(n, size = floor(0.8 * n))
      outer_test <- setdiff(seq_len(n), outer_train)
      inner_splits <- lapply(seq_len(inner), function(j) {
        inner_train <- sample(outer_train, size = floor(0.8 * length(outer_train)))
        list(train = inner_train, validation = setdiff(outer_train, inner_train))
      })
      list(train = outer_train, test = outer_test, inner = inner_splits)
    })
  })
}
