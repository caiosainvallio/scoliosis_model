# Apresentação de tabelas, equações e textos dinâmicos.

format_number_pt <- function(x, digits = 2L) {
  formatC(x, format = "f", digits = digits, decimal.mark = ",", big.mark = ".")
}

write_table_csv <- function(x, filename) {
  ensure_output_dirs()
  utils::write.csv(x, file.path(RESULTS_DIRS[["aggregated"]], filename), row.names = FALSE, na = "")
}

equation_text <- function(lhs, rhs) paste0("$", lhs, " = ", rhs, "$")

dynamic_text <- function(n, seed = GLOBAL_SEED) {
  paste0("A análise foi preparada com ", n, " observações disponíveis e semente global ", seed, ".")
}
