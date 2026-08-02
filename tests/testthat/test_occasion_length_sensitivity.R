import::from("testthat", test_that, expect_true, expect_equal)
import::from("tibble", tibble)
import::from("here", here)

source(here("R", "sensitivity_outputs.R"))
source(here("R", "detection_history.R"))

test_that("compute_occasion_length_sens returns rows for each length/species", {
  op_long <- tibble(
    trap_date = as.Date(c("2020-01-01", "2020-01-02")),
    site = c("A", "A"),
    on_off = c(1, 1)
  )
  events_per_day <- tibble(
    site = "A",
    species = "sp1",
    date = as.Date("2020-01-01"),
    events = 1
  )

  out <- compute_occasion_length_sens(
    op_long,
    events_per_day,
    species_list = "sp1",
    occasion_lengths = c(1, 2),
    start_date = "2020-01-01"
  )

  expect_equal(nrow(out), 2)
  expect_true(all(out$species == "sp1"))
})
