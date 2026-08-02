import::from("testthat", test_that, expect_equal, expect_true, expect_error)
import::from("tibble", tibble)
import::from("here", here)

source(here("R", "event_outputs.R"))

test_that("compute_event_spacing returns expected gaps", {
  obs_events <- tibble(
    site = c("A", "A", "A"),
    species = c("sp1", "sp1", "sp1"),
    event_id = c("A_sp1_1", "A_sp1_2", "A_sp1_2"),
    dt = as.POSIXct(
      c("2020-01-01 00:00:00", "2020-01-01 01:00:00", "2020-01-01 01:10:00"),
      tz = "Australia/Hobart"
    )
  )

  spacing <- compute_event_spacing(obs_events)
  gap <- spacing$gap_hours[spacing$event_id == "A_sp1_2"]

  expect_equal(length(unique(spacing$event_id)), 2)
  expect_true(is.na(spacing$gap_hours[spacing$event_id == "A_sp1_1"]))
  expect_equal(gap, 1)
})

test_that("validate_event_invariants fails if event rows exceed detections", {
  obs_events <- tibble(
    site = c("A", "A"),
    species = c("sp1", "sp1"),
    event_id = c("A_sp1_1", "A_sp1_2")
  )
  obs_filtered <- tibble(site = "A", species = "sp1")

  expect_error(
    validate_event_invariants(obs_events, obs_filtered),
    "events table has more rows"
  )
})
