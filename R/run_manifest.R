# run_manifest.R

#' Write a run manifest to disk
#'
#' @param path Path to the manifest JSON.
#' @param schema_version Input schema version string.
#' @param params Configuration list used for the run.
#' @param outputs Named list of output paths.
#' @param session_info_path Path to session info text file.
#' @param config_file Path to the configuration file used for the run.
#' @return Manifest path invisibly.
#' @export
write_run_manifest <- function(path, schema_version, params, outputs, session_info_path, config_file = NULL) {
  import::from("jsonlite", write_json)
  import::from("fs", path_rel, is_absolute_path)

  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)

  relativize_paths <- function(x, base_dir) {
    if (is.null(x)) return(x)
    if (is.list(x)) {
      return(lapply(x, relativize_paths, base_dir = base_dir))
    }
    if (length(x) > 1) {
      return(vapply(x, relativize_paths, base_dir = base_dir, FUN.VALUE = character(1)))
    }
    if (!is.character(x) || is.na(x)) return(x)
    if (is_absolute_path(x)) {
      return(path_rel(x, start = base_dir))
    }
    x
  }

  base_dir <- dirname(path)
  outputs_rel <- relativize_paths(outputs, base_dir)
  session_info_rel <- relativize_paths(session_info_path, base_dir)
  config_path_rel <- relativize_paths(config_file, base_dir)
  config_hash <- if (!is.null(config_file) && file.exists(config_file)) {
    unname(tools::md5sum(config_file))
  } else {
    NA_character_
  }

  git_commit <- get_git_commit()
  if (is.na(git_commit)) {
    warning("Git commit unavailable; run manifest may not be reproducible.")
  }

  manifest <- list(
    run_id = format(Sys.time(), "%Y%m%dT%H%M%SZ", tz = "UTC"),
    timestamp_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    schema_version = schema_version,
    git_commit = git_commit,
    config = list(
      path = config_path_rel,
      md5 = config_hash
    ),
    params = params,
    outputs = outputs_rel,
    session_info = session_info_rel
  )

  write_json(manifest, path, pretty = TRUE, auto_unbox = TRUE)

  invisible(path)
}

get_git_commit <- function() {
  env_commit <- Sys.getenv("CAMTRAP_WORKFLOW_GIT_COMMIT", unset = NA_character_)
  if (!is.na(env_commit) && nzchar(env_commit) && !identical(env_commit, "unknown")) {
    return(env_commit)
  }

  out <- tryCatch(
    suppressWarnings(system2("git", c("rev-parse", "HEAD"), stdout = TRUE, stderr = TRUE)),
    error = function(e) character(0)
  )
  status <- attr(out, "status")

  if (
    length(out) == 0 ||
      (!is.null(status) && !is.na(status) && status != 0) ||
      any(grepl("fatal", out, ignore.case = TRUE))
  ) {
    return(NA_character_)
  }

  out[[1]]
}
