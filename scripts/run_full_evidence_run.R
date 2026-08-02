#!/usr/bin/env Rscript

load_runner_helpers <- function(project_root) {
  helpers <- new.env(parent = globalenv())
  files <- c(
    "R/fixity.R",
    "R/config_identity.R",
    "R/config.R",
    "R/run_identity.R",
    "R/source_inventory.R"
  )
  for (file in files) {
    sys.source(file.path(project_root, file), envir = helpers)
  }
  helpers
}

parse_full_run_args <- function(args) {
  config <- "config.yml"
  verify_bundle <- NULL
  validation_only <- FALSE
  index <- 1L
  while (index <= length(args)) {
    argument <- args[[index]]
    if (argument %in% c("--config", "--verify-bundle")) {
      if (index == length(args)) stop(argument, " requires a path.")
      if (identical(argument, "--config")) {
        config <- args[[index + 1L]]
      } else {
        verify_bundle <- args[[index + 1L]]
      }
      index <- index + 2L
    } else if (identical(argument, "--validate-only")) {
      validation_only <- TRUE
      index <- index + 1L
    } else {
      stop("Unknown argument: ", argument)
    }
  }
  if (!is.null(verify_bundle) && validation_only) {
    stop("--verify-bundle and --validate-only cannot be combined.")
  }
  list(
    config = config,
    verify_bundle = verify_bundle,
    validation_only = validation_only
  )
}

publish_validation_preview <- function(
    validation,
    outputs_root,
    run_id,
    helpers) {
  staging <- validation$ingest$request$staging_dir
  record <- list(
    validation_preview_schema = "camtrap-validation-preview/2.0",
    run_id = run_id,
    status = if (isTRUE(validation$state$can_analyze)) "ready" else "blocked",
    can_analyze = isTRUE(validation$state$can_analyze),
    finding_count = as.integer(length(validation$state$findings)),
    proposal_count = as.integer(length(validation$state$proposals)),
    changed_field_count = as.integer(length(validation$state$changed_fields))
  )
  helpers$atomic_write_json(
    record,
    file.path(staging, "validation_preview.json")
  )
  final <- file.path(outputs_root, "preflight", run_id)
  if (file.exists(final)) stop("Validation preview already exists: ", run_id)
  dir.create(dirname(final), recursive = TRUE, showWarnings = FALSE)
  if (!file.rename(staging, final)) {
    stop("Atomic validation-preview publication failed.")
  }
  list(
    mode = "validation_only",
    run_id = run_id,
    preview = final,
    analysis_ready = record$can_analyze
  )
}

run_full_evidence_run <- function(
    config_path = "config.yml",
    run_id = NULL,
    validation_only = FALSE,
    clock = Sys.time,
    token = NULL,
    fetch = NULL,
    project_root = here::here(),
    target_store = NULL,
    reporter = "balanced") {
  project_root <- normalizePath(project_root, winslash = "/", mustWork = TRUE)
  old_working_directory <- setwd(project_root)
  on.exit(setwd(old_working_directory), add = TRUE)
  helpers <- load_runner_helpers(project_root)
  if (is.null(token)) token <- helpers$default_run_token
  if (is.null(fetch)) fetch <- helpers$default_remote_fetch
  config_path <- helpers$resolve_project_path(config_path, project_root)
  bootstrap_config <- helpers$read_config(config_path)
  outputs_root <- helpers$resolve_project_path(
    bootstrap_config$paths$outputs,
    project_root
  )
  dir.create(outputs_root, recursive = TRUE, showWarnings = FALSE)
  outputs_root <- normalizePath(outputs_root, winslash = "/", mustWork = TRUE)
  run_id <- if (is.null(run_id)) {
    helpers$allocate_run_id(clock = clock, token = token)
  } else {
    helpers$assert_safe_run_id(run_id)
  }
  staging <- if (isTRUE(validation_only)) {
    file.path(outputs_root, "preflight", ".staging", run_id)
  } else {
    file.path(outputs_root, "runs", ".staging", run_id)
  }
  target_store <- if (is.null(target_store)) {
    file.path(outputs_root, ".targets-goal011")
  } else {
    normalizePath(target_store, winslash = "/", mustWork = FALSE)
  }
  request <- list(
    request_schema = "camtrap-workflow-request/2.0",
    run_id = run_id,
    created_utc = format(clock(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    config_path = config_path,
    project_root = project_root,
    outputs_root = outputs_root,
    staging_dir = staging,
    target_store = target_store,
    fetch = fetch
  )
  target_environment <- new.env(parent = globalenv())
  target_environment$workflow_request <- request
  published <- FALSE
  on.exit({
    if (!published && dir.exists(staging)) {
      unlink(staging, recursive = TRUE, force = TRUE)
    }
  }, add = TRUE)

  target_name <- if (isTRUE(validation_only)) {
    "validation_stage"
  } else {
    "bundle_stage"
  }
  targets::tar_make(
    names = tidyselect::all_of(target_name),
    reporter = reporter,
    callr_function = NULL,
    envir = target_environment,
    script = file.path(project_root, "_targets.R"),
    store = target_store
  )
  result <- if (isTRUE(validation_only)) {
    validation <- targets::tar_read(validation_stage, store = target_store)
    value <- publish_validation_preview(
      validation,
      outputs_root,
      run_id,
      helpers
    )
    published <- TRUE
    value
  } else {
    bundle <- targets::tar_read(bundle_stage, store = target_store)
    published <- TRUE
    list(
      mode = "full",
      run_id = bundle$run_id,
      bundle = bundle$bundle,
      latest = bundle$latest
    )
  }
  cat(helpers$canonical_json(result, pretty = TRUE), "\n")
  invisible(result)
}

main <- function() {
  project_root <- here::here()
  args <- parse_full_run_args(commandArgs(trailingOnly = TRUE))
  if (!is.null(args$verify_bundle)) {
    status <- system2(
      "Rscript",
      c(
        file.path(project_root, "scripts", "verify_published_bundle.R"),
        args$verify_bundle
      )
    )
    if (!identical(status, 0L)) stop("Independent bundle verification failed.")
  } else {
    run_full_evidence_run(
      config_path = args$config,
      validation_only = args$validation_only,
      project_root = project_root
    )
  }
}

if (sys.nframe() == 0L) main()
