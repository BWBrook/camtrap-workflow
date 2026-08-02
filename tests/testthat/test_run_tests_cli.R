runner_path <- here::here("scripts", "run_tests.R")

source_test_runner <- function() {
  runner <- new.env(parent = globalenv())
  sys.source(runner_path, envir = runner)
  runner
}

test_that("the sourceable parser accepts only documented CLI forms", {
  expect_silent(runner <- source_test_runner())
  parse_profile <- runner$parse_test_profile
  valid_args <- list(
    character(),
    c("--profile", "fast"),
    c("--profile", "release"),
    c("--profile", "all")
  )
  valid_profiles <- c("fast", "fast", "release", "all")
  invalid_args <- list(
    "--profile",
    c("--profile", "slow"),
    "release",
    c("--profile", "fast", "extra")
  )
  invalid_errors <- c(
    "--profile requires exactly one value",
    "Unknown test profile 'slow'",
    rep("Expected no arguments or exactly", 2L)
  )

  for (index in seq_along(valid_args)) {
    expect_identical(parse_profile(valid_args[[index]]), valid_profiles[[index]])
  }
  for (index in seq_along(invalid_args)) {
    expect_error(parse_profile(invalid_args[[index]]), invalid_errors[[index]])
  }
})

test_that("all runs both profiles strictly and test failures propagate", {
  runner <- source_test_runner()
  project_root <- file.path(tempdir(), "camtrap-workflow")
  fast_dir <- file.path(project_root, "tests", "testthat")
  release_dir <- file.path(fast_dir, "release")
  paths <- character()
  settings <- list()
  record_test_dir <- function(
      path,
      stop_on_failure,
      stop_on_warning) {
    paths <<- c(paths, path)
    settings[[length(settings) + 1L]] <<- c(stop_on_failure, stop_on_warning)
  }

  expect_no_error(runner$run_tests_cli(
    c("--profile", "all"),
    project_root = project_root,
    test_dir = record_test_dir
  ))

  expect_identical(paths, c(fast_dir, release_dir))
  expect_identical(settings, rep(list(c(TRUE, FALSE)), 2L))

  attempted <- NULL
  fail_test_dir <- function(path, ...) {
    attempted <<- path
    stop("injected test failure")
  }
  expect_error(
    runner$run_tests_cli(character(), project_root, fail_test_dir),
    "injected test failure"
  )
  expect_identical(attempted, fast_dir)
})
