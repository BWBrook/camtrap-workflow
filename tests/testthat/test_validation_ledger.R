import::from(
  "testthat",
  test_that,
  expect_equal,
  expect_error,
  expect_false,
  expect_setequal,
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
source(here("R", "input_loader.R"))
source(here("R", "camtrapdp_adapter.R"))
source(here("R", "source_row_lineage.R"))
source(here("R", "repair_ledger.R"))
source(here("R", "event_outputs.R"))
source(here("R", "validation_ledger.R"))

current_validation_fixture <- function(mutator = NULL) {
  source_root <- here(
    "tests", "testthat", "fixtures", "goal006", "four_table_clean"
  )
  root <- tempfile("current-validation-fixture-")
  fs::dir_copy(source_root, root)
  if (!is.null(mutator)) {
    mutator(root)
  }
  root
}

current_validation_config <- function(
    root,
    outputs = tempfile("current-validation-outputs-")) {
  config <- default_config()
  config$schema_version_path <- here("schema_version.txt")
  config$timezone_fixed_offset_hours <- 10
  config$validation <- list(repair_decisions = list())
  config$paths$inputs <- list(
    site = file.path(root, "site.csv"),
    op = file.path(root, "op.csv"),
    obs = file.path(root, "obs.csv"),
    taxa = file.path(root, "taxa.csv"),
    camtrapdp = NULL
  )
  config$paths$outputs <- outputs
  config$entity_resolution <- entity_null_selection()
  config$deployment_evidence <- list(
    profile_id = NULL,
    service_sidecar_path = NULL,
    service_sidecar_sha256 = NULL,
    deployment_ledger_path = NULL,
    deployment_ledger_sha256 = NULL,
    authority_reference = NULL
  )
  config$analysis_unit <- list(
    resolution = "physical_location",
    mapping_profile_id = NULL,
    mapping_path = NULL,
    mapping_sha256 = NULL,
    authority_reference = NULL
  )
  validate_config(config)
}

current_validation_snapshot <- function(config) {
  stage <- tempfile("current-validation-stage-")
  dir.create(stage)
  list(
    stage = stage,
    snapshot = materialize_source_snapshot(config, stage)
  )
}

test_that("clean preflight reconciles validated inputs and source lineage", {
  config <- current_validation_config(current_validation_fixture())
  materialized <- current_validation_snapshot(config)
  state <- prepare_validation_preflight(config, materialized$snapshot)

  expect_true(state$can_analyze)
  expect_equal(length(state$proposals), 0L)
  expect_equal(length(state$applications), 0L)
  expect_equal(nrow(state$lineage$rows), 8L)
  expect_equal(sum(state$lineage$rows$logical_name == "obs"), 3L)
  expect_equal(sum(state$lineage$rows$disposition == "excluded"), 0L)
  expect_false("event_lineage" %in% names(state))
  expect_equal(state$post_validation$integrity_failures, 0L)
  expect_equal(state$parser_audit$audit_schema, "camtrap-parser-audit/1.0")
  expect_equal(names(state$inputs), c("site", "op", "obs", "taxa"))
})

test_that("whitespace normalization is explicit, applicable, or declined", {
  root <- current_validation_fixture(function(path) {
    obs <- readLines(file.path(path, "obs.csv"))
    obs[2] <- sub(",sp1,", ", sp1 ,", obs[2], fixed = TRUE)
    writeLines(obs, file.path(path, "obs.csv"))
  })
  config <- current_validation_config(root)
  materialized <- current_validation_snapshot(config)
  preview <- prepare_validation_preflight(config, materialized$snapshot)

  expect_false(preview$can_analyze)
  expect_equal(length(preview$proposals), 1L)
  expect_equal(
    preview$proposals[[1]]$repair_class,
    "representation_normalization"
  )
  expect_equal(preview$inputs$obs$species[1], " sp1 ")

  config$validation$repair_decisions <- list(list(
    proposal_id = preview$proposals[[1]]$proposal_id,
    proposal_digest = preview$proposals[[1]]$proposal_digest,
    decision = "approved",
    reason = NULL
  ))
  approved <- prepare_validation_preflight(config, materialized$snapshot)
  expect_true(approved$can_analyze)
  expect_equal(approved$inputs$obs$species[1], "sp1")
  expect_equal(approved$applications[[1]]$status, "applied")
  expect_equal(length(approved$changed_fields), 1L)

  config$validation$repair_decisions[[1]]$decision <- "declined"
  declined <- prepare_validation_preflight(config, materialized$snapshot)
  expect_false(declined$can_analyze)
  expect_equal(declined$inputs$obs$species[1], " sp1 ")
  expect_equal(declined$applications[[1]]$reason, "declined")
})

test_that("stale authority and broken keys are non-waivable findings", {
  clean <- current_validation_config(current_validation_fixture())
  materialized <- current_validation_snapshot(clean)
  clean$validation$repair_decisions <- list(list(
    proposal_id = paste(rep("0", 64L), collapse = ""),
    proposal_digest = paste(rep("1", 64L), collapse = ""),
    decision = "approved",
    reason = NULL
  ))
  stale <- prepare_validation_preflight(clean, materialized$snapshot)
  expect_false(stale$can_analyze)
  expect_true(any(vapply(
    stale$findings,
    function(x) identical(x$category, "integrity"),
    logical(1)
  )))

  broken_root <- current_validation_fixture(function(path) {
    obs <- readLines(file.path(path, "obs.csv"))
    obs[2] <- sub(",jc_a,", ",missing_site,", obs[2], fixed = TRUE)
    writeLines(obs, file.path(path, "obs.csv"))
  })
  broken_config <- current_validation_config(broken_root)
  broken_materialized <- current_validation_snapshot(broken_config)
  broken <- prepare_validation_preflight(
    broken_config,
    broken_materialized$snapshot
  )
  expect_false(broken$can_analyze)
  expect_true(any(vapply(
    broken$findings,
    function(x) identical(x$category, "integrity"),
    logical(1)
  )))
})

test_that("validation sidecars exclude event-formation evidence", {
  config <- current_validation_config(current_validation_fixture())
  materialized <- current_validation_snapshot(config)
  state <- prepare_validation_preflight(config, materialized$snapshot)
  root <- materialized$stage
  dir.create(file.path(root, "provenance"))
  yaml::write_yaml(config, file.path(root, "provenance", "config.raw.yml"))
  write_source_inventory(
    materialized$snapshot,
    "20260723T123456Z-0000000000000059",
    file.path(root, "provenance", "source_inventory.json")
  )
  paths <- write_validation_artifacts(state, root)
  expect_false("event_membership" %in% names(paths))

  expect_true(all(file.exists(unlist(paths, use.names = FALSE))))
  expect_setequal(names(paths), c(
    "resource_registry", "source_row_ledger", "validation_findings",
    "transformations", "repair_proposals", "repair_decisions",
    "repair_applications", "changed_fields", "post_validation",
    "validated_inputs"
  ))
  expect_false(any(grepl("event", basename(unlist(paths, use.names = FALSE)))))
})
