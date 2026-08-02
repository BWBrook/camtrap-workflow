# community_matrices.R

#' Build selected-resolution presence by logical OR
#'
#' @param event_map Validated event-to-analysis-unit map.
#' @param analysis_units Character vector of selected analytical units.
#' @param species Character vector of observed species columns.
#' @return A 0/1 data frame in the supplied row and column order.
#' @export
build_selected_presence <- function(event_map, analysis_units, species) {
  if (!is.data.frame(event_map) ||
        !all(c("analysis_unit_id", "species") %in% names(event_map))) {
    stop("Selected presence requires analysis-unit and species event fields.")
  }
  analysis_units <- as.character(analysis_units)
  species <- as.character(species)
  if (anyNA(analysis_units) || any(!nzchar(analysis_units)) ||
        anyDuplicated(analysis_units) || anyNA(species) ||
        any(!nzchar(species)) || anyDuplicated(species)) {
    stop("Selected presence identities must be complete and unique.")
  }
  presence <- matrix(
    0L,
    nrow = length(analysis_units),
    ncol = length(species),
    dimnames = list(NULL, species)
  )
  if (nrow(event_map) > 0L) {
    pairs <- unique(data.frame(
      analysis_unit_id = as.character(event_map$analysis_unit_id),
      species = as.character(event_map$species),
      stringsAsFactors = FALSE
    ))
    if (anyNA(pairs) || any(!pairs$analysis_unit_id %in% analysis_units) ||
          any(!pairs$species %in% species)) {
      stop("Selected event map contains malformed or orphaned identities.")
    }
    presence[cbind(
      match(pairs$analysis_unit_id, analysis_units),
      match(pairs$species, species)
    )] <- 1L
  }
  as.data.frame(presence, check.names = FALSE, stringsAsFactors = FALSE)
}

compute_selected_observed_richness <- function( # nolint: object_length_linter.
    presence_matrix,
    analysis_units = rownames(presence_matrix)) {
  matrix_value <- as.matrix(presence_matrix)
  if ((!is.numeric(matrix_value) && !is.logical(matrix_value)) ||
        anyNA(matrix_value) || any(!matrix_value %in% c(0, 1))) {
    stop("Observed richness requires complete zero/one presence values.")
  }
  analysis_units <- as.character(analysis_units)
  if (length(analysis_units) != nrow(matrix_value) || anyNA(analysis_units) ||
        any(!nzchar(analysis_units)) || anyDuplicated(analysis_units)) {
    stop("Observed richness requires one unique analysis-unit identity per row.")
  }
  data.frame(
    analysis_unit_id = analysis_units,
    observed_richness = as.integer(rowSums(matrix_value)),
    stringsAsFactors = FALSE
  )
}

compute_selected_jaccard <- function(
    presence_matrix,
    analysis_units = rownames(presence_matrix)) {
  matrix_value <- as.matrix(presence_matrix)
  if ((!is.numeric(matrix_value) && !is.logical(matrix_value)) ||
        anyNA(matrix_value) || any(!matrix_value %in% c(0, 1))) {
    stop("Jaccard requires complete zero/one presence values.")
  }
  analysis_units <- as.character(analysis_units)
  if (length(analysis_units) != nrow(matrix_value) || anyNA(analysis_units) ||
        any(!nzchar(analysis_units)) || anyDuplicated(analysis_units)) {
    stop("Jaccard requires one unique analysis-unit identity per row.")
  }
  rows <- vector("list", length(analysis_units)^2)
  index <- 0L
  for (first_index in seq_along(analysis_units)) {
    first <- matrix_value[first_index, ] == 1
    for (second_index in seq_along(analysis_units)) {
      second <- matrix_value[second_index, ] == 1
      union_count <- sum(first | second)
      index <- index + 1L
      rows[[index]] <- data.frame(
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
  if (length(rows) == 0L) {
    return(data.frame(
      analysis_unit_id_1 = character(),
      analysis_unit_id_2 = character(),
      jaccard_dissimilarity = numeric(),
      stringsAsFactors = FALSE
    ))
  }
  do.call(rbind, rows)
}


summarise_selected_effort_coverage <- function(operation, analysis_units) { # nolint: object_length_linter.
  if (!is.data.frame(operation) ||
        !all(c("analysis_unit_id", "date", "operation") %in% names(operation))) {
    stop("Selected effort coverage requires validated selected operation.")
  }
  analysis_units <- as.character(analysis_units)
  operation$analysis_unit_id <- as.character(operation$analysis_unit_id)
  operation$date <- as.Date(operation$date)
  operation$operation <- suppressWarnings(as.numeric(operation$operation))
  if (anyNA(operation$date) ||
        any(!is.na(operation$operation) & !operation$operation %in% c(0, 1)) ||
        any(!operation$analysis_unit_id %in% analysis_units) ||
        anyDuplicated(paste(operation$analysis_unit_id, operation$date, sep = "\r"))) {
    stop("Selected effort coverage contains invalid unit-date states.")
  }
  do.call(rbind, lapply(analysis_units, function(id) {
    rows <- operation[operation$analysis_unit_id == id, , drop = FALSE]
    data.frame(
      analysis_unit_id = id,
      confirmed_active_days = as.integer(sum(rows$operation == 1, na.rm = TRUE)),
      confirmed_inactive_days = as.integer(sum(rows$operation == 0, na.rm = TRUE)),
      unknown_days = as.integer(sum(is.na(rows$operation))),
      observed_date_count = as.integer(nrow(rows)),
      first_observed_date = if (nrow(rows)) min(rows$date) else as.Date(NA),
      last_observed_date = if (nrow(rows)) max(rows$date) else as.Date(NA),
      stringsAsFactors = FALSE
    )
  }))
}

selected_ecological_paths <- function(root) {
  tables <- file.path(root, "tables")
  list(
    effort_coverage = file.path(tables, "selected_effort_coverage.csv"),
    community_presence = file.path(tables, "selected_community_presence.csv"),
    observed_richness = file.path(tables, "selected_observed_richness.csv"),
    jaccard = file.path(tables, "selected_jaccard.csv"),
    status = file.path(tables, "selected_resolution_status.json")
  )
}

selected_contributors <- function(state, analysis_units) {
  membership <- state$membership
  if (!is.data.frame(membership) ||
        !all(c("physical_location_id", "analysis_unit_id") %in% names(membership))) {
    stop("Selected ecological outputs require validated membership.")
  }
  operation <- state$operation
  lapply(analysis_units, function(id) {
    deployments <- character()
    if (all(c("analysis_unit_id", "deployment_states_json") %in% names(operation))) {
      evidence <- operation$deployment_states_json[operation$analysis_unit_id == id]
      deployments <- unlist(lapply(evidence, function(value) {
        parsed <- tryCatch(jsonlite::fromJSON(value), error = function(e) NULL)
        unname(unlist(parsed, use.names = FALSE))
      }), use.names = FALSE)
    }
    if ("deployment_id" %in% names(state$event_map)) {
      deployments <- c(
        deployments,
        state$event_map$deployment_id[state$event_map$analysis_unit_id == id]
      )
    }
    physical <- sort(unique(as.character(membership$physical_location_id[
      membership$analysis_unit_id == id
    ])), method = "radix")
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

selected_common_metadata <- function(
    state,
    n,
    claim_limit,
    temporal_scope,
    analysis_unit_count = state$summary$analysis_unit_count) {
  data.frame(
    resolution = rep(state$summary$resolution, n),
    scheme_id = rep(state$summary$scheme_id, n),
    scheme_version = rep(state$summary$scheme_version, n),
    authority_reference = rep(state$summary$authority_reference, n),
    analysis_unit_count = rep(as.integer(analysis_unit_count), n),
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

selected_attach_metadata <- function(
    table,
    state,
    claim_limit,
    temporal_scope,
    analysis_unit_count = state$summary$analysis_unit_count) {
  cbind(
    table["analysis_unit_id"],
    selected_common_metadata(
      state,
      nrow(table),
      claim_limit,
      temporal_scope,
      analysis_unit_count
    ),
    table[setdiff(names(table), "analysis_unit_id")]
  )
}

selected_write_ecology_csv <- function(value, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  readr::write_csv(value, path, na = "")
  path
}

#' Write bounded selected-resolution ecological outputs
#'
#' @param state Validated selected-resolution state.
#' @param root Completed-run staging directory.
#' @return Named list of four nullable CSV paths and one status path.
#' @export
write_selected_ecological_outputs <- function( # nolint: object_length_linter.
    state, root) {
  if (!is.list(state) || !is.list(state$summary)) {
    stop("Selected ecological outputs require validated selected provenance.")
  }
  paths <- selected_ecological_paths(root)
  analysis_units <- sort(unique(as.character(stats::na.omit(
    state$membership$analysis_unit_id
  ))), method = "radix")
  if (length(analysis_units) != as.integer(state$summary$analysis_unit_count)) {
    stop("Selected ecological analysis-unit count does not reconcile.")
  }
  operation_dates <- as.Date(state$operation$date)
  temporal_scope <- if (!length(operation_dates) || all(is.na(operation_dates))) {
    c(NA_character_, NA_character_)
  } else {
    as.character(c(min(operation_dates, na.rm = TRUE),
                   max(operation_dates, na.rm = TRUE)))
  }

  output_paths <- output_links <- list(
    effort_coverage = NULL,
    community_presence = NULL,
    observed_richness = NULL,
    jaccard = NULL
  )
  status_names <- c(
    effort_coverage = "effort_coverage",
    community_presence = "observed_presence",
    observed_richness = "observed_richness",
    jaccard = "jaccard"
  )
  reasons <- state$reasons
  if (is.null(reasons) || length(reasons) == 0L) {
    reasons <- unlist(state$summary$reasons, use.names = FALSE)
  }
  reasons <- unique(as.character(reasons))
  default_reason <- if (length(reasons) > 0L) {
    paste(reasons, collapse = "; ")
  } else {
    "The selected spatial route lacked the required scientific evidence."
  }
  output_status <- list()
  eligible_units <- character()
  excluded_units <- character()
  zero_detection_units <- character()
  if (!isTRUE(state$integrity_ok)) {
    for (name in names(output_paths)) {
      output_status[[status_names[[name]]]] <- list(
        status = "failed",
        reason = default_reason
      )
    }
  } else if (!isTRUE(state$route_eligible)) {
    for (name in names(output_paths)) {
      output_status[[status_names[[name]]]] <- list(
        status = "omitted",
        reason = default_reason
      )
    }
  } else {
    effort <- summarise_selected_effort_coverage(state$operation, analysis_units)
    effort_table <- selected_attach_metadata(
      effort,
      state,
      "confirmed-active-days-only-no-downtime-filling",
      temporal_scope
    )
    output_paths$effort_coverage <- selected_write_ecology_csv(
      effort_table,
      paths$effort_coverage
    )
    output_links$effort_coverage <- file.path(
      "tables",
      basename(paths$effort_coverage)
    )
    output_status$effort_coverage <- list(status = "completed", reason = NULL)
    eligible_units <- effort$analysis_unit_id[effort$confirmed_active_days >= 1L]
    excluded_units <- setdiff(analysis_units, eligible_units)
    if (length(eligible_units) == 0L) {
      reason <- paste(
        "No selected analysis unit had at least one confirmed active day;",
        "presence, richness, and Jaccard were omitted."
      )
      for (name in c("community_presence", "observed_richness", "jaccard")) {
        output_status[[status_names[[name]]]] <- list(
          status = "omitted",
          reason = reason
        )
      }
    } else {
      eligible_events <- state$event_map[
        state$event_map$analysis_unit_id %in% eligible_units,
        ,
        drop = FALSE
      ]
      species <- sort(unique(as.character(eligible_events$species)),
                      method = "radix")
      species <- species[!is.na(species) & nzchar(species)]
      presence <- build_selected_presence(
        eligible_events,
        eligible_units,
        species
      )
      zero_detection_units <- eligible_units[rowSums(presence) == 0L]
      warning_parts <- character()
      if (length(excluded_units) > 0L) {
        warning_parts <- c(
          warning_parts,
          paste0(
            "Excluded units without a confirmed active day: ",
            paste(excluded_units, collapse = ", "), "."
          )
        )
      }
      if (length(zero_detection_units) > 0L) {
        warning_parts <- c(
          warning_parts,
          paste0(
            "Sampled units with zero detections have zero observed richness ",
            "and undefined empty-union Jaccard: ",
            paste(zero_detection_units, collapse = ", "), "."
          )
        )
      }
      core_status <- if (length(warning_parts)) {
        "completed_with_warnings"
      } else {
        "completed"
      }
      core_reason <- if (length(warning_parts)) {
        paste(warning_parts, collapse = " ")
      } else {
        NULL
      }
      tables <- list(
        community_presence = selected_attach_metadata(
          data.frame(
            analysis_unit_id = eligible_units,
            presence,
            check.names = FALSE
          ),
          state,
          "observed-presence-detection-effort-bounded",
          temporal_scope,
          length(eligible_units)
        ),
        observed_richness = selected_attach_metadata(
          compute_selected_observed_richness(presence, eligible_units),
          state,
          "observed-richness-detection-effort-bounded",
          temporal_scope,
          length(eligible_units)
        )
      )
      jaccard <- compute_selected_jaccard(presence, eligible_units)
      tables$jaccard <- cbind(
        jaccard[1:2],
        selected_common_metadata(
          state,
          nrow(jaccard),
          paste0(
            "jaccard-descriptive-observed-presence-effort-completeness-",
            "detectability-limited"
          ),
          temporal_scope,
          length(eligible_units)
        ),
        jaccard["jaccard_dissimilarity"]
      )
      written <- Map(
        selected_write_ecology_csv,
        tables,
        paths[names(tables)]
      )
      output_paths[names(written)] <- written
      output_links[names(written)] <- lapply(
        paths[names(written)],
        function(path) file.path("tables", basename(path))
      )
      for (name in names(written)) {
        output_status[[status_names[[name]]]] <- list(
          status = core_status,
          reason = core_reason
        )
      }
    }
  }
  statuses <- vapply(output_status, `[[`, character(1), "status")
  module_status <- if (any(statuses == "failed")) {
    "failed"
  } else if (all(statuses[names(statuses) != "effort_coverage"] == "omitted")) {
    "omitted"
  } else if (any(statuses == "completed_with_warnings")) {
    "completed_with_warnings"
  } else {
    "completed"
  }
  status_reasons <- unique(vapply(
    output_status[statuses != "completed"],
    function(value) value$reason,
    character(1)
  ))
  reason <- if (identical(module_status, "completed")) {
    NULL
  } else {
    paste(status_reasons, collapse = " ")
  }
  status <- list(
    module_status_schema = "camtrap-module-status/1.0",
    module = "selected_community",
    status = module_status,
    reason = reason,
    required_evidence = as.list(c(
      "validated_selected_resolution", "confirmed_effort",
      "physical_location_events"
    )),
    actual_resolution = state$summary$resolution,
    integrity_ok = isTRUE(state$integrity_ok),
    route_eligible = isTRUE(state$route_eligible),
    output_status = output_status,
    reasons = as.list(reasons),
    resolution = state$summary$resolution,
    scheme_id = state$summary$scheme_id,
    scheme_version = state$summary$scheme_version,
    authority_reference = state$summary$authority_reference,
    membership_count = as.integer(state$summary$membership_count),
    analysis_unit_count = as.integer(state$summary$analysis_unit_count),
    physical_location_count = as.integer(state$summary$physical_location_count),
    temporal_scope = list(start = temporal_scope[[1L]], end = temporal_scope[[2L]]),
    eligible_analysis_units = as.list(eligible_units),
    excluded_no_effort_analysis_units = as.list(excluded_units),
    zero_detection_analysis_units = as.list(zero_detection_units),
    effort_definition = paste(
      "one confirmed active selected analysis-unit calendar day after",
      "conservative member-location union; unknown periods are not effort"
    ),
    analysis_units = selected_contributors(state, analysis_units),
    claim_limits = list(
      effort_coverage = "confirmed-active-days-only-no-downtime-filling",
      community_presence = "observed-presence-detection-effort-bounded",
      observed_richness = "observed-richness-detection-effort-bounded",
      jaccard = "jaccard-descriptive-observed-presence-effort-completeness-detectability-limited"
    ),
    outputs = output_links
  )
  dir.create(dirname(paths$status), recursive = TRUE, showWarnings = FALSE)
  jsonlite::write_json(
    status, paths$status, auto_unbox = TRUE, pretty = TRUE,
    null = "null", na = "null", digits = NA
  )
  c(output_paths, list(status = paths$status))
}
