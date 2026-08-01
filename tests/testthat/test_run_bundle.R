import::from(
  "testthat",
  test_that,
  expect_equal,
  expect_error,
  expect_false,
  expect_null,
  expect_true
)
import::from("here", here)

source(here("R", "config_identity.R"))
source(here("R", "fixity.R"))
source(here("R", "run_identity.R"))
source(here("R", "config.R"))
source(here("R", "entity_resolution.R"))
source(here("R", "source_inventory.R"))
source(here("R", "custom_funcs.R"))
source(here("R", "qc_schema.R"))
source(here("R", "camtrapdp_adapter.R"))
source(here("R", "input_loader.R"))
source(here("R", "source_row_lineage.R"))
source(here("R", "repair_ledger.R"))
source(here("R", "event_outputs.R"))
source(here("R", "selected_resolution.R"))
source(here("R", "validation_ledger.R"))
source(here("R", "alpha_diversity.R"))
source(here("R", "beta_diversity.R"))
source(here("R", "community_matrices.R"))
source(here("R", "run_bundle.R"))
source(here("R", "run_manifest.R"))
source(here("scripts", "run_full_evidence_run.R"))

goal005_bundle_stage <- function(outputs_root, run_id) {
  stage <- file.path(outputs_root, "runs", ".staging", run_id)
  dir.create(file.path(stage, "report"), recursive = TRUE)
  dir.create(file.path(stage, "exports"), recursive = TRUE)
  dir.create(file.path(stage, "provenance"), recursive = TRUE)
  dir.create(file.path(stage, "source_snapshot", "four_table"), recursive = TRUE)

  raw_config <- file.path(stage, "provenance", "config.raw.yml")
  legacy_config <- yaml::read_yaml(here("config.template_example.yml"))
  legacy_config$analysis_unit <- NULL
  yaml::write_yaml(legacy_config, raw_config)
  config <- read_config(raw_config, attach_runtime = FALSE)
  source_file <- file.path(stage, "source_snapshot", "four_table", "obs.csv")
  writeLines("site,species\nsite1,sp1", source_file)
  source_records <- list(file_fixity_record(
    source_file,
    stage,
    role = "parser_input",
    consumed = TRUE
  ))
  source_sha256 <- fixity_identity(source_records)
  engine <- list(
    engine_schema = "camtrap-engine-identity/1.0",
    git_commit = "abc123",
    git_dirty = FALSE,
    git_status = character(),
    git_diff_sha256 = sha256_text(""),
    r_version = R.version.string,
    platform = R.version$platform,
    package_versions = list(list(package = "targets", version = "1.0.0")),
    files = list(list(
      path = "_targets.R",
      bytes = 1,
      sha256 = paste(rep("a", 64L), collapse = "")
    ))
  )
  engine$engine_sha256 <- engine_identity_fingerprint(engine)
  config_hashes <- config_fingerprints(raw_config, config)
  fingerprints <- list(
    source = source_sha256,
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
    supported_full_run = TRUE,
    run_id = run_id,
    created_utc = "2026-07-23T12:34:56Z",
    legacy_run_label = config$run_id,
    config_file = raw_config,
    config_source_name = "config.template_example.yml",
    fingerprints = fingerprints,
    engine = engine,
    provenance = list(
      raw_config = raw_config,
      effective_config = file.path(stage, "provenance", "effective_config.json"),
      source_inventory = file.path(stage, "provenance", "source_inventory.json")
    )
  )
  snapshot <- list(
    source_sha256 = source_sha256,
    acquisition = list(
      input_mode = "four_table",
      acquisition_mode = "local",
      cache_policy = "not-applicable"
    ),
    inventory = source_records
  )
  write_source_inventory(
    snapshot,
    run_id,
    context$provenance$source_inventory
  )
  write_effective_config(
    config,
    context,
    context$provenance$effective_config
  )

  writeLines(paste("report", run_id), file.path(stage, "report", "report.html"))
  saveRDS(
    list(params = list(evidence_run = list(id = run_id))),
    file.path(stage, "report", "report_inputs.rds")
  )
  writeLines("export", file.path(stage, "exports", "data.csv"))
  write_run_manifest(
    path = file.path(stage, "run_manifest.json"),
    schema_version = "0.1.0",
    params = config,
    outputs = list(
      report = list(html = file.path(stage, "report", "report.html")),
      exports = list(data = file.path(stage, "exports", "data.csv"))
    ),
    session_info_path = file.path(stage, "report", "report_inputs.rds"),
    config_file = raw_config,
    context = context
  )
  stage
}

goal005_reclose_bundle <- function(bundle) {
  manifest_file <- manifest_path(bundle)
  manifest <- jsonlite::read_json(manifest_file, simplifyVector = FALSE)
  manifest$payload <- payload_inventory(bundle)
  jsonlite::write_json(
    manifest,
    manifest_file,
    pretty = TRUE,
    auto_unbox = TRUE,
    null = "null",
    na = "null",
    digits = NA
  )

  completion_file <- completion_path(bundle)
  completion <- jsonlite::read_json(completion_file, simplifyVector = FALSE)
  completion$manifest_sha256 <- sha256_file(manifest_file)
  jsonlite::write_json(
    completion,
    completion_file,
    pretty = TRUE,
    auto_unbox = TRUE,
    null = "null",
    na = "null",
    digits = NA
  )
  invisible(bundle)
}

goal007_reclose_source_identity <- function(bundle) {
  source_path <- file.path(bundle, "provenance", "source_inventory.json")
  source <- jsonlite::read_json(source_path, simplifyVector = FALSE)
  source$files <- source$files[order(
    vapply(source$files, `[[`, character(1), "path"),
    method = "radix"
  )]
  source$source_sha256 <- fixity_identity(source$files)
  jsonlite::write_json(
    source,
    source_path,
    pretty = TRUE,
    auto_unbox = TRUE,
    null = "null",
    na = "null",
    digits = NA
  )

  manifest_file <- manifest_path(bundle)
  manifest <- jsonlite::read_json(manifest_file, simplifyVector = FALSE)
  manifest$fingerprints$source <- source$source_sha256
  manifest$fingerprints$composite <- composite_fingerprint(
    manifest$fingerprints$source,
    manifest$fingerprints$config$resolved,
    manifest$fingerprints$engine
  )
  jsonlite::write_json(
    manifest,
    manifest_file,
    pretty = TRUE,
    auto_unbox = TRUE,
    null = "null",
    na = "null",
    digits = NA
  )

  effective_path <- file.path(bundle, "provenance", "effective_config.json")
  effective <- jsonlite::read_json(effective_path, simplifyVector = FALSE)
  effective$config$evidence_run$source_sha256 <- source$source_sha256
  effective$config$evidence_run$composite_sha256 <-
    manifest$fingerprints$composite
  jsonlite::write_json(
    effective,
    effective_path,
    pretty = TRUE,
    auto_unbox = TRUE,
    null = "null",
    na = "null",
    digits = NA
  )
  goal005_reclose_bundle(bundle)
}

goal006_bundle_stage <- function(
    outputs_root,
    run_id,
    include_entity = FALSE,
    goal008 = FALSE,
    goal009 = NULL,
    preview_only = FALSE) {
  if (!is.null(goal009)) {
    goal009 <- match.arg(goal009, c("eligible", "ineligible"))
  }
  if (isTRUE(goal008)) {
    config <- read_config(here("config.yml"), attach_runtime = FALSE)
    config$analysis_unit <- NULL
    config$analysis_unit_resolved <- NULL
    config$deployment_evidence <- list(
      profile_id = "judbury-deployment-evidence/1.0.0-proposed",
      service_sidecar_path = "data/jc_services.csv",
      service_sidecar_sha256 =
        "f33eeac9d70126966717c8e3f4731c00a97cbc3a34c2f44ce5c70d91c7d5283a",
      deployment_ledger_path =
        "docs/goals/008-judbury-deployment-evidence/judbury_deployment_ledger.csv",
      deployment_ledger_sha256 =
        "0921eb8845c2bb1ad5760271f283ab2783735b7739e254c67e9243bc906f3ebf",
      authority_reference = paste0(
        "goal008-judbury-deployment-evidence-source-sha256-",
        "f33eeac9d70126966717c8e3f4731c00a97cbc3a34c2f44ce5c70d91c7d5283a-",
        "ledger-sha256-",
        "0921eb8845c2bb1ad5760271f283ab2783735b7739e254c67e9243bc906f3ebf"
      )
    )
    include_entity <- TRUE
  } else {
    fixture <- here(
      "tests",
      "testthat",
      "fixtures",
      "goal006",
      "four_table_clean"
    )
    source_root <- tempfile("goal006-bundle-input-")
    fs::dir_copy(fixture, source_root)
    config <- default_config()
    config$schema_version_path <- here("schema_version.txt")
    config$timezone_fixed_offset_hours <- 10
    config$paths$inputs <- list(
      site = file.path(source_root, "site.csv"),
      op = file.path(source_root, "op.csv"),
      obs = file.path(source_root, "obs.csv"),
      taxa = file.path(source_root, "taxa.csv"),
      camtrapdp = NULL
    )
    config$entity_resolution <- entity_null_selection()
    config$deployment_evidence <- list(
      profile_id = NULL,
      service_sidecar_path = NULL,
      service_sidecar_sha256 = NULL,
      deployment_ledger_path = NULL,
      deployment_ledger_sha256 = NULL,
      authority_reference = NULL
    )
    if (!is.null(goal009)) {
      config$analysis_unit <- list(
        resolution = if (identical(goal009, "eligible")) {
          "physical_location"
        } else {
          "nominal_station"
        },
        mapping_profile_id = NULL,
        mapping_path = NULL,
        mapping_sha256 = NULL,
        authority_reference = NULL
      )
      include_entity <- TRUE
    }
  }
  config$paths$outputs <- outputs_root
  config_path <- tempfile("goal006-bundle-config-", fileext = ".yml")
  yaml::write_yaml(config, config_path)

  run_full_evidence_run(
    config_path = config_path,
    run_id = run_id,
    validation_only = TRUE,
    project_root = here()
  )
  preview <- file.path(outputs_root, "preflight", run_id)
  preview_record <- jsonlite::read_json(
    preflight_record_path(preview),
    simplifyVector = FALSE
  )
  if (isTRUE(preview_only)) {
    return(preview)
  }
  stage <- file.path(outputs_root, "runs", ".staging", run_id)
  dir.create(dirname(stage), recursive = TRUE, showWarnings = FALSE)
  if (!file.rename(preview, stage)) {
    stop("Could not convert fixture preview to a bundle stage.")
  }
  unlink(preflight_record_path(stage))

  raw_config <- file.path(stage, preview_record$config$raw)
  resolved <- read_config(raw_config, attach_runtime = FALSE)
  phase2 <- lapply(preview_record$phase2, function(path) {
    file.path(stage, path)
  })
  entity <- lapply(preview_record$entity_resolution, function(path) {
    file.path(stage, path)
  })
  selected <- if (is.null(preview_record$selected_resolution)) {
    NULL
  } else {
    lapply(preview_record$selected_resolution, function(path) {
      file.path(stage, path)
    })
  }
  if (!isTRUE(include_entity)) {
    unlink(
      file.path(stage, "provenance", "entity_resolution"),
      recursive = TRUE,
      force = TRUE
    )
    entity <- NULL
  }
  context <- list(
    supported_full_run = TRUE,
    run_id = run_id,
    created_utc = preview_record$created_utc,
    legacy_run_label = resolved$run_id,
    config_file = raw_config,
    config_source_name = preview_record$config$source_name,
    fingerprints = preview_record$fingerprints,
    engine = preview_record$engine,
    provenance = list(
      raw_config = raw_config,
      effective_config = file.path(stage, preview_record$config$effective),
      source_inventory = file.path(stage, preview_record$source_inventory)
    )
  )
  selected_state <- selected_outputs <- NULL
  if (!is.null(selected)) {
    selected_state <- validate_selected_resolution_artifacts(
      stage,
      unlist(selected, use.names = TRUE),
      require_integrity = FALSE
    )
    event_map <- selected_state$event_map
    event_timezone <- "Australia/Hobart"
    event_time_text <- as.character(event_map$event_time)
    event_time <- as.POSIXct(
      event_time_text,
      format = "%Y-%m-%dT%H:%M:%SZ",
      tz = "UTC"
    )
    event_time_round_trip <- format(
      event_time,
      format = "%Y-%m-%dT%H:%M:%SZ",
      tz = "UTC",
      usetz = FALSE
    )
    if (anyNA(event_time) ||
          !identical(unname(event_time_round_trip), unname(event_time_text))) {
      stop("Goal006 bundle fixture requires canonical UTC event times.")
    }
    event_time_epoch <- as.numeric(event_time)
    attr(event_time, "tzone") <- event_timezone
    if (!identical(as.numeric(event_time), event_time_epoch)) {
      stop("Goal006 bundle fixture display timezone changed event epochs.")
    }
    runtime_events <- data.frame(
      event_id = as.character(event_map$event_id),
      site = as.character(event_map$physical_location_id),
      species = as.character(event_map$species),
      dt = event_time,
      stringsAsFactors = FALSE
    )
    selected_outputs <- write_selected_ecological_outputs(
      selected_state,
      runtime_events,
      stage
    )
    context$selected_resolution <- list(
      artifacts = selected,
      integrity_ok = selected_state$integrity_ok,
      route_eligible = selected_state$route_eligible
    )
  }
  dir.create(file.path(stage, "report"), recursive = TRUE)
  dir.create(file.path(stage, "exports"), recursive = TRUE)
  report <- file.path(stage, "report", "report.html")
  report_inputs <- file.path(stage, "report", "report_inputs.rds")
  export <- file.path(stage, "exports", "data.csv")
  writeLines(paste("report", run_id), report)
  saveRDS(
    list(
      params = list(evidence_run = list(id = run_id)),
      selected_effort_coverage = if (is.null(selected_outputs$effort_coverage)) {
        NULL
      } else {
        readr::read_csv(selected_outputs$effort_coverage, show_col_types = FALSE)
      },
      selected_community_presence = if (is.null(selected_outputs$community_presence)) {
        NULL
      } else {
        readr::read_csv(selected_outputs$community_presence, show_col_types = FALSE)
      },
      selected_observed_richness = if (is.null(selected_outputs$observed_richness)) {
        NULL
      } else {
        readr::read_csv(selected_outputs$observed_richness, show_col_types = FALSE)
      },
      selected_jaccard = if (is.null(selected_outputs$jaccard)) {
        NULL
      } else {
        readr::read_csv(selected_outputs$jaccard, show_col_types = FALSE)
      },
      selected_resolution_status = if (is.null(selected_outputs$status)) {
        NULL
      } else {
        jsonlite::read_json(selected_outputs$status, simplifyVector = FALSE)
      }
    ),
    report_inputs
  )
  writeLines("export", export)
  outputs <- list(
    report = list(html = report),
    exports = list(data = export)
  )
  if (!is.null(selected_outputs)) {
    outputs$tables <- list(
      selected_effort_coverage = selected_outputs$effort_coverage,
      selected_community_presence = selected_outputs$community_presence,
      selected_observed_richness = selected_outputs$observed_richness,
      selected_jaccard = selected_outputs$jaccard,
      selected_resolution_status = selected_outputs$status
    )
  }
  manifest_args <- list(
    path = file.path(stage, "run_manifest.json"),
    schema_version = "0.1.0",
    params = resolved,
    outputs = outputs,
    session_info_path = report_inputs,
    config_file = raw_config,
    context = context,
    phase2 = phase2,
    entity_resolution = entity
  )
  if (!is.null(selected)) {
    manifest_args$selected_resolution <- selected
  }
  do.call(write_run_manifest, manifest_args)
  stage
}

test_that("publication is non-overwriting and identity agrees through latest", {
  root <- tempfile("goal005-output-")
  first_id <- "20260723T123456Z-0000000000000001"
  first_stage <- goal005_bundle_stage(root, first_id)
  final <- publish_run_bundle(first_stage, root, first_id)
  verified <- verify_run_bundle(final)

  expect_true(verified$valid)
  expect_equal(verified$run_id, first_id)
  expect_equal(basename(resolve_latest_bundle(root)), first_id)
  expect_equal(readLines(latest_pointer_path(root)), first_id)

  collision <- goal005_bundle_stage(root, first_id)
  expect_error(
    publish_run_bundle(collision, root, first_id),
    "Refusing to overwrite"
  )
  expect_true(verify_run_bundle(final)$valid)
})

test_that("failure after directory publication preserves the prior latest", {
  root <- tempfile("goal005-output-")
  first_id <- "20260723T123456Z-0000000000000001"
  second_id <- "20260723T123456Z-0000000000000002"
  publish_run_bundle(goal005_bundle_stage(root, first_id), root, first_id)
  pointer_before <- readBin(latest_pointer_path(root), "raw", n = 1000L)

  expect_error(
    publish_run_bundle(
      goal005_bundle_stage(root, second_id),
      root,
      second_id,
      fail_after_publish = TRUE
    ),
    "Injected failure"
  )

  pointer_after <- readBin(latest_pointer_path(root), "raw", n = 1000L)
  expect_equal(pointer_after, pointer_before)
  expect_equal(basename(resolve_latest_bundle(root)), first_id)
  expect_true(verify_run_bundle(file.path(root, "runs", second_id))$valid)
})

test_that("tamper and exact-payload violations fail verification", {
  root <- tempfile("goal005-output-")
  run_id <- "20260723T123456Z-0000000000000001"
  final <- publish_run_bundle(goal005_bundle_stage(root, run_id), root, run_id)

  write("tampered", file.path(final, "report", "report.html"), append = TRUE)
  expect_error(verify_run_bundle(final), "fixity mismatch")

  second_root <- tempfile("goal005-output-")
  second <- "20260723T123456Z-0000000000000002"
  second_final <- publish_run_bundle(
    goal005_bundle_stage(second_root, second),
    second_root,
    second
  )
  writeLines("extra", file.path(second_final, "EXTRA.txt"))
  expect_error(verify_run_bundle(second_final), "payload set mismatch")
})

test_that("checksum-reclosed provenance inconsistencies fail verification", {
  source_root <- tempfile("goal005-output-")
  source_id <- "20260723T123456Z-0000000000000011"
  source_final <- publish_run_bundle(
    goal005_bundle_stage(source_root, source_id),
    source_root,
    source_id
  )
  source_file <- file.path(source_final, "provenance", "source_inventory.json")
  source <- jsonlite::read_json(source_file, simplifyVector = FALSE)
  source$source_sha256 <- paste(rep("0", 64L), collapse = "")
  jsonlite::write_json(source, source_file, pretty = TRUE, auto_unbox = TRUE)
  goal005_reclose_bundle(source_final)
  expect_error(verify_run_bundle(source_final), "Source inventory fingerprint")

  config_root <- tempfile("goal005-output-")
  config_id <- "20260723T123456Z-0000000000000012"
  config_final <- publish_run_bundle(
    goal005_bundle_stage(config_root, config_id),
    config_root,
    config_id
  )
  effective_file <- file.path(config_final, "provenance", "effective_config.json")
  effective <- jsonlite::read_json(effective_file, simplifyVector = FALSE)
  effective$fingerprints$resolved <- paste(rep("0", 64L), collapse = "")
  jsonlite::write_json(
    effective,
    effective_file,
    pretty = TRUE,
    auto_unbox = TRUE,
    null = "null",
    na = "null",
    digits = NA
  )
  goal005_reclose_bundle(config_final)
  expect_error(verify_run_bundle(config_final), "Resolved configuration fingerprint")

  engine_root <- tempfile("goal005-output-")
  engine_id <- "20260723T123456Z-0000000000000013"
  engine_final <- publish_run_bundle(
    goal005_bundle_stage(engine_root, engine_id),
    engine_root,
    engine_id
  )
  engine_manifest_file <- manifest_path(engine_final)
  engine_manifest <- jsonlite::read_json(
    engine_manifest_file,
    simplifyVector = FALSE
  )
  engine_manifest$engine$package_versions[[1]]$version <- "9.9.9"
  jsonlite::write_json(
    engine_manifest,
    engine_manifest_file,
    pretty = TRUE,
    auto_unbox = TRUE
  )
  goal005_reclose_bundle(engine_final)
  expect_error(verify_run_bundle(engine_final), "Engine fingerprint")

  composite_root <- tempfile("goal005-output-")
  composite_id <- "20260723T123456Z-0000000000000014"
  composite_final <- publish_run_bundle(
    goal005_bundle_stage(composite_root, composite_id),
    composite_root,
    composite_id
  )
  effective_file <- file.path(composite_final, "provenance", "effective_config.json")
  effective <- jsonlite::read_json(effective_file, simplifyVector = FALSE)
  changed <- paste(rep("0", 64L), collapse = "")
  effective$config$evidence_run$composite_sha256 <- changed
  jsonlite::write_json(
    effective,
    effective_file,
    pretty = TRUE,
    auto_unbox = TRUE,
    null = "null",
    na = "null",
    digits = NA
  )
  manifest_file <- manifest_path(composite_final)
  manifest <- jsonlite::read_json(manifest_file, simplifyVector = FALSE)
  manifest$fingerprints$composite <- changed
  jsonlite::write_json(manifest, manifest_file, pretty = TRUE, auto_unbox = TRUE)
  goal005_reclose_bundle(composite_final)
  expect_error(verify_run_bundle(composite_final), "Composite fingerprint")
})

test_that("payload files may not be symlinks", {
  root <- tempfile("goal005-output-")
  run_id <- "20260723T123456Z-0000000000000021"
  final <- publish_run_bundle(goal005_bundle_stage(root, run_id), root, run_id)
  report <- file.path(final, "report", "report.html")
  external <- tempfile("goal005-external-report-")
  file.copy(report, external)
  unlink(report)
  expect_true(file.symlink(external, report))
  expect_error(verify_run_bundle(final), "symlink")
})

test_that("latest resolver rejects traversal, separators, symlinks, and unknown IDs", {
  root <- tempfile("goal005-output-")
  run_id <- "20260723T123456Z-0000000000000001"
  final <- publish_run_bundle(goal005_bundle_stage(root, run_id), root, run_id)
  pointer <- latest_pointer_path(root)

  for (invalid in c("/tmp/escape", "../escape", "nested/run", "unknown")) {
    writeLines(invalid, pointer)
    expect_error(resolve_latest_bundle(root))
  }

  unlink(pointer)
  expect_true(file.symlink(final, pointer))
  expect_error(resolve_latest_bundle(root), "symlink")
  unlink(pointer)
  update_latest_pointer(root, run_id)
  expect_equal(resolve_latest_bundle(root), final)
})

test_that("a copied bundle verifies without its repository or original root", {
  root <- tempfile("goal005-output-")
  run_id <- "20260723T123456Z-0000000000000001"
  final <- publish_run_bundle(goal005_bundle_stage(root, run_id), root, run_id)
  portable_root <- tempfile("goal005-portable-")
  dir.create(portable_root)
  copied <- file.path(portable_root, run_id)
  fs::dir_copy(final, copied)

  result <- verify_run_bundle(copied)
  manifest <- jsonlite::read_json(manifest_path(copied), simplifyVector = FALSE)
  paths <- vapply(manifest$payload, `[[`, character(1), "path")

  expect_true(result$valid)
  expect_true(all(c(
    "exports/data.csv",
    "report/report.html",
    "report/report_inputs.rds"
  ) %in% paths))
  expect_false(any(fs::is_absolute_path(paths)))
})

test_that("manifest 1.1 verifies Phase-2 links after portable relocation", {
  root <- tempfile("goal006-output-")
  run_id <- "20260723T123456Z-0000000000000061"
  final <- publish_run_bundle(
    goal006_bundle_stage(root, run_id),
    root,
    run_id
  )
  manifest <- jsonlite::read_json(
    manifest_path(final),
    simplifyVector = FALSE
  )
  verified <- verify_run_bundle(final)

  expect_equal(manifest$manifest_schema, "camtrap-evidence-manifest/1.1")
  expect_true(verified$valid)
  expect_true(all(c(
    "resource_registry",
    "source_row_ledger",
    "validation_findings",
    "transformations",
    "repair_proposals",
    "repair_decisions",
    "repair_applications",
    "changed_fields",
    "event_membership",
    "post_validation",
    "validated_inputs"
  ) %in% names(manifest$phase2)))
  expect_false(any(fs::is_absolute_path(unlist(manifest$phase2))))

  portable_root <- tempfile("goal006-portable-")
  dir.create(portable_root)
  copied <- file.path(portable_root, run_id)
  fs::dir_copy(final, copied)
  expect_true(verify_run_bundle(copied)$valid)
})

test_that("manifest 1.2 verifies entity links and semantic reconstruction portably", {
  root <- tempfile("goal007-output-")
  run_id <- "20260723T123456Z-0000000000000071"
  final <- publish_run_bundle(
    goal006_bundle_stage(root, run_id, include_entity = TRUE),
    root,
    run_id
  )
  manifest <- jsonlite::read_json(
    manifest_path(final),
    simplifyVector = FALSE
  )

  expect_equal(
    manifest$manifest_schema,
    "camtrap-evidence-manifest/1.2"
  )
  expect_equal(
    names(manifest$entity_resolution),
    c(
      "entity_resolution",
      "entity_links",
      "deployment_lineage",
      "entity_resolution_summary",
      "join_readiness"
    )
  )
  expect_equal(
    unlist(manifest$entity_resolution, use.names = TRUE),
    c(
      entity_resolution =
        "provenance/entity_resolution/entity_resolution.csv",
      entity_links = "provenance/entity_resolution/entity_links.csv",
      deployment_lineage =
        "provenance/entity_resolution/deployment_lineage.csv",
      entity_resolution_summary =
        "provenance/entity_resolution/entity_resolution_summary.json",
      join_readiness =
        "provenance/entity_resolution/join_readiness.json"
    )
  )
  readiness <- jsonlite::read_json(
    file.path(final, manifest$entity_resolution$join_readiness),
    simplifyVector = FALSE
  )
  source <- jsonlite::read_json(
    file.path(final, manifest$source_inventory),
    simplifyVector = FALSE
  )
  expect_equal(readiness$source_sha256, source$source_sha256)
  expect_equal(readiness$source_sha256, manifest$fingerprints$source)
  expect_true(verify_run_bundle(final)$valid)

  portable_root <- tempfile("goal007-portable-")
  dir.create(portable_root)
  copied <- file.path(portable_root, run_id)
  fs::dir_copy(final, copied)
  expect_true(verify_run_bundle(copied)$valid)
})

test_that("selected manifest comparison tolerates CSV round-trip drift only", {
  expected <- data.frame(
    analysis_unit_from = "jc_cen",
    analysis_unit_to = "jc_co2",
    jaccard_dissimilarity = 1 - 13 / 21
  )
  csv_path <- tempfile("goal009-jaccard-", fileext = ".csv")
  on.exit(unlink(csv_path), add = TRUE)
  readr::write_csv(expected, csv_path, na = "")
  observed <- utils::read.csv(
    csv_path,
    stringsAsFactors = FALSE,
    check.names = FALSE,
    na.strings = ""
  )

  expect_false(identical(
    observed$jaccard_dissimilarity,
    expected$jaccard_dissimilarity
  ))
  expect_true(selected_manifest_frames_equal(observed, expected))

  observed$jaccard_dissimilarity <-
    observed$jaccard_dissimilarity + 0.01
  expect_false(selected_manifest_frames_equal(observed, expected))
})

test_that("manifest 1.3 verifies eligible and ineligible selected routes portably", {
  expected_selected <- c(
    membership = "provenance/selected_resolution/membership.csv",
    operation = "provenance/selected_resolution/operation.csv",
    event_map = "provenance/selected_resolution/event_map.csv",
    summary = "provenance/selected_resolution/summary.json"
  )
  expected_data <- c(
    selected_effort_coverage = "tables/selected_effort_coverage.csv",
    selected_community_presence = "tables/selected_community_presence.csv",
    selected_observed_richness = "tables/selected_observed_richness.csv",
    selected_jaccard = "tables/selected_jaccard.csv"
  )

  for (index in seq_along(c("eligible", "ineligible"))) {
    mode <- c("eligible", "ineligible")[[index]]
    root <- tempfile(paste0("goal009-", mode, "-"))
    run_id <- paste0(
      "20260801T123456Z-000000000000009",
      index + 2L
    )
    final <- publish_run_bundle(
      goal006_bundle_stage(root, run_id, goal009 = mode),
      root,
      run_id
    )
    manifest <- jsonlite::read_json(
      manifest_path(final),
      simplifyVector = FALSE
    )
    status <- jsonlite::read_json(
      file.path(final, manifest$outputs$tables$selected_resolution_status),
      simplifyVector = FALSE
    )

    expect_equal(
      manifest$manifest_schema,
      "camtrap-evidence-manifest/1.3",
      info = mode
    )
    expect_equal(
      unlist(manifest$selected_resolution, use.names = TRUE),
      expected_selected,
      info = mode
    )
    expect_equal(
      status$selected_resolution_status_schema,
      "camtrap-selected-resolution-status/1.0",
      info = mode
    )
    if (identical(mode, "eligible")) {
      expect_equal(
        unlist(manifest$outputs$tables[names(expected_data)], use.names = TRUE),
        expected_data
      )
      expect_true(status$route_eligible)
    } else {
      for (name in names(expected_data)) {
        expect_null(manifest$outputs$tables[[name]], info = name)
        expect_false(file.exists(file.path(final, expected_data[[name]])))
      }
      expect_false(status$route_eligible)
    }
    expect_true(verify_run_bundle(final)$valid, info = mode)

    portable_root <- tempfile(paste0("goal009-portable-", mode, "-"))
    dir.create(portable_root)
    copied <- file.path(portable_root, run_id)
    fs::dir_copy(final, copied)
    expect_true(verify_run_bundle(copied)$valid, info = mode)
  }
})

test_that("explicit selected modes cannot downgrade preview or manifest schemas", {
  preview_root <- tempfile("goal009-preview-downgrade-")
  preview_id <- "20260801T123456Z-0000000000000096"
  preview <- goal006_bundle_stage(
    preview_root,
    preview_id,
    goal009 = "eligible",
    preview_only = TRUE
  )
  expect_true(verify_preflight_record(preview)$valid)
  preview_path <- preflight_record_path(preview)
  record <- jsonlite::read_json(preview_path, simplifyVector = FALSE)
  record$preview_schema <- "camtrap-validation-preview/1.1"
  record["selected_resolution"] <- list(NULL)
  unlink(
    file.path(preview, "provenance", "selected_resolution"),
    recursive = TRUE,
    force = TRUE
  )
  record$payload <- preflight_payload_inventory(preview)
  unlink(preview_path)
  atomic_write_json(record, preview_path)
  expect_error(
    verify_preflight_record(preview),
    "Explicit analysis_unit selection requires validation preview 1.2"
  )

  manifest_root <- tempfile("goal009-manifest-downgrade-")
  manifest_id <- "20260801T123456Z-0000000000000097"
  final <- publish_run_bundle(
    goal006_bundle_stage(
      manifest_root,
      manifest_id,
      goal009 = "eligible"
    ),
    manifest_root,
    manifest_id
  )
  manifest_file <- manifest_path(final)
  manifest <- jsonlite::read_json(manifest_file, simplifyVector = FALSE)
  manifest$manifest_schema <- "camtrap-evidence-manifest/1.2"
  unlink(manifest_file)
  atomic_write_json(manifest, manifest_file)
  completion_file <- completion_path(final)
  completion <- jsonlite::read_json(completion_file, simplifyVector = FALSE)
  completion$manifest_schema <- "camtrap-evidence-manifest/1.2"
  unlink(completion_file)
  atomic_write_json(completion, completion_file)
  goal005_reclose_bundle(final)
  expect_error(
    verify_run_bundle(final),
    "Explicit analysis_unit selection requires run manifest 1.3"
  )
})

test_that("manifest 1.3 rejects checksum-reclosed selected semantic tampering", {
  root <- tempfile("goal009-tamper-")
  run_id <- "20260801T123456Z-0000000000000095"
  final <- publish_run_bundle(
    goal006_bundle_stage(root, run_id, goal009 = "eligible"),
    root,
    run_id
  )
  manifest <- jsonlite::read_json(manifest_path(final), simplifyVector = FALSE)

  provenance_root <- tempfile("goal009-provenance-tamper-")
  dir.create(provenance_root)
  provenance_copy <- file.path(provenance_root, run_id)
  fs::dir_copy(final, provenance_copy)
  membership_path <- file.path(
    provenance_copy,
    manifest$selected_resolution$membership
  )
  membership <- readr::read_csv(membership_path, show_col_types = FALSE)
  membership$representative_latitude[[1]] <-
    membership$representative_latitude[[1]] + 0.01
  readr::write_csv(membership, membership_path, na = "")
  summary_path <- file.path(provenance_copy, manifest$selected_resolution$summary)
  summary <- jsonlite::read_json(summary_path, simplifyVector = FALSE)
  summary$artifact_sha256$membership <- sha256_file(membership_path)
  unlink(summary_path)
  atomic_write_json(summary, summary_path)
  goal005_reclose_bundle(provenance_copy)
  expect_error(
    verify_run_bundle(provenance_copy),
    "Selected-resolution artifacts do not reconstruct"
  )

  status_root <- tempfile("goal009-status-tamper-")
  dir.create(status_root)
  status_copy <- file.path(status_root, run_id)
  fs::dir_copy(final, status_copy)
  status_path <- file.path(
    status_copy,
    manifest$outputs$tables$selected_resolution_status
  )
  status <- jsonlite::read_json(status_path, simplifyVector = FALSE)
  status$status <- "ineligible"
  status$route_eligible <- FALSE
  unlink(status_path)
  atomic_write_json(status, status_path)
  goal005_reclose_bundle(status_copy)
  expect_error(
    verify_run_bundle(status_copy),
    "Selected-resolution status does not reconstruct"
  )

  link_root <- tempfile("goal009-link-tamper-")
  dir.create(link_root)
  link_copy <- file.path(link_root, run_id)
  fs::dir_copy(final, link_copy)
  link_manifest_path <- manifest_path(link_copy)
  link_manifest <- jsonlite::read_json(
    link_manifest_path,
    simplifyVector = FALSE
  )
  link_manifest$outputs$tables["selected_jaccard"] <- list(NULL)
  unlink(link_manifest_path)
  atomic_write_json(link_manifest, link_manifest_path)
  goal005_reclose_bundle(link_copy)
  expect_error(
    verify_run_bundle(link_copy),
    "Selected ecological output links do not match route eligibility"
  )

  output_root <- tempfile("goal009-output-tamper-")
  dir.create(output_root)
  output_copy <- file.path(output_root, run_id)
  fs::dir_copy(final, output_copy)
  richness_path <- file.path(
    output_copy,
    manifest$outputs$tables$selected_observed_richness
  )
  richness <- readr::read_csv(richness_path, show_col_types = FALSE)
  richness$observed_richness[[1]] <- richness$observed_richness[[1]] + 1L
  readr::write_csv(richness, richness_path, na = "")
  goal005_reclose_bundle(output_copy)
  expect_error(
    verify_run_bundle(output_copy),
    "Selected ecological output does not reconstruct: observed_richness"
  )
})

test_that("Goal 008 bundle reconstructs portably and rejects reclosed source evidence", {
  root <- tempfile("goal008-output-")
  run_id <- "20260727T123456Z-0000000000000081"
  final <- publish_run_bundle(
    goal006_bundle_stage(
      root,
      run_id,
      include_entity = TRUE,
      goal008 = TRUE
    ),
    root,
    run_id
  )
  manifest <- jsonlite::read_json(
    manifest_path(final),
    simplifyVector = FALSE
  )
  source <- jsonlite::read_json(
    file.path(final, manifest$source_inventory),
    simplifyVector = FALSE
  )
  roles <- vapply(source$files, `[[`, character(1), "role")
  lineage <- read_entity_csv(file.path(
    final,
    manifest$entity_resolution$deployment_lineage
  ))

  expect_equal(
    sort(roles[grepl("^deployment_", roles)]),
    c("deployment_ledger_input", "deployment_service_input")
  )
  expect_equal(nrow(lineage), 13L)
  expect_equal(
    unique(lineage$deployment_record_schema),
    "camtrap-deployment-lineage/1.1"
  )
  expect_true(verify_run_bundle(final)$valid)

  portable_root <- tempfile("goal008-portable-")
  dir.create(portable_root)
  copied <- file.path(portable_root, run_id)
  fs::dir_copy(final, copied)
  expect_true(verify_run_bundle(copied)$valid)
  if (!any(roles == "deployment_service_input")) {
    return(invisible(NULL))
  }

  service_path <- file.path(
    copied,
    source$files[[which(roles == "deployment_service_input")]]$path
  )
  service_text <- readLines(service_path)
  service_text[[2]] <- sub(
    "14/10/2019",
    "13/10/2019",
    service_text[[2]],
    fixed = TRUE
  )
  writeLines(service_text, service_path)
  source_path <- file.path(copied, manifest$source_inventory)
  copied_source <- jsonlite::read_json(source_path, simplifyVector = FALSE)
  copied_roles <- vapply(copied_source$files, `[[`, character(1), "role")
  service_index <- which(copied_roles == "deployment_service_input")
  copied_source$files[[service_index]] <- file_fixity_record(
    service_path,
    copied,
    role = "deployment_service_input",
    consumed = FALSE
  )
  jsonlite::write_json(
    copied_source,
    source_path,
    pretty = TRUE,
    auto_unbox = TRUE,
    null = "null",
    na = "null",
    digits = NA
  )
  goal007_reclose_source_identity(copied)
  expect_error(
    verify_run_bundle(copied),
    "deployment service.*authority|approved SHA-256"
  )
})

test_that("checksum-reclosed Goal 008 event digest fails semantic reconstruction", {
  root <- tempfile("goal008-lineage-output-")
  run_id <- "20260727T123456Z-0000000000000082"
  final <- publish_run_bundle(
    goal006_bundle_stage(
      root,
      run_id,
      include_entity = TRUE,
      goal008 = TRUE
    ),
    root,
    run_id
  )
  manifest <- jsonlite::read_json(
    manifest_path(final),
    simplifyVector = FALSE
  )
  paths <- lapply(manifest$entity_resolution, function(path) {
    file.path(final, path)
  })
  lineage <- read_entity_csv(paths$deployment_lineage)
  expect_equal(nrow(lineage), 13L)
  if (nrow(lineage) == 0L) {
    return(invisible(NULL))
  }
  lineage$service_event_digest[[1]] <- paste(rep("0", 64L), collapse = "")
  content <- as.list(
    lineage[1, setdiff(names(lineage), "record_digest"), drop = FALSE]
  )
  content <- lapply(content, function(value) {
    if (length(value) == 1L && is.na(value)) NA_character_ else as.character(value)
  })
  lineage$record_digest[[1]] <- sha256_text(canonical_json(content))
  unlink(paths$deployment_lineage)
  readr::write_csv(lineage, paths$deployment_lineage, na = "")

  records <- read_entity_csv(paths$entity_resolution)
  links <- read_entity_csv(paths$entity_links)
  entity_digest <- sha256_text(canonical_json(list(
    records = records,
    links = links,
    deployment_lineage = lineage
  )))
  summary <- jsonlite::read_json(
    paths$entity_resolution_summary,
    simplifyVector = FALSE
  )
  summary$ledger_content_sha256 <- entity_digest
  summary$ledger_sha256$deployment_lineage <-
    sha256_file(paths$deployment_lineage)
  unlink(paths$entity_resolution_summary)
  atomic_write_json(summary, paths$entity_resolution_summary)
  readiness <- jsonlite::read_json(paths$join_readiness, simplifyVector = FALSE)
  readiness$entity_ledger_digest <- entity_digest
  unlink(paths$join_readiness)
  atomic_write_json(readiness, paths$join_readiness)
  goal005_reclose_bundle(final)

  expect_error(
    verify_run_bundle(final),
    "does not reproduce from immutable source"
  )
})

test_that("reclosed undeclared sidecar and entity namespace extra fail", {
  source_root <- tempfile("goal007-undeclared-source-")
  source_id <- "20260723T123456Z-0000000000000073"
  source_final <- publish_run_bundle(
    goal006_bundle_stage(source_root, source_id, include_entity = TRUE),
    source_root,
    source_id
  )
  undeclared <- file.path(
    source_final,
    "source_snapshot",
    "entity_resolution",
    "undeclared.csv"
  )
  dir.create(dirname(undeclared), recursive = TRUE)
  writeLines("undeclared", undeclared)
  source_path <- file.path(
    source_final,
    "provenance",
    "source_inventory.json"
  )
  source <- jsonlite::read_json(source_path, simplifyVector = FALSE)
  source$files[[length(source$files) + 1L]] <- file_fixity_record(
    undeclared,
    source_final,
    role = "entity_resolution_input",
    consumed = FALSE
  )
  jsonlite::write_json(
    source,
    source_path,
    pretty = TRUE,
    auto_unbox = TRUE,
    null = "null",
    na = "null",
    digits = NA
  )
  goal007_reclose_source_identity(source_final)
  expect_error(
    verify_run_bundle(source_final),
    "explicit null.*zero entity-resolution sidecars"
  )

  namespace_root <- tempfile("goal007-namespace-")
  namespace_id <- "20260723T123456Z-0000000000000074"
  namespace_final <- publish_run_bundle(
    goal006_bundle_stage(namespace_root, namespace_id, include_entity = TRUE),
    namespace_root,
    namespace_id
  )
  writeLines(
    "extra",
    file.path(
      namespace_final,
      "provenance",
      "entity_resolution",
      "extra.txt"
    )
  )
  goal005_reclose_bundle(namespace_final)
  expect_error(
    verify_run_bundle(namespace_final),
    "canonical five-file namespace"
  )
})

test_that("checksum-reclosed entity evidence mutation fails reconstruction", {
  root <- tempfile("goal007-output-")
  run_id <- "20260723T123456Z-0000000000000072"
  final <- publish_run_bundle(
    goal006_bundle_stage(root, run_id, include_entity = TRUE),
    root,
    run_id
  )
  manifest <- jsonlite::read_json(
    manifest_path(final),
    simplifyVector = FALSE
  )
  entity_path <- file.path(
    final,
    manifest$entity_resolution$entity_resolution
  )
  records <- read_entity_csv(entity_path)
  records$source_identifier[[1]] <- "forged-identity"
  content <- as.list(records[1, setdiff(names(records), "record_digest"), drop = FALSE])
  content <- lapply(content, function(value) {
    if (length(value) == 1L && is.na(value)) NA_character_ else as.character(value)
  })
  records$record_digest[[1]] <- sha256_text(canonical_json(content))
  unlink(entity_path)
  readr::write_csv(records, entity_path, na = "")

  summary_path <- file.path(
    final,
    manifest$entity_resolution$entity_resolution_summary
  )
  summary <- jsonlite::read_json(summary_path, simplifyVector = FALSE)
  summary$ledger_sha256$entity_resolution <- sha256_file(entity_path)
  unlink(summary_path)
  atomic_write_json(summary, summary_path)
  goal005_reclose_bundle(final)

  expect_error(
    verify_run_bundle(final),
    "does not reproduce from immutable source"
  )
})

test_that("checksum-reclosed Phase-2 schema tamper fails for every ledger", {
  root <- tempfile("goal006-output-")
  run_id <- "20260723T123456Z-0000000000000062"
  final <- publish_run_bundle(
    goal006_bundle_stage(root, run_id),
    root,
    run_id
  )
  manifest <- jsonlite::read_json(
    manifest_path(final),
    simplifyVector = FALSE
  )
  schema_fields <- c(
    resource_registry = "resource_registry_schema",
    source_row_ledger = "source_row_ledger_schema",
    validation_findings = "validation_findings_schema",
    transformations = "transformations_schema",
    repair_proposals = "repair_proposals_schema",
    repair_decisions = "repair_decisions_schema",
    repair_applications = "repair_applications_schema",
    changed_fields = "changed_fields_schema",
    event_membership = "event_membership_schema",
    post_validation = "post_validation_schema"
  )

  for (name in names(schema_fields)) {
    copy_root <- tempfile(paste0("goal006-schema-", name, "-"))
    dir.create(copy_root)
    copied <- file.path(copy_root, run_id)
    fs::dir_copy(final, copied)
    path <- file.path(copied, manifest$phase2[[name]])
    document <- jsonlite::read_json(path, simplifyVector = FALSE)
    document[[schema_fields[[name]]]] <- "camtrap-unsupported/9.9"
    unlink(path)
    atomic_write_json(document, path)
    goal005_reclose_bundle(copied)
    expect_error(
      verify_run_bundle(copied),
      paste0("Unsupported Phase-2 artifact schema: ", name),
      info = name
    )
  }
})

test_that("Phase-2 removal, fixity tamper, and semantic reclosure fail", {
  root <- tempfile("goal006-output-")
  run_id <- "20260723T123456Z-0000000000000063"
  final <- publish_run_bundle(
    goal006_bundle_stage(root, run_id),
    root,
    run_id
  )
  manifest <- jsonlite::read_json(
    manifest_path(final),
    simplifyVector = FALSE
  )

  removed_root <- tempfile("goal006-removed-")
  dir.create(removed_root)
  removed <- file.path(removed_root, run_id)
  fs::dir_copy(final, removed)
  unlink(file.path(removed, manifest$phase2$repair_decisions))
  expect_error(verify_run_bundle(removed), "payload set mismatch")

  altered_root <- tempfile("goal006-altered-")
  dir.create(altered_root)
  altered <- file.path(altered_root, run_id)
  fs::dir_copy(final, altered)
  write(
    "tampered",
    file.path(altered, manifest$phase2$validation_findings),
    append = TRUE
  )
  expect_error(verify_run_bundle(altered), "fixity mismatch")

  orphan_root <- tempfile("goal006-orphan-")
  dir.create(orphan_root)
  orphan <- file.path(orphan_root, run_id)
  fs::dir_copy(final, orphan)
  membership_path <- file.path(orphan, manifest$phase2$event_membership)
  membership <- jsonlite::read_json(
    membership_path,
    simplifyVector = FALSE
  )
  membership$records[[1]]$source_row_id <- paste(rep("0", 64L), collapse = "")
  membership$records[[1]]$membership_id <- event_membership_identity(
    membership$records[[1]]$event_id,
    membership$records[[1]]$source_row_id
  )
  unlink(membership_path)
  atomic_write_json(membership, membership_path)
  goal005_reclose_bundle(orphan)
  expect_error(verify_run_bundle(orphan), "Orphan event membership")

  duplicate_root <- tempfile("goal006-duplicate-")
  dir.create(duplicate_root)
  duplicate <- file.path(duplicate_root, run_id)
  fs::dir_copy(final, duplicate)
  resource_path <- file.path(duplicate, manifest$phase2$resource_registry)
  resources <- jsonlite::read_json(resource_path, simplifyVector = FALSE)
  resources$records <- c(resources$records, resources$records[1])
  unlink(resource_path)
  atomic_write_json(resources, resource_path)
  goal005_reclose_bundle(duplicate)
  expect_error(verify_run_bundle(duplicate), "Duplicate logical resource")

  rds_root <- tempfile("goal006-rds-")
  dir.create(rds_root)
  rds_tamper <- file.path(rds_root, run_id)
  fs::dir_copy(final, rds_tamper)
  rds_path <- file.path(rds_tamper, manifest$phase2$validated_inputs)
  inputs <- readRDS(rds_path)
  inputs$obs$.source_row_id <- "forged"
  saveRDS(inputs, rds_path)
  goal005_reclose_bundle(rds_tamper)
  expect_error(verify_run_bundle(rds_tamper), "invalid audit surface")

  value_root <- tempfile("goal006-rds-value-")
  dir.create(value_root)
  value_tamper <- file.path(value_root, run_id)
  fs::dir_copy(final, value_tamper)
  value_path <- file.path(value_tamper, manifest$phase2$validated_inputs)
  inputs <- readRDS(value_path)
  inputs$obs$count[[1]] <- inputs$obs$count[[1]] + 1000
  saveRDS(inputs, value_path)
  goal005_reclose_bundle(value_tamper)
  expect_error(
    verify_run_bundle(value_tamper),
    "Validated analytical inputs do not reproduce"
  )
})

test_that("unknown manifest schema fails explicit dispatch", {
  root <- tempfile("goal006-output-")
  run_id <- "20260723T123456Z-0000000000000064"
  final <- publish_run_bundle(
    goal006_bundle_stage(root, run_id),
    root,
    run_id
  )
  manifest_file <- manifest_path(final)
  manifest <- jsonlite::read_json(manifest_file, simplifyVector = FALSE)
  manifest$manifest_schema <- "camtrap-evidence-manifest/9.9"
  unlink(manifest_file)
  atomic_write_json(manifest, manifest_file)
  goal005_reclose_bundle(final)

  expect_error(
    verify_run_bundle(final),
    "Unsupported run manifest schema: camtrap-evidence-manifest/9.9"
  )
})
