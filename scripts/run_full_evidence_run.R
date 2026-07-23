#!/usr/bin/env Rscript

load_evidence_helpers <- function(project_root) {
  files <- c(
    "R/config_identity.R",
    "R/fixity.R",
    "R/run_identity.R",
    "R/config.R",
    "R/source_inventory.R",
    "R/custom_funcs.R",
    "R/qc_schema.R",
    "R/camtrapdp_adapter.R",
    "R/input_loader.R",
    "R/source_row_lineage.R",
    "R/repair_ledger.R",
    "R/event_outputs.R",
    "R/validation_ledger.R",
    "R/run_bundle.R"
  )
  for (file in files) {
    source(file.path(project_root, file), local = .GlobalEnv)
  }
}

parse_full_run_args <- function(args) {
  config <- "config.yml"
  verify_bundle <- NULL
  validation_only <- FALSE
  index <- 1L
  while (index <= length(args)) {
    argument <- args[[index]]
    if (identical(argument, "--config")) {
      if (index == length(args)) {
        stop("--config requires a path.")
      }
      config <- args[[index + 1L]]
      index <- index + 2L
    } else if (identical(argument, "--verify-bundle")) {
      if (index == length(args)) {
        stop("--verify-bundle requires a path.")
      }
      verify_bundle <- args[[index + 1L]]
      index <- index + 2L
    } else if (identical(argument, "--validate-only")) {
      validation_only <- TRUE
      index <- index + 1L
    } else {
      stop("Unknown argument: ", argument)
    }
  }
  if (!is.null(verify_bundle) && isTRUE(validation_only)) {
    stop("--verify-bundle and --validate-only cannot be combined.")
  }
  list(
    config = config,
    verify_bundle = verify_bundle,
    validation_only = validation_only
  )
}

restore_environment <- function(previous) {
  for (name in names(previous)) {
    value <- previous[[name]]
    if (is.na(value)) {
      Sys.unsetenv(name)
    } else {
      do.call(Sys.setenv, stats::setNames(list(value), name))
    }
  }
}

run_full_evidence_run <- function(
    config_path = "config.yml",
    run_id = NULL,
    validation_only = FALSE,
    clock = Sys.time,
    token = default_run_token,
    fail_at = Sys.getenv("CAMTRAP_TEST_FAIL_AT", unset = ""),
    fetch = default_remote_fetch,
    project_root = here::here()) {
  project_root <- normalizePath(project_root, winslash = "/", mustWork = TRUE)
  old_working_dir <- setwd(project_root)
  on.exit(setwd(old_working_dir), add = TRUE)

  source_config_path <- resolve_project_path(config_path, project_root)
  bootstrap_config_path <- tempfile("camtrap-config-", fileext = ".yml")
  snapshot_config_file(source_config_path, bootstrap_config_path)
  on.exit(unlink(bootstrap_config_path, force = TRUE), add = TRUE)

  resolved_config <- read_config(bootstrap_config_path, attach_runtime = FALSE)
  output_root_path <- resolve_project_path(resolved_config$paths$outputs, project_root)
  run_id <- if (is.null(run_id)) allocate_run_id(clock = clock, token = token) else run_id
  assert_safe_run_id(run_id)

  run_final_dir <- file.path(output_root_path, "runs", run_id)
  preview_final_dir <- file.path(output_root_path, "preflight", run_id)
  staging_dir <- if (isTRUE(validation_only)) {
    file.path(output_root_path, "preflight", ".staging", run_id)
  } else {
    file.path(output_root_path, "runs", ".staging", run_id)
  }
  runtime_path <- file.path(output_root_path, ".runtime", paste0(run_id, ".json"))
  if (file.exists(run_final_dir) || file.exists(preview_final_dir)) {
    stop("Refusing invocation identity collision: ", run_id)
  }
  if (file.exists(staging_dir)) {
    stop("Refusing run ID collision with existing staging directory: ", run_id)
  }

  dir.create(staging_dir, recursive = TRUE, showWarnings = FALSE)
  raw_config_path <- file.path(staging_dir, "provenance", "config.raw.yml")
  snapshot_config_file(bootstrap_config_path, raw_config_path)
  published <- FALSE
  on.exit({
    unlink(runtime_path, force = TRUE)
    if (!published && dir.exists(staging_dir)) {
      unlink(staging_dir, recursive = TRUE, force = TRUE)
    }
  }, add = TRUE)

  snapshot <- materialize_source_snapshot(
    resolved_config,
    staging_dir,
    project_root = project_root,
    fetch = fetch
  )
  snapshot$staging_dir <- staging_dir
  config_hashes <- config_fingerprints(raw_config_path, resolved_config)
  engine <- compute_engine_identity(project_root)
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

  context <- list(
    context_schema = "camtrap-evidence-context/1.0",
    supported_full_run = TRUE,
    execution_mode = if (isTRUE(validation_only)) {
      "validation_only"
    } else {
      "full"
    },
    run_id = run_id,
    legacy_run_label = resolved_config$run_id,
    created_utc = format(clock(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    staging_dir = staging_dir,
    outputs_root = output_root_path,
    config_file = raw_config_path,
    config_source_name = basename(source_config_path),
    snapshot = snapshot,
    engine = engine,
    fingerprints = fingerprints,
    provenance = list(
      source_inventory = file.path(staging_dir, "provenance", "source_inventory.json"),
      raw_config = raw_config_path,
      effective_config = file.path(staging_dir, "provenance", "effective_config.json")
    )
  )

  write_source_inventory(snapshot, run_id, context$provenance$source_inventory)
  write_effective_config(resolved_config, context, context$provenance$effective_config)

  if (identical(fail_at, "after_snapshot")) {
    stop("Injected failure after source snapshot.")
  }

  validation_state <- prepare_validation_preflight(
    resolved_config,
    snapshot,
    four_table_reader = read_jc_csv,
    camtrapdp_reader = read_camtrapdp_dataset,
    camtrapdp_adapter = camtrapdp_to_internal
  )
  validation_artifacts <- write_validation_artifacts(
    validation_state,
    staging_dir
  )
  context$validation <- list(
    validation_schema = "camtrap-validation-context/1.0",
    can_analyze = validation_state$can_analyze,
    artifacts = validation_artifacts,
    validated_inputs_sha256 = sha256_file(
      validation_artifacts$validated_inputs
    )
  )
  dir.create(dirname(runtime_path), recursive = TRUE, showWarnings = FALSE)
  atomic_write_json(context, runtime_path)

  if (identical(fail_at, "after_preflight")) {
    stop("Injected failure after validation preflight.")
  }
  if (isTRUE(validation_only)) {
    final_dir <- publish_preflight_record(
      staging_dir,
      output_root_path,
      run_id
    )
    published <- TRUE
    result <- list(
      mode = "validation_only",
      run_id = run_id,
      preview = final_dir,
      analysis_ready = validation_state$can_analyze,
      fingerprints = fingerprints
    )
    cat(canonical_json(result, pretty = TRUE), "\n")
    if (!isTRUE(validation_state$can_analyze)) {
      stop(
        "Validation preview published but analysis is blocked: ",
        final_dir
      )
    }
    return(invisible(result))
  }
  if (!isTRUE(validation_state$can_analyze)) {
    stop("Validation preflight blocked the full run before analysis.")
  }

  environment_names <- c("CAMTRAP_CONFIG", "CAMTRAP_EVIDENCE_CONTEXT")
  previous <- Sys.getenv(environment_names, unset = NA_character_)
  on.exit(restore_environment(previous), add = TRUE)
  Sys.setenv(
    CAMTRAP_CONFIG = raw_config_path,
    CAMTRAP_EVIDENCE_CONTEXT = runtime_path
  )

  targets::tar_make(callr_function = NULL)
  if (!identical(sha256_file(raw_config_path), fingerprints$config$raw)) {
    stop("Raw configuration snapshot integrity mismatch.")
  }
  verify_source_snapshot(snapshot, staging_dir)
  if (identical(fail_at, "after_pipeline")) {
    stop("Injected failure after pipeline and before bundle publication.")
  }

  manifest <- manifest_path(staging_dir)
  if (!file.exists(manifest)) {
    stop("Full target graph did not produce run_manifest.json.")
  }
  final_dir <- publish_run_bundle(
    staging_dir,
    output_root_path,
    run_id,
    fail_after_publish = identical(fail_at, "after_publish")
  )
  published <- TRUE

  result <- list(
    mode = "full",
    run_id = run_id,
    bundle = final_dir,
    latest = latest_pointer_path(output_root_path),
    fingerprints = fingerprints
  )
  cat(canonical_json(result, pretty = TRUE), "\n")
  invisible(result)
}

main <- function() {
  project_root <- here::here()
  load_evidence_helpers(project_root)
  args <- parse_full_run_args(commandArgs(trailingOnly = TRUE))
  if (!is.null(args$verify_bundle)) {
    result <- verify_run_bundle(args$verify_bundle)
    cat(canonical_json(result, pretty = TRUE), "\n")
  } else {
    run_full_evidence_run(
      config_path = args$config,
      validation_only = args$validation_only,
      project_root = project_root
    )
  }
}

if (sys.nframe() == 0L) {
  main()
}
