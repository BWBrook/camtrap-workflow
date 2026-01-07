import::from("testthat", test_that, expect_error, expect_true)
import::from("tibble", tibble)
import::from("here", here)

source(here("R", "detection_history_checks.R"))

test_that("validate_det_hist_alignment fails on detections during no effort", {
  detection_history <- tibble(
    detected = c(1, 0),
    effort = c(0, 1)
  )

  expect_error(
    validate_det_hist_alignment(detection_history),
    "detections occur during zero effort"
  )
})

test_that("validate_det_hist_alignment passes on aligned data", {
  detection_history <- tibble(
    detected = c(1, 0, 0),
    effort = c(1, 1, 0)
  )

  expect_true(validate_det_hist_alignment(detection_history))
})
