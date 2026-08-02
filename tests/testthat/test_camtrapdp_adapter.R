import::from(
  "testthat", test_that, expect_equal, expect_error, expect_false, expect_true
)
import::from("tibble", tibble)
import::from("here", here)

source(here("R", "config_identity.R"))
source(here("R", "fixity.R"))
source(here("R", "config.R"))
source(here("R", "source_inventory.R"))
source(here("R", "camtrapdp_adapter.R"))

test_that("CamtrapDP supplied fields map exactly without fabrication", {
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
    eventStart = as.POSIXct("2020-01-02 10:00:00", tz = "UTC"),
    scientificName = "Canis lupus",
    count = 3L,
    flash = 1L,
    lifeStage = "adult",
    sex = "female",
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

  out <- camtrapdp_to_internal(dp, tz = "UTC", include_audit = TRUE)

  expect_true(all(c("site", "taxa", "op", "obs") %in% names(out)))
  expect_true(all(c("site", "lat", "lon") %in% names(out$site)))
  expect_true("loc1" %in% names(out$op))
  expect_false("dep1" %in% names(out$op))
  expect_true(all(c(
    "datetime", "species", "site", "deployment_id",
    "physical_location_id"
  ) %in% names(out$obs)))
  expect_true(all(c("short", "genus", "species") %in% names(out$taxa)))
  expect_equal(out$site$site, "loc1")
  expect_equal(out$obs$site[1], "loc1")
  expect_equal(out$obs$deployment_id[1], "dep1")
  expect_equal(out$obs$physical_location_id[1], "loc1")
  expect_equal(out$obs$datetime[[1]], "02/01/2020 10:00:00")
  expect_equal(out$obs$count[[1]], 3L)
  expect_equal(out$obs$flash[[1]], 1L)
  expect_equal(length(out$.audit$semantic_defaults), 0L)
  expect_true(all(vapply(
    out$.audit$transformations,
    `[[`,
    logical(1),
    "meaning_preserving"
  )))
})

test_that("CamtrapDP missing physical-location identity fails closed", {
  deployments <- tibble(
    deploymentID = "opaque-deployment",
    locationID = NA_character_,
    locationName = "Unresolved location",
    latitude = 1,
    longitude = 2,
    deploymentStart = as.POSIXct("2020-01-01", tz = "UTC"),
    deploymentEnd = as.POSIXct("2020-01-03", tz = "UTC"),
    featureType = "trail"
  )
  observations <- tibble(
    observationID = "obs1", deploymentID = "opaque-deployment",
    eventStart = as.POSIXct("2020-01-02", tz = "UTC"),
    scientificName = "Canis lupus", count = 1L, flash = 0L,
    lifeStage = "adult", sex = "unknown", mediaID = NA_character_
  )

  expect_error(
    camtrapdp_to_internal(
      structure(
        list(data = list(
          deployments = deployments, observations = observations, media = NULL
        )),
        class = c("camtrapdp", "datapackage", "list")
      ),
      tz = "UTC"
    ),
    "locationID"
  )
})

goal006_camtrapdp_object <- function(
    deployments,
    observations,
    media = NULL) {
  structure(
    list(data = list(
      deployments = deployments,
      observations = observations,
      media = media
    )),
    class = c("camtrapdp", "datapackage", "list")
  )
}

test_that("CamtrapDP unknowns and endpoints are never silently fabricated", {
  deployments <- tibble(
    deploymentID = "dep1",
    locationID = "loc1",
    locationName = "Site 1",
    latitude = 1,
    longitude = 2,
    deploymentStart = as.POSIXct("2020-01-01", tz = "UTC"),
    deploymentEnd = as.POSIXct("2020-01-03", tz = "UTC"),
    featureType = "trail"
  )
  observations <- tibble(
    observationID = "obs1",
    deploymentID = "dep1",
    eventStart = as.POSIXct(NA),
    scientificName = "Canis lupus",
    count = NA_integer_,
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
  out <- camtrapdp_to_internal(
    goal006_camtrapdp_object(deployments, observations, media),
    tz = "UTC",
    include_audit = TRUE
  )
  defaults <- out$.audit$semantic_defaults
  rules <- vapply(defaults, `[[`, character(1), "source_rule")

  expect_true(is.na(out$obs$datetime[[1]]))
  expect_true(is.na(out$obs$count[[1]]))
  expect_true(is.na(out$obs$flash[[1]]))
  expect_equal(
    sort(rules),
    sort(c(
      "adapter.copy_media_timestamp",
      "adapter.fill_count_one",
      "adapter.fill_flash_zero"
    ))
  )
  expect_true(all(vapply(
    defaults,
    function(record) {
      identical(record$repair_class, "fill_unknown") &&
        identical(record$production_applicable, FALSE)
    },
    logical(1)
  )))

  deployments$deploymentEnd[[1]] <- as.POSIXct(NA)
  observations$eventStart[[1]] <- as.POSIXct(
    "2020-01-02 12:00:00",
    tz = "UTC"
  )
  observations$count[[1]] <- 1L
  observations$flash <- 1L
  observations$mediaID[[1]] <- NA_character_
  dp <- goal006_camtrapdp_object(deployments, observations)
  preview <- camtrapdp_to_internal(dp, tz = "UTC", include_audit = TRUE)
  defaults <- preview$.audit$semantic_defaults

  expect_equal(nrow(preview$op), 0L)
  expect_true(is.na(
    preview$.audit$parsed_tables$deployments$deploymentEnd[[1]]
  ))
  expect_true(any(vapply(
    defaults,
    function(record) {
      identical(record$source_rule, "adapter.copy_deployment_endpoint") &&
        identical(record$production_applicable, FALSE)
    },
    logical(1)
  )))
  expect_error(
    camtrapdp_to_internal(dp, tz = "UTC"),
    "forbids automatic endpoint copying"
  )
})

test_that("CamtrapDP collisions and broken references fail without row loss", {
  deployments <- tibble(
    deploymentID = "dep1",
    locationID = "loc1",
    locationName = "Site 1",
    latitude = 1,
    longitude = 2,
    deploymentStart = as.POSIXct("2020-01-01", tz = "UTC"),
    deploymentEnd = as.POSIXct("2020-01-03", tz = "UTC"),
    featureType = "trail"
  )
  observations <- tibble(
    observationID = c("obs1", "obs2"),
    deploymentID = c("dep1", "dep1"),
    eventStart = as.POSIXct(
      c("2020-01-02 10:00:00", "2020-01-02 11:00:00"),
      tz = "UTC"
    ),
    scientificName = c("Foo bar-baz", "Foo bar baz"),
    count = c(1L, 1L),
    flash = c(1L, 1L),
    lifeStage = c("adult", "adult"),
    sex = c("unknown", "unknown"),
    mediaID = c(NA_character_, NA_character_)
  )
  expect_error(
    camtrapdp_to_internal(
      goal006_camtrapdp_object(deployments, observations),
      tz = "UTC",
      include_audit = TRUE
    ),
    "mapping collides"
  )

  observations$scientificName <- c("Canis lupus", "Vulpes vulpes")
  observations$deploymentID[[2]] <- "missing"
  expect_error(
    camtrapdp_to_internal(
      goal006_camtrapdp_object(deployments, observations),
      tz = "UTC",
      include_audit = TRUE
    ),
    "deployment key is unresolved"
  )
})

goal005_camtrapdp_config <- function(descriptor, mode = "local", cache_dir = tempfile()) {
  config <- default_config()
  config$input_mode <- "camtrapdp"
  config$schema_version_path <- here("schema_version.txt")
  config$paths$inputs <- list(
    site = NULL,
    op = NULL,
    obs = NULL,
    taxa = NULL,
    camtrapdp = descriptor
  )
  config$camtrapdp_acquisition <- list(
    mode = mode,
    cache_dir = cache_dir,
    descriptor_sha256 = NULL,
    resource_sha256 = list()
  )
  config
}

test_that("local CamtrapDP acquisition pins every referenced resource before parse", {
  fixture <- here("tests", "testthat", "fixtures", "goal005", "camtrapdp")
  config <- goal005_camtrapdp_config(file.path(fixture, "datapackage.json"))
  stage <- tempfile("goal005-camtrap-local-")
  dir.create(stage)
  snapshot <- materialize_source_snapshot(config, stage)

  paths <- vapply(snapshot$inventory, `[[`, character(1), "path")
  expect_true(all(c(
    "source_snapshot/camtrapdp/datapackage.json",
    "source_snapshot/camtrapdp/deployments.csv",
    "source_snapshot/camtrapdp/media.csv",
    "source_snapshot/camtrapdp/observations.csv",
    "source_snapshot/schema/schema_version.txt"
  ) %in% paths))
  expect_equal(
    sha256_file(file.path(fixture, "datapackage.json")),
    sha256_file(snapshot$parser_paths$camtrapdp)
  )
  expect_true(verify_source_snapshot(snapshot, stage))
  package <- frictionless::read_package(snapshot$parser_paths$camtrapdp)
  parsed <- lapply(
    c("deployments", "media", "observations"),
    function(name) frictionless::read_resource(package, name)
  )
  expect_equal(vapply(parsed, nrow, integer(1)), rep(1L, 3L))

  write("tamper", file.path(
    stage,
    "source_snapshot",
    "camtrapdp",
    "observations.csv"
  ), append = TRUE)
  expect_error(
    verify_source_snapshot(snapshot, stage),
    "Source snapshot integrity mismatch"
  )
})

test_that("CamtrapDP missing resources and pinned mismatches fail before analysis", {
  fixture <- here("tests", "testthat", "fixtures", "goal005", "camtrapdp")
  broken <- tempfile("goal005-camtrap-broken-")
  fs::dir_copy(fixture, broken)
  unlink(file.path(broken, "observations.csv"))
  config <- goal005_camtrapdp_config(file.path(broken, "datapackage.json"))
  stage <- tempfile("goal005-camtrap-stage-")
  dir.create(stage)
  expect_error(
    materialize_source_snapshot(config, stage),
    "missing or not a file"
  )

  descriptor_url <- "https://example.test/datapackage.json"
  config <- goal005_camtrapdp_config(
    descriptor_url,
    mode = "remote",
    cache_dir = tempfile("goal005-camtrap-cache-")
  )
  config$camtrapdp_acquisition$descriptor_sha256 <- paste(rep("0", 64L), collapse = "")
  config <- validate_config(config)
  fetch <- function(source, destination) {
    file.copy(file.path(fixture, "datapackage.json"), destination)
    invisible(destination)
  }
  mismatch_stage <- tempfile("goal005-camtrap-stage-")
  dir.create(mismatch_stage)
  expect_error(
    materialize_source_snapshot(config, mismatch_stage, fetch = fetch),
    "Pinned CamtrapDP digest mismatch"
  )
})
