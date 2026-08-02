import::from("testthat", test_that, expect_equal, expect_true, expect_error)
import::from("tibble", tibble)
import::from("here", here)

source(here("R", "event_outputs.R"))

test_that("compute_event_spacing returns expected gaps", {
  obs_events <- tibble(
    site = c("A", "A", "A"),
    species = c("sp1", "sp1", "sp1"),
    event_id = c("A_sp1_1", "A_sp1_2", "A_sp1_2"),
    dt = as.POSIXct(
      c("2020-01-01 00:00:00", "2020-01-01 01:00:00", "2020-01-01 01:10:00"),
      tz = "Australia/Hobart"
    )
  )

  spacing <- compute_event_spacing(obs_events)
  gap <- spacing$gap_hours[spacing$event_id == "A_sp1_2"]

  expect_equal(length(unique(spacing$event_id)), 2)
  expect_true(is.na(spacing$gap_hours[spacing$event_id == "A_sp1_1"]))
  expect_equal(gap, 1)
})

test_that("validate_event_invariants fails if event rows exceed detections", {
  obs_events <- tibble(
    site = c("A", "A"),
    species = c("sp1", "sp1"),
    event_id = c("A_sp1_1", "A_sp1_2")
  )
  obs_filtered <- tibble(site = "A", species = "sp1")

  expect_error(
    validate_event_invariants(obs_events, obs_filtered),
    "events table has more rows"
  )
})

test_that("physical events retain CamtrapDP deployment membership", {
  source(here("R", "config_identity.R"), local = TRUE)
  source(here("R", "fixity.R"), local = TRUE)
  source(here("R", "time_utils.R"), local = TRUE)
  source(here("R", "custom_funcs.R"), local = TRUE)
  source(here("R", "event_outputs.R"), local = TRUE)
  obs <- data.frame(
    index = 1:2,
    site = c("loc_a", "loc_b"),
    physical_location_id = c("loc_a", "loc_b"),
    deployment_id = c("dep_a", "dep_b"),
    species = c("sp1", "sp1"),
    datetime = c("01/01/2020 01:00:00", "01/01/2020 01:05:00"),
    stringsAsFactors = FALSE
  )
  op <- data.frame(
    date = "01/01/2020", loc_a = 1L, loc_b = 1L,
    check.names = FALSE
  )
  lineage <- list(
    rows = data.frame(
      logical_name = "observations", source_row_id = c("source-a", "source-b"),
      disposition = "retained", rule_id = "", reason = "",
      stringsAsFactors = FALSE
    ),
    observation_map = data.frame(
      internal_index = 1:2, source_row_id = c("source-a", "source-b"),
      stringsAsFactors = FALSE
    )
  )

  result <- build_event_lineage(
    obs, op, lineage, threshold = 15, tz = "UTC"
  )

  expect_equal(result$events$site, c("loc_a", "loc_b"))
  expect_equal(result$events$physical_location_id, c("loc_a", "loc_b"))
  expect_equal(result$memberships$deployment_id, c("dep_a", "dep_b"))
  expect_equal(
    result$memberships$physical_location_id,
    c("loc_a", "loc_b")
  )
  expect_equal(nrow(result$memberships), nrow(result$obs_events))
})
