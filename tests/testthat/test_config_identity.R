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
source(here("R", "config.R"))

goal009_mapping_selection <- function() {
  list(
    resolution = "analysis_site",
    mapping_profile_id = "judbury-analysis-site/1.0.0-proposed",
    mapping_path = paste0(
      "docs/goals/009-analysis-site-vertical-slice/",
      "judbury_analysis_site_mapping.csv"
    ),
    mapping_sha256 =
      "6490d7f7021e5c727b9be1c7d6dfbf44ba50a1ef5b0396c66e1dd813a9c77083",
    authority_reference = paste0(
      "goal009-judbury-analysis-site-mapping-sha256-",
      "6490d7f7021e5c727b9be1c7d6dfbf44ba50a1ef5b0396c66e1dd813a9c77083"
    )
  )
}

test_that("current configs preserve mapped and physical analysis authorities", {
  for (path in "config.yml") {
    mapped <- read_config(here(path))
    expect_equal(mapped$analysis_unit, goal009_mapping_selection(), info = path)
    expect_equal(mapped$analysis_unit_resolved$resolution, "analysis_site", info = path)
    expect_equal(
      mapped$analysis_unit_resolved$mapping_profile_id,
      "judbury-analysis-site/1.0.0-proposed",
      info = path
    )
    expect_equal(mapped$analysis_unit_resolved$mapping_sha256,
                 goal009_mapping_selection()$mapping_sha256, info = path)
  }

  for (path in c(
    "config.template_example.yml",
    "config.forest_example.yml",
    "config.camtrapdp_example.yml"
  )) {
    physical <- read_config(here(path))
    expect_equal(
      physical$analysis_unit,
      list(
        resolution = "physical_location",
        mapping_profile_id = NULL,
        mapping_path = NULL,
        mapping_sha256 = NULL,
        authority_reference = NULL
      ),
      info = path
    )
    expect_equal(
      physical$analysis_unit_resolved[c(
        "resolution", "scheme_id", "scheme_version", "authority_reference",
        "authority_state", "state"
      )],
      c(
        list(resolution = "physical_location"),
        analysis_unit_identity_authority(),
        list(state = "built_in_default")
      ),
      info = path
    )
  }
})

test_that("analysis-site selection accepts any explicit immutable mapping contract", {
  generic <- list(analysis_unit = list(
    resolution = "analysis_site",
    mapping_profile_id = "generic-two-camera/1.0.0",
    mapping_path = "tests/fixtures/goal011/generic_analysis_site_mapping.csv",
    mapping_sha256 = paste(rep("a", 64L), collapse = ""),
    authority_reference = "test-fixture-generic-two-camera/1.0.0"
  ))

  selected <- analysis_unit_selection(generic)

  expect_equal(selected$mapping_profile_id, "generic-two-camera/1.0.0")
  expect_equal(selected$state, "selected_mapping")
  expect_false("scheme_id" %in% names(selected))
})

test_that("raw YAML differs while equivalent resolved configuration matches", {
  fixture <- here("tests", "testthat", "fixtures", "goal005")
  first_path <- file.path(fixture, "config_equivalent_a.yml")
  second_path <- file.path(fixture, "config_equivalent_b.yml")
  first <- read_config(first_path)
  second <- read_config(second_path)

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
  expected <- read_config(snapshot)

  write("# concurrent live-config edit", source, append = TRUE)

  expect_false(identical(sha256_file(source), snapshot_record$sha256))
  expect_equal(sha256_file(snapshot), snapshot_record$sha256)
  expect_equal(read_config(snapshot), expected)
  expect_error(
    snapshot_config_file(source, snapshot),
    "snapshot already exists"
  )
})

test_that("current repair authority is explicit", {
  config <- read_config(here("config.yml"))
  expect_equal(config$validation, list(repair_decisions = list()))
})

test_that("repair decision configuration rejects broad authority", {
  config <- read_config(here("config.yml"))
  config$validation <- list(apply_all = TRUE)
  expect_error(validate_config(config), "repair_decisions")
})

test_that("current entity-resolution authority is exact", {
  selected <- read_config(here("config.yml"))
  expect_equal(
    names(selected$entity_resolution),
    c("profile_id", "sidecar_path", "sidecar_sha256", "authority_reference")
  )
  expect_equal(
    selected$entity_resolution$profile_id,
    "judbury-entity-crosswalk/1.0.0-proposed"
  )
  expect_equal(
    selected$entity_resolution$sidecar_sha256,
    "553abada14493f3a5f0ae3c072523b6d5cc0d0c6a6c6480ca17a9e3331f2d8ec"
  )
})

test_that("entity-resolution configuration rejects unapproved authority", {
  config <- read_config(here("config.yml"))
  config$entity_resolution$authority_reference <- "pending"
  expect_error(validate_config(config), "approved authority")
})

test_that("current deployment-evidence authority is exact", {
  config <- read_config(here("config.yml"))
  fields <- c(
    "profile_id",
    "service_sidecar_path",
    "service_sidecar_sha256",
    "deployment_ledger_path",
    "deployment_ledger_sha256",
    "authority_reference"
  )
  expect_equal(names(config$deployment_evidence), fields)
  expect_equal(
    config$deployment_evidence$profile_id,
    "judbury-deployment-evidence/1.0.0-proposed"
  )
  expect_equal(
    config$deployment_evidence$service_sidecar_sha256,
    "f33eeac9d70126966717c8e3f4731c00a97cbc3a34c2f44ce5c70d91c7d5283a"
  )
  expect_equal(
    config$deployment_evidence$deployment_ledger_sha256,
    "0921eb8845c2bb1ad5760271f283ab2783735b7739e254c67e9243bc906f3ebf"
  )
})

test_that("deployment-evidence configuration rejects unapproved authority", {
  config <- read_config(here("config.yml"))
  config$deployment_evidence$authority_reference <- "approved"
  expect_error(validate_config(config), "exact approved authority")
})

test_that("only current analytical resolutions and fields are accepted", {
  config <- read_config(here("config.template_example.yml"))
  config$analysis_unit$resolution <- "nominal_station"
  expect_error(validate_config(config), "physical_location or analysis_site")

  path <- tempfile(fileext = ".yml")
  writeLines(c("input_mode: four_table", "occupancy: {}"), path)
  expect_error(read_config(path), "removed or unknown")
})
