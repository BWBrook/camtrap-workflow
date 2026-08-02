import::from("testthat", test_that, expect_equal)
import::from("here", here)
import::from("withr", local_envvar)

source(here("R", "run_manifest.R"))

test_that("get_git_commit uses container-provided commit metadata", {
  local_envvar(
    c(CAMTRAP_WORKFLOW_GIT_COMMIT = "abc123"),
    .local_envir = testthat::teardown_env()
  )

  expect_equal(get_git_commit(), "abc123")
})
