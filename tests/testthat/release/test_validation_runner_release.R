import::from(
  "testthat",
  test_that,
  expect_equal,
  expect_error,
  expect_false,
  expect_true
)
import::from("here", here)

source(here("scripts", "run_full_evidence_run.R"))
load_evidence_helpers(here())

release_runner_null_deployment <- function() {
  list(
    profile_id = NULL,
    service_sidecar_path = NULL,
    service_sidecar_sha256 = NULL,
    deployment_ledger_path = NULL,
    deployment_ledger_sha256 = NULL,
    authority_reference = NULL
  )
}

release_runner_analysis_unit <- function(unauthorized_mapping = FALSE) {
  if (!isTRUE(unauthorized_mapping)) {
    return(list(
      resolution = "physical_location",
      mapping_profile_id = NULL,
      mapping_path = NULL,
      mapping_sha256 = NULL,
      authority_reference = NULL
    ))
  }
  authority <- analysis_unit_mapping_authority()
  c(
    list(resolution = "analysis_site"),
    authority[c("mapping_profile_id", "mapping_path", "mapping_sha256")],
    list(authority_reference = "unauthorized-mapping")
  )
}

release_runner_fixture <- function(unauthorized_mapping = FALSE) {
  source_root <- tempfile("release-runner-four-table-")
  fs::dir_copy(
    here("tests", "testthat", "fixtures", "goal006", "four_table_clean"),
    source_root
  )
  outputs_root <- tempfile("release-runner-output-")
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
  config$deployment_evidence <- release_runner_null_deployment()
  config$analysis_unit <- release_runner_analysis_unit(unauthorized_mapping)
  if (!isTRUE(unauthorized_mapping)) {
    config <- validate_config(config)
  }
  config_path <- tempfile("release-runner-config-", fileext = ".yml")
  yaml::write_yaml(config, config_path)
  list(
    config_path = config_path,
    source_root = source_root,
    outputs_root = outputs_root
  )
}

test_that("current validation-only runner publishes a ready preview", {
  fixture <- release_runner_fixture()
  source_before <- inventory_files(fixture$source_root)
  run_id <- "20260802T000000Z-0000000000000103"

  result <- run_full_evidence_run(
    config_path = fixture$config_path,
    run_id = run_id,
    validation_only = TRUE,
    project_root = here()
  )
  record <- jsonlite::read_json(
    preflight_record_path(result$preview),
    simplifyVector = FALSE
  )
  verified <- verify_preflight_record(result$preview)

  expect_equal(result$mode, "validation_only")
  expect_true(result$analysis_ready)
  expect_equal(record$preview_schema, "camtrap-validation-preview/1.2")
  expect_equal(record$status, "ready")
  expect_equal(verified$status, "ready")
  expect_true(is.list(record$selected_resolution))
  expect_false(file.exists(completion_path(result$preview)))
  expect_false(file.exists(latest_pointer_path(fixture$outputs_root)))
  expect_false(dir.exists(file.path(
    fixture$outputs_root,
    "runs",
    run_id
  )))
  expect_equal(inventory_files(fixture$source_root), source_before)
})

test_that("unauthorized mapping hard-stops without publishing", {
  fixture <- release_runner_fixture(unauthorized_mapping = TRUE)
  source_before <- inventory_files(fixture$source_root)
  run_id <- "20260802T000000Z-0000000000000104"

  expect_error(
    run_full_evidence_run(
      config_path = fixture$config_path,
      run_id = run_id,
      validation_only = TRUE,
      project_root = here()
    ),
    "analysis_unit selection has no exact approved authority"
  )
  preview <- file.path(fixture$outputs_root, "preflight", run_id)
  expect_false(dir.exists(preview))
  expect_false(file.exists(latest_pointer_path(fixture$outputs_root)))
  expect_false(dir.exists(file.path(
    fixture$outputs_root,
    "runs",
    run_id
  )))
  expect_equal(inventory_files(fixture$source_root), source_before)
})
