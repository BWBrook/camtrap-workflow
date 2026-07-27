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
source(here("R", "entity_resolution.R"))

goal007_profile <- function(sidecar) {
  list(
    profile_id = "judbury-entity-crosswalk/1.0.0-proposed",
    sidecar_path = sidecar,
    sidecar_sha256 =
      "553abada14493f3a5f0ae3c072523b6d5cc0d0c6a6c6480ca17a9e3331f2d8ec",
    authority_reference = paste0(
      "goal007-judbury-crosswalk-sha256-",
      "553abada14493f3a5f0ae3c072523b6d5cc0d0c6a6c6480ca17a9e3331f2d8ec"
    )
  )
}

goal007_snapshot <- function(sidecar = NULL) {
  root <- tempfile("goal007-snapshot-")
  source_root <- file.path(root, "source_snapshot")
  site_path <- file.path(source_root, "four_table", "site.csv")
  dir.create(dirname(site_path), recursive = TRUE)
  writeLines("site", site_path)
  inventory <- list(file_fixity_record(
    site_path,
    root,
    role = "parser_input",
    consumed = TRUE
  ))
  entity_resolution_path <- NULL
  if (!is.null(sidecar)) {
    entity_resolution_path <- file.path(
      source_root,
      "entity_resolution",
      basename(sidecar)
    )
    dir.create(dirname(entity_resolution_path), recursive = TRUE)
    file.copy(sidecar, entity_resolution_path)
    inventory[[2]] <- file_fixity_record(
      entity_resolution_path,
      root,
      role = "entity_resolution_input",
      consumed = FALSE
    )
  }
  inventory <- inventory[order(
    vapply(inventory, `[[`, character(1), "path"),
    method = "radix"
  )]
  list(
    staging_dir = root,
    snapshot_root = source_root,
    entity_resolution_path = entity_resolution_path,
    inventory = inventory,
    source_sha256 = fixity_identity(inventory)
  )
}

goal007_four_table_state <- function(sites) {
  list(
    inputs = list(
      site = data.frame(site = sites, stringsAsFactors = FALSE),
      op = data.frame(
        date = "01/01/2020",
        stats::setNames(as.list(rep(1, length(sites))), sites),
        check.names = FALSE
      ),
      obs = data.frame(
        site = sites,
        stringsAsFactors = FALSE
      ),
      taxa = data.frame(short = "sp1", stringsAsFactors = FALSE)
    ),
    parser_audit = list(
      audit_schema = "camtrap-parser-audit/1.0",
      parsed_tables = list()
    ),
    lineage = NULL
  )
}

goal007_null_entity_config <- function(input_mode) {
  list(
    input_mode = input_mode,
    entity_resolution = list(
      profile_id = NULL,
      sidecar_path = NULL,
      sidecar_sha256 = NULL,
      authority_reference = NULL
    )
  )
}

goal007_camtrapdp_state <- function(
    deployments,
    observation_deployments = deployments$deploymentID,
    lineage = NULL) {
  deployment_keys <- unique(as.character(deployments$deploymentID))
  deployment_keys <- deployment_keys[
    !is.na(deployment_keys) & nzchar(deployment_keys)
  ]
  effort <- data.frame(date = "01/01/2020", check.names = FALSE)
  for (deployment in deployment_keys) {
    effort[[deployment]] <- 1
  }
  list(
    inputs = list(
      site = data.frame(site = deployment_keys, stringsAsFactors = FALSE),
      op = effort,
      obs = data.frame(
        site = observation_deployments,
        stringsAsFactors = FALSE
      ),
      taxa = data.frame(short = character())
    ),
    parser_audit = list(parsed_tables = list(
      deployments = deployments,
      observations = data.frame(
        deploymentID = observation_deployments,
        stringsAsFactors = FALSE
      )
    )),
    lineage = lineage
  )
}

test_that("approved Judbury evidence resolves exactly 13 physical, nine nominal, and four pairs", {
  sidecar <- here(
    "tests", "testthat", "fixtures", "goal007",
    "judbury_entity_crosswalk.csv"
  )
  crosswalk <- read.csv(sidecar, stringsAsFactors = FALSE, na.strings = "")
  config <- list(
    input_mode = "four_table",
    entity_resolution = goal007_profile(sidecar)
  )
  state <- resolve_entity_evidence(
    config,
    goal007_snapshot(sidecar),
    goal007_four_table_state(crosswalk$source_physical_id)
  )

  resolved <- state$records[state$records$resolution_state == "resolved", ]
  expect_equal(
    length(unique(resolved$entity_id[resolved$entity_type == "physical_location"])),
    13L
  )
  expect_equal(
    length(unique(resolved$entity_id[resolved$entity_type == "nominal_grid_station"])),
    9L
  )
  expect_equal(
    sum(state$links$link_type == "service_history_move_pair"),
    4L
  )
  expect_equal(nrow(state$deployment_lineage), 0L)
  expect_equal(state$summary$analysis_site_status, "unselected")
  expect_equal(state$summary$analysis_site_membership_count, 0L)
  expect_equal(state$summary$crosswalk$sha256, goal007_profile(sidecar)$sidecar_sha256)
  expect_equal(
    state$summary$authority_reference,
    goal007_profile(sidecar)$authority_reference
  )
})

test_that("generic four-table identities do not infer suffix or coordinate relationships", {
  sites <- c("plot", "plot_s1", "same_a", "same_b", "close")
  config <- goal007_null_entity_config("four_table")
  validation_state <- goal007_four_table_state(sites)
  validation_state$inputs$site$lat <- c(0, 0, 1, 1, 1.000001)
  validation_state$inputs$site$lon <- c(0, 0, 2, 2, 2.000001)
  state <- resolve_entity_evidence(
    config,
    goal007_snapshot(),
    validation_state
  )

  physical <- state$records[
    state$records$entity_type == "physical_location" &
      state$records$resolution_state == "resolved",
  ]
  expect_equal(nrow(physical), length(sites))
  expect_equal(length(unique(physical$entity_id)), length(sites))
  expect_equal(nrow(state$links), 0L)
  expect_true(any(
    state$records$entity_type == "nominal_grid_station" &
      state$records$resolution_state == "unresolved"
  ))
  expect_true(any(
    state$records$entity_type == "deployment" &
      state$records$resolution_state == "unresolved"
  ))
})

test_that("entity selection and immutable sidecar inventory are exact", {
  sidecar <- here(
    "tests", "testthat", "fixtures", "goal007",
    "judbury_entity_crosswalk.csv"
  )
  sites <- read.csv(
    sidecar,
    stringsAsFactors = FALSE,
    na.strings = ""
  )$source_physical_id
  null_config <- goal007_null_entity_config("four_table")
  selected_config <- list(
    input_mode = "four_table",
    entity_resolution = goal007_profile(sidecar)
  )

  undeclared <- goal007_snapshot(sidecar)
  expect_error(
    resolve_entity_evidence(
      null_config,
      undeclared,
      goal007_four_table_state(sites)
    ),
    "explicit null.*zero entity-resolution sidecars"
  )

  stray_path <- goal007_snapshot()
  stray_path$entity_resolution_path <- sidecar
  expect_error(
    resolve_entity_evidence(
      null_config,
      stray_path,
      goal007_four_table_state(sites)
    ),
    "explicit null.*dedicated entity-resolution path"
  )

  missing <- goal007_snapshot(sidecar)
  missing$inventory <- Filter(
    function(record) !identical(record$role, "entity_resolution_input"),
    missing$inventory
  )
  missing$source_sha256 <- fixity_identity(missing$inventory)
  expect_error(
    resolve_entity_evidence(
      selected_config,
      missing,
      goal007_four_table_state(sites)
    ),
    "exactly one entity-resolution sidecar"
  )

  duplicate <- goal007_snapshot(sidecar)
  duplicate$inventory[[length(duplicate$inventory) + 1L]] <-
    duplicate$inventory[[which(vapply(
      duplicate$inventory,
      function(record) identical(record$role, "entity_resolution_input"),
      logical(1)
    ))]]
  duplicate$source_sha256 <- fixity_identity(duplicate$inventory)
  expect_error(
    resolve_entity_evidence(
      selected_config,
      duplicate,
      goal007_four_table_state(sites)
    ),
    "exactly one entity-resolution sidecar"
  )

  camtrapdp_config <- selected_config
  camtrapdp_config$input_mode <- "camtrapdp"
  expect_error(
    resolve_entity_evidence(
      camtrapdp_config,
      goal007_snapshot(sidecar),
      goal007_camtrapdp_state(data.frame(
        deploymentID = "dep-1",
        locationID = "loc-1",
        deploymentStart = as.POSIXct("2020-01-01", tz = "UTC"),
        deploymentEnd = as.POSIXct("2020-01-02", tz = "UTC")
      ))
    ),
    "only valid when input_mode = 'four_table'"
  )
})

test_that("entity and undirected link identities are deterministic and invocation-free", {
  first <- entity_identity(
    "physical_location",
    "four_table:site",
    "opaque_s99"
  )
  second <- entity_identity(
    "physical_location",
    "four_table:site",
    "opaque_s99"
  )
  other <- entity_identity(
    "physical_location",
    "four_table:site",
    "opaque"
  )

  expect_equal(first, second)
  expect_false(identical(first, other))
  expect_equal(
    entity_link_identity("service_history_move_pair", first, other),
    entity_link_identity("service_history_move_pair", other, first)
  )
})

test_that("opaque CamtrapDP identities resolve only explicit deployment evidence", {
  deployments <- data.frame(
    deploymentID = c("DEP::alpha", "opaque-2"),
    locationID = c("LOC_s1", "location without pattern"),
    deploymentStart = as.POSIXct(
      c("2020-01-01", "2020-02-01"),
      tz = "UTC"
    ),
    deploymentEnd = as.POSIXct(
      c("2020-01-03", "2020-02-04"),
      tz = "UTC"
    ),
    stringsAsFactors = FALSE
  )
  state <- goal007_camtrapdp_state(deployments)
  config <- goal007_null_entity_config("camtrapdp")
  resolved <- resolve_entity_evidence(config, goal007_snapshot(), state)

  expect_equal(
    sum(resolved$records$entity_type == "physical_location" &
      resolved$records$resolution_state == "resolved"),
    2L
  )
  expect_equal(
    sum(resolved$records$entity_type == "deployment" &
      resolved$records$resolution_state == "resolved"),
    2L
  )
  expect_equal(nrow(resolved$deployment_lineage), 2L)
  expect_true(all(resolved$deployment_lineage$resolution_state == "resolved"))
  expect_false(any(
    resolved$records$entity_type == "nominal_grid_station" &
      resolved$records$resolution_state == "resolved"
  ))
})

test_that("missing optional CamtrapDP location or interval evidence stays unresolved", {
  deployments <- data.frame(
    deploymentID = c("missing-location", "missing-end"),
    locationID = c(NA_character_, "explicit-location"),
    deploymentStart = as.POSIXct(
      c("2020-01-01", "2020-02-01"),
      tz = "UTC"
    ),
    deploymentEnd = as.POSIXct(
      c("2020-01-03", NA_character_),
      tz = "UTC"
    ),
    stringsAsFactors = FALSE
  )
  resolved <- resolve_entity_evidence(
    goal007_null_entity_config("camtrapdp"),
    goal007_snapshot(),
    goal007_camtrapdp_state(deployments)
  )

  expect_true(resolved$can_analyze)
  expect_true(all(
    resolved$records$resolution_state[
      resolved$records$entity_type == "deployment"
    ] == "resolved"
  ))
  expect_true(all(
    resolved$deployment_lineage$resolution_state == "unresolved"
  ))
  expect_equal(
    sum(resolved$links$link_type == "deployment_to_physical_location"),
    1L
  )
  expect_equal(length(resolved$integrity_findings), 0L)
})

test_that("duplicate and competing CamtrapDP deployment evidence stop distinctly", {
  base <- data.frame(
    deploymentID = c("dep-1", "dep-1"),
    locationID = c("loc-1", "loc-1"),
    deploymentStart = as.POSIXct(
      c("2020-01-01", "2020-01-01"),
      tz = "UTC"
    ),
    deploymentEnd = as.POSIXct(
      c("2020-01-03", "2020-01-03"),
      tz = "UTC"
    ),
    stringsAsFactors = FALSE
  )
  source_row_ids <- c(
    paste(rep("a", 64L), collapse = ""),
    paste(rep("b", 64L), collapse = "")
  )
  lineage <- list(rows = data.frame(
    logical_name = rep("deployments", 2L),
    record_ordinal = 1:2,
    source_row_id = source_row_ids,
    stringsAsFactors = FALSE
  ))
  duplicate <- resolve_entity_evidence(
    goal007_null_entity_config("camtrapdp"),
    goal007_snapshot(),
    goal007_camtrapdp_state(base, "dep-1", lineage)
  )
  expect_false(duplicate$can_analyze)
  expect_true(any(
    duplicate$records$entity_type == "deployment" &
      duplicate$records$resolution_state == "integrity_failure"
  ))
  expect_equal(nrow(duplicate$deployment_lineage), 2L)
  expect_setequal(duplicate$deployment_lineage$source_row_id, source_row_ids)
  expect_true(all(
    duplicate$deployment_lineage$resolution_state == "integrity_failure"
  ))

  for (field in c("locationID", "deploymentEnd")) {
    competing_data <- base
    competing_data[[field]][[2]] <- if (identical(field, "locationID")) {
      "loc-2"
    } else {
      as.POSIXct("2020-01-04", tz = "UTC")
    }
    competing <- resolve_entity_evidence(
      goal007_null_entity_config("camtrapdp"),
      goal007_snapshot(),
      goal007_camtrapdp_state(competing_data, "dep-1", lineage)
    )
    expect_false(competing$can_analyze, info = field)
    expect_true(any(
      competing$records$entity_type == "deployment" &
        competing$records$resolution_state == "ambiguous"
    ), info = field)
    expect_true(any(
      vapply(
        competing$join_readiness$results,
        function(result) result$ambiguous > 0L,
        logical(1)
      )
    ), info = field)
    expect_equal(nrow(competing$deployment_lineage), 2L, info = field)
    expect_setequal(
      competing$deployment_lineage$source_row_id,
      source_row_ids
    )
    expect_true(all(
      competing$deployment_lineage$resolution_state == "ambiguous"
    ), info = field)
    expect_false(any(
      competing$links$link_type == "deployment_to_physical_location"
    ), info = field)
    if (identical(field, "locationID")) {
      expect_equal(
        length(unique(stats::na.omit(
          competing$deployment_lineage$physical_location_entity_id
        ))),
        2L
      )
    } else {
      expect_equal(
        length(unique(stats::na.omit(
          competing$deployment_lineage$interval_end
        ))),
        2L
      )
    }
  }
})

test_that("join readiness binds the exact immutable source identity", {
  snapshot <- goal007_snapshot()
  state <- resolve_entity_evidence(
    goal007_null_entity_config("four_table"),
    snapshot,
    goal007_four_table_state(c("site-1"))
  )

  expect_equal(
    state$join_readiness$source_sha256,
    snapshot$source_sha256
  )
  expect_equal(
    state$join_readiness$entity_ledger_digest,
    state$summary$ledger_content_sha256
  )

  mismatched <- snapshot
  mismatched$source_sha256 <- paste(rep("0", 64L), collapse = "")
  expect_error(
    resolve_entity_evidence(
      goal007_null_entity_config("four_table"),
      mismatched,
      goal007_four_table_state(c("site-1"))
    ),
    "immutable source identity"
  )
})

test_that("CamtrapDP orphan observations stop and source-row evidence is retained", {
  deployments <- data.frame(
    deploymentID = "dep-1",
    locationID = "loc-1",
    deploymentStart = as.POSIXct("2020-01-01", tz = "UTC"),
    deploymentEnd = as.POSIXct("2020-01-03", tz = "UTC"),
    stringsAsFactors = FALSE
  )
  orphan <- resolve_entity_evidence(
    goal007_null_entity_config("camtrapdp"),
    goal007_snapshot(),
    goal007_camtrapdp_state(deployments, "missing-deployment")
  )
  expect_false(orphan$can_analyze)
  expect_true(any(vapply(
    orphan$integrity_findings,
    function(finding) {
      identical(finding$code, "camtrapdp.observation_deployment_orphan")
    },
    logical(1)
  )))

  source_row_id <- paste(rep("a", 64L), collapse = "")
  lineage <- list(rows = data.frame(
    logical_name = "deployments",
    record_ordinal = 1L,
    source_row_id = source_row_id,
    stringsAsFactors = FALSE
  ))
  linked <- resolve_entity_evidence(
    goal007_null_entity_config("camtrapdp"),
    goal007_snapshot(),
    goal007_camtrapdp_state(deployments, "dep-1", lineage)
  )
  expect_true(all(
    linked$records$source_row_id[
      linked$records$entity_type %in% c("deployment", "physical_location")
    ] == source_row_id
  ))
  expect_equal(linked$links$source_row_id, source_row_id)
  expect_equal(linked$deployment_lineage$source_row_id, source_row_id)
})

test_that("conflicts, orphans, reversed intervals, and altered crosswalks stop integrity", {
  sidecar <- here(
    "tests", "testthat", "fixtures", "goal007",
    "judbury_entity_crosswalk.csv"
  )
  crosswalk <- read.csv(sidecar, stringsAsFactors = FALSE, na.strings = "")
  duplicate <- tempfile(fileext = ".csv")
  write.csv(rbind(crosswalk, crosswalk[1, ]), duplicate, row.names = FALSE, na = "")
  expect_error(
    read_entity_crosswalk(duplicate, goal007_profile(sidecar)),
    "duplicate|Duplicate"
  )

  conflict <- crosswalk
  conflict$proposed_nominal_grid_station_id[1] <- "competing"
  conflict_path <- tempfile(fileext = ".csv")
  write.csv(conflict, conflict_path, row.names = FALSE, na = "")
  expect_error(
    read_entity_crosswalk(conflict_path, goal007_profile(sidecar)),
    "SHA-256|digest"
  )

  populated_analysis_site <- crosswalk
  populated_analysis_site$analysis_site <- "forbidden"
  populated_path <- tempfile(fileext = ".csv")
  write.csv(
    populated_analysis_site,
    populated_path,
    row.names = FALSE,
    na = ""
  )
  expect_error(
    read_entity_crosswalk(populated_path, goal007_profile(sidecar)),
    "closed schema"
  )

  deployments <- data.frame(
    deploymentID = "dep1",
    locationID = "missing",
    deploymentStart = as.POSIXct("2020-01-03", tz = "UTC"),
    deploymentEnd = as.POSIXct("2020-01-01", tz = "UTC"),
    stringsAsFactors = FALSE
  )
  state <- list(
    inputs = goal007_four_table_state("dep1")$inputs,
    parser_audit = list(parsed_tables = list(
      deployments = deployments,
      observations = data.frame(deploymentID = "dep1")
    )),
    lineage = NULL
  )
  config <- goal007_null_entity_config("camtrapdp")
  resolved <- resolve_entity_evidence(config, goal007_snapshot(), state)
  expect_false(resolved$can_analyze)
  expect_true(length(resolved$integrity_findings) > 0L)
})

test_that("missing optional deployment evidence and active runs remain unresolved", {
  config <- goal007_null_entity_config("four_table")
  state <- goal007_four_table_state(c("camera_s1", "camera"))
  state$inputs$op <- data.frame(
    date = c("01/01/2020", "02/01/2020", "03/01/2020"),
    camera_s1 = c(1, 1, 0),
    camera = c(0, 1, 1),
    check.names = FALSE
  )
  resolved <- resolve_entity_evidence(config, goal007_snapshot(), state)

  expect_equal(nrow(resolved$deployment_lineage), 0L)
  expect_false(any(resolved$links$link_type == "service_history_move_pair"))
  expect_true(any(
    resolved$records$entity_type == "deployment" &
      resolved$records$resolution_state == "unresolved"
  ))
})

goal008_profile <- function() {
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

goal008_entity_snapshot <- function() {
  root <- tempfile("goal008-entity-snapshot-")
  source_root <- file.path(root, "source_snapshot")
  paths <- list(
    site = file.path(source_root, "four_table", "site.csv"),
    op = file.path(source_root, "four_table", "op.csv"),
    entity = file.path(
      source_root,
      "entity_resolution",
      "judbury_entity_crosswalk.csv"
    ),
    service = file.path(
      source_root,
      "deployment_evidence",
      "service",
      "jc_services.csv"
    ),
    ledger = file.path(
      source_root,
      "deployment_evidence",
      "ledger",
      "judbury_deployment_ledger.csv"
    )
  )
  for (path in paths) {
    dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  }
  writeLines("site", paths$site)
  file.copy(here("data", "jc_op.csv"), paths$op)
  file.copy(
    here(
      "tests",
      "testthat",
      "fixtures",
      "goal007",
      "judbury_entity_crosswalk.csv"
    ),
    paths$entity
  )
  file.copy(
    here("tests", "testthat", "fixtures", "goal008", "jc_services.csv"),
    paths$service
  )
  file.copy(
    here(
      "tests",
      "testthat",
      "fixtures",
      "goal008",
      "judbury_deployment_ledger.csv"
    ),
    paths$ledger
  )
  inventory <- list(
    file_fixity_record(paths$site, root, "parser_input", TRUE),
    file_fixity_record(paths$op, root, "parser_input", TRUE),
    file_fixity_record(paths$entity, root, "entity_resolution_input", FALSE),
    file_fixity_record(paths$service, root, "deployment_service_input", FALSE),
    file_fixity_record(paths$ledger, root, "deployment_ledger_input", FALSE)
  )
  inventory <- inventory[order(
    vapply(inventory, `[[`, character(1), "path"),
    method = "radix"
  )]
  list(
    staging_dir = root,
    snapshot_root = source_root,
    entity_resolution_path = paths$entity,
    deployment_evidence_paths = paths[c("service", "ledger")],
    inventory = inventory,
    source_sha256 = fixity_identity(inventory)
  )
}

goal008_entity_config <- function(sidecar) {
  list(
    input_mode = "four_table",
    entity_resolution = goal007_profile(sidecar),
    deployment_evidence = goal008_profile()
  )
}

goal008_csv_copy <- function(path, na = "", mutator) {
  value <- utils::read.csv(
    path,
    stringsAsFactors = FALSE,
    colClasses = "character",
    na.strings = if (identical(na, "NA")) "NA" else "",
    check.names = FALSE
  )
  value <- mutator(value)
  output <- tempfile("goal008-mutated-", fileext = ".csv")
  utils::write.csv(value, output, row.names = FALSE, quote = FALSE, na = na)
  output
}

test_that("approved deployment evidence resolves exact audit-only Goal 008 state", {
  sidecar <- here(
    "tests", "testthat", "fixtures", "goal007",
    "judbury_entity_crosswalk.csv"
  )
  crosswalk <- read.csv(sidecar, stringsAsFactors = FALSE, na.strings = "")
  validation_state <- goal007_four_table_state(crosswalk$source_physical_id)
  inputs_before <- canonical_json(validation_state$inputs)
  state <- resolve_entity_evidence(
    goal008_entity_config(sidecar),
    goal008_entity_snapshot(),
    validation_state
  )
  lineage <- state$deployment_lineage

  expect_equal(
    sum(state$records$entity_type == "deployment" &
      state$records$resolution_state == "resolved"),
    13L
  )
  expect_equal(
    sum(state$links$link_type == "deployment_to_physical_location"),
    13L
  )
  expect_equal(nrow(lineage), 13L)
  expect_true(all(
    lineage$deployment_record_schema == "camtrap-deployment-lineage/1.1"
  ))
  expect_equal(
    lineage$service_event_count,
    as.character(c(8, 7, 2, 8, 2, 7, 8, 8, 6, 2, 8, 3, 6))
  )
  expect_equal(sum(as.integer(lineage$service_event_count)), 75L)
  expect_equal(
    sum(!is.na(lineage$predecessor_deployment_id) |
      !is.na(lineage$successor_deployment_id)),
    8L
  )
  expect_equal(state$summary$deployment_evidence$service_event_count, 75L)
  expect_equal(state$summary$deployment_evidence$run_days_value_count, 62L)
  expect_equal(state$summary$deployment_evidence$run_days_diagnostic_total, 7842L)
  expect_equal(state$summary$deployment_evidence$directed_relation_count, 4L)
  expect_equal(state$summary$analysis_site_membership_count, 0L)
  expect_equal(state$join_readiness$joined_analytical_row_count, 0L)
  expect_false(state$join_readiness$analytical_routing_permitted)
  deployment_readiness <- Filter(
    function(record) {
      identical(record$requested_entity_level, "deployment")
    },
    state$join_readiness$results
  )
  expect_true(all(vapply(
    deployment_readiness,
    function(record) identical(record$unresolved, 0L),
    logical(1)
  )))
  expect_equal(canonical_json(validation_state$inputs), inputs_before)
})

test_that("service normalization is closed, strict, ordered, and retains run-days state", {
  expect_true(exists("read_judbury_service_events", mode = "function"))
  if (!exists("read_judbury_service_events", mode = "function")) {
    return(invisible(NULL))
  }
  fixture <- here(
    "tests",
    "testthat",
    "fixtures",
    "goal008",
    "jc_services.csv"
  )
  evidence <- read_judbury_service_events(fixture)
  expect_equal(nrow(evidence$rows), 13L)
  expect_equal(nrow(evidence$events), 75L)
  expect_equal(sum(evidence$events$run_days_state == "present"), 62L)
  expect_equal(
    sum(as.integer(evidence$events$run_days_literal), na.rm = TRUE),
    7842L
  )
  expect_equal(evidence$events$event_role[[1]], "deployment_start")
  expect_true(all(nchar(evidence$rows$service_event_digest) == 64L))

  duplicate <- goal008_csv_copy(fixture, "NA", function(value) {
    rbind(value, value[1, , drop = FALSE])
  })
  expect_error(read_judbury_service_events(duplicate), "duplicate|13 exact")

  unknown <- goal008_csv_copy(fixture, "NA", function(value) {
    value$site[[1]] <- "jc_unknown"
    value
  })
  expect_error(read_judbury_service_events(unknown), "unlisted raw alias")

  missing_label <- goal008_csv_copy(fixture, "NA", function(value) {
    value$s2.date[[1]] <- NA_character_
    value
  })
  expect_error(read_judbury_service_events(missing_label), "missing service label")

  malformed <- goal008_csv_copy(fixture, "NA", function(value) {
    value$s1.date[[1]] <- "2019-10-14"
    value
  })
  expect_error(read_judbury_service_events(malformed), "malformed service date")

  reversed <- goal008_csv_copy(fixture, "NA", function(value) {
    value$s1.date[[1]] <- "4/06/2019"
    value
  })
  expect_error(read_judbury_service_events(reversed), "reversed service chronology")
})

test_that("ledger reconciliation rejects duplicates, orphans, and source disagreements", {
  expected_functions <- c(
    "read_judbury_service_events",
    "read_judbury_deployment_ledger",
    "reconcile_judbury_deployment_evidence"
  )
  available <- vapply(expected_functions, exists, logical(1), mode = "function")
  expect_true(all(available))
  if (!all(available)) {
    return(invisible(NULL))
  }
  fixture_root <- here("tests", "testthat", "fixtures", "goal008")
  service <- read_judbury_service_events(file.path(fixture_root, "jc_services.csv"))
  ledger_path <- file.path(fixture_root, "judbury_deployment_ledger.csv")
  ledger <- read_judbury_deployment_ledger(ledger_path)
  crosswalk_path <- here(
    "tests",
    "testthat",
    "fixtures",
    "goal007",
    "judbury_entity_crosswalk.csv"
  )
  crosswalk <- read_entity_crosswalk(
    crosswalk_path,
    goal007_profile(crosswalk_path)
  )
  reconciled <- reconcile_judbury_deployment_evidence(
    service,
    ledger,
    crosswalk
  )
  expect_equal(nrow(reconciled$rows), 13L)
  expect_equal(reconciled$directed_relation_count, 4L)

  duplicate <- goal008_csv_copy(ledger_path, "", function(value) {
    value$deployment_id[[2]] <- value$deployment_id[[1]]
    value
  })
  expect_error(
    read_judbury_deployment_ledger(duplicate),
    "duplicate deployment"
  )

  endpoint <- goal008_csv_copy(ledger_path, "", function(value) {
    value$end_date[[1]] <- "2022-05-09"
    value
  })
  expect_error(
    reconcile_judbury_deployment_evidence(
      service,
      read_judbury_deployment_ledger(endpoint),
      crosswalk
    ),
    "endpoint disagreement"
  )

  count <- goal008_csv_copy(ledger_path, "", function(value) {
    value$service_event_count[[1]] <- "7"
    value
  })
  expect_error(
    reconcile_judbury_deployment_evidence(
      service,
      read_judbury_deployment_ledger(count),
      crosswalk
    ),
    "service-count disagreement"
  )

  orphan <- goal008_csv_copy(ledger_path, "", function(value) {
    value$predecessor_deployment_id[[2]] <- "judbury_dep_missing"
    value
  })
  expect_error(
    reconcile_judbury_deployment_evidence(
      service,
      read_judbury_deployment_ledger(orphan),
      crosswalk
    ),
    "orphan predecessor"
  )

  conflict <- goal008_csv_copy(ledger_path, "", function(value) {
    value$physical_location_id[[2]] <- value$physical_location_id[[1]]
    value
  })
  expect_error(
    read_judbury_deployment_ledger(conflict),
    "duplicate physical"
  )
})
