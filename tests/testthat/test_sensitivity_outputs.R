import::from("testthat", test_that, expect_equal, expect_true)
import::from("tibble", tibble)
import::from("here", here)

source(here("R", "custom_funcs.R"))
source(here("R", "sensitivity_outputs.R"))

test_that("compute_event_threshold_sens is monotonic for increasing thresholds", {
  obs_filtered <- tibble(
    site = c("A", "A", "A"),
    species = c("sp1", "sp1", "sp1"),
    datetime = c("01/01/2020 00:00:00", "01/01/2020 00:10:00", "01/01/2020 00:40:00"),
    flash = c(0, 0, 0)
  )
  trap_nights <- tibble(site = "A", trap_nights = 1)

  sensitivity <- compute_event_threshold_sens(
    obs_filtered,
    trap_nights,
    thresholds = c(5, 15, 60),
    tz = "Australia/Hobart"
  )

  expect_equal(sensitivity$total_events, c(3, 2, 1))
  expect_true(all(diff(sensitivity$total_events) <= 0))
})

test_that("plot_event_threshold_sens writes a file", {
  sensitivity <- tibble(
    threshold_minutes = c(5, 15, 30),
    total_events = c(10, 7, 5),
    events_per_trap_night = c(0.2, 0.14, 0.1)
  )

  out_path <- tempfile(fileext = ".png")
  plot_event_threshold_sens(sensitivity, out_path)
  expect_true(file.exists(out_path))
})
