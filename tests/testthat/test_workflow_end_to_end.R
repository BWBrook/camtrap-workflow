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

source(here("R", "fixity.R"))
source(here("R", "config_identity.R"))
source(here("R", "run_identity.R"))
source(here("R", "community_matrices.R"))
source(here("R", "run_bundle.R"))
source(here("scripts", "run_full_evidence_run.R"))
source(here("scripts", "verify_published_bundle.R"))

workflow_fixture <- function() {
  helpers <- load_runner_helpers(here())
  root <- tempfile("goal011-workflow-")
  dir.create(root)
  source_root <- normalizePath(here(
    "tests", "testthat", "fixtures", "goal006", "four_table_clean"
  ))
  config <- helpers$default_config()
  config$schema_version_path <- normalizePath(here("schema_version.txt"))
  config$timezone_fixed_offset_hours <- 10
  config$paths$inputs <- list(
    site = file.path(source_root, "site.csv"),
    op = file.path(source_root, "op.csv"),
    obs = file.path(source_root, "obs.csv"),
    taxa = file.path(source_root, "taxa.csv"),
    camtrapdp = NULL
  )
  config$paths$outputs <- file.path(root, "outputs")
  config_path <- file.path(root, "config.yml")
  yaml::write_yaml(config, config_path)
  list(
    root = root,
    source_root = source_root,
    source_fixity = lapply(
      list.files(source_root, full.names = TRUE),
      sha256_file
    ),
    config_path = config_path,
    outputs_root = config$paths$outputs
  )
}

run_workflow_cli <- function(config_path, validation_only = FALSE) {
  arguments <- c(
    here("scripts", "run_full_evidence_run.R"),
    "--config",
    config_path,
    if (isTRUE(validation_only)) "--validate-only" else character()
  )
  output <- system2("Rscript", arguments, stdout = TRUE, stderr = TRUE)
  status <- attr(output, "status")
  if (is.null(status)) status <- 0L
  expect_equal(status, 0L, info = paste(output, collapse = "\n"))
  output
}

test_that("current seven-stage workflow publishes one verifiable bundle", {
  fixture <- workflow_fixture()
  run_workflow_cli(fixture$config_path)
  run_id <- trimws(readLines(latest_pointer_path(fixture$outputs_root)))
  bundle <- file.path(fixture$outputs_root, "runs", run_id)
  independently_verified <- verify_published_bundle_independent(bundle)
  manifest <- jsonlite::read_json(
    file.path(bundle, "run_manifest.json"),
    simplifyVector = FALSE
  )
  status <- jsonlite::read_json(
    file.path(bundle, manifest$module_status),
    simplifyVector = FALSE
  )

  expect_equal(manifest$manifest_schema, "camtrap-run-bundle/2.0")
  expect_true(independently_verified$valid)
  expect_equal(independently_verified$events, 2L)
  expect_equal(independently_verified$source_memberships, 2L)
  expect_setequal(
    vapply(status$records, `[[`, character(1), "module"),
    c(
      "effort_coverage", "observed_presence", "observed_richness",
      "jaccard", "operational_event_detection_rate", "coarse_day_night",
      "species_accumulation", "point_map", "event_gap_sensitivity"
    )
  )
  expect_false(any(vapply(
    status$records,
    function(record) identical(record$status, "failed"),
    logical(1)
  )))
  expect_equal(
    basename(resolve_latest_bundle(fixture$outputs_root)),
    run_id
  )
  expect_equal(
    lapply(list.files(fixture$source_root, full.names = TRUE), sha256_file),
    fixture$source_fixity
  )

  tamper_root <- tempfile("goal011-completion-")
  dir.create(tamper_root)
  tampered_bundle <- file.path(tamper_root, run_id)
  fs::dir_copy(bundle, tampered_bundle)
  completion_path <- file.path(tampered_bundle, "COMPLETE.json")
  completion <- jsonlite::read_json(completion_path, simplifyVector = FALSE)
  completion$manifest_sha256 <- paste(rep("0", 64L), collapse = "")
  jsonlite::write_json(
    completion,
    completion_path,
    auto_unbox = TRUE,
    pretty = TRUE
  )
  expect_error(
    verify_published_bundle_independent(tampered_bundle),
    "completion"
  )

  second_root <- tempfile("goal011-atomic-")
  stage <- file.path(second_root, "runs", ".staging", run_id)
  dir.create(dirname(stage), recursive = TRUE)
  fs::dir_copy(bundle, stage)
  unlink(file.path(stage, "COMPLETE.json"))
  dir.create(second_root, recursive = TRUE, showWarnings = FALSE)
  atomic_replace_text("pre-existing-pointer", latest_pointer_path(second_root))
  pointer_before <- readBin(
    latest_pointer_path(second_root),
    "raw",
    n = file.info(latest_pointer_path(second_root))$size
  )
  expect_error(
    publish_current_bundle(
      stage,
      second_root,
      run_id,
      fail_before_latest = TRUE
    ),
    "Injected failure"
  )
  expect_equal(
    readBin(
      latest_pointer_path(second_root),
      "raw",
      n = file.info(latest_pointer_path(second_root))$size
    ),
    pointer_before
  )
  published <- file.path(second_root, "runs", run_id)
  expect_true(verify_current_bundle(published)$valid)
  write("tampered", file.path(published, "tables", "selected_jaccard.csv"),
        append = TRUE)
  expect_error(verify_current_bundle(published), "fixity mismatch")
})

test_that("validation-only mode publishes no completed run or latest pointer", {
  fixture <- workflow_fixture()
  run_workflow_cli(fixture$config_path, validation_only = TRUE)
  previews <- list.dirs(
    file.path(fixture$outputs_root, "preflight"),
    full.names = TRUE,
    recursive = FALSE
  )
  previews <- previews[basename(previews) != ".staging"]
  expect_equal(length(previews), 1L)
  record <- jsonlite::read_json(
    file.path(previews[[1L]], "validation_preview.json"),
    simplifyVector = FALSE
  )
  expect_equal(record$validation_preview_schema, "camtrap-validation-preview/2.0")
  expect_true(record$can_analyze)
  expect_false(file.exists(latest_pointer_path(fixture$outputs_root)))
  expect_false(dir.exists(file.path(fixture$outputs_root, "runs")))
})
