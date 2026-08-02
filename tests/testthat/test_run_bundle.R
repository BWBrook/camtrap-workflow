import::from(
  "testthat",
  test_that,
  expect_false,
  expect_true
)
import::from("here", here)

source(here("R", "config_identity.R"))
source(here("R", "fixity.R"))
source(here("R", "run_identity.R"))
source(here("R", "run_bundle.R"))

test_that("selected table comparison tolerates machine epsilon only", {
  expected <- data.frame(
    analysis_unit_from = "jc_cen",
    analysis_unit_to = "jc_co2",
    jaccard_dissimilarity = 1
  )
  observed <- expected
  observed$jaccard_dissimilarity <-
    expected$jaccard_dissimilarity - .Machine$double.eps / 2

  expect_false(identical(
    observed$jaccard_dissimilarity,
    expected$jaccard_dissimilarity
  ))
  expect_true(selected_manifest_frames_equal(observed, expected))

  observed$jaccard_dissimilarity <-
    expected$jaccard_dissimilarity - 0.01
  expect_false(selected_manifest_frames_equal(observed, expected))
})
