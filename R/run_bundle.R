# One current Goal 011 run-bundle contract.

current_manifest_schema <- "camtrap-run-bundle/2.0"
current_completion_schema <- "camtrap-run-completion/2.0"

manifest_path <- function(bundle_dir) {
  file.path(bundle_dir, "run_manifest.json")
}

completion_path <- function(bundle_dir) {
  file.path(bundle_dir, "COMPLETE.json")
}

latest_pointer_path <- function(outputs_root) {
  file.path(outputs_root, "latest")
}

relative_artifacts <- function(value, root) {
  if (is.null(value)) return(NULL)
  if (is.list(value)) {
    return(lapply(value, relative_artifacts, root = root))
  }
  if (!is.character(value)) return(value)
  if (length(value) > 1L) {
    return(vapply(value, stage_relative_path, character(1), root = root))
  }
  stage_relative_path(value, root)
}

payload_inventory <- function(bundle_dir) {
  records <- inventory_files(
    bundle_dir,
    exclude = c("run_manifest.json", "READY", "COMPLETE.json")
  )
  lapply(records, function(record) {
    record[c("path", "bytes", "sha256")]
  })
}

write_current_manifest <- function(report, session_info_path) {
  modules <- report$modules
  events <- modules$events
  foundation <- events$foundation
  validation <- foundation$validation
  ingest <- validation$ingest
  root <- ingest$request$staging_dir
  path <- manifest_path(root)
  manifest <- list(
    manifest_schema = current_manifest_schema,
    run_id = ingest$run$run_id,
    status = "completed",
    created_utc = ingest$run$created_utc,
    spatial_resolution = foundation$selected$summary$resolution,
    fingerprints = ingest$run$fingerprints,
    engine = ingest$engine,
    config = list(
      raw = stage_relative_path(ingest$artifacts$raw_config, root),
      effective = stage_relative_path(
        ingest$artifacts$effective_config,
        root
      )
    ),
    source_inventory = stage_relative_path(
      ingest$artifacts$source_inventory,
      root
    ),
    audit = list(
      validation = relative_artifacts(validation$artifacts, root),
      entity = relative_artifacts(foundation$entity_artifacts, root),
      selected_resolution = relative_artifacts(
        foundation$selected_artifacts,
        root
      ),
      events = relative_artifacts(events$artifacts, root)
    ),
    module_status = stage_relative_path(modules$module_status, root),
    outputs = relative_artifacts(modules$outputs, root),
    report = stage_relative_path(report$report, root),
    session_info = stage_relative_path(session_info_path, root),
    payload = payload_inventory(root)
  )
  atomic_write_json(manifest, path)
  path
}

bundle_path <- function(root, relative, label) {
  assert_safe_relative_path(relative, label)
  path <- file.path(root, relative)
  assert_path_within_root(path, root, label)
  if (isTRUE(file.info(path)$isdir) || nzchar(Sys.readlink(path))) {
    stop(label, " must be a regular file.")
  }
  path
}

read_current_manifest <- function(bundle_dir) {
  path <- manifest_path(bundle_dir)
  if (!file.exists(path)) stop("Current run manifest is missing.")
  manifest <- jsonlite::read_json(path, simplifyVector = FALSE)
  if (!identical(manifest$manifest_schema, current_manifest_schema) ||
        !identical(manifest$status, "completed")) {
    stop("Unsupported or incomplete current run manifest.")
  }
  assert_safe_run_id(manifest$run_id)
  if (!manifest$spatial_resolution %in% c(
    "physical_location",
    "analysis_site"
  )) {
    stop("Manifest analytical resolution is unsupported.")
  }
  manifest
}

verify_payload_inventory <- function(bundle_dir, manifest) {
  records <- manifest$payload
  if (!is.list(records)) stop("Manifest payload inventory is malformed.")
  paths <- vapply(records, `[[`, character(1), "path")
  if (anyDuplicated(paths) || any(!vapply(paths, is_safe_relative_path, logical(1)))) {
    stop("Manifest payload paths are unsafe or duplicated.")
  }
  actual <- payload_inventory(bundle_dir)
  actual_paths <- vapply(actual, `[[`, character(1), "path")
  if (!identical(paths, actual_paths)) {
    stop("Manifest payload does not exactly inventory the bundle.")
  }
  for (index in seq_along(records)) {
    path <- bundle_path(bundle_dir, paths[[index]], "Payload path")
    if (!identical(as.numeric(records[[index]]$bytes),
                   unname(as.numeric(file.info(path)$size))) ||
          !identical(records[[index]]$sha256, sha256_file(path))) {
      stop("Bundle payload fixity mismatch: ", paths[[index]])
    }
  }
  invisible(TRUE)
}

verify_source_inventory_record <- function(bundle_dir, manifest) {
  path <- bundle_path(
    bundle_dir,
    manifest$source_inventory,
    "Source inventory"
  )
  inventory <- jsonlite::read_json(path, simplifyVector = FALSE)
  if (!identical(inventory$source_inventory_schema,
                 "camtrap-source-inventory/1.0") ||
        !identical(inventory$run_id, manifest$run_id)) {
    stop("Source inventory identity is invalid.")
  }
  for (record in inventory$files) {
    source <- bundle_path(bundle_dir, record$path, "Captured source")
    if (!identical(as.numeric(record$bytes),
                   unname(as.numeric(file.info(source)$size))) ||
          !identical(record$sha256, sha256_file(source))) {
      stop("Captured source fixity mismatch: ", record$path)
    }
  }
  observed <- fixity_identity(inventory$files)
  if (!identical(observed, inventory$source_sha256) ||
        !identical(observed, manifest$fingerprints$source)) {
    stop("Captured source identity does not reconcile.")
  }
  invisible(TRUE)
}

module_status_records <- function(bundle_dir, manifest) {
  path <- bundle_path(bundle_dir, manifest$module_status, "Module status")
  document <- jsonlite::read_json(path, simplifyVector = FALSE)
  if (!identical(document$module_status_set_schema,
                 "camtrap-module-status-set/2.0") ||
        !identical(document$run_id, manifest$run_id) ||
        !is.list(document$records)) {
    stop("Module status document is invalid.")
  }
  expected <- c(
    "effort_coverage",
    "observed_presence",
    "observed_richness",
    "jaccard",
    "operational_event_detection_rate",
    "coarse_day_night",
    "species_accumulation",
    "point_map",
    "event_gap_sensitivity"
  )
  names <- vapply(document$records, `[[`, character(1), "module")
  if (!setequal(names, expected) || anyDuplicated(names)) {
    stop("Module status set does not cover the current candidate modules.")
  }
  allowed <- c("completed", "completed_with_warnings", "omitted", "failed")
  for (record in document$records) {
    if (!identical(record$module_status_schema, "camtrap-module-status/2.0") ||
          !record$status %in% allowed ||
          !record$actual_resolution %in% c("physical_location", "analysis_site") ||
          length(record$required_evidence) == 0L) {
      stop("Module status record is malformed: ", record$module)
    }
    reason <- record$reason
    if (!identical(record$status, "completed") &&
          (is.null(reason) || !is.character(reason) || !nzchar(reason))) {
      stop("Non-completed module lacks a plain-language reason: ", record$module)
    }
    if (identical(record$status, "failed")) {
      stop("Failed module cannot appear in a completed bundle: ", record$module)
    }
  }
  document$records
}

verify_event_consequences <- function(bundle_dir, manifest) {
  event_path <- bundle_path(
    bundle_dir,
    manifest$audit$events$physical_events,
    "Physical events"
  )
  membership_path <- bundle_path(
    bundle_dir,
    manifest$audit$events$event_membership,
    "Event membership"
  )
  events <- utils::read.csv(event_path, stringsAsFactors = FALSE)
  memberships <- utils::read.csv(membership_path, stringsAsFactors = FALSE)
  required_events <- c(
    "event_id", "physical_location_id", "species", "event_time",
    "source_membership_count", "source_membership_digest"
  )
  required_memberships <- c(
    "membership_schema", "membership_id", "event_id", "source_row_id",
    "physical_location_id", "deployment_id"
  )
  if (!identical(names(events), required_events) ||
        !identical(names(memberships), required_memberships) ||
        anyDuplicated(events$event_id) ||
        anyDuplicated(memberships$membership_id) ||
        any(!memberships$event_id %in% events$event_id)) {
    stop("Physical event or source-membership evidence is malformed.")
  }
  for (index in seq_len(nrow(events))) {
    rows <- memberships[memberships$event_id == events$event_id[[index]], ]
    digest <- sha256_text(canonical_json(sort(
      rows$source_row_id,
      method = "radix"
    )))
    if (nrow(rows) != events$source_membership_count[[index]] ||
          !identical(digest, events$source_membership_digest[[index]]) ||
          any(rows$physical_location_id != events$physical_location_id[[index]])) {
      stop("Physical event source membership does not reconcile.")
    }
  }
  list(events = events, memberships = memberships)
}

selected_output_path <- function(bundle_dir, manifest, name) {
  relative <- manifest$outputs[[name]]
  if (is.null(relative)) return(NULL)
  bundle_path(bundle_dir, relative, paste("Selected output", name))
}

verify_selected_ecology <- function(bundle_dir, manifest, event_evidence) {
  presence_path <- selected_output_path(
    bundle_dir,
    manifest,
    "community_presence"
  )
  richness_path <- selected_output_path(
    bundle_dir,
    manifest,
    "observed_richness"
  )
  jaccard_path <- selected_output_path(bundle_dir, manifest, "jaccard")
  if (any(vapply(
    list(presence_path, richness_path, jaccard_path),
    is.null,
    logical(1)
  ))) {
    stop("Completed bundle lacks selected ecological core outputs.")
  }
  presence <- utils::read.csv(
    presence_path,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  richness <- utils::read.csv(richness_path, stringsAsFactors = FALSE)
  jaccard <- utils::read.csv(jaccard_path, stringsAsFactors = FALSE)
  metadata <- c(
    "analysis_unit_id", "resolution", "scheme_id", "scheme_version",
    "authority_reference", "analysis_unit_count", "temporal_scope_start",
    "temporal_scope_end", "effort_definition", "claim_limit",
    "metadata_reference"
  )
  species <- setdiff(names(presence), metadata)
  matrix <- as.matrix(presence[species])
  storage.mode(matrix) <- "integer"
  if (anyNA(matrix) || any(!matrix %in% c(0L, 1L)) ||
        !identical(as.character(richness$analysis_unit_id),
                   as.character(presence$analysis_unit_id)) ||
        !identical(as.integer(richness$observed_richness),
                   as.integer(rowSums(matrix)))) {
    stop("Observed presence and richness do not reconcile.")
  }
  expected <- compute_selected_jaccard(matrix, presence$analysis_unit_id)
  observed <- jaccard[c(
    "analysis_unit_id_1",
    "analysis_unit_id_2",
    "jaccard_dissimilarity"
  )]
  if (!identical(as.character(observed$analysis_unit_id_1),
                 expected$analysis_unit_id_1) ||
    !identical(as.character(observed$analysis_unit_id_2),
               expected$analysis_unit_id_2) ||
    !isTRUE(all.equal(
      observed$jaccard_dissimilarity,
      expected$jaccard_dissimilarity,
      tolerance = 1e-12,
      check.attributes = FALSE
    ))) {
    stop("Descriptive Jaccard output does not reconstruct from presence.")
  }

  selected_event <- bundle_path(
    bundle_dir,
    manifest$audit$selected_resolution$event_map,
    "Selected event map"
  )
  event_map <- utils::read.csv(selected_event, stringsAsFactors = FALSE)
  if (!setequal(event_map$event_id, event_evidence$events$event_id) ||
        sum(event_map$source_membership_count) !=
          nrow(event_evidence$memberships)) {
    stop("Selected-resolution event conservation failed.")
  }

  membership_path <- bundle_path(
    bundle_dir,
    manifest$audit$selected_resolution$membership,
    "Selected membership"
  )
  membership <- utils::read.csv(membership_path, stringsAsFactors = FALSE)
  input_path <- bundle_path(
    bundle_dir,
    manifest$audit$validation$validated_inputs,
    "Validated inputs"
  )
  inputs <- readRDS(input_path)
  site <- inputs$site
  matched <- match(membership$physical_location_id, site$site)
  if (anyNA(matched) ||
    !isTRUE(all.equal(
      membership$physical_latitude,
      as.numeric(site$lat[matched]),
      tolerance = 0,
      check.attributes = FALSE
    )) ||
    !isTRUE(all.equal(
      membership$physical_longitude,
      as.numeric(site$lon[matched]),
      tolerance = 0,
      check.attributes = FALSE
    ))) {
    stop("Physical-location coordinates changed during spatial grouping.")
  }
  invisible(TRUE)
}

verify_current_bundle <- function(bundle_dir, require_ready = TRUE) {
  if (!dir.exists(bundle_dir) || nzchar(Sys.readlink(bundle_dir))) {
    stop("Bundle directory is missing or is a symlink.")
  }
  manifest <- read_current_manifest(bundle_dir)
  if (!identical(basename(normalizePath(
    bundle_dir,
    winslash = "/",
    mustWork = TRUE
  )), manifest$run_id)) {
    stop("Bundle directory and run identity disagree.")
  }
  if (isTRUE(require_ready) && !file.exists(file.path(bundle_dir, "READY"))) {
    stop("Bundle has no internal-verification marker.")
  }
  verify_payload_inventory(bundle_dir, manifest)
  verify_source_inventory_record(bundle_dir, manifest)
  module_status_records(bundle_dir, manifest)
  event_evidence <- verify_event_consequences(bundle_dir, manifest)
  verify_selected_ecology(bundle_dir, manifest, event_evidence)
  bundle_path(bundle_dir, manifest$report, "HTML ecological report")

  completed <- completion_path(bundle_dir)
  if (file.exists(completed)) {
    record <- jsonlite::read_json(completed, simplifyVector = FALSE)
    if (!identical(record$completion_schema, current_completion_schema) ||
          !identical(record$run_id, manifest$run_id) ||
          !identical(record$manifest_sha256, sha256_file(manifest_path(bundle_dir)))) {
      stop("Bundle completion record is invalid.")
    }
  }
  list(
    valid = TRUE,
    run_id = manifest$run_id,
    manifest_sha256 = sha256_file(manifest_path(bundle_dir)),
    payload_files = length(manifest$payload)
  )
}

write_completion_record <- function(bundle_dir) {
  manifest <- read_current_manifest(bundle_dir)
  atomic_write_json(list(
    completion_schema = current_completion_schema,
    run_id = manifest$run_id,
    status = "completed",
    manifest_sha256 = sha256_file(manifest_path(bundle_dir)),
    completed_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  ), completion_path(bundle_dir))
}

resolve_latest_bundle <- function(outputs_root, verify = TRUE) {
  pointer <- latest_pointer_path(outputs_root)
  if (!file.exists(pointer) || dir.exists(pointer) || nzchar(Sys.readlink(pointer))) {
    stop("Latest pointer is missing or is not a regular file.")
  }
  value <- readLines(pointer, warn = FALSE)
  if (length(value) != 1L || !identical(value, trimws(value))) {
    stop("Latest pointer must contain exactly one canonical run ID.")
  }
  assert_safe_run_id(value)
  bundle <- file.path(outputs_root, "runs", value)
  if (!dir.exists(bundle)) stop("Latest pointer targets an unknown run.")
  if (isTRUE(verify)) verify_current_bundle(bundle)
  bundle
}

publish_current_bundle <- function(
    staging_dir,
    outputs_root,
    run_id,
    fail_before_latest = FALSE) {
  assert_safe_run_id(run_id)
  staged <- verify_current_bundle(staging_dir)
  if (!identical(staged$run_id, run_id)) {
    stop("Staging bundle and invocation identities disagree.")
  }
  final <- file.path(outputs_root, "runs", run_id)
  if (file.exists(final)) stop("Refusing to overwrite completed run: ", run_id)
  dir.create(dirname(final), recursive = TRUE, showWarnings = FALSE)
  if (!file.rename(staging_dir, final)) {
    stop("Atomic bundle directory publication failed.")
  }
  write_completion_record(final)
  verify_current_bundle(final)
  if (isTRUE(fail_before_latest)) {
    stop("Injected failure before latest-completed pointer update.")
  }
  atomic_replace_text(run_id, latest_pointer_path(outputs_root))
  resolved <- resolve_latest_bundle(outputs_root)
  if (!identical(normalizePath(resolved), normalizePath(final))) {
    stop("Latest-completed pointer verification failed.")
  }
  final
}
