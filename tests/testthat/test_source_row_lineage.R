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
source(here("R", "source_inventory.R"))
source(here("R", "custom_funcs.R"))
source(here("R", "input_loader.R"))
source(here("R", "camtrapdp_adapter.R"))
source(here("R", "source_row_lineage.R"))

goal006_fixture_config <- function(root, outputs = tempfile("goal006-outputs-")) {
  config <- default_config()
  config$schema_version_path <- here("schema_version.txt")
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

goal006_materialized_inputs <- function(root) {
  stage <- tempfile("goal006-snapshot-")
  dir.create(stage)
  config <- goal006_fixture_config(root)
  snapshot <- materialize_source_snapshot(config, stage)
  loaded <- load_inputs(config, snapshot, include_audit = TRUE)
  list(config = config, snapshot = snapshot, loaded = loaded, stage = stage)
}

test_that("resource and source-row identities depend only on logical bytes and ordinal", {
  fixture <- here("tests", "testthat", "fixtures", "goal006", "four_table_clean")
  first <- goal006_materialized_inputs(fixture)
  second <- goal006_materialized_inputs(fixture)

  first_lineage <- build_source_row_lineage(
    first$snapshot,
    first$loaded$.audit$parsed_tables,
    input_mode = "four_table",
    observation_source_ordinal = first$loaded$.audit$observation_source_ordinal,
    observation_index = first$loaded$obs$index
  )
  second_lineage <- build_source_row_lineage(
    second$snapshot,
    second$loaded$.audit$parsed_tables,
    input_mode = "four_table",
    observation_source_ordinal = second$loaded$.audit$observation_source_ordinal,
    observation_index = second$loaded$obs$index
  )

  expect_true(validate_source_row_lineage(first_lineage, first$snapshot))
  expect_equal(first_lineage$resources$resource_id, second_lineage$resources$resource_id)
  expect_equal(first_lineage$rows$source_row_id, second_lineage$rows$source_row_id)
  expect_equal(nrow(first_lineage$resources), 4L)
  expect_equal(nrow(first_lineage$rows), 8L)
  expect_equal(
    first_lineage$resources$parsed_record_count,
    c(2L, 2L, 3L, 1L)
  )
  expect_false(any(grepl(first$stage, canonical_json(first_lineage), fixed = TRUE)))

  first_resource <- first_lineage$resources[1, ]
  expect_equal(
    first_resource$resource_id,
    resource_identity(
      first_resource$input_mode,
      first_resource$logical_name,
      first_resource$content_sha256
    )
  )
  first_row <- first_lineage$rows[1, ]
  expect_equal(
    first_row$source_row_id,
    source_row_identity(first_row$resource_id, first_row$record_ordinal)
  )
})

test_that("source byte mutation changes only the affected resource and row identities", {
  fixture <- here("tests", "testthat", "fixtures", "goal006", "four_table_clean")
  changed <- tempfile("goal006-mutated-")
  fs::dir_copy(fixture, changed)
  write(" ", file.path(changed, "obs.csv"), append = TRUE)

  original <- goal006_materialized_inputs(fixture)
  modified <- goal006_materialized_inputs(changed)
  original_lineage <- build_source_row_lineage(
    original$snapshot,
    original$loaded$.audit$parsed_tables,
    "four_table",
    original$loaded$.audit$observation_source_ordinal,
    original$loaded$obs$index
  )
  modified_lineage <- build_source_row_lineage(
    modified$snapshot,
    modified$loaded$.audit$parsed_tables,
    "four_table",
    modified$loaded$.audit$observation_source_ordinal,
    modified$loaded$obs$index
  )

  unchanged <- c("site", "op", "taxa")
  expect_equal(
    original_lineage$resources$resource_id[
      original_lineage$resources$logical_name %in% unchanged
    ],
    modified_lineage$resources$resource_id[
      modified_lineage$resources$logical_name %in% unchanged
    ]
  )
  expect_false(identical(
    original_lineage$resources$resource_id[
      original_lineage$resources$logical_name == "obs"
    ],
    modified_lineage$resources$resource_id[
      modified_lineage$resources$logical_name == "obs"
    ]
  ))
})

test_that("duplicate, omitted, and invalid row identities fail closed", {
  fixture <- here("tests", "testthat", "fixtures", "goal006", "four_table_clean")
  materialized <- goal006_materialized_inputs(fixture)
  lineage <- build_source_row_lineage(
    materialized$snapshot,
    materialized$loaded$.audit$parsed_tables,
    "four_table",
    materialized$loaded$.audit$observation_source_ordinal,
    materialized$loaded$obs$index
  )

  duplicated <- lineage
  duplicated$rows$source_row_id[2] <- duplicated$rows$source_row_id[1]
  expect_error(validate_source_row_lineage(duplicated, materialized$snapshot), "Duplicate source-row")

  omitted <- lineage
  omitted$rows <- omitted$rows[-1, ]
  expect_error(validate_source_row_lineage(omitted, materialized$snapshot), "row count")

  invalid <- lineage
  invalid$rows$record_ordinal[1] <- 0L
  expect_error(validate_source_row_lineage(invalid, materialized$snapshot), "ordinal")
})

test_that("local CamtrapDP resources receive parser-order row identities", {
  fixture <- here("tests", "testthat", "fixtures", "goal005", "camtrapdp")
  config <- default_config()
  config$input_mode <- "camtrapdp"
  config$schema_version_path <- here("schema_version.txt")
  config$paths$inputs <- list(
    site = NULL,
    op = NULL,
    obs = NULL,
    taxa = NULL,
    camtrapdp = file.path(fixture, "datapackage.json")
  )
  config <- validate_config(config)
  stage <- tempfile("goal006-camtrapdp-")
  dir.create(stage)
  snapshot <- materialize_source_snapshot(config, stage)
  deployments <- readr::read_csv(
    file.path(fixture, "deployments.csv"),
    show_col_types = FALSE
  )
  deployments$deploymentStart <- as.POSIXct(
    deployments$deploymentStart,
    tz = "UTC"
  )
  deployments$deploymentEnd <- as.POSIXct(
    deployments$deploymentEnd,
    tz = "UTC"
  )
  observations <- readr::read_csv(
    file.path(fixture, "observations.csv"),
    show_col_types = FALSE
  )
  observations$eventStart <- as.POSIXct(observations$eventStart, tz = "UTC")
  media <- readr::read_csv(
    file.path(fixture, "media.csv"),
    show_col_types = FALSE
  )
  media$timestamp <- as.POSIXct(media$timestamp, tz = "UTC")
  dp <- structure(
    list(data = list(
      deployments = deployments,
      media = media,
      observations = observations
    )),
    class = c("camtrapdp", "datapackage", "list")
  )
  loaded <- camtrapdp_to_internal(dp, tz = "UTC", include_audit = TRUE)
  lineage <- build_source_row_lineage(
    snapshot,
    loaded$.audit$parsed_tables,
    "camtrapdp",
    loaded$.audit$observation_source_ordinal,
    loaded$obs$index
  )

  expect_true(validate_source_row_lineage(lineage, snapshot))
  expect_equal(
    lineage$resources$logical_name,
    c("deployments", "media", "observations")
  )
  expect_equal(lineage$resources$parsed_record_count, rep(1L, 3L))
  expect_equal(nrow(lineage$observation_map), 1L)
})
