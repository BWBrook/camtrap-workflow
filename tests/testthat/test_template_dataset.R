import::from("testthat", test_that, expect_true)
import::from("here", here)

source(here("R", "custom_funcs.R"))
source(here("R", "qc_schema.R"))

test_that("template dataset satisfies input contract", {
  site <- read_jc_csv(here("data", "template_dataset", "site.csv"))
  op <- read_jc_csv(here("data", "template_dataset", "op.csv"))
  obs <- read_jc_csv(here("data", "template_dataset", "obs.csv"))
  taxa <- read_jc_csv(here("data", "template_dataset", "taxa.csv"))

  expect_true(
    validate_input_contract(site, op, obs, taxa, tz = "Australia/Hobart")
  )
})

test_that("forest example dataset satisfies input contract", {
  site <- read_jc_csv(here("data", "forest_example", "site.csv"))
  op <- read_jc_csv(here("data", "forest_example", "op.csv"))
  obs <- read_jc_csv(here("data", "forest_example", "obs.csv"))
  taxa <- read_jc_csv(here("data", "forest_example", "taxa.csv"))

  expect_true(
    validate_input_contract(site, op, obs, taxa, tz = "UTC")
  )
})
