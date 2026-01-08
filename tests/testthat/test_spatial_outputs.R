import::from("testthat", test_that, expect_true)
import::from("tibble", tibble)
import::from("here", here)

source(here("R", "spatial_outputs.R"))

test_that("plot_site_map writes a map file", {
  site <- tibble(
    site = c("a", "b", "c"),
    lat = c(-42.0, -42.1, -42.05),
    lon = c(146.0, 146.1, 146.05),
    ndvi = c(0.2, 0.4, 0.3)
  )

  out_path <- file.path(tempdir(), "site_map_test.png")
  plot_site_map(site, out_path, surface_var = "ndvi", resolution = 50, buffer_deg = 0.01)

  expect_true(file.exists(out_path))
  expect_true(file.info(out_path)$size > 0)
})
