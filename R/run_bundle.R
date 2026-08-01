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

preflight_record_path <- function(preflight_dir) {
  file.path(preflight_dir, "PREVIEW.json")
}

preflight_payload_inventory <- function(preflight_dir) {
  inventory_files(preflight_dir, exclude = "PREVIEW.json")
}

bundle_relative_path <- function(path, root) {
  relative <- normalize_relative_path(fs::path_rel(path, start = root))
  assert_safe_relative_path(relative, "Evidence artifact path")
  relative
}

phase2_bundle_paths <- function(bundle_dir, links) {
  lapply(links, function(relative) {
    bundle_identity_path(bundle_dir, relative, "Phase-2 artifact path")
  })
}

entity_bundle_paths <- function(bundle_dir, links) {
  lapply(links, function(relative) {
    bundle_identity_path(
      bundle_dir,
      relative,
      "Entity-resolution artifact path"
    )
  })
}

write_preflight_record <- function(staging_dir, context) {
  path <- preflight_record_path(staging_dir)
  if (file.exists(path)) {
    stop("Preflight preview record already exists: ", path)
  }
  phase2 <- lapply(
    context$validation$artifacts,
    bundle_relative_path,
    root = staging_dir
  )
  entity <- lapply(
    context$entity_resolution$artifacts,
    bundle_relative_path,
    root = staging_dir
  )
  selected <- if (!is.null(context$selected_resolution)) {
    lapply(context$selected_resolution$artifacts, bundle_relative_path,
           root = staging_dir)
  } else {
    NULL
  }
  record <- list(
    preview_schema = if (is.null(selected)) {
      "camtrap-validation-preview/1.1"
    } else {
      "camtrap-validation-preview/1.2"
    },
    run_id = context$run_id,
    status = if (isTRUE(context$validation$can_analyze)) "ready" else "blocked",
    created_utc = context$created_utc,
    fingerprints = context$fingerprints,
    config = list(
      source_name = context$config_source_name,
      raw = bundle_relative_path(context$provenance$raw_config, staging_dir),
      effective = bundle_relative_path(
        context$provenance$effective_config,
        staging_dir
      )
    ),
    source_inventory = bundle_relative_path(
      context$provenance$source_inventory,
      staging_dir
    ),
    engine = context$engine,
    phase2 = phase2,
    entity_resolution = entity,
    selected_resolution = selected,
    payload = preflight_payload_inventory(staging_dir)
  )
  atomic_write_json(record, path)
  invisible(path)
}

validate_preflight_payload <- function(preflight_dir) {
  path <- preflight_record_path(preflight_dir)
  if (!file.exists(path)) {
    stop("Preflight preview record is missing.")
  }
  record <- jsonlite::read_json(path, simplifyVector = FALSE)
  supported <- c(
    "camtrap-validation-preview/1.0",
    "camtrap-validation-preview/1.1",
    "camtrap-validation-preview/1.2"
  )
  if (!record$preview_schema %in% supported) {
    stop("Unsupported validation preview schema.")
  }
  assert_safe_run_id(record$run_id)
  if (!is.character(record$status) ||
        length(record$status) != 1L ||
        !record$status %in% c("ready", "blocked")) {
    stop("Invalid validation preview status.")
  }
  expected <- record$payload
  actual <- preflight_payload_inventory(preflight_dir)
  expected_paths <- vapply(expected, `[[`, character(1), "path")
  actual_paths <- vapply(actual, `[[`, character(1), "path")
  if (!identical(expected_paths, actual_paths)) {
    stop("Preflight payload set mismatch.")
  }
  for (index in seq_along(expected)) {
    same_bytes <- identical(
      as.numeric(expected[[index]]$bytes),
      as.numeric(actual[[index]]$bytes)
    )
    same_hash <- identical(
      expected[[index]]$sha256,
      actual[[index]]$sha256
    )
    if (!same_bytes || !same_hash) {
      stop("Preflight payload fixity mismatch: ", expected[[index]]$path)
    }
  }
  record
}

verify_preflight_record <- function(preflight_dir) {
  if (!dir.exists(preflight_dir) || nzchar(Sys.readlink(preflight_dir))) {
    stop("Preflight directory is missing or is a symlink.")
  }
  record <- validate_preflight_payload(preflight_dir)
  if (!identical(
    basename(normalizePath(preflight_dir, winslash = "/", mustWork = TRUE)),
    record$run_id
  )) {
    stop("Preflight directory and invocation identities disagree.")
  }
  validate_source_identity(preflight_dir, record)
  validate_config_identity(preflight_dir, record)
  validate_analysis_unit_record_schema(preflight_dir, record)
  validate_engine_identity(record)
  validate_composite_identity(record)
  phase2 <- phase2_bundle_paths(preflight_dir, record$phase2)
  validate_validation_artifacts(
    preflight_dir,
    phase2,
    require_analysis_ready = identical(record$status, "ready")
  )
  if (record$preview_schema %in% c(
    "camtrap-validation-preview/1.1",
    "camtrap-validation-preview/1.2"
  )) {
    entity <- entity_bundle_paths(preflight_dir, record$entity_resolution)
    validate_entity_artifacts(
      preflight_dir,
      entity,
      require_analysis_ready = identical(record$status, "ready")
    )
  }
  if (identical(record$preview_schema, "camtrap-validation-preview/1.2")) {
    if (!is.list(record$selected_resolution) ||
          !setequal(names(record$selected_resolution),
                    c("membership", "operation", "event_map", "summary"))) {
      stop("Selected-resolution preview links are incomplete.")
    }
    selected <- vapply(record$selected_resolution, function(path) {
      bundle_identity_path(preflight_dir, path, "Selected-resolution artifact path")
    }, character(1))
    selected <- selected[c("membership", "operation", "event_map", "summary")]
    validate_selected_resolution_artifacts(
      preflight_dir,
      selected,
      require_integrity = FALSE
    )
  }
  forbidden <- c("COMPLETED.json", "run_manifest.json")
  if (any(file.exists(file.path(preflight_dir, forbidden))) ||
        dir.exists(file.path(preflight_dir, "report"))) {
    stop("Validation preview contains a completion or scientific-report artifact.")
  }
  list(
    valid = TRUE,
    run_id = record$run_id,
    status = record$status,
    payload_files = length(record$payload)
  )
}

publish_preflight_record <- function(staging_dir, outputs_root, run_id) {
  assert_safe_run_id(run_id)
  if (!dir.exists(staging_dir)) {
    stop("Preflight staging directory does not exist.")
  }
  if (file.exists(file.path(outputs_root, "runs", run_id))) {
    stop("Refusing invocation collision with an existing completed run.")
  }
  write_preflight_record(
    staging_dir,
    jsonlite::read_json(
      file.path(outputs_root, ".runtime", paste0(run_id, ".json")),
      simplifyVector = FALSE
    )
  )
  staged <- verify_preflight_record(staging_dir)
  if (!identical(staged$run_id, run_id)) {
    stop("Staged preflight identity verification failed.")
  }

  final_dir <- file.path(outputs_root, "preflight", run_id)
  if (file.exists(final_dir)) {
    stop("Refusing to overwrite immutable validation preview: ", final_dir)
  }
  dir.create(dirname(final_dir), recursive = TRUE, showWarnings = FALSE)
  if (!file.rename(staging_dir, final_dir)) {
    stop("Atomic validation preview publication failed.")
  }
  verify_preflight_record(final_dir)
  invisible(final_dir)
}

validate_manifest_payload <- function(bundle_dir) {
  path <- manifest_path(bundle_dir)
  if (!file.exists(path)) {
    stop("Bundle manifest is missing: ", path)
  }
  manifest <- jsonlite::read_json(path, simplifyVector = FALSE)
  supported_schemas <- c(
    "camtrap-evidence-manifest/1.0",
    "camtrap-evidence-manifest/1.1",
    "camtrap-evidence-manifest/1.2",
    "camtrap-evidence-manifest/1.3"
  )
  if (!is.character(manifest$manifest_schema) ||
        length(manifest$manifest_schema) != 1L ||
        !manifest$manifest_schema %in% supported_schemas) {
    stop(
      "Unsupported run manifest schema: ",
      paste(manifest$manifest_schema, collapse = ",")
    )
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

  goal007 <- identical(
    manifest$preview_schema,
    "camtrap-validation-preview/1.1"
  ) || identical(
    manifest$preview_schema,
    "camtrap-validation-preview/1.2"
  ) || identical(
    manifest$manifest_schema,
    "camtrap-evidence-manifest/1.2"
  ) || identical(
    manifest$manifest_schema,
    "camtrap-evidence-manifest/1.3"
  )
  for (record in records) {
    allowed_entity_input <- goal007 &&
      identical(record$role, "entity_resolution_input") &&
      identical(record$consumed_by_parser, FALSE)
    allowed_deployment_input <- goal007 &&
      record$role %in% c(
        "deployment_service_input",
        "deployment_ledger_input"
      ) &&
      identical(record$consumed_by_parser, FALSE)
    allowed_selected_mapping <- (identical(
      manifest$preview_schema,
      "camtrap-validation-preview/1.2"
    ) || identical(
      manifest$manifest_schema,
      "camtrap-evidence-manifest/1.3"
    )) && identical(record$role, "analysis_site_mapping_input") &&
      identical(record$consumed_by_parser, FALSE)
    if (!isTRUE(record$consumed_by_parser) &&
          !allowed_entity_input &&
          !allowed_deployment_input &&
          !allowed_selected_mapping) {
      stop("Source inventory contains an unauthorized non-parser input: ", record$path)
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

validate_analysis_unit_record_schema <- function(bundle_dir, record) { # nolint: object_length_linter.
  raw_path <- bundle_identity_path(
    bundle_dir,
    record$config$raw,
    "Raw configuration path"
  )
  config <- read_config(raw_path, attach_runtime = FALSE)
  explicit <- !is.null(analysis_unit_selection(config))

  if (!is.null(record$preview_schema)) {
    selected_schema <- identical(
      record$preview_schema,
      "camtrap-validation-preview/1.2"
    )
    if (explicit && !selected_schema) {
      stop("Explicit analysis_unit selection requires validation preview 1.2.")
    }
    if (!explicit && selected_schema) {
      stop("Validation preview 1.2 requires an explicit analysis_unit selection.")
    }
    return(invisible(TRUE))
  }

  selected_schema <- identical(
    record$manifest_schema,
    "camtrap-evidence-manifest/1.3"
  )
  if (explicit && !selected_schema) {
    stop("Explicit analysis_unit selection requires run manifest 1.3.")
  }
  if (!explicit && selected_schema) {
    stop("Run manifest 1.3 requires an explicit analysis_unit selection.")
  }
  invisible(TRUE)
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

validate_phase2_manifest <- function(bundle_dir, manifest) {
  if (!manifest$manifest_schema %in% c(
    "camtrap-evidence-manifest/1.1",
    "camtrap-evidence-manifest/1.2",
    "camtrap-evidence-manifest/1.3"
  )) {
    return(invisible(TRUE))
  }
  required <- c(
    "resource_registry",
    "source_row_ledger",
    "validation_findings",
    "transformations",
    "repair_proposals",
    "repair_decisions",
    "repair_applications",
    "changed_fields",
    "event_membership",
    "post_validation",
    "validated_inputs"
  )
  if (!is.list(manifest$phase2) ||
        !setequal(names(manifest$phase2), required)) {
    stop("Manifest 1.1 Phase-2 links are incomplete.")
  }
  paths <- phase2_bundle_paths(bundle_dir, manifest$phase2)
  validate_validation_artifacts(
    bundle_dir,
    paths,
    require_analysis_ready = TRUE
  )

  resources <- jsonlite::read_json(
    paths$resource_registry,
    simplifyVector = FALSE
  )$records
  source <- jsonlite::read_json(
    bundle_identity_path(
      bundle_dir,
      manifest$source_inventory,
      "Source inventory path"
    ),
    simplifyVector = FALSE
  )
  source_paths <- vapply(source$files, `[[`, character(1), "path")
  for (resource in resources) {
    index <- match(resource$inventory_path, source_paths)
    content_matches <- !is.na(index) && identical(
      resource$content_sha256,
      source$files[[index]]$sha256
    )
    inventory_matches <- identical(
      resource$source_inventory_link,
      manifest$source_inventory
    )
    if (!content_matches || !inventory_matches) {
      stop("Phase-2 logical resource does not cross-link to source inventory.")
    }
  }
  invisible(TRUE)
}

validate_entity_manifest <- function(bundle_dir, manifest) {
  if (!manifest$manifest_schema %in% c(
    "camtrap-evidence-manifest/1.2",
    "camtrap-evidence-manifest/1.3"
  )) {
    return(invisible(TRUE))
  }
  required <- c(
    "entity_resolution",
    "entity_links",
    "deployment_lineage",
    "entity_resolution_summary",
    "join_readiness"
  )
  if (!is.list(manifest$entity_resolution) ||
        !identical(names(manifest$entity_resolution), required)) {
    stop("Manifest 1.2 entity-resolution links are incomplete.")
  }
  paths <- entity_bundle_paths(bundle_dir, manifest$entity_resolution)
  validate_entity_artifacts(
    bundle_dir,
    paths,
    require_analysis_ready = TRUE
  )
  invisible(TRUE)
}

selected_manifest_provenance_links <- function() { # nolint: object_length_linter.
  c(
    membership = "provenance/selected_resolution/membership.csv",
    operation = "provenance/selected_resolution/operation.csv",
    event_map = "provenance/selected_resolution/event_map.csv",
    summary = "provenance/selected_resolution/summary.json"
  )
}

selected_manifest_output_links <- function() {
  c(
    selected_effort_coverage = "tables/selected_effort_coverage.csv",
    selected_community_presence = "tables/selected_community_presence.csv",
    selected_observed_richness = "tables/selected_observed_richness.csv",
    selected_jaccard = "tables/selected_jaccard.csv"
  )
}

selected_manifest_frames_equal <- function(observed, expected) {
  if (!is.data.frame(observed) || !is.data.frame(expected) ||
        !identical(names(observed), names(expected)) ||
        nrow(observed) != nrow(expected)) {
    return(FALSE)
  }
  all(vapply(names(expected), function(field) {
    left <- observed[[field]]
    right <- expected[[field]]
    if (is.numeric(left) && is.numeric(right)) {
      return(isTRUE(all.equal(
        as.numeric(left),
        as.numeric(right),
        tolerance = .Machine$double.eps,
        check.attributes = FALSE
      )))
    }
    identical(as.character(left), as.character(right))
  }, logical(1)))
}

selected_manifest_common_metadata <- function( # nolint: object_length_linter.
    state,
    n,
    claim_limit,
    temporal_scope) {
  data.frame(
    resolution = rep(state$summary$resolution, n),
    scheme_id = rep(state$summary$scheme_id, n),
    scheme_version = rep(state$summary$scheme_version, n),
    authority_reference = rep(state$summary$authority_reference, n),
    analysis_unit_count = rep(as.integer(state$summary$analysis_unit_count), n),
    temporal_scope_start = rep(temporal_scope[[1L]], n),
    temporal_scope_end = rep(temporal_scope[[2L]], n),
    effort_definition = rep(paste(
      "one confirmed active selected analysis-unit calendar day after",
      "conservative member-location union; unknown periods are not effort"
    ), n),
    claim_limit = rep(claim_limit, n),
    metadata_reference = rep("tables/selected_resolution_status.json", n),
    stringsAsFactors = FALSE
  )
}

selected_manifest_attach_metadata <- function( # nolint: object_length_linter.
    table,
    state,
    claim_limit,
    temporal_scope) {
  cbind(
    table["analysis_unit_id"],
    selected_manifest_common_metadata(
      state,
      nrow(table),
      claim_limit,
      temporal_scope
    ),
    table[setdiff(names(table), "analysis_unit_id")]
  )
}

selected_manifest_expected_tables <- function(state) { # nolint: object_length_linter.
  analysis_units <- sort(unique(as.character(stats::na.omit(
    state$membership$analysis_unit_id
  ))), method = "radix")
  operation_dates <- as.Date(state$operation$date)
  temporal_scope <- if (!length(operation_dates) || all(is.na(operation_dates))) {
    c(NA_character_, NA_character_)
  } else {
    as.character(c(
      min(operation_dates, na.rm = TRUE),
      max(operation_dates, na.rm = TRUE)
    ))
  }

  effort_rows <- lapply(analysis_units, function(id) {
    rows <- state$operation[
      state$operation$analysis_unit_id == id,
      ,
      drop = FALSE
    ]
    dates <- as.Date(rows$date)
    values <- suppressWarnings(as.numeric(rows$operation))
    data.frame(
      analysis_unit_id = id,
      confirmed_active_days = as.integer(sum(values == 1, na.rm = TRUE)),
      confirmed_inactive_days = as.integer(sum(values == 0, na.rm = TRUE)),
      unknown_days = as.integer(sum(is.na(values))),
      observed_date_count = as.integer(nrow(rows)),
      first_observed_date = if (nrow(rows)) {
        as.character(min(dates))
      } else {
        NA_character_
      },
      last_observed_date = if (nrow(rows)) {
        as.character(max(dates))
      } else {
        NA_character_
      },
      stringsAsFactors = FALSE
    )
  })
  effort <- if (length(effort_rows)) {
    do.call(rbind, effort_rows)
  } else {
    data.frame(
      analysis_unit_id = character(),
      confirmed_active_days = integer(),
      confirmed_inactive_days = integer(),
      unknown_days = integer(),
      observed_date_count = integer(),
      first_observed_date = character(),
      last_observed_date = character(),
      stringsAsFactors = FALSE
    )
  }

  species <- sort(unique(as.character(state$event_map$species)), method = "radix")
  species <- species[!is.na(species) & nzchar(species)]
  presence_values <- matrix(
    0L,
    nrow = length(analysis_units),
    ncol = length(species),
    dimnames = list(NULL, species)
  )
  if (nrow(state$event_map) > 0L && length(species) > 0L) {
    pairs <- unique(data.frame(
      analysis_unit_id = as.character(state$event_map$analysis_unit_id),
      species = as.character(state$event_map$species),
      stringsAsFactors = FALSE
    ))
    presence_values[cbind(
      match(pairs$analysis_unit_id, analysis_units),
      match(pairs$species, species)
    )] <- 1L
  }
  presence <- data.frame(
    analysis_unit_id = analysis_units,
    as.data.frame(
      presence_values,
      check.names = FALSE,
      stringsAsFactors = FALSE
    ),
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  richness <- data.frame(
    analysis_unit_id = analysis_units,
    observed_richness = as.integer(rowSums(presence_values)),
    stringsAsFactors = FALSE
  )

  jaccard_rows <- vector("list", length(analysis_units)^2)
  index <- 0L
  for (first_index in seq_along(analysis_units)) {
    first <- presence_values[first_index, ] == 1
    for (second_index in seq_along(analysis_units)) {
      second <- presence_values[second_index, ] == 1
      union_count <- sum(first | second)
      index <- index + 1L
      jaccard_rows[[index]] <- data.frame(
        analysis_unit_id_1 = analysis_units[[first_index]],
        analysis_unit_id_2 = analysis_units[[second_index]],
        jaccard_dissimilarity = if (union_count == 0L) {
          NA_real_
        } else {
          1 - sum(first & second) / union_count
        },
        stringsAsFactors = FALSE
      )
    }
  }
  jaccard <- if (length(jaccard_rows)) {
    do.call(rbind, jaccard_rows)
  } else {
    data.frame(
      analysis_unit_id_1 = character(),
      analysis_unit_id_2 = character(),
      jaccard_dissimilarity = numeric(),
      stringsAsFactors = FALSE
    )
  }

  list(
    effort_coverage = selected_manifest_attach_metadata(
      effort,
      state,
      "confirmed-active-days-only-no-downtime-filling",
      temporal_scope
    ),
    community_presence = selected_manifest_attach_metadata(
      presence,
      state,
      "observed-presence-detection-effort-bounded",
      temporal_scope
    ),
    observed_richness = selected_manifest_attach_metadata(
      richness,
      state,
      "observed-richness-detection-effort-bounded",
      temporal_scope
    ),
    jaccard = cbind(
      jaccard[1:2],
      selected_manifest_common_metadata(
        state,
        nrow(jaccard),
        "jaccard-descriptive-observed-presence-effort-completeness-detectability-limited",
        temporal_scope
      ),
      jaccard["jaccard_dissimilarity"]
    )
  )
}

selected_manifest_contributors <- function(state, analysis_units) {
  lapply(analysis_units, function(id) {
    deployments <- character()
    if (all(c("analysis_unit_id", "deployment_states_json") %in%
              names(state$operation))) {
      evidence <- state$operation$deployment_states_json[
        state$operation$analysis_unit_id == id
      ]
      deployments <- unlist(lapply(evidence, function(value) {
        parsed <- tryCatch(
          jsonlite::fromJSON(value),
          error = function(e) NULL
        )
        unname(unlist(parsed, use.names = FALSE))
      }), use.names = FALSE)
    }
    if ("deployment_id" %in% names(state$event_map)) {
      deployments <- c(
        deployments,
        state$event_map$deployment_id[
          state$event_map$analysis_unit_id == id
        ]
      )
    }
    physical <- sort(unique(as.character(
      state$membership$physical_location_id[
        state$membership$analysis_unit_id == id
      ]
    )), method = "radix")
    deployments <- sort(unique(as.character(deployments)), method = "radix")
    list(
      analysis_unit_id = id,
      contributing_physical_locations = as.list(physical[
        !is.na(physical) & nzchar(physical)
      ]),
      contributing_deployments = as.list(deployments[
        !is.na(deployments) & nzchar(deployments)
      ])
    )
  })
}

selected_manifest_expected_status <- function(state) { # nolint: object_length_linter.
  analysis_units <- sort(unique(as.character(stats::na.omit(
    state$membership$analysis_unit_id
  ))), method = "radix")
  operation_dates <- as.Date(state$operation$date)
  temporal_scope <- if (!length(operation_dates) || all(is.na(operation_dates))) {
    c(NA_character_, NA_character_)
  } else {
    as.character(c(
      min(operation_dates, na.rm = TRUE),
      max(operation_dates, na.rm = TRUE)
    ))
  }
  event_conservation <- if (!isTRUE(state$integrity_ok)) {
    list(
      checked = FALSE,
      exact = FALSE,
      reason = "selected_resolution_integrity_failure"
    )
  } else {
    counts <- table(state$event_map$species)
    list(
      checked = TRUE,
      exact = TRUE,
      preflight_event_count = as.integer(nrow(state$event_map)),
      runtime_event_count = as.integer(nrow(state$event_map)),
      per_species_event_count = stats::setNames(
        as.integer(counts),
        names(counts)
      )
    )
  }
  eligible <- isTRUE(state$integrity_ok) && isTRUE(state$route_eligible)
  output_links <- c(
    effort_coverage = "tables/selected_effort_coverage.csv",
    community_presence = "tables/selected_community_presence.csv",
    observed_richness = "tables/selected_observed_richness.csv",
    jaccard = "tables/selected_jaccard.csv"
  )

  list(
    selected_resolution_status_schema =
      "camtrap-selected-resolution-status/1.0",
    status = state$summary$status,
    integrity_ok = isTRUE(state$integrity_ok),
    route_eligible = isTRUE(state$route_eligible),
    reasons = as.list(as.character(unlist(
      state$summary$reasons,
      use.names = FALSE
    ))),
    resolution = state$summary$resolution,
    scheme_id = state$summary$scheme_id,
    scheme_version = state$summary$scheme_version,
    authority_reference = state$summary$authority_reference,
    membership_count = as.integer(state$summary$membership_count),
    analysis_unit_count = as.integer(state$summary$analysis_unit_count),
    physical_location_count = as.integer(state$summary$physical_location_count),
    temporal_scope = list(start = temporal_scope[[1L]], end = temporal_scope[[2L]]),
    effort_definition = paste(
      "one confirmed active selected analysis-unit calendar day after",
      "conservative member-location union; unknown periods are not effort"
    ),
    analysis_units = selected_manifest_contributors(state, analysis_units),
    claim_limits = list(
      effort_coverage = "confirmed-active-days-only-no-downtime-filling",
      community_presence = "observed-presence-detection-effort-bounded",
      observed_richness = "observed-richness-detection-effort-bounded",
      jaccard = "jaccard-descriptive-observed-presence-effort-completeness-detectability-limited"
    ),
    event_conservation = event_conservation,
    outputs = lapply(output_links, function(path) {
      if (eligible) path else NULL
    })
  )
}

validate_selected_report_inputs <- function( # nolint: object_length_linter.
    report_inputs,
    state,
    status,
    expected_tables) {
  required <- c(
    "selected_effort_coverage",
    "selected_community_presence",
    "selected_observed_richness",
    "selected_jaccard",
    "selected_resolution_status"
  )
  if (!is.list(report_inputs) || !all(required %in% names(report_inputs))) {
    stop("Report inputs omit parsed selected-resolution evidence.")
  }
  if (!identical(
    canonical_json(report_inputs$selected_resolution_status),
    canonical_json(status)
  )) {
    stop("Report inputs do not contain the parsed selected status.")
  }

  eligible <- isTRUE(state$integrity_ok) && isTRUE(state$route_eligible)
  table_names <- c(
    selected_effort_coverage = "effort_coverage",
    selected_community_presence = "community_presence",
    selected_observed_richness = "observed_richness",
    selected_jaccard = "jaccard"
  )
  for (report_name in names(table_names)) {
    value <- report_inputs[[report_name]]
    expected <- expected_tables[[table_names[[report_name]]]]
    if (eligible && !selected_manifest_frames_equal(value, expected)) {
      stop("Report inputs do not contain parsed selected table: ", report_name)
    }
    if (!eligible && !is.null(value)) {
      stop("Ineligible report inputs contain a selected ecological table.")
    }
  }
  invisible(TRUE)
}

validate_selected_manifest <- function(bundle_dir, manifest) {
  if (!identical(
    manifest$manifest_schema,
    "camtrap-evidence-manifest/1.3"
  )) {
    return(invisible(TRUE))
  }

  expected_provenance <- selected_manifest_provenance_links()
  if (!is.list(manifest$selected_resolution) ||
    !identical(names(manifest$selected_resolution), names(expected_provenance)) ||
    !identical(
      unlist(manifest$selected_resolution, use.names = TRUE),
      expected_provenance
    )) {
    stop("Manifest 1.3 selected-resolution links are not canonical.")
  }
  provenance_paths <- vapply(expected_provenance, function(relative) {
    bundle_identity_path(
      bundle_dir,
      relative,
      "Selected-resolution artifact path"
    )
  }, character(1))
  state <- validate_selected_resolution_artifacts(
    bundle_dir,
    provenance_paths,
    require_integrity = FALSE
  )

  required_outputs <- c(
    names(selected_manifest_output_links()),
    "selected_resolution_status"
  )
  tables <- manifest$outputs$tables
  if (!is.list(tables) || !all(required_outputs %in% names(tables))) {
    stop("Manifest 1.3 selected output links are incomplete.")
  }
  if (!identical(
    tables$selected_resolution_status,
    "tables/selected_resolution_status.json"
  )) {
    stop("Manifest 1.3 selected status link is not canonical.")
  }

  expected_outputs <- selected_manifest_output_links()
  eligible <- isTRUE(state$integrity_ok) && isTRUE(state$route_eligible)
  observed_outputs <- tables[names(expected_outputs)]
  links_match <- if (eligible) {
    all(vapply(observed_outputs, function(path) {
      is.character(path) && length(path) == 1L
    }, logical(1))) && identical(
      unlist(observed_outputs, use.names = TRUE),
      expected_outputs
    )
  } else {
    all(vapply(observed_outputs, is.null, logical(1)))
  }
  if (!links_match) {
    stop("Selected ecological output links do not match route eligibility.")
  }

  ecological_paths <- file.path(bundle_dir, unname(expected_outputs))
  if ((eligible && any(!file.exists(ecological_paths))) ||
        (!eligible && any(file.exists(ecological_paths)))) {
    stop("Selected ecological file cardinality does not match route eligibility.")
  }
  status_path <- bundle_identity_path(
    bundle_dir,
    tables$selected_resolution_status,
    "Selected-resolution status path"
  )
  if (!file.exists(status_path)) {
    stop("Selected-resolution status file is missing.")
  }
  status <- jsonlite::read_json(status_path, simplifyVector = FALSE)
  expected_status <- selected_manifest_expected_status(state)
  if (!identical(canonical_json(status), canonical_json(expected_status))) {
    stop("Selected-resolution status does not reconstruct from bundled evidence.")
  }

  expected_tables <- selected_manifest_expected_tables(state)
  if (eligible) {
    table_names <- c(
      selected_effort_coverage = "effort_coverage",
      selected_community_presence = "community_presence",
      selected_observed_richness = "observed_richness",
      selected_jaccard = "jaccard"
    )
    for (link_name in names(table_names)) {
      observed <- utils::read.csv(
        file.path(bundle_dir, tables[[link_name]]),
        stringsAsFactors = FALSE,
        check.names = FALSE,
        na.strings = ""
      )
      expected <- expected_tables[[table_names[[link_name]]]]
      if (!selected_manifest_frames_equal(observed, expected)) {
        stop(
          "Selected ecological output does not reconstruct: ",
          table_names[[link_name]]
        )
      }
    }
  }

  report_inputs <- readRDS(bundle_identity_path(
    bundle_dir,
    "report/report_inputs.rds",
    "Report inputs path"
  ))
  validate_selected_report_inputs(
    report_inputs,
    state,
    status,
    expected_tables
  )
  invisible(TRUE)
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
  validate_analysis_unit_record_schema(bundle_dir, manifest)
  validate_engine_identity(manifest)
  validate_composite_identity(manifest)
  validate_phase2_manifest(bundle_dir, manifest)
  validate_entity_manifest(bundle_dir, manifest)
  validate_selected_manifest(bundle_dir, manifest)

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
