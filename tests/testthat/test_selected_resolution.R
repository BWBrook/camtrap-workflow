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
  sha256_text(canonical_json(sort(as.character(source_ids), method = "radix")))
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
  event_lineage <- validation$event_lineage
  validation$event_lineage <- NULL
  event_lineage$lineage <- validation$lineage
  list(
    config = goal009_config(), mapping = mapping, snapshot = snapshot,
    validation_state = validation, entity_state = entity,
    event_lineage = event_lineage
  )
}
test_that("resolution preserves exact membership and chronology-based concurrency", {
  fixture <- goal009_fixture()
  physical_before <- serialize(list(
    site = fixture$validation_state$inputs$site,
    obs = fixture$validation_state$inputs$obs,
    event_lineage = fixture$event_lineage
  ), NULL)
  state <- do.call(
    resolve_selected_resolution,
    fixture[c(
      "config", "snapshot", "validation_state", "entity_state", "event_lineage"
    )]
  )
  expect_identical(serialize(list(
    site = fixture$validation_state$inputs$site,
    obs = fixture$validation_state$inputs$obs,
    event_lineage = fixture$event_lineage
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
  expected_keyed <- fixture$event_lineage$obs_events[
    !duplicated(fixture$event_lineage$obs_events$event_id),
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
    concurrent[c(
      "config", "snapshot", "validation_state", "entity_state", "event_lineage"
    )]
  )
  expect_true(isTRUE(concurrent_state$integrity_ok))
  expect_false(isTRUE(concurrent_state$route_eligible))
  expect_true(any(grepl("concurrent", concurrent_state$reasons)))
})

test_that("duplicate physical rows hard-stop the selected mapping reader", {
  fixture <- goal009_fixture()
  mismatch <- fixture$config
  mismatch$analysis_unit$mapping_profile_id <- "another-scheme/9.9.9"
  expect_error(
    selected_resolution_read_mapping(mismatch, fixture$snapshot),
    "profile identity"
  )
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
    fixture[c(
      "config", "snapshot", "validation_state", "entity_state", "event_lineage"
    )]
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
    fixture[c(
      "config", "snapshot", "validation_state", "entity_state", "event_lineage"
    )]
  )
  source_members <- fixture$event_lineage$memberships
  mapped <- state$event_map
  expect_equal(
    sort(unique(mapped$event_id)),
    sort(unique(fixture$event_lineage$obs_events$event_id))
  )
  expect_equal(
    sort(unique(mapped$physical_location_id)),
    sort(unique(fixture$event_lineage$obs_events$site))
  )
  expect_equal(sort(unique(mapped$species)), sort(unique(fixture$event_lineage$obs_events$species)))
  expect_true("event_time" %in% names(mapped))
  event_rows <- fixture$event_lineage$obs_events
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
    expect_equal(row$source_membership_reference, "provenance/event_membership.csv")
    expect_equal(row$deployment_resolution_state, "resolved")
    expect_true(nzchar(row$deployment_id))
  }
  expect_equal(
    table(unique(mapped[c("event_id", "species")])$species),
    table(unique(fixture$event_lineage$obs_events[c("event_id", "species")])$species)
  )
  expect_equal(length(unique(mapped$analysis_unit_id)), 1L)
})


test_that("handover authorization is date-, precision-, and lineage-specific", {
  fixture <- goal009_fixture()
  off_boundary <- fixture
  off_boundary$validation_state$inputs$op$jc_co1_s1 <- c(0L, 0L, 1L)
  off_boundary$validation_state$inputs$op$jc_co1 <- c(0L, 0L, 1L)
  off_state <- do.call(
    resolve_selected_resolution,
    off_boundary[c(
      "config", "snapshot", "validation_state", "entity_state", "event_lineage"
    )]
  )
  expect_false(isTRUE(off_state$route_eligible))
  expect_true(any(grepl("concurrent", off_state$reasons)))

  wrong_precision <- fixture
  wrong_precision$entity_state$deployment_lineage$date_precision[] <- "hour"
  precision_state <- do.call(
    resolve_selected_resolution,
    wrong_precision[c(
      "config", "snapshot", "validation_state", "entity_state", "event_lineage"
    )]
  )
  expect_false(isTRUE(precision_state$route_eligible))

  missing_lineage <- fixture
  missing_lineage$entity_state$deployment_lineage <-
    missing_lineage$entity_state$deployment_lineage[
      missing_lineage$entity_state$deployment_lineage$physical_location_identifier != "jc_co1_s1",
    ]
  missing_state <- do.call(
    resolve_selected_resolution,
    missing_lineage[c(
      "config", "snapshot", "validation_state", "entity_state", "event_lineage"
    )]
  )
  expect_false(isTRUE(missing_state$route_eligible))
})
