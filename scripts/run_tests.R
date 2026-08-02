#!/usr/bin/env Rscript

test_profiles <- c("fast", "release", "all")
test_profile_usage <- paste0(
  "Usage: Rscript scripts/run_tests.R ",
  "[--profile fast|release|all]"
)

stop_with_test_usage <- function(message) {
  stop(message, "\n", test_profile_usage, call. = FALSE)
}

parse_test_profile <- function(args) {
  if (length(args) == 0L) {
    return("fast")
  }
  if (length(args) == 1L && identical(args[[1L]], "--profile")) {
    stop_with_test_usage(
      "--profile requires exactly one value: fast, release, or all."
    )
  }
  if (length(args) != 2L || !identical(args[[1L]], "--profile")) {
    stop_with_test_usage(
      "Expected no arguments or exactly --profile <profile>."
    )
  }

  profile <- args[[2L]]
  if (!profile %in% test_profiles) {
    stop_with_test_usage(paste0("Unknown test profile '", profile, "'."))
  }
  profile
}

run_tests_cli <- function(
    args = commandArgs(trailingOnly = TRUE),
    project_root = here::here(),
    test_dir = testthat::test_dir) {
  profile <- parse_test_profile(args)
  fast_dir <- file.path(project_root, "tests", "testthat")
  release_dir <- file.path(fast_dir, "release")
  test_directories <- switch(
    profile,
    fast = fast_dir,
    release = release_dir,
    all = c(fast_dir, release_dir)
  )
  for (test_directory in test_directories) {
    test_dir(
      test_directory,
      stop_on_failure = TRUE,
      stop_on_warning = FALSE
    )
  }
}

if (sys.nframe() == 0L) {
  run_tests_cli()
}
