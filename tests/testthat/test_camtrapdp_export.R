import::from(
  "testthat", test_that, expect_equal, expect_true, expect_warning
)
import::from("tibble", tibble)
import::from("here", here)

source(here("R", "camtrapdp_export.R"))
source(here("R", "custom_funcs.R"))

sample_site <- tibble(
  site = c("A", "B"),
  lat = c(-42.0, -42.1),
  lon = c(147.3, 147.4),
  type = NA_character_,
  location = c("LocA", "LocB"),
  cover = NA_character_,
  vegclass = NA_character_,
  elevation_m = NA_real_,
  slope_d = NA_real_,
  canopy_h_m = NA_real_,
  ndvi = NA_real_,
  nbr = NA_real_,
  fire_flam = NA_character_,
  fire_sens = NA_character_
)

sample_op <- tibble(
  date = c("01/01/2020", "02/01/2020"),
  A = c(1, 1),
  B = c(0, 1)
)

sample_obs <- tibble(
  index = 1:2,
  site = c("A", "B"),
  datetime = c("01/01/2020 10:00:00", "02/01/2020 12:00:00"),
  flash = c(0, 0),
  count = c(1, 2),
  species = c("sp1", "sp2"),
  filename = c("img1.jpg", "img2.jpg"),
  age = c("adult", "juvenile"),
  sex = c("female", "male"),
  imageid = c(10, 11)
)

sample_taxa <- tibble(
  class = NA_character_,
  order = NA_character_,
  family = NA_character_,
  genus = c("GenusA", "GenusB"),
  species = c("speciesa", "speciesb"),
  common = c("CommonA", "CommonB"),
  short = c("sp1", "sp2"),
  diet = NA_character_,
  sec_diet = NA_character_,
  activity = NA_character_,
  habitat = NA_character_,
  status = NA_character_,
  body_size = NA_character_,
  sociality = NA_character_,
  mobility = NA_character_,
  reproductive = NA_character_,
  litter = NA_character_
)


test_that("CamtrapDP builders return complete required columns", {
  deployments <- build_camtrapdp_deployments(sample_site, sample_op, tz = "UTC")
  media_tbl <- build_camtrapdp_media(sample_obs, tz = "UTC")
  obs_tbl <- build_camtrapdp_observations(sample_obs, sample_taxa, tz = "UTC")

  expect_true(all(c(
    "deploymentID", "latitude", "longitude", "deploymentStart", "deploymentEnd"
  ) %in% names(deployments)))
  expect_true(all(!is.na(deployments$deploymentStart)))
  expect_true(all(!is.na(deployments$deploymentEnd)))
  expect_true(all(c(
    "mediaID", "deploymentID", "timestamp", "filePath", "filePublic",
    "fileMediatype"
  ) %in% names(media_tbl)))
  expect_true(all(!is.na(media_tbl$timestamp)))
  expect_true(all(c(
    "observationID", "deploymentID", "eventStart", "eventEnd",
    "observationLevel", "observationType"
  ) %in% names(obs_tbl)))
  expect_true(all(!is.na(obs_tbl$eventStart)))
})

test_that("parse_camtrapdp_datetimes audits DST-gap timestamps", {
  obs <- tibble(
    index = 1,
    site = "A",
    datetime = "04/10/2020 02:30:00",
    flash = 0,
    count = 1,
    species = "sp1",
    filename = "img1.jpg",
    age = "adult",
    sex = "female",
    imageid = 10
  )

  parsed <- parse_camtrapdp_datetimes(obs, tz = "Australia/Hobart")
  expect_equal(nrow(parsed$parsed), 0)
  expect_equal(nrow(parsed$dropped), 1)
  expect_equal(parsed$dropped$reason, "unparseable_datetime")
})

test_that("export_camtrapdp_package writes audit file for dropped observations", {
  bad_obs <- dplyr::bind_rows(
    sample_obs,
    tibble(
      index = 3,
      site = "A",
      datetime = "04/10/2020 02:30:00",
      flash = 0,
      count = 1,
      species = "sp1",
      filename = "img3.jpg",
      age = "adult",
      sex = "female",
      imageid = 12
    )
  )
  export_config <- list(
    name = "camtrapdp-test",
    title = "Camtrap DP test",
    description = "Test export",
    version = "0.0.0",
    license = "CC-BY-4.0"
  )
  tmp_dir <- tempfile()
  dir.create(tmp_dir)

  op_dst <- tibble(
    date = c("03/10/2020", "04/10/2020"),
    A = c(1, 1),
    B = c(1, 1)
  )

  expect_warning(
    export_camtrapdp_package(
      sample_site,
      op_dst,
      bad_obs,
      sample_taxa,
      export_config,
      tmp_dir,
      tz = "Australia/Hobart"
    ),
    "Dropping 1 observations with unparseable datetime"
  )

  audit_path <- file.path(tmp_dir, "camtrapdp_export", "dropped_observations.csv")
  expect_true(file.exists(audit_path))
  audit <- readr::read_csv(audit_path, show_col_types = FALSE)
  expect_true(nrow(audit) >= 1)
})
