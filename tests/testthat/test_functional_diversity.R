import::from("testthat", test_that, expect_true, expect_equal)
import::from("tibble", tibble)
import::from("here", here)

source(here("R", "functional_diversity.R"))

test_that("compute_functional_diversity returns metrics per site", {
  community <- tibble(
    site = c("A", "B"),
    sp1 = c(1, 0),
    sp2 = c(0, 2),
    sp3 = c(1, 1)
  )

  traits <- tibble(
    species = c("sp1", "sp2", "sp3"),
    diet = c("herbivore", "carnivore", "omnivore"),
    activity = c("nocturnal", "diurnal", "cathemeral")
  )

  fd <- suppressWarnings(compute_functional_diversity(community, traits))
  expect_equal(nrow(fd$metrics), 2)
  expect_true(all(c("FRic", "FDiv", "FDis") %in% names(fd$metrics)))
  expect_true(all(is.na(fd$metrics$FDiv) | is.finite(fd$metrics$FDiv)))
})
