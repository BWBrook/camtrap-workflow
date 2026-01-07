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

## Notes

- Changes to `config.yml` invalidate downstream targets.
- When outputs are disabled via toggles, a placeholder file is written to keep the pipeline consistent.
