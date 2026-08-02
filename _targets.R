# Goal 011 top-level workflow composer.

targets::tar_source("R", envir = environment())

targets::tar_option_set(
  packages = c(
    "camtrapdp",
    "digest",
    "dplyr",
    "fs",
    "frictionless",
    "ggplot2",
    "here",
    "janitor",
    "jsonlite",
    "knitr",
    "lubridate",
    "purrr",
    "readr",
    "stringr",
    "tibble",
    "tidyr",
    "uuid",
    "vegan",
    "yaml"
  )
)

list(
  targets::tar_target(
    ingest_stage,
    run_ingest_stage(workflow_request),
    cue = targets::tar_cue(mode = "always")
  ),
  targets::tar_target(
    validation_stage,
    run_validation_stage(ingest_stage)
  ),
  targets::tar_target(
    foundation_stage,
    run_foundation_stage(validation_stage)
  ),
  targets::tar_target(
    events_stage,
    run_events_stage(foundation_stage)
  ),
  targets::tar_target(
    modules_stage,
    run_modules_stage(events_stage)
  ),
  targets::tar_target(
    report_stage,
    run_report_stage(modules_stage)
  ),
  targets::tar_target(
    bundle_stage,
    run_bundle_stage(report_stage)
  )
)
