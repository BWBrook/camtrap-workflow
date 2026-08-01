import::from(
  "testthat",
  test_that,
  expect_equal,
  expect_false,
  expect_null,
  expect_true
)
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
  legacy_config <- yaml::read_yaml(here("config.yml"))
  legacy_config$analysis_unit <- NULL
  yaml::write_yaml(legacy_config, raw_config)
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
  legacy_config <- yaml::read_yaml(here("config.template_example.yml"))
  legacy_config$analysis_unit <- NULL
  yaml::write_yaml(legacy_config, raw)
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

goal009_manifest_fixture <- function(route_eligible) {
  run_id <- if (isTRUE(route_eligible)) {
    "20260801T123456Z-0000000000000091"
  } else {
    "20260801T123456Z-0000000000000092"
  }
  bundle <- file.path(tempfile("goal009-manifest-"), run_id)
  dir.create(file.path(bundle, "provenance", "phase2"), recursive = TRUE)
  dir.create(
    file.path(bundle, "provenance", "entity_resolution"),
    recursive = TRUE
  )
  dir.create(
    file.path(bundle, "provenance", "selected_resolution"),
    recursive = TRUE
  )
  dir.create(file.path(bundle, "report"), recursive = TRUE)
  dir.create(file.path(bundle, "tables"), recursive = TRUE)

  raw <- file.path(bundle, "provenance", "config.raw.yml")
  file.copy(here("config.template_example.yml"), raw)
  effective <- file.path(bundle, "provenance", "effective_config.json")
  inventory <- file.path(bundle, "provenance", "source_inventory.json")
  writeLines("effective", effective)
  writeLines("inventory", inventory)
  report <- file.path(bundle, "report", "report.html")
  session <- file.path(bundle, "report", "report_inputs.rds")
  status <- file.path(bundle, "tables", "selected_resolution_status.json")
  writeLines("report", report)
  saveRDS(list(), session)
  writeLines("status", status)

  phase2_names <- c(
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
  phase2 <- stats::setNames(lapply(phase2_names, function(name) {
    path <- file.path(bundle, "provenance", "phase2", paste0(name, ".json"))
    writeLines("phase2", path)
    path
  }), phase2_names)
  entity_names <- c(
    entity_resolution = "entity_resolution.csv",
    entity_links = "entity_links.csv",
    deployment_lineage = "deployment_lineage.csv",
    entity_resolution_summary = "entity_resolution_summary.json",
    join_readiness = "join_readiness.json"
  )
  entity <- lapply(entity_names, function(name) {
    path <- file.path(bundle, "provenance", "entity_resolution", name)
    writeLines("entity", path)
    path
  })
  selected_names <- c(
    membership = "membership.csv",
    operation = "operation.csv",
    event_map = "event_map.csv",
    summary = "summary.json"
  )
  selected <- lapply(selected_names, function(name) {
    path <- file.path(bundle, "provenance", "selected_resolution", name)
    writeLines("selected", path)
    path
  })
  data_names <- c(
    selected_effort_coverage = "selected_effort_coverage.csv",
    selected_community_presence = "selected_community_presence.csv",
    selected_observed_richness = "selected_observed_richness.csv",
    selected_jaccard = "selected_jaccard.csv"
  )
  data_paths <- lapply(data_names, function(name) {
    if (!isTRUE(route_eligible)) {
      return(NULL)
    }
    path <- file.path(bundle, "tables", name)
    writeLines("selected output", path)
    path
  })
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
    outputs = list(tables = c(data_paths, list(
      selected_resolution_status = status
    ))),
    session_info_path = session,
    config_file = raw,
    context = context,
    phase2 = phase2,
    entity_resolution = entity,
    selected_resolution = selected
  )
  read_json(path, simplifyVector = FALSE)
}

test_that("explicit eligible and ineligible modes select manifest 1.3", {
  eligible <- goal009_manifest_fixture(TRUE)
  ineligible <- goal009_manifest_fixture(FALSE)
  expected_provenance <- c(
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

  for (manifest in list(eligible, ineligible)) {
    expect_equal(
      manifest$manifest_schema,
      "camtrap-evidence-manifest/1.3"
    )
    expect_equal(names(manifest$selected_resolution), names(expected_provenance))
    expect_equal(
      unlist(manifest$selected_resolution, use.names = TRUE),
      expected_provenance
    )
    expect_equal(
      manifest$outputs$tables$selected_resolution_status,
      "tables/selected_resolution_status.json"
    )
  }
  expect_equal(
    unlist(eligible$outputs$tables[names(expected_data)], use.names = TRUE),
    expected_data
  )
  for (name in names(expected_data)) {
    expect_null(ineligible$outputs$tables[[name]])
  }
})
