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
  import::from("ggplot2", ggplot, aes, geom_histogram, theme_minimal, labs, ggsave)
  import::from("dplyr", filter)

  dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)

  plot_data <- event_spacing |>
    filter(!is.na(gap_hours))

  p <- ggplot(plot_data, aes(x = gap_hours)) +
    geom_histogram(bins = 30) +
    theme_minimal() +
    labs(x = "Gap between events (hours)", y = "Count")

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
