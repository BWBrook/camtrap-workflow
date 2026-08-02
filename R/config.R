# Current Goal 011 configuration contract.

default_config <- function() {
  list(
    schema_version_path = "schema_version.txt",
    timezone = "Australia/Hobart",
    timezone_fixed_offset_hours = NULL,
    event_threshold_minutes = 15,
    input_mode = "four_table",
    validation = list(repair_decisions = list()),
    entity_resolution = list(
      profile_id = NULL,
      sidecar_path = NULL,
      sidecar_sha256 = NULL,
      authority_reference = NULL
    ),
    deployment_evidence = list(
      profile_id = NULL,
      service_sidecar_path = NULL,
      service_sidecar_sha256 = NULL,
      deployment_ledger_path = NULL,
      deployment_ledger_sha256 = NULL,
      authority_reference = NULL
    ),
    analysis_unit = list(
      resolution = "physical_location",
      mapping_profile_id = NULL,
      mapping_path = NULL,
      mapping_sha256 = NULL,
      authority_reference = NULL
    ),
    camtrapdp_acquisition = list(
      mode = "local",
      cache_dir = "outputs/cache/camtrapdp",
      descriptor_sha256 = NULL,
      resource_sha256 = list()
    ),
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
    map = list(label_locations = TRUE),
    diel = list(
      method = "flash",
      day_start_hour = 6,
      day_end_hour = 18
    ),
    sensitivity = list(event_threshold_minutes = c(5, 15, 30, 60))
  )
}

analysis_unit_fields <- function() {
  c(
    "resolution",
    "mapping_profile_id",
    "mapping_path",
    "mapping_sha256",
    "authority_reference"
  )
}

analysis_unit_mapping_authority <- function() { # nolint: object_length_linter.
  digest <- "6490d7f7021e5c727b9be1c7d6dfbf44ba50a1ef5b0396c66e1dd813a9c77083"
  list(
    mapping_profile_id = "judbury-analysis-site/1.0.0-proposed",
    mapping_path = paste0(
      "docs/goals/009-analysis-site-vertical-slice/",
      "judbury_analysis_site_mapping.csv"
    ),
    mapping_sha256 = digest,
    authority_reference = paste0(
      "goal009-judbury-analysis-site-mapping-sha256-", digest
    ),
    scheme_id = "judbury-analysis-site",
    scheme_version = "1.0.0-proposed",
    authority_state = "proposed_for_barry_exact_approval"
  )
}

analysis_unit_identity_authority <- function() { # nolint: object_length_linter.
  list(
    scheme_id = "camtrap-physical-location-identity",
    scheme_version = "1.0.0",
    authority_reference =
      "camtrap-workflow-built-in-physical-location-identity/1.0.0",
    authority_state = "built_in_default"
  )
}

analysis_unit_selection <- function(config) {
  selection <- config$analysis_unit
  fields <- analysis_unit_fields()
  if (!is.list(selection) ||
        !identical(sort(names(selection)), sort(fields))) {
    stop(
      "config.yml analysis_unit must contain exactly resolution, ",
      "mapping_profile_id, mapping_path, mapping_sha256, and ",
      "authority_reference."
    )
  }
  selection <- selection[fields]
  resolution <- selection$resolution
  if (!is.character(resolution) || length(resolution) != 1L ||
        !resolution %in% c("analysis_site", "physical_location")) {
    stop(
      "config.yml analysis_unit.resolution must be physical_location or ",
      "analysis_site."
    )
  }

  mapping_fields <- fields[-1L]
  nulls <- vapply(selection[mapping_fields], is.null, logical(1))
  if (identical(resolution, "physical_location")) {
    if (!all(nulls)) {
      stop("Physical-location analysis must not supply a grouping mapping.")
    }
    return(c(
      utils::modifyList(selection, analysis_unit_identity_authority()),
      state = "built_in_default"
    ))
  }
  if (any(nulls)) {
    stop("Analysis-site resolution requires one complete approved mapping.")
  }
  if (!all(vapply(selection[mapping_fields], function(value) {
    is.character(value) && length(value) == 1L && nzchar(value)
  }, logical(1)))) {
    stop("config.yml analysis_unit mapping fields must be non-empty strings.")
  }
  if (!grepl("^[a-f0-9]{64}$", selection$mapping_sha256)) {
    stop("config.yml analysis_unit.mapping_sha256 must be a SHA-256 digest.")
  }
  if (!is_safe_relative_path(selection$mapping_path)) {
    stop("config.yml analysis_unit.mapping_path must be a safe relative path.")
  }
  authority <- analysis_unit_mapping_authority()
  if (!identical(selection[mapping_fields], authority[mapping_fields])) {
    stop("config.yml analysis_unit selection has no exact approved authority.")
  }
  c(
    selection,
    authority[c("scheme_id", "scheme_version", "authority_state")],
    state = "selected_mapping"
  )
}

normalize_analysis_unit_config <- function(config) {
  selection <- analysis_unit_selection(config)
  resolved <- selection[c(
    "resolution", "scheme_id", "scheme_version", "authority_reference",
    "authority_state", "state"
  )]
  if (identical(selection$state, "selected_mapping")) {
    resolved$mapping_profile_id <- selection$mapping_profile_id
    resolved$mapping_path <- selection$mapping_path
    resolved$mapping_sha256 <- selection$mapping_sha256
  } else {
    resolved$mapping_profile_id <- NULL
    resolved$mapping_path <- NULL
    resolved$mapping_sha256 <- NULL
  }
  config$analysis_unit_resolved <- resolved
  config
}

validate_exact_fields <- function(value, fields, label) {
  if (!is.list(value) || !identical(sort(names(value)), sort(fields))) {
    stop(label, " must contain exactly: ", paste(fields, collapse = ", "), ".")
  }
  invisible(TRUE)
}

validate_entity_config <- function(selection) {
  fields <- c(
    "profile_id", "sidecar_path", "sidecar_sha256", "authority_reference"
  )
  validate_exact_fields(selection, fields, "config.yml entity_resolution")
  values <- selection[fields]
  nulls <- vapply(values, is.null, logical(1))
  if (all(nulls)) return(invisible(TRUE))
  if (any(nulls) || !all(vapply(values, function(value) {
    is.character(value) && length(value) == 1L && nzchar(value)
  }, logical(1)))) {
    stop("config.yml entity_resolution must be all null or fully selected.")
  }
  digest <- "553abada14493f3a5f0ae3c072523b6d5cc0d0c6a6c6480ca17a9e3331f2d8ec"
  approved <- list(
    profile_id = "judbury-entity-crosswalk/1.0.0-proposed",
    sidecar_sha256 = digest,
    authority_reference = paste0("goal007-judbury-crosswalk-sha256-", digest)
  )
  if (!grepl("^[a-f0-9]{64}$", selection$sidecar_sha256) ||
        !identical(selection[names(approved)], approved)) {
    stop("config.yml entity_resolution selection has no exact approved authority.")
  }
  invisible(TRUE)
}

deployment_evidence_fields <- function() {
  c(
    "profile_id",
    "service_sidecar_path",
    "service_sidecar_sha256",
    "deployment_ledger_path",
    "deployment_ledger_sha256",
    "authority_reference"
  )
}

approved_deployment_evidence_config <- function() { # nolint: object_length_linter.
  service_sha256 <-
    "f33eeac9d70126966717c8e3f4731c00a97cbc3a34c2f44ce5c70d91c7d5283a"
  ledger_sha256 <-
    "0921eb8845c2bb1ad5760271f283ab2783735b7739e254c67e9243bc906f3ebf"
  list(
    profile_id = "judbury-deployment-evidence/1.0.0-proposed",
    service_sidecar_path = "data/jc_services.csv",
    service_sidecar_sha256 = service_sha256,
    deployment_ledger_path = paste0(
      "docs/goals/008-judbury-deployment-evidence/",
      "judbury_deployment_ledger.csv"
    ),
    deployment_ledger_sha256 = ledger_sha256,
    authority_reference = paste0(
      "goal008-judbury-deployment-evidence-source-sha256-",
      service_sha256,
      "-ledger-sha256-",
      ledger_sha256
    )
  )
}

validate_deployment_evidence_config <- function(selection) { # nolint: object_length_linter.
  fields <- deployment_evidence_fields()
  validate_exact_fields(
    selection,
    fields,
    "config.yml deployment_evidence"
  )
  nulls <- vapply(selection[fields], is.null, logical(1))
  if (all(nulls)) return(invisible(TRUE))
  if (any(nulls) || !all(vapply(selection[fields], function(value) {
    is.character(value) && length(value) == 1L && nzchar(value)
  }, logical(1)))) {
    stop("config.yml deployment_evidence must be all null or fully selected.")
  }
  if (!identical(selection[fields], approved_deployment_evidence_config())) {
    stop(
      "config.yml deployment_evidence selection has no exact approved authority."
    )
  }
  invisible(TRUE)
}

validate_repair_config <- function(validation) {
  validate_exact_fields(
    validation,
    "repair_decisions",
    "config.yml validation"
  )
  decisions <- validation$repair_decisions
  if (!is.list(decisions)) {
    stop("config.yml validation.repair_decisions must be an exact list.")
  }
  allowed <- c("proposal_id", "proposal_digest", "decision", "reason")
  required <- c("proposal_id", "proposal_digest", "decision")
  for (decision in decisions) {
    exact <- is.list(decision) && all(required %in% names(decision)) &&
      length(setdiff(names(decision), allowed)) == 0L
    digests <- if (exact) {
      c(decision$proposal_id, decision$proposal_digest)
    } else {
      character()
    }
    if (!exact || length(digests) != 2L ||
          !all(grepl("^[a-f0-9]{64}$", digests)) ||
          !is.character(decision$decision) ||
          length(decision$decision) != 1L ||
          !decision$decision %in% c("approved", "declined")) {
      stop("config.yml repair decision fields are malformed.")
    }
    if (!is.null(decision$reason) &&
          (!is.character(decision$reason) || length(decision$reason) != 1L)) {
      stop("config.yml repair decision reason must be one string or null.")
    }
  }
  invisible(TRUE)
}

validate_scalar <- function(value, type, label) {
  valid <- length(value) == 1L && !is.na(value) && switch(
    type,
    character = is.character(value) && nzchar(value),
    numeric = is.numeric(value),
    logical = is.logical(value),
    FALSE
  )
  if (!valid) stop(label, " is invalid.")
  invisible(TRUE)
}

validate_config <- function(config) { # nolint: object_length_linter.
  config$analysis_unit_resolved <- NULL
  fields <- names(default_config())
  validate_exact_fields(config, fields, "config.yml")
  validate_scalar(
    config$schema_version_path,
    "character",
    "config.yml schema_version_path"
  )
  validate_scalar(config$timezone, "character", "config.yml timezone")
  if (!is.null(config$timezone_fixed_offset_hours)) {
    validate_scalar(
      config$timezone_fixed_offset_hours,
      "numeric",
      "config.yml timezone_fixed_offset_hours"
    )
  }
  validate_scalar(
    config$event_threshold_minutes,
    "numeric",
    "config.yml event_threshold_minutes"
  )
  if (config$event_threshold_minutes < 0) {
    stop("config.yml event_threshold_minutes must be non-negative.")
  }
  if (!identical(config$input_mode, "four_table") &&
        !identical(config$input_mode, "camtrapdp")) {
    stop("config.yml input_mode must be four_table or camtrapdp.")
  }

  validate_repair_config(config$validation)
  validate_entity_config(config$entity_resolution)
  validate_deployment_evidence_config(config$deployment_evidence)
  analysis_unit_selection(config)
  validate_exact_fields(config$map, "label_locations", "config.yml map")
  validate_scalar(
    config$map$label_locations,
    "logical",
    "config.yml map.label_locations"
  )
  validate_exact_fields(
    config$diel,
    c("method", "day_start_hour", "day_end_hour"),
    "config.yml diel"
  )
  if (!config$diel$method %in% c("flash", "clock")) {
    stop("config.yml diel.method must be flash or clock.")
  }
  hours <- c(config$diel$day_start_hour, config$diel$day_end_hour)
  if (!is.numeric(hours) || length(hours) != 2L || anyNA(hours) ||
        any(hours < 0 | hours > 23) || hours[[2L]] <= hours[[1L]]) {
    stop("config.yml diel hours must be ordered values from 0 to 23.")
  }
  validate_exact_fields(
    config$sensitivity,
    "event_threshold_minutes",
    "config.yml sensitivity"
  )
  thresholds <- config$sensitivity$event_threshold_minutes
  if (!is.numeric(thresholds) || length(thresholds) == 0L ||
        anyNA(thresholds) || any(thresholds < 0)) {
    stop("config.yml sensitivity thresholds must be non-negative numbers.")
  }

  acquisition_fields <- c(
    "mode", "cache_dir", "descriptor_sha256", "resource_sha256"
  )
  acquisition <- config$camtrapdp_acquisition
  validate_exact_fields(
    acquisition,
    acquisition_fields,
    "config.yml camtrapdp_acquisition"
  )
  if (!acquisition$mode %in% c("local", "remote")) {
    stop("config.yml camtrapdp_acquisition.mode must be local or remote.")
  }
  validate_scalar(
    acquisition$cache_dir,
    "character",
    "config.yml camtrapdp_acquisition.cache_dir"
  )
  if (!is.null(acquisition$descriptor_sha256) &&
        (!is.character(acquisition$descriptor_sha256) ||
           length(acquisition$descriptor_sha256) != 1L ||
           !grepl("^[A-Fa-f0-9]{64}$", acquisition$descriptor_sha256))) {
    stop("CamtrapDP descriptor_sha256 must be null or one SHA-256 digest.")
  }
  if (!is.list(acquisition$resource_sha256)) {
    stop("CamtrapDP resource_sha256 must be a named map.")
  }

  validate_exact_fields(config$paths, c("inputs", "outputs"), "config.yml paths")
  input_fields <- c("site", "op", "obs", "taxa", "camtrapdp")
  validate_exact_fields(
    config$paths$inputs,
    input_fields,
    "config.yml paths.inputs"
  )
  validate_scalar(
    config$paths$outputs,
    "character",
    "config.yml paths.outputs"
  )
  if (identical(config$input_mode, "four_table")) {
    for (name in c("site", "op", "obs", "taxa")) {
      validate_scalar(
        config$paths$inputs[[name]],
        "character",
        paste0("config.yml paths.inputs.", name)
      )
    }
    if (!is.null(config$paths$inputs$camtrapdp)) {
      stop("Four-table input must not also select a CamtrapDP descriptor.")
    }
  } else {
    validate_scalar(
      config$paths$inputs$camtrapdp,
      "character",
      "config.yml paths.inputs.camtrapdp"
    )
    if (any(!vapply(
      config$paths$inputs[c("site", "op", "obs", "taxa")],
      is.null,
      logical(1)
    ))) {
      stop("CamtrapDP input must not also select four-table files.")
    }
    remote <- grepl("^https?://", config$paths$inputs$camtrapdp)
    if (identical(acquisition$mode, "remote") && !remote) {
      stop("Remote CamtrapDP acquisition requires an HTTP(S) descriptor.")
    }
    if (identical(acquisition$mode, "local") && remote) {
      stop("Local CamtrapDP acquisition requires a local descriptor.")
    }
    if (identical(acquisition$mode, "remote") &&
          is.null(acquisition$descriptor_sha256)) {
      stop("Remote CamtrapDP acquisition requires descriptor_sha256.")
    }
  }

  entity_selected <- !is.null(config$entity_resolution$profile_id)
  deployment_selected <- !is.null(config$deployment_evidence$profile_id)
  if ((entity_selected || deployment_selected) &&
        !identical(config$input_mode, "four_table")) {
    stop("Judbury authority selections only apply to four-table input.")
  }
  if (deployment_selected && !entity_selected) {
    stop("Deployment evidence requires the selected entity authority.")
  }
  invisible(config)
}

read_config <- function(path = "config.yml") {
  if (!file.exists(path)) stop("config.yml not found at path: ", path)
  raw <- yaml::read_yaml(path)
  if (!is.list(raw)) stop("config.yml must contain one configuration map.")
  unknown <- setdiff(names(raw), names(default_config()))
  if (length(unknown) > 0L) {
    stop("config.yml contains removed or unknown field(s): ", paste(unknown, collapse = ", "))
  }
  config <- utils::modifyList(default_config(), raw, keep.null = TRUE)
  validate_config(config)
  normalize_analysis_unit_config(config)
}
