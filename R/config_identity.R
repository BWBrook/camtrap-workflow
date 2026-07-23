# Canonical configuration identity.

canonicalize_value <- function(value) {
  if (is.data.frame(value)) {
    value <- lapply(value, canonicalize_value)
  }

  if (is.list(value)) {
    if (!is.null(names(value))) {
      value <- value[order(names(value), method = "radix")]
    }
    return(lapply(value, canonicalize_value))
  }

  if (!is.null(names(value))) {
    value <- value[order(names(value), method = "radix")]
  }
  value
}

canonical_json <- function(value, pretty = FALSE) {
  jsonlite::toJSON(
    canonicalize_value(value),
    auto_unbox = TRUE,
    null = "null",
    na = "null",
    digits = NA,
    POSIXt = "ISO8601",
    pretty = pretty
  )
}

snapshot_config_file <- function(source, destination) {
  if (!file.exists(source) || isTRUE(file.info(source)$isdir)) {
    stop("Configuration source is missing or not a file: ", source)
  }
  if (file.exists(destination)) {
    stop("Configuration snapshot already exists: ", destination)
  }

  size <- unname(as.numeric(file.info(source)$size))
  connection <- file(source, open = "rb")
  on.exit(close(connection), add = TRUE)
  bytes <- readBin(connection, what = "raw", n = size)
  if (!identical(as.numeric(length(bytes)), size)) {
    stop("Configuration changed while it was being snapshotted: ", source)
  }

  dir.create(dirname(destination), recursive = TRUE, showWarnings = FALSE)
  temporary <- tempfile(
    pattern = paste0(".", basename(destination), "."),
    tmpdir = dirname(destination)
  )
  on.exit(unlink(temporary, force = TRUE), add = TRUE)
  writeBin(bytes, temporary)
  if (!file.rename(temporary, destination)) {
    stop("Atomic configuration snapshot publication failed: ", destination)
  }

  list(
    path = destination,
    bytes = size,
    sha256 = sha256_file(destination)
  )
}

equivalence_config <- function(config) {
  config$evidence_run <- NULL
  config$schema_version_path <- "<schema-version>"
  config$paths$outputs <- "<outputs-root>"
  for (name in names(config$paths$inputs)) {
    if (!is.null(config$paths$inputs[[name]])) {
      config$paths$inputs[[name]] <- paste0("<source:", name, ">")
    }
  }
  config$camtrapdp_acquisition$cache_dir <- "<content-addressed-cache>"
  config
}

config_fingerprints <- function(path, resolved_config) {
  if (!file.exists(path)) {
    stop("Configuration file does not exist: ", path)
  }

  list(
    raw_sha256 = sha256_file(path),
    resolved_sha256 = sha256_text(canonical_json(equivalence_config(resolved_config)))
  )
}

composite_fingerprint <- function(source_sha256, resolved_config_sha256, engine_sha256) {
  sha256_text(canonical_json(list(
    source = source_sha256,
    config_resolved = resolved_config_sha256,
    engine = engine_sha256
  )))
}

attach_evidence_context <- function(config, context) {
  if (is.null(context)) {
    return(config)
  }

  config$evidence_run <- list(
    id = context$run_id,
    invocation_created_utc = context$created_utc,
    legacy_run_label = context$legacy_run_label,
    source_sha256 = context$fingerprints$source,
    config_raw_sha256 = context$fingerprints$config$raw,
    config_resolved_sha256 = context$fingerprints$config$resolved,
    engine_sha256 = context$fingerprints$engine,
    composite_sha256 = context$fingerprints$composite
  )
  config
}

write_effective_config <- function(config, context, path) {
  effective <- attach_evidence_context(config, context)
  record <- list(
    effective_config_schema = "camtrap-effective-config/1.0",
    run_id = context$run_id,
    legacy_run_label = context$legacy_run_label,
    fingerprints = context$fingerprints$config,
    config = effective
  )
  atomic_write_json(canonicalize_value(record), path)
}
