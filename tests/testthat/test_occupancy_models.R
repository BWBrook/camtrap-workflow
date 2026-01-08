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
    effort_days = c(2, 0, 2, 2),
    effort = c(1, 0, 1, 1),
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
  expect_true(is.na(umf@y[1, 2]))
  expect_equal(rownames(umf@siteCovs), c("A", "B"))
})

test_that("select_occupancy_covariates drops missing or non-informative covariates", {
  site_raw <- tibble(
    site = c("A", "B", "C"),
    canopy_h_m = c(NA_real_, NA_real_, NA_real_),
    ndvi = c(1, 1, 1),
    elevation_m = c(10, 20, 30)
  )

  selected <- suppressWarnings(
    select_occupancy_covariates(site_raw, c("canopy_h_m", "ndvi", "elevation_m", "missing"))
  )

  expect_equal(selected, "elevation_m")
})

test_that("summarise_occupancy_model returns non-missing p estimates", {
  detection_history <- tibble(
    site = rep(c("A", "B"), each = 3),
    species = "sp1",
    occasion = rep(1:3, times = 2),
    effort_days = c(1, 1, 1, 1, 0, 1),
    effort = c(1, 1, 1, 1, 0, 1),
    detected = c(1, 0, 1, 0, 0, 1)
  )
  site_covs <- tibble(
    site = c("A", "B"),
    canopy_h_m = c(0.1, -0.1),
    ndvi = c(0.2, -0.2)
  )

  umf <- build_unmarked_frame(detection_history, site_covs, "sp1")
  model <- suppressWarnings(unmarked::occu(~effort_days ~1, data = umf))
  summary <- summarise_occupancy_model(model, psi_ci_method = "none")

  expect_true(!is.na(summary$p["est"]))
  expect_true(summary$p["est"] >= 0)
  expect_true(summary$p["est"] <= 1)
})

test_that("compute_naive_occupancy returns expected counts", {
  detection_history <- tibble(
    site = rep(c("A", "B", "C"), each = 2),
    species = "sp1",
    occasion = rep(1:2, times = 3),
    effort_days = 1,
    effort = 1,
    detected = c(1, 0, 0, 0, 0, 0)
  )

  diag <- compute_naive_occupancy(detection_history, "sp1")
  expect_equal(diag$n_sites, 3)
  expect_equal(diag$n_sites_detected, 1)
  expect_equal(diag$n_sites_all_zero, 2)
  expect_equal(diag$naive_occupancy, 1 / 3)
  expect_true(diag$naive_occupancy_lower <= diag$naive_occupancy)
  expect_true(diag$naive_occupancy_upper >= diag$naive_occupancy)
})
