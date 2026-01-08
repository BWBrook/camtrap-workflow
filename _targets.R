# _targets.R – data-import + QC scaffold (targets ≥ 1.3.0)

import::from("targets", tar_option_set, tar_target, tar_cue)
import::from("here", here)

import::here(
  read_jc_csv, check_keys, validate_effort,
  pivot_op_long, calc_trap_nights, filter_obs_by_effort,
  define_events, summarise_events,
  calc_rai, calc_prop_days, calc_diel,
  build_rarefaction, plot_rarefaction,
  .from = "R/custom_funcs.R"
)

import::here(
  summarise_effort,
  validate_effort_censoring,
  plot_effort_histogram,
  plot_effort_heatmap,
  .from = "R/effort_outputs.R"
)

import::here(
  input_schema_v0_1,
  validate_input_contract,
  .from = "R/qc_schema.R"
)

import::here(
  get_schema_version,
  .from = "R/schema_version.R"
)

import::here(
  read_config,
  .from = "R/config.R"
)

import::here(
  load_inputs,
  .from = "R/input_loader.R"
)

import::here(
  export_camtrapdp_package,
  .from = "R/camtrapdp_export.R"
)

import::here(
  write_run_manifest,
  .from = "R/run_manifest.R"
)

import::here(
  write_disabled_file,
  .from = "R/output_helpers.R"
)

import::here(
  compute_time_qc,
  plot_time_qc_backwards,
  .from = "R/time_qc.R"
)

import::here(
  compute_event_spacing,
  plot_event_spacing,
  validate_event_invariants,
  .from = "R/event_outputs.R"
)

import::here(
  calc_rai_with_ci,
  plot_rai_species,
  summarise_diel_overall,
  plot_diel_overall,
  .from = "R/descriptive_outputs.R"
)

import::here(
  plot_site_map,
  write_placeholder_plot,
  .from = "R/spatial_outputs.R"
)

import::here(
  compute_event_threshold_sens,
  plot_event_threshold_sens,
  compute_occasion_length_sens,
  plot_occasion_length_sens,
  .from = "R/sensitivity_outputs.R"
)

import::here(
  build_detection_history,
  .from = "R/detection_history.R"
)

import::here(
  validate_det_hist_alignment,
  .from = "R/detection_history_checks.R"
)

import::here(
  select_occupancy_species,
  select_occupancy_covariates,
  prepare_site_covariates,
  build_occupancy_model_specs,
  build_unmarked_frame,
  fit_occupancy_models,
  summarise_occupancy_model,
  occupancy_aic_df,
  plot_occupancy_predictions,
  .from = "R/occupancy_models.R"
)

import::here(
  build_community_matrices,
  .from = "R/community_matrices.R"
)

import::here(
  compute_alpha_diversity,
  plot_alpha_diversity,
  .from = "R/alpha_diversity.R"
)

import::here(
  compute_beta_diversity,
  plot_distance_decay,
  .from = "R/beta_diversity.R"
)

import::here(
  default_trait_columns,
  clean_traits_table,
  align_traits_to_species,
  .from = "R/traits.R"
)

import::here(
  compute_functional_diversity,
  plot_functional_diversity,
  .from = "R/functional_diversity.R"
)

import::here(
  compute_trait_site_proportions,
  compute_trait_env_associations,
  plot_trait_env_heatmap,
  .from = "R/trait_environment.R"
)

# Packages available to every target
tar_option_set(
  packages = c(
    "FD",
    "camtrapdp",
    "dplyr",
    "fs",
    "frictionless",
    "ggplot2",
    "here",
    "janitor",
    "jsonlite",
    "knitr",
    "lubridate",
    "readr",
    "purrr",
    "stringr",
    "tibble",
    "tidyr",
    "unmarked",
    "uuid",
    "vegan",
    "yaml"
  )
)

list(
  ## ── CONFIG ───────────────────────────────────────────────────────────
  tar_target(
    config_file,
    {
      config_path <- Sys.getenv("CAMTRAP_CONFIG", unset = "config.yml")
      if (fs::is_absolute_path(config_path)) {
        config_path
      } else {
        here(config_path)
      }
    },
    format = "file",
    cue = tar_cue(mode = "always")
  ),
  tar_target(
    config,
    read_config(config_file)
  ),
  tar_target(
    outputs_root,
    here(config$paths$outputs)
  ),
  tar_target(
    run_dir,
    file.path(outputs_root, "runs", config$run_id)
  ),
  ## ── DATA DICTIONARY SYNC ─────────────────────────────────────────────
  tar_target(
    data_dictionary_md,
    here("data_dictionary.md"),
    format = "file"
  ),
  tar_target(
    data_dictionary_csv,
    {
      source(here("scripts/update_data_dictionary.R"))
      here("data", "data_dictionary.csv")
    },
    format = "file"
  ),
  ## ── RAW IMPORTS ──────────────────────────────────────────────────────
  tar_target(
    raw_inputs,
    load_inputs(config)
  ),
  tar_target(
    site_raw,
    raw_inputs$site
  ),
  tar_target(
    op_raw,
    raw_inputs$op
  ),
  tar_target(
    obs_raw,
    raw_inputs$obs
  ),
  tar_target(
    taxa_raw,
    raw_inputs$taxa
  ),
  tar_target(schema_version, get_schema_version(config$schema_version_path)),

  ## ── QC CHECKS (pipeline halts on error) ──────────────────────────────
  tar_target(
    input_contract_validation,
    validate_input_contract(
      site_raw,
      op_raw,
      obs_raw,
      taxa_raw,
      tz = config$timezone,
      fixed_offset_hours = config$timezone_fixed_offset_hours
    ),
    cue = tar_cue(mode = "always")
  ),
  tar_target(key_check,
    check_keys(obs_raw, site_raw),
    cue = tar_cue(mode = "always")
  ),
  tar_target(effort_validation,
    validate_effort(op_raw),
    cue = tar_cue(mode = "always")
  ),
  ## ── TIME DIAGNOSTICS ────────────────────────────────────────────────
  tar_target(
    time_qc,
    compute_time_qc(
      obs_raw,
      tz = config$timezone,
      fixed_offset_hours = config$timezone_fixed_offset_hours,
      backward_threshold_hours = config$time_qc$backward_jump_threshold_hours
    )
  ),
  tar_target(
    time_qc_summary_csv,
    {
      out_path <- file.path(run_dir, "tables", "time_qc_summary.csv")
      dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)
      readr::write_csv(time_qc$summary, out_path)
      out_path
    },
    format = "file"
  ),
  tar_target(
    time_qc_flags_csv,
    {
      out_path <- file.path(run_dir, "tables", "time_qc_flags.csv")
      dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)
      readr::write_csv(time_qc$flags, out_path)
      out_path
    },
    format = "file"
  ),
  tar_target(
    time_qc_backwards_plot,
    plot_time_qc_backwards(
      time_qc$summary,
      file.path(run_dir, "figures", "time_qc_backward_jumps.png")
    ),
    format = "file"
  ),
  ## ── EFFORT STANDARDISATION ───────────────────────────────────────────
  tar_target(op_long,      pivot_op_long(op_raw)),
  tar_target(trap_nights,  calc_trap_nights(op_long)),
  tar_target(obs_filtered, filter_obs_by_effort(obs_raw, op_long)),
  tar_target(
    effort_censoring_check,
    validate_effort_censoring(obs_filtered, op_long),
    cue = tar_cue(mode = "always")
  ),
  tar_target(
    effort_summary,
    summarise_effort(op_long)
  ),
  tar_target(
    effort_summary_csv,
    {
      out_path <- file.path(run_dir, "tables", "effort_summary.csv")
      dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)
      readr::write_csv(effort_summary, out_path)
      out_path
    },
    format = "file"
  ),
  tar_target(
    effort_histogram_plot,
    plot_effort_histogram(
      effort_summary,
      file.path(run_dir, "figures", "effort_histogram.png")
    ),
    format = "file"
  ),
  tar_target(
    effort_heatmap_plot,
    plot_effort_heatmap(
      op_long,
      file.path(run_dir, "figures", "effort_heatmap.png")
    ),
    format = "file"
  ),
  tar_target(
    site_map_plot,
    {
      out_path <- file.path(run_dir, "figures", "site_map.png")
      if (isTRUE(config$spatial_map$enable)) {
        plot_site_map(
          site_raw,
          out_path,
          surface_var = config$spatial_map$surface_var,
          resolution = config$spatial_map$resolution,
          buffer_deg = config$spatial_map$buffer_deg
        )
      } else {
        write_placeholder_plot(out_path, "Site map disabled by config.")
      }
      out_path
    },
    format = "file"
  ),
  ## ── INDEPENDENT-EVENT FILTERING ───────────────────────────────────────────────
  tar_target(
    obs_events,
    define_events(
      obs_filtered,
      threshold = config$event_threshold_minutes,
      tz = config$timezone,
      fixed_offset_hours = config$timezone_fixed_offset_hours
    )
  ),
  tar_target(
    event_invariants_check,
    validate_event_invariants(obs_events, obs_filtered),
    cue = tar_cue(mode = "always")
  ),
  tar_target(
    events_per_day,
    summarise_events(obs_events)
  ),
  tar_target(
    events_per_day_csv,
    {
      out_path <- file.path(run_dir, "tables", "events_per_day.csv")
      dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)
      readr::write_csv(events_per_day, out_path)
      out_path
    },
    format = "file"
  ),
  tar_target(
    event_spacing,
    compute_event_spacing(obs_events)
  ),
  tar_target(
    event_spacing_csv,
    {
      out_path <- file.path(run_dir, "tables", "event_spacing.csv")
      dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)
      readr::write_csv(event_spacing, out_path)
      out_path
    },
    format = "file"
  ),
  tar_target(
    event_spacing_plot,
    plot_event_spacing(
      event_spacing,
      file.path(run_dir, "figures", "event_spacing.png")
    ),
    format = "file"
  ),
  tar_target(
    event_threshold_sensitivity,
    compute_event_threshold_sens(
      obs_filtered,
      trap_nights,
      thresholds = config$sensitivity$event_threshold_minutes,
      tz = config$timezone
    )
  ),
  tar_target(
    event_threshold_sensitivity_csv,
    {
      out_path <- file.path(run_dir, "tables", "event_threshold_sensitivity.csv")
      dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)
      readr::write_csv(event_threshold_sensitivity, out_path)
      out_path
    },
    format = "file"
  ),
  tar_target(
    event_threshold_sensitivity_plot,
    plot_event_threshold_sens(
      event_threshold_sensitivity,
      file.path(run_dir, "figures", "event_threshold_sensitivity.png")
    ),
    format = "file"
  ),
  tar_target(
    occasion_length_sensitivity,
    compute_occasion_length_sens(
      op_long,
      events_per_day,
      species_list = occupancy_species,
      occasion_lengths = config$sensitivity$occasion_length_days,
      start_date = config$detection_history$start_date
    )
  ),
  tar_target(
    occasion_length_sensitivity_csv,
    {
      out_path <- file.path(run_dir, "tables", "occasion_length_sensitivity.csv")
      dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)
      readr::write_csv(occasion_length_sensitivity, out_path)
      out_path
    },
    format = "file"
  ),
  tar_target(
    occasion_length_sensitivity_plot,
    plot_occasion_length_sens(
      occasion_length_sensitivity,
      file.path(run_dir, "figures", "occasion_length_sensitivity.png")
    ),
    format = "file"
  ),
  ## ── DETECTION HISTORY (OCCUPANCY PREP) ───────────────────────────────
  tar_target(
    detection_history,
    build_detection_history(
      op_long,
      events_per_day,
      species_list = taxa_raw$short,
      occasion_length_days = config$detection_history$occasion_length_days,
      start_date = config$detection_history$start_date
    )
  ),
  tar_target(
    detection_history_alignment_check,
    validate_det_hist_alignment(detection_history),
    cue = tar_cue(mode = "always")
  ),
  tar_target(
    detection_history_csv,
    {
      out_path <- file.path(run_dir, "tables", "detection_history.csv")
      dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)
      readr::write_csv(detection_history, out_path)
      out_path
    },
    format = "file"
  ),
  ## ── OCCUPANCY MODELS (SINGLE-SEASON) ─────────────────────────────────
  tar_target(
    occupancy_species,
    select_occupancy_species(
      events_per_day,
      species_override = config$occupancy$species,
      top_n = config$occupancy$top_n
    )
  ),
  tar_target(
    occupancy_covariates,
    select_occupancy_covariates(site_raw, config$occupancy$covariates)
  ),
  tar_target(
    occupancy_site_covs,
    prepare_site_covariates(site_raw, occupancy_covariates)
  ),
  tar_target(
    occupancy_model_specs,
    build_occupancy_model_specs(occupancy_covariates)
  ),
  tar_target(
    occupancy_models,
    lapply(occupancy_species, function(sp) {
      umf <- build_unmarked_frame(detection_history, occupancy_site_covs, sp)
      models <- fit_occupancy_models(umf, occupancy_model_specs)

      list(
        species = sp,
        umf = umf,
        models = models
      )
    })
  ),
  tar_target(
    occupancy_aic_tables,
    lapply(occupancy_models, function(item) {
      tbl <- occupancy_aic_df(item$models)
      tbl$species <- item$species
      tbl
    })
  ),
  tar_target(
    occupancy_aic_tbl,
    dplyr::bind_rows(occupancy_aic_tables)
  ),
  tar_target(
    occupancy_summary,
    lapply(occupancy_models, function(item) {
      aic_tbl <- occupancy_aic_df(item$models)
      best_name <- aic_tbl$model[which.min(aic_tbl$AIC)][1]
      best_model <- item$models[[best_name]]
      estimates <- summarise_occupancy_model(best_model)

      data.frame(
        species = item$species,
        best_model = best_name,
        psi = estimates$psi["est"],
        psi_lower = estimates$psi["lower"],
        psi_upper = estimates$psi["upper"],
        p = estimates$p["est"],
        p_lower = estimates$p["lower"],
        p_upper = estimates$p["upper"]
      )
    })
  ),
  tar_target(
    occupancy_summary_table,
    dplyr::bind_rows(occupancy_summary)
  ),
  tar_target(
    occupancy_predictions,
    lapply(occupancy_models, function(item) {
      aic_tbl <- occupancy_aic_df(item$models)
      best_name <- aic_tbl$model[which.min(aic_tbl$AIC)][1]
      best_model <- item$models[[best_name]]

      preds <- predict(best_model, type = "state")
      pred_sites <- rownames(best_model@data@y)
      site_names <- rownames(best_model@data@siteCovs)
      if (!is.null(site_names) && length(site_names) == nrow(preds)) {
        pred_sites <- site_names
      }
      data.frame(
        site = pred_sites,
        species = item$species,
        psi = preds$Predicted,
        psi_lower = ifelse(is.na(preds$lower), preds$Predicted, preds$lower),
        psi_upper = ifelse(is.na(preds$upper), preds$Predicted, preds$upper)
      )
    })
  ),
  tar_target(
    occupancy_predictions_table,
    dplyr::bind_rows(occupancy_predictions)
  ),
  tar_target(
    occupancy_model_rds,
    {
      out_dir <- file.path(run_dir, "models")
      dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

      paths <- lapply(occupancy_models, function(item) {
        aic_tbl <- occupancy_aic_df(item$models)
        best_name <- aic_tbl$model[which.min(aic_tbl$AIC)][1]
        best_model <- item$models[[best_name]]

        out_path <- file.path(out_dir, paste0("occu_", item$species, "_", best_name, ".rds"))
        saveRDS(best_model, out_path)
        out_path
      })
      unlist(paths, use.names = FALSE)
    },
    format = "file"
  ),
  tar_target(
    occupancy_prediction_plots,
    {
      out_dir <- file.path(run_dir, "figures")
      dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

      paths <- lapply(occupancy_species, function(sp) {
        out_path <- file.path(out_dir, paste0("occupancy_pred_", sp, ".png"))
        plot_occupancy_predictions(occupancy_predictions_table, sp, out_path)
      })
      unlist(paths, use.names = FALSE)
    },
    format = "file"
  ),
  tar_target(
    occupancy_summary_csv,
    {
      out_path <- file.path(run_dir, "tables", "occupancy_summary.csv")
      dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)
      readr::write_csv(occupancy_summary_table, out_path)
      out_path
    },
    format = "file"
  ),
  tar_target(
    occupancy_aic_csv,
    {
      out_path <- file.path(run_dir, "tables", "occupancy_aic.csv")
      dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)
      readr::write_csv(occupancy_aic_tbl, out_path)
      out_path
    },
    format = "file"
  ),
  tar_target(
    occupancy_predictions_csv,
    {
      out_path <- file.path(run_dir, "tables", "occupancy_predictions.csv")
      dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)
      readr::write_csv(occupancy_predictions_table, out_path)
      out_path
    },
    format = "file"
  ),
  ## ── DESCRIPTIVE SUMMARIES ──────────────────────────────────────────────
  tar_target(
    community_matrices,
    build_community_matrices(events_per_day, sites = site_raw$site)
  ),
  tar_target(
    community_abundance,
    community_matrices$abundance
  ),
  tar_target(
    community_presence,
    community_matrices$presence
  ),
  tar_target(
    community_abundance_csv,
    {
      out_path <- file.path(run_dir, "tables", "community_abundance.csv")
      dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)
      readr::write_csv(community_abundance, out_path)
      out_path
    },
    format = "file"
  ),
  tar_target(
    community_presence_csv,
    {
      out_path <- file.path(run_dir, "tables", "community_presence.csv")
      dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)
      readr::write_csv(community_presence, out_path)
      out_path
    },
    format = "file"
  ),
  tar_target(
    alpha_diversity,
    compute_alpha_diversity(community_abundance)
  ),
  tar_target(
    alpha_diversity_csv,
    {
      out_path <- file.path(run_dir, "tables", "alpha_diversity.csv")
      dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)
      readr::write_csv(alpha_diversity, out_path)
      out_path
    },
    format = "file"
  ),
  tar_target(
    alpha_diversity_plot,
    plot_alpha_diversity(
      alpha_diversity,
      file.path(run_dir, "figures", "alpha_diversity.png")
    ),
    format = "file"
  ),
  tar_target(
    beta_diversity,
    compute_beta_diversity(community_abundance, site_raw)
  ),
  tar_target(
    beta_diversity_csv,
    {
      out_path <- file.path(run_dir, "tables", "beta_diversity.csv")
      dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)
      readr::write_csv(beta_diversity, out_path)
      out_path
    },
    format = "file"
  ),
  tar_target(
    beta_diversity_plot,
    plot_distance_decay(
      beta_diversity,
      file.path(run_dir, "figures", "beta_diversity_distance_decay.png")
    ),
    format = "file"
  ),
  tar_target(
    trait_columns,
    {
      if (is.null(config$traits$columns)) {
        default_trait_columns(taxa_raw)
      } else {
        config$traits$columns
      }
    }
  ),
  tar_target(
    trait_species_column,
    {
      if (is.null(config$traits$species_column)) {
        "short"
      } else {
        config$traits$species_column
      }
    }
  ),
  tar_target(
    traits_clean,
    clean_traits_table(taxa_raw, trait_columns, species_column = trait_species_column)
  ),
  tar_target(
    traits_alignment,
    align_traits_to_species(traits_clean, setdiff(names(community_abundance), "site"))
  ),
  tar_target(
    traits_aligned,
    traits_alignment$aligned
  ),
  tar_target(
    traits_missing,
    traits_alignment$missing
  ),
  tar_target(
    traits_clean_csv,
    {
      out_path <- file.path(run_dir, "tables", "traits_clean.csv")
      dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)
      readr::write_csv(traits_clean, out_path)
      out_path
    },
    format = "file"
  ),
  tar_target(
    traits_aligned_csv,
    {
      out_path <- file.path(run_dir, "tables", "traits_aligned.csv")
      dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)
      readr::write_csv(traits_aligned, out_path)
      out_path
    },
    format = "file"
  ),
  tar_target(
    traits_missing_csv,
    {
      out_path <- file.path(run_dir, "tables", "traits_missing.csv")
      dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)
      readr::write_csv(traits_missing, out_path)
      out_path
    },
    format = "file"
  ),
  tar_target(
    functional_diversity,
    compute_functional_diversity(community_abundance, traits_aligned)
  ),
  tar_target(
    functional_diversity_table,
    functional_diversity$metrics
  ),
  tar_target(
    functional_diversity_dropped,
    functional_diversity$dropped_species
  ),
  tar_target(
    functional_diversity_csv,
    {
      out_path <- file.path(run_dir, "tables", "functional_diversity.csv")
      dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)
      readr::write_csv(functional_diversity_table, out_path)
      out_path
    },
    format = "file"
  ),
  tar_target(
    functional_diversity_dropped_csv,
    {
      out_path <- file.path(run_dir, "tables", "functional_diversity_dropped_species.csv")
      dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)
      readr::write_csv(functional_diversity_dropped, out_path)
      out_path
    },
    format = "file"
  ),
  tar_target(
    functional_diversity_plot,
    plot_functional_diversity(
      functional_diversity_table,
      file.path(run_dir, "figures", "functional_diversity.png")
    ),
    format = "file"
  ),
  tar_target(
    trait_association_traits,
    {
      if (is.null(config$traits$association_traits)) {
        trait_columns
      } else {
        config$traits$association_traits
      }
    }
  ),
  tar_target(
    trait_env_vars,
    {
      if (is.null(config$traits$environment_vars)) {
        c("elevation_m", "canopy_h_m", "ndvi")
      } else {
        config$traits$environment_vars
      }
    }
  ),
  tar_target(
    trait_site_proportions,
    compute_trait_site_proportions(
      community_abundance,
      traits_aligned,
      traits_to_use = trait_association_traits
    )
  ),
  tar_target(
    trait_env_associations,
    compute_trait_env_associations(
      trait_site_proportions,
      site_raw,
      env_vars = trait_env_vars
    )
  ),
  tar_target(
    trait_site_proportions_csv,
    {
      out_path <- file.path(run_dir, "tables", "trait_site_proportions.csv")
      dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)
      readr::write_csv(trait_site_proportions, out_path)
      out_path
    },
    format = "file"
  ),
  tar_target(
    trait_env_associations_csv,
    {
      out_path <- file.path(run_dir, "tables", "trait_env_associations.csv")
      dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)
      readr::write_csv(trait_env_associations, out_path)
      out_path
    },
    format = "file"
  ),
  tar_target(
    trait_env_plot,
    plot_trait_env_heatmap(
      trait_env_associations,
      file.path(run_dir, "figures", "trait_env_associations.png")
    ),
    format = "file"
  ),
  tar_target(
    rai_with_ci,
    calc_rai_with_ci(events_per_day, trap_nights)
  ),
  tar_target(
    rai_species,
    rai_with_ci$pooled
  ),
  tar_target(
    rai_site_species,
    rai_with_ci$site
  ),
  tar_target(
    prop_days_site,
    calc_prop_days(events_per_day, trap_nights)$site
  ),
  tar_target(
    prop_days_species,
    calc_prop_days(events_per_day, trap_nights)$pooled
  ),
  tar_target(
    diel_site,
    calc_diel(
      obs_events,
      by_season = FALSE,
      method = config$diel$method,
      day_start_hour = config$diel$day_start_hour,
      day_end_hour = config$diel$day_end_hour
    )
  ),
  tar_target(
    diel_site_season,
    calc_diel(
      obs_events,
      by_season = TRUE,
      method = config$diel$method,
      day_start_hour = config$diel$day_start_hour,
      day_end_hour = config$diel$day_end_hour
    )
  ),
  tar_target(
    diel_overall,
    summarise_diel_overall(
      obs_events,
      method = config$diel$method,
      day_start_hour = config$diel$day_start_hour,
      day_end_hour = config$diel$day_end_hour
    )
  ),
  tar_target(
    rai_site_species_csv,
    {
      out_path <- file.path(run_dir, "tables", "rai_site_species.csv")
      dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)
      readr::write_csv(rai_site_species, out_path)
      out_path
    },
    format = "file"
  ),
  tar_target(
    rai_species_csv,
    {
      out_path <- file.path(run_dir, "tables", "rai_species.csv")
      dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)
      readr::write_csv(rai_species, out_path)
      out_path
    },
    format = "file"
  ),
  tar_target(
    rai_species_plot,
    plot_rai_species(
      rai_species,
      file.path(run_dir, "figures", "rai_species.png")
    ),
    format = "file"
  ),
  tar_target(
    diel_site_csv,
    {
      out_path <- file.path(run_dir, "tables", "diel_site.csv")
      dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)
      readr::write_csv(diel_site, out_path)
      out_path
    },
    format = "file"
  ),
  tar_target(
    diel_site_season_csv,
    {
      out_path <- file.path(run_dir, "tables", "diel_site_season.csv")
      dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)
      readr::write_csv(diel_site_season, out_path)
      out_path
    },
    format = "file"
  ),
  tar_target(
    diel_overall_csv,
    {
      out_path <- file.path(run_dir, "tables", "diel_overall.csv")
      dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)
      readr::write_csv(diel_overall, out_path)
      out_path
    },
    format = "file"
  ),
  tar_target(
    diel_overall_plot,
    plot_diel_overall(
      diel_overall,
      file.path(run_dir, "figures", "diel_overall.png")
    ),
    format = "file"
  ),
  tar_target(
    rarefaction_data,
    {
      if (isTRUE(config$analysis$rarefaction)) {
        build_rarefaction(events_per_day, 100)
      } else {
        tibble::tibble()
      }
    }
  ),
  tar_target(
    rarefaction_table_csv,
    {
      out_path <- file.path(run_dir, "tables", "rarefaction.csv")
      dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)

      if (isTRUE(config$analysis$rarefaction)) {
        readr::write_csv(rarefaction_data, out_path)
      } else {
        write_disabled_file(out_path, "Rarefaction disabled by config.")
      }

      out_path
    },
    format = "file"
  ),
  tar_target(
    rarefaction_plot,
    {
      out_path <- file.path(run_dir, "figures", "rarefaction.png")

      if (isTRUE(config$analysis$rarefaction)) {
        plot_rarefaction(rarefaction_data, out_path)
      } else {
        write_disabled_file(out_path, "Rarefaction disabled by config.")
      }
    },
    format = "file"
  ),
  tar_target(
    session_info,
    {
      out_path <- file.path(run_dir, "session_info.txt")
      dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)
      writeLines(capture.output(sessionInfo()), out_path)
      out_path
    },
    format = "file"
  ),
  tar_target(
    report_inputs_rds,
    {
      out_path <- file.path(run_dir, "report", "report_inputs.rds")
      dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)

      if (isTRUE(config$analysis$report)) {
        report_inputs <- list(
          n_sites = nrow(site_raw),
          n_obs_raw = nrow(obs_raw),
          n_obs_filtered = nrow(obs_filtered),
          trap_nights = trap_nights,
          effort_summary = effort_summary,
          time_qc_summary = time_qc$summary,
          time_qc_flags = time_qc$flags,
          events_per_day = events_per_day,
          event_spacing = event_spacing,
          event_threshold_sensitivity = event_threshold_sensitivity,
          occasion_length_sensitivity = occasion_length_sensitivity,
          rai_species = rai_species,
          diel_site = diel_site,
          diel_overall = diel_overall,
          rarefaction_data = rarefaction_data,
          community_abundance = community_abundance,
          community_presence = community_presence,
          alpha_diversity = alpha_diversity,
          beta_diversity = beta_diversity,
          traits_missing = traits_missing,
          functional_diversity = functional_diversity_table,
          trait_env_associations = trait_env_associations,
          occupancy_summary = occupancy_summary_table,
          occupancy_aic = occupancy_aic_tbl,
          occupancy_species = occupancy_species,
          occupancy_predictions = occupancy_predictions_table,
          schema_version = schema_version,
          params = config
        )

        saveRDS(report_inputs, out_path)
      } else {
        saveRDS(list(message = "Report disabled by config."), out_path)
      }

      out_path
    },
    format = "file"
  ),
  tar_target(
    report_html,
    {
      out_dir <- file.path(run_dir, "report")
      out_path <- file.path(out_dir, "report.html")
      dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

      if (isTRUE(config$analysis$report)) {
        system2(
          "quarto",
          c(
            "render",
            here("analysis", "report.qmd"),
            "--to",
            "html",
            "--output-dir",
            out_dir,
            "-P",
            paste0("inputs_path:", report_inputs_rds),
            "-P",
            paste0("rarefaction_path:", rarefaction_plot),
            "-P",
            paste0("effort_histogram_path:", effort_histogram_plot),
            "-P",
            paste0("effort_heatmap_path:", effort_heatmap_plot),
            "-P",
            paste0("time_qc_plot_path:", time_qc_backwards_plot),
            "-P",
            paste0("event_spacing_path:", event_spacing_plot),
            "-P",
            paste0("event_threshold_sensitivity_path:", event_threshold_sensitivity_plot),
            "-P",
            paste0("rai_species_path:", rai_species_plot),
            "-P",
            paste0("diel_overall_path:", diel_overall_plot),
            "-P",
            paste0("alpha_diversity_path:", alpha_diversity_plot),
            "-P",
            paste0("beta_diversity_path:", beta_diversity_plot),
            "-P",
            paste0("functional_diversity_path:", functional_diversity_plot),
            "-P",
            paste0("trait_env_path:", trait_env_plot),
            "-P",
            paste0("site_map_path:", site_map_plot),
            "-P",
            paste0("run_dir:", run_dir)
          )
        )
      } else {
        write_disabled_file(out_path, "Report disabled by config.")
      }

      out_path
    },
    format = "file"
  ),
  tar_target(
    report_pdf,
    {
      out_path <- file.path(run_dir, "report", "report.pdf")

      if (isTRUE(config$analysis$report)) {
        out_dir <- file.path(run_dir, "report")
        dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

        status <- system2(
          "quarto",
          c(
            "render",
            here("analysis", "report.qmd"),
            "--to",
            "pdf",
            "--output-dir",
            out_dir,
            "-P",
            paste0("inputs_path:", report_inputs_rds),
            "-P",
            paste0("rarefaction_path:", rarefaction_plot),
            "-P",
            paste0("effort_histogram_path:", effort_histogram_plot),
            "-P",
            paste0("effort_heatmap_path:", effort_heatmap_plot),
            "-P",
            paste0("time_qc_plot_path:", time_qc_backwards_plot),
            "-P",
            paste0("event_spacing_path:", event_spacing_plot),
            "-P",
            paste0("event_threshold_sensitivity_path:", event_threshold_sensitivity_plot),
            "-P",
            paste0("rai_species_path:", rai_species_plot),
            "-P",
            paste0("diel_overall_path:", diel_overall_plot),
            "-P",
            paste0("alpha_diversity_path:", alpha_diversity_plot),
            "-P",
            paste0("beta_diversity_path:", beta_diversity_plot),
            "-P",
            paste0("functional_diversity_path:", functional_diversity_plot),
            "-P",
            paste0("trait_env_path:", trait_env_plot),
            "-P",
            paste0("site_map_path:", site_map_plot),
            "-P",
            paste0("run_dir:", run_dir)
          )
        )

        if (!is.null(status) && status != 0) {
          stop("Quarto PDF render failed. Ensure LaTeX/TinyTeX is installed.")
        }
      } else {
        write_disabled_file(out_path, "Report disabled by config.")
      }

      out_path
    },
    format = "file"
  ),
  tar_target(
    methods_html,
    {
      out_dir <- file.path(run_dir, "manuscript")
      out_path <- file.path(out_dir, "methods.html")
      dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

      if (isTRUE(config$analysis$report)) {
        system2(
          "quarto",
          c(
            "render",
            here("analysis", "methods.qmd"),
            "--to",
            "html",
            "--output-dir",
            out_dir,
            "-P",
            paste0("inputs_path:", report_inputs_rds),
            "-P",
            paste0("run_dir:", run_dir)
          )
        )
      } else {
        write_disabled_file(out_path, "Manuscript disabled by config.")
      }

      out_path
    },
    format = "file"
  ),
  tar_target(
    methods_pdf,
    {
      out_dir <- file.path(run_dir, "manuscript")
      out_path <- file.path(out_dir, "methods.pdf")
      dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

      if (isTRUE(config$analysis$report)) {
        system2(
          "quarto",
          c(
            "render",
            here("analysis", "methods.qmd"),
            "--to",
            "pdf",
            "--output-dir",
            out_dir,
            "-P",
            paste0("inputs_path:", report_inputs_rds),
            "-P",
            paste0("run_dir:", run_dir)
          )
        )
      } else {
        write_disabled_file(out_path, "Manuscript disabled by config.")
      }

      out_path
    },
    format = "file"
  ),
  tar_target(
    camtrapdp_export,
    {
      if (isTRUE(config$camtrapdp_export$enable)) {
        export_camtrapdp_package(
          site_raw,
          op_raw,
          obs_raw,
          taxa_raw,
          export_config = config$camtrapdp_export,
          run_dir = run_dir,
          tz = config$timezone,
          fixed_offset_hours = config$timezone_fixed_offset_hours
        )
      } else {
        write_disabled_file(
          file.path(run_dir, "camtrapdp_export", "DISABLED.txt"),
          "Camtrap DP export disabled by config."
        )
      }
    },
    format = "file"
  ),
  tar_target(
    run_manifest,
    {
      out_path <- file.path(run_dir, "run_manifest.json")
      outputs <- list(
        tables = list(
          effort_summary = effort_summary_csv,
          time_qc_summary = time_qc_summary_csv,
          time_qc_flags = time_qc_flags_csv,
          events_per_day = events_per_day_csv,
          event_spacing = event_spacing_csv,
          event_threshold_sensitivity = event_threshold_sensitivity_csv,
          occasion_length_sensitivity = occasion_length_sensitivity_csv,
          detection_history = detection_history_csv,
          occupancy_summary = occupancy_summary_csv,
          occupancy_aic = occupancy_aic_csv,
          occupancy_predictions = occupancy_predictions_csv,
          community_abundance = community_abundance_csv,
          community_presence = community_presence_csv,
          alpha_diversity = alpha_diversity_csv,
          beta_diversity = beta_diversity_csv,
          traits_clean = traits_clean_csv,
          traits_aligned = traits_aligned_csv,
          traits_missing = traits_missing_csv,
          functional_diversity = functional_diversity_csv,
          functional_diversity_dropped = functional_diversity_dropped_csv,
          trait_site_proportions = trait_site_proportions_csv,
          trait_env_associations = trait_env_associations_csv,
          rai_site_species = rai_site_species_csv,
          rai_species = rai_species_csv,
          diel_site = diel_site_csv,
          diel_site_season = diel_site_season_csv,
          diel_overall = diel_overall_csv,
          rarefaction = rarefaction_table_csv
        ),
        figures = list(
          rarefaction = rarefaction_plot,
          effort_histogram = effort_histogram_plot,
          effort_heatmap = effort_heatmap_plot,
          site_map = site_map_plot,
          time_qc_backward_jumps = time_qc_backwards_plot,
          event_spacing = event_spacing_plot,
          event_threshold_sensitivity = event_threshold_sensitivity_plot,
          occasion_length_sensitivity = occasion_length_sensitivity_plot,
          occupancy_predictions = occupancy_prediction_plots,
          alpha_diversity = alpha_diversity_plot,
          beta_diversity = beta_diversity_plot,
          functional_diversity = functional_diversity_plot,
          trait_env_associations = trait_env_plot,
          rai_species = rai_species_plot,
          diel_overall = diel_overall_plot
        ),
        models = list(occupancy = occupancy_model_rds),
        report = list(html = report_html, pdf = report_pdf),
        manuscript = list(methods_html = methods_html, methods_pdf = methods_pdf),
        exports = list(camtrapdp = camtrapdp_export),
        session_info = session_info
      )

      write_run_manifest(
        path = out_path,
        schema_version = schema_version,
        params = config,
        outputs = outputs,
        session_info_path = session_info,
        config_file = config_file
      )
    },
    format = "file"
  )
)
