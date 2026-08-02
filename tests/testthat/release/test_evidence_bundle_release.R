import::from(
  "testthat",
  test_that,
  expect_equal,
  expect_error,
  expect_true
)
import::from("here", here)

release_bundle_modules <- c(
  "R/config_identity.R",
  "R/fixity.R",
  "R/run_identity.R",
  "R/config.R",
  "R/entity_resolution.R",
  "R/source_inventory.R",
  "R/custom_funcs.R",
  "R/qc_schema.R",
  "R/camtrapdp_adapter.R",
  "R/input_loader.R",
  "R/source_row_lineage.R",
  "R/repair_ledger.R",
  "R/event_outputs.R",
  "R/selected_resolution.R",
  "R/validation_ledger.R",
  "R/alpha_diversity.R",
  "R/beta_diversity.R",
  "R/community_matrices.R",
  "R/run_bundle.R",
  "R/run_manifest.R"
)
for (module in release_bundle_modules) {
  source(here(module))
}

release_null_deployment <- function() {
  list(
    profile_id = NULL,
    service_sidecar_path = NULL,
    service_sidecar_sha256 = NULL,
    deployment_ledger_path = NULL,
    deployment_ledger_sha256 = NULL,
    authority_reference = NULL
  )
}

release_physical_analysis_unit <- function() {
  list(
    resolution = "physical_location",
    mapping_profile_id = NULL,
    mapping_path = NULL,
    mapping_sha256 = NULL,
    authority_reference = NULL
  )
}

release_current_stage <- function(outputs_root, run_id) {
  source_root <- tempfile("release-four-table-")
  fs::dir_copy(
    here("tests", "testthat", "fixtures", "goal006", "four_table_clean"),
    source_root
  )
  stage <- file.path(outputs_root, "runs", ".staging", run_id)
  dir.create(file.path(stage, "provenance"), recursive = TRUE)

  config <- default_config()
  config$schema_version_path <- here("schema_version.txt")
  config$timezone_fixed_offset_hours <- 10
  config$validation <- list(repair_decisions = list())
  config$paths$inputs <- list(
    site = file.path(source_root, "site.csv"),
    op = file.path(source_root, "op.csv"),
    obs = file.path(source_root, "obs.csv"),
    taxa = file.path(source_root, "taxa.csv"),
    camtrapdp = NULL
  )
  config$paths$outputs <- outputs_root
  config$entity_resolution <- entity_null_selection()
  config$deployment_evidence <- release_null_deployment()
  config$analysis_unit <- release_physical_analysis_unit()
  raw_config <- file.path(stage, "provenance", "config.raw.yml")
  yaml::write_yaml(config, raw_config)
  resolved <- read_config(raw_config, attach_runtime = FALSE)

  snapshot <- materialize_source_snapshot(
    resolved,
    stage,
    project_root = here()
  )
  snapshot$staging_dir <- stage
  config_hashes <- config_fingerprints(raw_config, resolved)
  engine <- compute_engine_identity(here())
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
    execution_mode = "full",
    run_id = run_id,
    legacy_run_label = resolved$run_id,
    created_utc = "2026-08-02T00:00:00Z",
    staging_dir = stage,
    outputs_root = outputs_root,
    config_file = raw_config,
    config_source_name = "release-current.yml",
    snapshot = snapshot,
    engine = engine,
    fingerprints = fingerprints,
    provenance = list(
      source_inventory = file.path(
        stage,
        "provenance",
        "source_inventory.json"
      ),
      raw_config = raw_config,
      effective_config = file.path(
        stage,
        "provenance",
        "effective_config.json"
      )
    )
  )
  write_source_inventory(
    snapshot,
    run_id,
    context$provenance$source_inventory
  )
  write_effective_config(
    resolved,
    context,
    context$provenance$effective_config
  )

  validation <- prepare_validation_preflight(resolved, snapshot)
  if (!isTRUE(validation$can_analyze)) {
    stop("Current release fixture did not pass validation.")
  }
  phase2 <- write_validation_artifacts(validation, stage)
  entity <- resolve_entity_evidence(resolved, snapshot, validation)
  if (!isTRUE(entity$can_analyze)) {
    stop("Current release fixture did not pass entity resolution.")
  }
  entity_artifacts <- write_entity_artifacts(entity, stage)
  selected <- resolve_selected_resolution(
    resolved,
    snapshot,
    validation,
    entity
  )
  if (!isTRUE(selected$integrity_ok) || !isTRUE(selected$route_eligible)) {
    stop("Current release fixture did not pass selected resolution.")
  }
  selected_artifacts <- write_selected_resolution_artifacts(selected, stage)
  selected_outputs <- write_selected_ecological_outputs(
    selected,
    validation$event_lineage$obs_events,
    stage
  )

  dir.create(file.path(stage, "report"), recursive = TRUE)
  dir.create(file.path(stage, "exports"), recursive = TRUE)
  report <- file.path(stage, "report", "report.html")
  report_inputs <- file.path(stage, "report", "report_inputs.rds")
  export <- file.path(stage, "exports", "data.csv")
  writeLines(
    paste0("<html><body>Evidence run ", run_id, "</body></html>"),
    report
  )
  selected_tables <- lapply(
    selected_outputs[c(
      "effort_coverage",
      "community_presence",
      "observed_richness",
      "jaccard"
    )],
    readr::read_csv,
    show_col_types = FALSE
  )
  names(selected_tables) <- c(
    "selected_effort_coverage",
    "selected_community_presence",
    "selected_observed_richness",
    "selected_jaccard"
  )
  saveRDS(
    c(
      list(params = list(evidence_run = list(id = run_id))),
      selected_tables,
      list(selected_resolution_status = jsonlite::read_json(
        selected_outputs$status,
        simplifyVector = FALSE
      ))
    ),
    report_inputs
  )
  writeLines(c("value", "1"), export)

  outputs <- list(
    report = list(html = report),
    exports = list(data = export),
    tables = list(
      selected_effort_coverage = selected_outputs$effort_coverage,
      selected_community_presence = selected_outputs$community_presence,
      selected_observed_richness = selected_outputs$observed_richness,
      selected_jaccard = selected_outputs$jaccard,
      selected_resolution_status = selected_outputs$status
    )
  )
  write_run_manifest(
    path = file.path(stage, "run_manifest.json"),
    schema_version = trimws(readLines(here("schema_version.txt"))[[1L]]),
    params = resolved,
    outputs = outputs,
    session_info_path = report_inputs,
    config_file = raw_config,
    context = context,
    phase2 = as.list(phase2),
    entity_resolution = as.list(entity_artifacts),
    selected_resolution = as.list(selected_artifacts)
  )
  list(stage = stage, source_root = source_root)
}

test_that("current manifest 1.3 publishes, copies, and fails safely", {
  outputs_root <- tempfile("release-bundle-output-")
  dir.create(outputs_root)
  first_id <- "20260802T000000Z-0000000000000101"
  second_id <- "20260802T000000Z-0000000000000102"

  first <- release_current_stage(outputs_root, first_id)
  final <- publish_run_bundle(first$stage, outputs_root, first_id)
  verified <- verify_run_bundle(final)
  manifest <- jsonlite::read_json(manifest_path(final), simplifyVector = FALSE)
  report_inputs <- readRDS(file.path(final, "report", "report_inputs.rds"))

  expect_true(verified$valid)
  expect_equal(manifest$manifest_schema, "camtrap-evidence-manifest/1.3")
  expect_equal(resolve_latest_bundle(outputs_root), final)
  expect_true(grepl(
    first_id,
    paste(readLines(file.path(final, "report", "report.html")), collapse = ""),
    fixed = TRUE
  ))
  expect_true(all(vapply(
    report_inputs[c(
      "selected_effort_coverage",
      "selected_community_presence",
      "selected_observed_richness",
      "selected_jaccard"
    )],
    is.data.frame,
    logical(1)
  )))
  expect_true(is.list(report_inputs$selected_resolution_status))

  portable_root <- tempfile("release-bundle-copy-")
  dir.create(portable_root)
  copied <- file.path(portable_root, first_id)
  fs::dir_copy(final, copied)
  expect_equal(basename(copied), first_id)
  expect_true(verify_run_bundle(copied)$valid)

  write("mutated", file.path(copied, "exports", "data.csv"), append = TRUE)
  expect_error(verify_run_bundle(copied), "fixity mismatch")

  collision <- release_current_stage(outputs_root, first_id)
  expect_error(
    publish_run_bundle(collision$stage, outputs_root, first_id),
    "Refusing to overwrite"
  )

  pointer <- latest_pointer_path(outputs_root)
  pointer_before <- readBin(pointer, "raw", n = file.info(pointer)$size)
  second <- release_current_stage(outputs_root, second_id)
  expect_error(
    publish_run_bundle(
      second$stage,
      outputs_root,
      second_id,
      fail_after_publish = TRUE
    ),
    "Injected failure"
  )
  expect_equal(
    readBin(pointer, "raw", n = file.info(pointer)$size),
    pointer_before
  )
  expect_equal(basename(resolve_latest_bundle(outputs_root)), first_id)
  expect_true(verify_run_bundle(file.path(
    outputs_root,
    "runs",
    second_id
  ))$valid)
})
