# Goal 009 selected-resolution provenance and conservative aggregation.

selected_resolution_paths <- function(root) {
  directory <- file.path(root, "provenance", "selected_resolution")
  c(membership = file.path(directory, "membership.csv"),
    operation = file.path(directory, "operation.csv"),
    event_map = file.path(directory, "event_map.csv"),
    summary = file.path(directory, "summary.json"))
}

selected_resolution_membership_digest <- function(value) { # nolint: object_length_linter.
  sha256_text(canonical_json(value))
}

selected_source_membership_digest <- function(event_id, source_row_ids) { # nolint: object_length_linter.
  sha256_text(canonical_json(list(
    event_id = as.character(event_id),
    source_row_ids = sort(as.character(source_row_ids), method = "radix")
  )))
}

selected_resolution_read_mapping <- function(config, snapshot) { # nolint: object_length_linter.
  selection <- analysis_unit_selection(config)
  if (is.null(selection)) return(NULL)
  if (identical(selection$state, "built_in_default") &&
        identical(selection$resolution, "analysis_site")) {
    return(NULL)
  }
  if (identical(selection$state, "built_in_default") &&
        identical(selection$resolution, "physical_location")) {
    return(NULL)
  }
  matches <- vapply(snapshot$inventory, function(record) {
    identical(record$role, "analysis_site_mapping_input")
  }, logical(1))
  if (sum(matches) != 1L) {
    stop("Selected analysis-site mapping requires exactly one immutable inventory record.")
  }
  record <- snapshot$inventory[[which(matches)]]
  if (!identical(record$sha256, selection$mapping_sha256)) {
    stop("Selected analysis-site mapping fixity does not match configuration.")
  }
  path <- file.path(snapshot$staging_dir, record$path)
  assert_path_within_root(path, snapshot$staging_dir,
                          "Analysis-site mapping source")
  if (!identical(sha256_file(path), selection$mapping_sha256)) {
    stop("Selected analysis-site mapping bytes do not match configuration.")
  }
  mapping <- utils::read.csv(path, stringsAsFactors = FALSE,
                             check.names = FALSE, na.strings = "")
  expected <- c("analysis_site_mapping_schema", "scheme_id", "scheme_version",
                "authority_state", "analysis_site_id", "physical_location_id",
                "representative_latitude", "representative_longitude",
                "coordinate_basis")
  if (!identical(names(mapping), expected) || nrow(mapping) != 13L) {
    stop("Selected analysis-site mapping schema or row count is invalid.")
  }
  if (anyNA(mapping$physical_location_id) || any(!nzchar(mapping$physical_location_id)) ||
        anyDuplicated(mapping$physical_location_id) ||
        anyNA(mapping$analysis_site_id) || any(!nzchar(mapping$analysis_site_id)) ||
        anyNA(mapping$representative_latitude) || anyNA(mapping$representative_longitude) ||
        anyNA(mapping$coordinate_basis) || any(!nzchar(mapping$coordinate_basis))) {
    stop("Selected analysis-site mapping contains incomplete or duplicate membership.")
  }
  if (length(unique(mapping$analysis_site_mapping_schema)) != 1L ||
        !identical(mapping$analysis_site_mapping_schema[[1]], "camtrap-analysis-site-mapping/1.0") ||
        length(unique(mapping$scheme_id)) != 1L ||
        !identical(mapping$scheme_id[[1]], "judbury-analysis-site") ||
        length(unique(mapping$scheme_version)) != 1L ||
        !identical(mapping$scheme_version[[1]], "1.0.0-proposed") ||
        length(unique(mapping$authority_state)) != 1L ||
        !identical(mapping$authority_state[[1]], "proposed_for_barry_exact_approval")) {
    stop("Selected analysis-site mapping authority is invalid.")
  }
  for (site in unique(mapping$analysis_site_id)) {
    rows <- mapping[mapping$analysis_site_id == site, , drop = FALSE]
    if (length(unique(rows$representative_latitude)) != 1L ||
          length(unique(rows$representative_longitude)) != 1L ||
          length(unique(rows$coordinate_basis)) != 1L) {
      stop("Selected analysis-site mapping has inconsistent representative coordinates.")
    }
  }
  mapping
}

selected_resolution_physical_ids <- function(entity_state, validation_state) { # nolint: object_length_linter.
  if (is.list(entity_state) && is.data.frame(entity_state$records) &&
        all(c("entity_type", "source_identifier", "resolution_state") %in%
              names(entity_state$records))) {
    records <- entity_state$records
    ids <- records$source_identifier[records$entity_type == "physical_location" &
                                       records$resolution_state == "resolved"]
    if (length(ids) > 0L) return(unique(as.character(ids)))
  }
  if (is.list(validation_state$inputs) && is.data.frame(validation_state$inputs$site) &&
        "site" %in% names(validation_state$inputs$site)) {
    return(unique(as.character(validation_state$inputs$site$site)))
  }
  character()
}

selected_resolution_nominal_membership <- function( # nolint: object_length_linter.
    entity_state, physical_ids) {
  if (!is.list(entity_state) || !is.data.frame(entity_state$records) ||
        !is.data.frame(entity_state$links)) return(NULL)
  records <- entity_state$records
  links <- entity_state$links
  needed_records <- c("entity_type", "entity_id", "source_identifier", "resolution_state")
  needed_links <- c("link_type", "source_entity_id", "target_entity_id")
  if (!all(needed_records %in% names(records)) || !all(needed_links %in% names(links))) {
    stop("Nominal membership authority is malformed.")
  }
  nominal <- records[records$entity_type == "nominal_grid_station" &
                       records$resolution_state == "resolved", , drop = FALSE]
  physical <- records[records$entity_type == "physical_location" &
                        records$resolution_state == "resolved", , drop = FALSE]
  links <- links[links$link_type == "physical_location_to_nominal_grid_station", , drop = FALSE]
  if (nrow(nominal) == 0L || nrow(links) == 0L) return(NULL)
  if (anyDuplicated(physical$entity_id) ||
        anyDuplicated(physical$source_identifier) ||
        anyDuplicated(nominal$entity_id) ||
        any(!physical_ids %in% physical$source_identifier)) {
    stop("Nominal membership authority has duplicate or incomplete entity records.")
  }
  if ("resolution_state" %in% names(links) &&
        any(links$resolution_state != "resolved")) {
    stop("Nominal membership authority contains an unresolved link.")
  }
  source_map <- stats::setNames(as.character(physical$source_identifier), physical$entity_id)
  target_map <- stats::setNames(as.character(nominal$source_identifier), nominal$entity_id)
  links$physical_location_id <- unname(source_map[links$source_entity_id])
  links$analysis_unit_id <- unname(target_map[links$target_entity_id])
  if (anyNA(links$physical_location_id) || anyNA(links$analysis_unit_id) ||
        anyDuplicated(links$physical_location_id) ||
        !setequal(links$physical_location_id, physical_ids)) {
    stop("Nominal membership authority is duplicate, conflicting, or orphaned.")
  }
  links[c("physical_location_id", "analysis_unit_id")]
}

selected_resolution_deployment_for_date <- function( # nolint: object_length_linter.
    entity_state,
    physical_location_id,
    date) {
  lineage <- if (is.list(entity_state)) entity_state$deployment_lineage else NULL
  required <- c(
    "physical_location_identifier", "deployment_identifier",
    "resolution_state"
  )
  if (!is.data.frame(lineage) || !all(required %in% names(lineage))) {
    return(NA_character_)
  }
  rows <- lineage[
    lineage$physical_location_identifier == physical_location_id &
      lineage$resolution_state == "resolved",
    ,
    drop = FALSE
  ]
  if (all(c("interval_start", "interval_end") %in% names(rows))) {
    starts <- as.Date(rows$interval_start)
    ends <- as.Date(rows$interval_end)
    rows <- rows[
      !is.na(starts) & !is.na(ends) & starts <= date & ends >= date,
      ,
      drop = FALSE
    ]
  }
  ids <- unique(as.character(rows$deployment_identifier))
  ids <- ids[!is.na(ids) & nzchar(ids)]
  if (length(ids) == 1L) ids[[1L]] else NA_character_
}

selected_resolution_site_coordinates <- function(validation_state, ids) { # nolint: object_length_linter.
  site <- validation_state$inputs$site
  out <- data.frame(physical_location_id = ids, physical_latitude = NA_real_,
                    physical_longitude = NA_real_, stringsAsFactors = FALSE)
  if (is.data.frame(site) && all(c("site", "lat", "lon") %in% names(site))) {
    out$physical_latitude <- as.numeric(site$lat[match(ids, site$site)])
    out$physical_longitude <- as.numeric(site$lon[match(ids, site$site)])
  }
  out
}

build_selected_effort_coverage <- function(operation, membership, entity_state = NULL) {
  if (!is.data.frame(operation) || !is.data.frame(membership) ||
        !all(c("site", "trap_date", "on_off") %in% names(operation)) ||
        !all(c("analysis_unit_id", "physical_location_id") %in% names(membership))) {
    stop("Selected operation requires long physical operation and membership tables.")
  }
  operation$site <- as.character(operation$site)
  operation$trap_date <- as.Date(operation$trap_date)
  if (anyNA(operation$trap_date) || anyNA(operation$site) || any(!nzchar(operation$site))) {
    stop("Selected operation contains malformed site/date keys.")
  }
  if (anyDuplicated(paste(operation$site, operation$trap_date, sep = "\r"))) {
    stop("Selected operation contains duplicate physical site-date keys.")
  }
  membership <- membership[c("analysis_unit_id", "physical_location_id")]
  if (anyDuplicated(membership$physical_location_id)) {
    stop("Selected membership contains duplicate physical locations.")
  }
  operation <- operation[operation$site %in% membership$physical_location_id, , drop = FALSE]
  if (nrow(operation) == 0L) {
    return(data.frame(analysis_unit_id = character(), date = as.Date(character()),
                      operation = numeric(), member_states_json = character(),
                      member_states_digest = character(), member_count = integer(),
                      active_member_count = integer(), unknown_member_count = integer(),
                      deployment_states_json = character(),
                      deployment_states_digest = character(),
                      resolved_deployment_count = integer(),
                      concurrency_class = character(), handover_date = as.Date(character()),
                      stringsAsFactors = FALSE))
  }
  operation$analysis_unit_id <- membership$analysis_unit_id[
    match(operation$site, membership$physical_location_id)
  ]
  key <- paste(operation$analysis_unit_id, operation$trap_date, sep = "\r")
  groups <- split(seq_len(nrow(operation)), key, drop = TRUE)
  rows <- lapply(groups, function(index) {
    group <- operation[index, , drop = FALSE]
    unit <- group$analysis_unit_id[[1L]]
    date <- group$trap_date[[1L]]
    values <- group$on_off
    relevant <- membership$physical_location_id[
      membership$analysis_unit_id == unit
    ]
    observed_sites <- group$site
    all_present <- all(relevant %in% observed_sites)
    active <- any(!is.na(values) & values == 1)
    inactive <- all_present && length(values) > 0L && all(!is.na(values) & values == 0)
    value <- if (active) 1 else if (inactive) 0 else NA_real_
    member_ids <- relevant[order(relevant, method = "radix")]
    member_values <- vapply(member_ids, function(id) {
      idx <- which(group$site == id)
      if (length(idx) != 1L || is.na(group$on_off[[idx]])) NA_character_ else as.character(group$on_off[[idx]])
    }, character(1))
    member_record <- stats::setNames(as.list(member_values), member_ids)
    deployment_values <- vapply(
      member_ids,
      selected_resolution_deployment_for_date,
      character(1),
      entity_state = entity_state,
      date = as.Date(date)
    )
    deployment_record <- stats::setNames(as.list(deployment_values), member_ids)
    data.frame(analysis_unit_id = as.character(unit),
               date = as.Date(date), operation = value,
               member_states_json = canonical_json(member_record),
               member_states_digest = sha256_text(canonical_json(member_record)),
               member_count = as.integer(length(member_ids)),
               active_member_count = as.integer(sum(member_values == "1", na.rm = TRUE)),
               unknown_member_count = as.integer(sum(is.na(member_values))),
               deployment_states_json = canonical_json(deployment_record),
               deployment_states_digest = sha256_text(canonical_json(deployment_record)),
               resolved_deployment_count = as.integer(sum(!is.na(deployment_values))),
               concurrency_class = if (sum(member_values == "1", na.rm = TRUE) > 1L) {
                 "concurrent_unresolved"
               } else {
                 "none"
               },
               handover_date = as.Date(NA),
               stringsAsFactors = FALSE)
  })
  result <- do.call(rbind, rows)
  rownames(result) <- NULL
  result[order(result$analysis_unit_id, result$date, method = "radix"), , drop = FALSE]
}

selected_resolution_pivot_operation <- function(op) { # nolint: object_length_linter.
  if (exists("pivot_op_long", mode = "function")) return(pivot_op_long(op))
  date_name <- if ("date" %in% names(op)) "date" else names(op)[[1]]
  sites <- setdiff(names(op), date_name)
  rows <- lapply(sites, function(site) {
    data.frame(
      site = site, trap_date = as.Date(op[[date_name]]), on_off = op[[site]],
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

selected_resolution_concurrency <- function( # nolint: object_length_linter.
    membership, entity_state, operation = NULL) {
  reasons <- character()
  lineage <- if (is.list(entity_state)) entity_state$deployment_lineage else NULL
  if (!is.data.frame(lineage) || nrow(lineage) == 0L) return(reasons)
  required <- c("physical_location_identifier", "interval_start", "interval_end",
                "predecessor_deployment_id", "successor_deployment_id",
                "deployment_identifier")
  if (!all(required %in% names(lineage))) return(reasons)
  for (unit in unique(membership$analysis_unit_id)) {
    if (is.na(unit)) next
    ids <- membership$physical_location_id[membership$analysis_unit_id == unit]
    if (length(ids) < 2L) next
    rows <- lineage[lineage$physical_location_identifier %in% ids, , drop = FALSE]
    if (nrow(rows) != length(ids)) {
      reasons <- c(reasons, paste0("missing_deployment_evidence:", unit))
      next
    }
    starts <- as.Date(rows$interval_start)
    ends <- as.Date(rows$interval_end)
    if (anyNA(starts) || anyNA(ends) || any(starts > ends)) {
      reasons <- c(reasons, paste0("malformed_deployment_chronology:", unit))
      next
    }
    # Only simultaneous confirmed-active members make a selected route
    # ineligible.  Bounded chronology alone is audit evidence, not a reason to
    # reject otherwise non-overlapping operational histories.
    active_dates <- NULL
    if (is.data.frame(operation) && nrow(operation) > 0L &&
          all(c("site", "trap_date", "on_off") %in% names(operation))) {
      unit_for_site <- membership$analysis_unit_id[match(operation$site,
                                                         membership$physical_location_id)]
      active <- unit_for_site == unit & operation$on_off == 1
      active_dates <- split(operation$site[active], operation$trap_date[active])
    }
    overlap <- FALSE
    for (i in seq_len(nrow(rows) - 1L)) for (j in (i + 1L):nrow(rows)) {
      if (starts[[i]] > ends[[j]] || starts[[j]] > ends[[i]]) next
      if (!is.null(active_dates)) {
        simultaneous <- any(vapply(active_dates, function(ids) {
          all(c(rows$physical_location_identifier[[i]],
                rows$physical_location_identifier[[j]]) %in% ids)
        }, logical(1)))
        if (!simultaneous) next
      }
      approved <- identical(as.character(rows$successor_deployment_id[[i]]),
                            as.character(rows$deployment_identifier[[j]])) &&
        identical(as.character(rows$predecessor_deployment_id[[j]]),
                  as.character(rows$deployment_identifier[[i]]))
      approved <- approved && starts[[j]] == ends[[i]]
      approved <- approved || (
        identical(as.character(rows$successor_deployment_id[[j]]),
                  as.character(rows$deployment_identifier[[i]])) &&
          identical(as.character(rows$predecessor_deployment_id[[i]]),
                    as.character(rows$deployment_identifier[[j]])) &&
          starts[[i]] == ends[[j]]
      )
      if (!approved) overlap <- TRUE
    }
    if (overlap) reasons <- c(reasons, paste0("genuine_concurrent_member_deployments:", unit))
  }
  unique(reasons)
}

selected_resolution_classify_concurrency <- function( # nolint: object_length_linter.
    membership, entity_state, operation) {
  reasons <- character()
  integrity <- character()
  lineage <- if (is.list(entity_state)) entity_state$deployment_lineage else NULL
  if (!is.data.frame(operation) || nrow(operation) == 0L) {
    return(list(operation = operation, reasons = reasons, integrity = integrity))
  }
  required <- c("physical_location_identifier", "deployment_identifier",
                "predecessor_deployment_id", "successor_deployment_id",
                "interval_start", "interval_end", "date_precision",
                "endpoint_semantics", "chronology_state", "resolution_state")
  for (row_index in seq_len(nrow(operation))) {
    unit <- operation$analysis_unit_id[[row_index]]
    if (is.na(unit)) next
    ids <- membership$physical_location_id[membership$analysis_unit_id == unit]
    if (length(ids) < 2L) next
    date <- operation$date[[row_index]]
    parsed <- tryCatch(
      jsonlite::fromJSON(
        operation$member_states_json[[row_index]],
        simplifyVector = TRUE
      ),
      error = function(e) NULL
    )
    active_sites <- if (!is.null(names(parsed))) {
      names(parsed)[as.character(parsed) == "1"]
    } else {
      character()
    }
    active_sites <- intersect(unique(active_sites), ids)
    if (length(active_sites) < 2L) next
    if (length(active_sites) > 2L) {
      operation$concurrency_class[[row_index]] <- "concurrent_active_members"
      reasons <- c(reasons, paste0("concurrent_active_member_count_gt_two:", unit, ":", date))
      next
    }
    if (!is.data.frame(lineage) || !all(required %in% names(lineage))) {
      operation$concurrency_class[[row_index]] <- "concurrent_active_members"
      reasons <- c(reasons, paste0("missing_deployment_evidence:", unit, ":", date))
      next
    }
    pair <- lineage[lineage$physical_location_identifier %in% active_sites, , drop = FALSE]
    if (nrow(pair) != 2L) {
      operation$concurrency_class[[row_index]] <- "concurrent_active_members"
      if (nrow(pair) > 2L || anyDuplicated(pair$physical_location_identifier)) {
        integrity <- c(integrity, paste0("conflicting_deployment_evidence:", unit))
      } else {
        reasons <- c(reasons, paste0("missing_deployment_evidence:", unit, ":", date))
      }
      next
    }
    first <- pair[1L, , drop = FALSE]
    second <- pair[2L, , drop = FALSE]
    starts <- as.Date(pair$interval_start)
    ends <- as.Date(pair$interval_end)
    if (anyNA(starts) || anyNA(ends) || any(starts > ends)) {
      integrity <- c(integrity, paste0("malformed_deployment_chronology:", unit))
      operation$concurrency_class[[row_index]] <- "concurrent_active_members"
      next
    }
    boundary_date <- as.Date(date)
    forward <- identical(
      as.character(first$successor_deployment_id),
      as.character(second$deployment_identifier)
    ) && identical(
      as.character(second$predecessor_deployment_id),
      as.character(first$deployment_identifier)
    ) && ends[[1L]] == boundary_date && starts[[2L]] == boundary_date
    reverse <- identical(
      as.character(second$successor_deployment_id),
      as.character(first$deployment_identifier)
    ) && identical(
      as.character(first$predecessor_deployment_id),
      as.character(second$deployment_identifier)
    ) && ends[[2L]] == boundary_date && starts[[1L]] == boundary_date
    exact <- all(pair$date_precision == "day") &&
      all(pair$chronology_state == "same_date_boundary_not_full_day_overlap_or_routing_claim") &&
      all(pair$endpoint_semantics == "inclusive_at_day_precision_unknown_time") &&
      all(pair$resolution_state == "resolved") && (forward || reverse)
    if (exact) {
      operation$concurrency_class[[row_index]] <- "approved_same_day_handover"
      operation$handover_date[[row_index]] <- as.Date(date)
    } else {
      operation$concurrency_class[[row_index]] <- "concurrent_active_members"
      reasons <- c(reasons, paste0("genuine_concurrent_member_deployments:", unit, ":", date))
    }
  }
  list(operation = operation, reasons = unique(reasons), integrity = unique(integrity))
}

build_selected_event_map <- function(event_lineage, membership, lineage = NULL,
                                     deployment_lineage = NULL) {
  if (!is.list(event_lineage) || !is.data.frame(event_lineage$obs_events) ||
        !is.data.frame(event_lineage$memberships)) {
    stop("Selected event mapping requires recorded Phase-2 event lineage.")
  }
  events <- event_lineage$obs_events
  required <- c("event_id", "site", "species", "dt")
  if (!all(required %in% names(events)) || anyNA(events$event_id) ||
    any(vapply(
      split(events, events$event_id),
      function(rows) {
        length(unique(rows$site)) != 1L || length(unique(rows$species)) != 1L
      },
      logical(1)
    ))) {
    stop("Selected event lineage has malformed event identities.")
  }
  if (!is.null(lineage)) validate_event_membership(event_lineage, events, lineage)
  if (any(!events$site %in% membership$physical_location_id)) {
    stop("Selected event lineage contains an orphan physical location.")
  }
  event_ids <- unique(events$event_id)
  event_tz <- attr(events$dt, "tzone")
  event_tz <- if (is.null(event_tz) || length(event_tz) == 0L ||
                    is.na(event_tz[[1L]]) || !nzchar(event_tz[[1L]])) {
    "UTC"
  } else {
    event_tz[[1L]]
  }
  unique_events <- do.call(rbind, lapply(event_ids, function(id) {
    rows <- events[events$event_id == id, , drop = FALSE]
    rows[1L, , drop = FALSE]
  }))
  unique_events$dt <- as.POSIXct(vapply(event_ids, function(id) {
    as.numeric(min(events$dt[events$event_id == id]))
  }, numeric(1)), origin = "1970-01-01", tz = event_tz)
  unique_events$analysis_unit_id <- membership$analysis_unit_id[
    match(unique_events$site, membership$physical_location_id)
  ]
  members <- event_lineage$memberships
  source_ids <- split(members$source_row_id, members$event_id)
  unique_events$physical_location_id <- unique_events$site
  unique_events$event_time <- as.POSIXct(unique_events$dt, tz = event_tz)
  unique_events$source_membership_count <- as.integer(vapply(
    unique_events$event_id,
    function(id) length(source_ids[[id]] %||% character()),
    integer(1)
  ))
  unique_events$source_membership_digest <- vapply(
    unique_events$event_id,
    function(id) {
      selected_source_membership_digest(
        id,
        source_ids[[id]] %||% character()
      )
    },
    character(1)
  )
  unique_events$source_membership_reference <- "provenance/phase2/event_membership.json"
  unique_events$deployment_id <- NA_character_
  unique_events$deployment_resolution_state <- "unresolved"
  if (is.data.frame(deployment_lineage)) {
    deployment_state <- list(deployment_lineage = deployment_lineage)
    for (i in seq_len(nrow(unique_events))) {
      deployment_id <- selected_resolution_deployment_for_date(
        deployment_state,
        unique_events$physical_location_id[[i]],
        as.Date(unique_events$event_time[[i]], tz = event_tz)
      )
      if (!is.na(deployment_id)) {
        unique_events$deployment_id[[i]] <- deployment_id
        unique_events$deployment_resolution_state[[i]] <- "resolved"
      }
    }
  }
  unique_events <- unique_events[c(
    "event_id", "physical_location_id", "analysis_unit_id",
    "species", "event_time", "source_membership_count",
    "source_membership_digest", "source_membership_reference",
    "deployment_id", "deployment_resolution_state"
  )]
  unique_events[order(unique_events$event_id, method = "radix"), , drop = FALSE]
}

`%||%` <- function(x, y) if (is.null(x) || length(x) == 0L || is.na(x[[1]])) y else x

resolve_selected_resolution <- function(config, snapshot, validation_state, entity_state) {
  selection <- analysis_unit_selection(config)
  if (is.null(selection)) return(NULL)
  integrity_ok <- TRUE
  reasons <- character()
  mapping <- NULL
  mapping_error <- tryCatch({
    if (identical(selection$resolution, "analysis_site")) {
      mapping <- selected_resolution_read_mapping(config, snapshot)
    }
    NULL
  },
  error = function(e) conditionMessage(e))
  if (!is.null(mapping_error)) {
    integrity_ok <- FALSE
    reasons <- c(reasons, mapping_error)
  }
  physical_ids <- selected_resolution_physical_ids(entity_state, validation_state)
  if (length(physical_ids) == 0L) {
    integrity_ok <- FALSE
    reasons <- c(reasons, "no_resolved_physical_locations")
  }
  route_only_reasons <- character()
  nominal_membership <- NULL
  authority_reference <- selection$authority_reference
  if (identical(selection$resolution, "nominal_station")) {
    nominal_membership <- tryCatch(
      selected_resolution_nominal_membership(entity_state, physical_ids),
      error = function(e) {
        integrity_ok <<- FALSE
        reasons <<- c(reasons, conditionMessage(e))
        NULL
      }
    )
    if (is.null(nominal_membership)) {
      if (integrity_ok) route_only_reasons <- "nominal_station_membership_authority_unavailable"
      membership <- data.frame(physical_location_id = physical_ids,
                               analysis_unit_id = NA_character_, stringsAsFactors = FALSE)
      scheme_id <- selection$scheme_id
      scheme_version <- selection$scheme_version
    } else if (!is.null(nominal_membership)) {
      membership <- nominal_membership
      scheme_id <- selection$scheme_id
      scheme_version <- selection$scheme_version
      authority_reference <- entity_state$summary$authority_reference %||%
        entity_state$summary$ledger_content_sha256 %||%
        "goal007-authoritative-entity-links"
    }
  } else if (is.null(mapping)) {
    membership <- data.frame(physical_location_id = physical_ids,
                             analysis_unit_id = physical_ids,
                             stringsAsFactors = FALSE)
    scheme_id <- selection$scheme_id
    scheme_version <- selection$scheme_version
  } else {
    membership <- mapping[c("physical_location_id", "analysis_site_id")]
    names(membership)[[2]] <- "analysis_unit_id"
    if (!setequal(membership$physical_location_id, physical_ids) ||
          length(membership$physical_location_id) != length(physical_ids)) {
      integrity_ok <- FALSE
      reasons <- c(reasons, "incomplete_or_orphan_mapping")
    }
    scheme_id <- unique(mapping$scheme_id)[[1]]
    scheme_version <- unique(mapping$scheme_version)[[1]]
  }
  if (anyDuplicated(membership$physical_location_id) ||
        (anyNA(membership$analysis_unit_id) && length(route_only_reasons) == 0L)) {
    integrity_ok <- FALSE
    reasons <- c(reasons, "duplicate_or_malformed_membership")
  }
  coords <- selected_resolution_site_coordinates(validation_state, physical_ids)
  membership <- merge(membership, coords, by = "physical_location_id", all.x = TRUE,
                      sort = FALSE)
  membership$scheme_id <- scheme_id
  membership$scheme_version <- scheme_version
  membership$resolution <- selection$resolution
  membership$authority_reference <- authority_reference
  membership$representative_latitude <- membership$physical_latitude
  membership$representative_longitude <- membership$physical_longitude
  membership$coordinate_basis <- if (identical(selection$resolution, "nominal_station")) {
    "no_representative_coordinate_in_nominal_membership_authority"
  } else if (identical(selection$resolution, "physical_location") || is.null(mapping)) {
    "actual_physical_location_coordinates"
  } else {
    mapping$coordinate_basis[match(membership$physical_location_id,
                                   mapping$physical_location_id)]
  }
  if (!is.null(mapping)) {
    membership$representative_latitude <- mapping$representative_latitude[
      match(
        membership$physical_location_id,
        mapping$physical_location_id
      )
    ]
    membership$representative_longitude <- mapping$representative_longitude[
      match(
        membership$physical_location_id,
        mapping$physical_location_id
      )
    ]
    membership$coordinate_basis <- mapping$coordinate_basis[
      match(
        membership$physical_location_id,
        mapping$physical_location_id
      )
    ]
  }
  if (identical(selection$resolution, "nominal_station")) {
    membership$representative_latitude <- NA_real_
    membership$representative_longitude <- NA_real_
  }
  resolved_membership <- membership[!is.na(membership$analysis_unit_id), , drop = FALSE]
  operation <- tryCatch(
    build_selected_effort_coverage(
      selected_resolution_pivot_operation(validation_state$inputs$op),
      resolved_membership,
      entity_state
    ),
    error = function(e) {
      integrity_ok <<- FALSE
      reasons <<- c(reasons, conditionMessage(e))
      data.frame(
        analysis_unit_id = character(),
        date = as.Date(character()),
        operation = numeric()
      )
    }
  )
  concurrency_state <- selected_resolution_classify_concurrency(
    membership, entity_state, operation
  )
  operation <- concurrency_state$operation
  if (length(concurrency_state$integrity) > 0L) {
    integrity_ok <- FALSE
    reasons <- c(reasons, concurrency_state$integrity)
  }
  event_map <- tryCatch(
    build_selected_event_map(
      validation_state$event_lineage,
      membership,
      validation_state$lineage,
      entity_state$deployment_lineage
    ),
    error = function(e) {
      integrity_ok <<- FALSE
      reasons <<- c(reasons, conditionMessage(e))
      data.frame()
    }
  )
  concurrency <- concurrency_state$reasons
  reasons <- c(reasons, concurrency, route_only_reasons)
  route_eligible <- integrity_ok && length(concurrency) == 0L &&
    length(route_only_reasons) == 0L
  status <- if (!integrity_ok) "integrity_failure" else if (!route_eligible) "ineligible" else "eligible"
  summary <- list(
    selected_resolution_summary_schema = "camtrap-selected-resolution-summary/1.0",
    status = status, integrity_ok = integrity_ok, route_eligible = route_eligible,
    resolution = selection$resolution, scheme_id = scheme_id, scheme_version = scheme_version,
    authority_reference = authority_reference,
    membership_count = as.integer(nrow(membership)),
    analysis_unit_count = as.integer(length(unique(stats::na.omit(
      membership$analysis_unit_id
    )))),
    physical_location_count = as.integer(length(unique(membership$physical_location_id))),
    operation_state_counts = c(active = sum(operation$operation == 1, na.rm = TRUE),
                               inactive = sum(operation$operation == 0, na.rm = TRUE),
                               unknown = sum(is.na(operation$operation))),
    event_count = as.integer(if (nrow(event_map) == 0L) 0L else nrow(event_map)),
    source_row_membership_count = as.integer(if (nrow(event_map) == 0L) 0L else sum(event_map$source_membership_count)),
    reasons = unique(as.character(reasons)),
    claim_limits = c(
      "observed-richness-detection-effort-bounded",
      "jaccard-descriptive-observed-presence-effort-completeness-detectability-limited"
    )
  )
  list(selected_resolution_state_schema = "camtrap-selected-resolution-state/1.0",
       integrity_ok = integrity_ok, route_eligible = route_eligible,
       reasons = unique(as.character(reasons)), membership = membership,
       operation = operation, event_map = event_map, summary = summary)
}

selected_write_csv <- function(value, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  if (file.exists(path)) stop("Refusing to overwrite selected-resolution artifact: ", path)
  tmp <- tempfile(pattern = paste0(".", basename(path), "."), tmpdir = dirname(path))
  on.exit(unlink(tmp, force = TRUE), add = TRUE)
  readr::write_csv(value, tmp, na = "")
  if (!file.rename(tmp, path)) stop("Atomic selected-resolution CSV publication failed: ", path)
  invisible(path)
}

selected_resolution_prepare_membership <- function(value) { # nolint: object_length_linter.
  fields <- c("resolution", "scheme_id", "scheme_version", "authority_reference",
              "physical_location_id", "analysis_unit_id", "physical_latitude",
              "physical_longitude", "representative_latitude",
              "representative_longitude", "coordinate_basis")
  for (field in setdiff(fields, names(value))) value[[field]] <- NA
  value[fields]
}

selected_resolution_prepare_operation <- function(value) { # nolint: object_length_linter.
  fields <- c("analysis_unit_id", "date", "operation", "member_states_json",
              "member_states_digest", "member_count", "active_member_count",
              "unknown_member_count", "deployment_states_json",
              "deployment_states_digest", "resolved_deployment_count",
              "concurrency_class", "handover_date")
  for (field in setdiff(fields, names(value))) {
    value[[field]] <- if (field %in% c("date", "handover_date")) as.Date(NA) else NA
  }
  missing <- is.na(value$member_states_json) | !nzchar(value$member_states_json)
  value$member_states_json[missing] <- "{}"
  value$member_states_digest[missing] <- sha256_text("{}")
  value$member_count[missing] <- 0L
  value$active_member_count[missing] <- 0L
  value$unknown_member_count[missing] <- 0L
  value$concurrency_class[missing] <- "none"
  missing_deployment <- is.na(value$deployment_states_json) |
    !nzchar(value$deployment_states_json)
  value$deployment_states_json[missing_deployment] <- "{}"
  value$deployment_states_digest[missing_deployment] <-
    sha256_text("{}")
  value$resolved_deployment_count[missing_deployment] <- 0L
  value[fields]
}

selected_resolution_prepare_event_map <- function(value) { # nolint: object_length_linter.
  fields <- c("event_id", "physical_location_id", "analysis_unit_id", "species",
              "event_time", "source_membership_count", "source_membership_digest",
              "source_membership_reference", "deployment_id",
              "deployment_resolution_state")
  for (field in setdiff(fields, names(value))) value[[field]] <- NA
  value[fields]
}

write_selected_resolution_artifacts <- function(state, root) { # nolint: object_length_linter.
  paths <- selected_resolution_paths(root)
  selected_write_csv(selected_resolution_prepare_membership(state$membership), paths[["membership"]])
  selected_write_csv(selected_resolution_prepare_operation(state$operation), paths[["operation"]])
  selected_write_csv(selected_resolution_prepare_event_map(state$event_map), paths[["event_map"]])
  summary <- state$summary
  summary$artifact_sha256 <- list(
    membership = sha256_file(paths[["membership"]]), operation = sha256_file(paths[["operation"]]),
    event_map = sha256_file(paths[["event_map"]])
  )
  atomic_write_json(summary, paths[["summary"]])
  paths
}

validate_selected_resolution_artifacts <- function( # nolint: object_length_linter.
    root,
    paths = selected_resolution_paths(root),
    require_integrity = TRUE) {
  expected <- selected_resolution_paths(root)
  if (!identical(names(paths), names(expected)) ||
        !identical(unname(normalizePath(paths, winslash = "/", mustWork = FALSE)),
                   unname(normalizePath(expected, winslash = "/", mustWork = FALSE)))) {
    stop("Selected-resolution artifact namespace is not exact.")
  }
  directory <- dirname(expected[["membership"]])
  files <- if (dir.exists(directory)) list.files(directory, all.files = FALSE, full.names = TRUE) else character()
  if (length(files) != 4L || !setequal(basename(files), basename(unlist(expected)))) {
    stop("Selected-resolution artifact namespace is incomplete or contains extras.")
  }
  if (any(!file.exists(unlist(expected)))) stop("Selected-resolution artifact is missing.")
  summary <- jsonlite::read_json(expected[["summary"]], simplifyVector = FALSE)
  for (name in c("membership", "operation", "event_map")) {
    if (!identical(summary$artifact_sha256[[name]], sha256_file(expected[[name]]))) {
      stop("Selected-resolution artifact fixity mismatch: ", name)
    }
  }
  membership <- utils::read.csv(expected[["membership"]], stringsAsFactors = FALSE,
                                check.names = FALSE, na.strings = "")
  operation <- utils::read.csv(expected[["operation"]], stringsAsFactors = FALSE,
                               check.names = FALSE, na.strings = "")
  event_map <- utils::read.csv(expected[["event_map"]], stringsAsFactors = FALSE,
                               check.names = FALSE, na.strings = "")
  required_membership <- c("resolution", "scheme_id", "scheme_version", "authority_reference",
                           "physical_location_id", "analysis_unit_id", "physical_latitude",
                           "physical_longitude", "representative_latitude",
                           "representative_longitude", "coordinate_basis")
  required_operation <- c("analysis_unit_id", "date", "operation", "member_states_json",
                          "member_states_digest", "member_count", "active_member_count",
                          "unknown_member_count", "deployment_states_json",
                          "deployment_states_digest", "resolved_deployment_count",
                          "concurrency_class", "handover_date")
  required_event <- c("event_id", "physical_location_id", "analysis_unit_id", "species",
                      "event_time", "source_membership_count", "source_membership_digest",
                      "source_membership_reference", "deployment_id",
                      "deployment_resolution_state")
  if (!identical(names(membership), required_membership) ||
        !identical(names(operation), required_operation) ||
        !identical(names(event_map), required_event)) stop("Selected-resolution artifact schema mismatch.")
  nominal_unavailable <- identical(summary$resolution, "nominal_station") &&
    identical(summary$status, "ineligible")
  if (anyDuplicated(membership$physical_location_id) ||
        (anyNA(membership$analysis_unit_id) && !nominal_unavailable) ||
        anyDuplicated(event_map$event_id) || anyNA(event_map$event_id) ||
        any(!event_map$source_membership_reference %in% "provenance/phase2/event_membership.json")) {
    stop("Selected-resolution artifact identity or lineage is invalid.")
  }
  operation$date <- as.Date(operation$date)
  operation$operation <- suppressWarnings(as.numeric(operation$operation))
  if (anyNA(operation$date) || any(!is.na(operation$operation) &
                                     !operation$operation %in% c(0, 1))) {
    stop("Selected-resolution operation semantics are invalid.")
  }
  for (i in seq_len(nrow(operation))) {
    contribution_json <- trimws(as.character(operation$member_states_json[[i]]))
    contribution_count <- suppressWarnings(as.integer(operation$member_count[[i]]))
    contribution_active <- suppressWarnings(as.integer(operation$active_member_count[[i]]))
    contribution_unknown <- suppressWarnings(as.integer(operation$unknown_member_count[[i]]))
    # Unit fixtures and legacy callers may provide no member-level evidence at
    # all.  The writer materializes that absence as an explicit empty object;
    # accept it only when every reconciled count is zero, while still failing
    # closed for any non-empty or internally inconsistent contribution.
    if (identical(contribution_json, "{}") && identical(contribution_count, 0L) &&
          identical(contribution_active, 0L) && identical(contribution_unknown, 0L)) {
      next
    }
    parsed <- tryCatch(jsonlite::fromJSON(contribution_json, simplifyVector = TRUE),
                       error = function(e) NULL)
    if (is.null(parsed) || !identical(operation$member_states_digest[[i]],
                                      sha256_text(canonical_json(parsed))) ||
          contribution_count != length(parsed) ||
          contribution_active != sum(as.character(parsed) == "1", na.rm = TRUE)) {
      stop("Selected-resolution operation contribution evidence does not reconcile.")
    }
    deployment_json <- trimws(as.character(
      operation$deployment_states_json[[i]]
    ))
    deployments <- tryCatch(
      jsonlite::fromJSON(deployment_json, simplifyVector = TRUE),
      error = function(e) NULL
    )
    resolved_deployments <- suppressWarnings(as.integer(
      operation$resolved_deployment_count[[i]]
    ))
    if (is.null(deployments) || !identical(
      operation$deployment_states_digest[[i]],
      sha256_text(canonical_json(deployments))
    ) || resolved_deployments != sum(!is.na(unlist(deployments)))) {
      stop("Selected-resolution deployment contribution evidence does not reconcile.")
    }
  }
  if (!identical(as.integer(summary$membership_count), as.integer(nrow(membership))) ||
    !identical(as.integer(summary$analysis_unit_count),
               as.integer(length(unique(stats::na.omit(
                 membership$analysis_unit_id
               ))))) ||
    !identical(as.integer(summary$physical_location_count),
               as.integer(length(unique(membership$physical_location_id)))) ||
    !identical(as.integer(summary$event_count), as.integer(nrow(event_map))) ||
    !identical(as.integer(summary$source_row_membership_count),
               as.integer(sum(event_map$source_membership_count)))) {
    stop("Selected-resolution summary counts do not reconcile.")
  }
  observed_operation_counts <- c(
    active = sum(operation$operation == 1, na.rm = TRUE),
    inactive = sum(operation$operation == 0, na.rm = TRUE),
    unknown = sum(is.na(operation$operation))
  )
  if (!identical(
    as.integer(unlist(summary$operation_state_counts, use.names = FALSE)),
    as.integer(observed_operation_counts)
  )) {
    stop("Selected-resolution operation-state counts do not reconcile.")
  }
  event_units <- membership$analysis_unit_id[
    match(event_map$physical_location_id, membership$physical_location_id)
  ]
  if (!identical(as.character(event_map$analysis_unit_id), as.character(event_units))) {
    stop("Selected-resolution event membership does not reconcile.")
  }
  if (isTRUE(require_integrity) && !isTRUE(summary$integrity_ok)) {
    stop("Selected-resolution summary reports an integrity failure.")
  }
  expected_status <- if (!isTRUE(summary$integrity_ok)) {
    "integrity_failure"
  } else if (!isTRUE(summary$route_eligible)) {
    "ineligible"
  } else {
    "eligible"
  }
  if (!identical(as.character(summary$status), expected_status)) {
    stop("Selected-resolution summary status does not reconcile.")
  }
  config_path <- file.path(root, "provenance", "config.raw.yml")
  can_reconstruct <- file.exists(config_path) &&
    exists("reconstruct_validation_state", mode = "function") &&
    exists("reconstruct_entity_state", mode = "function") &&
    exists("read_config", mode = "function")
  if (can_reconstruct) {
    config <- read_config(config_path, attach_runtime = FALSE)
    validation_state <- reconstruct_validation_state(root)
    entity_state <- reconstruct_entity_state(root)
    portable_snapshot <- portable_validation_snapshot(root, config)
    portable_snapshot$staging_dir <- root
    expected_state <- resolve_selected_resolution(
      config,
      portable_snapshot,
      validation_state,
      entity_state
    )
    normalize_frame <- function(frame) {
      if (!is.data.frame(frame)) return(list())
      lapply(seq_len(nrow(frame)), function(i) {
        row <- as.list(frame[i, , drop = FALSE])
        lapply(row, function(x) if (length(x) == 1L && is.na(x)) NULL else as.character(x))
      })
    }
    roundtrip_csv <- function(frame) {
      path <- tempfile("selected-resolution-reconstruction-", fileext = ".csv")
      on.exit(unlink(path, force = TRUE), add = TRUE)
      readr::write_csv(frame, path, na = "")
      utils::read.csv(
        path,
        stringsAsFactors = FALSE,
        check.names = FALSE,
        na.strings = ""
      )
    }
    expected_membership <- roundtrip_csv(
      selected_resolution_prepare_membership(expected_state$membership)
    )
    expected_operation <- roundtrip_csv(
      selected_resolution_prepare_operation(expected_state$operation)
    )
    expected_operation$date <- as.Date(expected_operation$date)
    expected_operation$operation <- suppressWarnings(as.numeric(
      expected_operation$operation
    ))
    expected_event <- roundtrip_csv(
      selected_resolution_prepare_event_map(expected_state$event_map)
    )
    observed_summary <- summary
    observed_summary$artifact_sha256 <- NULL
    expected_summary <- expected_state$summary
    reconstruction_matches <- c(
      membership = identical(
        canonical_json(normalize_frame(membership)),
        canonical_json(normalize_frame(expected_membership))
      ),
      operation = identical(
        canonical_json(normalize_frame(operation)),
        canonical_json(normalize_frame(expected_operation))
      ),
      event_map = identical(
        canonical_json(normalize_frame(event_map)),
        canonical_json(normalize_frame(expected_event))
      ),
      summary = identical(
        canonical_json(observed_summary),
        canonical_json(expected_summary)
      )
    )
    if (!all(reconstruction_matches)) {
      stop(
        "Selected-resolution artifacts do not reconstruct from immutable evidence: ",
        paste(names(reconstruction_matches)[!reconstruction_matches], collapse = ", ")
      )
    }
  }
  list(integrity_ok = isTRUE(summary$integrity_ok), route_eligible = isTRUE(summary$route_eligible),
       summary = summary, membership = membership, operation = operation, event_map = event_map)
}
