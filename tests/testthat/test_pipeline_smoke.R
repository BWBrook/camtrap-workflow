import::from("testthat", test_that, expect_equal, expect_false, expect_true)
import::from("targets", tar_make, tar_manifest, tar_read_raw)
import::from("here", here)
import::from("withr", local_envvar, with_dir)

test_that("pipeline smoke: input contract validation target builds", {
  with_dir(here(), {
    suppressWarnings(
      tar_make(
        names = "input_contract_validation",
        callr_function = NULL,
        script = here("_targets.R"),
        reporter = "silent"
      )
    )

    result <- tar_read_raw("input_contract_validation", store = here("_targets"))
    expect_true(!is.null(result))
  })
})

test_that("pipeline smoke: exploratory summary and report targets build", {
  with_dir(here(), {
    legacy_config_path <- tempfile("pipeline-smoke-legacy-", fileext = ".yml")
    legacy_config <- yaml::read_yaml(here("config.template_example.yml"))
    legacy_config$analysis_unit <- NULL
    yaml::write_yaml(legacy_config, legacy_config_path)
    local_envvar(c(
      CAMTRAP_CONFIG = legacy_config_path,
      CAMTRAP_EVIDENCE_CONTEXT = NA
    ))
    dictionary_paths <- c(
      here("data_dictionary.md"),
      here("data", "data_dictionary.csv")
    )
    dictionary_before <- unname(tools::md5sum(dictionary_paths))
    suppressWarnings(
      tar_make(
        names = c("species_summary_csv", "report_html"),
        callr_function = NULL,
        script = here("_targets.R"),
        reporter = "silent"
      )
    )

    species_summary_path <- tar_read_raw("species_summary_csv", store = here("_targets"))
    report_html_path <- tar_read_raw("report_html", store = here("_targets"))

    expect_true(file.exists(species_summary_path))
    expect_true(file.exists(report_html_path))
    rendered_report <- readChar(
      report_html_path,
      nchars = file.info(report_html_path)$size,
      useBytes = TRUE
    )
    expect_false(grepl(
      "id=\"selected-analysis-resolution\"",
      rendered_report,
      fixed = TRUE
    ))
    expect_equal(unname(tools::md5sum(dictionary_paths)), dictionary_before)
  })
})

test_that("data dictionary maintenance is absent from the scientific DAG", {
  with_dir(here(), {
    manifest <- tar_manifest(
      script = here("_targets.R"),
      fields = "name",
      callr_function = NULL
    )
    expect_false(any(manifest$name %in% c(
      "data_dictionary_md",
      "data_dictionary_csv"
    )))
  })
})

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

test_that("Goal 008 deployment evidence remains outside the analytical DAG", {
  with_dir(here(), {
    local_envvar(c(
      CAMTRAP_CONFIG = here("config.yml"),
      CAMTRAP_EVIDENCE_CONTEXT = NA
    ))
    manifest <- tar_manifest(
      script = here("_targets.R"),
      fields = c("name", "command"),
      callr_function = NULL
    )
    target_text <- paste(manifest$name, manifest$command, collapse = "\n")

    expect_false(any(grepl(
      "deployment_evidence|deployment_service|deployment_ledger|jc_services",
      manifest$name
    )))
    expect_false(grepl(
      "deployment_to_physical_location|service_event_digest",
      target_text
    ))

    suppressWarnings(
      tar_make(
        names = "config",
        callr_function = NULL,
        script = here("_targets.R"),
        reporter = "silent"
      )
    )
    config <- tar_read_raw("config", store = here("_targets"))
    expect_equal(
      config$deployment_evidence$profile_id,
      "judbury-deployment-evidence/1.0.0-proposed"
    )
  })
})

test_that("selected ecological targets are additive and post-event only", {
  with_dir(here(), {
    manifest <- tar_manifest(
      script = here("_targets.R"),
      fields = c("name", "command"),
      callr_function = NULL
    )
    selected_targets <- c(
      "selected_resolution_state",
      "selected_event_conservation_check",
      "selected_ecological_outputs",
      "selected_effort_coverage_csv",
      "selected_community_presence_csv",
      "selected_observed_richness_csv",
      "selected_jaccard_csv",
      "selected_resolution_status_json"
    )
    expect_true(all(selected_targets %in% manifest$name))

    selected_commands <- manifest$command[manifest$name %in% selected_targets]
    expect_false(any(grepl("events_per_day", selected_commands, fixed = TRUE)))
    reconciliation <- manifest$command[
      manifest$name == "selected_event_conservation_check"
    ]
    expect_true(grepl("obs_events", reconciliation, fixed = TRUE))
    expect_true(grepl("event_map", reconciliation, fixed = TRUE))
    expect_true(grepl("integrity_ok", reconciliation, fixed = TRUE))

    output_commands <- manifest$command[manifest$name %in% c(
      "selected_effort_coverage_csv", "selected_community_presence_csv",
      "selected_observed_richness_csv", "selected_jaccard_csv"
    )]
    expect_true(all(grepl("selected_ecological_outputs", output_commands,
                          fixed = TRUE)))
  })
})

test_that("selected evidence is wired into reports and manifest 1.3", {
  with_dir(here(), {
    manifest <- tar_manifest(
      script = here("_targets.R"),
      fields = c("name", "command"),
      callr_function = NULL
    )
    selected_outputs <- c(
      "selected_effort_coverage_csv",
      "selected_community_presence_csv",
      "selected_observed_richness_csv",
      "selected_jaccard_csv",
      "selected_resolution_status_json"
    )
    report_command <- manifest$command[manifest$name == "report_inputs_rds"]
    run_manifest_command <- manifest$command[manifest$name == "run_manifest"]

    expect_true(all(vapply(
      selected_outputs,
      grepl,
      logical(1),
      x = report_command,
      fixed = TRUE
    )))
    expect_true(all(vapply(
      c(
        "selected_resolution_state",
        "selected_event_conservation_check",
        selected_outputs
      ),
      grepl,
      logical(1),
      x = run_manifest_command,
      fixed = TRUE
    )))
    expect_true(grepl(
      "run_context$selected_resolution$artifacts",
      run_manifest_command,
      fixed = TRUE
    ))
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

test_that("named legacy targets retain their original target inputs", {
  with_dir(here(), {
    manifest <- tar_manifest(
      script = here("_targets.R"),
      fields = c("name", "command"),
      callr_function = NULL
    )
    expected <- list(
      op_long = c("op_raw"),
      obs_events = c("config", "obs_filtered"),
      events_per_day = c("obs_events"),
      event_spacing = c("obs_events"),
      event_threshold_sensitivity = c("config", "obs_filtered", "trap_nights"),
      occasion_length_sensitivity = c(
        "config", "detection_history", "events_per_day", "occupancy_species",
        "op_long"
      ),
      detection_history = c("config", "events_per_day", "op_long", "taxa_raw"),
      occupancy_species = c("config", "events_per_day"),
      occupancy_models = c(
        "detection_history", "occupancy_model_specs", "occupancy_site_covs",
        "occupancy_species"
      ),
      community_matrices = c("events_per_day", "site_raw"),
      alpha_diversity = c("community_abundance"),
      beta_diversity = c("community_abundance", "site_raw"),
      traits_alignment = c("community_abundance", "traits_clean"),
      functional_diversity = c("community_abundance", "traits_aligned"),
      trait_site_proportions = c(
        "community_abundance", "trait_association_traits", "traits_aligned"
      ),
      trait_env_associations = c(
        "site_raw", "trait_env_vars", "trait_site_proportions"
      ),
      rai_with_ci = c("events_per_day", "trap_nights"),
      prop_days_site = c("events_per_day", "trap_nights"),
      prop_days_species = c("events_per_day", "trap_nights"),
      diel_site = c("config", "obs_events"),
      diel_site_season = c("config", "obs_events"),
      diel_overall = c("config", "obs_events"),
      rarefaction_data = c("config", "events_per_day"),
      camtrapdp_export = c(
        "config", "obs_raw", "op_raw", "run_dir", "site_raw", "taxa_raw"
      ),
      site_map_plot = c("config", "run_dir", "site_raw")
    )
    target_names <- manifest$name
    observed <- lapply(names(expected), function(name) {
      command <- manifest$command[manifest$name == name]
      symbols <- unique(all.names(parse(text = command)))
      sort(setdiff(intersect(symbols, target_names), name))
    })
    names(observed) <- names(expected)

    expect_equal(observed, expected)
  })
})
