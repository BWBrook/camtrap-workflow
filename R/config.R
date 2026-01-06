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
    paths = list(
      inputs = list(
        site = "data/jc_site.csv",
        op = "data/jc_op.csv",
        obs = "data/jc_obs.csv",
        taxa = "data/jc_taxa.csv"
      ),
      outputs = "outputs"
    ),
    analysis = list(
      rarefaction = TRUE,
      report = TRUE
    ),
    time_qc = list(
      backward_jump_threshold_hours = 1
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
    "paths",
    "analysis",
    "time_qc"
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

  invisible(config)
}
