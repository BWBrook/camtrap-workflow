import::from("testthat", test_that, expect_silent, expect_error)
import::from("readr", read_csv)
import::from("here", here)

source(here("R", "qc_schema.R"))

fixture_path <- function(...) {
  here("tests", "fixtures", "input_schema_v0_1", ...)
}

read_fixture <- function(path) {
  read_csv(path, show_col_types = FALSE)
}

test_that("input contract passes for valid fixtures", {
  site <- read_fixture(fixture_path("valid", "jc_site.csv"))
  taxa <- read_fixture(fixture_path("valid", "jc_taxa.csv"))
  op   <- read_fixture(fixture_path("valid", "jc_op.csv"))
  obs  <- read_fixture(fixture_path("valid", "jc_obs.csv"))

  expect_silent(validate_input_contract(site, op, obs, taxa, tz = "Australia/Hobart"))
})

test_that("input contract fails on missing site columns", {
  site <- read_fixture(fixture_path("invalid", "jc_site_missing_col.csv"))
  taxa <- read_fixture(fixture_path("valid", "jc_taxa.csv"))
  op   <- read_fixture(fixture_path("valid", "jc_op.csv"))
  obs  <- read_fixture(fixture_path("valid", "jc_obs.csv"))

  expect_error(
    validate_input_contract(site, op, obs, taxa),
    "missing required column"
  )
})

test_that("input contract fails on missing taxa short column", {
  site <- read_fixture(fixture_path("valid", "jc_site.csv"))
  taxa <- read_fixture(fixture_path("invalid", "jc_taxa_missing_short.csv"))
  op   <- read_fixture(fixture_path("valid", "jc_op.csv"))
  obs  <- read_fixture(fixture_path("valid", "jc_obs.csv"))

  expect_error(
    validate_input_contract(site, op, obs, taxa),
    "missing required column"
  )
})

test_that("input contract fails on invalid effort values", {
  site <- read_fixture(fixture_path("valid", "jc_site.csv"))
  taxa <- read_fixture(fixture_path("valid", "jc_taxa.csv"))
  op   <- read_fixture(fixture_path("invalid", "jc_op_bad_values.csv"))
  obs  <- read_fixture(fixture_path("valid", "jc_obs.csv"))

  expect_error(
    validate_input_contract(site, op, obs, taxa),
    "values outside \\{0, 1\\}"
  )
})

test_that("input contract fails on unparseable datetime values", {
  site <- read_fixture(fixture_path("valid", "jc_site.csv"))
  taxa <- read_fixture(fixture_path("valid", "jc_taxa.csv"))
  op   <- read_fixture(fixture_path("valid", "jc_op.csv"))
  obs  <- read_fixture(fixture_path("invalid", "jc_obs_bad_datetime.csv"))

  expect_error(
    validate_input_contract(site, op, obs, taxa),
    "unparseable datetimes"
  )
})

