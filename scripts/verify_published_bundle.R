#!/usr/bin/env Rscript

canonicalize_independent <- function(value) {
  if (is.data.frame(value)) value <- lapply(value, canonicalize_independent)
  if (is.list(value)) {
    if (!is.null(names(value))) {
      value <- value[order(names(value), method = "radix")]
    }
    return(lapply(value, canonicalize_independent))
  }
  if (!is.null(names(value))) {
    value <- value[order(names(value), method = "radix")]
  }
  value
}

canonical_json_independent <- function(value) {
  jsonlite::toJSON(
    canonicalize_independent(value),
    auto_unbox = TRUE,
    null = "null",
    na = "null",
    digits = NA
  )
}

sha256_file_independent <- function(path) {
  unname(digest::digest(file = path, algo = "sha256", serialize = FALSE))
}

sha256_text_independent <- function(value) {
  digest::digest(
    charToRaw(enc2utf8(value)),
    algo = "sha256",
    serialize = FALSE
  )
}

safe_relative_independent <- function(path) {
  is.character(path) && length(path) == 1L && !is.na(path) && nzchar(path) &&
    !grepl("^/|(^|/)\\.\\.(/|$)|//", path)
}

bundle_file_independent <- function(root, relative) {
  if (!safe_relative_independent(relative)) stop("Unsafe bundle path: ", relative)
  path <- file.path(root, relative)
  root_real <- normalizePath(root, winslash = "/", mustWork = TRUE)
  path_real <- normalizePath(path, winslash = "/", mustWork = TRUE)
  if (!startsWith(path_real, paste0(root_real, "/")) ||
        isTRUE(file.info(path_real)$isdir) || nzchar(Sys.readlink(path))) {
    stop("Bundle path is not one contained regular file: ", relative)
  }
  path_real
}

independent_jaccard <- function(presence, ids) {
  rows <- vector("list", length(ids)^2)
  index <- 0L
  for (first in seq_along(ids)) {
    for (second in seq_along(ids)) {
      left <- presence[first, ] == 1L
      right <- presence[second, ] == 1L
      union_count <- sum(left | right)
      index <- index + 1L
      rows[[index]] <- data.frame(
        analysis_unit_id_1 = ids[[first]],
        analysis_unit_id_2 = ids[[second]],
        jaccard_dissimilarity = if (union_count == 0L) {
          NA_real_
        } else {
          1 - sum(left & right) / union_count
        },
        stringsAsFactors = FALSE
      )
    }
  }
  do.call(rbind, rows)
}

compare_jaccard <- function(observed, expected, label) {
  keys <- c("analysis_unit_id_1", "analysis_unit_id_2")
  observed <- observed[do.call(order, observed[keys]), c(keys, "jaccard_dissimilarity")]
  expected <- expected[do.call(order, expected[keys]), c(keys, "jaccard_dissimilarity")]
  rownames(observed) <- rownames(expected) <- NULL
  if (!identical(observed[keys], expected[keys]) ||
    !isTRUE(all.equal(
      observed$jaccard_dissimilarity,
      expected$jaccard_dissimilarity,
      tolerance = 1e-12,
      check.attributes = FALSE
    ))) {
    stop(label, " Jaccard values disagree.")
  }
  invisible(TRUE)
}

validate_jaccard_semantics <- function(jaccard, presence, ids) {
  values <- jaccard$jaccard_dissimilarity
  if (any(!is.na(values) & (values < 0 | values > 1))) {
    stop("Published Jaccard values fall outside [0, 1].")
  }
  matrix <- matrix(
    values,
    nrow = length(ids),
    ncol = length(ids),
    byrow = TRUE
  )
  if (!isTRUE(all.equal(
    matrix,
    t(matrix),
    tolerance = 1e-12,
    check.attributes = FALSE
  ))) {
    stop("Published Jaccard matrix is not symmetric.")
  }
  expected_diagonal <- ifelse(rowSums(presence) == 0L, NA_real_, 0)
  if (!isTRUE(all.equal(
    diag(matrix),
    expected_diagonal,
    tolerance = 1e-12,
    check.attributes = FALSE
  ))) {
    stop("Published Jaccard diagonal does not respect empty unions.")
  }
  invisible(TRUE)
}

verify_source_inventory <- function(bundle, manifest) {
  inventory <- jsonlite::read_json(
    bundle_file_independent(bundle, manifest$source_inventory),
    simplifyVector = FALSE
  )
  if (!identical(inventory$source_inventory_schema,
                 "camtrap-source-inventory/1.0") ||
        !identical(inventory$run_id, manifest$run_id) ||
        !is.list(inventory$files)) {
    stop("Published source inventory is malformed.")
  }
  paths <- vapply(inventory$files, `[[`, character(1), "path")
  if (anyDuplicated(paths) ||
        any(!vapply(paths, safe_relative_independent, logical(1)))) {
    stop("Published source inventory paths are unsafe or duplicated.")
  }
  for (record in inventory$files) {
    path <- bundle_file_independent(bundle, record$path)
    if (as.numeric(record$bytes) != unname(as.numeric(file.info(path)$size)) ||
          !identical(record$sha256, sha256_file_independent(path))) {
      stop("Published source inventory fixity mismatch: ", record$path)
    }
  }
  stable <- lapply(inventory$files, function(record) {
    list(
      path = record$path,
      bytes = as.numeric(record$bytes),
      sha256 = record$sha256,
      role = record$role,
      consumed_by_parser = record$consumed_by_parser
    )
  })
  identity <- sha256_text_independent(canonical_json_independent(stable))
  if (!identical(identity, inventory$source_sha256) ||
        !identical(identity, manifest$fingerprints$source)) {
    stop("Published source inventory identity does not reconcile.")
  }
  inventory
}

verify_physical_source <- function(bundle, inventory, inputs) {
  site_records <- Filter(function(record) {
    grepl("^source_snapshot/four_table/site(\\.[^/]*)?$", record$path)
  }, inventory$files)
  if (length(site_records) == 0L) return(invisible(TRUE))
  if (length(site_records) != 1L) {
    stop("Published bundle has ambiguous physical-location source evidence.")
  }
  source <- utils::read.csv(
    bundle_file_independent(bundle, site_records[[1L]]$path),
    stringsAsFactors = FALSE,
    check.names = FALSE,
    na.strings = c("", "NA")
  )
  names(source) <- janitor::make_clean_names(names(source))
  if (anyDuplicated(names(source))) {
    stop("Physical-location source columns collide after normalization.")
  }
  validated <- inputs$site
  if (!"site" %in% names(source) || !all(names(source) %in% names(validated)) ||
        anyDuplicated(source$site) || anyDuplicated(validated$site) ||
        !setequal(as.character(source$site), as.character(validated$site))) {
    stop("Physical-location source and validated identities do not reconcile.")
  }
  matched <- match(as.character(source$site), as.character(validated$site))
  normalize <- function(value) {
    value <- as.character(value)
    value[is.na(value)] <- "<NA>"
    value
  }
  for (field in names(source)) {
    if (!identical(
      normalize(source[[field]]),
      normalize(validated[[field]][matched])
    )) {
      stop("Physical-location source field changed: ", field)
    }
  }
  invisible(TRUE)
}

verify_event_ledger <- function(bundle, manifest, memberships) {
  ledger <- jsonlite::read_json(bundle_file_independent(
    bundle,
    manifest$audit$events$source_row_ledger
  ), simplifyVector = TRUE)
  rows <- ledger$records
  required <- c(
    "row_schema", "source_row_id", "resource_id", "logical_name",
    "record_ordinal", "disposition", "rule_id", "reason"
  )
  if (!identical(ledger$source_row_ledger_schema,
                 "camtrap-source-row-ledger/1.0") ||
        !identical(ledger$disposition_scope, "event_formation") ||
        !is.data.frame(rows) || !identical(names(rows), required) ||
        anyDuplicated(rows$source_row_id) ||
        any(!rows$disposition %in% c("retained", "excluded"))) {
    stop("Published final source-row ledger is malformed.")
  }
  observations <- rows$logical_name %in% c("obs", "observations")
  retained <- rows$source_row_id[
    observations & rows$disposition == "retained"
  ]
  excluded <- observations & rows$disposition == "excluded"
  if (!setequal(retained, memberships$source_row_id) ||
        any(!memberships$source_row_id %in% rows$source_row_id) ||
        any(!nzchar(rows$rule_id[excluded])) ||
        any(!nzchar(rows$reason[excluded]))) {
    stop("Published source-row dispositions do not reconcile to memberships.")
  }
  invisible(TRUE)
}

parse_independent_date <- function(value) {
  if (inherits(value, "Date")) return(value)
  text <- as.character(value)
  parsed <- suppressWarnings(as.Date(text, format = "%d/%m/%Y"))
  missing <- is.na(parsed)
  parsed[missing] <- suppressWarnings(as.Date(text[missing]))
  parsed
}

deployment_at_date <- function(lineage, location, date) {
  rows <- lineage[
    lineage$physical_location_identifier == location &
      lineage$resolution_state == "resolved",
    ,
    drop = FALSE
  ]
  starts <- parse_independent_date(rows$interval_start)
  ends <- parse_independent_date(rows$interval_end)
  rows <- rows[
    !is.na(starts) & !is.na(ends) & starts <= date & ends >= date,
    ,
    drop = FALSE
  ]
  ids <- unique(as.character(rows$deployment_identifier))
  ids <- ids[!is.na(ids) & nzchar(ids)]
  if (length(ids) == 1L) ids[[1L]] else NA_character_
}

independent_concurrency <- function(lineage, active_sites, unit, date) {
  if (length(active_sites) < 2L) {
    return(list(class = "none", handover = as.Date(NA), reason = NULL))
  }
  if (length(active_sites) > 2L) {
    return(list(
      class = "concurrent_active_members",
      handover = as.Date(NA),
      reason = paste0("concurrent_active_member_count_gt_two:", unit, ":", date)
    ))
  }
  pair <- lineage[
    lineage$physical_location_identifier %in% active_sites,
    ,
    drop = FALSE
  ]
  if (nrow(pair) != 2L || anyDuplicated(pair$physical_location_identifier)) {
    if (nrow(pair) > 2L || anyDuplicated(pair$physical_location_identifier)) {
      stop("Published route has conflicting deployment evidence.")
    }
    return(list(
      class = "concurrent_active_members",
      handover = as.Date(NA),
      reason = paste0("missing_deployment_evidence:", unit, ":", date)
    ))
  }
  starts <- parse_independent_date(pair$interval_start)
  ends <- parse_independent_date(pair$interval_end)
  if (anyNA(starts) || anyNA(ends) || any(starts > ends)) {
    stop("Published route has malformed deployment chronology.")
  }
  first <- pair[1L, , drop = FALSE]
  second <- pair[2L, , drop = FALSE]
  forward <- identical(
    as.character(first$successor_deployment_id),
    as.character(second$deployment_identifier)
  ) && identical(
    as.character(second$predecessor_deployment_id),
    as.character(first$deployment_identifier)
  ) && ends[[1L]] == date && starts[[2L]] == date
  reverse <- identical(
    as.character(second$successor_deployment_id),
    as.character(first$deployment_identifier)
  ) && identical(
    as.character(first$predecessor_deployment_id),
    as.character(second$deployment_identifier)
  ) && ends[[2L]] == date && starts[[1L]] == date
  exact <- all(pair$date_precision == "day") &&
    all(pair$chronology_state ==
          "same_date_boundary_not_full_day_overlap_or_routing_claim") &&
    all(pair$endpoint_semantics ==
          "inclusive_at_day_precision_unknown_time") &&
    all(pair$resolution_state == "resolved") && (forward || reverse)
  if (exact) {
    list(class = "approved_same_day_handover", handover = date, reason = NULL)
  } else {
    list(
      class = "concurrent_active_members",
      handover = as.Date(NA),
      reason = paste0("genuine_concurrent_member_deployments:", unit, ":", date)
    )
  }
}

verify_selected_route_independent <- function( # nolint: object_length_linter.
    bundle,
    manifest,
    membership,
    operation,
    event_map,
    inputs) {
  selected <- manifest$audit$selected_resolution
  summary <- jsonlite::read_json(bundle_file_independent(
    bundle,
    selected$summary
  ), simplifyVector = FALSE)
  lineage <- utils::read.csv(bundle_file_independent(
    bundle,
    manifest$audit$entity$deployment_lineage
  ), stringsAsFactors = FALSE, na.strings = "")
  dates <- parse_independent_date(inputs$op$date)
  observed_dates <- parse_independent_date(operation$date)
  if (anyNA(dates) || anyNA(observed_dates) || anyDuplicated(dates)) {
    stop("Published selected operation dates are malformed.")
  }
  units <- sort(unique(as.character(membership$analysis_unit_id)), method = "radix")
  expected_keys <- as.vector(outer(
    units,
    as.character(dates),
    paste,
    sep = "\r"
  ))
  observed_keys <- paste(operation$analysis_unit_id, observed_dates, sep = "\r")
  if (anyDuplicated(observed_keys) || !setequal(observed_keys, expected_keys)) {
    stop("Published selected operation does not cover the physical effort frame.")
  }
  route_reasons <- character()
  for (index in seq_len(nrow(operation))) {
    unit <- as.character(operation$analysis_unit_id[[index]])
    date <- observed_dates[[index]]
    date_index <- match(date, dates)
    members <- sort(as.character(membership$physical_location_id[
      membership$analysis_unit_id == unit
    ]), method = "radix")
    if (any(!members %in% names(inputs$op))) {
      stop("Published membership contains a location absent from physical effort.")
    }
    states <- vapply(members, function(id) {
      value <- inputs$op[[id]][[date_index]]
      if (is.na(value)) NA_character_ else as.character(value)
    }, character(1))
    names(states) <- members
    deployments <- vapply(
      members,
      deployment_at_date,
      character(1),
      lineage = lineage,
      date = date
    )
    names(deployments) <- members
    member_json <- canonical_json_independent(as.list(states))
    deployment_json <- canonical_json_independent(as.list(deployments))
    active_sites <- names(states)[!is.na(states) & states == "1"]
    concurrency <- independent_concurrency(
      lineage,
      active_sites,
      unit,
      date
    )
    route_reasons <- c(route_reasons, concurrency$reason)
    expected_operation <- if (length(active_sites)) {
      1
    } else if (all(!is.na(states) & states == "0")) {
      0
    } else {
      NA_real_
    }
    observed_handover <- as.character(operation$handover_date[[index]])
    if (is.na(observed_handover) || !nzchar(observed_handover)) {
      observed_handover <- as.Date(NA)
    } else {
      observed_handover <- parse_independent_date(observed_handover)
    }
    checks <- c(
      member_json = identical(
        as.character(operation$member_states_json[[index]]),
        as.character(member_json)
      ),
      member_digest = identical(
        as.character(operation$member_states_digest[[index]]),
        sha256_text_independent(member_json)
      ),
      member_count = as.integer(operation$member_count[[index]]) ==
        length(members),
      active_count = as.integer(operation$active_member_count[[index]]) ==
        length(active_sites),
      unknown_count = as.integer(operation$unknown_member_count[[index]]) ==
        sum(is.na(states)),
      deployment_json = identical(
        as.character(operation$deployment_states_json[[index]]),
        as.character(deployment_json)
      ),
      deployment_digest = identical(
        as.character(operation$deployment_states_digest[[index]]),
        sha256_text_independent(deployment_json)
      ),
      deployment_count = as.integer(
        operation$resolved_deployment_count[[index]]
      ) == sum(!is.na(deployments)),
      operation = isTRUE(all.equal(
        as.numeric(operation$operation[[index]]),
        expected_operation,
        check.attributes = FALSE
      )),
      concurrency = identical(
        as.character(operation$concurrency_class[[index]]),
        concurrency$class
      ),
      handover = isTRUE(all.equal(observed_handover, concurrency$handover))
    )
    checks[is.na(checks)] <- FALSE
    if (!all(checks)) {
      stop(
        "Published selected operation does not independently reconstruct: ",
        paste(names(checks)[!checks], collapse = ", ")
      )
    }
  }
  route_reasons <- unique(route_reasons[!vapply(
    route_reasons,
    is.null,
    logical(1)
  )])
  route_eligible <- length(route_reasons) == 0L
  expected_status <- if (route_eligible) "eligible" else "ineligible"
  artifact_paths <- c(
    membership = selected$membership,
    operation = selected$operation,
    event_map = selected$event_map
  )
  artifact_sha256 <- vapply(artifact_paths, function(path) {
    sha256_file_independent(bundle_file_independent(bundle, path))
  }, character(1))
  operation_values <- suppressWarnings(as.numeric(operation$operation))
  operation_counts <- c(
    active = sum(operation_values == 1, na.rm = TRUE),
    inactive = sum(operation_values == 0, na.rm = TRUE),
    unknown = sum(is.na(operation_values))
  )
  if (!identical(summary$selected_resolution_summary_schema,
                 "camtrap-selected-resolution-summary/1.0") ||
    !isTRUE(summary$integrity_ok) ||
    !identical(summary$route_eligible, route_eligible) ||
    !identical(summary$status, expected_status) ||
    !setequal(unlist(summary$reasons, use.names = FALSE), route_reasons) ||
    !identical(
      unlist(summary$artifact_sha256, use.names = TRUE)[names(artifact_sha256)],
      artifact_sha256
    ) ||
    !identical(as.integer(unlist(summary$operation_state_counts)),
               as.integer(operation_counts)) ||
    as.integer(summary$membership_count) != nrow(membership) ||
    as.integer(summary$analysis_unit_count) != length(units) ||
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
    stop("Published selected route eligibility or summary does not reconstruct.")
  }
  route_eligible
}

verify_published_bundle_independent <- function( # nolint: object_length_linter.
    bundle,
    oracle = NULL) {
  bundle <- normalizePath(bundle, winslash = "/", mustWork = TRUE)
  manifest_path <- file.path(bundle, "run_manifest.json")
  manifest <- jsonlite::read_json(manifest_path, simplifyVector = FALSE)
  if (!identical(manifest$manifest_schema, "camtrap-run-bundle/2.0") ||
        !identical(manifest$status, "completed") ||
        !file.exists(file.path(bundle, "READY")) ||
        !file.exists(file.path(bundle, "COMPLETE.json"))) {
    stop("Published bundle is not a completed current-contract run.")
  }
  if (!identical(basename(bundle), manifest$run_id)) {
    stop("Published bundle identity disagrees with its directory.")
  }
  completion <- jsonlite::read_json(
    file.path(bundle, "COMPLETE.json"),
    simplifyVector = FALSE
  )
  completion_valid <- identical(
    completion$completion_schema,
    "camtrap-run-completion/2.0"
  ) && identical(completion$status, "completed") &&
    identical(completion$run_id, manifest$run_id) &&
    identical(
      completion$manifest_sha256,
      sha256_file_independent(manifest_path)
    )
  if (!completion_valid) {
    stop("Published completion record does not bind the current manifest.")
  }

  recorded_paths <- vapply(manifest$payload, `[[`, character(1), "path")
  actual <- list.files(
    bundle,
    recursive = TRUE,
    full.names = TRUE,
    all.files = TRUE,
    no.. = TRUE,
    include.dirs = FALSE
  )
  actual <- normalizePath(actual, winslash = "/", mustWork = TRUE)
  actual_relative <- substring(actual, nchar(bundle) + 2L)
  actual_relative <- sort(setdiff(
    actual_relative,
    c("run_manifest.json", "READY", "COMPLETE.json")
  ), method = "radix")
  if (anyDuplicated(recorded_paths) || !setequal(recorded_paths, actual_relative)) {
    stop(
      "Published payload inventory is incomplete or contains extras. Missing: ",
      paste(setdiff(recorded_paths, actual_relative), collapse = ", "),
      "; extras: ",
      paste(setdiff(actual_relative, recorded_paths), collapse = ", ")
    )
  }
  for (index in seq_along(manifest$payload)) {
    record <- manifest$payload[[index]]
    path <- bundle_file_independent(bundle, record$path)
    if (as.numeric(record$bytes) != unname(as.numeric(file.info(path)$size)) ||
          !identical(record$sha256, sha256_file_independent(path))) {
      stop("Published payload fixity mismatch: ", record$path)
    }
  }
  source_inventory <- verify_source_inventory(bundle, manifest)

  status <- jsonlite::read_json(
    bundle_file_independent(bundle, manifest$module_status),
    simplifyVector = FALSE
  )
  expected_modules <- c(
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
  modules <- vapply(status$records, `[[`, character(1), "module")
  states <- vapply(status$records, `[[`, character(1), "status")
  allowed_states <- c(
    "completed", "completed_with_warnings", "omitted", "failed"
  )
  records_valid <- vapply(status$records, function(record) {
    reason_valid <- identical(record$status, "completed") ||
      (is.character(record$reason) && length(record$reason) == 1L &&
         nzchar(record$reason))
    identical(record$module_status_schema, "camtrap-module-status/2.0") &&
      record$status %in% allowed_states &&
      record$actual_resolution %in% c("physical_location", "analysis_site") &&
      length(record$required_evidence) > 0L && reason_valid
  }, logical(1))
  if (!identical(status$module_status_set_schema,
                 "camtrap-module-status-set/2.0") ||
        !identical(status$run_id, manifest$run_id) ||
        !setequal(modules, expected_modules) || anyDuplicated(modules) ||
        any(states == "failed") || !all(records_valid)) {
    stop("Published module status contains a failure or missing candidate.")
  }
  records <- stats::setNames(status$records, modules)
  output_contract <- c(
    effort_coverage = "effort_coverage",
    observed_presence = "community_presence",
    observed_richness = "observed_richness",
    jaccard = "jaccard"
  )
  output_paths <- lapply(output_contract, function(name) {
    relative <- manifest$outputs[[name]]
    if (is.null(relative)) NULL else bundle_file_independent(bundle, relative)
  })
  for (module in names(output_contract)) {
    state <- records[[module]]$status
    present <- !is.null(output_paths[[module]])
    if (state %in% c("completed", "completed_with_warnings") && !present) {
      stop("Published selected payload is required by status: ", module)
    }
    if (identical(state, "omitted") && present) {
      stop("Published omitted selected module has a payload: ", module)
    }
  }

  events <- utils::read.csv(bundle_file_independent(
    bundle,
    manifest$audit$events$physical_events
  ), stringsAsFactors = FALSE)
  memberships <- utils::read.csv(bundle_file_independent(
    bundle,
    manifest$audit$events$event_membership
  ), stringsAsFactors = FALSE)
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
    stop("Published event identities or source memberships are invalid.")
  }
  for (index in seq_len(nrow(events))) {
    rows <- memberships[memberships$event_id == events$event_id[[index]], ]
    digest <- sha256_text_independent(canonical_json_independent(sort(
      rows$source_row_id,
      method = "radix"
    )))
    if (nrow(rows) != events$source_membership_count[[index]] ||
          !identical(digest, events$source_membership_digest[[index]]) ||
          any(rows$physical_location_id !=
                events$physical_location_id[[index]])) {
      stop("Published event membership does not independently reconcile.")
    }
  }
  verify_event_ledger(bundle, manifest, memberships)

  selected <- manifest$audit$selected_resolution
  selected_membership <- utils::read.csv(bundle_file_independent(
    bundle,
    selected$membership
  ), stringsAsFactors = FALSE)
  selected_operation <- utils::read.csv(bundle_file_independent(
    bundle,
    selected$operation
  ), stringsAsFactors = FALSE)
  selected_events <- utils::read.csv(bundle_file_independent(
    bundle,
    selected$event_map
  ), stringsAsFactors = FALSE)
  required_selected_event <- c(
    "event_id", "physical_location_id", "analysis_unit_id", "species",
    "event_time", "source_membership_count", "source_membership_digest",
    "source_membership_reference", "deployment_id",
    "deployment_resolution_state"
  )
  if (!identical(names(selected_events), required_selected_event) ||
        anyDuplicated(selected_events$event_id) ||
        any(!selected_events$source_membership_reference %in%
              "provenance/event_membership.csv")) {
    stop("Published selected event map is malformed.")
  }
  physical <- events[order(events$event_id, method = "radix"), , drop = FALSE]
  selected_events <- selected_events[
    order(selected_events$event_id, method = "radix"),
    ,
    drop = FALSE
  ]
  rownames(physical) <- rownames(selected_events) <- NULL
  shared <- c(
    "event_id", "physical_location_id", "species", "event_time",
    "source_membership_count", "source_membership_digest"
  )
  mapped_units <- selected_membership$analysis_unit_id[
    match(
      selected_events$physical_location_id,
      selected_membership$physical_location_id
    )
  ]
  if (!identical(selected_events[shared], physical[shared]) ||
        anyNA(mapped_units) ||
        !identical(as.character(selected_events$analysis_unit_id),
                   as.character(mapped_units)) ||
        sum(selected_events$source_membership_count) != nrow(memberships)) {
    stop("Published events contradict physical lineage or spatial mapping.")
  }

  inputs <- readRDS(bundle_file_independent(
    bundle,
    manifest$audit$validation$validated_inputs
  ))
  verify_physical_source(bundle, source_inventory, inputs)
  matched <- match(selected_membership$physical_location_id, inputs$site$site)
  if (anyNA(matched) ||
    !setequal(
      as.character(selected_membership$physical_location_id),
      as.character(inputs$site$site)
    ) ||
    !isTRUE(all.equal(
      selected_membership$physical_latitude,
      as.numeric(inputs$site$lat[matched]),
      tolerance = 0,
      check.attributes = FALSE
    )) ||
    !isTRUE(all.equal(
      selected_membership$physical_longitude,
      as.numeric(inputs$site$lon[matched]),
      tolerance = 0,
      check.attributes = FALSE
    ))) {
    stop("Published physical coordinates changed during grouping.")
  }

  route_eligible <- verify_selected_route_independent(
    bundle,
    manifest,
    selected_membership,
    selected_operation,
    selected_events,
    inputs
  )
  all_units <- sort(unique(as.character(selected_membership$analysis_unit_id)),
                    method = "radix")
  selected_operation$operation <- suppressWarnings(as.numeric(
    selected_operation$operation
  ))
  eligible_units <- sort(unique(as.character(
    selected_operation$analysis_unit_id[
      !is.na(selected_operation$operation) &
        selected_operation$operation == 1
    ]
  )), method = "radix")
  core_modules <- c("observed_presence", "observed_richness", "jaccard")
  core_present <- vapply(
    output_paths[core_modules],
    Negate(is.null),
    logical(1)
  )
  core_states <- vapply(records[core_modules], `[[`, character(1), "status")
  if (length(unique(core_present)) != 1L) {
    stop("Published selected ecological core is only partially present.")
  }
  if (!route_eligible) {
    selected_states <- vapply(
      records[c("effort_coverage", core_modules)],
      `[[`,
      character(1),
      "status"
    )
    if (any(selected_states != "omitted") ||
          any(vapply(output_paths, Negate(is.null), logical(1)))) {
      stop("Published ineligible selected route has ecological output.")
    }
  } else if (is.null(output_paths$effort_coverage) ||
               !identical(records$effort_coverage$status, "completed")) {
    stop("Published eligible route lacks complete effort coverage.")
  }
  if (!is.null(output_paths$effort_coverage)) {
    effort <- utils::read.csv(
      output_paths$effort_coverage,
      stringsAsFactors = FALSE
    )
    expected_effort <- do.call(rbind, lapply(all_units, function(id) {
      rows <- selected_operation[
        selected_operation$analysis_unit_id == id,
        ,
        drop = FALSE
      ]
      data.frame(
        analysis_unit_id = id,
        confirmed_active_days = sum(rows$operation == 1, na.rm = TRUE),
        confirmed_inactive_days = sum(rows$operation == 0, na.rm = TRUE),
        unknown_days = sum(is.na(rows$operation)),
        observed_date_count = nrow(rows),
        stringsAsFactors = FALSE
      )
    }))
    fields <- c(
      "analysis_unit_id", "confirmed_active_days", "confirmed_inactive_days",
      "unknown_days", "observed_date_count"
    )
    if (!identical(effort[fields], expected_effort[fields])) {
      stop("Published effort coverage does not reconstruct from operation.")
    }
  }

  jaccard <- NULL
  expected_presence <- NULL
  if (all(core_present)) {
    if (!route_eligible || length(eligible_units) == 0L) {
      stop("Published selected ecological core has no confirmed effort.")
    }
    eligible_events <- selected_events[
      selected_events$analysis_unit_id %in% eligible_units,
      ,
      drop = FALSE
    ]
    species <- sort(unique(as.character(eligible_events$species)),
                    method = "radix")
    species <- species[!is.na(species) & nzchar(species)]
    expected_presence <- matrix(
      0L,
      nrow = length(eligible_units),
      ncol = length(species),
      dimnames = list(NULL, species)
    )
    if (nrow(eligible_events) > 0L) {
      pairs <- unique(eligible_events[c("analysis_unit_id", "species")])
      expected_presence[cbind(
        match(pairs$analysis_unit_id, eligible_units),
        match(pairs$species, species)
      )] <- 1L
    }
    expected_core_status <- if (
      length(setdiff(all_units, eligible_units)) > 0L ||
        any(rowSums(expected_presence) == 0L)
    ) {
      "completed_with_warnings"
    } else {
      "completed"
    }
    if (any(core_states != expected_core_status)) {
      stop("Published selected core status contradicts effort and detections.")
    }
    presence <- utils::read.csv(
      output_paths$observed_presence,
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
          !identical(unname(observed_presence), unname(expected_presence))) {
      stop("Published presence does not reconstruct from selected events.")
    }
    richness <- utils::read.csv(
      output_paths$observed_richness,
      stringsAsFactors = FALSE
    )
    if (!identical(as.character(richness$analysis_unit_id), eligible_units) ||
          !identical(as.integer(richness$observed_richness),
                     as.integer(rowSums(expected_presence)))) {
      stop("Published richness does not reconstruct from selected events.")
    }
    jaccard <- utils::read.csv(
      output_paths$jaccard,
      stringsAsFactors = FALSE
    )
    expected_jaccard <- independent_jaccard(
      expected_presence,
      eligible_units
    )
    compare_jaccard(jaccard, expected_jaccard, "Event-reconstructed")
    validate_jaccard_semantics(
      jaccard,
      expected_presence,
      eligible_units
    )
  } else if (route_eligible &&
               (length(eligible_units) > 0L || any(core_states != "omitted"))) {
    stop("Published eligible selected ecological core is unjustifiably omitted.")
  } else if (!is.null(oracle)) {
    stop("An oracle cannot be checked when selected community outputs are omitted.")
  }

  scheme <- unique(selected_membership$scheme_id)
  if (identical(scheme, "judbury-analysis-site")) {
    oracle_sha256 <-
      "c45bb6285b58071c575a26cc9e85b556cacbcdee9f2dd0f936ae27f0d588daab"
    if (is.null(jaccard) || is.null(oracle) ||
          !identical(sha256_file_independent(oracle), oracle_sha256)) {
      stop("Judbury release requires the accepted Goal 010 Jaccard oracle.")
    }
    accepted <- utils::read.csv(oracle, stringsAsFactors = FALSE)
    compare_jaccard(jaccard, accepted, "Accepted oracle")
    expected_counts <- c(
      physical_locations = 13L,
      analysis_units = 9L,
      operation_rows = 9639L,
      events = 11572L,
      source_memberships = 15672L
    )
    observed_counts <- c(
      physical_locations = length(unique(
        selected_membership$physical_location_id
      )),
      analysis_units = length(unique(selected_membership$analysis_unit_id)),
      operation_rows = nrow(selected_operation),
      events = nrow(events),
      source_memberships = nrow(memberships)
    )
    if (!identical(as.integer(observed_counts), as.integer(expected_counts))) {
      stop("Published Judbury foundation counts changed.")
    }
  }
  report <- bundle_file_independent(bundle, manifest$report)
  if (unname(as.numeric(file.info(report)$size)) == 0) {
    stop("Published HTML ecological report is empty.")
  }
  list(
    valid = TRUE,
    run_id = manifest$run_id,
    physical_locations = length(unique(
      selected_membership$physical_location_id
    )),
    analysis_units = length(unique(selected_membership$analysis_unit_id)),
    eligible_analysis_units = length(eligible_units),
    operation_rows = nrow(selected_operation),
    events = nrow(events),
    source_memberships = nrow(memberships),
    jaccard_pairs = if (is.null(jaccard)) 0L else nrow(jaccard),
    oracle_checked = !is.null(oracle)
  )
}

parse_verifier_args <- function(args) {
  if (length(args) == 1L) return(list(bundle = args[[1L]], oracle = NULL))
  if (length(args) == 3L && identical(args[[2L]], "--oracle")) {
    return(list(bundle = args[[1L]], oracle = args[[3L]]))
  }
  stop("Usage: verify_published_bundle.R <bundle> [--oracle <selected_jaccard.csv>]")
}

if (sys.nframe() == 0L) {
  args <- parse_verifier_args(commandArgs(trailingOnly = TRUE))
  result <- verify_published_bundle_independent(args$bundle, args$oracle)
  cat(canonical_json_independent(result), "\n")
}
