# Versioned immutable evidence-run manifest.

relativize_manifest_paths <- function(value, base_dir) {
  if (is.null(value)) {
    return(value)
  }
  if (is.list(value)) {
    return(lapply(value, relativize_manifest_paths, base_dir = base_dir))
  }
  if (length(value) > 1L) {
    return(vapply(
      value,
      relativize_manifest_paths,
      base_dir = base_dir,
      FUN.VALUE = character(1)
    ))
  }
  if (!is.character(value) || is.na(value)) {
    return(value)
  }
  if (fs::is_absolute_path(value)) {
    return(normalize_relative_path(fs::path_rel(value, start = base_dir)))
  }
  normalize_relative_path(value)
}

#' Write an evidence-run manifest to disk
#'
#' @param path Path to the manifest JSON.
#' @param schema_version Input schema version string.
#' @param params Effective configuration used for the run.
#' @param outputs Named list of output paths.
#' @param session_info_path Path to session info text file.
#' @param config_file Path to the raw configuration file.
#' @param context Supported evidence-run context, or NULL for a partial run.
#' @param phase2 Named Phase-2 artifact paths for manifest schema 1.1.
#' @param entity_resolution Named entity artifact paths for manifest schema 1.2.
#' @return Manifest path invisibly.
#' @export
write_run_manifest <- function(
    path,
    schema_version,
    params,
    outputs,
    session_info_path,
    config_file = NULL,
    context = NULL,
    phase2 = NULL,
    entity_resolution = NULL) {
  bundle_dir <- dirname(path)
  dir.create(bundle_dir, recursive = TRUE, showWarnings = FALSE)
  if (file.exists(path)) {
    unlink(path)
  }

  supported <- !is.null(context) && isTRUE(context$supported_full_run)
  run_id <- if (supported) {
    context$run_id
  } else {
    safe_compatibility_label(paste0("partial-", params$run_id))
  }
  assert_safe_run_id(run_id)

  fingerprints <- if (supported) {
    context$fingerprints
  } else {
    config_hash <- if (!is.null(config_file) && file.exists(config_file)) {
      sha256_file(config_file)
    } else {
      NA_character_
    }
    list(
      source = NA_character_,
      config = list(raw = config_hash, resolved = NA_character_),
      engine = NA_character_,
      composite = NA_character_
    )
  }

  manifest <- list(
    manifest_schema = if (supported &&
                            !is.null(phase2) &&
                            !is.null(entity_resolution)) {
      "camtrap-evidence-manifest/1.2"
    } else if (supported && !is.null(phase2)) {
      "camtrap-evidence-manifest/1.1"
    } else {
      "camtrap-evidence-manifest/1.0"
    },
    run_id = run_id,
    legacy_run_label = params$run_id,
    status = if (supported) "completed" else "partial_unpublished",
    created_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    input_schema_version = schema_version,
    fingerprints = fingerprints,
    config = list(
      source_name = if (supported) {
        context$config_source_name
      } else if (is.null(config_file)) {
        NULL
      } else {
        basename(config_file)
      },
      raw = if (supported) {
        relativize_manifest_paths(context$provenance$raw_config, bundle_dir)
      } else {
        NULL
      },
      effective = if (supported) "provenance/effective_config.json" else NULL
    ),
    source_inventory = if (supported) "provenance/source_inventory.json" else NULL,
    engine = if (supported) context$engine else list(git_commit = get_git_commit()),
    phase2 = if (supported && !is.null(phase2)) {
      relativize_manifest_paths(phase2, bundle_dir)
    } else {
      NULL
    },
    entity_resolution = if (supported && !is.null(entity_resolution)) {
      relativize_manifest_paths(entity_resolution, bundle_dir)
    } else {
      NULL
    },
    outputs = relativize_manifest_paths(outputs, bundle_dir),
    session_info = relativize_manifest_paths(session_info_path, bundle_dir),
    payload = payload_inventory(bundle_dir)
  )
  atomic_write_json(manifest, path)
}

get_git_commit <- function() {
  env_commit <- Sys.getenv("CAMTRAP_WORKFLOW_GIT_COMMIT", unset = NA_character_)
  if (!is.na(env_commit) && nzchar(env_commit) && !identical(env_commit, "unknown")) {
    return(env_commit)
  }

  out <- tryCatch(
    suppressWarnings(system2("git", c("rev-parse", "HEAD"), stdout = TRUE, stderr = TRUE)),
    error = function(e) character()
  )
  status <- attr(out, "status")
  if (length(out) == 0L ||
        (!is.null(status) && !is.na(status) && status != 0L) ||
        any(grepl("fatal", out, ignore.case = TRUE))) {
    return(NA_character_)
  }
  out[[1]]
}
