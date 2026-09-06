# Configuração compartilhada do relatório prognóstico.
# Este arquivo não restaura nem salva workspaces .RData.

locate_project_root <- function(start = getwd()) {
  candidate <- normalizePath(start, mustWork = TRUE)
  repeat {
    data_file <- file.path(candidate, "data", "dataset_escoliose_01.xlsx")
    if (file.exists(data_file)) return(candidate)
    parent <- dirname(candidate)
    if (identical(parent, candidate)) {
      stop("Não foi possível localizar a raiz do projeto a partir de: ", start)
    }
    candidate <- parent
  }
}

PROJECT_ROOT <- locate_project_root()
DATA_FILE <- file.path(PROJECT_ROOT, "data", "dataset_escoliose_01.xlsx")
DATA_SHEET <- "dados"
RESULTS_ROOT <- file.path(PROJECT_ROOT, "results", "prognostico")
RESULTS_DIRS <- c(
  aggregated = file.path(RESULTS_ROOT, "aggregated"),
  figures = file.path(RESULTS_ROOT, "figures"),
  logs = file.path(RESULTS_ROOT, "logs"),
  reduced_objects = file.path(RESULTS_ROOT, "reduced_objects")
)

# Sementes fixas e documentadas para a análise principal e rotinas paralelas.
GLOBAL_SEED <- 20260906L
PARALLEL_SEEDS <- c(20260907L, 20260908L, 20260909L, 20260910L)

options(
  scipen = 999,
  stringsAsFactors = FALSE,
  save = "no"
)
RNGkind("L'Ecuyer-CMRG")
set.seed(GLOBAL_SEED)

ensure_output_dirs <- function() {
  invisible(lapply(RESULTS_DIRS, dir.create, recursive = TRUE, showWarnings = FALSE))
  invisible(RESULTS_DIRS)
}

with_fixed_seed <- function(seed, code) {
  old_seed <- if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
    get(".Random.seed", envir = .GlobalEnv)
  } else {
    NULL
  }
  on.exit({
    if (is.null(old_seed)) {
      if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
        rm(".Random.seed", envir = .GlobalEnv)
      }
    } else {
      assign(".Random.seed", old_seed, envir = .GlobalEnv)
    }
  }, add = TRUE)
  set.seed(seed)
  force(code)
}
