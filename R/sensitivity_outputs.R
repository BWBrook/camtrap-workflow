# sensitivity_outputs.R

#' Compute event-threshold sensitivity metrics
#'
#' @param obs_filtered Observations filtered to active effort days.
#' @param trap_nights Tibble with trap-night totals per site.
#' @param thresholds Numeric vector of gap thresholds (minutes).
#' @param tz Timezone for datetime parsing.
#' @return Tibble with event totals per threshold.
#' @export
compute_event_threshold_sens <- function(obs_filtered, trap_nights, thresholds, tz = "Australia/Hobart") {
  import::from("dplyr", mutate, summarise, arrange)
  import::from("tibble", tibble)

  total_effort <- sum(trap_nights$trap_nights)
  thresholds <- sort(unique(as.numeric(thresholds)))

  if (length(thresholds) == 0) {
    return(tibble())
  }

  results <- lapply(thresholds, function(threshold) {
    obs_events <- define_events(obs_filtered, threshold = threshold, tz = tz)
    events_per_day <- summarise_events(obs_events)
    total_events <- sum(events_per_day$events)

    tibble(
      threshold_minutes = threshold,
      total_events = total_events,
      events_per_trap_night = ifelse(total_effort > 0, total_events / total_effort, NA_real_)
    )
  })

  do.call(rbind, results) |>
    arrange(threshold_minutes)
}

#' Plot event-threshold sensitivity curve
#'
#' @param sensitivity_tbl Output of `compute_event_threshold_sens()`.
#' @param out_path File path where the figure is saved.
#' @return `out_path` invisibly.
#' @export
plot_event_threshold_sens <- function(sensitivity_tbl, out_path) {
  import::from("ggplot2", ggplot, aes, geom_line, geom_point, theme_minimal, labs, ggsave)

  dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)

  p <- ggplot(sensitivity_tbl, aes(x = threshold_minutes, y = events_per_trap_night)) +
    geom_line() +
    geom_point() +
    theme_minimal() +
    labs(x = "Event threshold (minutes)", y = "Events per trap night")

  ggsave(out_path, p, width = 6, height = 4, dpi = 300)
  out_path
}
