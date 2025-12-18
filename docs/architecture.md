# Architecture

## Architectural style

This repository is an R analysis project built around:
- `targets` for pipeline orchestration and reproducibility,
- modular R functions under `R/`,
- and a rendered report (Quarto/Rmd) as a first-class pipeline artefact.

The design goal is **traceable scientific computation**:
- each derived object has clear provenance,
- outputs are produced from upstream validated inputs,
- and the pipeline can be re-run deterministically in a locked environment.

## Repository layout (target state)

- `R/`
  - Reusable functions, grouped by concern (I/O, QC, effort, events, metrics, models, community).
- `_targets.R`
  - The pipeline definition (targets).
- `analysis/`
  - Report source(s) (e.g., `report.qmd`) and small helper scripts.
- `data/`
  - Exemplar dataset (Judbury) and documentation (data dictionary).
- `scripts/`
  - Maintenance scripts (e.g., data dictionary generation).
- `tests/`
  - `testthat` unit tests + optional smoke/integration checks.
- `docs/`
  - Product/engineering harness, roadmap, decisions, and workflow rules.
- `outputs/` (gitignored)
  - Pipeline artefacts (tables, figures, report, model objects).

## Core data flow

1) Inputs
- `jc_site.csv` (site covariates)
- `jc_op.csv` (effort on/off)
- `jc_obs.csv` (detections)
- `jc_taxa.csv` (traits)

2) Standardisation
- Column name harmonisation (snake_case)
- Datetime parsing with explicit timezone
- Type coercion where safe, otherwise fail

3) QC (fail-fast)
- Key alignment: obs.site ∈ site.site; obs.species ∈ taxa.short; op columns align to site IDs
- Effort validity: 0/1 only, no NAs (unless explicitly allowed as downtime)
- Datetime plausibility: clock drift diagnostics

4) Derived core tables
- `op_long` (date, site, on_off)
- `trap_nights` / `trap_days` (effort per site)
- `obs_filtered` (detections during operational periods)
- `obs_events` (detections tagged with event_id)
- `events_per_day` (site × species × date event counts)
- `detection_histories` (site × occasion × species matrices)
- `community_matrix` (site × species abundance/presence)

5) Analyses
- MVP: RAI, diel summaries, rarefaction, effort plots
- Beta: occupancy models (unmarked)
- 1.0: community and trait analyses

6) Outputs
- Write tables to `outputs/tables/`
- Write figures to `outputs/figures/`
- Write models to `outputs/models/`
- Render report to `outputs/report/`
- Save session info to `outputs/session_info.txt`

## Interfaces and module responsibilities

Suggested functional modules (implemented as R scripts under `R/`):

- `R/io_read.R`
  - Read inputs; standardise names; parse datetimes.
- `R/qc_validate.R`
  - Data contract checks; informative errors/warnings.
- `R/effort.R`
  - Pivot effort matrix; compute effort summaries; join effort to detections.
- `R/events.R`
  - Independent-event clustering; event-spacing diagnostics.
- `R/metrics_descriptive.R`
  - RAI and uncertainty; diel summaries; accumulation curves.
- `R/community.R`
  - Community matrices; alpha/beta diversity; distance–decay.
- `R/traits.R`
  - Trait cleaning; functional diversity; trait–environment workflows.
- `R/models_occupancy_unmarked.R`
  - Detection history builder; occupancy model fitting; predictions; diagnostics.
- `R/reporting_helpers.R`
  - Small helper utilities for report rendering and output writing.

Each module must be testable independently.

## targets pipeline strategy

- Keep `_targets.R` declarative: targets call functions; functions do the work.
- Use `format = "file"` for saved artefacts (figures, report, exported tables).
- Prefer `tarchetypes` for report rendering:
  - report reads upstream targets using `tar_read()`/`tar_load()`.
- Separate “heavy” analyses (e.g., spatial, multispecies models) into optional branches or conditional execution, so CI can run a minimal subset reliably.

## Configuration

The workflow must centralise user-modifiable parameters, such as:
- timezone,
- event threshold (minutes),
- definition of sampling occasion (day/week),
- inclusion/exclusion rules (e.g., species filters),
- formulas for occupancy models.

Preferred approaches:
- a `config.yml` read by the pipeline, OR
- a single `params` list defined near the top of `_targets.R`.

## Traceability

Every run must produce:
- session info (`sessionInfo()`),
- a small run manifest (timestamp, git commit hash if available, config snapshot),
- and output artefacts whose filenames include stable identifiers (not random strings).
