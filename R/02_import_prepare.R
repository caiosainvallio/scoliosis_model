# Importação e preparação mínima, sem ajuste de modelo ou resultado inferencial.

clean_names_basic <- function(x) {
  x <- iconv(x, from = "", to = "ASCII//TRANSLIT")
  x <- tolower(x)
  x <- gsub("[^a-z0-9]+", "_", x)
  x <- gsub("^_+|_+$", "", x)
  make.unique(x, sep = "_")
}

import_prognostic_data <- function(path = DATA_FILE, sheet = DATA_SHEET) {
  if (!file.exists(path)) {
    stop("Base documentada não encontrada: ", path)
  }
  available_sheets <- readxl::excel_sheets(path)
  if (!sheet %in% available_sheets) {
    stop(
      "A aba '", sheet, "' não existe em ", path,
      ". Abas disponíveis: ", paste(available_sheets, collapse = ", ")
    )
  }
  raw <- readxl::read_excel(path, sheet = sheet, na = "")
  names(raw) <- clean_names_basic(names(raw))
  as.data.frame(raw, stringsAsFactors = FALSE)
}

prepare_prognostic_data <- function(data) {
  stopifnot(is.data.frame(data))
  data
}

source_description <- function() {
  paste0(
    "Fonte documentada: ", DATA_FILE, "; aba: ", DATA_SHEET,
    ". A base bruta não é sobrescrita pelo relatório."
  )
}
