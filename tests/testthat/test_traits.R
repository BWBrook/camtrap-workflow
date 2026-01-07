import::from("testthat", test_that, expect_equal, expect_true)
import::from("tibble", tibble)
import::from("here", here)

source(here("R", "traits.R"))

test_that("clean_traits_table normalises and aligns columns", {
  taxa_raw <- tibble(
    short = c("Sp1", "Sp2"),
    diet = c("Herbivore", "NA"),
    activity = c("Nocturnal", "Diurnal")
  )

  traits <- clean_traits_table(taxa_raw, trait_columns = c("diet", "activity"), species_column = "short")
  expect_equal(traits$species, c("sp1", "sp2"))
  expect_true(is.na(traits$diet[2]))
})

test_that("align_traits_to_species reports missing species", {
  traits_tbl <- tibble(species = c("sp1"), diet = "herbivore")
  aligned <- align_traits_to_species(traits_tbl, c("sp1", "sp2"))
  expect_equal(nrow(aligned$missing), 1)
})
