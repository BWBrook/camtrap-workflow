#!/usr/bin/env Rscript

test_usage <- "Usage: Rscript scripts/run_tests.R [--profile fast]"

parse_test_profile <- function(args) {
  if (length(args) == 0L) return("fast")
  if (identical(args, c("--profile", "fast"))) return("fast")
  stop("Only the current fast profile is supported.\n", test_usage, call. = FALSE)
}

run_tests_cli <- function(
    args = commandArgs(trailingOnly = TRUE),
    project_root = here::here(),
    test_dir = testthat::test_dir) {
  parse_test_profile(args)
  test_dir(
    file.path(project_root, "tests", "testthat"),
    stop_on_failure = TRUE,
    stop_on_warning = FALSE
  )
}

if (sys.nframe() == 0L) run_tests_cli()
