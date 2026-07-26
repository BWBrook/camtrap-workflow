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
