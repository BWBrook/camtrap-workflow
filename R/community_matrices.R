# community_matrices.R

#' Build community presence and abundance matrices
#'
#' @param events_per_day Tibble with columns site, species, date, events.
#' @param sites Optional character vector of sites to include.
#' @return List with `abundance` and `presence` tibbles (site x species).
#' @export
build_community_matrices <- function(events_per_day, sites = NULL) {
  import::from("dplyr", group_by, summarise, mutate)
  import::from("tidyr", pivot_wider, replace_na)
  import::from("tibble", tibble)
  import::from("dplyr", left_join)

  abundance <- events_per_day |>
    group_by(site, species) |>
    summarise(events = sum(events), .groups = "drop") |>
    pivot_wider(names_from = species, values_from = events, values_fill = 0)

  if (!is.null(sites)) {
    abundance <- tibble(site = unique(sites)) |>
      left_join(abundance, by = "site") |>
      mutate(across(-site, ~ replace_na(.x, 0)))
  }

  presence <- abundance |>
    mutate(across(-site, \(x) ifelse(x > 0, 1L, 0L)))

  list(abundance = abundance, presence = presence)
}

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

validate_selected_runtime_events <- function(event_map, obs_events) { # nolint: object_length_linter.
  map_fields <- c("event_id", "physical_location_id", "species", "event_time")
  event_fields <- c("event_id", "site", "species", "dt")
  if (!is.data.frame(event_map) || !all(map_fields %in% names(event_map)) ||
        !is.data.frame(obs_events) || !all(event_fields %in% names(obs_events))) {
    stop("Selected event conservation requires preflight and runtime events.")
  }
  if (anyDuplicated(event_map$event_id) || anyNA(event_map$event_id)) {
    stop("Selected preflight event identities are malformed or duplicated.")
  }
  groups <- split(seq_len(nrow(obs_events)), as.character(obs_events$event_id))
  inconsistent <- vapply(groups, function(index) {
    length(unique(obs_events$site[index])) != 1L ||
      length(unique(obs_events$species[index])) != 1L ||
      anyNA(obs_events$dt[index])
  }, logical(1))
  if (any(inconsistent)) stop("Runtime event membership is inconsistent.")

  event_ids <- names(groups)
  first <- vapply(groups, `[[`, integer(1), 1L)
  runtime <- data.frame(
    event_id = event_ids,
    physical_location_id = as.character(obs_events$site[first]),
    species = as.character(obs_events$species[first]),
    event_time = vapply(groups, function(index) {
      min(as.numeric(obs_events$dt[index]))
    }, numeric(1)),
    stringsAsFactors = FALSE
  )
  recorded_time <- if (inherits(event_map$event_time, "POSIXt")) {
    as.numeric(event_map$event_time)
  } else {
    recorded_text <- as.character(event_map$event_time)
    canonical_pattern <- paste0(
      "^[0-9]{4}-[0-9]{2}-[0-9]{2}T",
      "[0-9]{2}:[0-9]{2}:[0-9]{2}Z$"
    )
    if (anyNA(recorded_text) || any(!grepl(canonical_pattern, recorded_text))) {
      stop("Selected event times must use exact canonical UTC T...Z text.")
    }
    parsed <- as.POSIXct(
      recorded_text,
      format = "%Y-%m-%dT%H:%M:%SZ",
      tz = "UTC"
    )
    round_trip <- format(
      parsed,
      format = "%Y-%m-%dT%H:%M:%SZ",
      tz = "UTC",
      usetz = FALSE
    )
    if (anyNA(parsed) || !identical(unname(round_trip), unname(recorded_text))) {
      stop("Selected event times must use exact canonical UTC T...Z text.")
    }
    as.numeric(parsed)
  }
  recorded <- data.frame(
    event_id = as.character(event_map$event_id),
    physical_location_id = as.character(event_map$physical_location_id),
    species = as.character(event_map$species),
    event_time = recorded_time,
    stringsAsFactors = FALSE
  )
  runtime <- runtime[order(runtime$event_id, method = "radix"), , drop = FALSE]
  recorded <- recorded[order(recorded$event_id, method = "radix"), , drop = FALSE]
  rownames(runtime) <- rownames(recorded) <- NULL
  if (anyNA(recorded$event_time) ||
        !identical(runtime[1:3], recorded[1:3]) ||
        !isTRUE(all.equal(runtime$event_time, recorded$event_time,
                          tolerance = 0, check.attributes = FALSE))) {
    stop("Selected preflight event map does not match unchanged runtime events.")
  }
  counts <- table(recorded$species)
  list(
    checked = TRUE,
    exact = TRUE,
    preflight_event_count = as.integer(nrow(recorded)),
    runtime_event_count = as.integer(nrow(runtime)),
    per_species_event_count = stats::setNames(as.integer(counts), names(counts))
  )
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

selected_common_metadata <- function(state, n, claim_limit, temporal_scope) {
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

selected_attach_metadata <- function(table, state, claim_limit, temporal_scope) {
  cbind(
    table["analysis_unit_id"],
    selected_common_metadata(state, nrow(table), claim_limit, temporal_scope),
    table[setdiff(names(table), "analysis_unit_id")]
  )
}

selected_write_csv <- function(value, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  readr::write_csv(value, path, na = "")
  path
}

#' Write bounded selected-resolution ecological outputs
#'
#' @param state Validated selected-resolution state.
#' @param obs_events Unchanged runtime physical-location events.
#' @param root Completed-run staging directory.
#' @param event_conservation Optional prior event-conservation result.
#' @return Named list of four nullable CSV paths and one status path.
#' @export
write_selected_ecological_outputs <- function( # nolint: object_length_linter.
    state, obs_events, root, event_conservation = NULL) {
  if (!is.list(state) || !is.list(state$summary)) {
    stop("Selected ecological outputs require validated selected provenance.")
  }
  if (is.null(event_conservation)) {
    event_conservation <- if (isTRUE(state$integrity_ok)) {
      validate_selected_runtime_events(state$event_map, obs_events)
    } else {
      list(
        checked = FALSE,
        exact = FALSE,
        reason = "selected_resolution_integrity_failure"
      )
    }
  }
  if (isTRUE(state$integrity_ok) && !isTRUE(event_conservation$exact)) {
    stop("Event conservation did not pass.")
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
  if (isTRUE(state$integrity_ok) && isTRUE(state$route_eligible)) {
    species <- sort(unique(as.character(state$event_map$species)), method = "radix")
    species <- species[!is.na(species) & nzchar(species)]
    presence <- build_selected_presence(state$event_map, analysis_units, species)
    tables <- list(
      effort_coverage = selected_attach_metadata(
        summarise_selected_effort_coverage(state$operation, analysis_units),
        state, "confirmed-active-days-only-no-downtime-filling", temporal_scope
      ),
      community_presence = selected_attach_metadata(
        data.frame(analysis_unit_id = analysis_units, presence,
                   check.names = FALSE),
        state, "observed-presence-detection-effort-bounded", temporal_scope
      ),
      observed_richness = selected_attach_metadata(
        compute_selected_observed_richness(presence, analysis_units),
        state, "observed-richness-detection-effort-bounded", temporal_scope
      )
    )
    jaccard <- compute_selected_jaccard(presence, analysis_units)
    tables$jaccard <- cbind(
      jaccard[1:2],
      selected_common_metadata(
        state,
        nrow(jaccard),
        "jaccard-descriptive-observed-presence-effort-completeness-detectability-limited",
        temporal_scope
      ),
      jaccard["jaccard_dissimilarity"]
    )
    output_paths <- Map(selected_write_csv, tables, paths[names(tables)])
    output_links <- lapply(paths[names(tables)], function(path) {
      file.path("tables", basename(path))
    })
  }

  reasons <- state$reasons
  if (is.null(reasons) || length(reasons) == 0L) {
    reasons <- unlist(state$summary$reasons, use.names = FALSE)
  }
  reasons <- unique(as.character(reasons))
  module_status <- if (!isTRUE(state$integrity_ok)) {
    "failed"
  } else if (!isTRUE(state$route_eligible)) {
    "omitted"
  } else if (nrow(state$event_map) == 0L) {
    "completed_with_warnings"
  } else {
    "completed"
  }
  reason <- if (identical(module_status, "completed")) {
    NULL
  } else if (identical(module_status, "completed_with_warnings")) {
    "no_operational_events"
  } else if (length(reasons) > 0L) {
    reasons[[1L]]
  } else if (identical(module_status, "omitted")) {
    "scientific_prerequisites_not_met"
  } else {
    "integrity_failure"
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
    reasons = as.list(reasons),
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
    analysis_units = selected_contributors(state, analysis_units),
    claim_limits = list(
      effort_coverage = "confirmed-active-days-only-no-downtime-filling",
      community_presence = "observed-presence-detection-effort-bounded",
      observed_richness = "observed-richness-detection-effort-bounded",
      jaccard = "jaccard-descriptive-observed-presence-effort-completeness-detectability-limited"
    ),
    event_conservation = event_conservation,
    outputs = output_links
  )
  dir.create(dirname(paths$status), recursive = TRUE, showWarnings = FALSE)
  jsonlite::write_json(
    status, paths$status, auto_unbox = TRUE, pretty = TRUE,
    null = "null", na = "null", digits = NA
  )
  c(output_paths, list(status = paths$status))
}
