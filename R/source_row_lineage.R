# Versioned logical-resource and parser-row audit identities.

resource_identity <- function(input_mode, logical_name, content_sha256) {
  if (!input_mode %in% c("four_table", "camtrapdp")) {
    stop("Unsupported input mode for resource identity: ", input_mode)
  }
  if (!is.character(logical_name) || length(logical_name) != 1L || !nzchar(logical_name)) {
    stop("Logical resource name must be one non-empty string.")
  }
  if (!is.character(content_sha256) ||
        length(content_sha256) != 1L ||
        !grepl("^[a-f0-9]{64}$", content_sha256)) {
    stop("Resource content identity must be one lowercase SHA-256 digest.")
  }

  sha256_text(canonical_json(list(
    identity_schema = "camtrap-resource-id/1.0",
    input_mode = input_mode,
    logical_name = logical_name,
    content_sha256 = content_sha256
  )))
}

source_row_identity <- function(resource_id, record_ordinal) {
  if (!is.character(resource_id) ||
        length(resource_id) != 1L ||
        !grepl("^[a-f0-9]{64}$", resource_id)) {
    stop("Source-row resource identity must be one lowercase SHA-256 digest.")
  }
  if (!is.numeric(record_ordinal) ||
        length(record_ordinal) != 1L ||
        is.na(record_ordinal) ||
        record_ordinal < 1 ||
        record_ordinal != as.integer(record_ordinal)) {
    stop("Parsed record ordinal must be one positive integer.")
  }

  sha256_text(canonical_json(list(
    identity_schema = "camtrap-source-row-id/1.0",
    resource_id = resource_id,
    record_ordinal = as.integer(record_ordinal)
  )))
}

lineage_inventory_record <- function(snapshot, path) {
  stage <- dirname(snapshot$snapshot_root)
  relative <- normalize_relative_path(fs::path_rel(path, start = stage))
  matches <- vapply(
    snapshot$inventory,
    function(record) {
      identical(as.character(record$path), as.character(relative))
    },
    logical(1)
  )
  if (sum(matches) != 1L) {
    stop("Parser resource does not resolve to exactly one source inventory record: ", relative)
  }
  snapshot$inventory[[which(matches)]]
}

camtrapdp_logical_paths <- function(snapshot, logical_names) {
  descriptor <- jsonlite::read_json(
    snapshot$parser_paths$camtrapdp,
    simplifyVector = FALSE
  )
  resources <- descriptor$resources
  if (!is.list(resources)) {
    stop("CamtrapDP descriptor has no resources list.")
  }

  paths <- vapply(logical_names, function(logical_name) {
    matches <- vapply(
      resources,
      function(resource) identical(resource$name, logical_name),
      logical(1)
    )
    if (sum(matches) != 1L) {
      stop(
        "CamtrapDP logical resource must resolve exactly once: ",
        logical_name
      )
    }
    reference <- resources[[which(matches)]]$path
    assert_safe_relative_path(reference, "CamtrapDP tabular resource path")
    file.path(dirname(snapshot$parser_paths$camtrapdp), reference)
  }, character(1))
  unname(paths)
}

logical_resource_paths <- function(snapshot, parsed_tables, input_mode) {
  logical_names <- names(parsed_tables)
  if (is.null(logical_names) ||
        any(!nzchar(logical_names)) ||
        anyDuplicated(logical_names)) {
    stop("Parsed tables must have unique non-empty logical names.")
  }

  if (identical(input_mode, "four_table")) {
    required <- c("site", "op", "obs", "taxa")
    if (!identical(logical_names, required)) {
      stop("Four-table parser resources must be ordered site, op, obs, taxa.")
    }
    return(vapply(
      required,
      function(name) snapshot$parser_paths[[name]],
      character(1)
    ))
  }

  if (identical(input_mode, "camtrapdp")) {
    return(camtrapdp_logical_paths(snapshot, logical_names))
  }
  stop("Unsupported input mode for source-row lineage: ", input_mode)
}

empty_source_row_table <- function() {
  data.frame(
    row_schema = character(),
    source_row_id = character(),
    resource_id = character(),
    logical_name = character(),
    record_ordinal = integer(),
    disposition = character(),
    rule_id = character(),
    reason = character(),
    stringsAsFactors = FALSE
  )
}

build_source_row_lineage <- function(
    snapshot,
    parsed_tables,
    input_mode,
    observation_source_ordinal = NULL,
    observation_index = NULL) {
  if (!is.list(parsed_tables) || length(parsed_tables) == 0L) {
    stop("Parsed tables must be a non-empty named list.")
  }
  paths <- logical_resource_paths(snapshot, parsed_tables, input_mode)
  logical_names <- names(parsed_tables)

  resources <- lapply(seq_along(logical_names), function(index) {
    logical_name <- logical_names[[index]]
    table <- parsed_tables[[logical_name]]
    if (!is.data.frame(table)) {
      stop("Parsed logical resource is not tabular: ", logical_name)
    }
    inventory <- lineage_inventory_record(snapshot, paths[[index]])
    id <- resource_identity(input_mode, logical_name, inventory$sha256)
    data.frame(
      resource_schema = "camtrap-logical-resource/1.0",
      resource_id = id,
      resource_kind = "table",
      logical_name = logical_name,
      input_mode = input_mode,
      content_sha256 = inventory$sha256,
      inventory_path = inventory$path,
      parsed_record_count = as.integer(nrow(table)),
      parser_version = if (identical(input_mode, "camtrapdp")) {
        "camtrapdp-parser/1.0"
      } else {
        "readr-janitor/1.0"
      },
      source_inventory_link = "provenance/source_inventory.json",
      stringsAsFactors = FALSE
    )
  })
  resources <- do.call(rbind, resources)
  rownames(resources) <- NULL

  row_sets <- lapply(seq_len(nrow(resources)), function(index) {
    count <- resources$parsed_record_count[[index]]
    if (count == 0L) {
      return(empty_source_row_table())
    }
    ordinals <- seq_len(count)
    data.frame(
      row_schema = "camtrap-source-row/1.0",
      source_row_id = vapply(
        ordinals,
        source_row_identity,
        resource_id = resources$resource_id[[index]],
        FUN.VALUE = character(1)
      ),
      resource_id = resources$resource_id[[index]],
      logical_name = resources$logical_name[[index]],
      record_ordinal = ordinals,
      disposition = "retained",
      rule_id = "",
      reason = "",
      stringsAsFactors = FALSE
    )
  })
  rows <- do.call(rbind, row_sets)
  rownames(rows) <- NULL

  observation_map <- data.frame(
    internal_index = numeric(),
    record_ordinal = integer(),
    source_row_id = character(),
    stringsAsFactors = FALSE
  )
  if (!is.null(observation_source_ordinal) || !is.null(observation_index)) {
    if (is.null(observation_source_ordinal) ||
          is.null(observation_index) ||
          length(observation_source_ordinal) != length(observation_index)) {
      stop("Observation ordinals and internal indices must be supplied together.")
    }
    observation_name <- if (identical(input_mode, "four_table")) {
      "obs"
    } else {
      "observations"
    }
    source_rows <- rows[rows$logical_name == observation_name, , drop = FALSE]
    ordinals <- as.integer(observation_source_ordinal)
    matches <- match(ordinals, source_rows$record_ordinal)
    if (anyNA(matches) || anyDuplicated(ordinals)) {
      stop("Observation source ordinals are missing, duplicated, or out of range.")
    }
    if (anyNA(observation_index) || anyDuplicated(observation_index)) {
      stop("Internal observation index is missing or duplicated.")
    }
    observation_map <- data.frame(
      internal_index = observation_index,
      record_ordinal = ordinals,
      source_row_id = source_rows$source_row_id[matches],
      stringsAsFactors = FALSE
    )
  }

  lineage <- list(
    lineage_schema = "camtrap-source-row-lineage/1.0",
    resources = resources,
    rows = rows,
    observation_map = observation_map
  )
  validate_source_row_lineage(lineage, snapshot)
  lineage
}

validate_source_row_lineage <- function(lineage, snapshot = NULL) {
  if (!identical(lineage$lineage_schema, "camtrap-source-row-lineage/1.0")) {
    stop("Unsupported source-row lineage schema.")
  }
  resources <- lineage$resources
  rows <- lineage$rows
  if (!is.data.frame(resources) || !is.data.frame(rows)) {
    stop("Source-row lineage resources and rows must be tables.")
  }
  if (nrow(resources) == 0L ||
        any(resources$resource_schema != "camtrap-logical-resource/1.0") ||
        any(resources$resource_kind != "table") ||
        any(rows$row_schema != "camtrap-source-row/1.0")) {
    stop("Source-row lineage contains an unsupported record schema.")
  }
  if (anyDuplicated(resources$resource_id) ||
        anyDuplicated(resources$logical_name) ||
        anyDuplicated(resources$inventory_path)) {
    stop("Duplicate logical resource identity.")
  }
  if (anyDuplicated(rows$source_row_id) ||
        any(!rows$resource_id %in% resources$resource_id)) {
    stop("Duplicate source-row identity.")
  }

  for (index in seq_len(nrow(resources))) {
    resource <- resources[index, ]
    assert_safe_relative_path(
      resource$inventory_path,
      "Logical resource inventory path"
    )
    if (!identical(
      resource$source_inventory_link,
      "provenance/source_inventory.json"
    )) {
      stop("Logical resource has an invalid source-inventory link.")
    }
    expected <- resource_identity(
      resource$input_mode,
      resource$logical_name,
      resource$content_sha256
    )
    if (!identical(resource$resource_id, expected)) {
      stop("Logical resource identity mismatch: ", resource$logical_name)
    }
    resource_rows <- rows[
      rows$resource_id == resource$resource_id,
      ,
      drop = FALSE
    ]
    expected_ordinals <- if (resource$parsed_record_count == 0L) {
      integer()
    } else {
      seq_len(resource$parsed_record_count)
    }
    if (!identical(resource_rows$record_ordinal, expected_ordinals)) {
      stop("Logical resource row count or ordinal mismatch: ", resource$logical_name)
    }
    expected_ids <- vapply(
      expected_ordinals,
      source_row_identity,
      resource_id = resource$resource_id,
      FUN.VALUE = character(1)
    )
    if (!identical(resource_rows$source_row_id, expected_ids)) {
      stop("Source-row identity mismatch: ", resource$logical_name)
    }

    if (!is.null(snapshot)) {
      inventory_paths <- vapply(
        snapshot$inventory,
        `[[`,
        character(1),
        "path"
      )
      match_index <- match(resource$inventory_path, inventory_paths)
      inventory_matches <- !is.na(match_index) && identical(
        snapshot$inventory[[match_index]]$sha256,
        resource$content_sha256
      )
      if (!inventory_matches) {
        stop("Logical resource source-inventory link mismatch: ", resource$logical_name)
      }
    }
  }

  if (any(!rows$disposition %in% c("retained", "transformed", "excluded"))) {
    stop("Invalid source-row disposition.")
  }
  explained <- rows$disposition != "retained"
  if (any(explained & (!nzchar(rows$rule_id) | !nzchar(rows$reason)))) {
    stop("Non-retained source rows require a rule and reason.")
  }

  observation_map <- lineage$observation_map
  if (!is.data.frame(observation_map) ||
        anyDuplicated(observation_map$internal_index) ||
        anyDuplicated(observation_map$source_row_id)) {
    stop("Observation source-row mapping is missing, duplicated, or ambiguous.")
  }
  if (nrow(observation_map) > 0L) {
    observation_names <- c("obs", "observations")
    observation_rows <- rows[
      rows$logical_name %in% observation_names,
      c("source_row_id", "record_ordinal"),
      drop = FALSE
    ]
    valid_ids <- observation_rows$source_row_id
    if (any(!observation_map$source_row_id %in% valid_ids)) {
      stop("Observation mapping contains an orphan source-row identity.")
    }
    matched <- match(observation_map$source_row_id, observation_rows$source_row_id)
    ordinals_match <- identical(
      observation_map$record_ordinal,
      observation_rows$record_ordinal[matched]
    )
    rows_match <- setequal(observation_map$source_row_id, valid_ids)
    if (!ordinals_match || !rows_match) {
      stop("Observation mapping does not exactly account for parsed rows.")
    }
  }
  invisible(TRUE)
}
