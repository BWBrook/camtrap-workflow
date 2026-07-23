import::from("testthat", test_that, expect_equal, expect_false, expect_true)
import::from("jsonlite", read_json)
import::from("here", here)
import::from("withr", local_envvar)

source(here("R", "config_identity.R"))
source(here("R", "fixity.R"))
source(here("R", "run_identity.R"))
source(here("R", "run_bundle.R"))
source(here("R", "run_manifest.R"))

test_that("manifest records exact relative payload and evidence identities", {
  run_id <- "20260723T123456Z-0000000000000001"
  root <- tempfile("goal005-manifest-")
  bundle <- file.path(root, run_id)
  dir.create(file.path(bundle, "report"), recursive = TRUE)
  dir.create(file.path(bundle, "exports"), recursive = TRUE)
  dir.create(file.path(bundle, "provenance"), recursive = TRUE)
  report <- file.path(bundle, "report", "report.html")
  report_inputs <- file.path(bundle, "report", "report_inputs.rds")
  export <- file.path(bundle, "exports", "data.csv")
  raw_config <- file.path(bundle, "provenance", "config.raw.yml")
  snapshot_config_file(here("config.yml"), raw_config)
  writeLines("report", report)
  saveRDS(
    list(params = list(evidence_run = list(id = run_id))),
    report_inputs
  )
  writeLines("data", export)
  atomic_write_json(
    list(
      run_id = run_id,
      config = list(evidence_run = list(id = run_id))
    ),
    file.path(bundle, "provenance", "effective_config.json")
  )
  atomic_write_json(
    list(run_id = run_id),
    file.path(bundle, "provenance", "source_inventory.json")
  )

  context <- list(
    supported_full_run = TRUE,
    run_id = run_id,
    config_source_name = "config.yml",
    provenance = list(
      raw_config = raw_config,
      effective_config = file.path(bundle, "provenance", "effective_config.json"),
      source_inventory = file.path(bundle, "provenance", "source_inventory.json")
    ),
    fingerprints = list(
      source = "source",
      config = list(raw = "raw", resolved = "resolved"),
      engine = "engine",
      composite = "composite"
    ),
    engine = list(git_commit = "abc123")
  )
  manifest_path <- file.path(bundle, "run_manifest.json")
  write_run_manifest(
    path = manifest_path,
    schema_version = "0.1.0",
    params = list(run_id = "legacy-label"),
    outputs = list(report = report, export = export),
    session_info_path = report_inputs,
    config_file = here("config.yml"),
    context = context
  )

  manifest <- read_json(manifest_path, simplifyVector = FALSE)
  payload_paths <- vapply(manifest$payload, `[[`, character(1), "path")

  expect_equal(manifest$manifest_schema, "camtrap-evidence-manifest/1.0")
  expect_equal(manifest$run_id, run_id)
  expect_equal(manifest$legacy_run_label, "legacy-label")
  expect_equal(manifest$fingerprints$source, "source")
  expect_equal(manifest$config$raw, "provenance/config.raw.yml")
  expect_true(all(c(
    "exports/data.csv",
    "provenance/config.raw.yml",
    "report/report.html",
    "report/report_inputs.rds"
  ) %in% payload_paths))
  expect_false("run_manifest.json" %in% payload_paths)
  expect_false(any(fs::is_absolute_path(payload_paths)))
  expect_true(all(vapply(
    manifest$payload,
    function(record) nchar(record$sha256) == 64L && record$bytes >= 0,
    logical(1)
  )))
})

test_that("get_git_commit uses container-provided commit metadata", {
  local_envvar(
    c(CAMTRAP_WORKFLOW_GIT_COMMIT = "abc123"),
    .local_envir = testthat::teardown_env()
  )

  expect_equal(get_git_commit(), "abc123")
})
