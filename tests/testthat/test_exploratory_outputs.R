import::from("testthat", test_that, expect_equal, expect_false, expect_true)
import::from("tibble", tibble)
import::from("here", here)

source(here("R", "exploratory_outputs.R"))

test_that("compute_species_summary returns expected current-workflow summaries", {
  obs_filtered <- tibble(
    index = 1:6,
    site = c("A", "A", "B", "A", "B", "B"),
    datetime = c(
      "01/01/2020 20:00:00",
      "02/01/2020 20:00:00",
      "03/01/2020 21:00:00",
      "01/01/2020 10:00:00",
      "02/01/2020 22:00:00",
      "04/01/2020 09:00:00"
    ),
    flash = c(1, 1, 1, 0, 1, 0),
    count = c(1, 1, 2, 4, 4, 4),
    species = c("sp1", "sp1", "sp1", "sp2", "sp2", "sp2"),
    imageid = c(101, 102, 103, 201, 202, 203)
  )

  obs_events <- tibble(
    site = c("A", "A", "B", "A", "B", "B"),
    species = c("sp1", "sp1", "sp1", "sp2", "sp2", "sp2"),
    event_id = c("A_sp1_1", "A_sp1_1", "B_sp1_1", "A_sp2_1", "B_sp2_1", "B_sp2_2"),
    flash = c(1, 1, 1, 0, 1, 0),
    dt = as.POSIXct(
      c(
        "2020-01-01 20:00:00",
        "2020-01-01 20:05:00",
        "2020-01-03 21:00:00",
        "2020-01-01 10:00:00",
        "2020-01-02 22:00:00",
        "2020-01-04 09:00:00"
      ),
      tz = "Australia/Hobart"
    )
  )

  events_per_day <- tibble(
    site = c("A", "B", "A", "B", "B"),
    species = c("sp1", "sp1", "sp2", "sp2", "sp2"),
    date = as.Date(c("2020-01-01", "2020-01-03", "2020-01-01", "2020-01-02", "2020-01-04")),
    events = c(1, 1, 1, 1, 1)
  )

  trap_nights <- tibble(
    site = c("A", "B", "C"),
    trap_nights = c(3, 4, 2)
  )

  summary_tbl <- compute_species_summary(
    obs_filtered,
    obs_events,
    events_per_day,
    trap_nights,
    total_sites = 3
  )

  sp1 <- summary_tbl[summary_tbl$species == "sp1", ]
  sp2 <- summary_tbl[summary_tbl$species == "sp2", ]

  expect_equal(sp1$n_sites_detected, 2)
  expect_equal(sp1$prop_sites_detected, 2 / 3)
  expect_equal(sp1$n_independent_events, 2)
  expect_equal(sp1$rai, 2 / 9)
  expect_equal(sp1$prop_active_days_detected, 2 / 9)
  expect_equal(sp1$prop_night_events, 1)
  expect_equal(sp1$mean_group_size, 4 / 3)
  expect_equal(sp1$max_group_size, 2)

  expect_equal(sp2$n_independent_events, 3)
  expect_equal(sp2$prop_night_events, 1 / 3)
  expect_equal(sp2$mean_group_size, 4)
  expect_equal(sp2$max_group_size, 4)
})

test_that("first-detection wait-time summaries count active days only", {
  op_long <- tibble(
    trap_date = as.Date(rep(c("2020-01-01", "2020-01-02", "2020-01-03", "2020-01-04"), 2)),
    site = rep(c("A", "B"), each = 4),
    on_off = c(1, 0, 1, 1, 1, 0, 1, 1)
  )

  events_per_day <- tibble(
    site = c("A", "B", "B"),
    species = c("sp1", "sp1", "sp2"),
    date = as.Date(c("2020-01-01", "2020-01-03", "2020-01-04")),
    events = c(1, 1, 1)
  )

  wait_tbl <- compute_first_detection_wait(op_long, events_per_day)
  species_tbl <- summarise_first_detection_wait(wait_tbl)

  expect_equal(wait_tbl$wait_days[wait_tbl$site == "A" & wait_tbl$species == "sp1"], 1)
  expect_equal(wait_tbl$wait_days[wait_tbl$site == "B" & wait_tbl$species == "sp1"], 2)
  expect_equal(wait_tbl$wait_days[wait_tbl$site == "B" & wait_tbl$species == "sp2"], 3)
  expect_false(any(wait_tbl$site == "A" & wait_tbl$species == "sp2"))

  sp1 <- species_tbl[species_tbl$species == "sp1", ]
  expect_equal(sp1$n_sites, 2)
  expect_equal(sp1$median_wait_days, 1.5)
  expect_equal(sp1$mean_wait_days, 1.5)
  expect_equal(sp1$min_wait_days, 1)
  expect_equal(sp1$max_wait_days, 2)
})

test_that("multi-species image summaries deduplicate species within images", {
  obs_filtered <- tibble(
    index = 1:7,
    site = c("A", "A", "A", "A", "B", "B", "B"),
    datetime = c(
      "01/01/2020 10:00:00",
      "01/01/2020 10:00:00",
      "01/01/2020 10:00:00",
      "02/01/2020 11:00:00",
      "03/01/2020 12:00:00",
      "03/01/2020 12:00:00",
      "03/01/2020 12:00:00"
    ),
    flash = c(0, 0, 0, 0, 0, 0, 0),
    count = c(1, 1, 1, 1, 1, 1, 1),
    species = c("sp1", "sp1", "sp2", "sp2", "sp1", "sp2", "sp3"),
    imageid = c(10, 10, 10, 11, 12, 12, 12)
  )

  image_tbl <- compute_multi_species_images(obs_filtered)
  pair_tbl <- compute_multi_species_pairs(image_tbl)

  img10 <- image_tbl[image_tbl$imageid == 10, ]
  img12 <- image_tbl[image_tbl$imageid == 12, ]

  expect_equal(img10$n_species, 2)
  expect_equal(img10$species_list, "sp1; sp2")
  expect_false(any(image_tbl$imageid == 11))
  expect_equal(img12$species_list, "sp1; sp2; sp3")

  expect_equal(pair_tbl$n_images[pair_tbl$species_1 == "sp1" & pair_tbl$species_2 == "sp2"], 2)
  expect_equal(nrow(pair_tbl), 3)
  expect_true(all(c("sp1", "sp2", "sp3") %in% unique(c(pair_tbl$species_1, pair_tbl$species_2))))
})
