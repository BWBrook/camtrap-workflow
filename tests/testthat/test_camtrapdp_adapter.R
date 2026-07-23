import::from("testthat", test_that, expect_error, expect_true, expect_equal)
import::from("tibble", tibble)
import::from("here", here)

source(here("R", "config_identity.R"))
source(here("R", "fixity.R"))
source(here("R", "config.R"))
source(here("R", "source_inventory.R"))
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

test_that("local CamtrapDP acquisition snapshots every referenced resource before parse", {
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

test_that("CamtrapDP descriptor byte-only changes alter source identity", {
  fixture <- here("tests", "testthat", "fixtures", "goal005", "camtrapdp")
  changed <- tempfile("goal005-camtrap-descriptor-")
  fs::dir_copy(fixture, changed)
  write(" ", file.path(changed, "datapackage.json"), append = TRUE)

  original_stage <- tempfile("goal005-camtrap-original-")
  changed_stage <- tempfile("goal005-camtrap-changed-")
  dir.create(original_stage)
  dir.create(changed_stage)
  original <- materialize_source_snapshot(
    goal005_camtrapdp_config(file.path(fixture, "datapackage.json")),
    original_stage
  )
  modified <- materialize_source_snapshot(
    goal005_camtrapdp_config(file.path(changed, "datapackage.json")),
    changed_stage
  )

  expect_false(identical(original$source_sha256, modified$source_sha256))
  expect_equal(
    sha256_file(file.path(changed, "datapackage.json")),
    sha256_file(modified$parser_paths$camtrapdp)
  )
  expect_true(verify_source_snapshot(modified, changed_stage))
})

test_that("mocked remote CamtrapDP acquisition is pinned and cache-backed", {
  fixture <- here("tests", "testthat", "fixtures", "goal005", "camtrapdp")
  base_url <- "https://example.test/camtrapdp/"
  descriptor_url <- paste0(base_url, "datapackage.json")
  source_map <- list(
    "https://example.test/camtrapdp/datapackage.json" = file.path(fixture, "datapackage.json"),
    "https://example.test/camtrapdp/deployments.csv" = file.path(fixture, "deployments.csv"),
    "https://example.test/camtrapdp/media.csv" = file.path(fixture, "media.csv"),
    "https://example.test/camtrapdp/observations.csv" = file.path(fixture, "observations.csv")
  )
  calls <- character()
  fetch <- function(source, destination) {
    calls <<- c(calls, source)
    if (!file.copy(source_map[[source]], destination)) {
      stop("mock fetch failed")
    }
    invisible(destination)
  }

  config <- goal005_camtrapdp_config(
    descriptor_url,
    mode = "remote",
    cache_dir = tempfile("goal005-camtrap-cache-")
  )
  config$camtrapdp_acquisition$descriptor_sha256 <- sha256_file(source_map[[descriptor_url]])
  for (name in c("deployments.csv", "media.csv", "observations.csv")) {
    config$camtrapdp_acquisition$resource_sha256[[name]] <-
      sha256_file(source_map[[paste0(base_url, name)]])
  }
  config <- validate_config(config)

  first_stage <- tempfile("goal005-camtrap-remote-")
  second_stage <- tempfile("goal005-camtrap-remote-")
  dir.create(first_stage)
  dir.create(second_stage)
  first <- materialize_source_snapshot(config, first_stage, fetch = fetch)
  call_count <- length(calls)
  second <- materialize_source_snapshot(config, second_stage, fetch = fetch)

  expect_equal(call_count, 4L)
  expect_equal(length(calls), call_count)
  expect_equal(first$source_sha256, second$source_sha256)
  expect_true(verify_source_snapshot(second, second_stage))
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
