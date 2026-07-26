# Versioned entity-resolution evidence.

entity_resolver_version <- "camtrap-entity-resolver/1.0"
entity_record_schema <- "camtrap-entity-resolution/1.0"
entity_link_schema <- "camtrap-entity-links/1.0"
deployment_lineage_schema <- "camtrap-deployment-lineage/1.0"
entity_summary_schema <- "camtrap-entity-resolution-summary/1.0"
join_readiness_schema <- "camtrap-join-readiness/1.0"

entity_null_selection <- function() {
  list(
    profile_id = NULL,
    sidecar_path = NULL,
    sidecar_sha256 = NULL,
    authority_reference = NULL
  )
}

judbury_entity_profile <- function() {
  digest <- "553abada14493f3a5f0ae3c072523b6d5cc0d0c6a6c6480ca17a9e3331f2d8ec"
  list(
    profile_id = "judbury-entity-crosswalk/1.0.0-proposed",
    crosswalk_schema = "camtrap-entity-crosswalk/1.0",
    crosswalk_version = "judbury-entity-crosswalk/1.0.0-proposed",
    sidecar_sha256 = digest,
    authority_reference = paste0(
      "goal007-judbury-crosswalk-sha256-",
      digest
    )
  )
}

entity_resolution_selection <- function(config, require_explicit = FALSE) {
  selection <- config$entity_resolution
  if (is.null(selection)) {
    if (isTRUE(require_explicit)) {
      stop(
        "Supported Goal 007 runs require an explicit entity_resolution ",
        "selection or explicit null selection."
      )
    }
    return(NULL)
  }
  expected_fields <- names(entity_null_selection())
  if (!is.list(selection) ||
        !identical(sort(names(selection)), sort(expected_fields))) {
    stop(
      "entity_resolution must contain exactly profile_id, sidecar_path, ",
      "sidecar_sha256, and authority_reference."
    )
  }
  values <- selection[expected_fields]
  nulls <- vapply(values, is.null, logical(1))
  if (all(nulls)) {
    return(entity_null_selection())
  }
  if (any(nulls) ||
    !all(vapply(values, function(value) {
      is.character(value) && length(value) == 1L && nzchar(value)
    }, logical(1)))) {
    stop(
      "entity_resolution must be either an exact null selection or a ",
      "complete selected profile."
    )
  }
  if (!grepl("^[a-f0-9]{64}$", selection$sidecar_sha256)) {
    stop("entity_resolution.sidecar_sha256 must be one lowercase SHA-256 digest.")
  }

  authority <- judbury_entity_profile()
  observed <- selection[c(
    "profile_id",
    "sidecar_sha256",
    "authority_reference"
  )]
  expected <- authority[c(
    "profile_id",
    "sidecar_sha256",
    "authority_reference"
  )]
  if (!identical(observed, expected)) {
    stop("Selected entity-resolution profile has no exact approved authority.")
  }
  if (!identical(config$input_mode, "four_table")) {
    stop(
      "The approved Judbury entity-resolution profile is only valid ",
      "when input_mode = 'four_table'; CamtrapDP requires an explicit ",
      "null entity_resolution selection."
    )
  }
  selection
}

entity_resolution_is_selected <- function(selection) {
  !is.null(selection) && !is.null(selection$profile_id)
}

entity_identity <- function(entity_type, source_namespace, stable_key) {
  sha256_text(canonical_json(list(
    identity_schema = "camtrap-entity-identity/1.0",
    algorithm = "sha256-canonical-json/1.0",
    entity_type = entity_type,
    source_namespace = source_namespace,
    stable_key = stable_key
  )))
}

entity_link_identity <- function(link_type, source_entity_id, target_entity_id) {
  endpoints <- c(source_entity_id, target_entity_id)
  if (identical(link_type, "service_history_move_pair")) {
    endpoints <- sort(endpoints, method = "radix")
  }
  sha256_text(canonical_json(list(
    identity_schema = "camtrap-entity-link-identity/1.0",
    algorithm = "sha256-canonical-json/1.0",
    link_type = link_type,
    source_entity_id = endpoints[[1]],
    target_entity_id = endpoints[[2]]
  )))
}

entity_record <- function(
    entity_type,
    entity_id,
    source_namespace,
    source_identifier,
    resolution_state,
    evidence_state,
    evidence_basis,
    source_inventory_path = NA_character_,
    source_row_id = NA_character_) {
  record <- list(
    entity_record_schema = entity_record_schema,
    resolver_version = entity_resolver_version,
    entity_type = entity_type,
    entity_id = entity_id,
    source_namespace = source_namespace,
    source_identifier = source_identifier,
    resolution_state = resolution_state,
    evidence_state = evidence_state,
    evidence_basis = evidence_basis,
    source_inventory_path = source_inventory_path,
    source_row_id = source_row_id
  )
  record$record_digest <- sha256_text(canonical_json(record))
  record
}

entity_link_record <- function(
    link_type,
    source_entity_type,
    source_entity_id,
    target_entity_type,
    target_entity_id,
    evidence_state,
    evidence_basis,
    source_inventory_path = NA_character_,
    source_row_id = NA_character_) {
  if (identical(link_type, "service_history_move_pair") &&
        target_entity_id < source_entity_id) {
    temporary_id <- source_entity_id
    source_entity_id <- target_entity_id
    target_entity_id <- temporary_id
  }
  record <- list(
    entity_link_schema = entity_link_schema,
    resolver_version = entity_resolver_version,
    link_id = entity_link_identity(
      link_type,
      source_entity_id,
      target_entity_id
    ),
    link_type = link_type,
    source_entity_type = source_entity_type,
    source_entity_id = source_entity_id,
    target_entity_type = target_entity_type,
    target_entity_id = target_entity_id,
    resolution_state = "resolved",
    evidence_state = evidence_state,
    evidence_basis = evidence_basis,
    source_inventory_path = source_inventory_path,
    source_row_id = source_row_id
  )
  record$record_digest <- sha256_text(canonical_json(record))
  record
}

deployment_lineage_record <- function(
    deployment_identifier,
    deployment_entity_id,
    physical_location_entity_id,
    interval_start,
    interval_end,
    interval_evidence_state,
    chronology_state,
    resolution_state,
    evidence_basis,
    source_inventory_path = NA_character_,
    source_row_id = NA_character_) {
  record <- list(
    deployment_record_schema = deployment_lineage_schema,
    resolver_version = entity_resolver_version,
    deployment_identifier = deployment_identifier,
    deployment_entity_id = deployment_entity_id,
    physical_location_entity_id = physical_location_entity_id,
    interval_start = interval_start,
    interval_end = interval_end,
    interval_evidence_state = interval_evidence_state,
    chronology_state = chronology_state,
    resolution_state = resolution_state,
    evidence_basis = evidence_basis,
    source_inventory_path = source_inventory_path,
    source_row_id = source_row_id
  )
  record$record_digest <- sha256_text(canonical_json(record))
  record
}

records_frame <- function(records, columns) {
  if (length(records) == 0L) {
    empty <- stats::setNames(rep(list(character()), length(columns)), columns)
    return(as.data.frame(empty, stringsAsFactors = FALSE))
  }
  rows <- lapply(records, function(record) {
    values <- record[columns]
    values <- lapply(values, function(value) {
      if (is.null(value) || length(value) == 0L) NA_character_ else as.character(value)
    })
    as.data.frame(values, stringsAsFactors = FALSE)
  })
  result <- do.call(rbind, rows)
  rownames(result) <- NULL
  result
}

entity_records_frame <- function(records) {
  result <- records_frame(records, c(
    "entity_record_schema",
    "resolver_version",
    "entity_type",
    "entity_id",
    "source_namespace",
    "source_identifier",
    "resolution_state",
    "evidence_state",
    "evidence_basis",
    "source_inventory_path",
    "source_row_id",
    "record_digest"
  ))
  if (nrow(result) > 0L) {
    result <- result[order(
      result$entity_type,
      result$source_namespace,
      result$source_identifier,
      result$evidence_basis,
      na.last = TRUE,
      method = "radix"
    ), , drop = FALSE]
    rownames(result) <- NULL
  }
  result
}

entity_links_frame <- function(records) {
  result <- records_frame(records, c(
    "entity_link_schema",
    "resolver_version",
    "link_id",
    "link_type",
    "source_entity_type",
    "source_entity_id",
    "target_entity_type",
    "target_entity_id",
    "resolution_state",
    "evidence_state",
    "evidence_basis",
    "source_inventory_path",
    "source_row_id",
    "record_digest"
  ))
  if (nrow(result) > 0L) {
    result <- result[order(
      result$link_type,
      result$source_entity_id,
      result$target_entity_id,
      method = "radix"
    ), , drop = FALSE]
    rownames(result) <- NULL
  }
  result
}

deployment_lineage_frame <- function(records) {
  result <- records_frame(records, c(
    "deployment_record_schema",
    "resolver_version",
    "deployment_identifier",
    "deployment_entity_id",
    "physical_location_entity_id",
    "interval_start",
    "interval_end",
    "interval_evidence_state",
    "chronology_state",
    "resolution_state",
    "evidence_basis",
    "source_inventory_path",
    "source_row_id",
    "record_digest"
  ))
  if (nrow(result) > 0L) {
    result <- result[order(
      result$deployment_identifier,
      result$physical_location_entity_id,
      result$source_row_id,
      na.last = TRUE,
      method = "radix"
    ), , drop = FALSE]
    rownames(result) <- NULL
  }
  result
}

inventory_path_for_role <- function(snapshot, role, fallback = NA_character_) {
  matches <- vapply(snapshot$inventory, function(record) {
    identical(record$role, role)
  }, logical(1))
  if (sum(matches) == 1L) snapshot$inventory[[which(matches)]]$path else fallback
}

validate_entity_source <- function(config, snapshot, selection) {
  inventory <- snapshot$inventory
  if (!is.list(inventory) || length(inventory) == 0L) {
    stop("Entity resolution requires a non-empty immutable source inventory.")
  }
  matches <- vapply(inventory, function(record) {
    identical(record$role, "entity_resolution_input")
  }, logical(1))
  selected <- entity_resolution_is_selected(selection)
  entity_path <- snapshot$entity_resolution_path

  if (!selected) {
    if (sum(matches) != 0L) {
      stop(
        "An explicit null entity_resolution selection requires zero ",
        "entity-resolution sidecars in the source inventory."
      )
    }
    if (!is.null(entity_path)) {
      stop(
        "An explicit null entity_resolution selection may not expose a ",
        "dedicated entity-resolution path."
      )
    }
  } else {
    if (!identical(config$input_mode, "four_table")) {
      stop(
        "The approved Judbury entity-resolution profile is only valid ",
        "when input_mode = 'four_table'; CamtrapDP requires an explicit ",
        "null entity_resolution selection."
      )
    }
    if (sum(matches) != 1L) {
      stop(
        "A selected entity-resolution profile requires exactly one ",
        "entity-resolution sidecar in the source inventory."
      )
    }
    if (!is.character(entity_path) ||
          length(entity_path) != 1L ||
          is.na(entity_path) ||
          !nzchar(entity_path)) {
      stop(
        "A selected entity-resolution profile requires one dedicated ",
        "entity-resolution snapshot path."
      )
    }

    record <- inventory[[which(matches)]]
    assert_safe_relative_path(
      record$path,
      "Entity-resolution source inventory path"
    )
    if (!grepl("^source_snapshot/entity_resolution/[^/]+$", record$path) ||
          !identical(record$consumed_by_parser, FALSE) ||
          !identical(record$sha256, selection$sidecar_sha256)) {
      stop(
        "The selected entity-resolution sidecar does not match its exact ",
        "non-parser source-inventory authority."
      )
    }
    if (!is.character(snapshot$snapshot_root) ||
          length(snapshot$snapshot_root) != 1L ||
          !dir.exists(snapshot$snapshot_root)) {
      stop("Entity-resolution snapshot root is unavailable.")
    }
    staging_root <- dirname(snapshot$snapshot_root)
    expected_path <- file.path(staging_root, record$path)
    assert_path_within_root(
      expected_path,
      staging_root,
      "Entity-resolution source inventory path"
    )
    assert_path_within_root(
      entity_path,
      staging_root,
      "Entity-resolution snapshot path"
    )
    if (!identical(
      normalizePath(expected_path, winslash = "/", mustWork = TRUE),
      normalizePath(entity_path, winslash = "/", mustWork = TRUE)
    ) || !identical(sha256_file(entity_path), record$sha256)) {
      stop(
        "The selected entity-resolution sidecar path and source-inventory ",
        "record do not reconcile."
      )
    }
  }

  source_sha256 <- fixity_identity(inventory)
  if (!is.character(snapshot$source_sha256) ||
        length(snapshot$source_sha256) != 1L ||
        !grepl("^[a-f0-9]{64}$", snapshot$source_sha256) ||
        !identical(source_sha256, snapshot$source_sha256)) {
    stop("Entity resolution cannot reproduce the immutable source identity.")
  }
  source_sha256
}

parser_inventory_path <- function(snapshot, pattern) {
  paths <- vapply(snapshot$inventory, `[[`, character(1), "path")
  matches <- grep(pattern, paths)
  if (length(matches) == 1L) paths[[matches]] else NA_character_
}

entity_source_row_id <- function(validation_state, logical_name, record_ordinal) {
  rows <- validation_state$lineage$rows
  required <- c("logical_name", "record_ordinal", "source_row_id")
  if (!is.data.frame(rows) || !all(required %in% names(rows))) {
    return(NA_character_)
  }
  matches <- which(
    rows$logical_name == logical_name &
      rows$record_ordinal == record_ordinal
  )
  if (length(matches) == 1L) {
    as.character(rows$source_row_id[[matches]])
  } else {
    NA_character_
  }
}

read_entity_crosswalk <- function(path, selection) {
  if (!file.exists(path) || isTRUE(file.info(path)$isdir)) {
    stop("Selected entity crosswalk is missing or not a file.")
  }
  if (nzchar(Sys.readlink(path))) {
    stop("Selected entity crosswalk may not be a symlink.")
  }
  crosswalk <- utils::read.csv(
    path,
    stringsAsFactors = FALSE,
    na.strings = "",
    check.names = FALSE
  )
  required <- c(
    "crosswalk_schema",
    "crosswalk_version",
    "mapping_state",
    "source_physical_id",
    "proposed_physical_location_id",
    "proposed_nominal_grid_station_id",
    "service_history_marker",
    "mapping_basis",
    "mapping_authority",
    "move_pair_id",
    "chronology_state",
    "deployment_state",
    "notes"
  )
  if (!identical(names(crosswalk), required)) {
    stop("Entity crosswalk fields do not match the closed schema.")
  }
  if (nrow(crosswalk) == 0L ||
        anyDuplicated(crosswalk$source_physical_id) ||
        anyDuplicated(crosswalk$proposed_physical_location_id)) {
    stop("Entity crosswalk contains a duplicate or empty physical mapping.")
  }
  authority <- judbury_entity_profile()
  if (!all(crosswalk$crosswalk_schema == authority$crosswalk_schema) ||
        !all(crosswalk$crosswalk_version == authority$crosswalk_version) ||
        !all(crosswalk$mapping_state == "proposed_for_barry_review") ||
        !all(crosswalk$chronology_state ==
               "unresolved_no_authoritative_order") ||
        !all(crosswalk$deployment_state ==
               "unresolved_no_authoritative_id_or_interval")) {
    stop("Entity crosswalk schema, version, or unresolved authority state is invalid.")
  }
  required_text <- c(
    "source_physical_id",
    "proposed_physical_location_id",
    "proposed_nominal_grid_station_id",
    "mapping_basis",
    "mapping_authority"
  )
  if (any(vapply(crosswalk[required_text], function(column) {
    any(is.na(column) | !nzchar(column))
  }, logical(1)))) {
    stop("Entity crosswalk contains an empty required mapping field.")
  }
  pairs <- split(
    crosswalk$proposed_physical_location_id[!is.na(crosswalk$move_pair_id)],
    crosswalk$move_pair_id[!is.na(crosswalk$move_pair_id)]
  )
  if (length(pairs) > 0L &&
    any(vapply(pairs, function(pair) {
      length(pair) != 2L || anyDuplicated(pair) || pair[[1]] == pair[[2]]
    }, logical(1)))) {
    stop("Entity crosswalk move pairs must have two distinct endpoints.")
  }
  actual_sha256 <- sha256_file(path)
  if (!identical(actual_sha256, selection$sidecar_sha256) ||
        !identical(selection$sidecar_sha256, authority$sidecar_sha256)) {
    stop("Entity crosswalk SHA-256 digest has no exact approved authority.")
  }
  crosswalk
}

unresolved_scope_record <- function(entity_type, namespace, basis) {
  entity_record(
    entity_type = entity_type,
    entity_id = NA_character_,
    source_namespace = namespace,
    source_identifier = NA_character_,
    resolution_state = "unresolved",
    evidence_state = "absent",
    evidence_basis = basis
  )
}

add_integrity_finding <- function(findings, code, message, scope) {
  findings[[length(findings) + 1L]] <- list(
    finding_schema = "camtrap-entity-integrity-finding/1.0",
    code = code,
    scope = scope,
    message = message
  )
  findings
}

format_endpoint <- function(value) {
  if (length(value) != 1L || is.na(value)) {
    return(NA_character_)
  }
  parsed <- suppressWarnings(as.POSIXct(value, tz = "UTC"))
  if (is.na(parsed)) {
    return(NA_character_)
  }
  format(parsed, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
}

resolve_four_table_entities <- function(
    config,
    snapshot,
    validation_state,
    selection) {
  sites <- as.character(validation_state$inputs$site$site)
  records <- list()
  links <- list()
  findings <- list()
  crosswalk <- NULL
  selected <- entity_resolution_is_selected(selection)

  if (any(is.na(sites) | !nzchar(sites)) || anyDuplicated(sites)) {
    findings <- add_integrity_finding(
      findings,
      "four_table.physical_identity_invalid",
      "Legacy site identifiers must be non-empty and unique.",
      "site"
    )
  }

  if (selected) {
    crosswalk <- read_entity_crosswalk(snapshot$entity_resolution_path, selection)
    if (!setequal(sites, crosswalk$source_physical_id) ||
          length(sites) != nrow(crosswalk)) {
      findings <- add_integrity_finding(
        findings,
        "crosswalk.source_key_mismatch",
        "Approved crosswalk keys do not exactly cover legacy site identifiers.",
        "site"
      )
    }
    inventory_path <- inventory_path_for_role(
      snapshot,
      "entity_resolution_input"
    )
    if (is.na(inventory_path)) {
      findings <- add_integrity_finding(
        findings,
        "crosswalk.inventory_missing",
        "Approved crosswalk has no unique source-inventory record.",
        "source_inventory"
      )
    }

    physical_ids <- stats::setNames(
      vapply(
        crosswalk$proposed_physical_location_id,
        entity_identity,
        character(1),
        entity_type = "physical_location",
        source_namespace = "judbury_crosswalk:physical_location"
      ),
      crosswalk$proposed_physical_location_id
    )
    for (index in seq_len(nrow(crosswalk))) {
      row <- crosswalk[index, , drop = FALSE]
      records[[length(records) + 1L]] <- entity_record(
        entity_type = "physical_location",
        entity_id = physical_ids[[row$proposed_physical_location_id]],
        source_namespace = "judbury_crosswalk:physical_location",
        source_identifier = row$source_physical_id,
        resolution_state = "resolved",
        evidence_state = "approved_sidecar",
        evidence_basis = row$mapping_basis,
        source_inventory_path = inventory_path
      )
    }

    nominal_keys <- sort(
      unique(crosswalk$proposed_nominal_grid_station_id),
      method = "radix"
    )
    nominal_ids <- stats::setNames(
      vapply(
        nominal_keys,
        entity_identity,
        character(1),
        entity_type = "nominal_grid_station",
        source_namespace = "judbury_crosswalk:nominal_grid_station"
      ),
      nominal_keys
    )
    for (key in nominal_keys) {
      records[[length(records) + 1L]] <- entity_record(
        entity_type = "nominal_grid_station",
        entity_id = nominal_ids[[key]],
        source_namespace = "judbury_crosswalk:nominal_grid_station",
        source_identifier = key,
        resolution_state = "resolved",
        evidence_state = "approved_sidecar",
        evidence_basis = "exact_approved_crosswalk_key",
        source_inventory_path = inventory_path
      )
    }
    for (index in seq_len(nrow(crosswalk))) {
      row <- crosswalk[index, , drop = FALSE]
      links[[length(links) + 1L]] <- entity_link_record(
        link_type = "physical_location_to_nominal_grid_station",
        source_entity_type = "physical_location",
        source_entity_id = physical_ids[[row$proposed_physical_location_id]],
        target_entity_type = "nominal_grid_station",
        target_entity_id = nominal_ids[[row$proposed_nominal_grid_station_id]],
        evidence_state = "approved_sidecar",
        evidence_basis = row$mapping_basis,
        source_inventory_path = inventory_path
      )
    }
    pair_ids <- sort(unique(stats::na.omit(crosswalk$move_pair_id)), method = "radix")
    for (pair_id in pair_ids) {
      endpoints <- crosswalk$proposed_physical_location_id[
        !is.na(crosswalk$move_pair_id) &
          crosswalk$move_pair_id == pair_id
      ]
      links[[length(links) + 1L]] <- entity_link_record(
        link_type = "service_history_move_pair",
        source_entity_type = "physical_location",
        source_entity_id = physical_ids[[endpoints[[1]]]],
        target_entity_type = "physical_location",
        target_entity_id = physical_ids[[endpoints[[2]]]],
        evidence_state = "approved_sidecar",
        evidence_basis = paste0("approved_undirected_pair:", pair_id),
        source_inventory_path = inventory_path
      )
    }
  } else {
    inventory_path <- parser_inventory_path(
      snapshot,
      "^source_snapshot/four_table/site(\\.[^/]*)?$"
    )
    for (site in sites) {
      records[[length(records) + 1L]] <- entity_record(
        entity_type = "physical_location",
        entity_id = entity_identity(
          "physical_location",
          "four_table:site",
          site
        ),
        source_namespace = "four_table:site",
        source_identifier = site,
        resolution_state = "resolved",
        evidence_state = "compatibility_identity",
        evidence_basis = "exact_legacy_site_identifier",
        source_inventory_path = inventory_path
      )
    }
    records[[length(records) + 1L]] <- unresolved_scope_record(
      "nominal_grid_station",
      "four_table:nominal_grid_station",
      "no_explicit_nominal_station_evidence"
    )
  }
  records[[length(records) + 1L]] <- unresolved_scope_record(
    "deployment",
    "four_table:deployment",
    "no_authoritative_deployment_identity_or_interval"
  )
  records[[length(records) + 1L]] <- unresolved_scope_record(
    "analysis_site",
    "analysis:site",
    "analysis_site_unselected"
  )
  list(
    records = records,
    links = links,
    deployment_lineage = list(),
    integrity_findings = findings,
    crosswalk = crosswalk
  )
}

resolve_camtrapdp_entities <- function(config, snapshot, validation_state) {
  audit <- validation_state$parser_audit
  deployments <- audit$parsed_tables$deployments
  observations <- audit$parsed_tables$observations
  records <- list()
  links <- list()
  lineage <- list()
  findings <- list()
  inventory_path <- parser_inventory_path(
    snapshot,
    "^source_snapshot/camtrapdp/.*deployments.*"
  )

  if (!is.data.frame(deployments) ||
        !"deploymentID" %in% names(deployments)) {
    findings <- add_integrity_finding(
      findings,
      "camtrapdp.deployment_evidence_missing",
      "CamtrapDP deployment identity evidence is unavailable.",
      "deployments"
    )
    records[[1L]] <- unresolved_scope_record(
      "deployment",
      "camtrapdp:deployment",
      "deployment_evidence_absent"
    )
    records[[2L]] <- unresolved_scope_record(
      "physical_location",
      "camtrapdp:physical_location",
      "location_evidence_absent"
    )
  } else {
    deployment_ids <- as.character(deployments$deploymentID)
    location_ids <- if ("locationID" %in% names(deployments)) {
      as.character(deployments$locationID)
    } else {
      rep(NA_character_, nrow(deployments))
    }
    starts <- vapply(seq_len(nrow(deployments)), function(index) {
      if ("deploymentStart" %in% names(deployments)) {
        format_endpoint(deployments$deploymentStart[[index]])
      } else {
        NA_character_
      }
    }, character(1))
    ends <- vapply(seq_len(nrow(deployments)), function(index) {
      if ("deploymentEnd" %in% names(deployments)) {
        format_endpoint(deployments$deploymentEnd[[index]])
      } else {
        NA_character_
      }
    }, character(1))
    nonempty_locations <- sort(
      unique(location_ids[!is.na(location_ids) & nzchar(location_ids)]),
      method = "radix"
    )
    physical_ids <- stats::setNames(
      vapply(
        nonempty_locations,
        entity_identity,
        character(1),
        entity_type = "physical_location",
        source_namespace = "camtrapdp:locationID"
      ),
      nonempty_locations
    )
    for (location in nonempty_locations) {
      source_index <- which(location_ids == location)[[1]]
      records[[length(records) + 1L]] <- entity_record(
        entity_type = "physical_location",
        entity_id = physical_ids[[location]],
        source_namespace = "camtrapdp:locationID",
        source_identifier = location,
        resolution_state = "resolved",
        evidence_state = "supplied",
        evidence_basis = "explicit_camtrapdp_locationID",
        source_inventory_path = inventory_path,
        source_row_id = entity_source_row_id(
          validation_state,
          "deployments",
          source_index
        )
      )
    }

    missing_deployments <- which(is.na(deployment_ids) | !nzchar(deployment_ids))
    if (length(missing_deployments) > 0L) {
      records[[length(records) + 1L]] <- unresolved_scope_record(
        "deployment",
        "camtrapdp:deploymentID",
        "deployment_identity_absent"
      )
    }
    supplied_deployments <- sort(
      unique(deployment_ids[!is.na(deployment_ids) & nzchar(deployment_ids)]),
      method = "radix"
    )
    for (deployment in supplied_deployments) {
      indices <- which(deployment_ids == deployment)
      evidence <- data.frame(
        location = location_ids[indices],
        start = starts[indices],
        end = ends[indices],
        stringsAsFactors = FALSE
      )
      normalized_evidence <- lapply(evidence, function(column) {
        ifelse(is.na(column), "<absent>", column)
      })
      distinct_evidence <- unique(as.data.frame(
        normalized_evidence,
        stringsAsFactors = FALSE
      ))
      duplicated_identity <- length(indices) > 1L
      competing_evidence <- nrow(distinct_evidence) > 1L
      group_state <- if (competing_evidence) {
        "ambiguous"
      } else if (duplicated_identity) {
        "integrity_failure"
      } else {
        "resolved"
      }
      if (competing_evidence) {
        findings <- add_integrity_finding(
          findings,
          "camtrapdp.deployment_evidence_competing",
          paste(
            "CamtrapDP deployment has competing location or interval evidence:",
            deployment
          ),
          deployment
        )
      } else if (duplicated_identity) {
        findings <- add_integrity_finding(
          findings,
          "camtrapdp.deployment_identity_duplicate",
          paste("CamtrapDP deployment identity is duplicated:", deployment),
          deployment
        )
      }

      index <- indices[[1]]
      source_row_id <- entity_source_row_id(
        validation_state,
        "deployments",
        index
      )
      deployment_id <- entity_identity(
        "deployment",
        "camtrapdp:deploymentID",
        deployment
      )
      candidate_locations <- unique(location_ids[indices])
      location_absent <- is.na(candidate_locations) | !nzchar(candidate_locations)
      location_competing <- length(candidate_locations) > 1L
      location <- if (!location_competing &&
                        length(candidate_locations) == 1L &&
                        !location_absent[[1]]) {
        candidate_locations[[1]]
      } else {
        NA_character_
      }
      location_ok <- !is.na(location)
      interval_competing <- nrow(unique(distinct_evidence[c("start", "end")])) > 1L
      start <- if (!interval_competing) starts[[index]] else NA_character_
      end <- if (!interval_competing) ends[[index]] else NA_character_
      endpoints_supplied <- !is.na(start) && !is.na(end)
      reversed <- endpoints_supplied &&
        as.POSIXct(start, tz = "UTC") > as.POSIXct(end, tz = "UTC")
      if (reversed) {
        findings <- add_integrity_finding(
          findings,
          "camtrapdp.deployment_interval_reversed",
          paste("Deployment interval is reversed:", deployment),
          deployment
        )
      }
      lineage_state <- if (competing_evidence) {
        "ambiguous"
      } else if (duplicated_identity || reversed) {
        "integrity_failure"
      } else if (!location_ok || !endpoints_supplied) {
        "unresolved"
      } else {
        "resolved"
      }
      records[[length(records) + 1L]] <- entity_record(
        entity_type = "deployment",
        entity_id = deployment_id,
        source_namespace = "camtrapdp:deploymentID",
        source_identifier = deployment,
        resolution_state = group_state,
        evidence_state = "supplied",
        evidence_basis = "explicit_camtrapdp_deploymentID",
        source_inventory_path = inventory_path,
        source_row_id = source_row_id
      )
      location_entity_id <- if (location_ok) {
        physical_ids[[location]]
      } else {
        NA_character_
      }
      if (location_ok && !duplicated_identity) {
        links[[length(links) + 1L]] <- entity_link_record(
          link_type = "deployment_to_physical_location",
          source_entity_type = "deployment",
          source_entity_id = deployment_id,
          target_entity_type = "physical_location",
          target_entity_id = location_entity_id,
          evidence_state = "supplied",
          evidence_basis = "explicit_camtrapdp_locationID",
          source_inventory_path = inventory_path,
          source_row_id = source_row_id
        )
      }
      for (evidence_index in indices) {
        candidate_location <- location_ids[[evidence_index]]
        candidate_location_ok <- !is.na(candidate_location) &&
          nzchar(candidate_location)
        candidate_location_entity_id <- if (candidate_location_ok) {
          physical_ids[[candidate_location]]
        } else {
          NA_character_
        }
        candidate_start <- starts[[evidence_index]]
        candidate_end <- ends[[evidence_index]]
        candidate_endpoints_supplied <- !is.na(candidate_start) &&
          !is.na(candidate_end)
        candidate_reversed <- candidate_endpoints_supplied &&
          as.POSIXct(candidate_start, tz = "UTC") >
            as.POSIXct(candidate_end, tz = "UTC")
        lineage[[length(lineage) + 1L]] <- deployment_lineage_record(
          deployment_identifier = deployment,
          deployment_entity_id = deployment_id,
          physical_location_entity_id = candidate_location_entity_id,
          interval_start = candidate_start,
          interval_end = candidate_end,
          interval_evidence_state = if (interval_competing) {
            "ambiguous_competing_endpoints"
          } else if (candidate_endpoints_supplied) {
            "explicit_endpoints"
          } else {
            "unresolved_missing_endpoint"
          },
          chronology_state = if (interval_competing) {
            "ambiguous"
          } else if (candidate_endpoints_supplied && !candidate_reversed) {
            "ordered_explicit_interval"
          } else {
            "unresolved"
          },
          resolution_state = lineage_state,
          evidence_basis = "explicit_camtrapdp_deployment_fields",
          source_inventory_path = inventory_path,
          source_row_id = entity_source_row_id(
            validation_state,
            "deployments",
            evidence_index
          )
        )
      }
    }

    if (is.data.frame(observations) &&
          "deploymentID" %in% names(observations)) {
      observation_ids <- unique(as.character(observations$deploymentID))
      orphans <- setdiff(
        observation_ids[!is.na(observation_ids) & nzchar(observation_ids)],
        deployment_ids[!is.na(deployment_ids) & nzchar(deployment_ids)]
      )
      if (length(orphans) > 0L) {
        findings <- add_integrity_finding(
          findings,
          "camtrapdp.observation_deployment_orphan",
          paste(
            "Observations reference missing deployments:",
            paste(sort(orphans), collapse = ", ")
          ),
          "observations"
        )
      }
    }
  }
  records[[length(records) + 1L]] <- unresolved_scope_record(
    "nominal_grid_station",
    "camtrapdp:nominal_grid_station",
    "no_explicit_nominal_station_evidence"
  )
  records[[length(records) + 1L]] <- unresolved_scope_record(
    "analysis_site",
    "analysis:site",
    "analysis_site_unselected"
  )
  list(
    records = records,
    links = links,
    deployment_lineage = lineage,
    integrity_findings = findings,
    crosswalk = NULL
  )
}

entity_count_records <- function(records) {
  if (nrow(records) == 0L) {
    return(list())
  }
  counts <- aggregate(
    rep(1L, nrow(records)),
    records[c("entity_type", "resolution_state", "evidence_state")],
    sum
  )
  names(counts)[[4]] <- "count"
  counts <- counts[order(
    counts$entity_type,
    counts$resolution_state,
    counts$evidence_state,
    method = "radix"
  ), ]
  lapply(seq_len(nrow(counts)), function(index) {
    list(
      entity_type = counts$entity_type[[index]],
      resolution_state = counts$resolution_state[[index]],
      evidence_state = counts$evidence_state[[index]],
      count = as.integer(counts$count[[index]])
    )
  })
}

link_count_records <- function(links) {
  types <- c(
    "physical_location_to_nominal_grid_station",
    "deployment_to_physical_location",
    "service_history_move_pair",
    "analysis_site_membership"
  )
  lapply(types, function(type) {
    list(
      link_type = type,
      count = as.integer(sum(links$link_type == type))
    )
  })
}

build_join_readiness <- function(
    config,
    validation_state,
    selected,
    links,
    deployment_lineage,
    entity_digest,
    source_sha256) {
  inputs <- validation_state$inputs
  op_keys <- setdiff(names(inputs$op), "date")
  obs_count <- nrow(inputs$obs)
  if (identical(config$input_mode, "camtrapdp")) {
    routing_ready <- unique(deployment_lineage$deployment_identifier[
      deployment_lineage$resolution_state == "resolved"
    ])
    linked_deployment_entities <- links$source_entity_id[
      links$link_type == "deployment_to_physical_location"
    ]
    physical_ready <- unique(deployment_lineage$deployment_identifier[
      deployment_lineage$deployment_entity_id %in% linked_deployment_entities
    ])
    ambiguous_deployments <- unique(deployment_lineage$deployment_identifier[
      deployment_lineage$resolution_state == "ambiguous"
    ])
    physical_ambiguous <- setdiff(ambiguous_deployments, physical_ready)
    deployment_ambiguous <- ambiguous_deployments
    observation_keys <- as.character(inputs$obs$site)
    keys <- list(
      effort_columns = op_keys,
      observation_rows = observation_keys
    )
    ready <- list(
      physical_location = physical_ready,
      nominal_grid_station = character(),
      deployment = routing_ready
    )
    ambiguous <- list(
      physical_location = physical_ambiguous,
      nominal_grid_station = character(),
      deployment = deployment_ambiguous
    )
  } else {
    observation_keys <- as.character(inputs$obs$site)
    keys <- list(
      effort_columns = op_keys,
      observation_rows = observation_keys
    )
    ready <- list(
      physical_location = unique(c(op_keys, observation_keys)),
      nominal_grid_station = if (selected) {
        unique(c(op_keys, observation_keys))
      } else {
        character()
      },
      deployment = character()
    )
    ambiguous <- list(
      physical_location = character(),
      nominal_grid_station = character(),
      deployment = character()
    )
  }
  results <- list()
  for (scope in names(keys)) {
    for (level in names(ready)) {
      scope_keys <- keys[[scope]]
      unique_count <- as.integer(sum(scope_keys %in% ready[[level]]))
      ambiguous_count <- as.integer(sum(
        scope_keys %in% ambiguous[[level]] &
          !scope_keys %in% ready[[level]]
      ))
      unresolved_count <- as.integer(
        length(scope_keys) - unique_count - ambiguous_count
      )
      results[[length(results) + 1L]] <- list(
        source_scope = scope,
        requested_entity_level = level,
        evidence_basis = if (ambiguous_count > 0L) {
          "competing_explicit_entity_evidence"
        } else if (unique_count == length(scope_keys)) {
          "exact_explicit_entity_evidence"
        } else if (unique_count > 0L) {
          "mixed_explicit_and_absent_entity_evidence"
        } else {
          "optional_entity_evidence_absent"
        },
        source_count = as.integer(length(scope_keys)),
        unique = unique_count,
        unresolved = unresolved_count,
        ambiguous = ambiguous_count
      )
    }
  }
  list(
    join_readiness_schema = join_readiness_schema,
    rule_version = "camtrap-entity-join-readiness/1.0",
    classification_values = c("unique", "unresolved", "ambiguous"),
    source_sha256 = source_sha256,
    entity_ledger_digest = entity_digest,
    results = results
  )
}

#' Resolve versioned entity evidence without changing analytical inputs
#'
#' @param config Effective configuration.
#' @param snapshot Immutable source snapshot.
#' @param validation_state Preflight state containing inputs and parser audit.
#' @return Entity-resolution evidence state.
resolve_entity_evidence <- function(config, snapshot, validation_state) {
  selection <- entity_resolution_selection(config, require_explicit = TRUE)
  source_sha256 <- validate_entity_source(
    config,
    snapshot,
    selection
  )
  if (!is.list(validation_state$inputs) ||
        !all(c("site", "op", "obs", "taxa") %in% names(validation_state$inputs))) {
    stop("Entity resolver requires the four validated analytical inputs.")
  }
  result <- if (identical(config$input_mode, "camtrapdp")) {
    resolve_camtrapdp_entities(config, snapshot, validation_state)
  } else {
    resolve_four_table_entities(
      config,
      snapshot,
      validation_state,
      selection
    )
  }
  records <- entity_records_frame(result$records)
  links <- entity_links_frame(result$links)
  deployment_lineage <- deployment_lineage_frame(result$deployment_lineage)
  selected <- entity_resolution_is_selected(selection)
  inventory_path <- if (selected) {
    inventory_path_for_role(snapshot, "entity_resolution_input")
  } else {
    NULL
  }
  entity_digest <- sha256_text(canonical_json(list(
    records = records,
    links = links,
    deployment_lineage = deployment_lineage
  )))
  crosswalk_summary <- if (selected) {
    list(
      schema = judbury_entity_profile()$crosswalk_schema,
      version = judbury_entity_profile()$crosswalk_version,
      sha256 = selection$sidecar_sha256,
      source_inventory_path = inventory_path,
      rows = as.integer(nrow(result$crosswalk))
    )
  } else {
    NULL
  }
  summary <- list(
    entity_resolution_summary_schema = entity_summary_schema,
    resolver_version = entity_resolver_version,
    selected_profile = selection$profile_id,
    sidecar_source_inventory_path = inventory_path,
    configured_sidecar_sha256 = selection$sidecar_sha256,
    authority_reference = selection$authority_reference,
    crosswalk = crosswalk_summary,
    entity_counts = entity_count_records(records),
    link_counts = link_count_records(links),
    unresolved_count = as.integer(sum(records$resolution_state == "unresolved")),
    ambiguous_count = as.integer(sum(records$resolution_state == "ambiguous")),
    integrity_findings = result$integrity_findings,
    ledger_content_sha256 = entity_digest,
    analysis_site_status = "unselected",
    analysis_site_membership_count = 0L
  )
  join_readiness <- build_join_readiness(
    config,
    validation_state,
    selected,
    links,
    deployment_lineage,
    entity_digest,
    source_sha256
  )
  list(
    entity_resolution_state_schema = "camtrap-entity-resolution-state/1.0",
    records = records,
    links = links,
    deployment_lineage = deployment_lineage,
    summary = summary,
    join_readiness = join_readiness,
    integrity_findings = result$integrity_findings,
    can_analyze = length(result$integrity_findings) == 0L
  )
}

write_entity_csv <- function(value, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  if (file.exists(path)) {
    stop("Refusing to overwrite entity evidence artifact: ", path)
  }
  temporary <- tempfile(
    pattern = paste0(".", basename(path), "."),
    tmpdir = dirname(path)
  )
  on.exit(unlink(temporary, force = TRUE), add = TRUE)
  readr::write_csv(value, temporary, na = "")
  if (!file.rename(temporary, path)) {
    stop("Atomic entity evidence CSV publication failed: ", path)
  }
  invisible(path)
}

entity_artifact_paths <- function(root) {
  directory <- file.path(root, "provenance", "entity_resolution")
  list(
    entity_resolution = file.path(directory, "entity_resolution.csv"),
    entity_links = file.path(directory, "entity_links.csv"),
    deployment_lineage = file.path(directory, "deployment_lineage.csv"),
    entity_resolution_summary = file.path(
      directory,
      "entity_resolution_summary.json"
    ),
    join_readiness = file.path(directory, "join_readiness.json")
  )
}

#' Write the five Goal 007 entity evidence artifacts
#'
#' @param state Entity-resolution evidence state.
#' @param root Staging or bundle root.
#' @return Named artifact paths.
write_entity_artifacts <- function(state, root) {
  paths <- entity_artifact_paths(root)
  write_entity_csv(state$records, paths$entity_resolution)
  write_entity_csv(state$links, paths$entity_links)
  write_entity_csv(state$deployment_lineage, paths$deployment_lineage)
  summary <- state$summary
  summary$ledger_sha256 <- list(
    entity_resolution = sha256_file(paths$entity_resolution),
    entity_links = sha256_file(paths$entity_links),
    deployment_lineage = sha256_file(paths$deployment_lineage)
  )
  atomic_write_json(summary, paths$entity_resolution_summary)
  atomic_write_json(state$join_readiness, paths$join_readiness)
  paths
}

read_entity_csv <- function(path) {
  utils::read.csv(
    path,
    stringsAsFactors = FALSE,
    na.strings = "",
    check.names = FALSE
  )
}

validate_entity_record_digests <- function(frame) {
  if (nrow(frame) == 0L) {
    return(invisible(TRUE))
  }
  digest_field <- "record_digest"
  for (index in seq_len(nrow(frame))) {
    record <- as.list(frame[index, setdiff(names(frame), digest_field), drop = FALSE])
    record <- lapply(record, function(value) {
      if (length(value) == 1L && is.na(value)) NA_character_ else as.character(value)
    })
    expected <- sha256_text(canonical_json(record))
    if (!identical(expected, frame[[digest_field]][[index]])) {
      stop("Entity evidence record digest mismatch.")
    }
  }
  invisible(TRUE)
}

reconstruct_entity_state <- function(root) {
  config_path <- file.path(root, "provenance", "config.raw.yml")
  config <- read_config(config_path, attach_runtime = FALSE)
  snapshot <- portable_validation_snapshot(root, config)
  validation_state <- prepare_validation_preflight(
    config,
    snapshot,
    camtrapdp_reader = read_camtrapdp_dataset,
    camtrapdp_adapter = camtrapdp_to_internal
  )
  resolve_entity_evidence(config, snapshot, validation_state)
}

#' Validate and semantically reconstruct Goal 007 evidence
#'
#' @param root Preview or bundle root.
#' @param paths Named entity artifact paths.
#' @param require_analysis_ready Whether integrity findings are forbidden.
#' @return TRUE invisibly.
validate_entity_artifacts <- function(
    root,
    paths,
    require_analysis_ready = FALSE) {
  expected_paths <- entity_artifact_paths(root)
  required <- names(expected_paths)
  if (!is.list(paths) || !identical(paths, expected_paths)) {
    stop(
      "Entity-resolution artifacts must use the exact canonical five-file ",
      "namespace."
    )
  }
  directory <- dirname(expected_paths$entity_resolution)
  if (!dir.exists(directory) || nzchar(Sys.readlink(directory))) {
    stop("Entity-resolution canonical namespace is missing or is a symlink.")
  }
  entries <- list.files(
    directory,
    all.files = TRUE,
    no.. = TRUE,
    recursive = TRUE,
    include.dirs = TRUE
  )
  expected_entries <- basename(unlist(expected_paths, use.names = FALSE))
  if (!identical(
    sort(entries, method = "radix"),
    sort(expected_entries, method = "radix")
  )) {
    stop(
      "Entity-resolution artifacts must use the exact canonical five-file ",
      "namespace."
    )
  }
  for (name in required) {
    assert_path_within_root(
      paths[[name]],
      root,
      paste("Entity-resolution artifact", name)
    )
    if (isTRUE(file.info(paths[[name]])$isdir) ||
          nzchar(Sys.readlink(paths[[name]]))) {
      stop("Entity-resolution artifact is missing or is a symlink: ", name)
    }
  }
  records <- read_entity_csv(paths$entity_resolution)
  links <- read_entity_csv(paths$entity_links)
  deployments <- read_entity_csv(paths$deployment_lineage)
  validate_entity_record_digests(records)
  validate_entity_record_digests(links)
  validate_entity_record_digests(deployments)
  summary <- jsonlite::read_json(
    paths$entity_resolution_summary,
    simplifyVector = FALSE
  )
  readiness <- jsonlite::read_json(paths$join_readiness, simplifyVector = FALSE)
  if (!identical(summary$entity_resolution_summary_schema, entity_summary_schema) ||
        !identical(readiness$join_readiness_schema, join_readiness_schema) ||
        !identical(summary$analysis_site_status, "unselected") ||
        !identical(as.integer(summary$analysis_site_membership_count), 0L) ||
        any(links$link_type == "analysis_site_membership")) {
    stop("Entity-resolution analysis_site contract is invalid.")
  }
  for (name in c(
    "entity_resolution",
    "entity_links",
    "deployment_lineage"
  )) {
    if (!identical(
      summary$ledger_sha256[[name]],
      sha256_file(paths[[name]])
    )) {
      stop("Entity-resolution ledger SHA-256 mismatch: ", name)
    }
  }
  reconstructed <- reconstruct_entity_state(root)
  temporary <- tempfile("entity-reconstruction-")
  dir.create(temporary)
  reconstructed_paths <- write_entity_artifacts(
    reconstructed,
    temporary
  )
  on.exit(unlink(temporary, recursive = TRUE, force = TRUE), add = TRUE)
  for (name in required) {
    observed <- if (grepl("\\.csv$", paths[[name]])) {
      canonical_json(read_entity_csv(paths[[name]]))
    } else {
      canonical_json(jsonlite::read_json(paths[[name]], simplifyVector = FALSE))
    }
    expected <- if (grepl("\\.csv$", reconstructed_paths[[name]])) {
      canonical_json(read_entity_csv(reconstructed_paths[[name]]))
    } else {
      canonical_json(jsonlite::read_json(
        reconstructed_paths[[name]],
        simplifyVector = FALSE
      ))
    }
    if (!identical(observed, expected)) {
      stop("Entity evidence does not reproduce from immutable source: ", name)
    }
  }
  if (isTRUE(require_analysis_ready) && !isTRUE(reconstructed$can_analyze)) {
    stop("Entity-resolution integrity findings block analysis.")
  }
  invisible(TRUE)
}
