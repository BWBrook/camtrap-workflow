import::from("testthat", test_that, expect_equal, expect_false, expect_true)
import::from("targets", tar_make, tar_manifest)
import::from("here", here)
import::from("withr", local_envvar, with_dir)

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
