# Immutable evidence-bundle publication and portable verification.

manifest_path <- function(bundle_dir) {
  file.path(bundle_dir, "run_manifest.json")
}

completion_path <- function(bundle_dir) {
  file.path(bundle_dir, "COMPLETED.json")
}

payload_inventory <- function(bundle_dir) {
  inventory_files(bundle_dir, exclude = c("run_manifest.json", "COMPLETED.json"))
}

validate_manifest_payload <- function(bundle_dir) {
  path <- manifest_path(bundle_dir)
  if (!file.exists(path)) {
    stop("Bundle manifest is missing: ", path)
  }
  manifest <- jsonlite::read_json(path, simplifyVector = FALSE)
  if (!identical(manifest$manifest_schema, "camtrap-evidence-manifest/1.0")) {
    stop("Unsupported run manifest schema.")
  }
  assert_safe_run_id(manifest$run_id)

  expected <- manifest$payload
  actual <- payload_inventory(bundle_dir)
  expected_paths <- vapply(expected, `[[`, character(1), "path")
  actual_paths <- vapply(actual, `[[`, character(1), "path")
  if (!identical(expected_paths, actual_paths)) {
    missing <- setdiff(expected_paths, actual_paths)
    extra <- setdiff(actual_paths, expected_paths)
    stop(
      "Bundle payload set mismatch; missing=[", paste(missing, collapse = ","),
      "], extra=[", paste(extra, collapse = ","), "]"
    )
  }

  for (index in seq_along(expected)) {
    record <- expected[[index]]
    assert_safe_relative_path(record$path, "Manifest payload path")
    if (!identical(as.numeric(record$bytes), as.numeric(actual[[index]]$bytes)) ||
          !identical(record$sha256, actual[[index]]$sha256)) {
      stop("Bundle payload fixity mismatch: ", record$path)
    }
  }
  manifest
}

validate_source_identity <- function(bundle_dir, manifest) {
  source_path <- bundle_identity_path(
    bundle_dir,
    manifest$source_inventory,
    "Source inventory path"
  )
  source <- jsonlite::read_json(source_path, simplifyVector = FALSE)
  if (!identical(source$source_inventory_schema, "camtrap-source-inventory/1.0") ||
        !identical(source$run_id, manifest$run_id)) {
    stop("Source inventory and manifest identities disagree.")
  }

  records <- source$files
  if (!is.list(records) || length(records) == 0L) {
    stop("Source inventory has no parser-consumed files.")
  }
  inventory_paths <- vapply(records, `[[`, character(1), "path")
  if (anyDuplicated(inventory_paths) ||
        !identical(inventory_paths, sort(inventory_paths, method = "radix"))) {
    stop("Source inventory paths must be unique and sorted.")
  }

  payload_paths <- vapply(manifest$payload, `[[`, character(1), "path")
  snapshot_paths <- sort(
    payload_paths[startsWith(payload_paths, "source_snapshot/")],
    method = "radix"
  )
  if (!identical(inventory_paths, snapshot_paths)) {
    stop("Source inventory does not exactly cover the source snapshot.")
  }

  for (record in records) {
    if (!isTRUE(record$consumed_by_parser)) {
      stop("Source inventory contains a non-parser input: ", record$path)
    }
    path <- bundle_identity_path(
      bundle_dir,
      record$path,
      "Source inventory file"
    )
    actual_size <- unname(as.numeric(file.info(path)$size))
    actual_hash <- sha256_file(path)
    if (!identical(actual_size, as.numeric(record$bytes)) ||
          !identical(actual_hash, record$sha256)) {
      stop("Source inventory file fixity mismatch: ", record$path)
    }
  }

  recomputed <- fixity_identity(records)
  if (!identical(recomputed, source$source_sha256) ||
        !identical(recomputed, manifest$fingerprints$source)) {
    stop("Source inventory fingerprint mismatch.")
  }
  invisible(recomputed)
}

validate_config_identity <- function(bundle_dir, manifest) {
  raw_path <- bundle_identity_path(
    bundle_dir,
    manifest$config$raw,
    "Raw configuration path"
  )
  effective_path <- bundle_identity_path(
    bundle_dir,
    manifest$config$effective,
    "Effective configuration path"
  )
  effective <- jsonlite::read_json(effective_path, simplifyVector = FALSE)
  if (!identical(effective$effective_config_schema, "camtrap-effective-config/1.0") ||
        !identical(effective$run_id, manifest$run_id) ||
        !identical(effective$config$evidence_run$id, manifest$run_id)) {
    stop("Effective configuration and manifest identities disagree.")
  }

  raw_hash <- sha256_file(raw_path)
  raw_config <- read_config(raw_path, attach_runtime = FALSE)
  resolved_hash <- sha256_text(canonical_json(equivalence_config(raw_config)))
  if (!identical(raw_hash, manifest$fingerprints$config$raw) ||
        !identical(raw_hash, effective$fingerprints$raw)) {
    stop("Raw configuration fingerprint mismatch.")
  }
  if (!identical(resolved_hash, manifest$fingerprints$config$resolved) ||
        !identical(resolved_hash, effective$fingerprints$resolved)) {
    stop("Resolved configuration fingerprint mismatch.")
  }

  effective_config <- effective$config
  evidence <- effective_config$evidence_run
  effective_config$evidence_run <- NULL
  if (!identical(canonical_json(raw_config), canonical_json(effective_config))) {
    stop("Raw and effective resolved configurations disagree.")
  }

  expected_evidence <- list(
    id = manifest$run_id,
    source_sha256 = manifest$fingerprints$source,
    config_raw_sha256 = raw_hash,
    config_resolved_sha256 = resolved_hash,
    engine_sha256 = manifest$fingerprints$engine,
    composite_sha256 = manifest$fingerprints$composite
  )
  for (name in names(expected_evidence)) {
    if (!identical(evidence[[name]], expected_evidence[[name]])) {
      stop("Effective configuration evidence fingerprint mismatch: ", name)
    }
  }
  invisible(resolved_hash)
}

validate_engine_identity <- function(manifest) {
  engine <- manifest$engine
  if (!identical(engine$engine_schema, "camtrap-engine-identity/1.0")) {
    stop("Unsupported engine identity schema.")
  }
  if (!is.list(engine$files) || length(engine$files) == 0L) {
    stop("Engine identity has no source files.")
  }
  engine_paths <- vapply(engine$files, `[[`, character(1), "path")
  if (anyDuplicated(engine_paths) ||
        !identical(engine_paths, sort(engine_paths, method = "radix"))) {
    stop("Engine identity paths must be unique and sorted.")
  }
  for (record in engine$files) {
    assert_safe_relative_path(record$path, "Engine identity path")
    if (!is.numeric(record$bytes) || length(record$bytes) != 1L ||
          record$bytes < 0 ||
          !is.character(record$sha256) ||
          !grepl("^[a-f0-9]{64}$", record$sha256)) {
      stop("Invalid engine source fixity record: ", record$path)
    }
  }

  packages <- engine$package_versions
  if (!is.list(packages) || length(packages) == 0L) {
    stop("Engine identity has no installed package versions.")
  }
  package_names <- vapply(packages, `[[`, character(1), "package")
  if (anyDuplicated(package_names) ||
        !identical(package_names, sort(package_names, method = "radix"))) {
    stop("Engine package identities must be unique and sorted.")
  }

  recomputed <- engine_identity_fingerprint(engine)
  if (!identical(recomputed, engine$engine_sha256) ||
        !identical(recomputed, manifest$fingerprints$engine)) {
    stop("Engine fingerprint mismatch.")
  }
  invisible(recomputed)
}

validate_composite_identity <- function(manifest) {
  recomputed <- composite_fingerprint(
    manifest$fingerprints$source,
    manifest$fingerprints$config$resolved,
    manifest$fingerprints$engine
  )
  if (!identical(recomputed, manifest$fingerprints$composite)) {
    stop("Composite fingerprint mismatch.")
  }
  invisible(recomputed)
}

bundle_identity_path <- function(bundle_dir, relative_path, label) {
  assert_safe_relative_path(relative_path, label)
  path <- file.path(bundle_dir, relative_path)
  assert_path_within_root(path, bundle_dir, label)
  path
}

validate_bundle_identities <- function(bundle_dir, manifest) {
  validate_source_identity(bundle_dir, manifest)
  validate_config_identity(bundle_dir, manifest)
  validate_engine_identity(manifest)
  validate_composite_identity(manifest)

  inputs_path <- bundle_identity_path(
    bundle_dir,
    "report/report_inputs.rds",
    "Report inputs path"
  )
  report_inputs <- readRDS(inputs_path)
  report_id <- report_inputs$params$evidence_run$id
  if (is.null(report_id) || !identical(report_id, manifest$run_id)) {
    stop("Report inputs and manifest identities disagree.")
  }

  report_path <- bundle_identity_path(
    bundle_dir,
    "report/report.html",
    "HTML report path"
  )
  report_text <- readChar(
    report_path,
    nchars = file.info(report_path)$size,
    useBytes = TRUE
  )
  if (!grepl(manifest$run_id, report_text, fixed = TRUE)) {
    stop("HTML report and manifest identities disagree.")
  }
  invisible(TRUE)
}

write_completion_record <- function(bundle_dir) {
  manifest <- validate_manifest_payload(bundle_dir)
  path <- completion_path(bundle_dir)
  if (file.exists(path)) {
    stop("Completion record already exists: ", path)
  }

  completion <- list(
    completion_schema = "camtrap-completed/1.0",
    run_id = manifest$run_id,
    manifest_schema = manifest$manifest_schema,
    manifest_sha256 = sha256_file(manifest_path(bundle_dir)),
    status = "completed",
    completed_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  )
  atomic_write_json(completion, path)
}

verify_run_bundle <- function(bundle_dir) {
  if (!dir.exists(bundle_dir)) {
    stop("Bundle directory does not exist: ", bundle_dir)
  }
  if (nzchar(Sys.readlink(bundle_dir))) {
    stop("Bundle directory may not be a symlink: ", bundle_dir)
  }

  completed <- completion_path(bundle_dir)
  if (!file.exists(completed)) {
    stop("Bundle completion record is missing.")
  }
  completion <- jsonlite::read_json(completed, simplifyVector = FALSE)
  if (!identical(completion$completion_schema, "camtrap-completed/1.0") ||
        !identical(completion$status, "completed")) {
    stop("Invalid terminal completion record.")
  }
  assert_safe_run_id(completion$run_id)

  manifest_hash <- sha256_file(manifest_path(bundle_dir))
  if (!identical(completion$manifest_sha256, manifest_hash)) {
    stop("Bundle manifest SHA-256 does not match completion record.")
  }
  manifest <- validate_manifest_payload(bundle_dir)
  if (!identical(manifest$status, "completed")) {
    stop("Manifest status is not completed.")
  }
  if (!identical(manifest$run_id, completion$run_id) ||
        !identical(manifest$manifest_schema, completion$manifest_schema)) {
    stop("Completion and manifest identities disagree.")
  }
  validate_bundle_identities(bundle_dir, manifest)
  if (!identical(basename(normalizePath(bundle_dir, winslash = "/", mustWork = TRUE)), manifest$run_id)) {
    stop("Bundle directory and manifest identities disagree.")
  }

  list(
    valid = TRUE,
    run_id = manifest$run_id,
    manifest_sha256 = manifest_hash,
    payload_files = length(manifest$payload)
  )
}

latest_pointer_path <- function(outputs_root) {
  file.path(outputs_root, "latest")
}

resolve_latest_bundle <- function(outputs_root, verify = TRUE) {
  pointer <- latest_pointer_path(outputs_root)
  link <- Sys.readlink(pointer)
  if (length(link) == 1L && !is.na(link) && nzchar(link)) {
    stop("Latest pointer may not be a symlink.")
  }
  if (!file.exists(pointer) || dir.exists(pointer)) {
    stop("Latest pointer is missing or not a regular file.")
  }

  lines <- readLines(pointer, warn = FALSE, encoding = "UTF-8")
  if (length(lines) != 1L || !identical(lines[[1]], trimws(lines[[1]]))) {
    stop("Latest pointer must contain exactly one canonical run ID.")
  }
  run_id <- lines[[1]]
  assert_safe_run_id(run_id)

  runs_root <- file.path(outputs_root, "runs")
  bundle_dir <- file.path(runs_root, run_id)
  if (!dir.exists(bundle_dir)) {
    stop("Latest pointer targets an unknown run: ", run_id)
  }
  assert_path_within_root(bundle_dir, runs_root, "Latest bundle")
  if (isTRUE(verify)) {
    verified <- verify_run_bundle(bundle_dir)
    if (!identical(verified$run_id, run_id)) {
      stop("Latest pointer and bundle identities disagree.")
    }
  }
  bundle_dir
}

update_latest_pointer <- function(outputs_root, run_id) {
  assert_safe_run_id(run_id)
  bundle_dir <- file.path(outputs_root, "runs", run_id)
  verified <- verify_run_bundle(bundle_dir)
  if (!identical(verified$run_id, run_id)) {
    stop("Cannot point latest at a mismatched bundle.")
  }

  atomic_replace_text(run_id, latest_pointer_path(outputs_root))
  resolved <- resolve_latest_bundle(outputs_root)
  if (!identical(basename(resolved), run_id)) {
    stop("Latest pointer verification failed after replacement.")
  }
  invisible(resolved)
}

publish_run_bundle <- function(staging_dir, outputs_root, run_id, fail_after_publish = FALSE) {
  assert_safe_run_id(run_id)
  if (!dir.exists(staging_dir)) {
    stop("Staging directory does not exist: ", staging_dir)
  }
  manifest <- validate_manifest_payload(staging_dir)
  if (!identical(manifest$run_id, run_id)) {
    stop("Staging manifest and invocation identities disagree.")
  }

  write_completion_record(staging_dir)
  staged <- verify_run_bundle(staging_dir)
  if (!identical(staged$run_id, run_id)) {
    stop("Staged bundle identity verification failed.")
  }

  final_dir <- file.path(outputs_root, "runs", run_id)
  if (file.exists(final_dir)) {
    stop("Refusing to overwrite completed run directory: ", final_dir)
  }
  dir.create(dirname(final_dir), recursive = TRUE, showWarnings = FALSE)
  if (!file.rename(staging_dir, final_dir)) {
    stop("Atomic bundle directory publication failed.")
  }
  verify_run_bundle(final_dir)

  if (isTRUE(fail_after_publish)) {
    stop("Injected failure after bundle publication and before latest update.")
  }
  update_latest_pointer(outputs_root, run_id)
  invisible(final_dir)
}
