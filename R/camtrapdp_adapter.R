# camtrapdp_adapter.R

#' Read a Camtrap DP dataset (local path or URL)
#'
#' @param path Path or URL to a Camtrap DP `datapackage.json`.
#' @return camtrapdp object.
#' @export
read_camtrapdp_dataset <- function(path) {
  import::from("camtrapdp", read_camtrapdp)

  if (is.null(path) || !nzchar(path)) {
    stop("camtrapdp path must be provided when input_mode = 'camtrapdp'.")
  }

  read_camtrapdp(path)
}

#' Build effort matrix (op table) from Camtrap DP deployments
#'
#' @param deployments Camtrap DP deployments table.
#' @return Tibble in wide format: date + one column per deploymentID (0/1).
build_effort_from_deployments <- function(deployments) {
  import::from("dplyr", mutate, select, left_join)
  import::from("tidyr", pivot_wider, expand_grid)
  import::from("tibble", tibble)
  import::from("lubridate", as_date)
  import::from("purrr", map2_dfr)

  dep <- deployments |>
    mutate(
      start_date = as_date(deploymentStart),
      end_date = as_date(deploymentEnd)
    )

  dep$end_date[is.na(dep$end_date) & !is.na(dep$start_date)] <-
    dep$start_date[is.na(dep$end_date) & !is.na(dep$start_date)]
  dep$start_date[is.na(dep$start_date) & !is.na(dep$end_date)] <-
    dep$end_date[is.na(dep$start_date) & !is.na(dep$end_date)]

  if (all(is.na(dep$start_date))) {
    stop("Camtrap DP deployments missing deploymentStart dates.")
  }

  if (any(is.na(dep$start_date)) || any(is.na(dep$end_date))) {
    warning("Some deployments missing start/end dates; dropping from effort table.")
    dep <- dep[!is.na(dep$start_date) & !is.na(dep$end_date), , drop = FALSE]
  }

  all_dates <- seq(min(dep$start_date, na.rm = TRUE), max(dep$end_date, na.rm = TRUE), by = "day")

  effort_long <- map2_dfr(dep$deploymentID, seq_len(nrow(dep)), function(dep_id, idx) {
    start <- dep$start_date[idx]
    end <- dep$end_date[idx]
    if (is.na(start) || is.na(end)) {
      return(tibble(date = as.Date(character()), site = character(), on_off = integer()))
    }
    tibble(date = seq(start, end, by = "day"), site = dep_id, on_off = 1L)
  })

  grid <- expand_grid(date = all_dates, site = dep$deploymentID)
  effort_long <- left_join(grid, effort_long, by = c("date", "site")) |>
    mutate(on_off = ifelse(is.na(on_off), 0L, on_off))

  effort_wide <- effort_long |>
    pivot_wider(names_from = site, values_from = on_off)

  effort_wide$date <- format(effort_wide$date, "%d/%m/%Y")
  effort_wide
}

#' Convert Camtrap DP dataset into internal four-table contract
#'
#' @param dp Camtrap DP object returned by `read_camtrapdp()`.
#' @param tz Timezone for datetime formatting.
#' @return List with `site`, `taxa`, `op`, and `obs` tibbles.
#' @export
camtrapdp_to_internal <- function(dp, tz = "UTC") {
  import::from("dplyr", mutate, select, distinct, left_join, arrange)
  import::from("stringr", str_to_lower, str_replace_all, str_trim, word)
  import::from("tibble", tibble)
  import::from("lubridate", with_tz)

  deployments <- dp$data$deployments
  observations <- dp$data$observations
  media <- dp$data$media

  if (is.null(deployments) || is.null(observations)) {
    stop("Camtrap DP dataset must include deployments and observations tables.")
  }

  if (is.null(media)) {
    media <- tibble(
      mediaID = character(),
      timestamp = as.POSIXct(character()),
      fileName = character()
    )
  }

  if (!"taxon.vernacularNames.eng" %in% names(observations)) {
    observations$taxon.vernacularNames.eng <- NA_character_
  }

  if (!"scientificName" %in% names(observations)) {
    observations$scientificName <- NA_character_
  }

  make_species_code <- function(name_vec) {
    cleaned <- str_to_lower(str_trim(as.character(name_vec)))
    cleaned <- str_replace_all(cleaned, "[^a-z0-9]+", "_")
    cleaned <- str_replace_all(cleaned, "^_+|_+$", "")
    cleaned[cleaned == "" | is.na(cleaned)] <- "unknown"
    make.unique(cleaned)
  }

  taxa_map <- observations |>
    mutate(
      scientificName = ifelse(is.na(scientificName) | scientificName == "", "unknown", scientificName)
    ) |>
    distinct(scientificName, common = taxon.vernacularNames.eng) |>
    mutate(
      genus = word(scientificName, 1),
      species = word(scientificName, 2),
      short = make.unique(make_species_code(scientificName)),
      class = NA_character_,
      order = NA_character_,
      family = NA_character_,
      diet = NA_character_,
      sec_diet = NA_character_,
      activity = NA_character_,
      habitat = NA_character_,
      status = NA_character_,
      body_size = NA_character_,
      sociality = NA_character_,
      mobility = NA_character_,
      reproductive = NA_character_,
      litter = NA_character_
    )

  observations_clean <- observations |>
    left_join(
      select(media, mediaID, timestamp, fileName),
      by = "mediaID"
    ) |>
    mutate(
      scientificName = ifelse(is.na(scientificName) | scientificName == "", "unknown", scientificName)
    ) |>
    left_join(
      select(taxa_map, scientificName, short),
      by = "scientificName"
    ) |>
    mutate(
      event_time = dplyr::coalesce(eventStart, timestamp),
      event_time = with_tz(event_time, tz),
      datetime = format(event_time, "%d/%m/%Y %H:%M:%S"),
      species = ifelse(is.na(short) | short == "", "unknown", short)
    ) |>
    mutate(
      count = ifelse(is.na(count), 1L, as.integer(round(count))),
      flash = 0L,
      filename = ifelse(!is.na(fileName), fileName, ifelse(!is.na(mediaID), mediaID, observationID)),
      age = as.character(lifeStage),
      sex = as.character(sex)
    ) |>
    arrange(event_time)

  observations_clean$index <- seq_len(nrow(observations_clean))
  observations_clean$imageid <- observations_clean$index

  obs_tbl <- observations_clean |>
    select(
      index, site = deploymentID, datetime, flash, count, species,
      filename, age, sex, imageid
    )

  site_tbl <- deployments |>
    mutate(
      site = deploymentID,
      lat = as.numeric(latitude),
      lon = as.numeric(longitude),
      type = as.character(featureType),
      location = as.character(locationName),
      cover = NA_character_,
      vegclass = NA_character_,
      elevation_m = NA_real_,
      slope_d = NA_real_,
      canopy_h_m = NA_real_,
      ndvi = NA_real_,
      nbr = NA_real_,
      fire_flam = NA_character_,
      fire_sens = NA_character_
    ) |>
    select(
      site, lat, lon, type, location, cover, vegclass, elevation_m,
      slope_d, canopy_h_m, ndvi, nbr, fire_flam, fire_sens
    )

  op_tbl <- build_effort_from_deployments(deployments)

  taxa_tbl <- taxa_map |>
    select(
      class, order, family, genus, species, common, short,
      diet, sec_diet, activity, habitat, status, body_size,
      sociality, mobility, reproductive, litter
    )

  list(site = site_tbl, taxa = taxa_tbl, op = op_tbl, obs = obs_tbl)
}
