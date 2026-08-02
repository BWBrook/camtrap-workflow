import::from(
  "testthat", test_that, expect_equal, expect_error, expect_false,
  expect_identical, expect_no_error, expect_setequal, expect_true
)
import::from("tibble", tibble)
import::from("here", here)

source(here("R", "community_matrices.R"))

test_that("selected community arithmetic is exact for the approved nine units", {
  mapping <- read.csv(
    here(
      "docs", "goals", "009-analysis-site-vertical-slice",
      "judbury_analysis_site_mapping.csv"
    ),
    stringsAsFactors = FALSE
  )
  analysis_units <- sort(unique(mapping$analysis_site_id))
  pooled <- mapping$analysis_site_id[duplicated(mapping$analysis_site_id)][[1]]
  pooled_members <- mapping$physical_location_id[
    mapping$analysis_site_id == pooled
  ][1:2]
  other_units <- setdiff(analysis_units, pooled)
  unit_b <- other_units[[1L]]
  unit_c <- other_units[[2L]]
  empty_unit <- other_units[[3L]]
  event_map <- data.frame(
    event_id = paste0("e", 1:5),
    physical_location_id = c(
      pooled_members,
      pooled_members[[2L]],
      mapping$physical_location_id[match(unit_b, mapping$analysis_site_id)],
      mapping$physical_location_id[match(unit_c, mapping$analysis_site_id)]
    ),
    analysis_unit_id = c(rep(pooled, 3L), unit_b, unit_c),
    species = c("sp1", "sp1", "sp2", "sp1", "sp3"),
    stringsAsFactors = FALSE
  )

  presence <- build_selected_presence(
    event_map,
    analysis_units,
    c("sp1", "sp2", "sp3")
  )

  expect_equal(nrow(presence), 9L)
  pooled_row <- match(pooled, analysis_units)
  expect_equal(
    unname(as.integer(presence[pooled_row, ])),
    c(1L, 1L, 0L)
  )
  expect_equal(sum(presence), 4L)
  physical_occurrences <- unique(event_map[c("physical_location_id", "species")])
  expect_equal(nrow(physical_occurrences) - sum(presence), 1L)

  richness <- compute_selected_observed_richness(presence, analysis_units)
  expect_equal(richness$analysis_unit_id, analysis_units)
  expect_equal(
    richness$observed_richness,
    as.integer(rowSums(presence))
  )

  jaccard <- compute_selected_jaccard(presence, analysis_units)
  matrix_view <- xtabs(
    jaccard_dissimilarity ~ analysis_unit_id_1 + analysis_unit_id_2,
    data = jaccard,
    addNA = TRUE,
    na.action = stats::na.pass
  )
  value <- function(a, b) {
    jaccard$jaccard_dissimilarity[
      jaccard$analysis_unit_id_1 == a & jaccard$analysis_unit_id_2 == b
    ]
  }
  expect_equal(nrow(jaccard), 81L)
  expect_equal(value(pooled, unit_b), 0.5)
  expect_equal(value(unit_b, pooled), 0.5)
  expect_equal(value(unit_b, unit_c), 1)
  expect_equal(value(pooled, pooled), 0)
  expect_true(is.na(value(empty_unit, empty_unit)))
  nonempty <- jaccard$jaccard_dissimilarity[
    !is.na(jaccard$jaccard_dissimilarity)
  ]
  expect_true(all(nonempty >= 0 & nonempty <= 1))
  expect_equal(unname(matrix_view), t(unname(matrix_view)))
})

test_that("runtime event conservation decodes canonical artifact times as UTC", {
  event_map <- data.frame(
    event_id = c("e1", "e2"),
    physical_location_id = c("camera_a", "camera_b"),
    species = c("sp1", "sp2"),
    event_time = c("2020-01-01T01:00:00Z", "2020-01-02T02:00:00Z"),
    stringsAsFactors = FALSE
  )
  artifact <- tempfile(fileext = ".csv")
  utils::write.csv(event_map, artifact, row.names = FALSE)
  event_map <- utils::read.csv(artifact, stringsAsFactors = FALSE)
  runtime_events <- data.frame(
    event_id = c("e1", "e1", "e2"),
    site = c("camera_a", "camera_a", "camera_b"),
    species = c("sp1", "sp1", "sp2"),
    dt = as.POSIXct(c(
      "2020-01-01 11:00:00", "2020-01-01 11:05:00",
      "2020-01-02 12:00:00"
    ), tz = "Etc/GMT-10"),
    stringsAsFactors = FALSE
  )

  conservation <- NULL
  expect_no_error(
    conservation <- validate_selected_runtime_events(event_map, runtime_events)
  )
  expect_true(isTRUE(conservation$exact))
  expect_equal(conservation$preflight_event_count, 2L)
  expect_equal(conservation$runtime_event_count, 2L)
})

test_that("runtime event conservation rejects noncanonical artifact times", {
  runtime_events <- data.frame(
    event_id = "e1",
    site = "camera_a",
    species = "sp1",
    dt = as.POSIXct("2020-01-01 01:00:00", tz = "UTC"),
    stringsAsFactors = FALSE
  )
  event_map <- data.frame(
    event_id = "e1",
    physical_location_id = "camera_a",
    species = "sp1",
    event_time = "2020-01-01 01:00:00",
    stringsAsFactors = FALSE
  )

  expect_error(
    validate_selected_runtime_events(event_map, runtime_events),
    "canonical UTC"
  )
  event_map$event_time <- "2020-02-30T01:00:00Z"
  expect_error(
    validate_selected_runtime_events(event_map, runtime_events),
    "canonical UTC"
  )
})

test_that("selected ecological writer conserves events and routes by eligibility", {
  root <- tempfile("selected-ecology-")
  event_map <- data.frame(
    event_id = c("e1", "e2"),
    physical_location_id = c("camera_a", "camera_b"),
    analysis_unit_id = c("unit_a", "unit_b"),
    species = c("sp1", "sp2"),
    event_time = c("2020-01-01T01:00:00Z", "2020-01-02T02:00:00Z"),
    deployment_id = c("dep_a", "dep_b"),
    stringsAsFactors = FALSE
  )
  runtime_events <- data.frame(
    event_id = c("e1", "e1", "e2"),
    site = c("camera_a", "camera_a", "camera_b"),
    species = c("sp1", "sp1", "sp2"),
    dt = as.POSIXct(c(
      "2020-01-01 01:00:00", "2020-01-01 01:05:00",
      "2020-01-02 02:00:00"
    ), tz = "UTC"),
    stringsAsFactors = FALSE
  )
  state <- list(
    integrity_ok = TRUE,
    route_eligible = TRUE,
    reasons = character(),
    membership = data.frame(
      physical_location_id = c("camera_a", "camera_b", "camera_c"),
      analysis_unit_id = c("unit_a", "unit_b", "unit_c"),
      stringsAsFactors = FALSE
    ),
    operation = data.frame(
      analysis_unit_id = c("unit_a", "unit_b", "unit_c"),
      date = as.Date(c("2020-01-01", "2020-01-02", "2020-01-02")),
      operation = c(1, 1, 0),
      deployment_states_json = c(
        '{"camera_a":"dep_a"}', '{"camera_b":"dep_b"}',
        '{"camera_c":"dep_c"}'
      ),
      stringsAsFactors = FALSE
    ),
    event_map = event_map,
    summary = list(
      status = "eligible",
      integrity_ok = TRUE,
      route_eligible = TRUE,
      resolution = "analysis_site",
      scheme_id = "test-scheme",
      scheme_version = "1.0.0",
      authority_reference = "test-authority",
      membership_count = 3L,
      analysis_unit_count = 3L,
      physical_location_count = 3L,
      event_count = 2L,
      reasons = character(),
      claim_limits = c(
        "observed-richness-detection-effort-bounded",
        "jaccard-descriptive-observed-presence-effort-completeness-detectability-limited"
      )
    )
  )

  outputs <- write_selected_ecological_outputs(state, runtime_events, root)
  expect_setequal(names(outputs), c(
    "effort_coverage", "community_presence", "observed_richness",
    "jaccard", "status"
  ))
  expect_equal(unname(basename(unlist(outputs))), c(
    "selected_effort_coverage.csv", "selected_community_presence.csv",
    "selected_observed_richness.csv", "selected_jaccard.csv",
    "selected_resolution_status.json"
  ))
  expect_true(all(file.exists(unlist(outputs))))

  effort <- read.csv(outputs$effort_coverage, check.names = FALSE)
  presence <- read.csv(outputs$community_presence, check.names = FALSE)
  richness <- read.csv(outputs$observed_richness, check.names = FALSE)
  jaccard <- read.csv(outputs$jaccard, check.names = FALSE)
  status <- jsonlite::read_json(outputs$status, simplifyVector = FALSE)
  jaccard_claim_limit <-
    "jaccard-descriptive-observed-presence-effort-completeness-detectability-limited"
  expect_false("site" %in% names(presence))
  expect_true(all(c(
    "analysis_unit_id", "analysis_unit_count", "temporal_scope_start",
    "temporal_scope_end", "effort_definition",
    "claim_limit", "metadata_reference"
  ) %in% names(presence)))
  expect_equal(effort$confirmed_active_days, c(1L, 1L, 0L))
  expect_equal(effort$confirmed_inactive_days, c(0L, 0L, 1L))
  expect_equal(richness$observed_richness, c(1L, 1L, 0L))
  expect_equal(unique(jaccard$claim_limit), jaccard_claim_limit)
  expect_identical(status$claim_limits$jaccard, jaccard_claim_limit)
  expect_identical(status$module_status_schema, "camtrap-module-status/1.0")
  expect_identical(status$status, "completed")
  expect_true(is.null(status$reason))
  expect_identical(status$actual_resolution, "analysis_site")
  expect_setequal(
    unlist(status$required_evidence, use.names = FALSE),
    c(
      "validated_selected_resolution", "confirmed_effort",
      "physical_location_events"
    )
  )
  expect_true(isTRUE(status$event_conservation$exact))
  expect_true(all(c(
    "contributing_physical_locations", "contributing_deployments"
  ) %in% names(status$analysis_units[[1]])))
  expect_true(is.list(
    status$analysis_units[[1]]$contributing_physical_locations
  ))
  expect_true(is.list(status$analysis_units[[1]]$contributing_deployments))

  ineligible <- state
  ineligible$route_eligible <- FALSE
  ineligible$reasons <- NULL
  ineligible$summary$status <- "ineligible"
  ineligible$summary$route_eligible <- FALSE
  ineligible$summary$reasons <-
    "genuine_concurrent_member_deployments:unit_a"
  ineligible_root <- tempfile("selected-ineligible-")
  ineligible_outputs <- write_selected_ecological_outputs(
    ineligible,
    runtime_events,
    ineligible_root
  )
  expect_true(all(vapply(ineligible_outputs[1:4], is.null, logical(1))))
  expect_true(file.exists(ineligible_outputs$status))
  expect_equal(
    list.files(file.path(ineligible_root, "tables")),
    "selected_resolution_status.json"
  )
  ineligible_status <- jsonlite::read_json(
    ineligible_outputs$status,
    simplifyVector = FALSE
  )
  expect_false(isTRUE(ineligible_status$route_eligible))
  expect_identical(ineligible_status$status, "omitted")
  expect_identical(
    ineligible_status$reason,
    "genuine_concurrent_member_deployments:unit_a"
  )
  expect_true(all(vapply(ineligible_status$outputs[1:4], is.null, logical(1))))
  expect_equal(
    ineligible_status$reasons[[1]],
    "genuine_concurrent_member_deployments:unit_a"
  )

  integrity_failure <- ineligible
  integrity_failure$integrity_ok <- FALSE
  integrity_failure$summary$status <- "integrity_failure"
  integrity_failure$summary$integrity_ok <- FALSE
  integrity_failure$summary$reasons <- "incomplete_or_orphan_mapping"
  integrity_failure$event_map$event_id[[1]] <- "nonmatching-event"
  integrity_root <- tempfile("selected-integrity-failure-")
  integrity_outputs <- write_selected_ecological_outputs(
    integrity_failure,
    runtime_events,
    integrity_root
  )
  expect_true(all(vapply(integrity_outputs[1:4], is.null, logical(1))))
  integrity_status <- jsonlite::read_json(
    integrity_outputs$status,
    simplifyVector = FALSE
  )
  expect_equal(integrity_status$status, "failed")
  expect_equal(integrity_status$reason, "incomplete_or_orphan_mapping")
  expect_equal(integrity_status$reasons[[1]], "incomplete_or_orphan_mapping")
  expect_false(isTRUE(integrity_status$event_conservation$checked))
})

test_that("zero events produce valid empty evidence with a plain warning", {
  root <- tempfile("selected-zero-events-")
  analysis_units <- c("unit_a", "unit_b")
  state <- list(
    integrity_ok = TRUE,
    route_eligible = TRUE,
    reasons = character(),
    membership = data.frame(
      physical_location_id = c("camera_a", "camera_b"),
      analysis_unit_id = analysis_units,
      stringsAsFactors = FALSE
    ),
    operation = data.frame(
      analysis_unit_id = analysis_units,
      date = as.Date(c("2020-01-01", "2020-01-01")),
      operation = c(0, 0),
      deployment_states_json = c("{}", "{}"),
      stringsAsFactors = FALSE
    ),
    event_map = data.frame(
      event_id = character(),
      physical_location_id = character(),
      analysis_unit_id = character(),
      species = character(),
      event_time = as.POSIXct(character(), tz = "UTC"),
      source_membership_count = integer(),
      source_membership_digest = character(),
      source_membership_reference = character(),
      deployment_id = character(),
      deployment_resolution_state = character(),
      stringsAsFactors = FALSE
    ),
    summary = list(
      status = "eligible", integrity_ok = TRUE, route_eligible = TRUE,
      resolution = "analysis_site", scheme_id = "test-scheme",
      scheme_version = "1.0.0", authority_reference = "test-authority",
      membership_count = 2L, analysis_unit_count = 2L,
      physical_location_count = 2L, event_count = 0L,
      source_row_membership_count = 0L, reasons = character()
    )
  )
  runtime_events <- data.frame(
    event_id = character(), site = character(), species = character(),
    dt = as.POSIXct(character(), tz = "UTC"), stringsAsFactors = FALSE
  )

  outputs <- write_selected_ecological_outputs(state, runtime_events, root)
  presence <- read.csv(outputs$community_presence, check.names = FALSE)
  richness <- read.csv(outputs$observed_richness, check.names = FALSE)
  jaccard <- read.csv(outputs$jaccard, check.names = FALSE)
  status <- jsonlite::read_json(outputs$status, simplifyVector = FALSE)

  expect_equal(nrow(presence), 2L)
  expect_equal(richness$observed_richness, c(0L, 0L))
  expect_equal(nrow(jaccard), 4L)
  expect_true(all(is.na(jaccard$jaccard_dissimilarity)))
  expect_identical(status$status, "completed_with_warnings")
  expect_identical(status$reason, "no_operational_events")
})
