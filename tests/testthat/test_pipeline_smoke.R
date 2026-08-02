import::from(
  "testthat", test_that, expect_equal, expect_false, expect_identical,
  expect_setequal, expect_true
)
import::from("targets", tar_make, tar_manifest)
import::from("here", here)
import::from("withr", local_envvar, with_dir)

source(here("R", "alpha_diversity.R"))
source(here("R", "beta_diversity.R"))
source(here("R", "community_matrices.R"))

test_that("direct partial target calls cannot complete or advance latest", {
  with_dir(here(), {
    pointer <- here("outputs", "latest")
    pointer_before <- if (file.exists(pointer)) {
      readBin(pointer, "raw", n = file.info(pointer)$size)
    } else {
      raw()
    }
    local_envvar(c(
      CAMTRAP_CONFIG = here("config.template_example.yml"),
      CAMTRAP_EVIDENCE_CONTEXT = NA
    ))

    tar_make(
      names = "config",
      callr_function = NULL,
      script = here("_targets.R"),
      reporter = "silent"
    )

    pointer_after <- if (file.exists(pointer)) {
      readBin(pointer, "raw", n = file.info(pointer)$size)
    } else {
      raw()
    }
    partial_root <- here("outputs", "work", "template_example")
    completion <- if (dir.exists(partial_root)) {
      list.files(partial_root, pattern = "^COMPLETED[.]json$", recursive = TRUE)
    } else {
      character()
    }

    expect_equal(pointer_after, pointer_before)
    expect_equal(completion, character())
  })
})

test_that("report and methods state bounded selected-resolution claims", {
  report_text <- paste(readLines(here("analysis", "report.qmd")), collapse = " ")
  methods_text <- paste(readLines(here("analysis", "methods.qmd")), collapse = " ")
  claims <- c(
    "13 physical locations into nine analysis sites",
    "four coordinates are fixed synthetic midpoints",
    "physical covariates were not pooled",
    "confirmed active site-days",
    "observed and detection-limited",
    paste(
      "Jaccard turnover is descriptive and based on observed presences;",
      "it is not standardized for unequal confirmed effort, sampling completeness, or species detectability."
    )
  )

  expect_true(all(vapply(
    claims,
    function(claim) grepl(claim, report_text, fixed = TRUE),
    logical(1)
  )))
  expect_true(all(vapply(
    claims,
    function(claim) grepl(claim, methods_text, fixed = TRUE),
    logical(1)
  )))
  expect_true(grepl(
    "if \\(is_judbury_selected\\).*13 physical locations into nine analysis sites",
    report_text,
    perl = TRUE
  ))
  expect_true(grepl(
    "if \\(is_judbury_selected\\).*13 physical locations into nine analysis sites",
    methods_text,
    perl = TRUE
  ))
  for (text in list(report_text, methods_text)) {
    expect_true(grepl("judbury-analysis-site", text, fixed = TRUE))
    expect_true(grepl("1.0.0-proposed", text, fixed = TRUE))
    eligibility_gate <- regexpr(
      "if (isTRUE(selected_status$route_eligible))",
      text,
      fixed = TRUE
    )[[1L]]
    claim_positions <- vapply(claims, function(claim) {
      regexpr(claim, text, fixed = TRUE)[[1L]]
    }, integer(1))
    expect_true(eligibility_gate > 0L)
    expect_true(eligibility_gate < min(claim_positions))
  }
})

pipeline_selected_fixture <- function() {
  mapping <- read.csv(
    here(
      "docs", "goals", "009-analysis-site-vertical-slice",
      "judbury_analysis_site_mapping.csv"
    ),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  site_raw <- read.csv(
    here("data", "jc_site.csv"),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  physical_ids <- as.character(site_raw$site)
  analysis_ids <- sort(unique(mapping$analysis_site_id))
  physical_index <- match(mapping$physical_location_id, physical_ids)
  membership <- data.frame(
    physical_location_id = mapping$physical_location_id,
    analysis_unit_id = mapping$analysis_site_id,
    physical_latitude = site_raw$lat[physical_index],
    physical_longitude = site_raw$lon[physical_index],
    representative_latitude = mapping$representative_latitude,
    representative_longitude = mapping$representative_longitude,
    coordinate_basis = mapping$coordinate_basis,
    stringsAsFactors = FALSE
  )
  event_time <- as.POSIXct("2020-01-01 00:00:00", tz = "UTC") +
    seq_along(physical_ids) * 3600
  event_map <- data.frame(
    event_id = paste0("event-", seq_along(physical_ids)),
    physical_location_id = mapping$physical_location_id,
    analysis_unit_id = mapping$analysis_site_id,
    species = rep(c("sp1", "sp2", "sp3"), length.out = length(physical_ids)),
    event_time = event_time,
    deployment_id = paste0("deployment-", mapping$physical_location_id),
    stringsAsFactors = FALSE
  )
  obs_events <- data.frame(
    event_id = event_map$event_id,
    site = event_map$physical_location_id,
    species = event_map$species,
    dt = event_map$event_time,
    stringsAsFactors = FALSE
  )
  state <- list(
    integrity_ok = TRUE,
    route_eligible = TRUE,
    reasons = character(),
    membership = membership,
    operation = data.frame(
      analysis_unit_id = analysis_ids,
      date = as.Date("2020-01-01"),
      operation = 1L,
      deployment_states_json = "{}",
      stringsAsFactors = FALSE
    ),
    event_map = event_map,
    summary = list(
      status = "eligible",
      integrity_ok = TRUE,
      route_eligible = TRUE,
      resolution = "analysis_site",
      scheme_id = "judbury-analysis-site",
      scheme_version = "1.0.0-proposed",
      authority_reference = paste0(
        "goal009-judbury-analysis-site-mapping-sha256-",
        "6490d7f7021e5c727b9be1c7d6dfbf44ba50a1ef5b0396c66e1dd813a9c77083"
      ),
      membership_count = 13L,
      analysis_unit_count = 9L,
      physical_location_count = 13L,
      event_count = 13L,
      reasons = character()
    )
  )
  list(
    mapping = mapping,
    site_raw = site_raw,
    physical_ids = physical_ids,
    analysis_ids = analysis_ids,
    obs_events = obs_events,
    state = state
  )
}

test_that("selected outputs leave protected physical carriers unchanged", {
  fixture <- pipeline_selected_fixture()
  physical_before <- serialize(
    list(
      site = fixture$site_raw,
      events = fixture$obs_events,
      covariates = fixture$site_raw[c(
        "site", "lat", "lon", "elevation_m", "slope_d", "canopy_h_m",
        "ndvi", "nbr"
      )]
    ),
    NULL
  )

  outputs <- write_selected_ecological_outputs(
    fixture$state,
    fixture$obs_events,
    tempfile("pipeline-selected-")
  )
  physical_after <- serialize(
    list(
      site = fixture$site_raw,
      events = fixture$obs_events,
      covariates = fixture$site_raw[c(
        "site", "lat", "lon", "elevation_m", "slope_d", "canopy_h_m",
        "ndvi", "nbr"
      )]
    ),
    NULL
  )
  expect_identical(physical_after, physical_before)
  expect_equal(length(fixture$physical_ids), 13L)
  expect_equal(length(fixture$analysis_ids), 9L)

  expect_setequal(fixture$site_raw$site, fixture$physical_ids)
  expect_setequal(fixture$obs_events$site, fixture$physical_ids)
  expect_false("analysis_unit_id" %in% names(fixture$site_raw))
  expect_false("analysis_unit_id" %in% names(fixture$obs_events))

  selected_names <- c(
    "effort_coverage", "community_presence", "observed_richness", "jaccard"
  )
  expect_equal(names(outputs), c(selected_names, "status"))
  selected <- lapply(outputs[selected_names], read.csv, check.names = FALSE)
  selected_ids <- list(
    effort_coverage = selected$effort_coverage$analysis_unit_id,
    community_presence = selected$community_presence$analysis_unit_id,
    observed_richness = selected$observed_richness$analysis_unit_id,
    jaccard = c(
      selected$jaccard$analysis_unit_id_1,
      selected$jaccard$analysis_unit_id_2
    )
  )
  expect_true(all(vapply(
    selected_ids,
    setequal,
    logical(1),
    y = fixture$analysis_ids
  )))

  coordinate_fields <- c(
    "representative_latitude", "representative_longitude", "coordinate_basis"
  )
  expect_true(all(coordinate_fields %in% names(fixture$mapping)))
  expect_true(all(coordinate_fields %in% names(fixture$state$membership)))
  expect_false(any(coordinate_fields %in% names(fixture$site_raw)))
  synthetic <- grepl(
    "^synthetic_fixed_midpoint",
    fixture$state$membership$coordinate_basis
  )
  expect_equal(nrow(unique(fixture$state$membership[
    synthetic,
    c("representative_latitude", "representative_longitude")
  ])), 4L)
  expect_true(all(
    fixture$state$membership$representative_latitude[synthetic] !=
      fixture$state$membership$physical_latitude[synthetic] |
      fixture$state$membership$representative_longitude[synthetic] !=
        fixture$state$membership$physical_longitude[synthetic]
  ))
  expect_false(any(vapply(selected, function(value) {
    any(coordinate_fields %in% names(value))
  }, logical(1))))

  concurrent <- fixture$state
  concurrent$route_eligible <- FALSE
  concurrent$reasons <- "genuine_concurrent_member_deployments:jc_co1"
  concurrent$summary$status <- "ineligible"
  concurrent$summary$route_eligible <- FALSE
  concurrent$summary$reasons <- concurrent$reasons
  concurrent_outputs <- write_selected_ecological_outputs(
    concurrent,
    fixture$obs_events,
    tempfile("pipeline-concurrent-")
  )
  expect_true(all(vapply(
    concurrent_outputs[selected_names],
    is.null,
    logical(1)
  )))
  expect_true(file.exists(concurrent_outputs$status))
  concurrent_status <- jsonlite::read_json(
    concurrent_outputs$status,
    simplifyVector = FALSE
  )
  expect_false(isTRUE(concurrent_status$route_eligible))
  expect_equal(
    concurrent_status$reasons[[1L]],
    "genuine_concurrent_member_deployments:jc_co1"
  )
})

test_that("protected targets retain physical site carriers", {
  with_dir(here(), {
    manifest <- tar_manifest(
      script = here("_targets.R"),
      fields = c("name", "command"),
      callr_function = NULL
    )
    protected <- c(
      "rai_with_ci", "diel_site", "occupancy_models", "rarefaction_data",
      "functional_diversity", "trait_env_associations", "camtrapdp_export",
      "site_map_plot"
    )
    expect_true(all(protected %in% manifest$name))
    commands <- manifest$command[match(protected, manifest$name)]
    expect_false(any(grepl("selected_", commands, fixed = TRUE)))

    physical_carriers <- c(
      "occupancy_site_covs", "trait_env_associations", "camtrapdp_export",
      "site_map_plot"
    )
    carrier_commands <- manifest$command[
      match(physical_carriers, manifest$name)
    ]
    expect_true(all(grepl("site_raw", carrier_commands, fixed = TRUE)))
  })
})
