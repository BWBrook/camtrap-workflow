import::from("testthat", test_that, expect_true)
import::from("tibble", tibble)
import::from("here", here)

source(here("R", "alpha_diversity.R"))

test_that("compute_alpha_diversity returns non-negative richness", {
  abundance <- tibble(
    site = c("A", "B"),
    sp1 = c(1, 0),
    sp2 = c(2, 3)
  )

  alpha <- compute_alpha_diversity(abundance)
  expect_true(all(alpha$richness >= 0))
})
