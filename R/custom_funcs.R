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
  import::from(dplyr, group_by, summarise)
  
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
      # alternatively: trap_date = date(lubridate::dmy_hms(datetime))
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
define_events <- function(obs, threshold = 15) {  # 15-min gap
  import::from("dplyr", arrange, group_by, mutate, lag, ungroup, filter)
  import::from("lubridate", dmy_hms)

  obs |>
    mutate(
      dt = dmy_hms(datetime, tz = "Etc/GMT-10", quiet = TRUE)  # ← fixed offset
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
