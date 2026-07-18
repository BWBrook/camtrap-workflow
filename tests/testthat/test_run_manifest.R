import::from("testthat", test_that, expect_true, expect_equal)
import::from("jsonlite", read_json)
import::from("here", here)
import::from("withr", local_envvar)

source(here("R", "run_manifest.R"))

test_that("write_run_manifest creates a JSON file with required fields", {
  tmp_dir <- tempfile()
  dir.create(tmp_dir)
  tmp <- file.path(tmp_dir, "run_manifest.json")
  config_file <- file.path(tmp_dir, "config.yml")
  writeLines("run_id: test", config_file)
  output_path <- file.path(tmp_dir, "figures", "rarefaction.png")
  dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
  file.create(output_path)
  session_info_path <- file.path(tmp_dir, "session_info.txt")
  file.create(session_info_path)

  write_run_manifest(
    path = tmp,
    schema_version = "0.1.0",
    params = list(timezone = "Australia/Hobart"),
    outputs = list(figures = list(rarefaction = output_path)),
    session_info_path = session_info_path,
    config_file = config_file
  )

  expect_true(file.exists(tmp))

  manifest <- read_json(tmp, simplifyVector = TRUE)
  expect_equal(manifest$schema_version, "0.1.0")
  expect_true("run_id" %in% names(manifest))
  expect_true("timestamp_utc" %in% names(manifest))
  expect_true("outputs" %in% names(manifest))
  expect_true(!grepl("^/", manifest$outputs$figures$rarefaction))
  expect_true(!grepl("^/", manifest$session_info))
  expect_equal(manifest$config$path, "config.yml")
})

test_that("get_git_commit uses container-provided commit metadata", {
  local_envvar(c(CAMTRAP_WORKFLOW_GIT_COMMIT = "abc123"), .local_envir = testthat::teardown_env())

  expect_equal(get_git_commit(), "abc123")
})
