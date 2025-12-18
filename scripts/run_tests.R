#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(here)
  library(testthat)
})

testthat::test_dir(
  here("tests", "testthat"),
  stop_on_failure = TRUE,
  stop_on_warning = FALSE
)
