runner_path <- here::here("scripts", "run_tests.R")

source_test_runner <- function() {
  runner <- new.env(parent = globalenv())
  sys.source(runner_path, envir = runner)
  runner
}

test_that("the test runner accepts only the current fast profile", {
  runner <- source_test_runner()
  expect_identical(runner$parse_test_profile(character()), "fast")
  expect_identical(runner$parse_test_profile(c("--profile", "fast")), "fast")
  expect_error(runner$parse_test_profile(c("--profile", "release")), "current fast")
  expect_error(runner$parse_test_profile("fast"), "current fast")
})

test_that("test failures propagate from the fast directory", {
  runner <- source_test_runner()
  project_root <- file.path(tempdir(), "camtrap-workflow")
  attempted <- NULL
  fail_test_dir <- function(path, ...) {
    attempted <<- path
    stop("injected test failure")
  }
  expect_error(
    runner$run_tests_cli(character(), project_root, fail_test_dir),
    "injected test failure"
  )
  expect_identical(
    attempted,
    file.path(project_root, "tests", "testthat")
  )
})
