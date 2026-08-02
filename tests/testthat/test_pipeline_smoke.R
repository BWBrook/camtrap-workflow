import::from("testthat", test_that, expect_equal, expect_false, expect_true)
import::from("here", here)
import::from("withr", with_dir)

test_that("current report states bounded ecological claims", {
  report <- paste(readLines(here("analysis", "report.qmd")), collapse = " ")
  claims <- c(
    "not an estimate of species that went undetected",
    "do not establish environmental causes",
    "must not be interpreted as abundance or density",
    "do not support fine-scale diel inference",
    "do not interpolate habitat"
  )
  expect_true(all(vapply(
    claims,
    grepl,
    logical(1),
    x = report,
    fixed = TRUE
  )))
  expect_false(file.exists(here("analysis", "methods.qmd")))
})

test_that("targets graph exposes exactly the seven ecological stages", {
  environment <- new.env(parent = globalenv())
  environment$workflow_request <- list(
    request_schema = "camtrap-workflow-request/2.0",
    run_id = "test-run",
    created_utc = "2026-08-02T00:00:00Z",
    config_path = "config.yml",
    project_root = here(),
    outputs_root = tempfile(),
    staging_dir = tempfile(),
    target_store = tempfile(),
    fetch = function(source, destination) invisible(destination)
  )
  expected <- c(
    "ingest_stage",
    "validation_stage",
    "foundation_stage",
    "events_stage",
    "modules_stage",
    "report_stage",
    "bundle_stage"
  )
  with_dir(here(), {
    graph <- targets::tar_igraph(
      targets_only = TRUE,
      callr_function = NULL,
      envir = environment,
      script = here("_targets.R")
    )
    observed <- igraph::V(graph)$name
    expect_equal(sort(observed), sort(expected))
    for (index in seq_len(length(expected) - 1L)) {
      expect_true(
        igraph::are_adjacent(graph, expected[[index]], expected[[index + 1L]])
      )
    }
  })
})

test_that("ordinary stages have no environment or runtime-JSON handshake", {
  paths <- c(
    "_targets.R",
    "R/config.R",
    "R/run_identity.R",
    "R/workflow_stages.R",
    "scripts/run_full_evidence_run.R"
  )
  text <- paste(vapply(paths, function(path) {
    paste(readLines(here(path)), collapse = "\n")
  }, character(1)), collapse = "\n")
  expect_false(grepl("Sys.getenv", text, fixed = TRUE))
  expect_false(grepl("Sys.setenv", text, fixed = TRUE))
  expect_false(grepl("CAMTRAP_EVIDENCE_CONTEXT", text, fixed = TRUE))
  expect_false(grepl("CAMTRAP_CONFIG", text, fixed = TRUE))
})
