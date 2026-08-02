import::from(
  "testthat", test_that, expect_equal, expect_error, expect_false,
  expect_identical, expect_named, expect_true
)
import::from("here", here)
source(here("R", "config_identity.R"))
source(here("R", "fixity.R"))
source(here("R", "config.R"))
source(here("R", "event_outputs.R"))
source(here("R", "selected_resolution.R"))
source(here("R", "community_matrices.R"))
goal009_mapping <- function() {
  read.csv(
    here(
      "docs", "goals", "009-analysis-site-vertical-slice",
      "judbury_analysis_site_mapping.csv"
    ),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}
goal009_config <- function() {
  fields <- list(
    mapping_profile_id = "judbury-analysis-site/1.0.0-proposed",
    mapping_path = "docs/goals/009-analysis-site-vertical-slice/judbury_analysis_site_mapping.csv",
    mapping_sha256 = "6490d7f7021e5c727b9be1c7d6dfbf44ba50a1ef5b0396c66e1dd813a9c77083",
    authority_reference = paste0(
      "goal009-judbury-analysis-site-mapping-sha256-",
      "6490d7f7021e5c727b9be1c7d6dfbf44ba50a1ef5b0396c66e1dd813a9c77083"
    )
  )
  list(analysis_unit = c(list(resolution = "analysis_site"), fields))
}
goal009_membership_digest <- function(event_id, source_ids) {
  sha256_text(canonical_json(list(
    event_id = event_id,
    source_row_ids = sort(as.character(source_ids), method = "radix")
  )))
}
goal009_fixture <- function() {
  mapping <- goal009_mapping()
  physical_site <- read.csv(
    here("data", "jc_site.csv"),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  physical <- as.character(physical_site$site)
  deployment <- paste0("judbury_dep_", physical)
  predecessor <- rep(NA_character_, length(physical))
  successor <- predecessor
  predecessor[physical == "jc_co1"] <- deployment[physical == "jc_co1_s1"]
  successor[physical == "jc_co1_s1"] <- deployment[physical == "jc_co1"]
  operation <- data.frame(
    date = as.Date(c("2020-01-01", "2020-01-02", "2020-01-03")),
    check.names = FALSE
  )
  for (site in physical) operation[[site]] <- c(1L, 1L, 1L)
  operation[c("jc_co3_s16", "jc_pm14_s1", "jc_pm34_s15")] <- 0L
  operation$jc_co1 <- c(0L, 1L, 1L)
  operation$jc_co1_s1 <- c(1L, 1L, 0L)
  obs <- data.frame(
    index = 1:3, site = c("jc_co1_s1", "jc_co1_s1", "jc_co1"),
    species = c("pos", "pos", "wal"),
    datetime = c("01/01/2020 01:00:00", "01/01/2020 01:05:00", "03/01/2020 02:00:00"),
    dt = as.POSIXct(c("2020-01-01 01:00:00", "2020-01-01 01:05:00", "2020-01-03 02:00:00"), tz = "UTC"),
    event_id = c("jc_co1_s1_pos_1", "jc_co1_s1_pos_1", "jc_co1_wal_1"),
    flash = c(0L, 1L, 0L), count = c(1L, 1L, 2L), stringsAsFactors = FALSE
  )
  source_ids <- paste0("source-row-", 1:3)
  memberships <- data.frame(
    membership_schema = "camtrap-event-membership/1.0",
    membership_id = mapply(event_membership_identity, obs$event_id, source_ids,
      USE.NAMES = FALSE
    ), event_id = obs$event_id,
    source_row_id = source_ids, stringsAsFactors = FALSE
  )
  validation <- list(
    inputs = list(
      site = physical_site,
      op = operation, obs = obs, taxa = data.frame(short = c("pos", "wal"))
    ),
    lineage = list(
      rows = data.frame(
        logical_name = "obs", record_ordinal = 1:3,
        source_row_id = source_ids, disposition = "retained",
        rule_id = "", reason = ""
      ),
      observation_map = data.frame(
        internal_index = 1:3,
        record_ordinal = 1:3, source_row_id = source_ids
      )
    ),
    event_lineage = list(
      event_lineage_schema = "camtrap-event-lineage/1.0",
      event_rule = list(
        rule_id = "operational_detection_event.gap/1.0",
        threshold_minutes = 15, timezone = "UTC", fixed_offset_hours = NULL
      ),
      events = data.frame(
        event_schema = "camtrap-operational-event/1.0",
        event_id = c("jc_co1_s1_pos_1", "jc_co1_wal_1"),
        site = c("jc_co1_s1", "jc_co1"), species = c("pos", "wal"), member_count = c(2L, 1L)
      ),
      memberships = memberships, obs_events = obs
    )
  )
  entity <- list(
    can_analyze = TRUE,
    records = data.frame(
      entity_type = rep("physical_location", 13),
      entity_id = paste0("physical-entity-", physical), source_identifier = physical,
      resolution_state = "resolved"
    ),
    links = data.frame(
      link_type = rep("deployment_to_physical_location", 13),
      source_entity_id = paste0("deployment-entity-", deployment),
      target_entity_id = paste0("physical-entity-", physical)
    ),
    deployment_lineage = data.frame(
      deployment_identifier = deployment,
      deployment_entity_id = paste0("deployment-entity-", deployment),
      physical_location_identifier = physical, predecessor_deployment_id = predecessor,
      physical_location_entity_id = paste0("physical-entity-", physical),
      successor_deployment_id = successor, interval_start = as.Date("2019-01-01"),
      interval_end = as.Date("2022-12-31"), date_precision = "day",
      endpoint_semantics = "inclusive_at_day_precision_unknown_time",
      chronology_state = "not_applicable", resolution_state = "resolved"
    )
  )
  entity$deployment_lineage$interval_end[physical == "jc_co1_s1"] <- as.Date("2020-01-02")
  entity$deployment_lineage$interval_start[physical == "jc_co1"] <- as.Date("2020-01-02")
  entity$deployment_lineage$chronology_state[physical %in% c("jc_co1", "jc_co1_s1")] <-
    "same_date_boundary_not_full_day_overlap_or_routing_claim"
  staging_dir <- tempfile("goal009-source-")
  mapping_root <- file.path(staging_dir, "source_snapshot", "analysis_site_mapping")
  dir.create(mapping_root, recursive = TRUE)
  mapping_copy <- file.path(mapping_root, "judbury_analysis_site_mapping.csv")
  file.copy(here(
    "docs", "goals", "009-analysis-site-vertical-slice",
    "judbury_analysis_site_mapping.csv"
  ), mapping_copy)
  inventory <- file_fixity_record(mapping_copy, staging_dir,
    role = "analysis_site_mapping_input", consumed = FALSE
  )
  snapshot <- list(
    staging_dir = staging_dir,
    snapshot_root = file.path(staging_dir, "source_snapshot"),
    source_sha256 = fixity_identity(list(inventory)), inventory = list(inventory)
  )
  list(
    config = goal009_config(), mapping = mapping, snapshot = snapshot,
    validation_state = validation, entity_state = entity
  )
}
test_that("resolution preserves exact membership and chronology-based concurrency", {
  fixture <- goal009_fixture()
  physical_before <- serialize(list(
    site = fixture$validation_state$inputs$site,
    obs = fixture$validation_state$inputs$obs,
    event_lineage = fixture$validation_state$event_lineage
  ), NULL)
  state <- do.call(
    resolve_selected_resolution,
    fixture[c("config", "snapshot", "validation_state", "entity_state")]
  )
  expect_identical(serialize(list(
    site = fixture$validation_state$inputs$site,
    obs = fixture$validation_state$inputs$obs,
    event_lineage = fixture$validation_state$event_lineage
  ), NULL), physical_before)
  expected <- fixture$mapping[c("physical_location_id", "analysis_site_id")]
  names(expected)[[2]] <- "analysis_unit_id"
  actual <- state$membership[
    order(state$membership$physical_location_id),
    c("physical_location_id", "analysis_unit_id")
  ]
  expected <- expected[order(expected$physical_location_id), ]
  rownames(actual) <- rownames(expected) <- NULL
  expect_equal(nrow(actual), 13L)
  expect_equal(actual, expected)
  keyed <- state$event_map[c("event_id", "physical_location_id", "species", "event_time", "analysis_unit_id")]
  expected_keyed <- fixture$validation_state$event_lineage$obs_events[
    !duplicated(fixture$validation_state$event_lineage$obs_events$event_id),
    c("event_id", "site", "species", "dt")
  ]
  names(expected_keyed) <- c("event_id", "physical_location_id", "species", "event_time")
  expected_keyed$analysis_unit_id <- expected$analysis_unit_id[
    match(expected_keyed$physical_location_id, expected$physical_location_id)
  ]
  expected_keyed <- expected_keyed[order(expected_keyed$event_id), ]
  keyed <- keyed[order(keyed$event_id), ]
  rownames(keyed) <- rownames(expected_keyed) <- NULL
  expect_equal(keyed, expected_keyed)
  expect_true(isTRUE(state$integrity_ok))
  expect_true(isTRUE(state$route_eligible))
  expect_equal(
    state$summary$claim_limits,
    c(
      "observed-richness-detection-effort-bounded",
      "jaccard-descriptive-observed-presence-effort-completeness-detectability-limited"
    )
  )
  expect_true(all(
    c("analysis_unit_id", "date", "operation") %in% names(state$operation)
  ))
  expect_true(all(c(
    "member_states_json", "deployment_states_json", "concurrency_class"
  ) %in% names(state$operation)))
  expect_true(all(c(
    "physical_latitude", "physical_longitude", "representative_latitude",
    "representative_longitude", "coordinate_basis"
  ) %in% names(state$membership)))
  source_index <- match(
    state$membership$physical_location_id,
    fixture$validation_state$inputs$site$site
  )
  expect_equal(
    state$membership$physical_latitude,
    fixture$validation_state$inputs$site$lat[source_index]
  )
  expect_equal(
    state$membership$physical_longitude,
    fixture$validation_state$inputs$site$lon[source_index]
  )
  mapping_index <- match(
    state$membership$physical_location_id,
    fixture$mapping$physical_location_id
  )
  synthetic <- grepl(
    "^synthetic_fixed_midpoint",
    fixture$mapping$coordinate_basis[mapping_index]
  )
  expect_true(any(synthetic))
  expect_equal(
    state$membership$representative_latitude[synthetic],
    fixture$mapping$representative_latitude[mapping_index][synthetic]
  )
  expect_equal(
    state$membership$representative_longitude[synthetic],
    fixture$mapping$representative_longitude[mapping_index][synthetic]
  )
  handover <- state$operation[
    state$operation$analysis_unit_id == "jc_co1" &
      state$operation$operation == 1, ,
    drop = FALSE
  ]
  expect_equal(nrow(handover), 3L)
  expect_equal(length(unique(handover$date)), 3L)
  expect_equal(sum(handover$date == as.Date("2020-01-02")), 1L)

  concurrent <- fixture
  concurrent$validation_state$inputs$op[1, c("jc_co1", "jc_co1_s1")] <- 1L
  concurrent$entity_state$deployment_lineage$predecessor_deployment_id[] <- NA_character_
  concurrent$entity_state$deployment_lineage$successor_deployment_id[] <- NA_character_
  concurrent_state <- do.call(
    resolve_selected_resolution,
    concurrent[c("config", "snapshot", "validation_state", "entity_state")]
  )
  expect_true(isTRUE(concurrent_state$integrity_ok))
  expect_false(isTRUE(concurrent_state$route_eligible))
  expect_true(any(grepl("concurrent", concurrent_state$reasons)))
})

test_that("duplicate physical rows hard-stop the selected mapping reader", {
  fixture <- goal009_fixture()
  record <- fixture$snapshot$inventory[[1L]]
  mapping_path <- file.path(fixture$snapshot$staging_dir, record$path)
  duplicate <- fixture$mapping
  duplicate$physical_location_id[[2L]] <- duplicate$physical_location_id[[1L]]
  utils::write.csv(duplicate, mapping_path, row.names = FALSE, na = "")
  duplicate_sha256 <- sha256_file(mapping_path)
  fixture$snapshot$inventory[[1L]]$sha256 <- duplicate_sha256

  selection <- analysis_unit_selection(fixture$config)
  selection$mapping_sha256 <- duplicate_sha256
  rlang::local_bindings(
    analysis_unit_selection = function(config) selection,
    .env = environment(selected_resolution_read_mapping)
  )

  expect_error(
    selected_resolution_read_mapping(fixture$config, fixture$snapshot),
    "incomplete or duplicate membership"
  )
})

test_that("incomplete or orphaned membership hard stops without inference", {
  fixture <- goal009_fixture()
  records <- fixture$entity_state$records
  physical_rows <- which(records$entity_type == "physical_location")
  fixture$entity_state$records <- records[-physical_rows[[length(physical_rows)]], ]

  state <- do.call(
    resolve_selected_resolution,
    fixture[c("config", "snapshot", "validation_state", "entity_state")]
  )

  expect_false(isTRUE(state$integrity_ok))
  expect_false(isTRUE(state$route_eligible))
  expect_true("incomplete_or_orphan_mapping" %in% state$reasons)
  expect_equal(state$summary$status, "integrity_failure")
})

test_that("selected operation applies the full three-state union and preserves gaps", {
  membership <- data.frame(
    analysis_unit_id = rep("unit_a", 2),
    physical_location_id = c("camera_a", "camera_b"), stringsAsFactors = FALSE
  )
  operation <- data.frame(
    site = rep(c("camera_a", "camera_b"), 6),
    trap_date = as.Date(c(
      "2020-01-01", "2020-01-01", "2020-01-02", "2020-01-02",
      "2020-01-03", "2020-01-03", "2020-01-04", "2020-01-04",
      "2020-01-05", "2020-01-05", "2020-01-06", "2020-01-06"
    )),
    on_off = c(1, 0, 1, NA, 1, NA, NA, NA, 0, 0, 0, NA)
  )
  coverage <- build_selected_effort_coverage(operation, membership)
  value <- stats::setNames(coverage$operation, coverage$date)
  expect_equal(value[["2020-01-01"]], 1)
  expect_equal(value[["2020-01-02"]], 1)
  expect_equal(value[["2020-01-03"]], 1)
  expect_true(is.na(value[["2020-01-04"]]))
  expect_equal(value[["2020-01-05"]], 0)
  expect_true(is.na(value[["2020-01-06"]]))
  expect_false(any(coverage$date == as.Date("2020-01-07")))
})
test_that("event mapping preserves multi-row lineage and exact event conservation", {
  fixture <- goal009_fixture()
  state <- do.call(
    resolve_selected_resolution,
    fixture[c("config", "snapshot", "validation_state", "entity_state")]
  )
  source_members <- fixture$validation_state$event_lineage$memberships
  mapped <- state$event_map
  expect_equal(
    sort(unique(mapped$event_id)),
    sort(unique(fixture$validation_state$event_lineage$obs_events$event_id))
  )
  expect_equal(
    sort(unique(mapped$physical_location_id)),
    sort(unique(fixture$validation_state$event_lineage$obs_events$site))
  )
  expect_equal(sort(unique(mapped$species)), sort(unique(fixture$validation_state$event_lineage$obs_events$species)))
  expect_true("event_time" %in% names(mapped))
  event_rows <- fixture$validation_state$event_lineage$obs_events
  event_rows <- event_rows[!duplicated(event_rows$event_id), ]
  expect_equal(nrow(mapped), nrow(event_rows))
  expect_equal(anyDuplicated(mapped$event_id), 0L)
  expect_equal(length(unique(mapped$event_id)), nrow(event_rows))
  expect_equal(sort(as.numeric(mapped$event_time)), sort(as.numeric(event_rows$dt)))
  expect_true(all(c(
    "source_membership_count", "source_membership_digest",
    "source_membership_reference"
  ) %in% names(mapped)))
  expected_by_event <- split(source_members$source_row_id, source_members$event_id)
  for (event_id in names(expected_by_event)) {
    row <- mapped[mapped$event_id == event_id, , drop = FALSE]
    expect_equal(row$source_membership_count, length(expected_by_event[[event_id]]))
    expect_equal(
      row$source_membership_digest,
      goal009_membership_digest(event_id, expected_by_event[[event_id]])
    )
    expect_equal(row$source_membership_reference, "provenance/phase2/event_membership.json")
    expect_equal(row$deployment_resolution_state, "resolved")
    expect_true(nzchar(row$deployment_id))
  }
  expect_equal(
    table(unique(mapped[c("event_id", "species")])$species),
    table(unique(fixture$validation_state$event_lineage$obs_events[c("event_id", "species")])$species)
  )
  expect_equal(length(unique(mapped$analysis_unit_id)), 1L)
})

test_that("zero operational events remain typed and integrity valid", {
  fixture <- goal009_fixture()
  event_lineage <- fixture$validation_state$event_lineage
  event_lineage$events <- event_lineage$events[0, , drop = FALSE]
  event_lineage$memberships <- event_lineage$memberships[0, , drop = FALSE]
  event_lineage$obs_events <- event_lineage$obs_events[0, , drop = FALSE]
  fixture$validation_state$event_lineage <- event_lineage
  fixture$validation_state$lineage$rows$disposition <- "excluded"
  fixture$validation_state$lineage$rows$rule_id <- "operational_filter/1.0"
  fixture$validation_state$lineage$rows$reason <- "no_operational_event"

  state <- do.call(
    resolve_selected_resolution,
    fixture[c("config", "snapshot", "validation_state", "entity_state")]
  )

  expect_true(isTRUE(state$integrity_ok))
  expect_true(isTRUE(state$route_eligible))
  expect_equal(nrow(state$event_map), 0L)
  expect_identical(
    names(state$event_map),
    c(
      "event_id", "physical_location_id", "analysis_unit_id", "species",
      "event_time", "source_membership_count", "source_membership_digest",
      "source_membership_reference", "deployment_id",
      "deployment_resolution_state"
    )
  )
  expect_true(inherits(state$event_map$event_time, "POSIXct"))
  expect_identical(state$event_map$source_membership_count, integer())
  expect_equal(state$summary$event_count, 0L)
  expect_equal(state$summary$source_row_membership_count, 0L)

  root <- tempfile("goal011-zero-events-")
  paths <- write_selected_resolution_artifacts(state, root)
  reconstructed <- validate_selected_resolution_artifacts(root, paths)
  expect_true(isTRUE(reconstructed$integrity_ok))
  expect_equal(nrow(reconstructed$event_map), 0L)
})
test_that("explicit selected provenance retains root and reconstructed route status", {
  fixture <- goal009_fixture()
  root <- tempfile("goal009-artifacts-")
  selected_operation <- data.frame(
    analysis_unit_id = rep("jc_co1", 3),
    date = as.Date(c("2020-01-01", "2020-01-02", "2020-01-03")), operation = 1L
  )
  selected_events <- data.frame(
    event_id = c("jc_co1_s1_pos_1", "jc_co1_wal_1"),
    physical_location_id = c("jc_co1_s1", "jc_co1"), analysis_unit_id = "jc_co1",
    species = c("pos", "wal"), event_time = as.POSIXct(c("2020-01-01 01:00:00", "2020-01-03 02:00:00"), tz = "UTC"),
    source_membership_count = c(2L, 1L),
    source_membership_digest = c(
      goal009_membership_digest("jc_co1_s1_pos_1", c("source-row-1", "source-row-2")),
      goal009_membership_digest("jc_co1_wal_1", "source-row-3")
    ), source_membership_reference = "provenance/phase2/event_membership.json",
    stringsAsFactors = FALSE
  )
  selected_membership <- fixture$mapping[c("physical_location_id", "analysis_site_id")]
  names(selected_membership)[[2]] <- "analysis_unit_id"
  state <- list(
    integrity_ok = TRUE, route_eligible = TRUE, reasons = character(),
    membership = selected_membership,
    operation = selected_operation, event_map = selected_events,
    summary = list(
      status = "eligible", integrity_ok = TRUE, route_eligible = TRUE,
      resolution = "analysis_site", scheme_id = "judbury-analysis-site",
      scheme_version = "1.0.0-proposed",
      authority_reference = fixture$config$analysis_unit$authority_reference,
      membership_count = 13L, analysis_unit_count = 9L,
      physical_location_count = 13L,
      operation_state_counts = c(active = 3L, inactive = 0L, unknown = 0L),
      event_count = 2L, source_row_membership_count = 3L,
      reasons = character(),
      claim_limits = c(
        "observed-richness-detection-effort-bounded",
        "jaccard-descriptive-observed-presence-effort-completeness-detectability-limited"
      )
    )
  )
  paths <- write_selected_resolution_artifacts(state, root)
  expect_named(paths, c("membership", "operation", "event_map", "summary"))
  expect_equal(
    unname(basename(paths)),
    c("membership.csv", "operation.csv", "event_map.csv", "summary.json")
  )
  reconstructed <- validate_selected_resolution_artifacts(root, paths)
  expect_true(isTRUE(reconstructed$integrity_ok))
  expect_true(isTRUE(reconstructed$route_eligible))

  ineligible <- state
  ineligible$route_eligible <- FALSE
  ineligible$reasons <- "genuine_concurrent_member_deployments"
  ineligible$summary$status <- "ineligible"
  ineligible$summary$route_eligible <- FALSE
  ineligible$summary$reasons <- ineligible$reasons
  ineligible_root <- tempfile("goal009-ineligible-")
  ineligible_paths <- write_selected_resolution_artifacts(
    ineligible,
    ineligible_root
  )
  ineligible_state <- validate_selected_resolution_artifacts(
    ineligible_root,
    ineligible_paths
  )
  expect_true(isTRUE(ineligible_state$integrity_ok))
  expect_false(isTRUE(ineligible_state$route_eligible))
})

test_that("event time is canonical minimum independent of observation row order", {
  fixture <- goal009_fixture()
  fixture$validation_state$event_lineage$obs_events <-
    fixture$validation_state$event_lineage$obs_events[c(2L, 1L, 3L), ]
  state <- do.call(
    resolve_selected_resolution,
    fixture[c("config", "snapshot", "validation_state", "entity_state")]
  )
  event <- state$event_map[state$event_map$event_id == "jc_co1_s1_pos_1", ]
  expect_equal(
    as.numeric(event$event_time),
    as.numeric(min(fixture$validation_state$event_lineage$obs_events$dt[
      fixture$validation_state$event_lineage$obs_events$event_id == event$event_id
    ]))
  )
})

test_that("handover authorization is date-, precision-, and lineage-specific", {
  fixture <- goal009_fixture()
  off_boundary <- fixture
  off_boundary$validation_state$inputs$op$jc_co1_s1 <- c(0L, 0L, 1L)
  off_boundary$validation_state$inputs$op$jc_co1 <- c(0L, 0L, 1L)
  off_state <- do.call(
    resolve_selected_resolution,
    off_boundary[c("config", "snapshot", "validation_state", "entity_state")]
  )
  expect_false(isTRUE(off_state$route_eligible))
  expect_true(any(grepl("concurrent", off_state$reasons)))

  wrong_precision <- fixture
  wrong_precision$entity_state$deployment_lineage$date_precision[] <- "hour"
  precision_state <- do.call(
    resolve_selected_resolution,
    wrong_precision[c("config", "snapshot", "validation_state", "entity_state")]
  )
  expect_false(isTRUE(precision_state$route_eligible))

  missing_lineage <- fixture
  missing_lineage$entity_state$deployment_lineage <-
    missing_lineage$entity_state$deployment_lineage[
      missing_lineage$entity_state$deployment_lineage$physical_location_identifier != "jc_co1_s1",
    ]
  missing_state <- do.call(
    resolve_selected_resolution,
    missing_lineage[c("config", "snapshot", "validation_state", "entity_state")]
  )
  expect_false(isTRUE(missing_state$route_eligible))
})
