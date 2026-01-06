# run_manifest.R

#' Write a run manifest to disk
#'
#' @param path Path to the manifest JSON.
#' @param schema_version Input schema version string.
#' @param params Configuration list used for the run.
#' @param outputs Named list of output paths.
#' @param session_info_path Path to session info text file.
#' @return Manifest path invisibly.
#' @export
write_run_manifest <- function(path, schema_version, params, outputs, session_info_path) {
  import::from("jsonlite", write_json)

  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)

  manifest <- list(
    run_id = format(Sys.time(), "%Y%m%dT%H%M%SZ", tz = "UTC"),
    timestamp_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    schema_version = schema_version,
    git_commit = get_git_commit(),
    params = params,
    outputs = outputs,
    session_info = session_info_path
  )

  write_json(manifest, path, pretty = TRUE, auto_unbox = TRUE)

  invisible(path)
}

get_git_commit <- function() {
  out <- tryCatch(
    system2("git", c("rev-parse", "HEAD"), stdout = TRUE, stderr = TRUE),
    error = function(e) character(0)
  )

  if (length(out) == 0 || any(grepl("fatal", out))) {
    return(NA_character_)
  }

  out[[1]]
}
