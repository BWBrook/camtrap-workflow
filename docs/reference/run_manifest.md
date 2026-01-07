# Run manifest (placeholder)

This file documents the intended contents of the run manifest that will be written
to `outputs/` for each pipeline run (implemented in WP-0.3.5).

## Purpose

The run manifest is the authoritative provenance record for a pipeline run.
It enables auditing and comparison of runs without reading code.

## Required fields (v0.1)

- `run_id`: unique identifier for the run (timestamp-based or hash-based)
- `timestamp_utc`: ISO 8601 timestamp for when the run started
- `schema_version`: input schema version (see `schema_version` file)
- `git_commit`: git commit hash if available, otherwise `NA`
- `params`:
  - `timezone`
  - `event_threshold_minutes`
  - `inputs_path`
  - `outputs_path`
  - `analysis_toggles` (MVP outputs enabled/disabled)
- `inputs`:
  - `site_path`
  - `op_path`
  - `obs_path`
  - `taxa_path`
- `outputs`:
  - tables produced (paths)
  - figures produced (paths)
  - report paths (HTML + PDF)
  - manuscript paths (methods HTML + PDF)
  - exports (e.g., Camtrap DP datapackage path)
  - session info path
- `session_info`: captured output of `sessionInfo()`
- `warnings`: any warnings surfaced during the run (if captured)

## Format

The manifest should be machine-readable (JSON or YAML). A short human-readable
summary can be written alongside it for quick review.
