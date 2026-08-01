import::from(
  "testthat", test_that, expect_equal, expect_error, expect_false,
  expect_identical, expect_named, expect_null, expect_silent, expect_true
)
import::from("here", here)
source(here("R", "config_identity.R"))
source(here("R", "fixity.R"))
source(here("R", "config.R"))
source(here("R", "event_outputs.R"))

# Goal 009 is intentionally tested before its implementation exists. Missing
# interfaces become ordinary failed expectations, not load-order errors.
goal009_require <- function(name) {
  fn <- get0(name, envir = .GlobalEnv, mode = "function", inherits = FALSE)
  if (is.null(fn)) {
    expect_true(FALSE, info = paste("missing Goal 009 interface:", name))
    return(NULL)
  }
  fn
}
selected_resolution_path <- here("R", "selected_resolution.R")
if (file.exists(selected_resolution_path)) source(selected_resolution_path)
source(here("R", "community_matrices.R"))
goal009_mapping <- function() {
  read.csv(here("docs", "goals", "009-analysis-site-vertical-slice",
    "judbury_analysis_site_mapping.csv"), stringsAsFactors = FALSE,
    check.names = FALSE)
}
goal009_config <- function(resolution = "analysis_site", mapped = TRUE) {
  fields <- list(mapping_profile_id = NULL, mapping_path = NULL, mapping_sha256 = NULL,
                 authority_reference = NULL)
  if (mapped) fields <- list(
    mapping_profile_id = "judbury-analysis-site/1.0.0-proposed",
    mapping_path = "docs/goals/009-analysis-site-vertical-slice/judbury_analysis_site_mapping.csv",
    mapping_sha256 = "6490d7f7021e5c727b9be1c7d6dfbf44ba50a1ef5b0396c66e1dd813a9c77083",
    authority_reference = paste0("goal009-judbury-analysis-site-mapping-sha256-",
      "6490d7f7021e5c727b9be1c7d6dfbf44ba50a1ef5b0396c66e1dd813a9c77083")
  )
  list(analysis_unit = c(list(resolution = resolution), fields))
}
goal009_membership_digest <- function(event_id, source_ids) {
  sha256_text(canonical_json(list(event_id = event_id,
    source_row_ids = sort(as.character(source_ids), method = "radix"))))
}
goal009_fixture <- function() {
  mapping <- goal009_mapping()
  physical <- mapping$physical_location_id
  deployment <- paste0("judbury_dep_", physical)
  predecessor <- rep(NA_character_, length(physical))
  successor <- predecessor
  predecessor[physical == "jc_co1"] <- deployment[physical == "jc_co1_s1"]
  successor[physical == "jc_co1_s1"] <- deployment[physical == "jc_co1"]
  operation <- data.frame(date = as.Date(c("2020-01-01", "2020-01-02", "2020-01-03")),
                          check.names = FALSE)
  for (site in physical) operation[[site]] <- c(1L, 1L, 1L)
  operation[c("jc_co3_s16", "jc_pm14_s1", "jc_pm34_s15")] <- 0L
  operation$jc_co1 <- c(0L, 1L, 1L)
  operation$jc_co1_s1 <- c(1L, 1L, 0L)
  obs <- data.frame(index = 1:3, site = c("jc_co1_s1", "jc_co1_s1", "jc_co1"),
    species = c("pos", "pos", "wal"),
    datetime = c("01/01/2020 01:00:00", "01/01/2020 01:05:00", "03/01/2020 02:00:00"),
    dt = as.POSIXct(c("2020-01-01 01:00:00", "2020-01-01 01:05:00", "2020-01-03 02:00:00"), tz = "UTC"),
    event_id = c("jc_co1_s1_pos_1", "jc_co1_s1_pos_1", "jc_co1_wal_1"),
    flash = c(0L, 1L, 0L), count = c(1L, 1L, 2L), stringsAsFactors = FALSE)
  source_ids <- paste0("source-row-", 1:3)
  memberships <- data.frame(membership_schema = "camtrap-event-membership/1.0",
    membership_id = mapply(event_membership_identity, obs$event_id, source_ids,
      USE.NAMES = FALSE), event_id = obs$event_id,
    source_row_id = source_ids, stringsAsFactors = FALSE)
  validation <- list(
    inputs = list(site = data.frame(site = physical, stringsAsFactors = FALSE),
      op = operation, obs = obs, taxa = data.frame(short = c("pos", "wal"))),
    lineage = list(
      rows = data.frame(logical_name = "obs", record_ordinal = 1:3,
        source_row_id = source_ids, disposition = "retained",
        rule_id = "", reason = ""),
      observation_map = data.frame(internal_index = 1:3,
        record_ordinal = 1:3, source_row_id = source_ids)),
    event_lineage = list(event_lineage_schema = "camtrap-event-lineage/1.0",
      event_rule = list(rule_id = "operational_detection_event.gap/1.0",
        threshold_minutes = 15, timezone = "UTC", fixed_offset_hours = NULL),
      events = data.frame(event_schema = "camtrap-operational-event/1.0",
        event_id = c("jc_co1_s1_pos_1", "jc_co1_wal_1"),
        site = c("jc_co1_s1", "jc_co1"), species = c("pos", "wal"), member_count = c(2L, 1L)),
      memberships = memberships, obs_events = obs))
  entity <- list(can_analyze = TRUE,
    records = data.frame(entity_type = rep("physical_location", 13),
      entity_id = paste0("physical-entity-", physical), source_identifier = physical,
      resolution_state = "resolved"),
    links = data.frame(link_type = rep("deployment_to_physical_location", 13),
      source_entity_id = paste0("deployment-entity-", deployment),
      target_entity_id = paste0("physical-entity-", physical)),
    deployment_lineage = data.frame(deployment_identifier = deployment,
    deployment_entity_id = paste0("deployment-entity-", deployment),
    physical_location_identifier = physical, predecessor_deployment_id = predecessor,
    physical_location_entity_id = paste0("physical-entity-", physical),
    successor_deployment_id = successor, interval_start = as.Date("2019-01-01"),
    interval_end = as.Date("2022-12-31"), date_precision = "day",
    endpoint_semantics = "inclusive_at_day_precision_unknown_time",
    chronology_state = "not_applicable", resolution_state = "resolved"))
  entity$deployment_lineage$interval_end[physical == "jc_co1_s1"] <- as.Date("2020-01-02")
  entity$deployment_lineage$interval_start[physical == "jc_co1"] <- as.Date("2020-01-02")
  entity$deployment_lineage$chronology_state[physical %in% c("jc_co1", "jc_co1_s1")] <-
    "same_date_boundary_not_full_day_overlap_or_routing_claim"
  staging_dir <- tempfile("goal009-source-")
  mapping_root <- file.path(staging_dir, "source_snapshot", "analysis_site_mapping")
  dir.create(mapping_root, recursive = TRUE)
  mapping_copy <- file.path(mapping_root, "judbury_analysis_site_mapping.csv")
  file.copy(here("docs", "goals", "009-analysis-site-vertical-slice",
    "judbury_analysis_site_mapping.csv"), mapping_copy)
  inventory <- file_fixity_record(mapping_copy, staging_dir,
    role = "analysis_site_mapping_input", consumed = FALSE)
  snapshot <- list(staging_dir = staging_dir,
    snapshot_root = file.path(staging_dir, "source_snapshot"),
    source_sha256 = fixity_identity(list(inventory)), inventory = list(inventory))
  list(config = goal009_config(), mapping = mapping, snapshot = snapshot,
    validation_state = validation, entity_state = entity)
}
test_that("minimal interface-shaped fixture retains acquisition and lineage shapes", {
  fixture <- goal009_fixture()
  record <- fixture$snapshot$inventory[[1]]
  expect_equal(record$role, "analysis_site_mapping_input")
  expect_equal(record$sha256, fixture$config$analysis_unit$mapping_sha256)
  expect_equal(nrow(fixture$entity_state$records), 13L)
  expect_equal(nrow(fixture$entity_state$links), 13L)
  expect_equal(nrow(fixture$entity_state$deployment_lineage), 13L)
  expect_true(all(c("entity_id", "source_identifier") %in% names(fixture$entity_state$records)))
  expect_true(all(c("source_entity_id", "target_entity_id") %in% names(fixture$entity_state$links)))
  expect_true(all(c("deployment_entity_id", "physical_location_entity_id") %in% names(fixture$entity_state$deployment_lineage)))
  lineage <- fixture$entity_state$deployment_lineage
  expect_equal(lineage$predecessor_deployment_id[lineage$physical_location_identifier == "jc_co1"], "judbury_dep_jc_co1_s1")
  expect_equal(lineage$successor_deployment_id[lineage$physical_location_identifier == "jc_co1_s1"], "judbury_dep_jc_co1")
  expect_equal(lineage$chronology_state[lineage$physical_location_identifier == "jc_co1"],
    "same_date_boundary_not_full_day_overlap_or_routing_claim")
  expect_true(all(c("date", "jc_co1", "jc_co1_s1") %in%
    names(fixture$validation_state$inputs$op)))
  expect_true(all(c("event_id", "source_row_id") %in%
    names(fixture$validation_state$event_lineage$memberships)))
  expect_silent(validate_event_membership(fixture$validation_state$event_lineage,
    fixture$validation_state$event_lineage$obs_events, fixture$validation_state$lineage))
  expect_false("operation" %in% names(fixture$validation_state))
  expect_false("handover_approved" %in% names(fixture$validation_state$inputs))
})
test_that("analysis-unit selection normalizes legacy, mapped, identity, and direct modes", {
  fn <- goal009_require("analysis_unit_selection")
  if (!is.null(fn)) {
    expect_null(fn(list()))
    expect_equal(fn(goal009_config())$resolution, "analysis_site")
    identity <- fn(goal009_config(mapped = FALSE))
    expect_equal(identity$resolution, "analysis_site")
    expect_true("camtrap-physical-location-identity" %in%
      unname(unlist(identity, use.names = FALSE)))
    expect_equal(fn(goal009_config("physical_location", FALSE))$resolution,
                 "physical_location")
    expect_equal(fn(goal009_config("nominal_station", FALSE))$resolution,
                 "nominal_station")
    malformed <- goal009_config()
    malformed$analysis_unit$mapping_sha256 <- NULL
    expect_error(fn(malformed), "mapping|authority|selection", ignore.case = TRUE)
  }
})
test_that("resolution preserves exact membership, identity, and chronology-based concurrency", {
  fn <- goal009_require("resolve_selected_resolution")
  if (!is.null(fn)) {
    fixture <- goal009_fixture()
    state <- do.call(fn, fixture[c("config", "snapshot", "validation_state", "entity_state")])
    expected <- fixture$mapping[c("physical_location_id", "analysis_site_id")]
    names(expected)[[2]] <- "analysis_unit_id"
    actual <- state$membership[order(state$membership$physical_location_id),
                               c("physical_location_id", "analysis_unit_id")]
    expected <- expected[order(expected$physical_location_id), ]
    rownames(actual) <- rownames(expected) <- NULL
    expect_equal(nrow(actual), 13L)
    expect_equal(actual, expected)
    keyed <- state$event_map[c("event_id", "physical_location_id", "species", "event_time", "analysis_unit_id")]
    expected_keyed <- fixture$validation_state$event_lineage$obs_events[
      !duplicated(fixture$validation_state$event_lineage$obs_events$event_id),
      c("event_id", "site", "species", "dt")]
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
    expect_true(all(c("analysis_unit_id", "date", "operation") %in%
      names(state$operation)))
    expect_true(all(c(
      "member_states_json", "deployment_states_json", "concurrency_class"
    ) %in% names(state$operation)))
    expect_true(all(c(
      "physical_latitude", "physical_longitude", "representative_latitude",
      "representative_longitude", "coordinate_basis"
    ) %in% names(state$membership)))
    handover <- state$operation[
      state$operation$analysis_unit_id == "jc_co1" &
        state$operation$operation == 1, , drop = FALSE
    ]
    expect_equal(nrow(handover), 3L)
    expect_equal(length(unique(handover$date)), 3L)
    expect_equal(sum(handover$date == as.Date("2020-01-02")), 1L)

    identity <- fixture
    identity$config <- goal009_config(mapped = FALSE)
    identity$snapshot$inventory <- Filter(function(x) !identical(
      x$role, "analysis_site_mapping_input"), identity$snapshot$inventory)
    identity$snapshot$source_sha256 <- fixity_identity(identity$snapshot$inventory)
    identity_state <- do.call(fn, identity[c("config", "snapshot", "validation_state", "entity_state")])
    expect_equal(nrow(identity_state$membership), 13L)
    expect_equal(identity_state$membership$physical_location_id,
                 identity_state$membership$analysis_unit_id)

    physical_without_lineage <- identity
    physical_without_lineage$config <- goal009_config("physical_location", FALSE)
    physical_without_lineage$entity_state$deployment_lineage <- data.frame()
    physical_state <- do.call(
      fn,
      physical_without_lineage[c("config", "snapshot", "validation_state", "entity_state")]
    )
    expect_identical(physical_state$integrity_ok, TRUE)
    expect_identical(physical_state$route_eligible, TRUE)

    concurrent <- fixture
    concurrent$validation_state$inputs$op[1, c("jc_co1", "jc_co1_s1")] <- 1L
    concurrent$entity_state$deployment_lineage$predecessor_deployment_id[] <- NA_character_
    concurrent$entity_state$deployment_lineage$successor_deployment_id[] <- NA_character_
    concurrent_state <- do.call(fn, concurrent[c("config", "snapshot", "validation_state", "entity_state")])
    expect_true(isTRUE(concurrent_state$integrity_ok))
    expect_false(isTRUE(concurrent_state$route_eligible))
    expect_true(any(grepl("concurrent", concurrent_state$reasons)))
  }
})
test_that("selected operation applies the full three-state union and preserves gaps", {
  fn <- goal009_require("build_selected_effort_coverage")
  if (!is.null(fn)) {
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
    coverage <- fn(operation, membership)
    value <- stats::setNames(coverage$operation, coverage$date)
    expect_equal(value[["2020-01-01"]], 1)
    expect_equal(value[["2020-01-02"]], 1)
    expect_equal(value[["2020-01-03"]], 1)
    expect_true(is.na(value[["2020-01-04"]]))
    expect_equal(value[["2020-01-05"]], 0)
    expect_true(is.na(value[["2020-01-06"]]))
    expect_false(any(coverage$date == as.Date("2020-01-07")))
  }
})
test_that("event mapping preserves multi-row lineage and exact event conservation", {
  fn <- goal009_require("resolve_selected_resolution")
  if (!is.null(fn)) {
    fixture <- goal009_fixture()
    state <- do.call(fn, fixture[c("config", "snapshot", "validation_state", "entity_state")])
    source_members <- fixture$validation_state$event_lineage$memberships
    mapped <- state$event_map
    expect_equal(sort(unique(mapped$event_id)),
                 sort(unique(fixture$validation_state$event_lineage$obs_events$event_id)))
    expect_equal(sort(unique(mapped$physical_location_id)),
                 sort(unique(fixture$validation_state$event_lineage$obs_events$site)))
    expect_equal(sort(unique(mapped$species)), sort(unique(fixture$validation_state$event_lineage$obs_events$species)))
    expect_true("event_time" %in% names(mapped))
    event_rows <- fixture$validation_state$event_lineage$obs_events
    event_rows <- event_rows[!duplicated(event_rows$event_id), ]
    expect_equal(nrow(mapped), nrow(event_rows))
    expect_equal(anyDuplicated(mapped$event_id), 0L)
    expect_equal(length(unique(mapped$event_id)), nrow(event_rows))
    expect_equal(sort(as.numeric(mapped$event_time)), sort(as.numeric(event_rows$dt)))
    expect_true(all(c("source_membership_count", "source_membership_digest",
      "source_membership_reference") %in% names(mapped)))
    expected_by_event <- split(source_members$source_row_id, source_members$event_id)
    for (event_id in names(expected_by_event)) {
      row <- mapped[mapped$event_id == event_id, , drop = FALSE]
      expect_equal(row$source_membership_count, length(expected_by_event[[event_id]]))
      expect_equal(row$source_membership_digest,
        goal009_membership_digest(event_id, expected_by_event[[event_id]]))
      expect_equal(row$source_membership_reference, "provenance/phase2/event_membership.json")
      expect_equal(row$deployment_resolution_state, "resolved")
      expect_true(nzchar(row$deployment_id))
    }
    expect_equal(table(unique(mapped[c("event_id", "species")])$species),
                 table(unique(fixture$validation_state$event_lineage$obs_events[c("event_id", "species")])$species))
    expect_equal(length(unique(mapped$analysis_unit_id)), 1L)
  }
})
test_that("selected presence is member-presence OR with richness row sums", {
  fn <- goal009_require("build_selected_presence")
  if (!is.null(fn)) {
    event_map <- data.frame(
      analysis_unit_id = c("a", "a", "b"),
      species = c("sp1", "sp1", "sp2"), event_id = c("e1", "e2", "e3")
    )
    presence <- fn(event_map, c("a", "b", "c"), c("sp1", "sp2", "sp3"))
    expect_equal(unname(as.matrix(presence)),
                 matrix(c(1, 0, 0, 0, 1, 0, 0, 0, 0), nrow = 3, byrow = TRUE))
    expect_equal(rowSums(presence), c(1, 1, 0))
  }
})
test_that("explicit selected provenance retains root and reconstructed route status", {
  write_fn <- goal009_require("write_selected_resolution_artifacts")
  validate_fn <- goal009_require("validate_selected_resolution_artifacts")
  if (!is.null(write_fn) && !is.null(validate_fn)) {
    fixture <- goal009_fixture()
    root <- tempfile("goal009-artifacts-")
    selected_operation <- data.frame(analysis_unit_id = rep("jc_co1", 3),
      date = as.Date(c("2020-01-01", "2020-01-02", "2020-01-03")), operation = 1L)
    selected_events <- data.frame(event_id = c("jc_co1_s1_pos_1", "jc_co1_wal_1"),
      physical_location_id = c("jc_co1_s1", "jc_co1"), analysis_unit_id = "jc_co1",
      species = c("pos", "wal"), event_time = as.POSIXct(c("2020-01-01 01:00:00", "2020-01-03 02:00:00"), tz = "UTC"),
      source_membership_count = c(2L, 1L),
      source_membership_digest = c(
        goal009_membership_digest("jc_co1_s1_pos_1", c("source-row-1", "source-row-2")),
        goal009_membership_digest("jc_co1_wal_1", "source-row-3")
      ), source_membership_reference = "provenance/phase2/event_membership.json",
      stringsAsFactors = FALSE)
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
        claim_limits = c("observed-richness-detection-effort-bounded",
          "jaccard-descriptive-observed-presence-effort-completeness-detectability-limited")
      )
    )
    paths <- write_fn(state, root)
    expect_named(paths, c("membership", "operation", "event_map", "summary"))
    expect_equal(unname(basename(paths)),
                 c("membership.csv", "operation.csv", "event_map.csv", "summary.json"))
    reconstructed <- validate_fn(root, paths)
    expect_true(isTRUE(reconstructed$integrity_ok))
    expect_true(isTRUE(reconstructed$route_eligible))

    parity_root <- tempfile("goal009-artifact-parity-")
    parity_paths <- write_fn(state, parity_root)
    expect_equal(
      vapply(paths, sha256_file, character(1)),
      vapply(parity_paths, sha256_file, character(1))
    )

    ineligible <- state
    ineligible$route_eligible <- FALSE
    ineligible$reasons <- "genuine_concurrent_member_deployments"
    ineligible$summary$status <- "ineligible"
    ineligible$summary$route_eligible <- FALSE
    ineligible$summary$reasons <- ineligible$reasons
    ineligible_root <- tempfile("goal009-ineligible-")
    ineligible_paths <- write_fn(ineligible, ineligible_root)
    ineligible_state <- validate_fn(ineligible_root, ineligible_paths)
    expect_true(isTRUE(ineligible_state$integrity_ok))
    expect_false(isTRUE(ineligible_state$route_eligible))
    writeLines("tamper", file.path(dirname(paths[["membership"]]), "extra.txt"))
    expect_error(validate_fn(root, paths), "namespace|extra|incomplete")
    unlink(file.path(dirname(paths[["membership"]]), "extra.txt"))
    original_membership <- readLines(paths[["membership"]])
    writeLines(c(original_membership, "tamper"), paths[["membership"]])
    expect_error(validate_fn(root, paths), "fixity|tamper")
    writeLines(original_membership, paths[["membership"]])
    summary_path <- paths[["summary"]]
    summary_json <- jsonlite::read_json(summary_path, simplifyVector = FALSE)
    summary_json$status <- "ineligible"
    jsonlite::write_json(summary_json, summary_path, auto_unbox = TRUE, pretty = TRUE,
                         null = "null", na = "null", digits = NA)
    expect_error(validate_fn(root, paths), "status|reconstruct|summary")
  }
})

test_that("nominal selection uses authoritative physical-to-grid links", {
  fixture <- goal009_fixture()
  fixture$config <- goal009_config("nominal_station", mapped = FALSE)
  nominal_ids <- paste0("nominal-", seq_len(13L))
  nominal_records <- data.frame(
    entity_type = rep("nominal_grid_station", 13L),
    entity_id = nominal_ids,
    source_identifier = paste0("station-", seq_len(13L)),
    resolution_state = "resolved", stringsAsFactors = FALSE
  )
  fixture$entity_state$records <- rbind(fixture$entity_state$records, nominal_records)
  nominal_links <- data.frame(
    link_type = rep("physical_location_to_nominal_grid_station", 13L),
    source_entity_id = paste0("physical-entity-", fixture$mapping$physical_location_id),
    target_entity_id = nominal_ids, stringsAsFactors = FALSE
  )
  fixture$entity_state$links <- rbind(fixture$entity_state$links, nominal_links)
  state <- do.call(resolve_selected_resolution,
    fixture[c("config", "snapshot", "validation_state", "entity_state")])
  expect_true(isTRUE(state$integrity_ok))
  expect_true(isTRUE(state$route_eligible))
  expect_equal(length(unique(state$membership$analysis_unit_id)), 13L)
  expect_true(all(state$membership$analysis_unit_id %in%
    nominal_records$source_identifier))

  unavailable <- goal009_fixture()
  unavailable$config <- goal009_config("nominal_station", mapped = FALSE)
  unavailable_state <- do.call(resolve_selected_resolution,
    unavailable[c("config", "snapshot", "validation_state", "entity_state")])
  expect_identical(unavailable_state$integrity_ok, TRUE)
  expect_identical(unavailable_state$route_eligible, FALSE)
  expect_true(any(grepl("authority_unavailable", unavailable_state$reasons)))

  malformed <- fixture
  malformed$entity_state$links <- rbind(malformed$entity_state$links, nominal_links[1, ])
  malformed_state <- do.call(resolve_selected_resolution,
    malformed[c("config", "snapshot", "validation_state", "entity_state")])
  expect_false(isTRUE(malformed_state$integrity_ok))
})

test_that("event time is canonical minimum independent of observation row order", {
  fixture <- goal009_fixture()
  fixture$validation_state$event_lineage$obs_events <-
    fixture$validation_state$event_lineage$obs_events[c(2L, 1L, 3L), ]
  state <- do.call(resolve_selected_resolution,
    fixture[c("config", "snapshot", "validation_state", "entity_state")])
  event <- state$event_map[state$event_map$event_id == "jc_co1_s1_pos_1", ]
  expect_equal(as.numeric(event$event_time),
    as.numeric(min(fixture$validation_state$event_lineage$obs_events$dt[
      fixture$validation_state$event_lineage$obs_events$event_id == event$event_id])))
})

test_that("handover authorization is date-, precision-, and lineage-specific", {
  fixture <- goal009_fixture()
  off_boundary <- fixture
  off_boundary$validation_state$inputs$op$jc_co1_s1 <- c(0L, 0L, 1L)
  off_boundary$validation_state$inputs$op$jc_co1 <- c(0L, 0L, 1L)
  off_state <- do.call(resolve_selected_resolution,
    off_boundary[c("config", "snapshot", "validation_state", "entity_state")])
  expect_false(isTRUE(off_state$route_eligible))
  expect_true(any(grepl("concurrent", off_state$reasons)))

  wrong_precision <- fixture
  wrong_precision$entity_state$deployment_lineage$date_precision[] <- "hour"
  precision_state <- do.call(resolve_selected_resolution,
    wrong_precision[c("config", "snapshot", "validation_state", "entity_state")])
  expect_false(isTRUE(precision_state$route_eligible))

  missing_lineage <- fixture
  missing_lineage$entity_state$deployment_lineage <-
    missing_lineage$entity_state$deployment_lineage[
      missing_lineage$entity_state$deployment_lineage$physical_location_identifier != "jc_co1_s1", ]
  missing_state <- do.call(resolve_selected_resolution,
    missing_lineage[c("config", "snapshot", "validation_state", "entity_state")])
  expect_false(isTRUE(missing_state$route_eligible))
})
