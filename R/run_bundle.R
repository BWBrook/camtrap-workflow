# One current Goal 011 run-bundle contract.

current_manifest_schema <- "camtrap-run-bundle/2.0"
current_completion_schema <- "camtrap-run-completion/2.0"
verification_receipt_schema <- "camtrap-internal-verification-receipt/1.0"

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
    spatial_resolution = events$selected$summary$resolution,
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
      selected_resolution = relative_artifacts(events$selected_artifacts, root),
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
  ledger <- jsonlite::read_json(bundle_path(
    bundle_dir,
    manifest$audit$events$source_row_ledger,
    "Final source-row ledger"
  ), simplifyVector = TRUE)
  rows <- ledger$records
  required_rows <- c(
    "row_schema", "source_row_id", "resource_id", "logical_name",
    "record_ordinal", "disposition", "rule_id", "reason"
  )
  if (!identical(ledger$source_row_ledger_schema,
                 "camtrap-source-row-ledger/1.0") ||
        !identical(ledger$disposition_scope, "event_formation") ||
        !is.data.frame(rows) || !identical(names(rows), required_rows) ||
        anyDuplicated(rows$source_row_id) ||
        any(!rows$disposition %in% c("retained", "excluded"))) {
    stop("Final source-row ledger is malformed.")
  }
  observation_rows <- rows$logical_name %in% c("obs", "observations")
  retained <- rows$source_row_id[
    observation_rows & rows$disposition == "retained"
  ]
  excluded <- observation_rows & rows$disposition == "excluded"
  if (!setequal(retained, memberships$source_row_id) ||
        any(!memberships$source_row_id %in% rows$source_row_id) ||
        any(!nzchar(rows$rule_id[excluded])) ||
        any(!nzchar(rows$reason[excluded]))) {
    stop("Final source-row dispositions do not reconcile to event membership.")
  }
  list(events = events, memberships = memberships, source_rows = rows)
}

selected_output_path <- function(bundle_dir, manifest, name) {
  relative <- manifest$outputs[[name]]
  if (is.null(relative)) return(NULL)
  bundle_path(bundle_dir, relative, paste("Selected output", name))
}

normalize_selected_operation_evidence <- function(value) { # nolint: object_length_linter.
  value$member_states_json <- as.character(value$member_states_json)
  value$deployment_states_json <- as.character(value$deployment_states_json)
  value$date <- as.character(as.Date(value$date))
  handover <- as.character(value$handover_date)
  handover[!nzchar(handover)] <- NA_character_
  value$handover_date <- as.character(as.Date(handover))
  value$operation <- suppressWarnings(as.numeric(value$operation))
  integer_fields <- c(
    "member_count", "active_member_count", "unknown_member_count",
    "resolved_deployment_count"
  )
  value[integer_fields] <- lapply(value[integer_fields], as.integer)
  value <- value[order(value$analysis_unit_id, value$date, method = "radix"), ]
  rownames(value) <- NULL
  value
}

verify_selected_route_evidence <- function( # nolint: object_length_linter.
    bundle_dir,
    manifest,
    membership,
    operation,
    event_map,
    inputs) {
  selected <- manifest$audit$selected_resolution
  summary <- jsonlite::read_json(bundle_path(
    bundle_dir,
    selected$summary,
    "Selected-resolution summary"
  ), simplifyVector = FALSE)
  deployment_lineage <- utils::read.csv(bundle_path(
    bundle_dir,
    manifest$audit$entity$deployment_lineage,
    "Deployment lineage"
  ), stringsAsFactors = FALSE, na.strings = "")
  entity_state <- list(deployment_lineage = deployment_lineage)
  expected <- build_selected_effort_coverage(
    selected_resolution_pivot_operation(inputs$op),
    membership,
    entity_state
  )
  classified <- selected_resolution_classify_concurrency(
    membership,
    entity_state,
    expected
  )
  if (length(classified$integrity) > 0L) {
    stop("Selected operation has conflicting deployment evidence.")
  }
  expected <- normalize_selected_operation_evidence(
    selected_resolution_prepare_operation(classified$operation)
  )
  observed <- normalize_selected_operation_evidence(operation)
  comparison <- all.equal(
    observed,
    expected,
    tolerance = 0,
    check.attributes = FALSE
  )
  if (!isTRUE(comparison)) {
    stop(
      "Selected operation does not reconstruct from physical effort: ",
      paste(comparison, collapse = "; ")
    )
  }
  artifact_paths <- c(
    membership = selected$membership,
    operation = selected$operation,
    event_map = selected$event_map
  )
  artifact_sha256 <- vapply(artifact_paths, function(path) {
    sha256_file(bundle_path(bundle_dir, path, "Selected-resolution artifact"))
  }, character(1))
  recorded_sha256 <- unlist(summary$artifact_sha256, use.names = TRUE)
  route_eligible <- length(classified$reasons) == 0L
  expected_status <- if (route_eligible) "eligible" else "ineligible"
  expected_counts <- c(
    active = sum(observed$operation == 1, na.rm = TRUE),
    inactive = sum(observed$operation == 0, na.rm = TRUE),
    unknown = sum(is.na(observed$operation))
  )
  summary_reasons <- unlist(summary$reasons, use.names = FALSE)
  if (!identical(summary$selected_resolution_summary_schema,
                 "camtrap-selected-resolution-summary/1.0") ||
        !isTRUE(summary$integrity_ok) ||
        !identical(summary$route_eligible, route_eligible) ||
        !identical(summary$status, expected_status) ||
        !setequal(summary_reasons, classified$reasons) ||
        !identical(recorded_sha256[names(artifact_sha256)], artifact_sha256) ||
        !identical(as.integer(unlist(summary$operation_state_counts)),
                   as.integer(expected_counts)) ||
        as.integer(summary$membership_count) != nrow(membership) ||
        as.integer(summary$analysis_unit_count) !=
          length(unique(membership$analysis_unit_id)) ||
        as.integer(summary$physical_location_count) !=
          length(unique(membership$physical_location_id)) ||
        as.integer(summary$event_count) != nrow(event_map) ||
        as.integer(summary$source_row_membership_count) !=
          sum(event_map$source_membership_count) ||
        !identical(summary$resolution, manifest$spatial_resolution) ||
        !identical(summary$scheme_id, unique(membership$scheme_id)[[1L]]) ||
        !identical(summary$scheme_version,
                   unique(membership$scheme_version)[[1L]]) ||
        !identical(summary$authority_reference,
                   unique(membership$authority_reference)[[1L]])) {
    stop("Selected route eligibility or summary does not reconstruct.")
  }
  route_eligible
}

verify_selected_ecology <- function(
    bundle_dir,
    manifest,
    event_evidence,
    module_records) {
  record_names <- vapply(module_records, `[[`, character(1), "module")
  records <- stats::setNames(module_records, record_names)
  output_contract <- c(
    effort_coverage = "effort_coverage",
    observed_presence = "community_presence",
    observed_richness = "observed_richness",
    jaccard = "jaccard"
  )
  paths <- lapply(output_contract, function(name) {
    selected_output_path(bundle_dir, manifest, name)
  })
  for (module in names(output_contract)) {
    state <- records[[module]]$status
    present <- !is.null(paths[[module]])
    if (state %in% c("completed", "completed_with_warnings") && !present) {
      stop("Selected module payload is required by status: ", module)
    }
    if (identical(state, "omitted") && present) {
      stop("Omitted selected module has a payload: ", module)
    }
  }

  selected <- manifest$audit$selected_resolution
  membership <- utils::read.csv(bundle_path(
    bundle_dir,
    selected$membership,
    "Selected membership"
  ), stringsAsFactors = FALSE)
  operation <- utils::read.csv(bundle_path(
    bundle_dir,
    selected$operation,
    "Selected operation"
  ), stringsAsFactors = FALSE)
  event_map <- utils::read.csv(bundle_path(
    bundle_dir,
    selected$event_map,
    "Selected event map"
  ), stringsAsFactors = FALSE)
  required_event <- c(
    "event_id", "physical_location_id", "analysis_unit_id", "species",
    "event_time", "source_membership_count", "source_membership_digest",
    "source_membership_reference", "deployment_id",
    "deployment_resolution_state"
  )
  if (!identical(names(event_map), required_event) ||
        anyDuplicated(event_map$event_id) ||
        any(!event_map$source_membership_reference %in%
              "provenance/event_membership.csv")) {
    stop("Selected event mapping schema or canonical membership reference is invalid.")
  }
  event_order <- order(event_evidence$events$event_id, method = "radix")
  selected_order <- order(event_map$event_id, method = "radix")
  physical <- event_evidence$events[event_order, , drop = FALSE]
  mapped <- event_map[selected_order, , drop = FALSE]
  rownames(physical) <- rownames(mapped) <- NULL
  shared <- c(
    "event_id", "physical_location_id", "species", "event_time",
    "source_membership_count", "source_membership_digest"
  )
  if (!identical(mapped[shared], physical[shared]) ||
        sum(mapped$source_membership_count) != nrow(event_evidence$memberships)) {
    stop("Selected event mapping contradicts physical event lineage.")
  }
  mapped_units <- membership$analysis_unit_id[
    match(mapped$physical_location_id, membership$physical_location_id)
  ]
  if (anyNA(mapped_units) ||
        !identical(as.character(mapped$analysis_unit_id),
                   as.character(mapped_units))) {
    stop("Selected event mapping contradicts spatial membership.")
  }

  input_path <- bundle_path(
    bundle_dir,
    manifest$audit$validation$validated_inputs,
    "Validated inputs"
  )
  inputs <- readRDS(input_path)
  site <- inputs$site
  matched_site <- match(membership$physical_location_id, site$site)
  if (anyNA(matched_site) ||
    !setequal(
      as.character(membership$physical_location_id),
      as.character(site$site)
    ) ||
    !isTRUE(all.equal(
      membership$physical_latitude,
      as.numeric(site$lat[matched_site]),
      tolerance = 0,
      check.attributes = FALSE
    )) ||
    !isTRUE(all.equal(
      membership$physical_longitude,
      as.numeric(site$lon[matched_site]),
      tolerance = 0,
      check.attributes = FALSE
    ))) {
    stop("Physical-location coordinates changed during spatial grouping.")
  }

  route_eligible <- verify_selected_route_evidence(
    bundle_dir,
    manifest,
    membership,
    operation,
    event_map,
    inputs
  )
  all_units <- sort(unique(as.character(membership$analysis_unit_id)),
                    method = "radix")
  operation$date <- as.Date(operation$date)
  operation$operation <- suppressWarnings(as.numeric(operation$operation))
  eligible_units <- sort(unique(as.character(operation$analysis_unit_id[
    !is.na(operation$operation) & operation$operation == 1
  ])), method = "radix")
  core_modules <- c("observed_presence", "observed_richness", "jaccard")
  core_present <- vapply(paths[core_modules], Negate(is.null), logical(1))
  core_states <- vapply(records[core_modules], `[[`, character(1), "status")
  if (length(unique(core_present)) != 1L) {
    stop("Selected ecological core is only partially present.")
  }
  if (!route_eligible) {
    selected_states <- vapply(
      records[c("effort_coverage", core_modules)],
      `[[`,
      character(1),
      "status"
    )
    if (any(selected_states != "omitted") ||
          any(vapply(paths, Negate(is.null), logical(1)))) {
      stop("Ineligible selected route published ecological output.")
    }
    return(invisible(TRUE))
  }
  if (is.null(paths$effort_coverage) ||
        !identical(records$effort_coverage$status, "completed")) {
    stop("Eligible selected route lacks complete effort coverage.")
  }
  if (!is.null(paths$effort_coverage)) {
    effort <- utils::read.csv(paths$effort_coverage, stringsAsFactors = FALSE)
    expected_effort <- summarise_selected_effort_coverage(operation, all_units)
    fields <- c(
      "analysis_unit_id", "confirmed_active_days", "confirmed_inactive_days",
      "unknown_days", "observed_date_count"
    )
    if (!identical(effort[fields], expected_effort[fields])) {
      stop("Selected effort coverage does not reconstruct from operation.")
    }
  }

  if (length(eligible_units) == 0L) {
    if (any(core_present) || any(core_states != "omitted")) {
      stop("Selected ecological core was published without confirmed effort.")
    }
    return(invisible(TRUE))
  }
  if (!all(core_present) ||
        any(!core_states %in% c("completed", "completed_with_warnings"))) {
    stop("Eligible selected ecological core is absent or incomplete.")
  }
  eligible_events <- mapped[
    mapped$analysis_unit_id %in% eligible_units,
    ,
    drop = FALSE
  ]
  species <- sort(unique(as.character(eligible_events$species)),
                  method = "radix")
  species <- species[!is.na(species) & nzchar(species)]
  expected_presence <- build_selected_presence(
    eligible_events,
    eligible_units,
    species
  )
  expected_core_status <- if (
    length(setdiff(all_units, eligible_units)) > 0L ||
      any(rowSums(expected_presence) == 0L)
  ) {
    "completed_with_warnings"
  } else {
    "completed"
  }
  if (any(core_states != expected_core_status)) {
    stop("Selected ecological core status contradicts effort and detections.")
  }
  presence <- utils::read.csv(
    paths$observed_presence,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  metadata <- c(
    "analysis_unit_id", "resolution", "scheme_id", "scheme_version",
    "authority_reference", "analysis_unit_count", "temporal_scope_start",
    "temporal_scope_end", "effort_definition", "claim_limit",
    "metadata_reference"
  )
  observed_species <- setdiff(names(presence), metadata)
  observed_presence <- as.matrix(presence[observed_species])
  storage.mode(observed_presence) <- "integer"
  if (!identical(as.character(presence$analysis_unit_id), eligible_units) ||
        !identical(observed_species, species) ||
        anyNA(observed_presence) ||
        !identical(unname(observed_presence), unname(as.matrix(expected_presence)))) {
    stop("Published presence does not reconstruct from selected events and effort.")
  }
  richness <- utils::read.csv(
    paths$observed_richness,
    stringsAsFactors = FALSE
  )
  if (!identical(as.character(richness$analysis_unit_id), eligible_units) ||
        !identical(as.integer(richness$observed_richness),
                   as.integer(rowSums(expected_presence)))) {
    stop("Published richness does not reconstruct from selected events.")
  }
  jaccard <- utils::read.csv(paths$jaccard, stringsAsFactors = FALSE)
  expected_jaccard <- compute_selected_jaccard(
    expected_presence,
    eligible_units
  )
  fields <- c(
    "analysis_unit_id_1", "analysis_unit_id_2", "jaccard_dissimilarity"
  )
  observed <- jaccard[fields]
  if (!identical(observed[1:2], expected_jaccard[1:2]) ||
    !isTRUE(all.equal(
      observed$jaccard_dissimilarity,
      expected_jaccard$jaccard_dissimilarity,
      tolerance = 1e-12,
      check.attributes = FALSE
    ))) {
    stop("Published Jaccard does not reconstruct from selected events.")
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
  if (isTRUE(require_ready)) {
    ready <- file.path(bundle_dir, "READY")
    if (!file.exists(ready)) stop("Bundle has no internal-verification marker.")
    receipt <- jsonlite::read_json(ready, simplifyVector = FALSE)
    verify_publication_receipt(bundle_dir, receipt, manifest$run_id)
  }
  verify_payload_inventory(bundle_dir, manifest)
  verify_source_inventory_record(bundle_dir, manifest)
  records <- module_status_records(bundle_dir, manifest)
  event_evidence <- verify_event_consequences(bundle_dir, manifest)
  verify_selected_ecology(bundle_dir, manifest, event_evidence, records)
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
    verification_receipt_schema = verification_receipt_schema,
    valid = TRUE,
    run_id = manifest$run_id,
    manifest_sha256 = sha256_file(manifest_path(bundle_dir)),
    payload_files = length(manifest$payload)
  )
}

verify_publication_receipt <- function(bundle_dir, receipt, run_id) {
  fields <- c(
    "verification_receipt_schema", "valid", "run_id", "manifest_sha256",
    "payload_files"
  )
  if (!is.list(receipt) || !identical(sort(names(receipt)), sort(fields)) ||
        !identical(receipt$verification_receipt_schema,
                   verification_receipt_schema) ||
        !isTRUE(receipt$valid) || !identical(receipt$run_id, run_id) ||
        !identical(receipt$manifest_sha256,
                   sha256_file(manifest_path(bundle_dir)))) {
    stop("Internal verification receipt does not bind the staged manifest.")
  }
  manifest <- read_current_manifest(bundle_dir)
  if (!identical(manifest$run_id, run_id) ||
        as.integer(receipt$payload_files) != length(manifest$payload)) {
    stop("Internal verification receipt does not bind the staged payload count.")
  }
  ready <- file.path(bundle_dir, "READY")
  if (!file.exists(ready)) stop("Internal verification receipt marker is missing.")
  recorded <- jsonlite::read_json(ready, simplifyVector = FALSE)
  if (!identical(canonical_json(recorded), canonical_json(receipt))) {
    stop("Internal verification receipt marker disagrees with the passed receipt.")
  }
  invisible(TRUE)
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
    verification_receipt,
    fail_before_latest = FALSE) {
  assert_safe_run_id(run_id)
  verify_publication_receipt(staging_dir, verification_receipt, run_id)
  final <- file.path(outputs_root, "runs", run_id)
  if (file.exists(final)) stop("Refusing to overwrite completed run: ", run_id)
  dir.create(dirname(final), recursive = TRUE, showWarnings = FALSE)
  if (!file.rename(staging_dir, final)) {
    stop("Atomic bundle directory publication failed.")
  }
  write_completion_record(final)
  verify_publication_receipt(final, verification_receipt, run_id)
  if (isTRUE(fail_before_latest)) {
    stop("Injected failure before latest-completed pointer update.")
  }
  atomic_replace_text(run_id, latest_pointer_path(outputs_root))
  resolved <- resolve_latest_bundle(outputs_root, verify = FALSE)
  if (!identical(normalizePath(resolved), normalizePath(final))) {
    stop("Latest-completed pointer verification failed.")
  }
  final
}
