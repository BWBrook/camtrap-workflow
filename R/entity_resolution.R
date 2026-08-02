# Versioned entity-resolution evidence.

entity_resolver_version <- "camtrap-entity-resolver/1.0"
entity_record_schema <- "camtrap-entity-resolution/1.0"
entity_link_schema <- "camtrap-entity-links/1.0"
deployment_lineage_schema <- "camtrap-deployment-lineage/1.1"
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

deployment_evidence_null_selection <- function() { # nolint: object_length_linter.
  list(
    profile_id = NULL,
    service_sidecar_path = NULL,
    service_sidecar_sha256 = NULL,
    deployment_ledger_path = NULL,
    deployment_ledger_sha256 = NULL,
    authority_reference = NULL
  )
}

judbury_deployment_profile <- function() {
  service_sha256 <-
    "f33eeac9d70126966717c8e3f4731c00a97cbc3a34c2f44ce5c70d91c7d5283a"
  ledger_sha256 <-
    "0921eb8845c2bb1ad5760271f283ab2783735b7739e254c67e9243bc906f3ebf"
  list(
    profile_id = "judbury-deployment-evidence/1.0.0-proposed",
    service_sidecar_path = "data/jc_services.csv",
    service_sidecar_sha256 = service_sha256,
    deployment_ledger_path = paste0(
      "docs/goals/008-judbury-deployment-evidence/",
      "judbury_deployment_ledger.csv"
    ),
    deployment_ledger_sha256 = ledger_sha256,
    authority_reference = paste0(
      "goal008-judbury-deployment-evidence-source-sha256-",
      service_sha256,
      "-ledger-sha256-",
      ledger_sha256
    ),
    service_source_schema = "judbury-camera-service-history/1.0",
    service_source_version = "judbury-jc-services/1.0.0-proposed",
    deployment_ledger_schema = "camtrap-deployment-evidence-ledger/1.0",
    deployment_ledger_version =
      "judbury-deployment-evidence-ledger/1.0.0-proposed",
    operation_authority_path = "data/jc_op.csv",
    operation_authority_sha256 =
      "28222586fa232fccc46bfab5e8c07e0c453f07387ebe4eb95b9a90e4687033a3"
  )
}

deployment_evidence_selection <- function(config, require_explicit = FALSE) {
  selection <- config$deployment_evidence
  if (is.null(selection)) {
    if (isTRUE(require_explicit)) {
      stop(
        "Supported Goal 008 runs require an explicit deployment_evidence ",
        "selection or explicit null selection."
      )
    }
    return(NULL)
  }
  fields <- names(deployment_evidence_null_selection())
  if (!is.list(selection) ||
        !identical(sort(names(selection)), sort(fields))) {
    stop(
      "deployment_evidence must contain exactly profile_id, ",
      "service_sidecar_path, service_sidecar_sha256, ",
      "deployment_ledger_path, deployment_ledger_sha256, and ",
      "authority_reference."
    )
  }
  values <- selection[fields]
  nulls <- vapply(values, is.null, logical(1))
  if (all(nulls)) {
    return(deployment_evidence_null_selection())
  }
  if (any(nulls) ||
    !all(vapply(values, function(value) {
      is.character(value) && length(value) == 1L && nzchar(value)
    }, logical(1)))) {
    stop(
      "deployment_evidence must be either an exact null selection or a ",
      "complete selected profile."
    )
  }
  expected <- judbury_deployment_profile()[fields]
  if (!identical(selection[fields], expected)) {
    stop("Selected deployment-evidence profile has no exact approved authority.")
  }
  if (!identical(config$input_mode, "four_table")) {
    stop(
      "The approved Judbury deployment-evidence profile is only valid ",
      "when input_mode = 'four_table'."
    )
  }
  entity_selection <- entity_resolution_selection(config, require_explicit = TRUE)
  if (!entity_resolution_is_selected(entity_selection)) {
    stop(
      "Selected Goal 008 evidence requires the exact Goal 007 ",
      "entity-resolution selection."
    )
  }
  selection
}

deployment_evidence_is_selected <- function(selection) { # nolint: object_length_linter.
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
    source_row_id = NA_character_,
    physical_location_identifier = NA_character_,
    date_precision = NA_character_,
    endpoint_semantics = NA_character_,
    start_service_label = NA_character_,
    end_service_label = NA_character_,
    service_event_count = NA_character_,
    service_event_digest = NA_character_,
    predecessor_deployment_id = NA_character_,
    successor_deployment_id = NA_character_,
    service_source_schema = NA_character_,
    service_source_version = NA_character_,
    service_source_inventory_path = NA_character_,
    service_source_sha256 = NA_character_,
    service_source_row_ordinal = NA_character_,
    service_source_row_id = NA_character_,
    deployment_ledger_schema = NA_character_,
    deployment_ledger_version = NA_character_,
    deployment_ledger_inventory_path = NA_character_, # nolint: object_length_linter.
    deployment_ledger_sha256 = NA_character_,
    deployment_ledger_row_ordinal = NA_character_,
    deployment_ledger_row_id = NA_character_,
    approval_reference = NA_character_,
    operation_authority_inventory_path = NA_character_, # nolint: object_length_linter.
    operation_authority_sha256 = NA_character_,
    run_days_disposition = NA_character_) {
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
  record <- c(record, list(
    physical_location_identifier = physical_location_identifier,
    date_precision = date_precision,
    endpoint_semantics = endpoint_semantics,
    start_service_label = start_service_label,
    end_service_label = end_service_label,
    service_event_count = service_event_count,
    service_event_digest = service_event_digest,
    predecessor_deployment_id = predecessor_deployment_id,
    successor_deployment_id = successor_deployment_id,
    service_source_schema = service_source_schema,
    service_source_version = service_source_version,
    service_source_inventory_path = service_source_inventory_path,
    service_source_sha256 = service_source_sha256,
    service_source_row_ordinal = service_source_row_ordinal,
    service_source_row_id = service_source_row_id,
    deployment_ledger_schema = deployment_ledger_schema,
    deployment_ledger_version = deployment_ledger_version,
    deployment_ledger_inventory_path = deployment_ledger_inventory_path,
    deployment_ledger_sha256 = deployment_ledger_sha256,
    deployment_ledger_row_ordinal = deployment_ledger_row_ordinal,
    deployment_ledger_row_id = deployment_ledger_row_id,
    approval_reference = approval_reference,
    operation_authority_inventory_path = operation_authority_inventory_path,
    operation_authority_sha256 = operation_authority_sha256,
    run_days_disposition = run_days_disposition
  ))
  record <- lapply(record, function(value) {
    if (is.null(value) || length(value) == 0L || is.na(value)) {
      NA_character_
    } else {
      as.character(value)
    }
  })
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
  columns <- c(
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
    "source_row_id"
  )
  columns <- c(columns, c(
    "physical_location_identifier",
    "date_precision",
    "endpoint_semantics",
    "start_service_label",
    "end_service_label",
    "service_event_count",
    "service_event_digest",
    "predecessor_deployment_id",
    "successor_deployment_id",
    "service_source_schema",
    "service_source_version",
    "service_source_inventory_path",
    "service_source_sha256",
    "service_source_row_ordinal",
    "service_source_row_id",
    "deployment_ledger_schema",
    "deployment_ledger_version",
    "deployment_ledger_inventory_path",
    "deployment_ledger_sha256",
    "deployment_ledger_row_ordinal",
    "deployment_ledger_row_id",
    "approval_reference",
    "operation_authority_inventory_path",
    "operation_authority_sha256",
    "run_days_disposition"
  ))
  result <- records_frame(records, c(columns, "record_digest"))
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

validate_deployment_evidence_source <- function( # nolint: object_length_linter.
    config,
    snapshot,
    selection) {
  inventory <- snapshot$inventory
  if (!is.list(inventory) || length(inventory) == 0L) {
    stop("Deployment evidence requires a non-empty immutable source inventory.")
  }
  roles <- vapply(inventory, `[[`, character(1), "role")
  service_matches <- which(roles == "deployment_service_input")
  ledger_matches <- which(roles == "deployment_ledger_input")
  inventory_paths <- vapply(inventory, `[[`, character(1), "path")
  namespace_matches <- grep(
    "^source_snapshot/deployment_evidence/",
    inventory_paths
  )
  paths <- snapshot$deployment_evidence_paths
  if (is.null(paths)) {
    paths <- list(service = NULL, ledger = NULL)
  }
  if (!is.list(paths) ||
        !identical(sort(names(paths)), c("ledger", "service"))) {
    stop("Deployment-evidence snapshot paths have an invalid shape.")
  }

  selected <- deployment_evidence_is_selected(selection)
  if (!selected) {
    if (length(service_matches) != 0L ||
          length(ledger_matches) != 0L ||
          length(namespace_matches) != 0L) {
      stop(
        "An unselected deployment_evidence profile requires zero ",
        "deployment-evidence sidecars in the source inventory."
      )
    }
    if (!is.null(paths$service) || !is.null(paths$ledger)) {
      stop(
        "An unselected deployment_evidence profile may not expose dedicated ",
        "deployment-evidence paths."
      )
    }
  } else {
    if (!identical(config$input_mode, "four_table")) {
      stop(
        "The approved Judbury deployment-evidence profile is only valid ",
        "when input_mode = 'four_table'."
      )
    }
    if (length(service_matches) != 1L) {
      stop(
        "A selected deployment-evidence profile requires exactly one ",
        "deployment service sidecar in the source inventory."
      )
    }
    if (length(ledger_matches) != 1L) {
      stop(
        "A selected deployment-evidence profile requires exactly one ",
        "deployment ledger in the source inventory."
      )
    }
    expected_indices <- sort(c(service_matches, ledger_matches))
    if (!identical(sort(namespace_matches), expected_indices)) {
      stop(
        "The deployment-evidence source namespace contains an extra or ",
        "misclassified file."
      )
    }
    if (!is.character(snapshot$snapshot_root) ||
          length(snapshot$snapshot_root) != 1L ||
          !dir.exists(snapshot$snapshot_root)) {
      stop("Deployment-evidence snapshot root is unavailable.")
    }
    staging_root <- dirname(snapshot$snapshot_root)
    specifications <- list(
      service = list(
        index = service_matches,
        role = "deployment_service_input",
        path_pattern =
          "^source_snapshot/deployment_evidence/service/[^/]+$",
        sha256 = selection$service_sidecar_sha256
      ),
      ledger = list(
        index = ledger_matches,
        role = "deployment_ledger_input",
        path_pattern =
          "^source_snapshot/deployment_evidence/ledger/[^/]+$",
        sha256 = selection$deployment_ledger_sha256
      )
    )
    for (name in names(specifications)) {
      specification <- specifications[[name]]
      record <- inventory[[specification$index]]
      path <- paths[[name]]
      assert_safe_relative_path(
        record$path,
        paste("Deployment", name, "source inventory path")
      )
      if (!identical(record$role, specification$role) ||
            !grepl(specification$path_pattern, record$path) ||
            !identical(record$consumed_by_parser, FALSE) ||
            !identical(record$sha256, specification$sha256)) {
        stop(
          "The selected deployment ", name,
          " does not match its exact non-parser source-inventory authority."
        )
      }
      if (!is.character(path) ||
            length(path) != 1L ||
            is.na(path) ||
            !nzchar(path)) {
        stop(
          "A selected deployment-evidence profile requires one dedicated ",
          name, " snapshot path."
        )
      }
      expected_path <- file.path(staging_root, record$path)
      assert_path_within_root(
        expected_path,
        staging_root,
        paste("Deployment", name, "source inventory path")
      )
      assert_path_within_root(
        path,
        staging_root,
        paste("Deployment", name, "snapshot path")
      )
      if (nzchar(Sys.readlink(path)) ||
        !identical(
          normalizePath(expected_path, winslash = "/", mustWork = TRUE),
          normalizePath(path, winslash = "/", mustWork = TRUE)
        ) ||
        !identical(sha256_file(path), record$sha256)) {
        stop(
          "The selected deployment ", name,
          " path and source-inventory record do not reconcile."
        )
      }
    }
    evidence_root <- file.path(snapshot$snapshot_root, "deployment_evidence")
    actual_files <- if (dir.exists(evidence_root)) {
      sort(
        normalizePath(
          list.files(
            evidence_root,
            recursive = TRUE,
            full.names = TRUE,
            all.files = TRUE,
            include.dirs = FALSE,
            no.. = TRUE
          ),
          winslash = "/",
          mustWork = TRUE
        ),
        method = "radix"
      )
    } else {
      character()
    }
    expected_files <- sort(
      normalizePath(
        unlist(paths, use.names = FALSE),
        winslash = "/",
        mustWork = TRUE
      ),
      method = "radix"
    )
    if (!identical(actual_files, expected_files)) {
      stop(
        "The deployment-evidence snapshot namespace contains an extra, ",
        "missing, or duplicate file."
      )
    }
  }

  source_sha256 <- fixity_identity(inventory)
  if (!is.character(snapshot$source_sha256) ||
        length(snapshot$source_sha256) != 1L ||
        !grepl("^[a-f0-9]{64}$", snapshot$source_sha256) ||
        !identical(source_sha256, snapshot$source_sha256)) {
    stop(
      "Deployment evidence cannot reproduce the immutable source identity."
    )
  }
  source_sha256
}

parser_inventory_path <- function(snapshot, pattern) {
  paths <- vapply(snapshot$inventory, `[[`, character(1), "path")
  matches <- grep(pattern, paths)
  if (length(matches) == 1L) paths[[matches]] else NA_character_
}

deployment_operation_inventory_record <- function(snapshot) { # nolint: object_length_linter.
  profile <- judbury_deployment_profile()
  matches <- vapply(snapshot$inventory, function(record) {
    identical(record$role, "parser_input") &&
      isTRUE(record$consumed_by_parser) &&
      grepl("^source_snapshot/four_table/op(\\.[^/]*)?$", record$path)
  }, logical(1))
  if (sum(matches) != 1L) {
    stop(
      "Approved deployment evidence requires exactly one immutable daily ",
      "operation authority."
    )
  }
  record <- snapshot$inventory[[which(matches)]]
  if (!identical(record$sha256, profile$operation_authority_sha256)) {
    stop("Daily operation authority SHA-256 does not match approved evidence.")
  }
  staging_root <- dirname(snapshot$snapshot_root)
  path <- file.path(staging_root, record$path)
  assert_path_within_root(path, staging_root, "Daily operation authority path")
  if (!identical(sha256_file(path), profile$operation_authority_sha256)) {
    stop("Daily operation authority changed after immutable snapshotting.")
  }
  record
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

judbury_service_aliases <- function() {
  c(
    jc_cen = "jc_cen",
    jc_co_1 = "jc_co1",
    jc_co_1_s1 = "jc_co1_s1",
    jc_co_2 = "jc_co2",
    jc_co_3 = "jc_co3",
    `jc_co_3_s1-6` = "jc_co3_s16",
    `jc-co-4` = "jc_co4",
    `jc-pm-12` = "jc_pm12",
    `jc-pm-14` = "jc_pm14",
    `jc-pm-14_s1` = "jc_pm14_s1",
    `jc-pm-23` = "jc_pm23",
    `jc-pm-34` = "jc_pm34",
    `jc-pm-34_s1-5` = "jc_pm34_s15"
  )
}

judbury_service_header <- function() {
  c(
    "site",
    "s0.date",
    "s1.run_days",
    "s1.date",
    "s2.run_days",
    "s2.date",
    "s3.run_days",
    "s3.date",
    "s4.run_days",
    "s4.date",
    "s5.run_days",
    "s5.date",
    "s6.run_days",
    "s6.date",
    "s7.run_days",
    "s7.date"
  )
}

deployment_evidence_row_identity <- function( # nolint: object_length_linter.
    source_kind,
    source_sha256,
    row_ordinal) {
  sha256_text(canonical_json(list(
    identity_schema = "camtrap-deployment-evidence-row-id/1.0",
    source_kind = as.character(source_kind),
    source_sha256 = as.character(source_sha256),
    row_ordinal = as.character(row_ordinal)
  )))
}

parse_judbury_service_date <- function(value) {
  if (!is.character(value) ||
        length(value) != 1L ||
        is.na(value) ||
        !grepl("^[0-9]{1,2}/[0-9]{2}/[0-9]{4}$", value)) {
    stop("Service source contains a malformed service date.")
  }
  parts <- strsplit(value, "/", fixed = TRUE)[[1]]
  normalized <- sprintf(
    "%02d/%02d/%04d",
    as.integer(parts[[1]]),
    as.integer(parts[[2]]),
    as.integer(parts[[3]])
  )
  parsed <- suppressWarnings(as.Date(normalized, format = "%d/%m/%Y"))
  if (is.na(parsed) ||
        !identical(format(parsed, "%d/%m/%Y"), normalized)) {
    stop("Service source contains a malformed service date.")
  }
  format(parsed, "%Y-%m-%d")
}

read_judbury_service_events <- function(path) {
  if (!file.exists(path) || isTRUE(file.info(path)$isdir)) {
    stop("Judbury service source is missing or not a file.")
  }
  if (nzchar(Sys.readlink(path))) {
    stop("Judbury service source may not be a symlink.")
  }
  source <- utils::read.csv(
    path,
    stringsAsFactors = FALSE,
    colClasses = "character",
    na.strings = "NA",
    check.names = FALSE
  )
  if (anyDuplicated(names(source))) {
    stop("Service source contains a duplicate service label.")
  }
  if (!identical(names(source), judbury_service_header())) {
    stop("Judbury service source fields do not match the closed 16-column schema.")
  }
  aliases <- judbury_service_aliases()
  if (nrow(source) != 13L ||
        any(is.na(source$site) | !nzchar(source$site)) ||
        anyDuplicated(source$site)) {
    stop("Judbury service source must contain 13 exact unique rows.")
  }
  if (any(!source$site %in% names(aliases))) {
    stop("Judbury service source contains an unlisted raw alias.")
  }
  if (!identical(source$site, names(aliases))) {
    stop("Judbury service source rows do not match the exact approved order.")
  }

  source_sha256 <- sha256_file(path)
  row_records <- vector("list", nrow(source))
  event_records <- list()
  for (row_index in seq_len(nrow(source))) {
    raw_id <- source$site[[row_index]]
    physical_id <- unname(aliases[[raw_id]])
    date_values <- vapply(0:7, function(label_index) {
      source[[paste0("s", label_index, ".date")]][[row_index]]
    }, character(1))
    populated <- which(!is.na(date_values) & nzchar(date_values))
    if (length(populated) < 2L) {
      stop("Judbury service row has fewer than two deployment-boundary events.")
    }
    expected_populated <- seq.int(min(populated), max(populated))
    if (!identical(populated, expected_populated)) {
      stop("Judbury service row has a missing service label.")
    }

    row_events <- vector("list", length(populated))
    parsed_dates <- character(length(populated))
    for (event_index in seq_along(populated)) {
      label_index <- populated[[event_index]] - 1L
      service_label <- paste0("S", label_index)
      iso_date <- parse_judbury_service_date(date_values[[populated[[event_index]]]])
      parsed_dates[[event_index]] <- iso_date
      run_days <- if (label_index == 0L) {
        NA_character_
      } else {
        source[[paste0("s", label_index, ".run_days")]][[row_index]]
      }
      if (!is.na(run_days) &&
            (!nzchar(run_days) || !grepl("^[0-9]+$", run_days))) {
        stop("Judbury service source contains a malformed run_days literal.")
      }
      role <- if (event_index == 1L) {
        "deployment_start"
      } else if (event_index == length(populated)) {
        "deployment_end"
      } else {
        "service"
      }
      row_events[[event_index]] <- list(
        event_schema = "camtrap-deployment-service-event/1.0",
        raw_service_site_id = raw_id,
        physical_location_id = physical_id,
        service_source_row_ordinal = as.character(row_index),
        service_label = service_label,
        service_date = iso_date,
        event_role = role,
        run_days_literal = if (is.na(run_days)) NA_character_ else run_days,
        run_days_state = if (is.na(run_days)) "missing" else "present"
      )
    }
    if (is.unsorted(as.Date(parsed_dates), strictly = FALSE)) {
      stop("Judbury service row has reversed service chronology.")
    }
    missing_date_indices <- setdiff(seq_along(date_values), populated)
    for (date_index in missing_date_indices) {
      label_index <- date_index - 1L
      if (label_index == 0L) {
        next
      }
      run_days <- source[[paste0("s", label_index, ".run_days")]][[row_index]]
      if (!is.na(run_days) && nzchar(run_days)) {
        stop("Judbury service row has run_days for a missing service label.")
      }
    }
    service_source_row_id <- deployment_evidence_row_identity(
      "deployment_service_input",
      source_sha256,
      row_index
    )
    row_digest <- sha256_text(canonical_json(row_events))
    row_records[[row_index]] <- list(
      raw_service_site_id = raw_id,
      physical_location_id = physical_id,
      service_source_row_ordinal = as.character(row_index),
      service_source_row_id = service_source_row_id,
      start_service_label = row_events[[1L]]$service_label,
      start_date = row_events[[1L]]$service_date,
      end_service_label = row_events[[length(row_events)]]$service_label,
      end_date = row_events[[length(row_events)]]$service_date,
      service_event_count = as.character(length(row_events)),
      service_event_digest = row_digest
    )
    event_records <- c(event_records, row_events)
  }

  rows <- do.call(rbind, lapply(row_records, function(record) {
    as.data.frame(record, stringsAsFactors = FALSE)
  }))
  events <- do.call(rbind, lapply(event_records, function(record) {
    as.data.frame(record, stringsAsFactors = FALSE)
  }))
  rownames(rows) <- NULL
  rownames(events) <- NULL
  if (nrow(events) != 75L ||
        sum(events$run_days_state == "present") != 62L) {
    stop("Judbury service source event or run_days count is invalid.")
  }
  list(
    source_sha256 = source_sha256,
    rows = rows,
    events = events
  )
}

judbury_deployment_ledger_header <- function() { # nolint: object_length_linter.
  c(
    "deployment_ledger_schema",
    "deployment_ledger_version",
    "authority_state",
    "deployment_id",
    "service_source_schema",
    "service_source_version",
    "service_source_path",
    "service_source_sha256",
    "service_source_row_ordinal",
    "raw_service_site_id",
    "alias_basis",
    "physical_location_id",
    "nominal_grid_station_id",
    "move_pair_id",
    "predecessor_deployment_id",
    "successor_deployment_id",
    "start_service_label",
    "start_date",
    "end_service_label",
    "end_date",
    "date_precision",
    "endpoint_semantics",
    "service_event_count",
    "operation_authority_path",
    "operation_authority_sha256",
    "run_days_disposition",
    "pair_boundary_semantics"
  )
}

read_judbury_deployment_ledger <- function(path) {
  if (!file.exists(path) || isTRUE(file.info(path)$isdir)) {
    stop("Judbury deployment ledger is missing or not a file.")
  }
  if (nzchar(Sys.readlink(path))) {
    stop("Judbury deployment ledger may not be a symlink.")
  }
  ledger <- utils::read.csv(
    path,
    stringsAsFactors = FALSE,
    colClasses = "character",
    na.strings = "",
    check.names = FALSE
  )
  if (!identical(names(ledger), judbury_deployment_ledger_header())) {
    stop("Judbury deployment ledger fields do not match the closed schema.")
  }
  if (nrow(ledger) != 13L) {
    stop("Judbury deployment ledger must contain exactly 13 rows.")
  }
  required_text <- setdiff(
    names(ledger),
    c(
      "move_pair_id",
      "predecessor_deployment_id",
      "successor_deployment_id"
    )
  )
  if (any(vapply(ledger[required_text], function(column) {
    any(is.na(column) | !nzchar(column))
  }, logical(1)))) {
    stop("Judbury deployment ledger contains an empty required field.")
  }
  if (anyDuplicated(ledger$deployment_id)) {
    stop("Judbury deployment ledger contains a duplicate deployment ID.")
  }
  if (anyDuplicated(ledger$physical_location_id)) {
    stop("Judbury deployment ledger contains a duplicate physical location.")
  }
  if (anyDuplicated(ledger$raw_service_site_id)) {
    stop("Judbury deployment ledger contains a duplicate raw service row.")
  }

  profile <- judbury_deployment_profile()
  fixed <- list(
    deployment_ledger_schema = profile$deployment_ledger_schema,
    deployment_ledger_version = profile$deployment_ledger_version,
    authority_state = "proposed_for_barry_exact_approval",
    service_source_schema = profile$service_source_schema,
    service_source_version = profile$service_source_version,
    service_source_path = profile$service_sidecar_path,
    service_source_sha256 = profile$service_sidecar_sha256,
    alias_basis = "exact_judbury_alias_no_parser_rule",
    date_precision = "day",
    endpoint_semantics = "inclusive_at_day_precision_unknown_time",
    operation_authority_path = profile$operation_authority_path,
    operation_authority_sha256 = profile$operation_authority_sha256,
    run_days_disposition = "audit_only_not_effort_authority"
  )
  if (any(vapply(names(fixed), function(field) {
    !all(ledger[[field]] == fixed[[field]])
  }, logical(1)))) {
    stop("Judbury deployment ledger schema, version, or authority field is invalid.")
  }
  aliases <- judbury_service_aliases()
  if (!identical(ledger$raw_service_site_id, names(aliases)) ||
    !identical(ledger$physical_location_id, unname(aliases)) ||
    !identical(
      ledger$service_source_row_ordinal,
      as.character(seq_len(nrow(ledger)))
    )) {
    stop("Judbury deployment ledger aliases or source-row ordinals are invalid.")
  }
  if (!identical(
    ledger$deployment_id,
    paste0("judbury_dep_", ledger$physical_location_id)
  )) {
    stop("Judbury deployment ledger contains an invalid stable deployment ID.")
  }
  if (any(!grepl("^S[0-7]$", ledger$start_service_label)) ||
        any(!grepl("^S[0-7]$", ledger$end_service_label)) ||
        any(!grepl("^[0-9]+$", ledger$service_event_count)) ||
        any(as.integer(ledger$service_event_count) < 2L)) {
    stop("Judbury deployment ledger service labels or counts are invalid.")
  }
  invalid_start <- vapply(ledger$start_date, function(value) {
    is.na(suppressWarnings(as.Date(value, format = "%Y-%m-%d"))) ||
      !grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", value)
  }, logical(1))
  invalid_end <- vapply(ledger$end_date, function(value) {
    is.na(suppressWarnings(as.Date(value, format = "%Y-%m-%d"))) ||
      !grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", value)
  }, logical(1))
  if (any(invalid_start) ||
        any(invalid_end) ||
        any(as.Date(ledger$start_date) > as.Date(ledger$end_date))) {
    stop("Judbury deployment ledger contains a malformed or reversed interval.")
  }
  if (length(unique(ledger$nominal_grid_station_id)) != 9L ||
        length(unique(stats::na.omit(ledger$move_pair_id))) != 4L) {
    stop("Judbury deployment ledger aggregate counts are invalid.")
  }
  if (sum(as.integer(ledger$service_event_count)) != 75L) {
    stop("Judbury deployment ledger has a service-count disagreement.")
  }
  ledger_sha256 <- sha256_file(path)
  ledger$deployment_ledger_row_ordinal <- as.character(seq_len(nrow(ledger)))
  ledger$deployment_ledger_row_id <- vapply(
    seq_len(nrow(ledger)),
    deployment_evidence_row_identity,
    character(1),
    source_kind = "deployment_ledger_input",
    source_sha256 = ledger_sha256
  )
  list(
    source_sha256 = ledger_sha256,
    rows = ledger
  )
}

equal_nullable_character <- function(left, right) {
  (is.na(left) & is.na(right)) |
    (!is.na(left) & !is.na(right) & left == right)
}

reconcile_judbury_deployment_evidence <- function( # nolint: object_length_linter.
    service,
    ledger,
    crosswalk) {
  service_rows <- service$rows
  ledger_rows <- ledger$rows
  if (!is.data.frame(service_rows) || !is.data.frame(ledger_rows) ||
    nrow(service_rows) != 13L || nrow(ledger_rows) != 13L ||
    !identical(
      ledger_rows$raw_service_site_id,
      service_rows$raw_service_site_id
    )) {
    stop("Judbury deployment evidence has an orphan, missing, or extra row.")
  }
  endpoint_fields <- c(
    "start_service_label",
    "start_date",
    "end_service_label",
    "end_date"
  )
  if (any(vapply(endpoint_fields, function(field) {
    !identical(ledger_rows[[field]], service_rows[[field]])
  }, logical(1)))) {
    stop("Judbury service and deployment ledger have an endpoint disagreement.")
  }
  if (!identical(
    ledger_rows$service_event_count,
    service_rows$service_event_count
  )) {
    stop("Judbury service and deployment ledger have a service-count disagreement.")
  }
  if (!identical(
    ledger_rows$physical_location_id,
    service_rows$physical_location_id
  ) ||
    !identical(
      ledger_rows$service_source_row_ordinal,
      service_rows$service_source_row_ordinal
    )) {
    stop("Judbury service aliases disagree with the deployment ledger.")
  }

  crosswalk_matches <- match(
    ledger_rows$physical_location_id,
    crosswalk$proposed_physical_location_id
  )
  if (anyNA(crosswalk_matches) ||
    !setequal(
      ledger_rows$physical_location_id,
      crosswalk$proposed_physical_location_id
    )) {
    stop("Judbury deployment ledger has an orphan physical location.")
  }
  matched_crosswalk <- crosswalk[crosswalk_matches, , drop = FALSE]
  if (!identical(
    ledger_rows$physical_location_id,
    matched_crosswalk$source_physical_id
  ) ||
    !identical(
      ledger_rows$nominal_grid_station_id,
      matched_crosswalk$proposed_nominal_grid_station_id
    ) ||
    !all(equal_nullable_character(
      ledger_rows$move_pair_id,
      matched_crosswalk$move_pair_id
    ))) {
    stop("Judbury deployment ledger conflicts with the approved entity crosswalk.")
  }

  ids <- ledger_rows$deployment_id
  successor_rows <- which(!is.na(ledger_rows$successor_deployment_id))
  predecessor_rows <- which(!is.na(ledger_rows$predecessor_deployment_id))
  if (any(!ledger_rows$successor_deployment_id[successor_rows] %in% ids)) {
    stop("Judbury deployment ledger contains an orphan successor.")
  }
  if (any(!ledger_rows$predecessor_deployment_id[predecessor_rows] %in% ids)) {
    stop("Judbury deployment ledger contains an orphan predecessor.")
  }
  if (length(successor_rows) != 4L ||
        length(predecessor_rows) != 4L ||
        anyDuplicated(ledger_rows$successor_deployment_id[successor_rows]) ||
        anyDuplicated(ledger_rows$predecessor_deployment_id[predecessor_rows])) {
    stop("Judbury deployment ledger has conflicting lineage edges.")
  }

  edge_semantics <- character(length(successor_rows))
  for (edge_index in seq_along(successor_rows)) {
    predecessor_index <- successor_rows[[edge_index]]
    successor_id <-
      ledger_rows$successor_deployment_id[[predecessor_index]]
    successor_index <- match(successor_id, ids)
    if (!identical(
      ledger_rows$predecessor_deployment_id[[successor_index]],
      ids[[predecessor_index]]
    )) {
      stop("Judbury deployment ledger has a non-reciprocal lineage edge.")
    }
    if (is.na(ledger_rows$move_pair_id[[predecessor_index]]) ||
      !identical(
        ledger_rows$move_pair_id[[predecessor_index]],
        ledger_rows$move_pair_id[[successor_index]]
      ) ||
      !identical(
        ledger_rows$nominal_grid_station_id[[predecessor_index]],
        ledger_rows$nominal_grid_station_id[[successor_index]]
      )) {
      stop("Judbury deployment lineage edge conflicts with its physical pair.")
    }
    predecessor_end <- as.Date(ledger_rows$end_date[[predecessor_index]])
    successor_start <- as.Date(ledger_rows$start_date[[successor_index]])
    if (predecessor_end > successor_start) {
      stop("Judbury deployment ledger has reversed service chronology.")
    }
    expected_semantics <- if (identical(predecessor_end, successor_start)) {
      "same_date_boundary_not_full_day_overlap_or_routing_claim"
    } else {
      "documented_no_pair_deployment_between_2019-10-14_and_2020-02-26"
    }
    if (!identical(
      ledger_rows$pair_boundary_semantics[[predecessor_index]],
      expected_semantics
    ) ||
      !identical(
        ledger_rows$pair_boundary_semantics[[successor_index]],
        expected_semantics
      )) {
      stop("Judbury deployment ledger pair-boundary semantics are invalid.")
    }
    edge_semantics[[edge_index]] <- expected_semantics
  }
  unpaired <- which(is.na(ledger_rows$move_pair_id))
  same_day_count <- sum(
    edge_semantics ==
      "same_date_boundary_not_full_day_overlap_or_routing_claim"
  )
  declared_gap_count <- sum(
    edge_semantics ==
      "documented_no_pair_deployment_between_2019-10-14_and_2020-02-26"
  )
  if (any(!is.na(ledger_rows$predecessor_deployment_id[unpaired])) ||
        any(!is.na(ledger_rows$successor_deployment_id[unpaired])) ||
        any(ledger_rows$pair_boundary_semantics[unpaired] != "not_applicable") ||
        same_day_count != 3L ||
        declared_gap_count != 1L) {
    stop("Judbury deployment ledger has conflicting pair-boundary evidence.")
  }

  rows <- ledger_rows
  rows$service_event_digest <- service_rows$service_event_digest
  rows$service_source_row_id <- service_rows$service_source_row_id
  list(
    rows = rows,
    events = service$events,
    directed_relation_count = as.integer(length(successor_rows)),
    service_event_count = as.integer(nrow(service$events)),
    run_days_value_count = as.integer(sum(
      service$events$run_days_state == "present"
    )),
    run_days_diagnostic_total = as.integer(sum(
      as.integer(service$events$run_days_literal),
      na.rm = TRUE
    ))
  )
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
    selection,
    deployment_selection) {
  sites <- as.character(validation_state$inputs$site$site)
  records <- list()
  links <- list()
  lineage <- list()
  findings <- list()
  crosswalk <- NULL
  deployment_evidence <- NULL
  selected <- entity_resolution_is_selected(selection)
  deployment_selected <- deployment_evidence_is_selected(deployment_selection)

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
        "Approved crosswalk keys do not exactly cover source site identifiers.",
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
    if (deployment_selected) {
      service_inventory_path <- inventory_path_for_role(
        snapshot,
        "deployment_service_input"
      )
      ledger_inventory_path <- inventory_path_for_role(
        snapshot,
        "deployment_ledger_input"
      )
      operation_record <- deployment_operation_inventory_record(snapshot)
      service <- read_judbury_service_events(
        snapshot$deployment_evidence_paths$service
      )
      ledger <- read_judbury_deployment_ledger(
        snapshot$deployment_evidence_paths$ledger
      )
      deployment_evidence <- reconcile_judbury_deployment_evidence(
        service,
        ledger,
        crosswalk
      )
      for (row_index in seq_len(nrow(deployment_evidence$rows))) {
        row <- deployment_evidence$rows[row_index, , drop = FALSE]
        deployment_id <- entity_identity(
          "deployment",
          "judbury_deployment_evidence:deployment",
          row$deployment_id
        )
        physical_id <- physical_ids[[row$physical_location_id]]
        records[[length(records) + 1L]] <- entity_record(
          entity_type = "deployment",
          entity_id = deployment_id,
          source_namespace = "judbury_deployment_evidence:deployment",
          source_identifier = row$deployment_id,
          resolution_state = "resolved",
          evidence_state = "approved_sidecar",
          evidence_basis = "exact_approved_deployment_ledger",
          source_inventory_path = ledger_inventory_path,
          source_row_id = row$deployment_ledger_row_id
        )
        links[[length(links) + 1L]] <- entity_link_record(
          link_type = "deployment_to_physical_location",
          source_entity_type = "deployment",
          source_entity_id = deployment_id,
          target_entity_type = "physical_location",
          target_entity_id = physical_id,
          evidence_state = "approved_sidecar",
          evidence_basis = "exact_approved_deployment_physical_link",
          source_inventory_path = ledger_inventory_path,
          source_row_id = row$deployment_ledger_row_id
        )
        lineage[[length(lineage) + 1L]] <- deployment_lineage_record(
          deployment_identifier = row$deployment_id,
          deployment_entity_id = deployment_id,
          physical_location_entity_id = physical_id,
          interval_start = row$start_date,
          interval_end = row$end_date,
          interval_evidence_state = "approved_service_endpoints",
          chronology_state = row$pair_boundary_semantics,
          resolution_state = "resolved",
          evidence_basis = "exact_approved_deployment_service_reconciliation",
          source_inventory_path = ledger_inventory_path,
          source_row_id = row$deployment_ledger_row_id,
          physical_location_identifier = row$physical_location_id,
          date_precision = row$date_precision,
          endpoint_semantics = row$endpoint_semantics,
          start_service_label = row$start_service_label,
          end_service_label = row$end_service_label,
          service_event_count = row$service_event_count,
          service_event_digest = row$service_event_digest,
          predecessor_deployment_id = row$predecessor_deployment_id,
          successor_deployment_id = row$successor_deployment_id,
          service_source_schema = row$service_source_schema,
          service_source_version = row$service_source_version,
          service_source_inventory_path = service_inventory_path,
          service_source_sha256 = row$service_source_sha256,
          service_source_row_ordinal = row$service_source_row_ordinal,
          service_source_row_id = row$service_source_row_id,
          deployment_ledger_schema = row$deployment_ledger_schema,
          deployment_ledger_version = row$deployment_ledger_version,
          deployment_ledger_inventory_path = ledger_inventory_path,
          deployment_ledger_sha256 =
            deployment_selection$deployment_ledger_sha256,
          deployment_ledger_row_ordinal =
            row$deployment_ledger_row_ordinal,
          deployment_ledger_row_id = row$deployment_ledger_row_id,
          approval_reference = deployment_selection$authority_reference,
          operation_authority_inventory_path = operation_record$path,
          operation_authority_sha256 = operation_record$sha256,
          run_days_disposition = row$run_days_disposition
        )
      }
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
        evidence_state = "direct_source_identity",
        evidence_basis = "exact_four_table_site_identifier",
        source_inventory_path = inventory_path
      )
    }
    records[[length(records) + 1L]] <- unresolved_scope_record(
      "nominal_grid_station",
      "four_table:nominal_grid_station",
      "no_explicit_nominal_station_evidence"
    )
  }
  if (!deployment_selected) {
    records[[length(records) + 1L]] <- unresolved_scope_record(
      "deployment",
      "four_table:deployment",
      "no_authoritative_deployment_identity_or_interval"
    )
  }
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
    crosswalk = crosswalk,
    deployment_evidence = deployment_evidence
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
    missing_locations <- which(is.na(location_ids) | !nzchar(location_ids))
    if (length(missing_locations) > 0L) {
      findings <- add_integrity_finding(
        findings,
        "camtrapdp.physical_location_identity_missing",
        "CamtrapDP deployment locationID is missing; physical identity cannot be inferred.",
        "deployments"
      )
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
          ),
          physical_location_identifier = candidate_location
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
    crosswalk = NULL,
    deployment_evidence = NULL
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
    deployment_selected,
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
    physical_ready <- unique(deployment_lineage$physical_location_identifier[
      deployment_lineage$resolution_state == "resolved"
    ])
    ambiguous_deployments <- unique(deployment_lineage$deployment_identifier[
      deployment_lineage$resolution_state == "ambiguous"
    ])
    physical_ambiguous <- unique(
      deployment_lineage$physical_location_identifier[
        deployment_lineage$resolution_state == "ambiguous"
      ]
    )
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
      deployment = if (deployment_selected) {
        unique(deployment_lineage$physical_location_identifier[
          deployment_lineage$resolution_state == "resolved"
        ])
      } else {
        character()
      }
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
  readiness <- list(
    join_readiness_schema = join_readiness_schema,
    rule_version = "camtrap-entity-join-readiness/1.0",
    classification_values = c("unique", "unresolved", "ambiguous"),
    source_sha256 = source_sha256,
    entity_ledger_digest = entity_digest,
    results = results
  )
  if (deployment_selected) {
    readiness$analytical_routing_permitted <- FALSE
    readiness$joined_analytical_row_count <- 0L
  }
  readiness
}

#' Resolve versioned entity evidence without changing analytical inputs
#'
#' @param config Effective configuration.
#' @param snapshot Immutable source snapshot.
#' @param validation_state Preflight state containing inputs and parser audit.
#' @return Entity-resolution evidence state.
resolve_entity_evidence <- function(config, snapshot, validation_state) {
  selection <- entity_resolution_selection(config, require_explicit = TRUE)
  deployment_selection <- deployment_evidence_selection(
    config,
    require_explicit = FALSE
  )
  source_sha256 <- validate_entity_source(
    config,
    snapshot,
    selection
  )
  deployment_source_sha256 <- validate_deployment_evidence_source(
    config,
    snapshot,
    deployment_selection
  )
  if (!identical(source_sha256, deployment_source_sha256)) {
    stop("Entity and deployment evidence disagree on immutable source identity.")
  }
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
      selection,
      deployment_selection
    )
  }
  records <- entity_records_frame(result$records)
  links <- entity_links_frame(result$links)
  deployment_lineage <- deployment_lineage_frame(result$deployment_lineage)
  selected <- entity_resolution_is_selected(selection)
  deployment_selected <- deployment_evidence_is_selected(
    deployment_selection
  )
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
  if (deployment_selected) {
    profile <- judbury_deployment_profile()
    operation_record <- deployment_operation_inventory_record(snapshot)
    summary$deployment_evidence <- list(
      profile_id = deployment_selection$profile_id,
      authority_reference = deployment_selection$authority_reference,
      deployment_row_count = as.integer(nrow(
        result$deployment_evidence$rows
      )),
      service_event_count =
        result$deployment_evidence$service_event_count,
      run_days_value_count =
        result$deployment_evidence$run_days_value_count,
      run_days_diagnostic_total =
        result$deployment_evidence$run_days_diagnostic_total,
      directed_relation_count =
        result$deployment_evidence$directed_relation_count,
      service_source = list(
        schema = profile$service_source_schema,
        version = profile$service_source_version,
        source_inventory_path = inventory_path_for_role(
          snapshot,
          "deployment_service_input"
        ),
        sha256 = deployment_selection$service_sidecar_sha256
      ),
      deployment_ledger = list(
        schema = profile$deployment_ledger_schema,
        version = profile$deployment_ledger_version,
        source_inventory_path = inventory_path_for_role(
          snapshot,
          "deployment_ledger_input"
        ),
        sha256 = deployment_selection$deployment_ledger_sha256
      ),
      daily_operation_authority = list(
        source_inventory_path = operation_record$path,
        sha256 = operation_record$sha256
      ),
      run_days_disposition = "audit_only_not_effort_authority",
      analytical_routing_permitted = FALSE,
      joined_analytical_row_count = 0L
    )
  }
  join_readiness <- build_join_readiness(
    config,
    validation_state,
    selected,
    deployment_selected,
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
