# detection_history.R

#' Build detection history (long format) from effort and events
#'
#' @param op_long Effort table in long form with columns trap_date, site, on_off.
#' @param events_per_day Tibble with columns site, species, date, events.
#' @param species_list Character vector of species codes to include.
#' @param occasion_length_days Integer length of each occasion (days).
#' @param start_date Optional start date (Date or YYYY-MM-DD string).
#' @param end_date Optional end date (Date or YYYY-MM-DD string).
#' @return Tibble with detection history in long format.
#' @export
build_detection_history <- function(op_long,
                                    events_per_day,
                                    species_list,
                                    occasion_length_days = 7,
                                    start_date = NULL,
                                    end_date = NULL) {
  import::from("dplyr", mutate, group_by, summarise, ungroup, left_join, arrange, distinct, n)
  import::from("tidyr", expand_grid)
  import::from("lubridate", as_date)

  if (is.null(start_date)) {
    start_date <- min(op_long$trap_date)
  } else {
    start_date <- as_date(start_date)
  }

  if (is.null(end_date)) {
    end_date <- max(op_long$trap_date)
  } else {
    end_date <- as_date(end_date)
  }

  if (is.na(start_date) || is.na(end_date)) {
    stop("Detection history start/end dates could not be determined.")
  }

  if (end_date < start_date) {
    stop("Detection history end_date must be on or after start_date.")
  }

  if (!is.numeric(occasion_length_days) || length(occasion_length_days) != 1 || occasion_length_days < 1) {
    stop("occasion_length_days must be a positive integer.")
  }

  occasion_index <- function(date) {
    floor(as.numeric(date - start_date) / occasion_length_days) + 1L
  }

  op_by_occ <- op_long |>
    mutate(occasion = occasion_index(trap_date)) |>
    group_by(site, occasion) |>
    summarise(
      effort_days = sum(on_off),
      total_days = n(),
      effort = ifelse(effort_days > 0, 1L, 0L),
      .groups = "drop"
    )

  det_by_occ <- events_per_day |>
    mutate(
      date = as_date(date),
      occasion = occasion_index(date),
      detected = ifelse(events > 0, 1L, 0L)
    ) |>
    group_by(site, species, occasion) |>
    summarise(detected = max(detected), .groups = "drop")

  sites <- distinct(op_long, site)
  occasions <- distinct(op_by_occ, occasion)

  grid <- expand_grid(
    sites,
    species = species_list,
    occasions
  )

  history <- grid |>
    left_join(op_by_occ, by = c("site", "occasion")) |>
    left_join(det_by_occ, by = c("site", "species", "occasion")) |>
    mutate(
      detected = ifelse(is.na(detected), 0L, detected),
      effort = ifelse(is.na(effort), 0L, effort),
      effort_days = ifelse(is.na(effort_days), 0L, effort_days),
      total_days = ifelse(is.na(total_days), 0L, total_days),
      occasion_start = start_date + (occasion - 1) * occasion_length_days,
      occasion_end = occasion_start + occasion_length_days
    ) |>
    arrange(site, species, occasion)

  history
}
