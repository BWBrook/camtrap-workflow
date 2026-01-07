# config.R

#' Return default configuration values
#'
#' @return List of default configuration values.
#' @export
default_config <- function() {
  list(
    schema_version_path = "schema_version.txt",
    run_id = "latest",
    timezone = "Australia/Hobart",
    event_threshold_minutes = 15,
    input_mode = "four_table",
    paths = list(
      inputs = list(
        site = "data/jc_site.csv",
        op = "data/jc_op.csv",
        obs = "data/jc_obs.csv",
        taxa = "data/jc_taxa.csv",
        camtrapdp = NULL
      ),
      outputs = "outputs"
    ),
    analysis = list(
      rarefaction = TRUE,
      report = TRUE
    ),
    time_qc = list(
      backward_jump_threshold_hours = 1
    ),
    sensitivity = list(
      event_threshold_minutes = c(5, 15, 30, 60),
      occasion_length_days = c(3, 7, 14, 30)
    ),
    detection_history = list(
      occasion_length_days = 7,
      start_date = NULL
    ),
    occupancy = list(
      species = NULL,
      top_n = 3,
      covariates = c("canopy_h_m", "ndvi")
    ),
    traits = list(
      species_column = "short",
      columns = c("diet", "sec_diet", "activity", "habitat", "status", "body_size", "sociality", "mobility"),
      association_traits = c("diet", "activity", "habitat", "body_size", "status"),
      environment_vars = c("elevation_m", "canopy_h_m", "ndvi")
    )
  )
}

#' Read and validate configuration
#'
#' @param path Path to config YAML.
#' @return List with configuration values.
#' @export
read_config <- function(path = "config.yml") {
  import::from("fs", file_exists)
  import::from("yaml", read_yaml)

  if (!file_exists(path)) {
    stop("config.yml not found at path: ", path)
  }

  config <- read_yaml(path)
  config <- modifyList(default_config(), config)

  validate_config(config)
}

#' Validate configuration values
#'
#' @param config List of configuration values.
#' @return config invisibly.
#' @export
validate_config <- function(config) {
  required_paths <- c(
    "schema_version_path",
    "run_id",
    "timezone",
    "event_threshold_minutes",
    "input_mode",
    "paths",
    "analysis",
    "time_qc",
    "sensitivity",
    "detection_history",
    "occupancy",
    "traits"
  )

  missing <- setdiff(required_paths, names(config))
  if (length(missing) > 0) {
    stop("config.yml missing required field(s): ", paste(missing, collapse = ", "))
  }

  if (!is.numeric(config$event_threshold_minutes) || length(config$event_threshold_minutes) != 1) {
    stop("config.yml field event_threshold_minutes must be a single numeric value.")
  }

  if (!is.character(config$timezone) || length(config$timezone) != 1) {
    stop("config.yml field timezone must be a single character value.")
  }

  if (!is.character(config$run_id) || length(config$run_id) != 1) {
    stop("config.yml field run_id must be a single character value.")
  }

  if (!is.character(config$input_mode) || length(config$input_mode) != 1) {
    stop("config.yml field input_mode must be a single character value.")
  }

  if (!config$input_mode %in% c("four_table", "camtrapdp")) {
    stop("config.yml input_mode must be 'four_table' or 'camtrapdp'.")
  }

  analysis_fields <- c("rarefaction", "report")
  missing_analysis <- setdiff(analysis_fields, names(config$analysis))
  if (length(missing_analysis) > 0) {
    stop("config.yml missing analysis field(s): ", paste(missing_analysis, collapse = ", "))
  }

  for (field in analysis_fields) {
    if (!is.logical(config$analysis[[field]]) || length(config$analysis[[field]]) != 1) {
      stop("config.yml analysis.", field, " must be TRUE/FALSE.")
    }
  }

  if (isTRUE(config$analysis$report) && !isTRUE(config$analysis$rarefaction)) {
    stop("config.yml analysis.rarefaction must be TRUE when analysis.report is TRUE.")
  }

  if (!is.list(config$time_qc) || is.null(config$time_qc$backward_jump_threshold_hours)) {
    stop("config.yml time_qc.backward_jump_threshold_hours must be provided.")
  }

  if (!is.numeric(config$time_qc$backward_jump_threshold_hours) ||
        length(config$time_qc$backward_jump_threshold_hours) != 1) {
    stop("config.yml time_qc.backward_jump_threshold_hours must be a single numeric value.")
  }

  if (!is.list(config$sensitivity) || is.null(config$sensitivity$event_threshold_minutes)) {
    stop("config.yml sensitivity.event_threshold_minutes must be provided.")
  }

  if (!is.numeric(config$sensitivity$event_threshold_minutes) ||
        length(config$sensitivity$event_threshold_minutes) < 1) {
    stop("config.yml sensitivity.event_threshold_minutes must be a numeric vector.")
  }

  if (is.null(config$sensitivity$occasion_length_days) ||
        !is.numeric(config$sensitivity$occasion_length_days) ||
        length(config$sensitivity$occasion_length_days) < 1) {
    stop("config.yml sensitivity.occasion_length_days must be a numeric vector.")
  }

  if (!is.list(config$detection_history) || is.null(config$detection_history$occasion_length_days)) {
    stop("config.yml detection_history.occasion_length_days must be provided.")
  }

  if (!is.numeric(config$detection_history$occasion_length_days) ||
        length(config$detection_history$occasion_length_days) != 1 ||
        config$detection_history$occasion_length_days < 1) {
    stop("config.yml detection_history.occasion_length_days must be a positive integer.")
  }

  if (!is.list(config$occupancy)) {
    stop("config.yml occupancy must be provided as a list.")
  }

  if (config$input_mode == "camtrapdp") {
    camtrap_path <- config$paths$inputs$camtrapdp
    if (is.null(camtrap_path) || !is.character(camtrap_path) || !nzchar(camtrap_path)) {
      stop("config.yml paths.inputs.camtrapdp must be a non-empty string when input_mode = 'camtrapdp'.")
    }
  }

  if (!is.null(config$occupancy$species) &&
        !is.character(config$occupancy$species)) {
    stop("config.yml occupancy.species must be NULL or a character vector.")
  }

  if (is.null(config$occupancy$top_n) ||
        !is.numeric(config$occupancy$top_n) ||
        length(config$occupancy$top_n) != 1 ||
        config$occupancy$top_n < 1) {
    stop("config.yml occupancy.top_n must be a positive integer.")
  }

  if (is.null(config$occupancy$covariates) ||
        !is.character(config$occupancy$covariates) ||
        length(config$occupancy$covariates) < 1) {
    stop("config.yml occupancy.covariates must be a character vector.")
  }

  if (!is.list(config$traits)) {
    stop("config.yml traits must be provided as a list.")
  }

  if (is.null(config$traits$species_column) ||
        !is.character(config$traits$species_column) ||
        length(config$traits$species_column) != 1) {
    stop("config.yml traits.species_column must be a single character value.")
  }

  if (is.null(config$traits$columns) ||
        !is.character(config$traits$columns) ||
        length(config$traits$columns) < 1) {
    stop("config.yml traits.columns must be a character vector.")
  }

  if (!is.null(config$traits$association_traits) &&
        !is.character(config$traits$association_traits)) {
    stop("config.yml traits.association_traits must be NULL or a character vector.")
  }

  if (is.null(config$traits$environment_vars) ||
        !is.character(config$traits$environment_vars) ||
        length(config$traits$environment_vars) < 1) {
    stop("config.yml traits.environment_vars must be a character vector.")
  }

  invisible(config)
}
