import::from(
  "testthat",
  test_that,
  expect_equal,
  expect_error,
  expect_false,
  expect_setequal,
  expect_true
)
import::from("here", here)

source(here("R", "fixity.R"))
source(here("R", "config_identity.R"))
source(here("R", "run_identity.R"))
source(here("R", "custom_funcs.R"))
source(here("R", "community_matrices.R"))
source(here("R", "selected_resolution.R"))
source(here("R", "run_bundle.R"))
source(here("scripts", "run_full_evidence_run.R"))
source(here("scripts", "verify_published_bundle.R"))

workflow_fixture <- function(copy_sources = FALSE) {
  helpers <- load_runner_helpers(here())
  root <- tempfile("goal011-workflow-")
  dir.create(root)
  source_root <- normalizePath(here(
    "tests", "testthat", "fixtures", "goal006", "four_table_clean"
  ))
  if (isTRUE(copy_sources)) {
    copied_source_root <- file.path(root, "inputs")
    fs::dir_copy(source_root, copied_source_root)
    source_root <- normalizePath(copied_source_root)
  }
  config <- helpers$default_config()
  config$schema_version_path <- normalizePath(here("schema_version.txt"))
  config$timezone_fixed_offset_hours <- 10
  config$paths$inputs <- list(
    site = file.path(source_root, "site.csv"),
    op = file.path(source_root, "op.csv"),
    obs = file.path(source_root, "obs.csv"),
    taxa = file.path(source_root, "taxa.csv"),
    camtrapdp = NULL
  )
  config$paths$outputs <- file.path(root, "outputs")
  config_path <- file.path(root, "config.yml")
  yaml::write_yaml(config, config_path)
  list(
    root = root,
    source_root = source_root,
    source_fixity = lapply(
      list.files(source_root, full.names = TRUE),
      sha256_file
    ),
    config_path = config_path,
    outputs_root = config$paths$outputs
  )
}

run_workflow_cli <- function(config_path, validation_only = FALSE) {
  arguments <- c(
    here("scripts", "run_full_evidence_run.R"),
    "--config",
    config_path,
    if (isTRUE(validation_only)) "--validate-only" else character()
  )
  output <- system2("Rscript", arguments, stdout = TRUE, stderr = TRUE)
  status <- attr(output, "status")
  if (is.null(status)) status <- 0L
  expect_equal(status, 0L, info = paste(output, collapse = "\n"))
  output
}

test_that("current seven-stage workflow publishes one verifiable bundle", {
  fixture <- workflow_fixture()
  run_workflow_cli(fixture$config_path)
  run_id <- trimws(readLines(latest_pointer_path(fixture$outputs_root)))
  bundle <- file.path(fixture$outputs_root, "runs", run_id)
  independently_verified <- verify_published_bundle_independent(bundle)
  manifest <- jsonlite::read_json(
    file.path(bundle, "run_manifest.json"),
    simplifyVector = FALSE
  )
  status <- jsonlite::read_json(
    file.path(bundle, manifest$module_status),
    simplifyVector = FALSE
  )
  report_html <- paste(
    readLines(file.path(bundle, manifest$report), warn = FALSE),
    collapse = "\n"
  )
  report_source <- paste(
    readLines(file.path(bundle, "report", "report.qmd"), warn = FALSE),
    collapse = "\n"
  )
  source_ledger <- jsonlite::read_json(
    file.path(bundle, manifest$audit$events$source_row_ledger),
    simplifyVector = TRUE
  )

  expect_equal(manifest$manifest_schema, "camtrap-run-bundle/2.0")
  expect_true(independently_verified$valid)
  expect_true(all(vapply(c(
    "Sampling and observed richness",
    "Detected community differences",
    "Operational-event detection rates",
    "Broad day/night patterns"
  ), grepl, logical(1), x = report_html, fixed = TRUE)))
  expect_false(grepl("knitr::kable(diel", report_source, fixed = TRUE))
  expect_equal(independently_verified$events, 2L)
  expect_equal(independently_verified$source_memberships, 2L)
  expect_equal(source_ledger$disposition_scope, "event_formation")
  observation_rows <- source_ledger$records[
    source_ledger$records$logical_name == "obs", , drop = FALSE
  ]
  expect_equal(sum(observation_rows$disposition == "retained"), 2L)
  expect_equal(
    observation_rows$rule_id[observation_rows$disposition == "excluded"],
    "effort.not_operational/1.0"
  )
  expect_setequal(
    vapply(status$records, `[[`, character(1), "module"),
    c(
      "effort_coverage", "observed_presence", "observed_richness",
      "jaccard", "operational_event_detection_rate", "coarse_day_night",
      "species_accumulation", "point_map", "event_gap_sensitivity"
    )
  )
  expect_false(any(vapply(
    status$records,
    function(record) identical(record$status, "failed"),
    logical(1)
  )))
  partial_manifest <- manifest
  partial_manifest$outputs$community_presence <- NULL
  partial_records <- status$records
  presence_index <- which(vapply(
    partial_records, function(record) record$module == "observed_presence",
    logical(1)
  ))
  partial_records[[presence_index]]$status <- "omitted"
  partial_records[[presence_index]]$reason <- "tampered partial core"
  expect_error(verify_selected_ecology(
    bundle, partial_manifest, verify_event_consequences(bundle, manifest),
    partial_records
  ), "partially")
  expect_equal(
    basename(resolve_latest_bundle(fixture$outputs_root)),
    run_id
  )
  expect_equal(
    lapply(list.files(fixture$source_root, full.names = TRUE), sha256_file),
    fixture$source_fixity
  )

  tamper_root <- tempfile("goal011-completion-")
  dir.create(tamper_root)
  tampered_bundle <- file.path(tamper_root, run_id)
  fs::dir_copy(bundle, tampered_bundle)
  completion_path <- file.path(tampered_bundle, "COMPLETE.json")
  completion <- jsonlite::read_json(completion_path, simplifyVector = FALSE)
  completion$manifest_sha256 <- paste(rep("0", 64L), collapse = "")
  jsonlite::write_json(
    completion,
    completion_path,
    auto_unbox = TRUE,
    pretty = TRUE
  )
  expect_error(
    verify_published_bundle_independent(tampered_bundle),
    "completion"
  )

  semantic_root <- tempfile("goal011-semantic-")
  dir.create(semantic_root)
  semantic_bundle <- file.path(semantic_root, run_id)
  fs::dir_copy(bundle, semantic_bundle)
  semantic_manifest_path <- file.path(semantic_bundle, "run_manifest.json")
  semantic_manifest <- jsonlite::read_json(
    semantic_manifest_path,
    simplifyVector = FALSE
  )
  jaccard_relative <- semantic_manifest$outputs$jaccard
  jaccard_path <- file.path(semantic_bundle, jaccard_relative)
  jaccard <- utils::read.csv(jaccard_path, stringsAsFactors = FALSE)
  jaccard$jaccard_dissimilarity[[1L]] <- 0.5
  utils::write.csv(jaccard, jaccard_path, row.names = FALSE, na = "")
  payload_paths <- vapply(
    semantic_manifest$payload,
    `[[`,
    character(1),
    "path"
  )
  payload_index <- match(jaccard_relative, payload_paths)
  semantic_manifest$payload[[payload_index]]$bytes <-
    unname(as.numeric(file.info(jaccard_path)$size))
  semantic_manifest$payload[[payload_index]]$sha256 <- sha256_file(jaccard_path)
  jsonlite::write_json(
    semantic_manifest,
    semantic_manifest_path,
    auto_unbox = TRUE,
    pretty = TRUE,
    null = "null",
    na = "null",
    digits = NA
  )
  semantic_completion_path <- file.path(semantic_bundle, "COMPLETE.json")
  semantic_completion <- jsonlite::read_json(
    semantic_completion_path,
    simplifyVector = FALSE
  )
  semantic_completion$manifest_sha256 <- sha256_file(semantic_manifest_path)
  jsonlite::write_json(
    semantic_completion,
    semantic_completion_path,
    auto_unbox = TRUE,
    pretty = TRUE,
    null = "null",
    na = "null",
    digits = NA
  )
  expect_error(
    verify_published_bundle_independent(semantic_bundle),
    "reconstruct"
  )

  second_root <- tempfile("goal011-atomic-")
  stage <- file.path(second_root, "runs", ".staging", run_id)
  dir.create(dirname(stage), recursive = TRUE)
  fs::dir_copy(bundle, stage)
  unlink(file.path(stage, "COMPLETE.json"))
  receipt <- jsonlite::read_json(
    file.path(stage, "READY"),
    simplifyVector = FALSE
  )
  dir.create(second_root, recursive = TRUE, showWarnings = FALSE)
  atomic_replace_text("pre-existing-pointer", latest_pointer_path(second_root))
  pointer_before <- readBin(
    latest_pointer_path(second_root),
    "raw",
    n = file.info(latest_pointer_path(second_root))$size
  )
  expect_error(
    publish_current_bundle(
      stage,
      second_root,
      run_id,
      receipt,
      fail_before_latest = TRUE
    ),
    "Injected failure"
  )
  expect_equal(
    readBin(
      latest_pointer_path(second_root),
      "raw",
      n = file.info(latest_pointer_path(second_root))$size
    ),
    pointer_before
  )
  published <- file.path(second_root, "runs", run_id)
  expect_true(verify_current_bundle(published)$valid)
  write("tampered", file.path(published, "tables", "selected_jaccard.csv"),
        append = TRUE)
  expect_error(verify_current_bundle(published), "fixity mismatch")
})

test_that("ineligible generic grouping publishes viable physical modules", {
  fixture <- workflow_fixture(copy_sources = TRUE)
  obs <- utils::read.csv(
    file.path(fixture$source_root, "obs.csv"),
    stringsAsFactors = FALSE
  )
  obs$flash[[1L]] <- NA
  utils::write.csv(
    obs, file.path(fixture$source_root, "obs.csv"), row.names = FALSE, na = ""
  )
  site <- utils::read.csv(
    file.path(fixture$source_root, "site.csv"),
    stringsAsFactors = FALSE
  )
  site$lat[site$site == "jc_b"] <- NA
  utils::write.csv(
    site, file.path(fixture$source_root, "site.csv"), row.names = FALSE, na = ""
  )
  config <- yaml::read_yaml(fixture$config_path)
  mapping_path <- here(
    "tests", "testthat", "fixtures", "goal011",
    "generic_analysis_site_mapping.csv"
  )
  config$analysis_unit <- list(
    resolution = "analysis_site",
    mapping_profile_id = "generic-two-camera/1.0.0",
    mapping_path = file.path(
      "tests", "testthat", "fixtures", "goal011",
      "generic_analysis_site_mapping.csv"
    ),
    mapping_sha256 = sha256_file(mapping_path),
    authority_reference = "test-fixture-generic-two-camera/1.0.0"
  )
  yaml::write_yaml(config, fixture$config_path)

  run_workflow_cli(fixture$config_path)

  run_id <- trimws(readLines(latest_pointer_path(fixture$outputs_root)))
  bundle <- file.path(fixture$outputs_root, "runs", run_id)
  verified <- verify_published_bundle_independent(bundle)
  manifest <- jsonlite::read_json(
    file.path(bundle, "run_manifest.json"),
    simplifyVector = FALSE
  )
  status <- jsonlite::read_json(
    file.path(bundle, manifest$module_status),
    simplifyVector = FALSE
  )
  records <- stats::setNames(
    status$records,
    vapply(status$records, `[[`, character(1), "module")
  )

  expect_true(verified$valid)
  selected_summary <- jsonlite::read_json(
    file.path(bundle, manifest$audit$selected_resolution$summary),
    simplifyVector = FALSE
  )
  expect_false(selected_summary$route_eligible)
  expect_true(all(vapply(
    records[c(
      "effort_coverage", "observed_presence", "observed_richness", "jaccard"
    )],
    function(record) identical(record$status, "omitted"),
    logical(1)
  )))
  expect_equal(records$coarse_day_night$status, "completed_with_warnings")
  expect_equal(records$species_accumulation$status, "completed_with_warnings")
  expect_equal(records$point_map$status, "completed_with_warnings")
  expect_true(grepl("Classified 1 of 2", records$coarse_day_night$reason))
  expect_true(grepl("jc_b", records$species_accumulation$reason))
  expect_true(grepl("Mapped 1 of 2", records$point_map$reason))
  expect_true(file.exists(file.path(bundle, manifest$report)))
  expect_true(is.null(manifest$outputs$community_presence))
  expect_false("event_membership" %in% names(manifest$audit$validation))
  expect_equal(
    manifest$audit$events$event_membership,
    "provenance/event_membership.csv"
  )
})
