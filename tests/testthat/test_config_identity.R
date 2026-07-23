import::from(
  "testthat",
  test_that,
  expect_equal,
  expect_error,
  expect_false,
  expect_true
)
import::from("here", here)
import::from("jsonlite", read_json)

source(here("R", "config_identity.R"))
source(here("R", "fixity.R"))
source(here("R", "config.R"))

test_that("raw YAML differs while equivalent resolved configuration matches", {
  fixture <- here("tests", "testthat", "fixtures", "goal005")
  first_path <- file.path(fixture, "config_equivalent_a.yml")
  second_path <- file.path(fixture, "config_equivalent_b.yml")
  first <- read_config(first_path, attach_runtime = FALSE)
  second <- read_config(second_path, attach_runtime = FALSE)

  first_hash <- config_fingerprints(first_path, first)
  second_hash <- config_fingerprints(second_path, second)

  expect_false(identical(first_hash$raw_sha256, second_hash$raw_sha256))
  expect_equal(first_hash$resolved_sha256, second_hash$resolved_sha256)
  expect_equal(
    composite_fingerprint("source", first_hash$resolved_sha256, "engine"),
    composite_fingerprint("source", second_hash$resolved_sha256, "engine")
  )
})

test_that("configuration execution remains bound to the immutable raw snapshot", {
  source <- tempfile(fileext = ".yml")
  snapshot <- tempfile(fileext = ".yml")
  file.copy(
    here("tests", "testthat", "fixtures", "goal005", "config_equivalent_a.yml"),
    source
  )
  snapshot_record <- snapshot_config_file(source, snapshot)
  expected <- read_config(snapshot, attach_runtime = FALSE)

  write("# concurrent live-config edit", source, append = TRUE)

  expect_false(identical(sha256_file(source), snapshot_record$sha256))
  expect_equal(sha256_file(snapshot), snapshot_record$sha256)
  expect_equal(read_config(snapshot, attach_runtime = FALSE), expected)
  expect_error(
    snapshot_config_file(source, snapshot),
    "snapshot already exists"
  )
})

test_that("effective configuration carries authoritative and compatibility identities", {
  path <- tempfile(fileext = ".json")
  config <- read_config(here("config.yml"), attach_runtime = FALSE)
  context <- list(
    run_id = "20260723T123456Z-0000000000000001",
    created_utc = "2026-07-23T12:34:56Z",
    legacy_run_label = "latest",
    fingerprints = list(
      source = "source",
      config = list(raw = "raw", resolved = "resolved"),
      engine = "engine",
      composite = "composite"
    )
  )

  write_effective_config(config, context, path)
  value <- read_json(path, simplifyVector = FALSE)

  expect_equal(value$run_id, context$run_id)
  expect_equal(value$legacy_run_label, "latest")
  expect_equal(value$config$evidence_run$id, context$run_id)
  expect_true(file.exists(path))
})

test_that("repair decisions are explicit while legacy configuration stays compatible", {
  expect_false("validation" %in% names(default_config()))

  current <- c(
    "config.yml",
    "config.template_example.yml",
    "config.forest_example.yml",
    "config.camtrapdp_example.yml",
    "config.camtrapdp_export.yml"
  )
  for (path in current) {
    config <- read_config(here(path), attach_runtime = FALSE)
    expect_equal(
      config$validation,
      list(repair_decisions = list()),
      info = path
    )
  }

  legacy <- read_config(
    here(
      "tests",
      "testthat",
      "fixtures",
      "goal005",
      "config_equivalent_a.yml"
    ),
    attach_runtime = FALSE
  )
  expect_false("validation" %in% names(legacy))
})

test_that("repair decision configuration rejects broad or malformed authority", {
  config <- default_config()
  config$validation <- list(apply_all = TRUE)
  expect_error(validate_config(config), "repair_decisions")

  config$validation <- list(repair_decisions = list(list(
    repair_class = "fill_unknown",
    decision = "approved"
  )))
  expect_error(validate_config(config), "exact proposal_id")

  config$validation <- list(repair_decisions = list(list(
    proposal_id = paste(rep("a", 64L), collapse = ""),
    proposal_digest = paste(rep("b", 64L), collapse = ""),
    decision = "approved",
    wildcard = TRUE
  )))
  expect_error(validate_config(config), "exact proposal_id")
})
