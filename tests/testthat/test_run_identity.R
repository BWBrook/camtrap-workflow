import::from("testthat", test_that, expect_error, expect_false, expect_match, expect_true)
import::from("here", here)

source(here("R", "run_identity.R"))

test_that("fixed-clock allocations remain unique and filesystem-safe", {
  fixed_clock <- function() as.POSIXct("2026-07-23 12:34:56", tz = "UTC")
  tokens <- c("0000000000000001", "0000000000000002")
  index <- 0L
  next_token <- function() {
    index <<- index + 1L
    tokens[[index]]
  }

  first <- allocate_run_id(clock = fixed_clock, token = next_token)
  second <- allocate_run_id(clock = fixed_clock, token = next_token)

  expect_false(identical(first, second))
  expect_match(first, "^20260723T123456Z-[a-f0-9]{16}$")
  expect_true(is_safe_run_id(first))
  expect_true(is_safe_run_id(second))
})

test_that("run IDs and compatibility labels reject path syntax", {
  expect_error(assert_safe_run_id("../escape"), "Unsafe")
  expect_error(assert_safe_run_id("/absolute"), "Unsafe")
  expect_error(assert_safe_run_id("a/b"), "Unsafe")
  expect_true(is_safe_run_id(safe_compatibility_label("Judbury run 1")))
})
