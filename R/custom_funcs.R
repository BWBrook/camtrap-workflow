# custom_funcs.R
# Helper functions for the Judbury camera-trap workflow

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
define_events <- function(obs, threshold = 15, tz = "Australia/Hobart") {  # 15-min gap
  import::from("dplyr", arrange, group_by, mutate, lag, ungroup, filter, if_else, select)
  import::from("lubridate", dmy_hms)

  obs |>
    mutate(
      dt = dmy_hms(datetime, tz = tz, quiet = TRUE)
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

#' Calculate relative‐abundance indices (RAI)
#'
#' Derives RAI at two resolutions: per camera‐site × species and site‐pooled
#' across all cameras. RAI is defined as the number of independent events
#' divided by trap-night effort.
#'
#' @param events_per_day Tibble with columns `site`, `species`, `date`, `events`
#'   (output of `summarise_events()`).
#' @param trap_nights    Tibble with columns `site`, `trap_nights`
#'   (output of `calc_trap_nights()`).
#'
#' @return A list with two tibbles:
#' * `$site`    — one row per `site` × `species`, columns `rai`.
#' * `$pooled` — one row per `species`, pooled across sites, column `rai`.
#'
#' @export
calc_rai <- function(events_per_day, trap_nights) {
  import::from("dplyr", group_by, summarise, left_join, mutate, across, select)

  rai_site <- events_per_day |>
    group_by(site, species) |>
    summarise(events = sum(events), .groups = "drop") |>
    left_join(trap_nights, by = "site") |>
    mutate(rai = events / trap_nights) |>
    select(site, species, rai)

  rai_species <- rai_site |>
    group_by(species) |>
    summarise(rai = sum(rai), .groups = "drop")

  list(site = rai_site, pooled = rai_species)
}

#' Proportion of camera-active days with an event
#'
#' Computes, for each species at each camera site, the fraction of days
#' on which at least one independent detection occurred while the camera
#' was operational.
#'
#' @param events_per_day Tibble of independent events aggregated by day
#'   (see `summarise_events()`).
#' @param trap_nights    Tibble of trap-night effort per site.
#'
#' @return A list with two tibbles analogous to `calc_rai()`:
#' * `$site`    — proportion per site × species.
#' * `$pooled` — mean proportion across sites for each species.
#'
#' @export
calc_prop_days <- function(events_per_day, trap_nights) {
  import::from("dplyr", group_by, summarise, left_join, mutate, select)

  days_with_event <- events_per_day |>
    group_by(site, species) |>
    summarise(days_event = n(), .groups = "drop")

  prop_site <- days_with_event |>
    left_join(trap_nights, by = "site") |>
    mutate(prop_days = days_event / trap_nights) |>
    select(site, species, prop_days)

  prop_species <- prop_site |>
    group_by(species) |>
    summarise(prop_days = mean(prop_days), .groups = "drop")

  list(site = prop_site, pooled = prop_species)
}

#' Day–night (and seasonal) activity proportions
#'
#' Classifies each independent event as ‘day’ (flash == 0) or ‘night’
#' (flash == 1) and, optionally, assigns it to a climatological season
#' (DJF, MAM, JJA, SON). Returns counts and proportions.
#'
#' @param obs_events Tibble with one row per independent event and columns
#'   `site`, `species`, `flash`, `dt` (POSIXct).
#' @param by_season  Logical. If `TRUE` results are split by season; if
#'   `FALSE` proportions are computed over the whole year.
#'
#' @return Tibble with grouping columns (`site`, `species`, and optionally
#'   `season`, `period`) plus `n` (count) and `prop` (proportion).
#'
#' @export
calc_diel <- function(obs_events, by_season = FALSE) {
  import::from("dplyr", mutate, group_by, summarise, ungroup, across, case_when, n)
  import::from("lubridate", month)

  df <- obs_events |>
    mutate(
      period = ifelse(flash == 1, "night", "day"),
      season = case_when(
        month(dt) %in% c(12, 1, 2)  ~ "DJF",
        month(dt) %in% c(3, 4, 5)   ~ "MAM",
        month(dt) %in% c(6, 7, 8)   ~ "JJA",
        TRUE                        ~ "SON"
      )
    )

  if (by_season) {
    df <- group_by(df, site, species, season, period)
  } else {
    df <- group_by(df, site, species, period)
  }

  df |>
    summarise(n = n(), .groups = "drop") |>
    group_by(across(-c(n, period))) |>
    mutate(prop = n / sum(n)) |>
    ungroup()
}

#' Build a species-accumulation curve
#'
#' Converts the events table to a presence–absence matrix and runs
#' `vegan::specaccum()` with random permutations.
#'
#' @param events_per_day Tibble of daily independent events.
#' @param permutations   Integer, number of random permutations.
#'
#' @return Tibble with columns `sites`, `richness`, and `se`
#'   (standard error of richness).
#'
#' @export
build_rarefaction <- function(events_per_day, permutations = 100) {
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

  acc <- specaccum(inc_mat, method = "random", permutations = permutations)

  tibble(
    sites    = acc$sites,
    richness = acc$richness,
    se       = acc$sd
  )
}

#' Plot and save the rarefaction curve
#'
#' Generates a `ggplot2` figure from the species-accumulation data and
#' writes it to disk.
#'
#' @param df       Output of `build_rarefaction()`.
#' @param out_path File path (character) where the graphic is saved.
#'
#' @return Invisibly returns `out_path` for use in `targets` with
#'   `format = "file"`.
#'
#' @export
plot_rarefaction <- function(df, out_path) {
  import::from("ggplot2", ggplot, aes, geom_line,
               geom_ribbon, theme_minimal, labs, ggsave)

  # ensure directory exists
  dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)

  p <- ggplot(df, aes(sites, richness)) +
    geom_ribbon(aes(ymin = richness - se, ymax = richness + se), alpha = 0.2) +
    geom_line() +
    theme_minimal() +
    labs(x = "Number of camera sites", y = "Species richness")

  ggsave(out_path, p, width = 6, height = 4, dpi = 300)
  out_path
}
