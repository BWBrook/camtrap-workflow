import::from("testthat", test_that, expect_true, expect_equal)
import::from("jsonlite", read_json)
import::from("here", here)

source(here("R", "run_manifest.R"))

test_that("write_run_manifest creates a JSON file with required fields", {
  tmp <- tempfile(fileext = ".json")

  write_run_manifest(
    path = tmp,
    schema_version = "0.1.0",
    params = list(timezone = "Australia/Hobart"),
    outputs = list(figures = list(rarefaction = "path/rarefaction.png")),
    session_info_path = "path/session_info.txt"
  )

  expect_true(file.exists(tmp))

  manifest <- read_json(tmp, simplifyVector = TRUE)
  expect_equal(manifest$schema_version, "0.1.0")
  expect_true("run_id" %in% names(manifest))
  expect_true("timestamp_utc" %in% names(manifest))
  expect_true("outputs" %in% names(manifest))
})
