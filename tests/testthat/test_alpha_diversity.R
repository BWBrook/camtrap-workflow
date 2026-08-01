import::from("testthat", test_that, expect_equal, expect_true)
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

test_that("plot_alpha_diversity writes a file", {
  alpha <- tibble(site = c("A", "B"), richness = c(2, 3), shannon = c(0.5, 0.6), simpson = c(0.2, 0.3))
  out_path <- tempfile(fileext = ".png")

  plot_alpha_diversity(alpha, out_path)
  expect_true(file.exists(out_path))
})

test_that("selected observed richness is the exact presence row sum", {
  presence <- data.frame(
    sp1 = c(1L, 0L, 0L),
    sp2 = c(1L, 1L, 0L),
    sp3 = c(0L, 1L, 0L),
    row.names = c("unit_a", "unit_b", "unit_c"),
    check.names = FALSE
  )

  richness <- compute_selected_observed_richness(presence)

  expect_equal(richness$analysis_unit_id, rownames(presence))
  expect_equal(richness$observed_richness, c(2L, 2L, 0L))
  expect_equal(richness$observed_richness, as.integer(rowSums(presence)))
})
