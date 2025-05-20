# _targets.R – data-import + QC scaffold (targets ≥ 1.3.0)

import::from("targets", tar_option_set, tar_target, tar_cue)
import::from("here", here)

import::here(
  read_jc_csv, check_keys, validate_effort,
  pivot_op_long, calc_trap_nights, filter_obs_by_effort,
  define_events, summarise_events,
  .from = "R/custom_funcs.R"
)

# Packages available to every target
tar_option_set(
  packages = c(
    "camtrapR", "unmarked", "spOccupancy", "readr", "dplyr",
    "FD", "cowplot", "sf", "janitor", "tidyr", "lubridate",
    "here"
  )
)

list(
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
  tar_target(taxa_raw, read_jc_csv(here("data", "jc_taxa.csv"))),
  tar_target(site_raw, read_jc_csv(here("data", "jc_site.csv"))),
  tar_target(op_raw,   read_jc_csv(here("data", "jc_op.csv"))),
  tar_target(obs_raw,  read_jc_csv(here("data", "jc_obs.csv"))),
  
  ## ── QC CHECKS (pipeline halts on error) ──────────────────────────────
  tar_target(key_check,
    check_keys(obs_raw, site_raw),
    cue = tar_cue(mode = "always")
  ),
  tar_target(effort_validation,
    validate_effort(op_raw),
    cue = tar_cue(mode = "always")
  ),
  ## ── EFFORT STANDARDISATION ───────────────────────────────────────────
  tar_target(op_long,      pivot_op_long(op_raw)),
  tar_target(trap_nights,  calc_trap_nights(op_long)),
  tar_target(obs_filtered, filter_obs_by_effort(obs_raw, op_long)),
  ## ── INDEPENDENT-EVENT FILTERING ───────────────────────────────────────────────
  tar_target(
    obs_events,
    define_events(obs_filtered, threshold = 15)   # 15-min gap
  ),
  tar_target(
    events_per_day,
    summarise_events(obs_events)
  )
)
