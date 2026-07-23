# camtrapdp_adapter.R

#' Read a materialised local Camtrap DP dataset
#'
#' @param path Local path to a snapshotted Camtrap DP `datapackage.json`.
#' @return camtrapdp object.
#' @export
read_camtrapdp_dataset <- function(path) {
  import::from("camtrapdp", read_camtrapdp)

  if (is.null(path) || !nzchar(path)) {
    stop("camtrapdp path must be provided when input_mode = 'camtrapdp'.")
  }
  if (grepl("^https?://", path, ignore.case = TRUE)) {
    stop("CamtrapDP URLs must be acquired and snapshotted before parsing.")
  }
  if (!file.exists(path)) {
    stop("Snapshotted CamtrapDP descriptor does not exist: ", path)
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

  if (all(is.na(dep$start_date))) {
    stop("Camtrap DP deployments missing deploymentStart dates.")
  }

  if (any(is.na(dep$start_date)) || any(is.na(dep$end_date))) {
    stop(
      "Camtrap DP deployment endpoints remain unknown; ",
      "Goal 006 forbids automatic endpoint copying."
    )
  }
  if (any(dep$end_date < dep$start_date)) {
    stop("Camtrap DP deploymentEnd precedes deploymentStart.")
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

assert_unique_camtrapdp_key <- function(table, field, resource) {
  if (!field %in% names(table)) {
    stop("CamtrapDP ", resource, " resource is missing key field ", field, ".")
  }
  values <- table[[field]]
  if (anyNA(values) || any(!nzchar(as.character(values))) || anyDuplicated(values)) {
    stop("CamtrapDP ", resource, " key is missing or duplicated: ", field)
  }
  invisible(TRUE)
}

assert_camtrapdp_integrity <- function(deployments, observations, media) {
  assert_unique_camtrapdp_key(deployments, "deploymentID", "deployments")
  assert_unique_camtrapdp_key(observations, "observationID", "observations")
  if (!is.null(media) && nrow(media) > 0L) {
    assert_unique_camtrapdp_key(media, "mediaID", "media")
  }

  missing_deployments <- setdiff(
    unique(observations$deploymentID),
    deployments$deploymentID
  )
  if (length(missing_deployments) > 0L) {
    stop(
      "CamtrapDP observation deployment key is unresolved: ",
      paste(missing_deployments, collapse = ", ")
    )
  }
  if (!is.null(media) &&
        nrow(media) > 0L &&
        "mediaID" %in% names(observations)) {
    referenced <- unique(stats::na.omit(observations$mediaID))
    missing_media <- setdiff(referenced, media$mediaID)
    if (length(missing_media) > 0L) {
      stop(
        "CamtrapDP observation media key is unresolved: ",
        paste(missing_media, collapse = ", ")
      )
    }
  }
  invisible(TRUE)
}

camtrapdp_semantic_defaults <- function(deployments, observations, media) {
  records <- list()
  add_record <- function(
      resource,
      ordinal,
      field,
      proposed_value,
      legacy_rule,
      affected_domains,
      blocks_analysis) {
    records[[length(records) + 1L]] <<- list(
      resource = resource,
      record_ordinal = as.integer(ordinal),
      field = field,
      original_value = NA,
      proposed_value = proposed_value,
      repair_class = "fill_unknown",
      legacy_rule = legacy_rule,
      affected_domains = affected_domains,
      blocks_analysis = isTRUE(blocks_analysis),
      production_applicable = FALSE
    )
  }

  for (index in seq_len(nrow(deployments))) {
    start_missing <- is.na(deployments$deploymentStart[[index]])
    end_missing <- is.na(deployments$deploymentEnd[[index]])
    if (start_missing) {
      add_record(
        "deployments",
        index,
        "deploymentStart",
        deployments$deploymentEnd[[index]],
        "legacy.copy_deployment_endpoint",
        c("effort", "operational_events", "all_analysis"),
        TRUE
      )
    }
    if (end_missing) {
      add_record(
        "deployments",
        index,
        "deploymentEnd",
        deployments$deploymentStart[[index]],
        "legacy.copy_deployment_endpoint",
        c("effort", "operational_events", "all_analysis"),
        TRUE
      )
    }
  }

  media_lookup <- NULL
  if (!is.null(media) && nrow(media) > 0L) {
    media_lookup <- match(observations$mediaID, media$mediaID)
  }
  for (index in seq_len(nrow(observations))) {
    if (is.na(observations$count[[index]])) {
      add_record(
        "observations",
        index,
        "count",
        1L,
        "legacy.fill_count_one",
        c("abundance_summaries"),
        FALSE
      )
    }
    if (!"flash" %in% names(observations) ||
          is.na(observations$flash[[index]])) {
      add_record(
        "observations",
        index,
        "flash",
        0L,
        "legacy.fill_flash_zero",
        c("diel_classification"),
        FALSE
      )
    }
    if (is.na(observations$eventStart[[index]]) &&
          !is.null(media_lookup) &&
          !is.na(media_lookup[[index]])) {
      add_record(
        "observations",
        index,
        "eventStart",
        media$timestamp[[media_lookup[[index]]]],
        "legacy.copy_media_timestamp",
        c("time_qc", "operational_events", "all_analysis"),
        TRUE
      )
    }
    if (is.na(observations$scientificName[[index]]) ||
          !nzchar(observations$scientificName[[index]])) {
      add_record(
        "observations",
        index,
        "scientificName",
        "unknown",
        "legacy.fill_unknown_taxon",
        c("taxonomy", "all_analysis"),
        TRUE
      )
    }
  }
  records
}

camtrapdp_transformations <- function() {
  list(
    list(
      transformation_schema = "camtrap-transformation/1.0",
      rule_id = "adapter.camtrapdp.deployments_to_site",
      rule_version = "1.0",
      input_resources = "deployments",
      source_fields = c(
        "deploymentID", "latitude", "longitude", "featureType", "locationName"
      ),
      resolved_table = "site",
      resolved_fields = c("site", "lat", "lon", "type", "location"),
      meaning_preserving = TRUE,
      reversibility_basis = "Direct field mapping; absent optional covariates remain NA."
    ),
    list(
      transformation_schema = "camtrap-transformation/1.0",
      rule_id = "adapter.camtrapdp.deployments_to_effort",
      rule_version = "1.0",
      input_resources = "deployments",
      source_fields = c("deploymentID", "deploymentStart", "deploymentEnd"),
      resolved_table = "op",
      resolved_fields = c("date", "deploymentID columns"),
      meaning_preserving = TRUE,
      reversibility_basis = "Daily 0/1 effort expands explicit closed deployment intervals."
    ),
    list(
      transformation_schema = "camtrap-transformation/1.0",
      rule_id = "adapter.camtrapdp.observations_to_obs",
      rule_version = "1.0",
      input_resources = c("observations", "media"),
      source_fields = c(
        "deploymentID", "eventStart", "scientificName", "count",
        "lifeStage", "sex", "fileName"
      ),
      resolved_table = "obs",
      resolved_fields = c(
        "site", "datetime", "species", "count", "age", "sex", "filename"
      ),
      meaning_preserving = TRUE,
      reversibility_basis = paste(
        "One output row per observation source ordinal;",
        "unknown source values remain NA."
      )
    )
  )
}

#' Convert Camtrap DP dataset into internal four-table contract
#'
#' @param dp Camtrap DP object returned by `read_camtrapdp()`.
#' @param tz Timezone for datetime formatting.
#' @param include_audit Include parser-order tables and mapping evidence.
#' @return List with `site`, `taxa`, `op`, and `obs` tibbles.
#' @export
camtrapdp_to_internal <- function(dp, tz = "UTC", include_audit = FALSE) {
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
  parsed_tables <- list(
    deployments = deployments,
    media = media,
    observations = observations
  )
  parsed_tables <- parsed_tables[!vapply(parsed_tables, is.null, logical(1))]

  if (is.null(media)) {
    media <- tibble(
      mediaID = character(),
      deploymentID = character(),
      timestamp = as.POSIXct(character()),
      fileName = character()
    )
  }

  character_defaults <- c(
    "mediaID", "scientificName", "taxon.vernacularNames.eng",
    "lifeStage", "sex"
  )
  for (field in character_defaults) {
    if (!field %in% names(observations)) {
      observations[[field]] <- NA_character_
    }
  }
  if (!"eventStart" %in% names(observations)) {
    observations$eventStart <- as.POSIXct(NA)
  }
  if (!"count" %in% names(observations)) {
    observations$count <- NA_integer_
  }
  if (!"timestamp" %in% names(media)) {
    media$timestamp <- as.POSIXct(NA)
  }
  if (!"fileName" %in% names(media)) {
    media$fileName <- NA_character_
  }
  assert_camtrapdp_integrity(deployments, observations, media)
  semantic_defaults <- camtrapdp_semantic_defaults(
    deployments,
    observations,
    media
  )
  if (!"flash" %in% names(observations)) {
    observations$flash <- NA_integer_
  }

  make_species_code <- function(name_vec) {
    cleaned <- str_to_lower(str_trim(as.character(name_vec)))
    cleaned <- str_replace_all(cleaned, "[^a-z0-9]+", "_")
    cleaned <- str_replace_all(cleaned, "^_+|_+$", "")
    cleaned[cleaned == "" | is.na(cleaned)] <- NA_character_
    cleaned
  }

  taxa_map <- observations |>
    dplyr::filter(!is.na(scientificName), nzchar(scientificName)) |>
    distinct(scientificName, common = taxon.vernacularNames.eng) |>
    mutate(
      genus = word(scientificName, 1),
      species = word(scientificName, 2),
      short = make_species_code(scientificName),
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
  if (anyDuplicated(taxa_map$scientificName)) {
    stop("CamtrapDP scientific name maps to conflicting taxon representations.")
  }
  collision_codes <- taxa_map$short[
    !is.na(taxa_map$short) & duplicated(taxa_map$short)
  ]
  if (length(collision_codes) > 0L) {
    stop(
      "CamtrapDP scientific-name code mapping collides: ",
      paste(unique(collision_codes), collapse = ", ")
    )
  }

  observations$.source_ordinal <- seq_len(nrow(observations))
  observations_clean <- observations |>
    left_join(
      select(media, mediaID, timestamp, fileName),
      by = "mediaID"
    ) |>
    left_join(
      select(taxa_map, scientificName, short),
      by = "scientificName"
    ) |>
    mutate(
      event_time = eventStart,
      event_time = with_tz(event_time, tz),
      datetime = format(event_time, "%d/%m/%Y %H:%M:%S"),
      species = short
    ) |>
    mutate(
      count = as.integer(round(count)),
      flash = as.integer(round(flash)),
      filename = as.character(fileName),
      age = as.character(lifeStage),
      sex = as.character(sex)
    ) |>
    arrange(event_time)

  if (nrow(observations_clean) != nrow(observations)) {
    stop("CamtrapDP adapter changed observation row count during joins.")
  }
  observation_source_ordinal <- observations_clean$.source_ordinal
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

  endpoint_unknown <- any(is.na(deployments$deploymentStart)) ||
    any(is.na(deployments$deploymentEnd))
  op_tbl <- if (isTRUE(include_audit) && endpoint_unknown) {
    empty <- tibble(date = character())
    for (deployment_id in deployments$deploymentID) {
      empty[[deployment_id]] <- numeric()
    }
    empty
  } else {
    build_effort_from_deployments(deployments)
  }

  taxa_tbl <- taxa_map |>
    select(
      class, order, family, genus, species, common, short,
      diet, sec_diet, activity, habitat, status, body_size,
      sociality, mobility, reproductive, litter
    )

  result <- list(site = site_tbl, taxa = taxa_tbl, op = op_tbl, obs = obs_tbl)
  if (isTRUE(include_audit)) {
    result$.audit <- list(
      audit_schema = "camtrap-parser-audit/1.0",
      parsed_tables = parsed_tables,
      observation_source_ordinal = observation_source_ordinal,
      transformations = camtrapdp_transformations(),
      semantic_defaults = semantic_defaults
    )
  }
  result
}
