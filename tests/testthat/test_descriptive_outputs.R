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
  expect_equal(length(unique(rai$pooled$trap_nights)), 1)
  expect_equal(unique(rai$pooled$trap_nights), sum(trap_nights$trap_nights))
})

test_that("summarise_diel_overall proportions sum to 1", {
  obs_events <- tibble(
    flash = c(0, 1, 1, 0)
  )

  diel <- summarise_diel_overall(obs_events)
  expect_equal(sum(diel$prop), 1)
})
