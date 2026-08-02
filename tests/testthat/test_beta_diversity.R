import::from("testthat", test_that, expect_true)
import::from("tibble", tibble)
import::from("here", here)

source(here("R", "beta_diversity.R"))

test_that("compute_beta_diversity returns pairwise rows", {
  abundance <- tibble(
    site = c("A", "B"),
    sp1 = c(1, 0),
    sp2 = c(0, 1)
  )
  site_raw <- tibble(
    site = c("A", "B"),
    lat = c(0, 1),
    lon = c(0, 1)
  )

  beta <- compute_beta_diversity(abundance, site_raw)
  expect_true(nrow(beta) == 1)
})
