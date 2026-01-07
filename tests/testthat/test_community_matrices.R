import::from("testthat", test_that, expect_equal, expect_true)
import::from("tibble", tibble)
import::from("here", here)

source(here("R", "community_matrices.R"))

test_that("build_community_matrices returns presence/abundance matrices", {
  events_per_day <- tibble(
    site = c("A", "A", "B"),
    species = c("sp1", "sp2", "sp1"),
    date = as.Date(c("2020-01-01", "2020-01-01", "2020-01-02")),
    events = c(2, 0, 1)
  )

  mats <- build_community_matrices(events_per_day, sites = c("A", "B", "C"))

  expect_true(all(c("abundance", "presence") %in% names(mats)))
  expect_equal(nrow(mats$abundance), 3)
  expect_true(all(mats$presence$sp1 %in% c(0, 1)))
  expect_equal(sum(mats$abundance$site == "C"), 1)
})
