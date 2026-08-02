# Explicit Goal 011 workflow stages.

workflow_request_schema <- "camtrap-workflow-request/2.0"
workflow_stage_schema <- "camtrap-workflow-stage/2.0"
module_status_schema <- "camtrap-module-status/2.0"

assert_workflow_request <- function(request) {
  fields <- c(
    "request_schema", "run_id", "created_utc", "config_path",
    "project_root", "outputs_root", "staging_dir", "target_store", "fetch"
  )
  if (!is.list(request) || !identical(sort(names(request)), sort(fields)) ||
        !identical(request$request_schema, workflow_request_schema)) {
    stop("Workflow request does not match the current explicit contract.")
  }
  assert_safe_run_id(request$run_id)
  for (name in c(
    "created_utc", "config_path", "project_root", "outputs_root",
    "staging_dir", "target_store"
  )) {
    value <- request[[name]]
    if (!is.character(value) || length(value) != 1L || !nzchar(value)) {
      stop("Workflow request field is invalid: ", name)
    }
  }
  if (!is.function(request$fetch)) {
    stop("Workflow request fetch implementation must be a function.")
  }
  invisible(TRUE)
}

stage_record <- function(stage, ...) {
  list(
    stage_schema = workflow_stage_schema,
    stage = stage,
    ...
  )
}

write_stage_csv <- function(value, path) {
  if (file.exists(path)) stop("Refusing to overwrite stage output: ", path)
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  readr::write_csv(value, path, na = "")
  path
}

stage_relative_path <- function(path, root) {
  if (is.null(path)) return(NULL)
  normalize_relative_path(fs::path_rel(path, start = root))
}

run_ingest_stage <- function(request) {
  assert_workflow_request(request)
  if (dir.exists(request$staging_dir) ||
        file.exists(file.path(request$outputs_root, "runs", request$run_id))) {
    stop("Refusing run identity collision: ", request$run_id)
  }
  dir.create(request$staging_dir, recursive = TRUE, showWarnings = FALSE)
  raw_config <- file.path(
    request$staging_dir,
    "provenance",
    "config.raw.yml"
  )
  snapshot_config_file(request$config_path, raw_config)
  config <- read_config(raw_config)
  configured_outputs <- resolve_project_path(
    config$paths$outputs,
    request$project_root
  )
  if (!identical(configured_outputs, request$outputs_root)) {
    stop("Workflow request output root disagrees with captured configuration.")
  }
  snapshot <- materialize_source_snapshot(
    config,
    request$staging_dir,
    project_root = request$project_root,
    fetch = request$fetch
  )
  config_hashes <- config_fingerprints(raw_config, config)
  engine <- compute_engine_identity(request$project_root)
  fingerprints <- list(
    source = snapshot$source_sha256,
    config = list(
      raw = config_hashes$raw_sha256,
      resolved = config_hashes$resolved_sha256
    ),
    engine = engine$engine_sha256
  )
  fingerprints$composite <- composite_fingerprint(
    fingerprints$source,
    fingerprints$config$resolved,
    fingerprints$engine
  )
  run <- list(
    run_id = request$run_id,
    created_utc = request$created_utc,
    fingerprints = fingerprints
  )
  source_inventory <- file.path(
    request$staging_dir,
    "provenance",
    "source_inventory.json"
  )
  effective_config <- file.path(
    request$staging_dir,
    "provenance",
    "effective_config.json"
  )
  write_source_inventory(snapshot, request$run_id, source_inventory)
  write_effective_config(config, run, effective_config)
  stage_record(
    "ingest",
    request = request,
    run = run,
    config = config,
    snapshot = snapshot,
    engine = engine,
    artifacts = list(
      raw_config = raw_config,
      effective_config = effective_config,
      source_inventory = source_inventory
    )
  )
}

run_validation_stage <- function(ingest) {
  stopifnot(identical(ingest$stage, "ingest"))
  verify_source_snapshot(ingest$snapshot, ingest$request$staging_dir)
  state <- prepare_validation_preflight(
    ingest$config,
    ingest$snapshot,
    four_table_reader = read_jc_csv,
    camtrapdp_reader = read_camtrapdp_dataset,
    camtrapdp_adapter = camtrapdp_to_internal
  )
  artifacts <- write_validation_artifacts(
    state,
    ingest$request$staging_dir
  )
  stage_record(
    "validate",
    ingest = ingest,
    state = state,
    artifacts = artifacts
  )
}

run_foundation_stage <- function(validation) {
  stopifnot(identical(validation$stage, "validate"))
  if (!isTRUE(validation$state$can_analyze)) {
    stop("Validation blocked analysis; inspect the validation audit bundle.")
  }
  ingest <- validation$ingest
  entity <- resolve_entity_evidence(
    ingest$config,
    ingest$snapshot,
    validation$state
  )
  entity_artifacts <- write_entity_artifacts(
    entity,
    ingest$request$staging_dir
  )
  if (!isTRUE(entity$can_analyze)) {
    stop("Entity or deployment integrity blocked analysis.")
  }
  selected <- resolve_selected_resolution(
    ingest$config,
    ingest$snapshot,
    validation$state,
    entity
  )
  selected_artifacts <- write_selected_resolution_artifacts(
    selected,
    ingest$request$staging_dir
  )
  if (!isTRUE(selected$integrity_ok)) {
    stop("Selected-resolution integrity blocked analysis.")
  }
  stage_record(
    "foundation",
    validation = validation,
    entity = entity,
    entity_artifacts = entity_artifacts,
    selected = selected,
    selected_artifacts = as.list(selected_artifacts)
  )
}

physical_event_table <- function(event_lineage) {
  events <- event_lineage$events
  observations <- event_lineage$obs_events
  if (nrow(events) == 0L) {
    return(data.frame(
      event_id = character(),
      physical_location_id = character(),
      species = character(),
      event_time = character(),
      source_membership_count = integer(),
      source_membership_digest = character(),
      stringsAsFactors = FALSE
    ))
  }
  rows <- lapply(seq_len(nrow(events)), function(index) {
    event_id <- events$event_id[[index]]
    event_rows <- observations[observations$event_id == event_id, , drop = FALSE]
    memberships <- event_lineage$memberships[
      event_lineage$memberships$event_id == event_id,
      ,
      drop = FALSE
    ]
    data.frame(
      event_id = event_id,
      physical_location_id = as.character(events$physical_location_id[[index]]),
      species = as.character(events$species[[index]]),
      event_time = format(
        min(event_rows$dt),
        "%Y-%m-%dT%H:%M:%SZ",
        tz = "UTC"
      ),
      source_membership_count = as.integer(nrow(memberships)),
      source_membership_digest = sha256_text(canonical_json(sort(
        memberships$source_row_id,
        method = "radix"
      ))),
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

run_events_stage <- function(foundation) {
  stopifnot(identical(foundation$stage, "foundation"))
  validation <- foundation$validation
  ingest <- validation$ingest
  event_lineage <- validation$state$event_lineage
  validate_event_lineage(event_lineage, validation$state$lineage)
  validate_event_membership(
    event_lineage,
    event_lineage$obs_events,
    validation$state$lineage
  )
  physical_events <- physical_event_table(event_lineage)
  root <- ingest$request$staging_dir
  event_path <- write_stage_csv(
    physical_events,
    file.path(root, "tables", "physical_events.csv")
  )
  membership_path <- write_stage_csv(
    event_lineage$memberships,
    file.path(root, "provenance", "event_membership.csv")
  )
  op_long <- pivot_op_long(validation$state$inputs$op)
  trap_nights <- calc_trap_nights(op_long)
  events_per_day <- summarise_events(event_lineage$obs_events)
  stage_record(
    "events",
    foundation = foundation,
    event_lineage = event_lineage,
    physical_events = physical_events,
    events_per_day = events_per_day,
    op_long = op_long,
    trap_nights = trap_nights,
    artifacts = list(
      physical_events = event_path,
      event_membership = membership_path
    )
  )
}

module_record <- function(
    module,
    status,
    required_evidence,
    actual_resolution,
    reason = NULL,
    claim_limit = NULL,
    outputs = list()) {
  allowed <- c("completed", "completed_with_warnings", "omitted", "failed")
  if (!status %in% allowed) stop("Invalid module status: ", status)
  if (!identical(status, "completed") &&
        (!is.character(reason) || length(reason) != 1L || !nzchar(reason))) {
    stop("Non-completed modules require one plain-language reason.")
  }
  list(
    module_status_schema = module_status_schema,
    module = module,
    status = status,
    required_evidence = as.list(required_evidence),
    actual_resolution = actual_resolution,
    reason = reason,
    claim_limit = claim_limit,
    outputs = outputs
  )
}

attempt_module <- function(
    module,
    required_evidence,
    actual_resolution,
    claim_limit,
    action) {
  tryCatch(
    action(),
    error = function(error) {
      list(
        record = module_record(
          module,
          "failed",
          required_evidence,
          actual_resolution,
          reason = conditionMessage(error),
          claim_limit = claim_limit
        ),
        outputs = list()
      )
    }
  )
}

selected_module_records <- function(selected_status, selected_paths, root) {
  status <- selected_status$status
  reason <- if (identical(status, "completed")) {
    NULL
  } else if (identical(status, "completed_with_warnings")) {
    "No operational detection events were available; valid empty summaries were produced."
  } else if (identical(status, "omitted")) {
    "The selected spatial route lacked the required scientific evidence."
  } else {
    "Selected-resolution integrity failed."
  }
  specification <- list(
    effort_coverage = list(
      required = c("confirmed operation", "selected spatial membership"),
      claim = "Confirmed active days only; unknown operation is not effort."
    ),
    observed_presence = list(
      required = c("physical-location events", "selected spatial membership"),
      claim = "Observed presence is detection- and effort-bounded."
    ),
    observed_richness = list(
      required = c("observed presence", "selected spatial membership"),
      claim = "Observed richness does not estimate unseen species."
    ),
    jaccard = list(
      required = c("observed presence", "selected spatial membership"),
      claim = paste(
        "Descriptive detected composition only; not standardized for effort,",
        "completeness, or detectability."
      )
    )
  )
  path_names <- c(
    effort_coverage = "effort_coverage",
    observed_presence = "community_presence",
    observed_richness = "observed_richness",
    jaccard = "jaccard"
  )
  lapply(names(specification), function(name) {
    path <- selected_paths[[path_names[[name]]]]
    outputs <- if (is.null(path)) list() else list(
      table = stage_relative_path(path, root)
    )
    module_record(
      name,
      status,
      specification[[name]]$required,
      selected_status$resolution,
      reason = reason,
      claim_limit = specification[[name]]$claim,
      outputs = outputs
    )
  })
}

run_modules_stage <- function(events) { # nolint: object_length_linter.
  stopifnot(identical(events$stage, "events"))
  foundation <- events$foundation
  validation <- foundation$validation
  ingest <- validation$ingest
  root <- ingest$request$staging_dir
  config <- ingest$config
  selected_paths <- write_selected_ecological_outputs(
    foundation$selected,
    events$event_lineage$obs_events,
    root,
    event_conservation = validate_selected_runtime_events(
      foundation$selected$event_map,
      events$event_lineage$obs_events
    )
  )
  selected_status <- jsonlite::read_json(
    selected_paths$status,
    simplifyVector = FALSE
  )
  records <- selected_module_records(selected_status, selected_paths, root)
  outputs <- selected_paths
  zero_events <- nrow(events$physical_events) == 0L

  rate <- attempt_module(
    "operational_event_detection_rate",
    c("physical-location events", "confirmed active days"),
    "physical_location",
    "Operational detection rate is not abundance or density.",
    function() {
      table <- compute_operational_event_detection_rate(
        events$events_per_day,
        events$trap_nights
      )
      path <- write_stage_csv(
        table,
        file.path(root, "tables", "operational_event_detection_rate.csv")
      )
      status <- if (zero_events) "completed_with_warnings" else "completed"
      reason <- if (zero_events) {
        "No operational detection events were available; the rate table is empty."
      } else {
        NULL
      }
      list(
        record = module_record(
          "operational_event_detection_rate",
          status,
          c("physical-location events", "confirmed active days"),
          "physical_location",
          reason,
          "Operational detection rate is not abundance or density.",
          list(table = stage_relative_path(path, root))
        ),
        outputs = list(operational_event_detection_rate = path)
      )
    }
  )
  records[[length(records) + 1L]] <- rate$record
  outputs <- c(outputs, rate$outputs)

  day_night <- attempt_module(
    "coarse_day_night",
    c("identified physical-location events", "flash or usable clock evidence"),
    "physical_location",
    "Coarse day/night categories do not imply fine-scale diel timing.",
    function() {
      table <- calc_diel(
        events$event_lineage$obs_events,
        method = config$diel$method,
        day_start_hour = config$diel$day_start_hour,
        day_end_hour = config$diel$day_end_hour
      )
      path <- write_stage_csv(
        table,
        file.path(root, "tables", "coarse_day_night.csv")
      )
      status <- if (zero_events) "completed_with_warnings" else "completed"
      reason <- if (zero_events) {
        "No operational detection events were available; the summary is empty."
      } else {
        NULL
      }
      list(
        record = module_record(
          "coarse_day_night",
          status,
          c("identified physical-location events", "flash or usable clock evidence"),
          "physical_location",
          reason,
          "Coarse day/night categories do not imply fine-scale diel timing.",
          list(table = stage_relative_path(path, root))
        ),
        outputs = list(coarse_day_night = path)
      )
    }
  )
  records[[length(records) + 1L]] <- day_night$record
  outputs <- c(outputs, day_night$outputs)

  physical_locations <- unique(events$events_per_day$site)
  accumulation <- if (length(physical_locations) < 2L) {
    list(
      record = module_record(
        "species_accumulation",
        "omitted",
        c("events from at least two physical locations"),
        "physical_location",
        "Fewer than two physical locations had operational detection events.",
        "Sampling accumulation is not an unseen-richness estimate."
      ),
      outputs = list()
    )
  } else {
    attempt_module(
      "species_accumulation",
      c("events from at least two physical locations"),
      "physical_location",
      "Sampling accumulation is not an unseen-richness estimate.",
      function() {
        table <- compute_species_accumulation(events$events_per_day)
        table_path <- write_stage_csv(
          table,
          file.path(root, "tables", "species_accumulation.csv")
        )
        plot_path <- plot_species_accumulation(
          table,
          file.path(root, "figures", "species_accumulation.png")
        )
        relative <- list(
          table = stage_relative_path(table_path, root),
          figure = stage_relative_path(plot_path, root)
        )
        list(
          record = module_record(
            "species_accumulation",
            "completed",
            c("events from at least two physical locations"),
            "physical_location",
            claim_limit = "Sampling accumulation is not an unseen-richness estimate.",
            outputs = relative
          ),
          outputs = list(
            species_accumulation = table_path,
            species_accumulation_plot = plot_path
          )
        )
      }
    )
  }
  records[[length(records) + 1L]] <- accumulation$record
  outputs <- c(outputs, accumulation$outputs)

  site <- validation$state$inputs$site
  coordinates_available <- all(c("lat", "lon") %in% names(site)) &&
    any(!is.na(suppressWarnings(as.numeric(site$lat))) &
          !is.na(suppressWarnings(as.numeric(site$lon))))
  point_map <- if (!coordinates_available) {
    list(
      record = module_record(
        "point_map",
        "omitted",
        c("physical-location coordinates"),
        "physical_location",
        "No usable physical-location coordinates were supplied.",
        "The map shows supplied points only and does not interpolate a surface."
      ),
      outputs = list()
    )
  } else {
    attempt_module(
      "point_map",
      c("physical-location coordinates"),
      "physical_location",
      "The map shows supplied points only and does not interpolate a surface.",
      function() {
        path <- plot_physical_location_map(
          site,
          file.path(root, "figures", "physical_location_map.png"),
          membership = foundation$selected$membership,
          label_locations = config$map$label_locations
        )
        list(
          record = module_record(
            "point_map",
            "completed",
            c("physical-location coordinates"),
            "physical_location",
            claim_limit = paste(
              "The map shows supplied points only and does not interpolate",
              "a surface."
            ),
            outputs = list(figure = stage_relative_path(path, root))
          ),
          outputs = list(point_map = path)
        )
      }
    )
  }
  records[[length(records) + 1L]] <- point_map$record
  outputs <- c(outputs, point_map$outputs)

  sensitivity <- attempt_module(
    "event_gap_sensitivity",
    c("effort-filtered observations", "candidate event-gap thresholds"),
    "physical_location",
    "This diagnostic describes dependence on the event-gap rule.",
    function() {
      table <- compute_event_gap_sensitivity(
        events$event_lineage$obs_filtered,
        events$trap_nights,
        config$sensitivity$event_threshold_minutes,
        config$timezone,
        config$timezone_fixed_offset_hours
      )
      table_path <- write_stage_csv(
        table,
        file.path(root, "tables", "event_gap_sensitivity.csv")
      )
      plot_path <- plot_event_gap_sensitivity(
        table,
        file.path(root, "figures", "event_gap_sensitivity.png")
      )
      status <- if (zero_events) "completed_with_warnings" else "completed"
      reason <- if (zero_events) {
        "No operational events were formed at the configured thresholds."
      } else {
        NULL
      }
      list(
        record = module_record(
          "event_gap_sensitivity",
          status,
          c("effort-filtered observations", "candidate event-gap thresholds"),
          "physical_location",
          reason,
          "This diagnostic describes dependence on the event-gap rule.",
          list(
            table = stage_relative_path(table_path, root),
            figure = stage_relative_path(plot_path, root)
          )
        ),
        outputs = list(
          event_gap_sensitivity = table_path,
          event_gap_sensitivity_plot = plot_path
        )
      )
    }
  )
  records[[length(records) + 1L]] <- sensitivity$record
  outputs <- c(outputs, sensitivity$outputs)

  status_document <- list(
    module_status_set_schema = "camtrap-module-status-set/2.0",
    run_id = ingest$run$run_id,
    records = records
  )
  status_path <- file.path(root, "results", "module_status.json")
  atomic_write_json(status_document, status_path)
  stage_record(
    "modules",
    events = events,
    records = records,
    outputs = outputs,
    module_status = status_path
  )
}

run_report_stage <- function(modules) {
  stopifnot(identical(modules$stage, "modules"))
  events <- modules$events
  ingest <- events$foundation$validation$ingest
  root <- ingest$request$staging_dir
  report_dir <- file.path(root, "report")
  dir.create(report_dir, recursive = TRUE, showWarnings = FALSE)
  input_path <- file.path(report_dir, "report_inputs.rds")
  saveRDS(list(
    run_id = ingest$run$run_id,
    resolution = events$foundation$selected$summary$resolution,
    scheme_id = events$foundation$selected$summary$scheme_id,
    scheme_version = events$foundation$selected$summary$scheme_version,
    physical_location_count = events$foundation$selected$summary$physical_location_count,
    analysis_unit_count = events$foundation$selected$summary$analysis_unit_count,
    operation_state_counts = events$foundation$selected$summary$operation_state_counts,
    event_count = nrow(events$physical_events),
    source_membership_count = nrow(events$event_lineage$memberships),
    module_status = modules$records,
    outputs = lapply(modules$outputs, stage_relative_path, root = root)
  ), input_path)
  report_path <- file.path(report_dir, "report.html")
  report_source <- file.path(report_dir, "report.qmd")
  if (!file.copy(
    file.path(ingest$request$project_root, "analysis", "report.qmd"),
    report_source
  )) {
    stop("Could not stage the ecological report source.")
  }
  old_working_directory <- setwd(report_dir)
  on.exit(setwd(old_working_directory), add = TRUE)
  status <- system2("quarto", c(
    "render", basename(report_source),
    "--to", "html",
    "--output", basename(report_path),
    "-P", paste0("inputs_path:", input_path)
  ))
  if (!identical(status, 0L) || !file.exists(report_path)) {
    stop("Concise HTML ecological report rendering failed.")
  }
  stage_record(
    "report",
    modules = modules,
    report = report_path,
    report_inputs = input_path
  )
}

run_bundle_stage <- function(report) {
  stopifnot(identical(report$stage, "report"))
  modules <- report$modules
  ingest <- modules$events$foundation$validation$ingest
  root <- ingest$request$staging_dir
  failed <- vapply(
    modules$records,
    function(record) identical(record$status, "failed"),
    logical(1)
  )
  if (any(failed)) {
    stop(
      "Failed ecological module(s) block publication: ",
      paste(vapply(modules$records[failed], `[[`, character(1), "module"),
            collapse = ", ")
    )
  }
  session_path <- file.path(root, "provenance", "session_info.txt")
  writeLines(capture.output(sessionInfo()), session_path)
  manifest <- write_current_manifest(report, session_path)
  verify_current_bundle(root, require_ready = FALSE)
  atomic_replace_text("verified", file.path(root, "READY"))
  final <- publish_current_bundle(
    root,
    ingest$request$outputs_root,
    ingest$run$run_id
  )
  stage_record(
    "publish",
    run_id = ingest$run$run_id,
    bundle = final,
    manifest = file.path(final, basename(manifest)),
    latest = latest_pointer_path(ingest$request$outputs_root)
  )
}
