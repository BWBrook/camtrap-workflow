import::from("testthat", test_that, expect_true)
import::from("tibble", tibble)
import::from("here", here)

source(here("R", "trait_environment.R"))

test_that("trait environment association returns correlation table", {
  community <- tibble(
    site = c("A", "B"),
    sp1 = c(1, 0),
    sp2 = c(1, 2)
  )
  traits <- tibble(
    species = c("sp1", "sp2"),
    diet = c("herbivore", "carnivore")
  )
  site_raw <- tibble(
    site = c("A", "B"),
    elevation_m = c(100, 200)
  )

  props <- compute_trait_site_proportions(community, traits, traits_to_use = c("diet"))
  assoc <- compute_trait_env_associations(props, site_raw, env_vars = c("elevation_m"))

  expect_true(all(c("rho", "p_value", "p_adj") %in% names(assoc)))
  expect_true(all(is.na(assoc$p_adj) | (assoc$p_adj >= 0 & assoc$p_adj <= 1)))
})
