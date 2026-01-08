# camtrapdp_export.R

source(here::here("R", "time_utils.R"), local = TRUE)

#' Parse observation datetimes for Camtrap DP export and audit drops
#'
#' @param obs Internal observations table.
#' @param tz Timezone.
#' @param fixed_offset_hours Optional fixed offset in hours.
#' @return List with parsed observations and dropped-row audit.
parse_camtrapdp_datetimes <- function(obs, tz = "UTC", fixed_offset_hours = NULL) {
  import::from("dplyr", mutate, filter)

  parsed <- obs |>
    mutate(event_time = parse_datetime_local(datetime, tz = tz, fixed_offset_hours = fixed_offset_hours, quiet = TRUE))

  dropped <- parsed |>
    filter(is.na(event_time)) |>
    mutate(reason = "unparseable_datetime", timezone = tz)

  parsed <- parsed |>
    filter(!is.na(event_time))

  list(parsed = parsed, dropped = dropped)
}

#' Build Camtrap DP deployments table from internal site/op tables
#'
#' @param site Internal site table.
#' @param op Internal effort table (wide).
#' @param tz Timezone.
#' @param fixed_offset_hours Optional fixed offset in hours.
#' @return Tibble matching Camtrap DP deployments schema.
#' @export
build_camtrapdp_deployments <- function(site, op, tz = "UTC", fixed_offset_hours = NULL) {
  import::from("dplyr", mutate, select, left_join, summarise, group_by)
  op_long <- pivot_op_long(op)

  effort_bounds <- op_long |>
    dplyr::filter(on_off == 1) |>
    group_by(site) |>
    summarise(
      start_date = min(trap_date),
      end_date = max(trap_date),
      .groups = "drop"
    )

  if (nrow(effort_bounds) == 0) {
    stop("Camtrap DP export requires at least one effort day (op == 1).")
  }

  site_export <- site |>
    mutate(
      locationID = site,
      locationName = ifelse(is.na(location) | location == "", site, location)
    ) |>
    left_join(effort_bounds, by = "site")

  if (any(is.na(site_export$lat)) || any(is.na(site_export$lon))) {
    stop("Camtrap DP export requires non-missing site lat/lon.")
  }

  if (any(is.na(site_export$start_date)) || any(is.na(site_export$end_date))) {
    stop("Camtrap DP export requires effort dates for all sites.")
  }

  deployment_start <- parse_date_local(site_export$start_date, tz = tz, fixed_offset_hours = fixed_offset_hours)
  deployment_end <- parse_date_local(site_export$end_date, tz = tz, fixed_offset_hours = fixed_offset_hours) + 86399

  deployments <- dplyr::tibble(
    deploymentID = site_export$site,
    locationID = site_export$locationID,
    locationName = site_export$locationName,
    latitude = site_export$lat,
    longitude = site_export$lon,
    coordinateUncertainty = NA_real_,
    deploymentStart = deployment_start,
    deploymentEnd = deployment_end,
    setupBy = NA_character_,
    cameraID = NA_character_,
    cameraModel = NA_character_,
    cameraDelay = NA_real_,
    cameraHeight = NA_real_,
    cameraDepth = NA_real_,
    cameraTilt = NA_real_,
    cameraHeading = NA_real_,
    detectionDistance = NA_real_,
    timestampIssues = NA,
    baitUse = NA,
    featureType = NA_character_,
    habitat = NA_character_,
    deploymentGroups = NA_character_,
    deploymentTags = NA_character_,
    deploymentComments = NA_character_
  )

  deployments
}

#' Build Camtrap DP media table from internal observations
#'
#' @param obs Internal observations table.
#' @param tz Timezone.
#' @param fixed_offset_hours Optional fixed offset in hours.
#' @return Tibble matching Camtrap DP media schema.
#' @export
build_camtrapdp_media <- function(obs, tz = "UTC", fixed_offset_hours = NULL) {
  import::from("dplyr", mutate, select, distinct)
  import::from("stringr", str_replace_all)

  has_event_time <- "event_time" %in% names(obs)
  media_tbl <- obs |>
    mutate(
      mediaID = as.character(ifelse(!is.na(imageid), imageid, index)),
      deploymentID = site,
      eventID = NA_character_,
      timestamp = if (has_event_time) event_time else parse_datetime_local(
        datetime,
        tz = tz,
        fixed_offset_hours = fixed_offset_hours,
        quiet = TRUE
      ),
      fileName = ifelse(!is.na(filename) & filename != "", basename(filename), paste0(mediaID, ".jpg")),
      fileName = str_replace_all(fileName, "\\s+", "_"),
      filePath = paste0("media/", fileName),
      filePublic = TRUE,
      fileMediatype = "image/jpeg",
      captureMethod = "activityDetection",
      exifData = NA_character_,
      favorite = NA,
      mediaComments = NA_character_
    ) |>
    distinct(mediaID, .keep_all = TRUE) |>
    select(
      mediaID,
      deploymentID,
      eventID,
      captureMethod,
      timestamp,
      filePath,
      filePublic,
      fileName,
      fileMediatype,
      exifData,
      favorite,
      mediaComments
    )

  media_tbl
}

#' Build Camtrap DP observations table from internal observations
#'
#' @param obs Internal observations table.
#' @param taxa Internal taxa table.
#' @param tz Timezone.
#' @param fixed_offset_hours Optional fixed offset in hours.
#' @return Tibble matching Camtrap DP observations schema.
#' @export
build_camtrapdp_observations <- function(obs, taxa, tz = "UTC", fixed_offset_hours = NULL) {
  import::from("dplyr", mutate, left_join, select)
  import::from("stringr", str_to_lower)

  has_event_time <- "event_time" %in% names(obs)
  taxa_map <- taxa |>
    mutate(
      scientificName = dplyr::case_when(
        !is.na(genus) & !is.na(species) ~ paste(genus, species),
        !is.na(genus) & is.na(species) ~ genus,
        TRUE ~ short
      )
    ) |>
    select(short, scientificName)

  obs_tbl <- obs |>
    mutate(
      observationID = as.character(index),
      deploymentID = site,
      mediaID = as.character(ifelse(!is.na(imageid), imageid, index)),
      eventID = NA_character_,
      eventStart = if (has_event_time) event_time else parse_datetime_local(
        datetime,
        tz = tz,
        fixed_offset_hours = fixed_offset_hours,
        quiet = TRUE
      ),
      eventEnd = eventStart,
      observationLevel = "media",
      observationType = dplyr::if_else(
        str_to_lower(species) %in% c("blank", "unclassified"),
        "blank",
        "animal"
      ),
      count = ifelse(is.na(count) | count < 1, 1L, as.integer(count)),
      lifeStage = dplyr::case_when(
        str_to_lower(age) %in% c("adult", "subadult", "juvenile") ~ str_to_lower(age),
        TRUE ~ NA_character_
      ),
      sex = dplyr::case_when(
        str_to_lower(sex) %in% c("female", "male") ~ str_to_lower(sex),
        TRUE ~ NA_character_
      ),
      cameraSetupType = NA_character_,
      behavior = NA_character_,
      individualID = NA_character_,
      individualPositionRadius = NA_real_,
      individualPositionAngle = NA_real_,
      individualSpeed = NA_real_,
      bboxX = NA_real_,
      bboxY = NA_real_,
      bboxWidth = NA_real_,
      bboxHeight = NA_real_,
      classificationMethod = NA_character_,
      classifiedBy = NA_character_,
      classificationTimestamp = as.POSIXct(NA),
      classificationProbability = NA_real_,
      observationTags = NA_character_,
      observationComments = NA_character_
    ) |>
    left_join(taxa_map, by = c("species" = "short")) |>
    mutate(scientificName = ifelse(is.na(scientificName), species, scientificName)) |>
    select(
      observationID,
      deploymentID,
      mediaID,
      eventID,
      eventStart,
      eventEnd,
      observationLevel,
      observationType,
      cameraSetupType,
      scientificName,
      count,
      lifeStage,
      sex,
      behavior,
      individualID,
      individualPositionRadius,
      individualPositionAngle,
      individualSpeed,
      bboxX,
      bboxY,
      bboxWidth,
      bboxHeight,
      classificationMethod,
      classifiedBy,
      classificationTimestamp,
      classificationProbability,
      observationTags,
      observationComments
    )

  obs_tbl
}

#' Build Camtrap DP taxonomic metadata from taxa table
#'
#' @param taxa Internal taxa table.
#' @return List of taxonomic entries.
#' @export
build_camtrapdp_taxonomic <- function(taxa) {
  import::from("dplyr", mutate)

  taxonomic <- taxa |>
    mutate(
      scientificName = dplyr::case_when(
        !is.na(genus) & !is.na(species) ~ paste(genus, species),
        !is.na(genus) & is.na(species) ~ genus,
        TRUE ~ short
      ),
      taxonRank = dplyr::case_when(
        !is.na(genus) & !is.na(species) ~ "species",
        !is.na(genus) & is.na(species) ~ "genus",
        TRUE ~ NA_character_
      )
    )

  lapply(seq_len(nrow(taxonomic)), function(i) {
    item <- list(
      scientificName = taxonomic$scientificName[i],
      taxonRank = taxonomic$taxonRank[i]
    )
    if (!is.na(taxonomic$common[i]) && taxonomic$common[i] != "") {
      item$vernacularNames <- list(eng = taxonomic$common[i])
    }
    item
  })
}

#' Export internal data as a Camtrap DP package
#'
#' @param site Internal site table.
#' @param op Internal effort table.
#' @param obs Internal observations table.
#' @param taxa Internal taxa table.
#' @param export_config Config list for export metadata.
#' @param run_dir Output run directory.
#' @param tz Timezone.
#' @param fixed_offset_hours Optional fixed offset in hours.
#' @return Path to the exported `datapackage.json`.
#' @export
export_camtrapdp_package <- function(
  site,
  op,
  obs,
  taxa,
  export_config,
  run_dir,
  tz = "UTC",
  fixed_offset_hours = NULL
) {
  import::from("camtrapdp", example_dataset, deployments, media, observations, check_camtrapdp, write_camtrapdp)
  import::from("frictionless", read_package, check_package)
  import::from("uuid", UUIDgenerate)

  out_dir <- file.path(run_dir, "camtrapdp_export")
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

  parse_result <- parse_camtrapdp_datetimes(obs, tz = tz, fixed_offset_hours = fixed_offset_hours)
  obs_parsed <- parse_result$parsed
  dropped_obs <- parse_result$dropped
  dropped_count <- nrow(dropped_obs)
  audit_path <- file.path(out_dir, "dropped_observations.csv")
  if (dropped_count > 0) {
    warning("Dropping ", dropped_count, " observations with unparseable datetime for Camtrap DP export.")
    readr::write_csv(
      dropped_obs |>
        dplyr::select(index, site, datetime, species, imageid, reason, timezone),
      audit_path
    )
  } else if (file.exists(audit_path)) {
    file.remove(audit_path)
  }

  deployments_tbl <- build_camtrapdp_deployments(site, op, tz = tz, fixed_offset_hours = fixed_offset_hours)
  media_tbl <- build_camtrapdp_media(obs_parsed, tz = tz, fixed_offset_hours = fixed_offset_hours)
  observations_tbl <- build_camtrapdp_observations(obs_parsed, taxa, tz = tz, fixed_offset_hours = fixed_offset_hours)

  dp <- example_dataset()
  dp$resources <- purrr::keep(dp$resources, ~ .x$name %in% c("deployments", "media", "observations"))
  dp$data <- list(deployments = deployments_tbl, media = media_tbl, observations = observations_tbl)

  dp$name <- export_config$name
  dp$title <- export_config$title
  dp$description <- export_config$description
  dp$version <- export_config$version
  dp$id <- if (!is.null(export_config$id)) export_config$id else UUIDgenerate()
  dp$created <- if (!is.null(export_config$created)) {
    export_config$created
  } else {
    format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  }

  dp$taxonomic <- build_camtrapdp_taxonomic(taxa)
  dp$licenses <- list(list(name = export_config$license, scope = "data"))

  check_camtrapdp(dp)
  write_camtrapdp(dp, out_dir)

  pkg <- read_package(file.path(out_dir, "datapackage.json"))
  check_package(pkg)

  validation_path <- file.path(out_dir, "validation.txt")
  writeLines(
    c(
      "Camtrap DP export validation: OK",
      paste("Dropped observations (unparseable datetime):", dropped_count),
      paste("Generated:", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"))
    ),
    validation_path
  )

  file.path(out_dir, "datapackage.json")
}
