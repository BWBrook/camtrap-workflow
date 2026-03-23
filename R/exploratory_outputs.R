# exploratory_outputs.R

#' Collapse event records to one row per independent event
#'
#' @param obs_events Observation-level event table from `define_events()`.
#' @param method Diel classification method: `flash` or `clock`.
#' @param day_start_hour Hour (0-23) marking the start of day for `clock`.
#' @param day_end_hour Hour (0-23) marking the end of day for `clock`.
#' @return Tibble with one row per `event_id`.
#' @export
collapse_event_records <- function(
  obs_events,
  method = "flash",
  day_start_hour = 6,
  day_end_hour = 18
) {
  import::from("dplyr", arrange, first, group_by, mutate, summarise)
  import::from("lubridate", hour)

  if (!method %in% c("flash", "clock")) {
    stop("collapse_event_records method must be 'flash' or 'clock'.")
  }

  obs_events |>
    arrange(site, species, event_id, dt) |>
    group_by(site, species, event_id) |>
    summarise(
      dt = first(dt),
      flash = first(flash),
      .groups = "drop"
    ) |>
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
}

#' Compute a consolidated species summary table
#'
#' @param obs_filtered Effort-filtered observations table.
#' @param obs_events Observation-level event table from `define_events()`.
#' @param events_per_day Independent event counts by site/species/day.
#' @param trap_nights Trap-night totals by site.
#' @param total_sites Total number of sites in the run.
#' @param method Diel classification method: `flash` or `clock`.
#' @param day_start_hour Hour (0-23) marking the start of day for `clock`.
#' @param day_end_hour Hour (0-23) marking the end of day for `clock`.
#' @return Tibble with one row per species.
#' @export
compute_species_summary <- function(
  obs_filtered,
  obs_events,
  events_per_day,
  trap_nights,
  total_sites,
  method = "flash",
  day_start_hour = 6,
  day_end_hour = 18
) {
  import::from("dplyr", across, arrange, coalesce, desc, group_by, left_join, mutate, select, summarise)
  import::from("tibble", tibble)

  empty_result <- tibble(
    species = character(),
    n_sites_detected = integer(),
    prop_sites_detected = numeric(),
    n_independent_events = integer(),
    rai = numeric(),
    prop_active_days_detected = numeric(),
    prop_night_events = numeric(),
    mean_group_size = numeric(),
    max_group_size = numeric()
  )

  species_values <- sort(unique(c(obs_filtered$species, events_per_day$species)))
  species_values <- species_values[!is.na(species_values)]

  if (length(species_values) == 0) {
    return(empty_result)
  }

  species_tbl <- tibble(species = species_values)
  total_trap_nights <- sum(trap_nights$trap_nights, na.rm = TRUE)

  event_summary <- events_per_day |>
    group_by(species) |>
    summarise(
      n_sites_detected = dplyr::n_distinct(site),
      n_independent_events = sum(events, na.rm = TRUE),
      detected_active_days = dplyr::n(),
      .groups = "drop"
    ) |>
    mutate(
      prop_sites_detected = if (isTRUE(total_sites > 0)) {
        n_sites_detected / total_sites
      } else {
        NA_real_
      },
      rai = if (isTRUE(total_trap_nights > 0)) {
        n_independent_events / total_trap_nights
      } else {
        NA_real_
      },
      prop_active_days_detected = if (isTRUE(total_trap_nights > 0)) {
        detected_active_days / total_trap_nights
      } else {
        NA_real_
      }
    )

  event_level <- collapse_event_records(
    obs_events,
    method = method,
    day_start_hour = day_start_hour,
    day_end_hour = day_end_hour
  ) |>
    group_by(species) |>
    summarise(
      prop_night_events = mean(period == "night"),
      .groups = "drop"
    )

  image_fallback <- if ("index" %in% names(obs_filtered)) {
    paste0("index_", obs_filtered$index)
  } else {
    paste0("row_", seq_len(nrow(obs_filtered)))
  }

  image_counts <- obs_filtered |>
    mutate(
      count_clean = ifelse(is.na(count) | count < 1, 1, count),
      image_key = dplyr::coalesce(as.character(imageid), image_fallback)
    ) |>
    group_by(species, image_key) |>
    summarise(image_count = sum(count_clean), .groups = "drop") |>
    group_by(species) |>
    summarise(
      mean_group_size = mean(image_count),
      max_group_size = max(image_count),
      .groups = "drop"
    )

  species_tbl |>
    left_join(event_summary, by = "species") |>
    left_join(event_level, by = "species") |>
    left_join(image_counts, by = "species") |>
    mutate(
      across(
        c(n_sites_detected, n_independent_events, detected_active_days),
        ~ coalesce(.x, 0)
      ),
      prop_sites_detected = coalesce(prop_sites_detected, 0),
      rai = coalesce(rai, 0),
      prop_active_days_detected = coalesce(prop_active_days_detected, 0)
    ) |>
    select(
      species,
      n_sites_detected,
      prop_sites_detected,
      n_independent_events,
      rai,
      prop_active_days_detected,
      prop_night_events,
      mean_group_size,
      max_group_size
    ) |>
    arrange(desc(prop_sites_detected), desc(rai), species)
}

#' Compute operating-days-to-first-detection summaries
#'
#' @param op_long Long effort table from `pivot_op_long()`.
#' @param events_per_day Independent event counts by site/species/day.
#' @return Tibble with one row per detected site x species.
#' @export
compute_first_detection_wait <- function(op_long, events_per_day) {
  import::from("dplyr", arrange, distinct, filter, group_by, inner_join, summarise)
  import::from("tibble", tibble)

  empty_result <- tibble(
    site = character(),
    species = character(),
    first_active_date = as.Date(character()),
    first_detection_date = as.Date(character()),
    wait_days = integer()
  )

  active_days <- op_long |>
    filter(on_off == 1) |>
    distinct(site, trap_date)

  if (nrow(active_days) == 0 || nrow(events_per_day) == 0) {
    return(empty_result)
  }

  first_active <- active_days |>
    group_by(site) |>
    summarise(first_active_date = min(trap_date), .groups = "drop")

  first_detection <- events_per_day |>
    group_by(site, species) |>
    summarise(first_detection_date = min(date), .groups = "drop") |>
    inner_join(first_active, by = "site")

  if (nrow(first_detection) == 0) {
    return(empty_result)
  }

  active_days |>
    inner_join(first_detection, by = "site", relationship = "many-to-many") |>
    filter(
      trap_date >= first_active_date,
      trap_date <= first_detection_date
    ) |>
    group_by(site, species, first_active_date, first_detection_date) |>
    summarise(wait_days = dplyr::n(), .groups = "drop") |>
    arrange(site, species)
}

#' Summarise first-detection wait times by species
#'
#' @param wait_tbl Site-level wait times from `compute_first_detection_wait()`.
#' @return Tibble with one row per species.
#' @export
summarise_first_detection_wait <- function(wait_tbl) {
  import::from("dplyr", arrange, desc, group_by, summarise)
  import::from("tibble", tibble)

  if (nrow(wait_tbl) == 0) {
    return(tibble(
      species = character(),
      n_sites = integer(),
      median_wait_days = numeric(),
      mean_wait_days = numeric(),
      min_wait_days = numeric(),
      max_wait_days = numeric()
    ))
  }

  wait_tbl |>
    group_by(species) |>
    summarise(
      n_sites = dplyr::n(),
      median_wait_days = stats::median(wait_days),
      mean_wait_days = mean(wait_days),
      min_wait_days = min(wait_days),
      max_wait_days = max(wait_days),
      .groups = "drop"
    ) |>
    arrange(desc(n_sites), median_wait_days, species)
}

#' Find images containing more than one species
#'
#' @param obs_filtered Effort-filtered observations table.
#' @return Tibble with one row per multi-species image.
#' @export
compute_multi_species_images <- function(obs_filtered) {
  import::from("dplyr", arrange, distinct, filter, first, group_by, mutate, summarise)
  import::from("tibble", tibble)

  if (!"imageid" %in% names(obs_filtered)) {
    stop("compute_multi_species_images requires an 'imageid' column.")
  }

  if (nrow(obs_filtered) == 0) {
    return(tibble(
      imageid = integer(),
      site = character(),
      datetime = character(),
      n_species = integer(),
      species_list = character()
    ))
  }

  obs_filtered |>
    filter(!is.na(imageid)) |>
    group_by(imageid) |>
    summarise(
      site = first(site),
      datetime = first(datetime),
      n_species = dplyr::n_distinct(species),
      species_list = paste(sort(unique(species)), collapse = "; "),
      .groups = "drop"
    ) |>
    filter(n_species > 1) |>
    arrange(desc(n_species), imageid)
}

#' Count co-occurring species pairs across multi-species images
#'
#' @param multi_species_images Output of `compute_multi_species_images()`.
#' @return Tibble with one row per species pair.
#' @export
compute_multi_species_pairs <- function(multi_species_images) {
  import::from("dplyr", arrange, group_by, summarise)
  import::from("tibble", tibble)

  if (nrow(multi_species_images) == 0) {
    return(tibble(
      species_1 = character(),
      species_2 = character(),
      n_images = integer()
    ))
  }

  pair_rows <- lapply(seq_len(nrow(multi_species_images)), function(i) {
    species <- strsplit(multi_species_images$species_list[[i]], "; ", fixed = TRUE)[[1]]
    species <- sort(unique(species))

    if (length(species) < 2) {
      return(NULL)
    }

    combos <- utils::combn(species, 2)
    tibble(
      species_1 = combos[1, ],
      species_2 = combos[2, ],
      imageid = multi_species_images$imageid[[i]]
    )
  })

  pair_rows <- Filter(Negate(is.null), pair_rows)
  if (length(pair_rows) == 0) {
    return(tibble(
      species_1 = character(),
      species_2 = character(),
      n_images = integer()
    ))
  }

  dplyr::bind_rows(pair_rows) |>
    group_by(species_1, species_2) |>
    summarise(n_images = dplyr::n_distinct(imageid), .groups = "drop") |>
    arrange(desc(n_images), species_1, species_2)
}
