# Parser-consumed source snapshots and engine identity.

resolve_project_path <- function(path, project_root = here::here()) {
  if (is.null(path) || !is.character(path) || length(path) != 1L || !nzchar(path)) {
    stop("Expected one non-empty path.")
  }
  if (fs::is_absolute_path(path)) {
    return(normalizePath(path, winslash = "/", mustWork = FALSE))
  }
  normalizePath(file.path(project_root, path), winslash = "/", mustWork = FALSE)
}

copy_snapshot_file <- function(source, destination) {
  if (!file.exists(source) || isTRUE(file.info(source)$isdir)) {
    stop("Source input is missing or not a file: ", source)
  }
  if (nzchar(Sys.readlink(source))) {
    stop("Source input may not be a symlink: ", source)
  }

  dir.create(dirname(destination), recursive = TRUE, showWarnings = FALSE)
  if (file.exists(destination)) {
    stop("Snapshot destination already exists: ", destination)
  }
  if (!file.copy(source, destination, copy.mode = TRUE, copy.date = TRUE)) {
    stop("Failed to copy source input into snapshot: ", source)
  }
  invisible(destination)
}

resolve_remote_reference <- function(base_url, reference) {
  if (grepl("^https?://", reference, ignore.case = TRUE)) {
    return(reference)
  }
  assert_safe_relative_path(reference, "CamtrapDP resource reference")
  base <- sub("[^/]*([?#].*)?$", "", base_url)
  paste0(base, reference)
}

configured_resource_digest <- function(config, reference, resource) {
  configured <- config$camtrapdp_acquisition$resource_sha256
  if (!is.null(configured) && !is.null(configured[[reference]])) {
    return(tolower(configured[[reference]]))
  }

  declared <- resource$hash
  if (is.character(declared) && length(declared) == 1L) {
    declared <- sub("^sha256:", "", tolower(declared))
    if (grepl("^[a-f0-9]{64}$", declared)) {
      return(declared)
    }
  }
  NULL
}

default_remote_fetch <- function(source, destination) {
  result <- utils::download.file(source, destination, mode = "wb", quiet = TRUE)
  if (!identical(result, 0L)) {
    stop("Remote acquisition failed: ", source)
  }
  invisible(destination)
}

acquire_remote_file <- function(source, expected_sha256, cache_dir, fetch = default_remote_fetch) {
  if (is.null(expected_sha256) ||
        !is.character(expected_sha256) ||
        !grepl("^[A-Fa-f0-9]{64}$", expected_sha256)) {
    stop("Remote CamtrapDP resources require a pinned SHA-256 digest: ", source)
  }
  expected_sha256 <- tolower(expected_sha256)
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  cache_path <- file.path(cache_dir, expected_sha256)

  if (file.exists(cache_path)) {
    if (!identical(sha256_file(cache_path), expected_sha256)) {
      stop("Cached CamtrapDP resource digest mismatch: ", source)
    }
    return(cache_path)
  }

  tmp <- tempfile(pattern = ".download-", tmpdir = cache_dir)
  on.exit(unlink(tmp, force = TRUE), add = TRUE)
  fetch(source, tmp)
  actual <- sha256_file(tmp)
  if (!identical(actual, expected_sha256)) {
    stop(
      "Pinned CamtrapDP digest mismatch for ", source,
      ": expected ", expected_sha256, ", got ", actual
    )
  }
  if (!file.rename(tmp, cache_path)) {
    stop("Failed to publish CamtrapDP resource into cache: ", source)
  }
  cache_path
}

camtrapdp_resources <- function(descriptor) {
  resources <- descriptor$resources
  if (is.null(resources) || !is.list(resources)) {
    stop("CamtrapDP descriptor has no resources list.")
  }
  resources
}

snapshot_camtrapdp <- function(config, snapshot_root, project_root, fetch) {
  acquisition <- config$camtrapdp_acquisition
  mode <- acquisition$mode
  source <- config$paths$inputs$camtrapdp
  cache_dir <- resolve_project_path(acquisition$cache_dir, project_root)
  descriptor_source <- if (identical(mode, "local")) {
    resolve_project_path(source, project_root)
  } else {
    acquire_remote_file(
      source,
      acquisition$descriptor_sha256,
      cache_dir,
      fetch = fetch
    )
  }

  destination_root <- file.path(snapshot_root, "camtrapdp")
  dir.create(destination_root, recursive = TRUE, showWarnings = FALSE)
  descriptor_path <- file.path(destination_root, "datapackage.json")
  copy_snapshot_file(descriptor_source, descriptor_path)

  descriptor <- jsonlite::read_json(descriptor_path, simplifyVector = FALSE)
  resources <- camtrapdp_resources(descriptor)

  parser_resources <- character()
  for (index in seq_along(resources)) {
    resource <- resources[[index]]
    reference <- resource$path
    if (is.null(reference)) {
      next
    }
    if (!is.character(reference) || length(reference) != 1L || !nzchar(reference)) {
      stop("CamtrapDP resource path must be one non-empty string.")
    }
    assert_safe_relative_path(reference, "CamtrapDP resource reference")
    destination <- file.path(destination_root, reference)

    acquired <- if (identical(mode, "local")) {
      local_path <- file.path(dirname(descriptor_source), reference)
      local_real <- normalizePath(local_path, winslash = "/", mustWork = FALSE)
      descriptor_root <- normalizePath(dirname(descriptor_source), winslash = "/", mustWork = TRUE)
      if (!startsWith(local_real, paste0(descriptor_root, "/"))) {
        stop("CamtrapDP resource escapes descriptor directory: ", reference)
      }
      local_path
    } else {
      resource_url <- resolve_remote_reference(source, reference)
      digest <- configured_resource_digest(config, reference, resource)
      acquire_remote_file(resource_url, digest, cache_dir, fetch = fetch)
    }

    copy_snapshot_file(acquired, destination)
    parser_resources <- c(parser_resources, destination)
  }

  schema_source <- resolve_project_path(config$schema_version_path, project_root)
  schema_destination <- file.path(snapshot_root, "schema", basename(schema_source))
  copy_snapshot_file(schema_source, schema_destination)
  list(
    parser_paths = list(
      camtrapdp = descriptor_path,
      schema_version = schema_destination
    ),
    parser_files = c(descriptor_path, parser_resources, schema_destination),
    acquisition = list(
      input_mode = "camtrapdp",
      acquisition_mode = mode,
      descriptor = "source_snapshot/camtrapdp/datapackage.json",
      cache_policy = if (identical(mode, "remote")) "sha256-addressed" else "not-applicable"
    )
  )
}

snapshot_four_tables <- function(config, snapshot_root, project_root) {
  destination_root <- file.path(snapshot_root, "four_table")
  parser_paths <- list()
  parser_files <- character()
  for (name in c("site", "op", "obs", "taxa")) {
    source <- resolve_project_path(config$paths$inputs[[name]], project_root)
    extension <- tools::file_ext(source)
    destination <- file.path(
      destination_root,
      paste0(name, if (nzchar(extension)) paste0(".", extension) else "")
    )
    copy_snapshot_file(source, destination)
    parser_paths[[name]] <- destination
    parser_files <- c(parser_files, destination)
  }

  schema_source <- resolve_project_path(config$schema_version_path, project_root)
  schema_destination <- file.path(snapshot_root, "schema", basename(schema_source))
  copy_snapshot_file(schema_source, schema_destination)
  parser_paths$schema_version <- schema_destination
  parser_files <- c(parser_files, schema_destination)

  list(
    parser_paths = parser_paths,
    parser_files = parser_files,
    acquisition = list(
      input_mode = "four_table",
      acquisition_mode = "local",
      cache_policy = "not-applicable"
    )
  )
}

snapshot_entity_resolution <- function(config, snapshot_root, project_root) {
  selection <- config$entity_resolution
  if (is.null(selection)) {
    return(NULL)
  }
  if (exists("validate_entity_config", mode = "function")) {
    validate_entity_config(selection)
  }
  fields <- c(
    "profile_id",
    "sidecar_path",
    "sidecar_sha256",
    "authority_reference"
  )
  if (!is.list(selection) ||
        !identical(sort(names(selection)), sort(fields))) {
    stop(
      "Entity-resolution snapshot selection must contain exactly profile_id, ",
      "sidecar_path, sidecar_sha256, and authority_reference."
    )
  }
  if (all(vapply(selection[fields], is.null, logical(1)))) {
    return(NULL)
  }
  if (!identical(config$input_mode, "four_table")) {
    stop(
      "The approved Judbury entity-resolution profile is only valid ",
      "when input_mode = 'four_table'; CamtrapDP requires an explicit ",
      "null entity_resolution selection."
    )
  }
  source <- resolve_project_path(selection$sidecar_path, project_root)
  root <- normalizePath(project_root, winslash = "/", mustWork = TRUE)
  resolved <- normalizePath(source, winslash = "/", mustWork = FALSE)
  if (!startsWith(resolved, paste0(root, "/"))) {
    stop("Entity-resolution sidecar escapes the project root.")
  }
  actual <- sha256_file(source)
  if (!identical(actual, selection$sidecar_sha256)) {
    stop("Entity-resolution sidecar SHA-256 does not match approved authority.")
  }
  destination <- file.path(
    snapshot_root,
    "entity_resolution",
    basename(source)
  )
  copy_snapshot_file(source, destination)
  if (!identical(sha256_file(destination), selection$sidecar_sha256)) {
    stop("Entity-resolution sidecar changed during snapshotting.")
  }
  destination
}

materialize_source_snapshot <- function(
    config,
    staging_dir,
    project_root = here::here(),
    fetch = default_remote_fetch) {
  snapshot_root <- file.path(staging_dir, "source_snapshot")
  if (file.exists(snapshot_root)) {
    stop("Source snapshot already exists: ", snapshot_root)
  }
  dir.create(snapshot_root, recursive = TRUE, showWarnings = FALSE)

  snapshot <- if (identical(config$input_mode, "camtrapdp")) {
    snapshot_camtrapdp(config, snapshot_root, project_root, fetch)
  } else {
    snapshot_four_tables(config, snapshot_root, project_root)
  }
  entity_resolution_path <- snapshot_entity_resolution(
    config,
    snapshot_root,
    project_root
  )

  records <- lapply(snapshot$parser_files, function(path) {
    role <- if (identical(path, snapshot$parser_paths$schema_version)) "schema" else "parser_input"
    file_fixity_record(path, staging_dir, role = role, consumed = TRUE)
  })
  if (!is.null(entity_resolution_path)) {
    records[[length(records) + 1L]] <- file_fixity_record(
      entity_resolution_path,
      staging_dir,
      role = "entity_resolution_input",
      consumed = FALSE
    )
  }
  records <- records[order(vapply(records, `[[`, character(1), "path"), method = "radix")]
  snapshot$inventory <- records
  snapshot$source_sha256 <- fixity_identity(records)
  snapshot$snapshot_root <- snapshot_root
  snapshot$entity_resolution_path <- entity_resolution_path
  if (exists("validate_entity_source", mode = "function")) {
    selection <- entity_resolution_selection(config, require_explicit = FALSE)
    validate_entity_source(config, snapshot, selection)
  }
  snapshot
}

verify_source_snapshot <- function(snapshot, staging_dir = NULL) {
  if (is.null(staging_dir)) {
    staging_dir <- snapshot$staging_dir
  }
  if (is.null(staging_dir) || !dir.exists(staging_dir)) {
    stop("Snapshot staging directory is unavailable.")
  }

  for (record in snapshot$inventory) {
    assert_safe_relative_path(record$path, "Source inventory path")
    path <- file.path(staging_dir, record$path)
    assert_path_within_root(path, staging_dir, "Source inventory path")
    actual_size <- unname(as.numeric(file.info(path)$size))
    actual_hash <- sha256_file(path)
    if (!identical(actual_size, as.numeric(record$bytes)) ||
          !identical(actual_hash, record$sha256)) {
      stop("Source snapshot integrity mismatch: ", record$path)
    }
  }

  actual_identity <- fixity_identity(snapshot$inventory)
  if (!identical(actual_identity, snapshot$source_sha256)) {
    stop("Source snapshot identity mismatch.")
  }
  invisible(TRUE)
}

write_source_inventory <- function(snapshot, run_id, path) {
  record <- list(
    source_inventory_schema = "camtrap-source-inventory/1.0",
    run_id = run_id,
    source_sha256 = snapshot$source_sha256,
    acquisition = snapshot$acquisition,
    files = snapshot$inventory
  )
  atomic_write_json(record, path)
}

engine_file_paths <- function(project_root = here::here()) {
  candidates <- c(
    "_targets.R",
    sort(fs::path_rel(Sys.glob(file.path(project_root, "R", "*.R")), start = project_root)),
    "analysis/report.qmd",
    "analysis/methods.qmd",
    "scripts/run_full_evidence_run.R",
    sort(fs::path_rel(
      Sys.glob(file.path(project_root, "config.*.yml")),
      start = project_root
    )),
    ".github/workflows/ci.yml",
    "Dockerfile",
    "renv.lock",
    "VERSION"
  )
  candidates <- unique(normalize_relative_path(candidates))
  sort(
    candidates[file.exists(file.path(project_root, candidates))],
    method = "radix"
  )
}

engine_package_versions <- function(
    project_root = here::here(),
    installed = utils::installed.packages()) {
  lock_path <- file.path(project_root, "renv.lock")
  packages <- if (file.exists(lock_path)) {
    lock <- jsonlite::read_json(lock_path, simplifyVector = FALSE)
    sort(names(lock$Packages), method = "radix")
  } else {
    character()
  }

  lapply(packages, function(package) {
    version <- if (package %in% rownames(installed)) {
      unname(installed[package, "Version"])
    } else {
      NA_character_
    }
    list(package = package, version = version)
  })
}

engine_identity_fingerprint <- function(engine) {
  engine$engine_sha256 <- NULL
  sha256_text(canonical_json(engine))
}

git_output <- function(args, project_root = here::here()) {
  old <- setwd(project_root)
  on.exit(setwd(old), add = TRUE)
  output <- suppressWarnings(system2("git", args, stdout = TRUE, stderr = TRUE))
  status <- attr(output, "status")
  if (!is.null(status) && !is.na(status) && status != 0L) {
    return(character())
  }
  output
}

compute_engine_identity <- function(project_root = here::here()) {
  paths <- engine_file_paths(project_root)
  records <- lapply(paths, function(rel) {
    path <- file.path(project_root, rel)
    list(
      path = rel,
      bytes = unname(as.numeric(file.info(path)$size)),
      sha256 = sha256_file(path)
    )
  })
  commit <- git_output(c("rev-parse", "HEAD"), project_root)
  commit <- if (length(commit) == 1L) commit[[1]] else NA_character_
  dirty <- git_output(
    c("status", "--porcelain=v1", "--untracked-files=all", "--", paths),
    project_root
  )
  diff <- git_output(
    c("diff", "--binary", "--no-ext-diff", "HEAD", "--", paths),
    project_root
  )
  metadata <- list(
    engine_schema = "camtrap-engine-identity/1.0",
    git_commit = commit,
    git_dirty = length(dirty) > 0L,
    git_status = unname(dirty),
    git_diff_sha256 = sha256_text(paste(diff, collapse = "\n")),
    r_version = R.version.string,
    platform = R.version$platform,
    package_versions = engine_package_versions(project_root),
    files = records
  )
  metadata$engine_sha256 <- engine_identity_fingerprint(metadata)
  metadata
}
