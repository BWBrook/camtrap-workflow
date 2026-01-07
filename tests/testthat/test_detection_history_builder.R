import::from("testthat", test_that, expect_equal, expect_true)
import::from("tibble", tibble)
import::from("here", here)

source(here("R", "detection_history.R"))
source(here("R", "detection_history_checks.R"))

test_that("build_detection_history aggregates to occasions and aligns effort", {
  op_long <- tibble(
    trap_date = as.Date(c("2020-01-01", "2020-01-02")),
    site = c("A", "A"),
    on_off = c(1, 0)
  )

  events_per_day <- tibble(
    site = "A",
    species = "sp1",
    date = as.Date("2020-01-01"),
    events = 1
  )

  history <- build_detection_history(
    op_long,
    events_per_day,
    species_list = "sp1",
    occasion_length_days = 2,
    start_date = "2020-01-01"
  )

  expect_equal(nrow(history), 1)
  expect_equal(history$detected, 1)
  expect_equal(history$effort, 1)
  expect_true(validate_det_hist_alignment(history))
})
