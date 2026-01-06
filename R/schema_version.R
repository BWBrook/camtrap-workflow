# schema_version.R

#' Read the input schema version string
#'
#' @param path Path to `schema_version.txt`.
#' @return Character scalar with the schema version.
#' @export
get_schema_version <- function(path = "schema_version.txt") {
  import::from("fs", file_exists)

  if (!file_exists(path)) {
    stop("schema_version.txt not found at path: ", path)
  }

  version <- readLines(path, warn = FALSE)
  version <- version[nzchar(version)]

  if (length(version) == 0) {
    stop("schema_version.txt is empty.")
  }

  version[[1]]
}
