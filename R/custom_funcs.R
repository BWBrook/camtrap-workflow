# custom_funcs.R
# Helper functions for the Judbury camera-trap workflow

source(here::here("R", "time_utils.R"), local = TRUE)

#' Read a JC CSV and return a clean tibble
#' @param path Relative file path (character)
#' @return tibble with snake-case names
#' @export
read_jc_csv <- function(path) {
  import::from("readr",   read_csv)
  import::from("janitor", clean_names)

  read_csv(path, show_col_types = FALSE) |>
    clean_names()
}

#' Verify that every observation site exists in the site table
#' Stops the pipeline if mismatches are found.
#' @param obs  tibble of observations
#' @param site tibble of site metadata
#' @return TRUE invisibly
#' @export
check_keys <- function(obs, site) {
  import::from("dplyr", pull)

  missing_sites <- setdiff(unique(obs$site), pull(site, site))
  if (length(missing_sites) > 0L) {
    stop(
      "QC failure: sites in obs missing from jc_site.csv: ",
      paste(missing_sites, collapse = ", ")
    )
  }
  invisible(TRUE)
}

#' Validate effort table: error if any NA values are present
#' @param op tibble of camera effort (0 / 1 values)
#' @return TRUE invisibly
#' @export
validate_effort <- function(op) {
  import::from("dplyr", across, summarise, select, everything)

  na_summary <- op |>
    select(-date) |>
    summarise(across(everything(), \(x) sum(is.na(x)))) |>
    unlist()

  total_na <- sum(na_summary)
  if (total_na > 0L) {
    stop("QC failure: effort table contains ", total_na, " NA values.")
  }
  invisible(TRUE)
}

#' Pivot daily effort table to long format
#' @param op  tibble (date + camera columns)
#' @return tibble with columns: date, site, on_off (0/1)
#' @export
pivot_op_long <- function(op) {
  import::from("tidyr",      pivot_longer)
  import::from("dplyr",      rename, mutate)
  import::from("lubridate",  as_date)

  op |>
    mutate(date = as_date(date, format = "%d/%m/%Y")) |>  # ← parse once
    pivot_longer(-date, names_to = "site", values_to = "on_off") |>
    rename(trap_date = date)
}

#' Summarise trap nights per site
#' @param op_long tibble from pivot_op_long()
#' @return tibble: site, trap_nights
#' @export
calc_trap_nights <- function(op_long) {
  import::from("dplyr", group_by, summarise)

  op_long |>
    group_by(site) |>
    summarise(trap_nights = sum(on_off), .groups = "drop")
}

#' Filter observations to periods when camera was on
#' @param obs tibble of detections
#' @param op_long tibble with on/off per date-site
#' @return filtered tibble
#' @export
filter_obs_by_effort <- function(obs, op_long) {
  import::from("dplyr",      left_join, filter, select, mutate)
  import::from("lubridate",  as_date)   # already in use

  obs |>
    mutate(
      trap_date = as_date(datetime, format = "%d/%m/%Y %H:%M:%S")
    ) |>
    left_join(op_long, by = c("site", "trap_date")) |>
    filter(on_off == 1) |>
    select(-on_off)
}

#' Tag independent camera-trap events
#' @param obs        tibble from obs_filtered
#' @param threshold  gap (minutes) that separates events
#' @return obs with new columns: dt (POSIXct) and event_id (character)
#' @export
define_events <- function(obs, threshold = 15, tz = "Australia/Hobart", fixed_offset_hours = NULL) {  # 15-min gap
  import::from("dplyr", arrange, group_by, mutate, lag, ungroup, filter, if_else, select)

  obs |>
    mutate(
      dt = parse_datetime_local(datetime, tz = tz, fixed_offset_hours = fixed_offset_hours, quiet = TRUE)
    ) |>
    filter(!is.na(dt)) |>
    arrange(site, species, dt) |>
    group_by(site, species) |>
    mutate(
      gap_min  = as.numeric(difftime(dt, lag(dt), units = "mins")),
      new_evt  = if_else(is.na(gap_min) | gap_min > threshold, 1L, 0L),
      event_id = paste(site, species, cumsum(new_evt), sep = "_")
    ) |>
    ungroup() |>
    select(-gap_min, -new_evt)
}

#' Summarise events per day–site–species
#' @param obs_events tibble from define_events()
#' @return tibble with columns site, species, date, events
#' @export
summarise_events <- function(obs_events) {
  import::from("dplyr", group_by, summarise, n_distinct)
  import::from("lubridate", as_date)

  obs_events |>
    group_by(site, species, date = as_date(dt)) |>
    summarise(events = n_distinct(event_id), .groups = "drop")
}

compute_operational_event_detection_rate <- function( # nolint: object_length_linter.
    events_per_day,
    trap_nights) {
  import::from("dplyr", group_by, left_join, mutate, select, summarise)

  events_per_day |>
    group_by(site, species) |>
    summarise(event_count = sum(events), .groups = "drop") |>
    left_join(trap_nights, by = "site") |>
    mutate(
      events_per_100_active_days = ifelse(
        trap_nights > 0,
        100 * event_count / trap_nights,
        NA_real_
      )
    ) |>
    select(
      physical_location_id = site, species, event_count,
      confirmed_active_days = trap_nights, events_per_100_active_days
    )
}

#' Coarse day/night activity proportions
#'
#' Classifies each independent event as ‘day’ (flash == 0) or ‘night’
#' (flash == 1) and, optionally, assigns it to a climatological season
#' (DJF, MAM, JJA, SON). Returns counts and proportions.
#'
#' @param obs_events Tibble with one row per independent event and columns
#'   `site`, `species`, `flash`, `dt` (POSIXct).
#' @param method Diel classification method: `flash` or `clock`.
#' @param day_start_hour Hour (0-23) marking start of day for `clock` method.
#' @param day_end_hour Hour (0-23) marking end of day for `clock` method.
#'
#' @return Tibble with physical location, species, period, count, and proportion.
#'
#' @export
calc_diel <- function(
  obs_events,
  method = "flash",
  day_start_hour = 6,
  day_end_hour = 18
) {
  import::from(
    "dplyr", across, distinct, group_by, mutate, n, summarise, ungroup
  )
  import::from("lubridate", hour)

  if (!method %in% c("flash", "clock")) {
    stop("calc_diel method must be 'flash' or 'clock'.")
  }
  required <- c("event_id", "site", "species", "flash", "dt")
  if (!is.data.frame(obs_events) || !all(required %in% names(obs_events))) {
    stop("Coarse day-night output requires identified independent events.")
  }

  df <- obs_events |>
    distinct(event_id, .keep_all = TRUE) |>
    mutate(
      period = if (method == "flash") {
        ifelse(flash == 1, "night", "day")
      } else {
        ifelse(
          hour(dt) >= day_start_hour & hour(dt) < day_end_hour,
          "day",
          "night"
        )
      }
    )

  df |>
    group_by(site, species, period) |>
    summarise(n = n(), .groups = "drop") |>
    group_by(across(-c(n, period))) |>
    mutate(prop = n / sum(n)) |>
    ungroup() |>
    dplyr::rename(
      physical_location_id = site,
      event_count = n,
      event_proportion = prop
    )
}

#' Build a species-accumulation curve
#'
#' Converts the events table to a presence-absence matrix and runs the exact
#' expected species-accumulation calculation in `vegan::specaccum()`.
#'
#' @param events_per_day Tibble of daily independent events.
#' @return Tibble with columns `sites`, `richness`, and `se`
#'   (standard error of richness).
#'
#' @export
compute_species_accumulation <- function(events_per_day) {
  import::from("vegan", specaccum)
  import::from("dplyr", distinct, mutate)
  import::from("tidyr", pivot_wider)
  import::from("tibble", column_to_rownames, tibble)

  # one row per site × species
  inc_mat <- events_per_day |>
    distinct(site, species) |>
    mutate(pres = 1L) |>
    pivot_wider(names_from = species, values_from = pres, values_fill = 0) |>
    column_to_rownames("site") |>
    as.matrix()

  acc <- suppressWarnings(specaccum(inc_mat, method = "exact"))

  tibble(
    sites    = acc$sites,
    richness = acc$richness,
    se       = acc$sd
  )
}

#' Plot and save the species-accumulation curve
#'
#' Generates a `ggplot2` figure from the species-accumulation data and
#' writes it to disk.
#'
#' @param df       Output of `compute_species_accumulation()`.
#' @param out_path File path (character) where the graphic is saved.
#'
#' @return Invisibly returns `out_path` for use in `targets` with
#'   `format = "file"`.
#'
#' @export
plot_species_accumulation <- function(df, out_path) {
  import::from("ggplot2", ggplot, aes, geom_line,
               geom_ribbon, theme_minimal, labs, ggsave)

  # ensure directory exists
  dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)

  p <- ggplot(df, aes(sites, richness)) +
    geom_ribbon(aes(ymin = richness - se, ymax = richness + se), alpha = 0.2) +
    geom_line() +
    theme_minimal() +
    labs(
      x = "Number of physical locations",
      y = "Expected accumulated species"
    )

  ggsave(out_path, p, width = 6, height = 4, dpi = 300)
  out_path
}
