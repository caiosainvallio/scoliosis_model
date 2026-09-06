# Verificação de dependências. Não instala pacotes.

REQUIRED_PACKAGES <- c("readxl")
RELEVANT_PACKAGES <- c(
  "readxl", "dplyr", "tidyr", "purrr", "tibble", "ggplot2", "scales",
  "broom", "pROC", "rsample", "yardstick", "future", "furrr", "withr",
  "knitr", "rmarkdown"
)

check_dependencies <- function(
    required = REQUIRED_PACKAGES,
    relevant = RELEVANT_PACKAGES,
    write_log = TRUE,
    fail = TRUE) {
  packages <- unique(c(required, relevant))
  status <- data.frame(
    package = packages,
    required_for_setup = packages %in% required,
    present = vapply(packages, requireNamespace, logical(1), quietly = TRUE),
    version = vapply(
      packages,
      function(pkg) if (requireNamespace(pkg, quietly = TRUE)) {
        as.character(utils::packageVersion(pkg))
      } else {
        NA_character_
      },
      character(1)
    ),
    stringsAsFactors = FALSE
  )

  if (write_log) {
    ensure_output_dirs()
    utils::write.csv(
      status,
      file.path(RESULTS_DIRS[["logs"]], "dependency_status.csv"),
      row.names = FALSE,
      na = ""
    )
  }

  missing_required <- status$package[status$required_for_setup & !status$present]
  if (fail && length(missing_required) > 0) {
    stop(
      "Dependências obrigatórias ausentes: ",
      paste(missing_required, collapse = ", "),
      ". Instale-as fora do relatório e execute novamente; " ,
      "este projeto não instala pacotes automaticamente."
    )
  }

  status
}

record_environment <- function(status = check_dependencies(write_log = TRUE, fail = TRUE)) {
  ensure_output_dirs()
  quarto <- Sys.which("quarto")
  lines <- c(
    "Registro inicial de ambiente — relatório prognóstico",
    paste("data_registro:", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
    paste("project_root:", PROJECT_ROOT),
    paste("data_file:", DATA_FILE),
    paste("data_sheet:", DATA_SHEET),
    paste("R.version:", R.version.string),
    paste("R.platform:", R.version$platform),
    paste("OS.type:", .Platform$OS.type),
    paste("system:", Sys.info()[["sysname"]]),
    paste("system_release:", Sys.info()[["release"]]),
    paste("quarto:", if (nzchar(quarto)) quarto else "ausente"),
    paste("global_seed:", GLOBAL_SEED),
    paste("parallel_seeds:", paste(PARALLEL_SEEDS, collapse = ", ")),
    "",
    "Pacotes relevantes (AUSENTE também é registrado explicitamente):",
    paste(sprintf("%s\t%s", status$package, ifelse(status$present, status$version, "AUSENTE")), collapse = "\n"),
    "",
    "Política de workspace:",
    "execução esperada com R --vanilla ou Rscript --vanilla; nenhum load(.RData) é usado.",
    "O relatório não chama install.packages()."
  )
  writeLines(lines, file.path(RESULTS_DIRS[["logs"]], "initial_environment_and_seeds.txt"))
  invisible(lines)
}
