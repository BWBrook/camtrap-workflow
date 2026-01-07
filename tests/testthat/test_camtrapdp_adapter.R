import::from("testthat", test_that, expect_true, expect_equal)
import::from("tibble", tibble)
import::from("here", here)

source(here("R", "camtrapdp_adapter.R"))

test_that("camtrapdp_to_internal maps minimal dataset", {
  deployments <- tibble(
    deploymentID = "dep1",
    locationID = "loc1",
    locationName = "Site 1",
    latitude = 1.0,
    longitude = 2.0,
    deploymentStart = as.POSIXct("2020-01-01 00:00:00", tz = "UTC"),
    deploymentEnd = as.POSIXct("2020-01-03 00:00:00", tz = "UTC"),
    featureType = "trail"
  )
  observations <- tibble(
    observationID = "obs1",
    deploymentID = "dep1",
    eventStart = as.POSIXct("2020-01-02 12:00:00", tz = "UTC"),
    scientificName = "Canis lupus",
    count = 1,
    lifeStage = "adult",
    sex = "unknown",
    mediaID = "m1"
  )
  media <- tibble(
    mediaID = "m1",
    deploymentID = "dep1",
    timestamp = as.POSIXct("2020-01-02 12:00:00", tz = "UTC"),
    fileName = "img1.jpg"
  )

  dp <- structure(
    list(data = list(deployments = deployments, observations = observations, media = media)),
    class = c("camtrapdp", "datapackage", "list")
  )

  out <- camtrapdp_to_internal(dp, tz = "UTC")

  expect_true(all(c("site", "taxa", "op", "obs") %in% names(out)))
  expect_true(all(c("site", "lat", "lon") %in% names(out$site)))
  expect_true("dep1" %in% names(out$op))
  expect_true(all(c("datetime", "species", "site") %in% names(out$obs)))
  expect_true(all(c("short", "genus", "species") %in% names(out$taxa)))
  expect_equal(out$obs$site[1], "dep1")
})
