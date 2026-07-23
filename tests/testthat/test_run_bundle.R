import::from(
  "testthat",
  test_that,
  expect_equal,
  expect_error,
  expect_false,
  expect_true
)
import::from("here", here)

source(here("R", "config_identity.R"))
source(here("R", "fixity.R"))
source(here("R", "run_identity.R"))
source(here("R", "config.R"))
source(here("R", "source_inventory.R"))
source(here("R", "run_bundle.R"))
source(here("R", "run_manifest.R"))

goal005_bundle_stage <- function(outputs_root, run_id) {
  stage <- file.path(outputs_root, "runs", ".staging", run_id)
  dir.create(file.path(stage, "report"), recursive = TRUE)
  dir.create(file.path(stage, "exports"), recursive = TRUE)
  dir.create(file.path(stage, "provenance"), recursive = TRUE)
  dir.create(file.path(stage, "source_snapshot", "four_table"), recursive = TRUE)

  raw_config <- file.path(stage, "provenance", "config.raw.yml")
  snapshot_config_file(here("config.template_example.yml"), raw_config)
  config <- read_config(raw_config, attach_runtime = FALSE)
  source_file <- file.path(stage, "source_snapshot", "four_table", "obs.csv")
  writeLines("site,species\nsite1,sp1", source_file)
  source_records <- list(file_fixity_record(
    source_file,
    stage,
    role = "parser_input",
    consumed = TRUE
  ))
  source_sha256 <- fixity_identity(source_records)
  engine <- list(
    engine_schema = "camtrap-engine-identity/1.0",
    git_commit = "abc123",
    git_dirty = FALSE,
    git_status = character(),
    git_diff_sha256 = sha256_text(""),
    r_version = R.version.string,
    platform = R.version$platform,
    package_versions = list(list(package = "targets", version = "1.0.0")),
    files = list(list(
      path = "_targets.R",
      bytes = 1,
      sha256 = paste(rep("a", 64L), collapse = "")
    ))
  )
  engine$engine_sha256 <- engine_identity_fingerprint(engine)
  config_hashes <- config_fingerprints(raw_config, config)
  fingerprints <- list(
    source = source_sha256,
    config = list(
      raw = config_hashes$raw_sha256,
      resolved = config_hashes$resolved_sha256
    ),
    engine = engine$engine_sha256
  )
  fingerprints$composite <- composite_fingerprint(
    fingerprints$source,
    fingerprints$config$resolved,
    fingerprints$engine
  )

  context <- list(
    supported_full_run = TRUE,
    run_id = run_id,
    created_utc = "2026-07-23T12:34:56Z",
    legacy_run_label = config$run_id,
    config_file = raw_config,
    config_source_name = "config.template_example.yml",
    fingerprints = fingerprints,
    engine = engine,
    provenance = list(
      raw_config = raw_config,
      effective_config = file.path(stage, "provenance", "effective_config.json"),
      source_inventory = file.path(stage, "provenance", "source_inventory.json")
    )
  )
  snapshot <- list(
    source_sha256 = source_sha256,
    acquisition = list(
      input_mode = "four_table",
      acquisition_mode = "local",
      cache_policy = "not-applicable"
    ),
    inventory = source_records
  )
  write_source_inventory(
    snapshot,
    run_id,
    context$provenance$source_inventory
  )
  write_effective_config(
    config,
    context,
    context$provenance$effective_config
  )

  writeLines(paste("report", run_id), file.path(stage, "report", "report.html"))
  saveRDS(
    list(params = list(evidence_run = list(id = run_id))),
    file.path(stage, "report", "report_inputs.rds")
  )
  writeLines("export", file.path(stage, "exports", "data.csv"))
  write_run_manifest(
    path = file.path(stage, "run_manifest.json"),
    schema_version = "0.1.0",
    params = config,
    outputs = list(
      report = list(html = file.path(stage, "report", "report.html")),
      exports = list(data = file.path(stage, "exports", "data.csv"))
    ),
    session_info_path = file.path(stage, "report", "report_inputs.rds"),
    config_file = raw_config,
    context = context
  )
  stage
}

goal005_reclose_bundle <- function(bundle) {
  manifest_file <- manifest_path(bundle)
  manifest <- jsonlite::read_json(manifest_file, simplifyVector = FALSE)
  manifest$payload <- payload_inventory(bundle)
  jsonlite::write_json(
    manifest,
    manifest_file,
    pretty = TRUE,
    auto_unbox = TRUE,
    null = "null",
    na = "null",
    digits = NA
  )

  completion_file <- completion_path(bundle)
  completion <- jsonlite::read_json(completion_file, simplifyVector = FALSE)
  completion$manifest_sha256 <- sha256_file(manifest_file)
  jsonlite::write_json(
    completion,
    completion_file,
    pretty = TRUE,
    auto_unbox = TRUE,
    null = "null",
    na = "null",
    digits = NA
  )
  invisible(bundle)
}

test_that("publication is non-overwriting and identity agrees through latest", {
  root <- tempfile("goal005-output-")
  first_id <- "20260723T123456Z-0000000000000001"
  first_stage <- goal005_bundle_stage(root, first_id)
  final <- publish_run_bundle(first_stage, root, first_id)
  verified <- verify_run_bundle(final)

  expect_true(verified$valid)
  expect_equal(verified$run_id, first_id)
  expect_equal(basename(resolve_latest_bundle(root)), first_id)
  expect_equal(readLines(latest_pointer_path(root)), first_id)

  collision <- goal005_bundle_stage(root, first_id)
  expect_error(
    publish_run_bundle(collision, root, first_id),
    "Refusing to overwrite"
  )
  expect_true(verify_run_bundle(final)$valid)
})

test_that("failure after directory publication preserves the prior latest", {
  root <- tempfile("goal005-output-")
  first_id <- "20260723T123456Z-0000000000000001"
  second_id <- "20260723T123456Z-0000000000000002"
  publish_run_bundle(goal005_bundle_stage(root, first_id), root, first_id)
  pointer_before <- readBin(latest_pointer_path(root), "raw", n = 1000L)

  expect_error(
    publish_run_bundle(
      goal005_bundle_stage(root, second_id),
      root,
      second_id,
      fail_after_publish = TRUE
    ),
    "Injected failure"
  )

  pointer_after <- readBin(latest_pointer_path(root), "raw", n = 1000L)
  expect_equal(pointer_after, pointer_before)
  expect_equal(basename(resolve_latest_bundle(root)), first_id)
  expect_true(verify_run_bundle(file.path(root, "runs", second_id))$valid)
})

test_that("tamper and exact-payload violations fail verification", {
  root <- tempfile("goal005-output-")
  run_id <- "20260723T123456Z-0000000000000001"
  final <- publish_run_bundle(goal005_bundle_stage(root, run_id), root, run_id)

  write("tampered", file.path(final, "report", "report.html"), append = TRUE)
  expect_error(verify_run_bundle(final), "fixity mismatch")

  second_root <- tempfile("goal005-output-")
  second <- "20260723T123456Z-0000000000000002"
  second_final <- publish_run_bundle(
    goal005_bundle_stage(second_root, second),
    second_root,
    second
  )
  writeLines("extra", file.path(second_final, "EXTRA.txt"))
  expect_error(verify_run_bundle(second_final), "payload set mismatch")
})

test_that("checksum-reclosed provenance inconsistencies fail verification", {
  source_root <- tempfile("goal005-output-")
  source_id <- "20260723T123456Z-0000000000000011"
  source_final <- publish_run_bundle(
    goal005_bundle_stage(source_root, source_id),
    source_root,
    source_id
  )
  source_file <- file.path(source_final, "provenance", "source_inventory.json")
  source <- jsonlite::read_json(source_file, simplifyVector = FALSE)
  source$source_sha256 <- paste(rep("0", 64L), collapse = "")
  jsonlite::write_json(source, source_file, pretty = TRUE, auto_unbox = TRUE)
  goal005_reclose_bundle(source_final)
  expect_error(verify_run_bundle(source_final), "Source inventory fingerprint")

  config_root <- tempfile("goal005-output-")
  config_id <- "20260723T123456Z-0000000000000012"
  config_final <- publish_run_bundle(
    goal005_bundle_stage(config_root, config_id),
    config_root,
    config_id
  )
  effective_file <- file.path(config_final, "provenance", "effective_config.json")
  effective <- jsonlite::read_json(effective_file, simplifyVector = FALSE)
  effective$fingerprints$resolved <- paste(rep("0", 64L), collapse = "")
  jsonlite::write_json(effective, effective_file, pretty = TRUE, auto_unbox = TRUE)
  goal005_reclose_bundle(config_final)
  expect_error(verify_run_bundle(config_final), "Resolved configuration fingerprint")

  engine_root <- tempfile("goal005-output-")
  engine_id <- "20260723T123456Z-0000000000000013"
  engine_final <- publish_run_bundle(
    goal005_bundle_stage(engine_root, engine_id),
    engine_root,
    engine_id
  )
  engine_manifest_file <- manifest_path(engine_final)
  engine_manifest <- jsonlite::read_json(
    engine_manifest_file,
    simplifyVector = FALSE
  )
  engine_manifest$engine$package_versions[[1]]$version <- "9.9.9"
  jsonlite::write_json(
    engine_manifest,
    engine_manifest_file,
    pretty = TRUE,
    auto_unbox = TRUE
  )
  goal005_reclose_bundle(engine_final)
  expect_error(verify_run_bundle(engine_final), "Engine fingerprint")

  composite_root <- tempfile("goal005-output-")
  composite_id <- "20260723T123456Z-0000000000000014"
  composite_final <- publish_run_bundle(
    goal005_bundle_stage(composite_root, composite_id),
    composite_root,
    composite_id
  )
  effective_file <- file.path(composite_final, "provenance", "effective_config.json")
  effective <- jsonlite::read_json(effective_file, simplifyVector = FALSE)
  changed <- paste(rep("0", 64L), collapse = "")
  effective$config$evidence_run$composite_sha256 <- changed
  jsonlite::write_json(effective, effective_file, pretty = TRUE, auto_unbox = TRUE)
  manifest_file <- manifest_path(composite_final)
  manifest <- jsonlite::read_json(manifest_file, simplifyVector = FALSE)
  manifest$fingerprints$composite <- changed
  jsonlite::write_json(manifest, manifest_file, pretty = TRUE, auto_unbox = TRUE)
  goal005_reclose_bundle(composite_final)
  expect_error(verify_run_bundle(composite_final), "Composite fingerprint")
})

test_that("payload files may not be symlinks", {
  root <- tempfile("goal005-output-")
  run_id <- "20260723T123456Z-0000000000000021"
  final <- publish_run_bundle(goal005_bundle_stage(root, run_id), root, run_id)
  report <- file.path(final, "report", "report.html")
  external <- tempfile("goal005-external-report-")
  file.copy(report, external)
  unlink(report)
  expect_true(file.symlink(external, report))
  expect_error(verify_run_bundle(final), "symlink")
})

test_that("latest resolver rejects traversal, separators, symlinks, and unknown IDs", {
  root <- tempfile("goal005-output-")
  run_id <- "20260723T123456Z-0000000000000001"
  final <- publish_run_bundle(goal005_bundle_stage(root, run_id), root, run_id)
  pointer <- latest_pointer_path(root)

  for (invalid in c("/tmp/escape", "../escape", "nested/run", "unknown")) {
    writeLines(invalid, pointer)
    expect_error(resolve_latest_bundle(root))
  }

  unlink(pointer)
  expect_true(file.symlink(final, pointer))
  expect_error(resolve_latest_bundle(root), "symlink")
  unlink(pointer)
  update_latest_pointer(root, run_id)
  expect_equal(resolve_latest_bundle(root), final)
})

test_that("a copied bundle verifies without its repository or original root", {
  root <- tempfile("goal005-output-")
  run_id <- "20260723T123456Z-0000000000000001"
  final <- publish_run_bundle(goal005_bundle_stage(root, run_id), root, run_id)
  portable_root <- tempfile("goal005-portable-")
  dir.create(portable_root)
  copied <- file.path(portable_root, run_id)
  fs::dir_copy(final, copied)

  result <- verify_run_bundle(copied)
  manifest <- jsonlite::read_json(manifest_path(copied), simplifyVector = FALSE)
  paths <- vapply(manifest$payload, `[[`, character(1), "path")

  expect_true(result$valid)
  expect_true(all(c(
    "exports/data.csv",
    "report/report.html",
    "report/report_inputs.rds"
  ) %in% paths))
  expect_false(any(fs::is_absolute_path(paths)))
})
