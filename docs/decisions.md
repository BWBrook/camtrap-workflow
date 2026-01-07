# Decisions

This file records key decisions that shape the project. Add entries whenever a choice is:
- hard to reverse,
- affects architecture or scientific interpretation,
- or changes user-facing behaviour.

Use the format:
- Date
- Decision
- Rationale
- Consequences / follow-ups

---

## 2025-12-16 — Project is an analysis workflow repo (not a CRAN package)
Decision:
- Treat camtrap-workflow as a reproducible analysis project built around `targets` + Quarto, not as a CRAN-ready R package.

Rationale:
- The primary deliverable is a complete end-to-end workflow with artefacts and a report, not a reusable library alone.
- Package structure constraints can conflict with keeping exemplar CSV datasets and workflow artefacts in-repo.

Consequences / follow-ups:
- We will still write modular functions under `R/` and test them.
- Packaging can be revisited later as an optional “extract library” step.

---

## 2025-12-16 — Primary input contract is four tabular CSVs
Decision:
- The canonical workflow ingests four tables (site, taxa, op, obs) as CSVs.

Rationale:
- Matches the current repo data and the intended usage: analysis after labelling and metadata assembly.

Consequences / follow-ups:
- Add strict schema validation and clear error messages.
- Optional adapters may convert other formats into this contract.

---

## 2025-12-16 — Optional adapter: Camtrap DP / WildObsR
Decision:
- Support Camtrap Data Package ingestion via WildObsR as an optional adapter layer if it materially improves interoperability.

Rationale:
- WildObsR is explicitly built for standardised camera trap packages and provides tooling for model-ready matrices.

Consequences / follow-ups:
- Do not block MVP on this.
- If implemented, ensure parity: conversion must preserve provenance and pass the same QC checks.

---

## 2025-12-16 — Independent event is the core unit; threshold is configurable
Decision:
- Define independent events by clustering detections of the same species at the same site within a time-gap threshold.
- Default threshold: 15 minutes.

Rationale:
- This is a standard approach for avoiding inflation of abundance proxies.
- The exemplar outline suggests a 15-minute gap as a reasonable default.

Consequences / follow-ups:
- Make threshold a config parameter.
- Add an event-spacing diagnostic plot and sensitivity checks.

---

## 2025-12-16 — Timezone default and clock drift handling
Decision:
- Treat datetimes as local time with an explicit timezone parameter (default: Australia/Hobart).
- Do not silently “correct” clock drift; instead flag suspicious patterns with diagnostics.

Rationale:
- Camera trap clocks are often wrong; silent correction creates irreproducible and non-auditable transformations.

Consequences / follow-ups:
- Implement a clock drift check that produces warnings/flags and a QC report section.
- Allow users to opt into corrections only with explicit configuration and documented assumptions.

---

## 2025-12-16 — Output contract and provenance
Decision:
- All derived artefacts are written under `outputs/` (gitignored) with stable filenames.
- Each run must write session info and a run manifest.

Rationale:
- Scientific outputs must be inspectable and traceable to the pipeline run.

Consequences / follow-ups:
- Add helper utilities for writing outputs and manifests.
- CI should upload key artefacts for review.

---

## 2025-12-18 — CI + report artefact via Quarto (minimal MVP)
Decision:
- Treat a minimal Quarto HTML report as a first-class pipeline artefact (rendered in `targets`) for MVP, using a lightweight `analysis/report.qmd` that reads precomputed pipeline outputs.

Rationale:
- The repo goal is an end-to-end workflow producing coherent scientific artefacts; a rendered report provides an immediate review surface for PI and collaborators.
- Rendering in the pipeline makes it reproducible and CI-checkable.

Consequences / follow-ups:
- Keep the report inputs narrow and explicitly passed via a saved `report_inputs.rds` target to avoid hidden coupling.
- Expand report sections and diagnostics (effort, event-spacing, QC summaries) as subsequent WPs land.

---

## 2025-12-18 — Fix exemplar species code mismatch (`ben` → `wal`)
Decision:
- Treat the single `obs$species == "ben"` record as a typo and recode it to `wal` to align with `jc_taxa.csv`.

Rationale:
- Input contract requires all observation species codes to exist in the taxa table.
- `jc_taxa.csv` already includes Bennett’s wallaby as `wal`; no `ben` entry exists.

Consequences / follow-ups:
- Documented in WP-0.3.3 log; re-run required for downstream artefacts.

---

## 2025-12-18 — Central configuration via `config.yml`
Decision:
- Use a single `config.yml` file at the project root as the primary configuration surface.

Rationale:
- Keeps key parameters (timezone, event threshold, paths, toggles) in one place.
- Aligns with the architecture doc’s recommended options and supports reproducible runs.

Consequences / follow-ups:
- `config.yml` is now a tracked input for the pipeline.
- Future parameters should be added here rather than hard-coded in `_targets.R`.

---

## 2026-01-06 — RAI uncertainty via Poisson rate confidence intervals
Decision:
- Compute RAI uncertainty using Poisson rate confidence intervals on event counts per unit effort.

Rationale:
- Provides a simple, transparent uncertainty estimate aligned with event count data.
- Avoids heavy bootstrap costs for the MVP while still surfacing uncertainty.

Consequences / follow-ups:
- RAI outputs now include `rai_lower`/`rai_upper` bounds.
- If later analyses require more complex uncertainty models, revisit with bootstrap or hierarchical methods.

---

## 2026-01-06 — Occupancy package choice for 0.4.x: `unmarked`
Decision:
- Use `unmarked` as the primary single-season occupancy package for WP-0.4.x.

Rationale:
- Mature, widely used in camera-trap workflows, and well-supported for single-season occupancy.
- Allows clear separation between detection history construction and model fitting.

Consequences / follow-ups:
- Detection history outputs will be shaped to allow easy conversion to `unmarked` matrices.
- Revisit if multi-species or spatial models become a requirement (WP-0.4.6).

---

## 2026-01-06 — Detection history canonical format: long table with effort
Decision:
- Canonical detection history output will be a long table with `site`, `species`, `occasion`, `detected`, `effort`, and occasion boundaries.

Rationale:
- Long format preserves metadata and is easily reshaped into wide matrices required by modeling packages.
- Simplifies alignment checks between detection and effort.

Consequences / follow-ups:
- Documented in `docs/reference/detection_history_schema_v0.1.md`.
- Alignment checks will enforce `detected == 1` only when `effort == 1`.
