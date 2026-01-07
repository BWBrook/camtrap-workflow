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

---

## 2026-01-07 — Temporarily disable CI on push/PR (GLPK dependency)
Decision:
- Disable GitHub Actions runs on push/PR until the system dependency for `igraph` (GLPK) is resolved.

Rationale:
- CI failed during `renv::restore()` with missing `libglpk.so.40` on GitHub runners.
- Avoids noisy failures while the dependency strategy is decided.

Consequences / follow-ups:
- CI is now manual (`workflow_dispatch`) only.
- Re-enable push/PR triggers once GLPK installation (or binary package strategy) is in place.

---

## 2026-01-07 — Defer advanced occupancy track (spOccupancy/ubms)
Decision:
- Defer advanced occupancy modelling (spOccupancy/ubms) until after community and trait outputs are complete.

Rationale:
- Single-season `unmarked` models satisfy the Beta milestone requirements.
- Advanced models add complexity before the community/trait pipeline is stable.

Consequences / follow-ups:
- Revisit in WP-0.4.6+ if spatial or multi-species models become necessary.

---

## 2026-01-07 — Traits sourced from taxa table with configurable columns
Decision:
- Use the taxa table (`jc_taxa.csv`) as the default trait source, keyed by `short` species codes, with configurable trait columns.

Rationale:
- The exemplar dataset already contains trait metadata aligned to species codes.
- Avoids introducing a separate trait file requirement for MVP community analyses.

Consequences / follow-ups:
- Trait cleaning and alignment now operate on the taxa table.
- Future datasets can override trait columns or supply a different species code column via config.

---

## 2026-01-07 — Trait–environment associations via abundance-weighted proportions + Spearman
Decision:
- Use abundance-weighted trait proportions per site and Spearman correlations against environmental covariates.

Rationale:
- Provides a stable, transparent alternative to RLQ/fourth-corner methods for MVP trait–environment signals.
- Works with categorical traits in the exemplar without heavy modeling dependencies.

Consequences / follow-ups:
- Results are exploratory; interpret with caution.
- RLQ/fourth-corner can be revisited once trait coverage expands and assumptions are reviewed.

---

## 2026-01-07 — Functional diversity uses dummy-encoded categorical traits
Decision:
- Compute functional diversity on a dummy-encoded trait matrix with missing values encoded as `unknown`.

Rationale:
- The exemplar trait data are categorical; `FD::dbFD` does not compute FDiv on purely categorical inputs.
- Dummy encoding stabilises FDiv computation while retaining all species.

Consequences / follow-ups:
- FDiv is now available for the exemplar dataset (interpret cautiously).
- If continuous traits become available, revisit the encoding strategy.

---

## 2026-01-07 — Trait–environment reporting uses BH-adjusted p-values
Decision:
- Add Benjamini–Hochberg adjusted p-values to trait–environment association outputs and use FDR filtering in the report.

Rationale:
- Multiple trait × environment tests inflate false positives; FDR adjustment provides a conservative screen.

Consequences / follow-ups:
- Report now highlights only associations passing FDR 0.1 (or falls back to strongest unadjusted correlations if none pass).

---

## 2026-01-07 — Defer WildObsR integration; adopt camtrapdp for Camtrap DP ingestion
Decision:
- Defer WildObsR integration for now and use the CRAN `camtrapdp` package for Camtrap DP ingestion.

Rationale:
- WildObsR is not currently on CRAN (GitHub-only), which adds dependency weight and install friction.
- `camtrapdp` provides core Camtrap DP parsing/validation utilities needed for the ingestion adapter with a lighter footprint.

Consequences / follow-ups:
- Revisit WildObsR if matrix-generation utilities or DP validation needs expand beyond camtrapdp’s scope.

---

## 2026-01-07 — Camtrap DP mapping uses deploymentID as site and eventStart for datetime
Decision:
- Map Camtrap DP `deploymentID` to the internal `site` field and use `observations.eventStart` (fallback to media timestamp) for `obs$datetime`.

Rationale:
- `deploymentID` aligns directly with observation records and avoids ambiguity across locations.
- `eventStart` best represents the detection time for event‑level observations.

Consequences / follow-ups:
- If multiple deployments per location need merging, revisit and add a location‑level mapping option.
- Trait fields are left `NA` unless a taxon reference is provided.

---

## 2026-01-07 — Drop non-informative occupancy covariates automatically
Decision:
- Remove occupancy covariates that are missing from the site table, all-NA, or zero variance before fitting models.

Rationale:
- Camtrap DP datasets often lack site covariates used in the exemplar, which otherwise causes degenerate model fits.
- The occupancy interface should gracefully fall back to base/effort-only models.

Consequences / follow-ups:
- Occupancy predictions may be constant across sites if no covariates remain.
- If a dataset supplies valid covariates, the full candidate set is still used.

---

## 2026-01-07 — Functional diversity ignores single-level trait columns
Decision:
- Drop trait columns with only one unique level before dummy encoding and functional diversity calculation; if no informative traits remain, return NA metrics and a placeholder plot.

Rationale:
- Dummy encoding fails when categorical traits have a single level.
- Camtrap DP example data contain no trait annotations; reporting NA avoids misleading metrics.

Consequences / follow-ups:
- Functional diversity plots may show a “no metrics available” placeholder for DP runs.
- Users should supply trait data if they require functional diversity outputs.

---

## 2026-01-07 — Disable GitHub Actions workflow pending system deps
Decision:
- Remove the GitHub Actions workflow file temporarily and rely on local quality gates until GLPK (and other system dependencies) are resolved.

Rationale:
- The CI runner lacks `libglpk.so.40`, causing `igraph` (and thus `renv::restore()`) to fail.
- The PI requested disabling CI until the roadmap is complete and dependencies are settled.

Consequences / follow-ups:
- CI will not run automatically; developers must run lint/tests/pipeline locally.
- Re‑enable CI once system dependencies are installed or a container strategy is adopted.

---

## 2026-01-07 — Override roadmap review gates for Lines 0.6–0.7
Decision:
- Proceed through all WPs in Lines 0.6 and 0.7 without stopping at the usual review gates (Large WP and line-completion gates).

Rationale:
- PI explicitly requested uninterrupted progress through Lines 0.6 and 0.7.

Consequences / follow-ups:
- A single consolidated review package will be produced after WP‑0.7.5.

---

## 2026-01-07 — Camtrap DP export uses example dataset template
Decision:
- Build Camtrap DP exports by starting from `camtrapdp::example_dataset()` and replacing deployments/media/observations plus minimal metadata.

Rationale:
- Ensures schemas and profiles align with Camtrap DP 1.0.1 without hand‑crafting frictionless resources.
- Leverages camtrapdp’s validation and write helpers.

Consequences / follow-ups:
- Export requires network access the first time the template dataset is fetched.
- Metadata defaults should be overridden in `config.yml` for publication‑ready exports.

---

## 2026-01-07 — Adopt VERSION + CHANGELOG + CITATION for releases
Decision:
- Track release version in `VERSION`, maintain a human‑readable `CHANGELOG.md`, and provide citation metadata in `CITATION.cff`.

Rationale:
- Provides consistent versioning for release bundles and external citation.
Consequences / follow-ups:
- Update `VERSION` and `CHANGELOG.md` for each release tag.

---

## 2026-01-07 — Container base image and Quarto strategy
Decision:
- Use `rocker/r-ver:4.5.2` as the container base and install Quarto + TinyTeX during the build.

Rationale:
- Aligns with the project’s R version requirement and enables PDF report rendering inside the container.

Consequences / follow-ups:
- Container builds are larger due to TeX dependencies.
- Update the Quarto version in `Dockerfile` if needed.

---

## 2026-01-07 — Pooled RAI denominator uses total survey effort
Decision:
- Define pooled RAI as total independent events per species divided by total trap nights across all included sites (not detection-only sites).

Rationale:
- Matches the report definition and standard interpretation of RAI as survey-wide effort-normalized rates.

Consequences / follow-ups:
- `rai_species.csv` now has constant `trap_nights` across species within a run.
- If a detected-sites-only variant is needed later, it should be a separately named output.

---

## 2026-01-07 — Run manifests store run-relative paths
Decision:
- Store all manifest paths relative to the run directory and include a config file hash for provenance.

Rationale:
- Ensures manifests are portable across machines and remain reviewable in zip bundles.

Consequences / follow-ups:
- Tests enforce that manifests contain no absolute paths.
