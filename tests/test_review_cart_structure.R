# Testes independentes da revisão estrutural da CART.

project_root <- normalizePath(".", mustWork = TRUE)
source(file.path(project_root, "R", "00_config.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "02_import_prepare.R"), local = .GlobalEnv)
source(file.path(project_root, "R", "10_cart_nested.R"), local = .GlobalEnv)

cart_requirements()
set.seed(606L)
n <- 180L
group <- factor(sample(c("baixo", "medio", "alto"), n, replace = TRUE),
                levels = c("baixo", "medio", "alto"))
x <- as.numeric(group) + rnorm(n, sd = 0.18)
z <- x + rnorm(n, sd = 0.12)
w <- rnorm(n)
y <- factor(ifelse(group == "alto" | (group == "medio" & w > 0), "sim", "nao"),
            levels = c("nao", "sim"))
toy <- data.frame(y = y, group = group, x = x, z = z, w = w)
toy$x[seq(3L, n, by = 17L)] <- NA_real_

known <- rpart::rpart(
  y ~ group + x + z + w, data = toy, method = "class", model = TRUE,
  control = rpart::rpart.control(cp = 0, minsplit = 8L, maxdepth = 3L,
                                maxcompete = 4L, maxsurrogate = 5L, xval = 0L)
)
info <- list(model = known, tree_id = 1L, repeat_id = 1L, outer_fold = 1L)
tables <- cart_structure_tables(list(info), fit_origin = "synthetic_test")
internal <- known$frame$var != "<leaf>"

stopifnot(
  nrow(tables$primary_splits) == sum(internal),
  identical(as.character(tables$primary_splits$variable), as.character(known$frame$var[internal])),
  nrow(tables$competitor_splits) == sum(known$frame$ncompete[internal]),
  nrow(tables$surrogate_splits) == sum(known$frame$nsurrogate[internal]),
  nrow(tables$primary_splits) + nrow(tables$competitor_splits) + nrow(tables$surrogate_splits) == nrow(known$splits),
  all(tables$primary_splits$split_role == "primary"),
  all(tables$competitor_splits$split_role == "competitor"),
  all(tables$surrogate_splits$split_role == "surrogate"),
  any(tables$primary_splits$split_type == "categorical"),
  all(nzchar(tables$primary_splits$left_rule)),
  all(nzchar(tables$primary_splits$right_rule)),
  nrow(tables$leaf_rules) == sum(!internal),
  sum(tables$leaf_rules$node_n) == known$frame$n[[1]],
  all(grepl("synthetic_test", tables$leaf_rules$fit_origin, fixed = TRUE))
)

# Árvore sem cortes: nenhuma linha de splits e uma única regra de folha.
no_split <- rpart::rpart(
  y ~ group + x + z + w, data = toy, method = "class", model = TRUE,
  control = rpart::rpart.control(cp = 1, minsplit = n + 1L, xval = 0L)
)
empty <- cart_structure_tables(list(list(
  model = no_split, tree_id = 2L, repeat_id = 1L, outer_fold = 2L
)))
stopifnot(nrow(empty$primary_splits) == 0L, nrow(empty$competitor_splits) == 0L,
          nrow(empty$surrogate_splits) == 0L, nrow(empty$leaf_rules) == 1L,
          empty$leaf_rules$rule == "<root leaf>")

# Frequência por árvore não pode duplicar uma árvore que reutiliza a variável.
frequency_input <- data.frame(
  tree_id = c(1L, 1L, 1L, 2L, 2L), variable = c("a", "a", "b", "a", "c"),
  depth = c(0L, 1L, 3L, 0L, 2L), stringsAsFactors = FALSE
)
frequency <- cart_variable_frequency_summary(frequency_input, n_trees = 3L)
all_a <- frequency[frequency$scope == "all_levels" & frequency$variable == "a", ]
stopifnot(all_a$n_primary_splits == 3L, all_a$trees_with_variable == 2L,
          all_a$denominator_trees == 3L, all_a$relative_frequency == 2 / 3,
          setequal(unique(frequency$scope), c("root", "depths_1_2", "deeper_than_2", "all_levels")),
          all(frequency$relative_frequency >= 0 & frequency$relative_frequency <= 1))

# O baseline tem 50 folds; somente um intercepto é inválido, logo n válido = 49.
saved <- readRDS(file.path(project_root, "results", "prognostico", "reduced_objects",
                           "cart_nested_internal.rds"))
calibration <- cart_calibration_validity(saved$metrics, saved$predictions)
intercept <- calibration$summary[calibration$summary$metric == "calibration_intercept", ]
stopifnot(intercept$total_outer_folds == 50L, intercept$valid_folds == 49L,
          intercept$invalid_folds == 1L, intercept$denominator_summary == 49L,
          nrow(calibration$invalid) == 1L,
          calibration$invalid$repeat_id == 3L, calibration$invalid$outer_fold == 1L,
          calibration$invalid$n_at_boundary == 9L)

cat("Revisão CART: todos os testes estruturais passaram.\n")
