# Configuration reference (config.yml)

The pipeline is configured via a single YAML file at the project root: `config.yml`.

## Fields

- `schema_version_path`  
  Path to `schema_version.txt`.

- `run_id`  
  Run identifier used for the canonical run folder (default: `latest`).

- `timezone`  
  Olson timezone string used for datetime parsing (e.g., `Australia/Hobart`).

- `timezone_fixed_offset_hours`  
  Optional fixed offset in hours (e.g., `10` for UTC+10). When provided, datetimes are parsed using a fixed offset (`Etc/GMT±H`) and DST gaps are ignored.

- `event_threshold_minutes`  
  Gap threshold (minutes) for independent-event clustering.

- `input_mode`  
  Input mode selector: `four_table` (default) or `camtrapdp`.

- `paths.inputs`  
  Input table paths for the four-table contract:
  - `site`
  - `op`
  - `obs`
  - `taxa`
  - `camtrapdp` (path or URL to `datapackage.json` when `input_mode = camtrapdp`)

- `paths.outputs`  
  Base output directory for all artefacts (default `outputs`).

- `analysis.rarefaction`  
  Toggle rarefaction/species accumulation outputs (TRUE/FALSE).

- `analysis.report`  
  Toggle report rendering (TRUE/FALSE). Requires `analysis.rarefaction = TRUE`.

- `time_qc.backward_jump_threshold_hours`  
  Threshold (hours) for flagging backward time jumps as potential clock drift.

- `diel.method`  
  Diel classification method: `flash` (default) uses `flash == 1` as night; `clock` uses event time and fixed day/night hours.

- `diel.day_start_hour` / `diel.day_end_hour`  
  Daytime window for `clock` method (hours, 0–23). Events outside this window are classified as night.

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
  Vector of site covariate names to include in occupancy candidate models. Covariates with all-NA values or zero variance are dropped automatically (models fall back to base/effort-only if none remain).

## Camtrap DP export

- `camtrapdp_export.enable`  
  Set `true` to export the internal tables to a Camtrap Data Package under `outputs/runs/<run_id>/camtrapdp_export/`.

- `camtrapdp_export.name`  
  Data Package name (machine-friendly identifier).

- `camtrapdp_export.title`  
  Human-readable title for the export.

- `camtrapdp_export.description`  
  Description of the export (shown in `datapackage.json`).

- `camtrapdp_export.version`  
  Camtrap DP version string (default `1.0.1`).

- `camtrapdp_export.license`  
  License name for the exported data (default `CC0-1.0`).

- `camtrapdp_export.id`  
  Optional UUID for the export; if `null`, one is generated.

- `camtrapdp_export.created`  
  Optional ISO timestamp; if `null`, the export time is used.
- `traits.species_column`  
  Column in the taxa table that identifies the species short code used by observations.

- `traits.columns`  
  Vector of trait columns to clean and retain for community/functional analyses.

- `traits.association_traits`  
  Subset of trait columns used for trait–environment associations.

- `traits.environment_vars`  
  Vector of site-level environmental covariates used in trait–environment associations.

## Notes

- Changes to `config.yml` invalidate downstream targets.
- When outputs are disabled via toggles, a placeholder file is written to keep the pipeline consistent.
