import::from(
  "testthat", test_that, expect_equal, expect_error, expect_false,
  expect_true
)
import::from("here", here)

source(here("R", "config_identity.R"))
source(here("R", "fixity.R"))
source(here("R", "config.R"))
source(here("R", "entity_resolution.R"))
source(here("R", "source_inventory.R"))

goal009_mapping_selection <- function() {
  list(
    resolution = "analysis_site",
    mapping_profile_id = "judbury-analysis-site/1.0.0-proposed",
    mapping_path = paste0(
      "docs/goals/009-analysis-site-vertical-slice/",
      "judbury_analysis_site_mapping.csv"
    ),
    mapping_sha256 =
      "6490d7f7021e5c727b9be1c7d6dfbf44ba50a1ef5b0396c66e1dd813a9c77083",
    authority_reference = paste0(
      "goal009-judbury-analysis-site-mapping-sha256-",
      "6490d7f7021e5c727b9be1c7d6dfbf44ba50a1ef5b0396c66e1dd813a9c77083"
    )
  )
}

goal005_four_table_config <- function(input_root) {
  config <- default_config()
  config$schema_version_path <- here("schema_version.txt")
  config$paths$inputs <- list(
    site = file.path(input_root, "site.csv"),
    op = file.path(input_root, "op.csv"),
    obs = file.path(input_root, "obs.csv"),
    taxa = file.path(input_root, "taxa.csv"),
    camtrapdp = NULL
  )
  validate_config(config)
}

copy_goal005_inputs <- function(destination) {
  source_root <- here("tests", "testthat", "fixtures", "goal005", "four_table")
  dir.create(destination, recursive = TRUE)
  for (name in c("site.csv", "op.csv", "obs.csv", "taxa.csv")) {
    file.copy(file.path(source_root, name), file.path(destination, name))
  }
  invisible(destination)
}

test_that("four-table snapshots inventory every parser-consumed byte", {
  input_root <- copy_goal005_inputs(tempfile("goal005-input-"))
  stage <- tempfile("goal005-stage-")
  dir.create(stage)
  snapshot <- materialize_source_snapshot(goal005_four_table_config(input_root), stage)

  expect_equal(length(snapshot$inventory), 5L)
  expect_true(all(vapply(
    snapshot$inventory,
    function(record) isTRUE(record$consumed_by_parser),
    logical(1)
  )))
  expect_true(verify_source_snapshot(snapshot, stage))
  expect_false(any(grepl(normalizePath(input_root), canonical_json(snapshot$inventory), fixed = TRUE)))
})

test_that("mapped analysis-site selection snapshots exactly one immutable mapping input", {
  input_root <- copy_goal005_inputs(tempfile("goal009-input-"))
  stage <- tempfile("goal009-stage-")
  dir.create(stage)
  config <- goal005_four_table_config(input_root)
  config$analysis_unit <- goal009_mapping_selection()
  validate_config(config)

  snapshot <- materialize_source_snapshot(config, stage, project_root = here())
  mapping <- snapshot$inventory[vapply(
    snapshot$inventory,
    function(record) identical(record$role, "analysis_site_mapping_input"),
    logical(1)
  )]
  expect_equal(length(mapping), 1L)
  expect_false(mapping[[1]]$consumed_by_parser)
  expect_equal(mapping[[1]]$sha256, config$analysis_unit$mapping_sha256)
  expect_equal(
    snapshot$analysis_site_mapping_path,
    file.path(stage, "source_snapshot", "analysis_site_mapping",
              "judbury_analysis_site_mapping.csv")
  )
  expect_equal(sha256_file(snapshot$analysis_site_mapping_path),
               config$analysis_unit$mapping_sha256)
  expect_true(verify_source_snapshot(snapshot, stage))

  write("sidecar", file.path(stage, "source_snapshot", "analysis_site_mapping",
                              "unexpected.txt"))
  expect_error(verify_source_snapshot(snapshot, stage), "exactly one|extra")
})

test_that("omitted and identity selections retain zero mapping inventory", {
  input_root <- copy_goal005_inputs(tempfile("goal009-legacy-input-"))
  selections <- list(
    omitted = NULL,
    identity = list(
      resolution = "analysis_site", mapping_profile_id = NULL,
      mapping_path = NULL, mapping_sha256 = NULL, authority_reference = NULL
    ),
    physical = list(
      resolution = "physical_location", mapping_profile_id = NULL,
      mapping_path = NULL, mapping_sha256 = NULL, authority_reference = NULL
    ),
    nominal = list(
      resolution = "nominal_station", mapping_profile_id = NULL,
      mapping_path = NULL, mapping_sha256 = NULL, authority_reference = NULL
    )
  )
  for (name in names(selections)) {
    selection <- selections[[name]]
    stage <- tempfile("goal009-zero-stage-")
    dir.create(stage)
    config <- goal005_four_table_config(input_root)
    if (!is.null(selection)) config$analysis_unit <- selection
    snapshot <- materialize_source_snapshot(config, stage, project_root = here())
    roles <- vapply(snapshot$inventory, `[[`, character(1), "role")
    expect_equal(sum(roles == "analysis_site_mapping_input"), 0L, info = name)
    expect_true(is.null(snapshot$analysis_site_mapping_path), info = name)
    expect_true(verify_source_snapshot(snapshot, stage), info = name)
  }
})

test_that("mapped analysis-site acquisition rejects path escape, symlink, and checksum drift", {
  input_root <- copy_goal005_inputs(tempfile("goal009-invalid-input-"))
  config <- goal005_four_table_config(input_root)
  config$analysis_unit <- goal009_mapping_selection()

  escaped <- config
  escaped$analysis_unit$mapping_path <- "../judbury_analysis_site_mapping.csv"
  expect_error(materialize_source_snapshot(escaped, tempfile("goal009-escape-")),
               "path|approved|escape")

  drifted <- config
  drifted$analysis_unit$mapping_sha256 <- paste(rep("a", 64L), collapse = "")
  expect_error(materialize_source_snapshot(drifted, tempfile("goal009-drift-")),
               "authority|SHA-256")

  symlink_root <- tempfile("goal009-symlink-root-")
  dir.create(file.path(symlink_root, "docs", "goals"), recursive = TRUE)
  approved_dir <- file.path(symlink_root, "approved-mapping")
  dir.create(approved_dir, recursive = TRUE)
  copy_goal005_inputs(file.path(symlink_root, "data"))
  file.copy(here("docs", "goals", "009-analysis-site-vertical-slice",
                 "judbury_analysis_site_mapping.csv"),
            file.path(approved_dir, "judbury_analysis_site_mapping.csv"))
  expect_true(file.symlink(
    approved_dir,
    file.path(symlink_root, "docs", "goals", "009-analysis-site-vertical-slice")
  ))
  symlink_config <- goal005_four_table_config(file.path(symlink_root, "data"))
  symlink_config$paths$inputs <- list(
    site = file.path(symlink_root, "data", "site.csv"),
    op = file.path(symlink_root, "data", "op.csv"),
    obs = file.path(symlink_root, "data", "obs.csv"),
    taxa = file.path(symlink_root, "data", "taxa.csv"),
    camtrapdp = NULL
  )
  symlink_config$analysis_unit <- config$analysis_unit
  expect_error(
    materialize_source_snapshot(
      symlink_config,
      tempfile("goal009-symlink-stage-"),
      project_root = symlink_root
    ),
    "symlink"
  )
})

test_that("mapping mutation cannot be hidden by inventory reclosure or duplicate roles", {
  input_root <- copy_goal005_inputs(tempfile("goal009-reclosure-input-"))
  config <- goal005_four_table_config(input_root)
  config$analysis_unit <- goal009_mapping_selection()
  stage <- tempfile("goal009-reclosure-stage-")
  dir.create(stage)
  snapshot <- materialize_source_snapshot(config, stage, project_root = here())
  index <- which(vapply(snapshot$inventory, function(record) {
    identical(record$role, "analysis_site_mapping_input")
  }, logical(1)))
  write("tamper", snapshot$analysis_site_mapping_path, append = TRUE)
  mutated <- file.info(snapshot$analysis_site_mapping_path)
  snapshot$inventory[[index]]$bytes <- unname(as.numeric(mutated$size))
  snapshot$inventory[[index]]$sha256 <- sha256_file(snapshot$analysis_site_mapping_path)
  snapshot$source_sha256 <- fixity_identity(snapshot$inventory)
  expect_error(verify_source_snapshot(snapshot, stage), "authority|configured|mapping")

  duplicate <- materialize_source_snapshot(
    config, tempfile("goal009-duplicate-stage-"), project_root = here()
  )
  duplicate$inventory[[length(duplicate$inventory) + 1L]] <-
    duplicate$inventory[[which(vapply(duplicate$inventory, function(record) {
      identical(record$role, "analysis_site_mapping_input")
    }, logical(1)))[[1L]]]]
  duplicate$source_sha256 <- fixity_identity(duplicate$inventory)
  expect_error(verify_source_snapshot(duplicate), "exactly one|duplicate")
})

test_that("one source byte changes identity and snapshot mutation fails fixity", {
  input_root <- copy_goal005_inputs(tempfile("goal005-input-"))
  first_stage <- tempfile("goal005-stage-")
  second_stage <- tempfile("goal005-stage-")
  dir.create(first_stage)
  dir.create(second_stage)
  config <- goal005_four_table_config(input_root)
  first <- materialize_source_snapshot(config, first_stage)

  site_path <- file.path(input_root, "site.csv")
  text <- readLines(site_path)
  writeLines(sub("-42.0", "-42.1", text, fixed = TRUE), site_path)
  second <- materialize_source_snapshot(config, second_stage)
  expect_false(identical(first$source_sha256, second$source_sha256))

  snapshotted_site <- first$parser_paths$site
  write("tamper", snapshotted_site, append = TRUE)
  expect_error(
    verify_source_snapshot(first, first_stage),
    "Source snapshot integrity mismatch"
  )
})

test_that("missing source input fails before analysis", {
  input_root <- copy_goal005_inputs(tempfile("goal005-input-"))
  unlink(file.path(input_root, "obs.csv"))
  stage <- tempfile("goal005-stage-")
  dir.create(stage)

  expect_error(
    materialize_source_snapshot(goal005_four_table_config(input_root), stage),
    "missing or not a file"
  )
})

test_that("engine identity is bounded, relative, and SHA-256 based", {
  engine <- compute_engine_identity(here())
  paths <- vapply(engine$files, `[[`, character(1), "path")
  packages <- vapply(engine$package_versions, `[[`, character(1), "package")

  expect_equal(nchar(engine$engine_sha256), 64L)
  expect_true("_targets.R" %in% paths)
  expect_true("renv.lock" %in% paths)
  expect_true("targets" %in% packages)
  expect_false(any(fs::is_absolute_path(paths)))
  expect_false(grepl(normalizePath(here()), canonical_json(engine), fixed = TRUE))

  drifted <- engine
  drifted$package_versions[[1]]$version <- paste0(
    drifted$package_versions[[1]]$version,
    "-drift"
  )
  expect_false(identical(
    engine_identity_fingerprint(engine),
    engine_identity_fingerprint(drifted)
  ))
})

test_that("approved entity sidecar is snapshotted with a distinct non-parser role", {
  input_root <- copy_goal005_inputs(tempfile("goal007-input-"))
  stage <- tempfile("goal007-stage-")
  dir.create(stage)
  config <- goal005_four_table_config(input_root)
  sidecar <- here(
    "docs",
    "goals",
    "007-entity-resolution",
    "judbury_entity_crosswalk.csv"
  )
  config$entity_resolution <- list(
    profile_id = "judbury-entity-crosswalk/1.0.0-proposed",
    sidecar_path = sidecar,
    sidecar_sha256 =
      "553abada14493f3a5f0ae3c072523b6d5cc0d0c6a6c6480ca17a9e3331f2d8ec",
    authority_reference = paste0(
      "goal007-judbury-crosswalk-sha256-",
      "553abada14493f3a5f0ae3c072523b6d5cc0d0c6a6c6480ca17a9e3331f2d8ec"
    )
  )
  snapshot <- materialize_source_snapshot(config, stage)
  roles <- vapply(snapshot$inventory, `[[`, character(1), "role")
  entity_index <- which(roles == "entity_resolution_input")

  expect_equal(length(entity_index), 1L)
  expect_false(snapshot$inventory[[entity_index]]$consumed_by_parser)
  expect_equal(
    snapshot$inventory[[entity_index]]$sha256,
    config$entity_resolution$sidecar_sha256
  )
  expect_false(snapshot$entity_resolution_path %in% snapshot$parser_files)
  expect_true(verify_source_snapshot(snapshot, stage))
})

test_that("sidecar authority and post-snapshot mutation fail fixity", {
  input_root <- copy_goal005_inputs(tempfile("goal007-input-"))
  sidecar <- here(
    "docs",
    "goals",
    "007-entity-resolution",
    "judbury_entity_crosswalk.csv"
  )
  config <- goal005_four_table_config(input_root)
  config$entity_resolution <- list(
    profile_id = "judbury-entity-crosswalk/1.0.0-proposed",
    sidecar_path = sidecar,
    sidecar_sha256 = paste(rep("a", 64L), collapse = ""),
    authority_reference = paste0(
      "goal007-judbury-crosswalk-sha256-",
      "553abada14493f3a5f0ae3c072523b6d5cc0d0c6a6c6480ca17a9e3331f2d8ec"
    )
  )
  expect_error(
    materialize_source_snapshot(config, tempfile("goal007-stage-")),
    "approved authority|SHA-256"
  )

  config$entity_resolution$sidecar_sha256 <-
    "553abada14493f3a5f0ae3c072523b6d5cc0d0c6a6c6480ca17a9e3331f2d8ec"
  stage <- tempfile("goal007-stage-")
  dir.create(stage)
  snapshot <- materialize_source_snapshot(config, stage)
  write("tamper", snapshot$entity_resolution_path, append = TRUE)
  expect_error(
    verify_source_snapshot(snapshot, stage),
    "Source snapshot integrity mismatch"
  )
})

goal008_deployment_selection <- function() {
  list(
    profile_id = "judbury-deployment-evidence/1.0.0-proposed",
    service_sidecar_path = "data/jc_services.csv",
    service_sidecar_sha256 =
      "f33eeac9d70126966717c8e3f4731c00a97cbc3a34c2f44ce5c70d91c7d5283a",
    deployment_ledger_path =
      "docs/goals/008-judbury-deployment-evidence/judbury_deployment_ledger.csv",
    deployment_ledger_sha256 =
      "0921eb8845c2bb1ad5760271f283ab2783735b7739e254c67e9243bc906f3ebf",
    authority_reference = paste0(
      "goal008-judbury-deployment-evidence-source-sha256-",
      "f33eeac9d70126966717c8e3f4731c00a97cbc3a34c2f44ce5c70d91c7d5283a-",
      "ledger-sha256-",
      "0921eb8845c2bb1ad5760271f283ab2783735b7739e254c67e9243bc906f3ebf"
    )
  )
}

goal008_selected_source_config <- function(input_root) {
  config <- goal005_four_table_config(input_root)
  config$entity_resolution <- list(
    profile_id = "judbury-entity-crosswalk/1.0.0-proposed",
    sidecar_path =
      "docs/goals/007-entity-resolution/judbury_entity_crosswalk.csv",
    sidecar_sha256 =
      "553abada14493f3a5f0ae3c072523b6d5cc0d0c6a6c6480ca17a9e3331f2d8ec",
    authority_reference = paste0(
      "goal007-judbury-crosswalk-sha256-",
      "553abada14493f3a5f0ae3c072523b6d5cc0d0c6a6c6480ca17a9e3331f2d8ec"
    )
  )
  config$deployment_evidence <- goal008_deployment_selection()
  validate_config(config)
}

test_that("deployment service and ledger use two immutable non-parser roles", {
  input_root <- copy_goal005_inputs(tempfile("goal008-input-"))
  stage <- tempfile("goal008-stage-")
  dir.create(stage)
  config <- goal008_selected_source_config(input_root)
  snapshot <- materialize_source_snapshot(config, stage, project_root = here())
  roles <- vapply(snapshot$inventory, `[[`, character(1), "role")
  deployment_roles <- c("deployment_service_input", "deployment_ledger_input")

  expect_equal(sum(roles %in% deployment_roles), 2L)
  expect_equal(length(snapshot$parser_files), 5L)
  expect_false(any(vapply(
    snapshot$inventory[roles %in% deployment_roles],
    function(record) isTRUE(record$consumed_by_parser),
    logical(1)
  )))
  expect_equal(
    sort(vapply(
      snapshot$inventory[roles %in% deployment_roles],
      `[[`,
      character(1),
      "sha256"
    )),
    sort(c(
      config$deployment_evidence$service_sidecar_sha256,
      config$deployment_evidence$deployment_ledger_sha256
    ))
  )
  expect_false(any(unlist(snapshot$deployment_evidence_paths) %in% snapshot$parser_files))
  expect_true(verify_source_snapshot(snapshot, stage))
})

test_that("deployment snapshot mutation, duplicate role, and configured symlink fail", {
  input_root <- copy_goal005_inputs(tempfile("goal008-input-"))
  config <- goal008_selected_source_config(input_root)
  stage <- tempfile("goal008-stage-")
  dir.create(stage)
  snapshot <- materialize_source_snapshot(config, stage, project_root = here())
  expect_true(is.list(snapshot$deployment_evidence_paths))
  if (!is.list(snapshot$deployment_evidence_paths)) {
    return(invisible(NULL))
  }
  write("tamper", snapshot$deployment_evidence_paths$service, append = TRUE)
  expect_error(
    verify_source_snapshot(snapshot, stage),
    "Source snapshot integrity mismatch"
  )

  stage <- tempfile("goal008-stage-")
  dir.create(stage)
  snapshot <- materialize_source_snapshot(config, stage, project_root = here())
  service_index <- which(vapply(
    snapshot$inventory,
    function(record) identical(record$role, "deployment_service_input"),
    logical(1)
  ))
  snapshot$inventory[[length(snapshot$inventory) + 1L]] <-
    snapshot$inventory[[service_index]]
  snapshot$source_sha256 <- fixity_identity(snapshot$inventory)
  expect_error(
    validate_deployment_evidence_source(
      config,
      snapshot,
      deployment_evidence_selection(config)
    ),
    "exactly one deployment service"
  )

  project_root <- tempfile("goal008-symlink-root-")
  dir.create(file.path(project_root, "data"), recursive = TRUE)
  dir.create(
    file.path(project_root, "docs", "goals", "007-entity-resolution"),
    recursive = TRUE
  )
  dir.create(
    file.path(
      project_root,
      "docs",
      "goals",
      "008-judbury-deployment-evidence"
    ),
    recursive = TRUE
  )
  file.copy(
    here(
      "docs",
      "goals",
      "007-entity-resolution",
      "judbury_entity_crosswalk.csv"
    ),
    file.path(
      project_root,
      "docs",
      "goals",
      "007-entity-resolution",
      "judbury_entity_crosswalk.csv"
    )
  )
  file.copy(
    here(
      "tests",
      "testthat",
      "fixtures",
      "goal008",
      "judbury_deployment_ledger.csv"
    ),
    file.path(
      project_root,
      "docs",
      "goals",
      "008-judbury-deployment-evidence",
      "judbury_deployment_ledger.csv"
    )
  )
  expect_true(file.symlink(
    here("tests", "testthat", "fixtures", "goal008", "jc_services.csv"),
    file.path(project_root, "data", "jc_services.csv")
  ))
  symlink_stage <- tempfile("goal008-symlink-stage-")
  dir.create(symlink_stage)
  expect_error(
    materialize_source_snapshot(config, symlink_stage, project_root = project_root),
    "may not be a symlink"
  )
})
