import::from(
  "testthat",
  test_that,
  expect_equal,
  expect_error,
  expect_false,
  expect_null,
  expect_true
)
import::from("here", here)
import::from("jsonlite", read_json)

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

test_that("analysis-unit selection preserves omission and normalizes explicit modes", {
  expect_false("analysis_unit" %in% names(default_config()))
  legacy <- read_config(
    here("tests", "testthat", "fixtures", "goal005", "config_equivalent_a.yml"),
    attach_runtime = FALSE
  )
  expect_null(analysis_unit_selection(legacy))
  expect_false("analysis_unit_resolved" %in% names(legacy))

  for (path in c("config.yml", "config.camtrapdp_export.yml")) {
    mapped <- read_config(here(path), attach_runtime = FALSE)
    expect_equal(mapped$analysis_unit, goal009_mapping_selection(), info = path)
    expect_equal(mapped$analysis_unit_resolved$resolution, "analysis_site", info = path)
    expect_equal(mapped$analysis_unit_resolved$scheme_id, "judbury-analysis-site", info = path)
    expect_equal(mapped$analysis_unit_resolved$scheme_version, "1.0.0-proposed", info = path)
    expect_equal(mapped$analysis_unit_resolved$mapping_sha256,
                 goal009_mapping_selection()$mapping_sha256, info = path)
  }

  identity <- list(
    analysis_unit = list(
      resolution = "analysis_site", mapping_profile_id = NULL,
      mapping_path = NULL, mapping_sha256 = NULL, authority_reference = NULL
    )
  )
  expect_equal(analysis_unit_selection(identity)$scheme_id,
               "camtrap-physical-location-identity")
  nominal <- identity
  nominal$analysis_unit$resolution <- "nominal_station"
  expect_equal(analysis_unit_selection(nominal)$state,
               "requires_runtime_authority")

  for (path in c("config.template_example.yml", "config.forest_example.yml",
                 "config.camtrapdp_example.yml")) {
    config <- read_config(here(path), attach_runtime = FALSE)
    expect_equal(config$analysis_unit$resolution, "physical_location", info = path)
    expect_true(all(vapply(config$analysis_unit[setdiff(names(config$analysis_unit), "resolution")],
                           is.null, logical(1))), info = path)
    expect_equal(config$analysis_unit_resolved$scheme_id,
                 "camtrap-physical-location-identity", info = path)
  }
})

test_that("analysis-unit selection rejects null, partial, extra, and unapproved blocks", {
  expect_error(analysis_unit_selection(list(analysis_unit = NULL)), "explicit null")
  partial <- list(analysis_unit = goal009_mapping_selection())
  partial$analysis_unit$mapping_sha256 <- NULL
  expect_error(analysis_unit_selection(partial), "exact|complete|mapping")
  extra <- list(analysis_unit = c(goal009_mapping_selection(), extra = "no"))
  expect_error(analysis_unit_selection(extra), "exact")

  unsupported <- list(analysis_unit = goal009_mapping_selection())
  unsupported$analysis_unit$resolution <- "deployment"
  expect_error(analysis_unit_selection(unsupported), "resolution")

  direct <- goal009_mapping_selection()
  direct$resolution <- "physical_location"
  direct[c("mapping_profile_id", "mapping_path", "mapping_sha256",
           "authority_reference")] <- list(NULL, NULL, NULL, NULL)
  expect_equal(analysis_unit_selection(list(analysis_unit = direct))$resolution,
               "physical_location")

  direct_with_mapping <- list(analysis_unit = goal009_mapping_selection())
  direct_with_mapping$analysis_unit$resolution <- "physical_location"
  expect_error(analysis_unit_selection(direct_with_mapping), "only valid")

  bad_authority <- list(analysis_unit = goal009_mapping_selection())
  bad_authority$analysis_unit$authority_reference <- "not-approved"
  expect_error(analysis_unit_selection(bad_authority), "authority")
})

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

test_that("entity resolution is explicit in current configs and absent from legacy defaults", {
  expect_false("entity_resolution" %in% names(default_config()))

  current <- c(
    "config.yml",
    "config.template_example.yml",
    "config.forest_example.yml",
    "config.camtrapdp_example.yml",
    "config.camtrapdp_export.yml"
  )
  for (path in current) {
    config <- read_config(here(path), attach_runtime = FALSE)
    expect_true("entity_resolution" %in% names(config), info = path)
    expect_equal(
      names(config$entity_resolution),
      c(
        "profile_id",
        "sidecar_path",
        "sidecar_sha256",
        "authority_reference"
      ),
      info = path
    )
  }

  selected <- read_config(here("config.yml"), attach_runtime = FALSE)
  expect_equal(
    selected$entity_resolution$profile_id,
    "judbury-entity-crosswalk/1.0.0-proposed"
  )
  expect_equal(
    selected$entity_resolution$sidecar_sha256,
    "553abada14493f3a5f0ae3c072523b6d5cc0d0c6a6c6480ca17a9e3331f2d8ec"
  )

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
  expect_false("entity_resolution" %in% names(legacy))
})

test_that("entity-resolution configuration rejects broad or malformed authority", {
  config <- default_config()
  config$entity_resolution <- list(inline_mapping = list(site = "nominal"))
  expect_error(validate_config(config), "exactly profile_id")

  config$entity_resolution <- list(
    profile_id = "judbury-entity-crosswalk/1.0.0-proposed",
    sidecar_path = "crosswalk.csv",
    sidecar_sha256 = paste(rep("a", 64L), collapse = ""),
    authority_reference = "pending"
  )
  expect_error(validate_config(config), "approved authority")

  config$entity_resolution <- list(
    profile_id = NULL,
    sidecar_path = "crosswalk.csv",
    sidecar_sha256 = NULL,
    authority_reference = NULL
  )
  expect_error(validate_config(config), "exact null selection")

  config <- default_config()
  config$input_mode <- "camtrapdp"
  config$paths$inputs$camtrapdp <- "camtrapdp/datapackage.json"
  config$entity_resolution <- list(
    profile_id = "judbury-entity-crosswalk/1.0.0-proposed",
    sidecar_path = "crosswalk.csv",
    sidecar_sha256 =
      "553abada14493f3a5f0ae3c072523b6d5cc0d0c6a6c6480ca17a9e3331f2d8ec",
    authority_reference = paste0(
      "goal007-judbury-crosswalk-sha256-",
      "553abada14493f3a5f0ae3c072523b6d5cc0d0c6a6c6480ca17a9e3331f2d8ec"
    )
  )
  expect_error(
    validate_config(config),
    "only valid when input_mode = 'four_table'"
  )
})

test_that("deployment evidence is explicit in current configs and omitted from legacy defaults", {
  expect_false("deployment_evidence" %in% names(default_config()))

  current <- c(
    "config.yml",
    "config.template_example.yml",
    "config.forest_example.yml",
    "config.camtrapdp_example.yml",
    "config.camtrapdp_export.yml"
  )
  fields <- c(
    "profile_id",
    "service_sidecar_path",
    "service_sidecar_sha256",
    "deployment_ledger_path",
    "deployment_ledger_sha256",
    "authority_reference"
  )
  values <- lapply(current, function(path) {
    config <- read_config(here(path), attach_runtime = FALSE)
    expect_true("deployment_evidence" %in% names(config), info = path)
    expect_equal(names(config$deployment_evidence), fields, info = path)
    config$deployment_evidence
  })
  names(values) <- current

  selected <- c("config.yml", "config.camtrapdp_export.yml")
  for (path in selected) {
    expect_equal(
      values[[path]]$profile_id,
      "judbury-deployment-evidence/1.0.0-proposed",
      info = path
    )
    expect_equal(
      values[[path]]$service_sidecar_sha256,
      "f33eeac9d70126966717c8e3f4731c00a97cbc3a34c2f44ce5c70d91c7d5283a",
      info = path
    )
    expect_equal(
      values[[path]]$deployment_ledger_sha256,
      "0921eb8845c2bb1ad5760271f283ab2783735b7739e254c67e9243bc906f3ebf",
      info = path
    )
  }
  for (path in setdiff(current, selected)) {
    expect_true(all(vapply(values[[path]], is.null, logical(1))), info = path)
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
  expect_false("deployment_evidence" %in% names(legacy))
})

test_that("deployment-evidence configuration rejects partial or unapproved authority", {
  null_entity <- list(
    profile_id = NULL,
    sidecar_path = NULL,
    sidecar_sha256 = NULL,
    authority_reference = NULL
  )
  selection <- list(
    profile_id = "judbury-deployment-evidence/1.0.0-proposed",
    service_sidecar_path = "data/jc_services.csv",
    service_sidecar_sha256 =
      "f33eeac9d70126966717c8e3f4731c00a97cbc3a34c2f44ce5c70d91c7d5283a",
    deployment_ledger_path =
      "docs/goals/008-judbury-deployment-evidence/judbury_deployment_ledger.csv",
    deployment_ledger_sha256 =
      "0921eb8845c2bb1ad5760271f283ab2783735b7739e254c67e9243bc906f3ebf",
    authority_reference = paste0(
      "goal008-judbury-deployment-evidence-source-sha256-",
      "f33eeac9d70126966717c8e3f4731c00a97cbc3a34c2f44ce5c70d91c7d5283a-",
      "ledger-sha256-",
      "0921eb8845c2bb1ad5760271f283ab2783735b7739e254c67e9243bc906f3ebf"
    )
  )

  config <- default_config()
  config$entity_resolution <- null_entity
  config$deployment_evidence <- selection
  expect_error(
    validate_config(config),
    "exact Goal 007 entity-resolution selection"
  )

  config$deployment_evidence["deployment_ledger_sha256"] <- list(NULL)
  expect_error(validate_config(config), "exact null selection|complete selected")

  config$deployment_evidence <- c(selection, inline_mapping = list(site = "x"))
  expect_error(validate_config(config), "contain exactly")

  config$deployment_evidence <- selection
  config$deployment_evidence$authority_reference <- "approved"
  expect_error(validate_config(config), "exact approved authority")

  config$deployment_evidence <- selection
  config$input_mode <- "camtrapdp"
  config$paths$inputs$camtrapdp <- "camtrapdp/datapackage.json"
  expect_error(
    validate_config(config),
    "only valid when input_mode = 'four_table'"
  )
})
