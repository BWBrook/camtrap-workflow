runner_path <- here::here("scripts", "run_tests.R")

source_test_runner <- function() {
  runner_environment <- new.env(parent = globalenv())
  sys.source(runner_path, envir = runner_environment)
  runner_environment
}

test_that("sourcing the test runner does not start a test suite", {
  testthat_namespace <- asNamespace("testthat")
  trace(
    "test_dir",
    tracer = quote(stop("test suite started while sourcing")),
    where = testthat_namespace,
    print = FALSE
  )
  on.exit(untrace("test_dir", where = testthat_namespace), add = TRUE)

  expect_no_error(source_test_runner())
})

test_that("the test profile defaults to fast and accepts explicit profiles", {
  runner <- source_test_runner()

  expect_identical(runner$parse_test_profile(character()), "fast")
  expect_identical(runner$parse_test_profile(c("--profile", "fast")), "fast")
  expect_identical(runner$parse_test_profile(c("--profile", "release")), "release")
  expect_identical(runner$parse_test_profile(c("--profile", "all")), "all")
})

test_that("the test profile rejects missing, unknown, and extra arguments", {
  runner <- source_test_runner()

  expect_error(
    runner$parse_test_profile("--profile"),
    "--profile requires exactly one value"
  )
  expect_error(
    runner$parse_test_profile(c("--profile", "slow")),
    "Unknown test profile 'slow'"
  )
  expect_error(
    runner$parse_test_profile(c("--profile", "fast", "extra")),
    "Expected no arguments or exactly --profile <profile>"
  )
  expect_error(
    runner$parse_test_profile("release"),
    "Expected no arguments or exactly --profile <profile>"
  )
})

test_that("profiles expand to the intended test directories in order", {
  runner <- source_test_runner()
  project_root <- file.path(tempdir(), "camtrap-workflow")
  fast_dir <- file.path(project_root, "tests", "testthat")
  release_dir <- file.path(fast_dir, "release")

  expect_identical(
    runner$test_profile_directories("fast", project_root),
    fast_dir
  )
  expect_identical(
    runner$test_profile_directories("release", project_root),
    release_dir
  )
  expect_identical(
    runner$test_profile_directories("all", project_root),
    c(fast_dir, release_dir)
  )
})

test_that("the CLI runs selected directories with strict testthat settings", {
  runner <- source_test_runner()
  project_root <- file.path(tempdir(), "camtrap-workflow")
  calls <- list()
  record_test_dir <- function(
      path,
      stop_on_failure,
      stop_on_warning) {
    calls[[length(calls) + 1L]] <<- list(
      path = path,
      stop_on_failure = stop_on_failure,
      stop_on_warning = stop_on_warning
    )
  }

  runner$run_tests_cli(
    c("--profile", "all"),
    project_root = project_root,
    test_dir = record_test_dir
  )

  expect_identical(
    vapply(calls, `[[`, character(1L), "path"),
    c(
      file.path(project_root, "tests", "testthat"),
      file.path(project_root, "tests", "testthat", "release")
    )
  )
  expect_true(all(vapply(calls, `[[`, logical(1L), "stop_on_failure")))
  expect_false(any(vapply(calls, `[[`, logical(1L), "stop_on_warning")))
})
