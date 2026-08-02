#!/usr/bin/env Rscript

test_profile_usage <- paste(
  "Usage: Rscript scripts/run_tests.R",
  "[--profile fast|release|all]"
)

parse_test_profile <- function(args) {
  if (length(args) == 0L) {
    return("fast")
  }
  if (length(args) == 1L && identical(args[[1L]], "--profile")) {
    stop(
      "--profile requires exactly one value: fast, release, or all.\n",
      test_profile_usage,
      call. = FALSE
    )
  }
  if (length(args) != 2L || !identical(args[[1L]], "--profile")) {
    stop(
      "Expected no arguments or exactly --profile <profile>.\n",
      test_profile_usage,
      call. = FALSE
    )
  }

  profile <- args[[2L]]
  if (!profile %in% c("fast", "release", "all")) {
    stop(
      "Unknown test profile '", profile, "'.\n",
      test_profile_usage,
      call. = FALSE
    )
  }
  profile
}

test_profile_directories <- function(profile, project_root = here::here()) {
  fast_dir <- file.path(project_root, "tests", "testthat")
  release_dir <- file.path(fast_dir, "release")

  switch(
    profile,
    fast = fast_dir,
    release = release_dir,
    all = c(fast_dir, release_dir),
    stop("Unknown test profile '", profile, "'.", call. = FALSE)
  )
}

run_test_profile <- function(
    profile,
    project_root = here::here(),
    test_dir = testthat::test_dir) {
  test_directories <- test_profile_directories(profile, project_root)
  for (test_directory in test_directories) {
    test_dir(
      test_directory,
      stop_on_failure = TRUE,
      stop_on_warning = FALSE
    )
  }
  invisible(test_directories)
}

run_tests_cli <- function(
    args = commandArgs(trailingOnly = TRUE),
    project_root = here::here(),
    test_dir = testthat::test_dir) {
  profile <- parse_test_profile(args)
  run_test_profile(profile, project_root, test_dir)
}

if (sys.nframe() == 0L) {
  run_tests_cli()
}
