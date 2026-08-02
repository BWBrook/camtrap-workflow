import::from("testthat", test_that, expect_true, expect_equal, expect_error, expect_gte, expect_lte)
import::from("tibble", tibble)
import::from("here", here)

source(here("R", "custom_funcs.R"))
source(here("R", "effort_outputs.R"))

test_that("QC: check_keys fails fast on unknown sites", {
  obs <- tibble(
    site = c("A", "C"),
    datetime = c("01/01/2020 00:00:00", "01/01/2020 00:10:00"),
    species = c("sp1", "sp1"),
    flash = c(0, 0)
  )
  site <- tibble(site = c("A", "B"))

  expect_error(check_keys(obs, site), "QC failure: sites in obs missing")
})

test_that("QC: validate_effort errors when NA exists in effort matrix", {
  op <- tibble(
    date = c("01/01/2020", "02/01/2020"),
    A = c(1, NA),
    B = c(1, 1)
  )

  expect_error(validate_effort(op), "effort table contains")
})

test_that("Effort: pivot_op_long and calc_trap_nights produce expected totals", {
  op <- tibble(
    date = c("01/01/2020", "02/01/2020", "03/01/2020"),
    A = c(1, 0, NA),
    B = c(1, 1, NA)
  )

  op_long <- pivot_op_long(op)
  expect_equal(nrow(op_long), 6)
  expect_equal(sort(unique(op_long$site)), c("A", "B"))

  trap_nights <- calc_trap_nights(op_long)
  expect_equal(trap_nights$trap_nights[trap_nights$site == "A"], 1)
  expect_equal(trap_nights$trap_nights[trap_nights$site == "B"], 2)
})

test_that("Effort: filter_obs_by_effort keeps only detections on active days", {
  op <- tibble(
    date = c("01/01/2020", "02/01/2020"),
    A = c(1, 1),
    B = c(0, 1)
  )
  op_long <- pivot_op_long(op)

  obs <- tibble(
    site = c("A", "B", "B"),
    datetime = c("01/01/2020 12:00:00", "01/01/2020 13:00:00", "02/01/2020 14:00:00"),
    species = c("sp1", "sp1", "sp1"),
    flash = c(0, 0, 0)
  )

  obs_filtered <- filter_obs_by_effort(obs, op_long)
  expect_equal(nrow(obs_filtered), 2)
  expect_equal(sort(unique(obs_filtered$site)), c("A", "B"))
})

test_that("Events: define_events clusters within threshold and is monotonic in threshold", {
  obs <- tibble(
    site = c("A", "A", "A", "A"),
    species = c("sp1", "sp1", "sp1", "sp1"),
    datetime = c(
      "01/01/2020 00:00:00",
      "01/01/2020 00:10:00",
      "01/01/2020 00:40:00",
      "01/01/2020 00:45:00"
    ),
    flash = c(0, 0, 1, 1)
  )

  ev_15 <- define_events(obs, threshold = 15, tz = "Australia/Hobart")
  ev_60 <- define_events(obs, threshold = 60, tz = "Australia/Hobart")

  n_ev_15 <- length(unique(ev_15$event_id))
  n_ev_60 <- length(unique(ev_60$event_id))

  expect_equal(n_ev_15, 2)
  expect_lte(n_ev_60, n_ev_15)
  expect_lte(n_ev_15, nrow(ev_15))

  colocated <- tibble(
    site = c("jc_co1", "jc_co1_s1"),
    species = c("pos", "pos"),
    datetime = c("01/01/2020 00:00:00", "01/01/2020 00:05:00"),
    flash = c(0, 0)
  )
  physical_events <- define_events(
    colocated,
    threshold = 15,
    tz = "Australia/Hobart"
  )
  expect_equal(
    sort(unique(physical_events$event_id)),
    c("jc_co1_pos_1", "jc_co1_s1_pos_1")
  )

  mapping <- read.csv(here(
    "docs", "goals", "009-analysis-site-vertical-slice",
    "judbury_analysis_site_mapping.csv"
  ))
  physical_events$analysis_site <- mapping$analysis_site_id[
    match(physical_events$site, mapping$physical_location_id)
  ]
  expect_equal(unique(physical_events$analysis_site), "jc_co1")
  expect_equal(length(unique(physical_events$event_id)), 2L)
})

test_that("Events: summarise_events counts distinct event_id per day", {
  obs <- tibble(
    site = c("A", "A", "A"),
    species = c("sp1", "sp1", "sp1"),
    datetime = c(
      "01/01/2020 00:00:00",
      "01/01/2020 00:10:00",
      "01/01/2020 01:00:00"
    ),
    flash = c(0, 0, 0)
  )

  obs_events <- define_events(obs, threshold = 15, tz = "Australia/Hobart")
  events_per_day <- summarise_events(obs_events)

  expect_equal(nrow(events_per_day), 1)
  expect_equal(events_per_day$events, 2)
})

test_that("Metrics: operational event rates use confirmed active days", {
  events_per_day <- tibble(
    site = c("A", "A", "B"),
    species = c("sp1", "sp2", "sp1"),
    date = as.Date(c("2020-01-01", "2020-01-01", "2020-01-01")),
    events = c(2, 0, 1)
  )
  trap_nights <- tibble(site = c("A", "B"), trap_nights = c(10, 5))

  rates <- compute_operational_event_detection_rate(
    events_per_day,
    trap_nights
  )

  expect_true(all(rates$events_per_100_active_days >= 0))
  expect_equal(
    rates$events_per_100_active_days[
      rates$physical_location_id == "A" & rates$species == "sp1"
    ],
    20
  )
  expect_equal(
    rates$events_per_100_active_days[
      rates$physical_location_id == "A" & rates$species == "sp2"
    ],
    0
  )
})

test_that("Metrics: coarse day-night proportions count each event once", {
  obs_events <- tibble(
    event_id = c("e1", "e1", "e2", "e3"),
    site = c("A", "A", "A", "A"),
    species = c("sp1", "sp1", "sp1", "sp1"),
    flash = c(0, 0, 1, 1),
    dt = as.POSIXct(
      c("2020-01-01 01:00:00", "2020-01-01 01:05:00", "2020-01-01 02:00:00", "2020-06-01 02:00:00"),
      tz = "Australia/Hobart"
    )
  )

  diel <- calc_diel(obs_events)
  expect_equal(sum(diel$event_count), 3)
  expect_equal(sum(diel$event_proportion), 1)
  expect_true(all(diel$event_proportion >= 0))
  expect_true(all(diel$event_proportion <= 1))
})

test_that("Metrics: flash classification does not turn missing evidence into day", {
  obs_events <- tibble(
    event_id = c("e1", "e2"),
    site = "A",
    species = "sp1",
    flash = c(NA, 1),
    dt = as.POSIXct(c("2020-01-01 12:00:00", "2020-01-01 23:00:00"), tz = "UTC")
  )

  diel <- calc_diel(obs_events, method = "flash")

  expect_equal(sum(diel$event_count), 1L)
  expect_equal(diel$period, "night")
  expect_equal(nrow(calc_diel(transform(obs_events, flash = NA), "flash")), 0L)
})

test_that("Accumulation: exact curve includes sampled zero-detection sites", {
  events_per_day <- tibble(
    site = c("A", "A"), species = c("sp1", "sp2"),
    date = as.Date(c("2020-01-01", "2020-01-01")), events = c(1, 1)
  )

  acc <- compute_species_accumulation(events_per_day, c("A", "B"))

  expect_equal(names(acc), c("sites", "richness", "se"))
  expect_equal(nrow(acc), 2)
  expect_equal(max(acc$richness), 2)
})

test_that("Effort: summarise_effort computes totals and proportions", {
  op_long <- tibble(
    trap_date = as.Date(c("2020-01-01", "2020-01-02", "2020-01-01", "2020-01-02")),
    site = c("A", "A", "B", "B"),
    on_off = c(1, 0, 1, 1)
  )

  summary <- summarise_effort(op_long)
  expect_equal(summary$trap_nights[summary$site == "A"], 1)
  expect_equal(summary$days_total[summary$site == "A"], 2)
  expect_equal(summary$prop_active[summary$site == "A"], 0.5)
})

test_that("Effort: validate_effort_censoring fails on inactive detections", {
  op_long <- tibble(
    trap_date = as.Date(c("2020-01-01", "2020-01-02")),
    site = c("A", "A"),
    on_off = c(1, 0)
  )
  obs_filtered <- tibble(
    site = c("A", "A"),
    trap_date = as.Date(c("2020-01-01", "2020-01-02"))
  )

  expect_error(
    validate_effort_censoring(obs_filtered, op_long),
    "detections found on inactive"
  )
})
