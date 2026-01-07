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

#' Compute occasion-length sensitivity metrics
#'
#' @param op_long Effort table in long form.
#' @param events_per_day Events per day table.
#' @param species_list Species codes to include.
#' @param occasion_lengths Vector of occasion lengths (days).
#' @param start_date Optional start date (YYYY-MM-DD).
#' @return Tibble with naive occupancy and detection rates by occasion length.
#' @export
compute_occasion_length_sens <- function(op_long,
                                         events_per_day,
                                         species_list,
                                         occasion_lengths,
                                         start_date = NULL) {
  import::from("dplyr", group_by, summarise, bind_rows, left_join)
  import::from("tibble", tibble)

  occasion_lengths <- sort(unique(as.numeric(occasion_lengths)))
  if (length(occasion_lengths) == 0) {
    return(tibble())
  }

  results <- lapply(occasion_lengths, function(length_days) {
    history <- build_detection_history(
      op_long,
      events_per_day,
      species_list = species_list,
      occasion_length_days = length_days,
      start_date = start_date
    )

    naive <- history |>
      group_by(site, species) |>
      summarise(detected_any = max(detected), .groups = "drop") |>
      group_by(species) |>
      summarise(naive_occupancy = mean(detected_any), .groups = "drop")

    det_rate <- history |>
      group_by(species) |>
      summarise(detection_rate = mean(detected), .groups = "drop")

    left_join(naive, det_rate, by = "species") |>
      mutate(occasion_length_days = length_days)
  })

  bind_rows(results)
}

#' Plot occasion-length sensitivity
#'
#' @param sensitivity_tbl Output of `compute_occasion_length_sens()`.
#' @param out_path File path where the figure is saved.
#' @return `out_path` invisibly.
#' @export
plot_occasion_length_sens <- function(sensitivity_tbl, out_path) {
  import::from("dplyr", arrange)
  import::from("ggplot2", ggplot, aes, geom_line, geom_point, theme_minimal, labs, ggsave)

  dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)

  plot_data <- sensitivity_tbl |>
    arrange(occasion_length_days)

  p <- ggplot(plot_data, aes(x = occasion_length_days, y = naive_occupancy, color = species)) +
    geom_line() +
    geom_point() +
    theme_minimal() +
    labs(x = "Occasion length (days)", y = "Naive occupancy")

  ggsave(out_path, p, width = 6, height = 4, dpi = 300)
  out_path
}
