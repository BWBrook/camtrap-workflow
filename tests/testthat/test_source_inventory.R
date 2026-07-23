import::from("testthat", test_that, expect_equal, expect_error, expect_false, expect_true)
import::from("here", here)

source(here("R", "config_identity.R"))
source(here("R", "fixity.R"))
source(here("R", "config.R"))
source(here("R", "source_inventory.R"))

goal005_four_table_config <- function(input_root) {
  config <- default_config()
  config$schema_version_path <- here("schema_version.txt")
  config$paths$inputs <- list(
    site = file.path(input_root, "site.csv"),
    op = file.path(input_root, "op.csv"),
    obs = file.path(input_root, "obs.csv"),
    taxa = file.path(input_root, "taxa.csv"),
    camtrapdp = NULL
  )
  validate_config(config)
}

copy_goal005_inputs <- function(destination) {
  source_root <- here("tests", "testthat", "fixtures", "goal005", "four_table")
  dir.create(destination, recursive = TRUE)
  for (name in c("site.csv", "op.csv", "obs.csv", "taxa.csv")) {
    file.copy(file.path(source_root, name), file.path(destination, name))
  }
  invisible(destination)
}

test_that("four-table snapshots inventory every parser-consumed byte", {
  input_root <- copy_goal005_inputs(tempfile("goal005-input-"))
  stage <- tempfile("goal005-stage-")
  dir.create(stage)
  snapshot <- materialize_source_snapshot(goal005_four_table_config(input_root), stage)

  expect_equal(length(snapshot$inventory), 5L)
  expect_true(all(vapply(
    snapshot$inventory,
    function(record) isTRUE(record$consumed_by_parser),
    logical(1)
  )))
  expect_true(verify_source_snapshot(snapshot, stage))
  expect_false(any(grepl(normalizePath(input_root), canonical_json(snapshot$inventory), fixed = TRUE)))
})

test_that("one source byte changes identity and snapshot mutation fails fixity", {
  input_root <- copy_goal005_inputs(tempfile("goal005-input-"))
  first_stage <- tempfile("goal005-stage-")
  second_stage <- tempfile("goal005-stage-")
  dir.create(first_stage)
  dir.create(second_stage)
  config <- goal005_four_table_config(input_root)
  first <- materialize_source_snapshot(config, first_stage)

  site_path <- file.path(input_root, "site.csv")
  text <- readLines(site_path)
  writeLines(sub("-42.0", "-42.1", text, fixed = TRUE), site_path)
  second <- materialize_source_snapshot(config, second_stage)
  expect_false(identical(first$source_sha256, second$source_sha256))

  snapshotted_site <- first$parser_paths$site
  write("tamper", snapshotted_site, append = TRUE)
  expect_error(
    verify_source_snapshot(first, first_stage),
    "Source snapshot integrity mismatch"
  )
})

test_that("missing source input fails before analysis", {
  input_root <- copy_goal005_inputs(tempfile("goal005-input-"))
  unlink(file.path(input_root, "obs.csv"))
  stage <- tempfile("goal005-stage-")
  dir.create(stage)

  expect_error(
    materialize_source_snapshot(goal005_four_table_config(input_root), stage),
    "missing or not a file"
  )
})

test_that("engine identity is bounded, relative, and SHA-256 based", {
  engine <- compute_engine_identity(here())
  paths <- vapply(engine$files, `[[`, character(1), "path")
  packages <- vapply(engine$package_versions, `[[`, character(1), "package")

  expect_equal(nchar(engine$engine_sha256), 64L)
  expect_true("_targets.R" %in% paths)
  expect_true("renv.lock" %in% paths)
  expect_true("targets" %in% packages)
  expect_false(any(fs::is_absolute_path(paths)))
  expect_false(grepl(normalizePath(here()), canonical_json(engine), fixed = TRUE))

  drifted <- engine
  drifted$package_versions[[1]]$version <- paste0(
    drifted$package_versions[[1]]$version,
    "-drift"
  )
  expect_false(identical(
    engine_identity_fingerprint(engine),
    engine_identity_fingerprint(drifted)
  ))
})
