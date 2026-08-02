import::from("testthat", test_that, expect_error, expect_true)
import::from("here", here)

source(here("R", "spatial_outputs.R"))

test_that("point map represents physical locations without interpolation", {
  site <- data.frame(
    site = c("camera_a", "camera_b"),
    lat = c(-42.1, -42.2),
    lon = c(147.1, 147.2)
  )
  membership <- data.frame(
    physical_location_id = c("camera_a", "camera_b"),
    analysis_unit_id = c("unit_a", "unit_a")
  )
  output <- tempfile(fileext = ".png")

  plot_physical_location_map(site, output, membership)

  expect_true(file.exists(output))
  expect_true(file.info(output)$size > 0)
})

test_that("point map rejects duplicate physical-location identities", {
  site <- data.frame(
    site = c("camera_a", "camera_a"),
    lat = c(-42.1, -42.2),
    lon = c(147.1, 147.2)
  )

  expect_error(
    plot_physical_location_map(site, tempfile(fileext = ".png")),
    "complete and unique"
  )
})
