import::from("testthat", test_that, expect_false, expect_true)
import::from("targets", tar_igraph)
import::from("here", here)
import::from("withr", with_dir)

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

test_that("protected targets stay outside the selected-resolution graph", {
  with_dir(here(), {
    graph <- tar_igraph(
      targets_only = TRUE,
      script = here("_targets.R"),
      callr_function = NULL
    )
    target_names <- igraph::V(graph)$name
    protected <- c(
      "rai_with_ci", "diel_site", "occupancy_models", "rarefaction_data",
      "functional_diversity", "trait_env_associations", "camtrapdp_export",
      "site_map_plot"
    )
    selected_targets <- grep("^selected_", target_names, value = TRUE)

    expect_true(all(protected %in% target_names))
    expect_true(length(selected_targets) > 0L)
    for (target in protected) {
      ancestors <- target_names[igraph::subcomponent(
        graph,
        target,
        mode = "in"
      )]
      expect_false(
        any(ancestors %in% selected_targets),
        info = target
      )
    }

    physical_carriers <- c(
      "occupancy_site_covs", "trait_env_associations", "camtrapdp_export",
      "site_map_plot"
    )
    for (target in physical_carriers) {
      ancestors <- target_names[igraph::subcomponent(
        graph,
        target,
        mode = "in"
      )]
      expect_true("site_raw" %in% ancestors, info = target)
    }
  })
})
