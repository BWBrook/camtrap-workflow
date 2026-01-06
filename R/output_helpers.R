# output_helpers.R

#' Write a small placeholder file when an output is disabled
#'
#' @param path Output path to write.
#' @param message Message to write into the file.
#' @return Path invisibly.
#' @export
write_disabled_file <- function(path, message = "Output disabled by config.") {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(message, path)
  invisible(path)
}
