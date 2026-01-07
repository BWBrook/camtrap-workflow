# Configuration reference (config.yml)

The pipeline is configured via a single YAML file at the project root: `config.yml`.

## Fields

- `schema_version_path`  
  Path to `schema_version.txt`.

- `run_id`  
  Run identifier used for the canonical run folder (default: `latest`).

- `timezone`  
  Olson timezone string used for datetime parsing (e.g., `Australia/Hobart`).

- `event_threshold_minutes`  
  Gap threshold (minutes) for independent-event clustering.

- `paths.inputs`  
  Input table paths for the four-table contract:
  - `site`
  - `op`
  - `obs`
  - `taxa`

- `paths.outputs`  
  Base output directory for all artefacts (default `outputs`).

- `analysis.rarefaction`  
  Toggle rarefaction/species accumulation outputs (TRUE/FALSE).

- `analysis.report`  
  Toggle report rendering (TRUE/FALSE). Requires `analysis.rarefaction = TRUE`.

- `time_qc.backward_jump_threshold_hours`  
  Threshold (hours) for flagging backward time jumps as potential clock drift.

- `sensitivity.event_threshold_minutes`  
  Vector of event-threshold values (minutes) to use in sensitivity outputs.

- `sensitivity.occasion_length_days`  
  Vector of occasion lengths (days) to use in sensitivity outputs.

- `detection_history.occasion_length_days`  
  Length of each detection-history occasion in days.

- `detection_history.start_date`  
  Optional start date for occasions (ISO `YYYY-MM-DD`); defaults to the first effort date.

- `occupancy.species`  
  Optional character vector of species short codes for occupancy modeling. If `null`, the top `occupancy.top_n` species by event count are used.

- `occupancy.top_n`  
  Number of top species (by events) to model when `occupancy.species` is null.

- `occupancy.covariates`  
  Vector of site covariate names to include in occupancy candidate models.

## Notes

- Changes to `config.yml` invalidate downstream targets.
- When outputs are disabled via toggles, a placeholder file is written to keep the pipeline consistent.
