# event_outputs.R

#' Compute time gaps between independent events
#'
#' @param obs_events Observations with event_id and dt (POSIXct).
#' @return Tibble with one row per event and gap_hours to prior event.
#' @export
compute_event_spacing <- function(obs_events) {
  import::from("dplyr", group_by, summarise, arrange, mutate, lag, ungroup)

  obs_events |>
    group_by(site, species, event_id) |>
    summarise(event_time = min(dt), .groups = "drop") |>
    arrange(site, species, event_time) |>
    group_by(site, species) |>
    mutate(gap_hours = as.numeric(difftime(event_time, lag(event_time), units = "hours"))) |>
    ungroup()
}

#' Plot event spacing distribution
#'
#' @param event_spacing Output of `compute_event_spacing()`.
#' @param out_path File path where the figure is saved.
#' @return `out_path` invisibly.
#' @export
plot_event_spacing <- function(event_spacing, out_path) {
  import::from("ggplot2", ggplot, aes, geom_histogram, theme_minimal, labs, ggsave, scale_x_log10)
  import::from("dplyr", filter)

  dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)

  plot_data <- event_spacing |>
    filter(!is.na(gap_hours), gap_hours > 0)

  p <- ggplot(plot_data, aes(x = gap_hours)) +
    geom_histogram(bins = 30) +
    theme_minimal() +
    scale_x_log10() +
    labs(x = "Gap between events (hours, log10 scale)", y = "Count")

  ggsave(out_path, p, width = 8, height = 4, dpi = 300)
  out_path
}

#' Validate event invariants
#'
#' @param obs_events Observations with event_id (output of `define_events()`).
#' @param obs_filtered Observations filtered to active effort days.
#' @return TRUE invisibly if invariants pass.
#' @export
validate_event_invariants <- function(obs_events, obs_filtered) {
  import::from("dplyr", distinct, count, left_join, mutate)

  if (nrow(obs_events) > nrow(obs_filtered)) {
    stop("Event invariant failed: events table has more rows than filtered observations.")
  }

  event_counts <- obs_events |>
    distinct(site, species, event_id) |>
    count(site, species, name = "events")

  detection_counts <- obs_events |>
    count(site, species, name = "detections")

  joined <- left_join(event_counts, detection_counts, by = c("site", "species")) |>
    mutate(detections = ifelse(is.na(detections), 0, detections))

  if (any(joined$events > joined$detections)) {
    stop("Event invariant failed: event counts exceed detections for at least one site/species.")
  }

  invisible(TRUE)
}

event_membership_identity <- function(event_id, source_row_id) {
  sha256_text(canonical_json(list(
    identity_schema = "camtrap-event-membership-id/1.0",
    event_id = event_id,
    source_row_id = source_row_id
  )))
}

#' Build operational-event membership and observation dispositions
#'
#' @param obs Observation table after approved repairs.
#' @param op Effort table after approved repairs.
#' @param lineage Source-row lineage object.
#' @param threshold Event-gap threshold in minutes.
#' @param tz Timezone used by the current event rule.
#' @param fixed_offset_hours Optional fixed timezone offset.
#' @return Event membership, updated lineage, and current preprocessing tables.
build_event_lineage <- function(
    obs,
    op,
    lineage,
    threshold,
    tz,
    fixed_offset_hours = NULL) {
  if (!is.data.frame(obs) || !"index" %in% names(obs)) {
    stop("Event lineage requires the current observation index.")
  }
  if (anyNA(obs$index) || anyDuplicated(obs$index)) {
    stop("Event lineage cannot resolve a missing or duplicate observation index.")
  }
  mapping <- lineage$observation_map
  matches <- match(obs$index, mapping$internal_index)
  if (anyNA(matches) || anyDuplicated(mapping$source_row_id[matches])) {
    stop("Event lineage cannot resolve observations one-to-one to source rows.")
  }

  op_long <- pivot_op_long(op)
  if (anyDuplicated(paste(op_long$site, op_long$trap_date, sep = "\r"))) {
    stop("Effort mapping contains duplicate site-date keys.")
  }
  obs_filtered <- filter_obs_by_effort(obs, op_long)
  if (nrow(obs_filtered) > nrow(obs) || anyDuplicated(obs_filtered$index)) {
    stop("Effort filtering duplicated or expanded observation rows.")
  }
  obs_events <- define_events(
    obs_filtered,
    threshold = threshold,
    tz = tz,
    fixed_offset_hours = fixed_offset_hours
  )
  if (nrow(obs_events) > nrow(obs_filtered) || anyDuplicated(obs_events$index)) {
    stop("Operational-event mapping duplicated or expanded observation rows.")
  }

  event_rows <- unique(obs_events[c("event_id", "site", "species")])
  if (anyDuplicated(event_rows$event_id)) {
    stop("Operational event identity is ambiguous across site or species.")
  }
  event_rows <- event_rows[order(event_rows$event_id, method = "radix"), , drop = FALSE]
  event_records <- lapply(seq_len(nrow(event_rows)), function(index) {
    event_id <- event_rows$event_id[[index]]
    members <- obs_events$index[obs_events$event_id == event_id]
    list(
      event_schema = "camtrap-operational-event/1.0",
      event_id = event_id,
      site = event_rows$site[[index]],
      physical_location_id = event_rows$site[[index]],
      species = event_rows$species[[index]],
      member_count = as.integer(length(members))
    )
  })
  events <- if (length(event_records) == 0L) {
    data.frame(
      event_schema = character(),
      event_id = character(),
      site = character(),
      physical_location_id = character(),
      species = character(),
      member_count = integer(),
      stringsAsFactors = FALSE
    )
  } else {
    do.call(rbind, lapply(event_records, as.data.frame, stringsAsFactors = FALSE))
  }
  rownames(events) <- NULL

  membership_records <- lapply(seq_len(nrow(obs_events)), function(index) {
    source_index <- match(
      obs_events$index[[index]],
      mapping$internal_index
    )
    source_row_id <- mapping$source_row_id[[source_index]]
    data.frame(
      membership_schema = "camtrap-event-membership/1.0",
      membership_id = event_membership_identity(
        obs_events$event_id[[index]],
        source_row_id
      ),
      event_id = obs_events$event_id[[index]],
      source_row_id = source_row_id,
      physical_location_id = if (
        "physical_location_id" %in% names(obs_events)
      ) {
        as.character(obs_events$physical_location_id[[index]])
      } else {
        as.character(obs_events$site[[index]])
      },
      deployment_id = if ("deployment_id" %in% names(obs_events)) {
        as.character(obs_events$deployment_id[[index]])
      } else {
        NA_character_
      },
      stringsAsFactors = FALSE
    )
  })
  memberships <- if (length(membership_records) == 0L) {
    data.frame(
      membership_schema = character(),
      membership_id = character(),
      event_id = character(),
      source_row_id = character(),
      physical_location_id = character(),
      deployment_id = character(),
      stringsAsFactors = FALSE
    )
  } else {
    do.call(rbind, membership_records)
  }
  memberships <- memberships[
    order(
      memberships$event_id,
      memberships$source_row_id,
      method = "radix"
    ),
    ,
    drop = FALSE
  ]
  rownames(memberships) <- NULL

  updated <- lineage
  mapped_source <- stats::setNames(mapping$source_row_id, mapping$internal_index)
  filtered_ids <- unname(mapped_source[as.character(obs_filtered$index)])
  event_member_ids <- unname(mapped_source[as.character(obs_events$index)])
  parsed_time <- parse_datetime_local(
    obs$datetime,
    tz = tz,
    fixed_offset_hours = fixed_offset_hours,
    quiet = TRUE
  )
  unparseable_ids <- unname(mapped_source[as.character(obs$index[is.na(parsed_time)])])
  observation_names <- c("obs", "observations")
  observation_rows <- which(updated$rows$logical_name %in% observation_names)
  for (row_index in observation_rows) {
    source_row_id <- updated$rows$source_row_id[[row_index]]
    if (source_row_id %in% unparseable_ids) {
      updated$rows$disposition[[row_index]] <- "excluded"
      updated$rows$rule_id[[row_index]] <- "event.unparseable_time/1.0"
      updated$rows$reason[[row_index]] <- paste(
        "Observation time cannot be used by the unchanged event-gap rule."
      )
    } else if (!source_row_id %in% filtered_ids) {
      updated$rows$disposition[[row_index]] <- "excluded"
      updated$rows$rule_id[[row_index]] <- "effort.not_operational/1.0"
      updated$rows$reason[[row_index]] <- paste(
        "Observation is outside a configured camera-operational day."
      )
    } else if (!source_row_id %in% event_member_ids) {
      updated$rows$disposition[[row_index]] <- "excluded"
      updated$rows$rule_id[[row_index]] <- "event.unparseable_time/1.0"
      updated$rows$reason[[row_index]] <- paste(
        "Observation time cannot be used by the unchanged event-gap rule."
      )
    }
  }

  result <- list(
    event_lineage_schema = "camtrap-event-lineage/1.0",
    event_rule = list(
      rule_id = "operational_detection_event.gap/1.0",
      threshold_minutes = threshold,
      timezone = tz,
      fixed_offset_hours = fixed_offset_hours
    ),
    events = events,
    memberships = memberships,
    lineage = updated,
    obs_filtered = obs_filtered,
    obs_events = obs_events
  )
  validate_event_lineage(result, updated)
  result
}

validate_event_lineage <- function(event_lineage, lineage) {
  if (!identical(
    event_lineage$event_lineage_schema,
    "camtrap-event-lineage/1.0"
  )) {
    stop("Unsupported event-lineage schema.")
  }
  events <- event_lineage$events
  memberships <- event_lineage$memberships
  if (!is.data.frame(events) || !is.data.frame(memberships)) {
    stop("Event and membership records must be tables.")
  }
  rule <- event_lineage$event_rule
  if (!is.list(rule)) {
    stop("Operational-event rule is invalid or unsupported.")
  }
  valid_rule_id <- identical(
    rule$rule_id,
    "operational_detection_event.gap/1.0"
  )
  valid_threshold <- is.numeric(rule$threshold_minutes) &&
    length(rule$threshold_minutes) == 1L &&
    !is.na(rule$threshold_minutes) &&
    rule$threshold_minutes >= 0
  valid_timezone <- is.character(rule$timezone) &&
    length(rule$timezone) == 1L &&
    nzchar(rule$timezone)
  valid_offset <- is.null(rule$fixed_offset_hours) ||
    is.numeric(rule$fixed_offset_hours) &&
      length(rule$fixed_offset_hours) == 1L &&
      !is.na(rule$fixed_offset_hours)
  if (!valid_rule_id || !valid_threshold || !valid_timezone || !valid_offset) {
    stop("Operational-event rule is invalid or unsupported.")
  }
  valid_event_schema <- all(
    events$event_schema == "camtrap-operational-event/1.0"
  )
  valid_membership_schema <- all(
    memberships$membership_schema == "camtrap-event-membership/1.0"
  )
  complete_ids <- !anyNA(events$event_id) &&
    !anyNA(memberships$event_id) &&
    !anyNA(memberships$source_row_id)
  if (!valid_event_schema || !valid_membership_schema || !complete_ids) {
    stop("Operational-event membership contains an unsupported record.")
  }
  membership_keys <- paste(
    memberships$event_id,
    memberships$source_row_id,
    sep = "\r"
  )
  if (anyDuplicated(events$event_id) ||
        anyDuplicated(memberships$membership_id) ||
        anyDuplicated(membership_keys)) {
    stop("Duplicate or ambiguous event membership.")
  }
  expected_membership_ids <- if (nrow(memberships) == 0L) {
    character()
  } else {
    mapply(
      event_membership_identity,
      memberships$event_id,
      memberships$source_row_id,
      USE.NAMES = FALSE
    )
  }
  if (!identical(memberships$membership_id, expected_membership_ids)) {
    stop("Operational-event membership identity mismatch.")
  }
  if (any(!memberships$event_id %in% events$event_id)) {
    stop("Orphan event membership refers to an unknown event.")
  }
  if (any(!memberships$source_row_id %in% lineage$rows$source_row_id)) {
    stop("Orphan event membership refers to an unknown source row.")
  }
  excluded <- lineage$rows$source_row_id[
    lineage$rows$disposition == "excluded"
  ]
  if (any(memberships$source_row_id %in% excluded)) {
    stop("Excluded observation appears in operational-event membership.")
  }

  for (index in seq_len(nrow(events))) {
    count <- sum(memberships$event_id == events$event_id[[index]])
    if (count < 1L || count != events$member_count[[index]]) {
      stop("Operational event member count does not reconcile.")
    }
  }
  observation_names <- c("obs", "observations")
  retained <- lineage$rows$source_row_id[
    lineage$rows$logical_name %in% observation_names &
      lineage$rows$disposition != "excluded"
  ]
  if (!setequal(retained, memberships$source_row_id)) {
    stop("Retained observation rows do not exactly reconcile to event membership.")
  }
  if (any(
    lineage$rows$disposition == "excluded" &
      (!nzchar(lineage$rows$rule_id) | !nzchar(lineage$rows$reason))
  )) {
    stop("Excluded observations require a rule and reason.")
  }
  invisible(TRUE)
}

validate_event_membership <- function(
    event_lineage,
    obs_events,
    lineage) {
  validate_event_lineage(event_lineage, lineage)
  mapping <- lineage$observation_map
  source_matches <- match(obs_events$index, mapping$internal_index)
  if (anyNA(source_matches)) {
    stop("Current event rows have no source-row mapping.")
  }
  current <- data.frame(
    event_id = obs_events$event_id,
    source_row_id = mapping$source_row_id[source_matches],
    stringsAsFactors = FALSE
  )
  lineage_fields <- intersect(
    c("physical_location_id", "deployment_id"),
    names(event_lineage$memberships)
  )
  if ("physical_location_id" %in% lineage_fields) {
    current$physical_location_id <- if (
      "physical_location_id" %in% names(obs_events)
    ) {
      as.character(obs_events$physical_location_id)
    } else {
      as.character(obs_events$site)
    }
  }
  if ("deployment_id" %in% lineage_fields) {
    current$deployment_id <- if ("deployment_id" %in% names(obs_events)) {
      as.character(obs_events$deployment_id)
    } else {
      rep(NA_character_, nrow(obs_events))
    }
  }
  current <- current[
    order(current$event_id, current$source_row_id, method = "radix"),
    ,
    drop = FALSE
  ]
  recorded <- event_lineage$memberships[c(
    "event_id", "source_row_id", lineage_fields
  )]
  recorded <- recorded[
    order(recorded$event_id, recorded$source_row_id, method = "radix"),
    ,
    drop = FALSE
  ]
  rownames(current) <- NULL
  rownames(recorded) <- NULL
  if (!identical(current, recorded)) {
    stop("Current operational events and recorded membership disagree.")
  }
  invisible(TRUE)
}
