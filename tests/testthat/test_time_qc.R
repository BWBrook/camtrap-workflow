import::from("testthat", test_that, expect_equal, expect_true)
import::from("tibble", tibble)
import::from("here", here)

source(here("R", "time_qc.R"))

test_that("time_qc flags backward jumps using imageid order", {
  obs <- tibble(
    site = c("A", "A", "A"),
    datetime = c(
      "01/01/2021 01:00:00",
      "01/01/2021 00:30:00",
      "01/01/2021 02:00:00"
    ),
    imageid = c(1, 2, 3)
  )

  qc <- compute_time_qc(obs, tz = "Australia/Hobart", backward_threshold_hours = 0.25)

  expect_equal(qc$summary$backward_jumps[qc$summary$site == "A"], 1)
  expect_true(any(qc$flags$backward_jump))
})

test_that("time_qc flags DST gaps and parse failures", {
  obs <- tibble(
    site = c("B", "B"),
    datetime = c(
      "03/10/2021 02:30:00",
      "not-a-date"
    ),
    imageid = c(1, 2)
  )

  qc <- compute_time_qc(obs, tz = "Australia/Hobart", backward_threshold_hours = 1)

  expect_true(any(qc$flags$dst_gap))
  expect_true(any(qc$flags$parse_fail))
})

test_that("time_qc ignores DST gaps when fixed offset is set", {
  obs <- tibble(
    site = c("B", "B"),
    datetime = c(
      "03/10/2021 02:30:00",
      "03/10/2021 03:30:00"
    ),
    imageid = c(1, 2)
  )

  qc <- compute_time_qc(
    obs,
    tz = "Australia/Hobart",
    fixed_offset_hours = 10,
    backward_threshold_hours = 1
  )

  expect_true(all(qc$summary$dst_gap == 0))
  expect_true(all(!qc$flags$dst_gap))
})
