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

#' Check rendered artefacts for absolute repo paths
#'
#' @param paths Character vector of file paths to scan.
#' @param repo_root Repo root path to detect (defaults to here::here()).
#' @return TRUE if no absolute paths are found; otherwise errors.
#' @export
check_rendered_paths <- function(paths, repo_root = here::here()) {
  import::from("fs", path_norm)

  repo_root <- path_norm(repo_root)
  if (is.null(paths)) return(TRUE)

  for (path in paths) {
    if (is.null(path) || !file.exists(path)) next
    text <- readLines(path, warn = FALSE)
    if (any(grepl(repo_root, text, fixed = TRUE))) {
      stop("Rendered artefact contains absolute path: ", repo_root)
    }
  }

  TRUE
}
