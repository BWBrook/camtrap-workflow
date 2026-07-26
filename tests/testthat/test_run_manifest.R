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

test_that("supported entity evidence selects manifest 1.2 with an exact link map", {
  run_id <- "20260723T123456Z-0000000000000079"
  root <- tempfile("goal007-manifest-")
  bundle <- file.path(root, run_id)
  dir.create(file.path(bundle, "provenance", "entity_resolution"), recursive = TRUE)
  dir.create(file.path(bundle, "provenance", "phase2"), recursive = TRUE)
  dir.create(file.path(bundle, "report"), recursive = TRUE)
  raw <- file.path(bundle, "provenance", "config.raw.yml")
  file.copy(here("config.template_example.yml"), raw)
  effective <- file.path(bundle, "provenance", "effective_config.json")
  inventory <- file.path(bundle, "provenance", "source_inventory.json")
  writeLines("effective", effective)
  writeLines("inventory", inventory)
  report <- file.path(bundle, "report", "report.html")
  session <- file.path(bundle, "report", "report_inputs.rds")
  writeLines("report", report)
  saveRDS(list(), session)
  phase2 <- stats::setNames(
    lapply(seq_len(11L), function(index) {
      path <- file.path(
        bundle,
        "provenance",
        "phase2",
        paste0("artifact-", index)
      )
      writeLines("phase2", path)
      path
    }),
    c(
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
    )
  )
  entity <- stats::setNames(
    lapply(
      c(
        "entity_resolution.csv",
        "entity_links.csv",
        "deployment_lineage.csv",
        "entity_resolution_summary.json",
        "join_readiness.json"
      ),
      function(name) {
        path <- file.path(bundle, "provenance", "entity_resolution", name)
        writeLines("entity", path)
        path
      }
    ),
    c(
      "entity_resolution",
      "entity_links",
      "deployment_lineage",
      "entity_resolution_summary",
      "join_readiness"
    )
  )
  context <- list(
    supported_full_run = TRUE,
    run_id = run_id,
    config_source_name = "config.template_example.yml",
    provenance = list(
      raw_config = raw,
      effective_config = effective,
      source_inventory = inventory
    ),
    fingerprints = list(
      source = "source",
      config = list(raw = "raw", resolved = "resolved"),
      engine = "engine",
      composite = "composite"
    ),
    engine = list(git_commit = "abc123")
  )
  path <- file.path(bundle, "run_manifest.json")
  write_run_manifest(
    path = path,
    schema_version = "0.1.0",
    params = list(run_id = "legacy"),
    outputs = list(report = report),
    session_info_path = session,
    config_file = raw,
    context = context,
    phase2 = phase2,
    entity_resolution = entity
  )
  manifest <- read_json(path, simplifyVector = FALSE)

  expect_equal(
    manifest$manifest_schema,
    "camtrap-evidence-manifest/1.2"
  )
  expect_equal(names(manifest$entity_resolution), names(entity))
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
  expect_false(any(fs::is_absolute_path(unlist(manifest$entity_resolution))))
})
