import::from("testthat", test_that, expect_equal, expect_true)
import::from("tibble", tibble)
import::from("here", here)

source(here("R", "occupancy_models.R"))

test_that("select_occupancy_species chooses top N by events", {
  events_per_day <- tibble(
    site = c("A", "A", "B", "B"),
    species = c("sp1", "sp2", "sp1", "sp3"),
    date = as.Date(c("2020-01-01", "2020-01-01", "2020-01-02", "2020-01-02")),
    events = c(3, 1, 2, 5)
  )

  selected <- select_occupancy_species(events_per_day, species_override = NULL, top_n = 2)
  expect_equal(selected, c("sp1", "sp3"))
})

test_that("build_unmarked_frame creates expected dimensions", {
  detection_history <- tibble(
    site = c("A", "A", "B", "B"),
    species = c("sp1", "sp1", "sp1", "sp1"),
    occasion = c(1, 2, 1, 2),
    effort_days = c(2, 2, 2, 2),
    effort = c(1, 1, 1, 1),
    detected = c(1, 0, 0, 1)
  )
  site_covs <- tibble(
    site = c("A", "B"),
    canopy_h_m = c(0.1, -0.1),
    ndvi = c(0.2, -0.2)
  )

  umf <- build_unmarked_frame(detection_history, site_covs, "sp1")
  expect_equal(nrow(umf@y), 2)
  expect_equal(ncol(umf@y), 2)
  expect_true(all(dim(umf@obsCovs$effort_days) == c(2, 2)))
})
