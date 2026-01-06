import::from("testthat", test_that, expect_true, expect_equal)
import::from("tibble", tibble)
import::from("here", here)

source(here("R", "descriptive_outputs.R"))

test_that("calc_rai_with_ci returns non-negative rates within CI bounds", {
  events_per_day <- tibble(
    site = c("A", "A", "B"),
    species = c("sp1", "sp2", "sp1"),
    date = as.Date(c("2020-01-01", "2020-01-01", "2020-01-01")),
    events = c(2, 0, 1)
  )
  trap_nights <- tibble(site = c("A", "B"), trap_nights = c(10, 5))

  rai <- calc_rai_with_ci(events_per_day, trap_nights)

  expect_true(all(rai$pooled$rai >= 0))
  expect_true(all(rai$pooled$rai >= rai$pooled$rai_lower))
  expect_true(all(rai$pooled$rai <= rai$pooled$rai_upper))
})

test_that("plot_rai_species writes a file", {
  rai_species <- tibble(
    species = c("sp1", "sp2"),
    events = c(3, 1),
    trap_nights = c(10, 10),
    rai = c(0.3, 0.1),
    rai_lower = c(0.1, 0.01),
    rai_upper = c(0.5, 0.2)
  )
  out_path <- tempfile(fileext = ".png")

  plot_rai_species(rai_species, out_path, top_n = 2)
  expect_true(file.exists(out_path))
})

test_that("summarise_diel_overall proportions sum to 1", {
  obs_events <- tibble(
    flash = c(0, 1, 1, 0)
  )

  diel <- summarise_diel_overall(obs_events)
  expect_equal(sum(diel$prop), 1)
})

test_that("plot_diel_overall writes a file", {
  diel <- tibble(period = c("day", "night"), n = c(2, 2), prop = c(0.5, 0.5))
  out_path <- tempfile(fileext = ".png")

  plot_diel_overall(diel, out_path)
  expect_true(file.exists(out_path))
})
