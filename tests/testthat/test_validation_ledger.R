import::from(
  "testthat",
  test_that,
  expect_equal,
  expect_error,
  expect_false,
  expect_true
)
import::from("here", here)

source(here("R", "config_identity.R"))
source(here("R", "fixity.R"))
source(here("R", "run_identity.R"))
source(here("R", "config.R"))
source(here("R", "source_inventory.R"))
source(here("R", "custom_funcs.R"))
source(here("R", "qc_schema.R"))
source(here("R", "input_loader.R"))
source(here("R", "camtrapdp_adapter.R"))
source(here("R", "source_row_lineage.R"))
source(here("R", "repair_ledger.R"))
source(here("R", "event_outputs.R"))
source(here("R", "validation_ledger.R"))
source(here("R", "run_bundle.R"))
source(here("scripts", "run_full_evidence_run.R"))

goal006_validation_fixture <- function(mutator = NULL) {
  source_root <- here("tests", "testthat", "fixtures", "goal006", "four_table_clean")
  root <- tempfile("goal006-validation-fixture-")
  fs::dir_copy(source_root, root)
  if (!is.null(mutator)) {
    mutator(root)
  }
  root
}

goal006_validation_config <- function(root, outputs = tempfile("goal006-validation-outputs-")) {
  config <- default_config()
  config$schema_version_path <- here("schema_version.txt")
  config$timezone_fixed_offset_hours <- 10
  config$paths$inputs <- list(
    site = file.path(root, "site.csv"),
    op = file.path(root, "op.csv"),
    obs = file.path(root, "obs.csv"),
    taxa = file.path(root, "taxa.csv"),
    camtrapdp = NULL
  )
  config$paths$outputs <- outputs
  validate_config(config)
}

goal006_snapshot <- function(config) {
  stage <- tempfile("goal006-validation-stage-")
  dir.create(stage)
  list(
    stage = stage,
    snapshot = materialize_source_snapshot(config, stage)
  )
}

test_that("clean preflight reconciles rows, exclusions, and operational-event membership", {
  config <- goal006_validation_config(goal006_validation_fixture())
  materialized <- goal006_snapshot(config)
  state <- prepare_validation_preflight(config, materialized$snapshot)

  expect_true(state$can_analyze)
  expect_equal(length(state$proposals), 0L)
  expect_equal(length(state$applications), 0L)
  expect_equal(nrow(state$lineage$rows), 8L)
  expect_equal(sum(state$lineage$rows$logical_name == "obs"), 3L)
  expect_equal(sum(state$lineage$rows$disposition == "excluded"), 1L)
  expect_true(all(
    state$lineage$rows$reason[state$lineage$rows$disposition == "excluded"] != ""
  ))
  expect_equal(nrow(state$event_lineage$events), 2L)
  expect_equal(nrow(state$event_lineage$memberships), 2L)
  expect_true(validate_event_lineage(state$event_lineage, state$lineage))
  expect_equal(state$post_validation$integrity_failures, 0L)
})

test_that("mocked CamtrapDP preflight preserves unknown semantic defaults", {
  source_root <- tempfile("goal006-camtrapdp-preflight-")
  fs::dir_copy(
    here("tests", "testthat", "fixtures", "goal005", "camtrapdp"),
    source_root
  )
  deployments <- tibble::tibble(
    deploymentID = "dep1",
    locationID = "loc1",
    locationName = "Site 1",
    latitude = 1,
    longitude = 2,
    deploymentStart = as.POSIXct("2020-01-01", tz = "UTC"),
    deploymentEnd = as.POSIXct("2020-01-03", tz = "UTC"),
    featureType = "trail"
  )
  observations <- tibble::tibble(
    observationID = "obs1",
    deploymentID = "dep1",
    eventStart = as.POSIXct("2020-01-02 12:00:00", tz = "UTC"),
    scientificName = "Canis lupus",
    count = NA_integer_,
    lifeStage = "adult",
    sex = "unknown",
    mediaID = "m1"
  )
  media <- tibble::tibble(
    mediaID = "m1",
    deploymentID = "dep1",
    timestamp = as.POSIXct("2020-01-02 12:00:00", tz = "UTC"),
    fileName = "img1.jpg"
  )
  readr::write_csv(deployments, file.path(source_root, "deployments.csv"))
  readr::write_csv(media, file.path(source_root, "media.csv"))
  readr::write_csv(observations, file.path(source_root, "observations.csv"))
  dp <- structure(
    list(data = list(
      deployments = deployments,
      media = media,
      observations = observations
    )),
    class = c("camtrapdp", "datapackage", "list")
  )
  config <- default_config()
  config$input_mode <- "camtrapdp"
  config$timezone <- "UTC"
  config$schema_version_path <- here("schema_version.txt")
  config$paths$inputs <- list(
    site = NULL,
    op = NULL,
    obs = NULL,
    taxa = NULL,
    camtrapdp = file.path(source_root, "datapackage.json")
  )
  config <- validate_config(config)
  stage <- tempfile("goal006-camtrapdp-stage-")
  dir.create(stage)
  snapshot <- materialize_source_snapshot(config, stage)
  state <- prepare_validation_preflight(
    config,
    snapshot,
    camtrapdp_reader = function(path) dp,
    camtrapdp_adapter = camtrapdp_to_internal
  )
  rules <- vapply(state$proposals, `[[`, character(1), "rule_id")

  expect_true(state$can_analyze)
  expect_equal(
    sort(rules),
    sort(c("legacy.fill_count_one", "legacy.fill_flash_zero"))
  )
  expect_true(all(vapply(
    state$proposals,
    function(proposal) {
      identical(proposal$repair_class, "fill_unknown") &&
        identical(proposal$applicable, FALSE)
    },
    logical(1)
  )))
  expect_true(is.na(state$inputs$obs$count[[1]]))
  expect_true(is.na(state$inputs$obs$flash[[1]]))
  expect_equal(
    state$lineage$resources$logical_name,
    c("deployments", "media", "observations")
  )
  expect_equal(nrow(state$event_lineage$memberships), 1L)
})

test_that("bounded whitespace normalization previews, applies, and declines exactly", {
  root <- goal006_validation_fixture(function(path) {
    obs <- readLines(file.path(path, "obs.csv"))
    obs[2] <- sub(",sp1,", ", sp1 ,", obs[2], fixed = TRUE)
    writeLines(obs, file.path(path, "obs.csv"))
  })
  config <- goal006_validation_config(root)
  materialized <- goal006_snapshot(config)
  preview <- prepare_validation_preflight(config, materialized$snapshot)

  expect_false(preview$can_analyze)
  expect_equal(length(preview$proposals), 1L)
  expect_equal(preview$proposals[[1]]$repair_class, "representation_normalization")
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

test_that("stale authority and broken keys become non-waivable integrity findings", {
  clean <- goal006_validation_config(goal006_validation_fixture())
  materialized <- goal006_snapshot(clean)
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

  broken_root <- goal006_validation_fixture(function(path) {
    obs <- readLines(file.path(path, "obs.csv"))
    obs[2] <- sub(",jc_a,", ",missing_site,", obs[2], fixed = TRUE)
    writeLines(obs, file.path(path, "obs.csv"))
  })
  broken_config <- goal006_validation_config(broken_root)
  broken_materialized <- goal006_snapshot(broken_config)
  broken <- prepare_validation_preflight(broken_config, broken_materialized$snapshot)
  expect_false(broken$can_analyze)
  expect_true(any(vapply(
    broken$findings,
    function(x) identical(x$category, "integrity"),
    logical(1)
  )))
})

test_that("phase-2 sidecars round-trip and reject orphan membership", {
  config <- goal006_validation_config(goal006_validation_fixture())
  materialized <- goal006_snapshot(config)
  state <- prepare_validation_preflight(config, materialized$snapshot)
  root <- materialized$stage
  dir.create(file.path(root, "provenance"))
  yaml::write_yaml(
    config,
    file.path(root, "provenance", "config.raw.yml")
  )
  write_source_inventory(
    materialized$snapshot,
    "20260723T123456Z-0000000000000059",
    file.path(root, "provenance", "source_inventory.json")
  )
  paths <- write_validation_artifacts(state, root)

  expect_true(all(file.exists(unlist(paths, use.names = FALSE))))
  expect_true(validate_validation_artifacts(root, paths, require_analysis_ready = TRUE))

  membership_path <- paths$event_membership
  membership <- jsonlite::read_json(membership_path, simplifyVector = FALSE)
  membership$records[[1]]$source_row_id <- paste(rep("0", 64L), collapse = "")
  membership$records[[1]]$membership_id <- event_membership_identity(
    membership$records[[1]]$event_id,
    membership$records[[1]]$source_row_id
  )
  unlink(membership_path)
  atomic_write_json(membership, membership_path)
  expect_error(
    validate_validation_artifacts(root, paths, require_analysis_ready = TRUE),
    "Orphan event membership"
  )
})

test_that("supported validation-only runner publishes immutable preview without latest", {
  output_root <- tempfile("goal006-preview-root-")
  dir.create(output_root)
  config <- goal006_validation_config(
    goal006_validation_fixture(),
    outputs = output_root
  )
  config_path <- tempfile("goal006-preview-config-", fileext = ".yml")
  yaml::write_yaml(config, config_path)
  pointer <- file.path(output_root, "latest")
  writeBin(charToRaw("prior-pointer\n"), pointer)
  pointer_before <- readBin(pointer, "raw", n = 1000L)
  run_id <- "20260723T123456Z-0000000000000060"

  result <- run_full_evidence_run(
    config_path = config_path,
    run_id = run_id,
    validation_only = TRUE,
    project_root = here()
  )
  preview <- file.path(output_root, "preflight", run_id)

  expect_equal(result$mode, "validation_only")
  expect_true(dir.exists(preview))
  expect_true(file.exists(file.path(preview, "PREVIEW.json")))
  expect_false(file.exists(file.path(preview, "COMPLETED.json")))
  expect_false(dir.exists(file.path(output_root, "runs", run_id)))
  expect_equal(readBin(pointer, "raw", n = 1000L), pointer_before)
  expect_true(verify_preflight_record(preview)$valid)
  expect_error(
    run_full_evidence_run(
      config_path = config_path,
      run_id = run_id,
      validation_only = TRUE,
      project_root = here()
    ),
    "collision|overwrite"
  )
})

test_that("preview decisions and integrity failures never complete or advance latest", {
  output_root <- tempfile("goal006-preview-boundaries-")
  dir.create(output_root)
  pointer <- file.path(output_root, "latest")
  writeBin(charToRaw("prior-pointer\n"), pointer)
  pointer_before <- readBin(pointer, "raw", n = 1000L)

  normalized_root <- goal006_validation_fixture(function(path) {
    obs <- readLines(file.path(path, "obs.csv"))
    obs[2] <- sub(",sp1,", ", sp1 ,", obs[2], fixed = TRUE)
    writeLines(obs, file.path(path, "obs.csv"))
  })
  normalized_config <- goal006_validation_config(
    normalized_root,
    outputs = output_root
  )
  materialized <- goal006_snapshot(normalized_config)
  proposal <- prepare_validation_preflight(
    normalized_config,
    materialized$snapshot
  )$proposals[[1]]

  invocations <- list(
    unresolved = list(
      id = "20260723T123456Z-0000000000000070",
      config = normalized_config,
      ready = FALSE
    ),
    approved = list(
      id = "20260723T123456Z-0000000000000071",
      config = within(normalized_config, {
        validation <- list(repair_decisions = list(list(
          proposal_id = proposal$proposal_id,
          proposal_digest = proposal$proposal_digest,
          decision = "approved"
        )))
      }),
      ready = TRUE
    ),
    declined = list(
      id = "20260723T123456Z-0000000000000072",
      config = within(normalized_config, {
        validation <- list(repair_decisions = list(list(
          proposal_id = proposal$proposal_id,
          proposal_digest = proposal$proposal_digest,
          decision = "declined"
        )))
      }),
      ready = FALSE
    )
  )
  for (name in names(invocations)) {
    invocation <- invocations[[name]]
    config_path <- tempfile(
      paste0("goal006-", name, "-"),
      fileext = ".yml"
    )
    yaml::write_yaml(invocation$config, config_path)
    if (isTRUE(invocation$ready)) {
      run_full_evidence_run(
        config_path = config_path,
        run_id = invocation$id,
        validation_only = TRUE,
        project_root = here()
      )
    } else {
      expect_error(
        run_full_evidence_run(
          config_path = config_path,
          run_id = invocation$id,
          validation_only = TRUE,
          project_root = here()
        ),
        "analysis is blocked",
        info = name
      )
    }
    preview <- file.path(output_root, "preflight", invocation$id)
    expect_true(verify_preflight_record(preview)$valid, info = name)
    expect_false(
      file.exists(file.path(preview, "COMPLETED.json")),
      info = name
    )
    expect_false(
      dir.exists(file.path(output_root, "runs", invocation$id)),
      info = name
    )
    expect_equal(
      readBin(pointer, "raw", n = 1000L),
      pointer_before,
      info = name
    )
  }

  unresolved_proposals <- jsonlite::read_json(
    file.path(
      output_root,
      "preflight",
      invocations$unresolved$id,
      "provenance",
      "phase2",
      "repair_proposals.json"
    ),
    simplifyVector = FALSE
  )$records
  expect_equal(unresolved_proposals[[1]]$proposal_id, proposal$proposal_id)

  broken_root <- goal006_validation_fixture(function(path) {
    obs <- readLines(file.path(path, "obs.csv"))
    obs[2] <- sub(",jc_a,", ",missing_site,", obs[2], fixed = TRUE)
    writeLines(obs, file.path(path, "obs.csv"))
  })
  broken_config <- goal006_validation_config(
    broken_root,
    outputs = output_root
  )
  broken_path <- tempfile("goal006-integrity-", fileext = ".yml")
  yaml::write_yaml(broken_config, broken_path)
  broken_id <- "20260723T123456Z-0000000000000073"
  expect_error(
    run_full_evidence_run(
      config_path = broken_path,
      run_id = broken_id,
      validation_only = TRUE,
      project_root = here()
    ),
    "analysis is blocked"
  )
  integrity_preview <- file.path(output_root, "preflight", broken_id)
  expect_equal(verify_preflight_record(integrity_preview)$status, "blocked")
  expect_equal(readBin(pointer, "raw", n = 1000L), pointer_before)
  expect_false(dir.exists(file.path(output_root, "runs", broken_id)))
})

test_that("failure after preflight preserves prior preview and latest bytes", {
  output_root <- tempfile("goal006-preflight-failure-")
  dir.create(output_root)
  pointer <- file.path(output_root, "latest")
  writeBin(charToRaw("prior-pointer\n"), pointer)
  pointer_before <- readBin(pointer, "raw", n = 1000L)
  config <- goal006_validation_config(
    goal006_validation_fixture(),
    outputs = output_root
  )
  config_path <- tempfile("goal006-preflight-failure-", fileext = ".yml")
  yaml::write_yaml(config, config_path)
  prior_id <- "20260723T123456Z-0000000000000074"
  failed_id <- "20260723T123456Z-0000000000000075"
  run_full_evidence_run(
    config_path = config_path,
    run_id = prior_id,
    validation_only = TRUE,
    project_root = here()
  )
  prior_preview <- file.path(output_root, "preflight", prior_id)
  prior_inventory <- inventory_files(prior_preview)

  expect_error(
    run_full_evidence_run(
      config_path = config_path,
      run_id = failed_id,
      validation_only = FALSE,
      fail_at = "after_preflight",
      project_root = here()
    ),
    "Injected failure after validation preflight"
  )

  expect_equal(inventory_files(prior_preview), prior_inventory)
  expect_equal(readBin(pointer, "raw", n = 1000L), pointer_before)
  expect_false(dir.exists(file.path(output_root, "runs", failed_id)))
  expect_false(dir.exists(file.path(output_root, "preflight", failed_id)))
})
