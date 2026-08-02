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

## 2026-05-29 — Move project baseline to R 4.6.0 on the Mac mini
Decision:
- Treat the previous R 4.5.x pin as stale and migrate the project baseline to R 4.6.0.
- Refresh `renv.lock` under R 4.6.0 and use current CRAN-compatible package versions for this development bedrock.
- Update CI and the container recipe to R 4.6.0.

Rationale:
- The Mac mini dev box has Homebrew R 4.6.0 as the default terminal R.
- Moving the lockfile forward avoids carrying obsolete package pins such as `Matrix 1.7-4`, which does not compile cleanly against R 4.6 headers.
- Native Apple Silicon validation is now a first-class development target for this repo.

Consequences / follow-ups:
- R 4.6.0 is now the supported local and CI baseline.
- The Dockerfile installs a matching R base and uses an architecture-aware Quarto download so local arm64 Docker builds and amd64 CI builds can both work.
- Container builds can pass `GIT_COMMIT` so image-generated run manifests preserve source provenance even though `.git/` is excluded from the build context.
- Generated targets metadata is no longer tracked because it stores machine-specific absolute paths and changes on every local run.
- Re-run lint, tests, and the full exemplar pipeline after the migration.

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

## 2026-03-23 — Legacy Camelot ideas are incorporated only as standardised exploratory summaries
Decision:
- Do not port the legacy Camelot analysis scripts directly into the workflow.
- Retain only three descriptive ideas from that code as first-class outputs derived from the current internal schema: a consolidated species summary, operating-days-to-first-detection summaries, and multi-species same-image summaries.
- Use current workflow semantics for these outputs rather than attempting legacy parity.

Rationale:
- The legacy scripts are tightly coupled to Windows paths, Camelot-export assumptions, and hand-edited operational matrices that do not fit the current `targets` pipeline.
- The current workflow already supersedes most of the old analytical surface, so only a few missing convenience summaries add value.
- Preserving current semantics keeps the outputs consistent with the rest of the pipeline and easier to test and explain.

Consequences / follow-ups:
- New exploratory tables are documented and rendered in the report/methods artefacts as descriptive outputs, not as Camelot-compatibility mode.
- This pass intentionally does not add Camelot CSV ingestion, coordinate-based site clustering, 3D array outputs, or legacy geometric-mean summaries.
- Any future legacy-inspired additions should start from the validated internal tables rather than from the old scripts themselves.

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

## 2026-01-08 — Default Camtrap DP export license aligns with dataset CC-BY 4.0
Decision:
- Set the default `camtrapdp_export.license` to `CC-BY-4.0` for Judbury-derived exports.

Rationale:
- The exemplar dataset is CC‑BY 4.0; export metadata should reflect the dataset’s licensing.

Consequences / follow-ups:
- Users exporting other datasets should override the license in their config as needed.

---

## 2026-01-08 — Report section order is fixed for v1.0
Decision:
- Keep the report section ordering fixed (community → traits → spatial → occupancy) and defer configurable ordering.

Rationale:
- The current ordering matches the stated analysis priorities and avoids additional report‑templating complexity for v1.0.

Consequences / follow-ups:
- If users need custom ordering, add a `report.section_order` config option in a future release.

---

## 2026-01-08 — Add a synthetic non-Judbury example dataset for portability checks
Decision:
- Provide a small synthetic dataset (`data/forest_example/`) with realistic camera-trap structure to test portability beyond the Judbury exemplar.

Rationale:
- A lightweight, non-Judbury dataset surfaces schema and analysis edge cases without introducing data-licensing hurdles.

Consequences / follow-ups:
- The example is illustrative rather than ecological truth; users should replace it with real study data for inference.

---

## 2026-01-08 — Occupancy summaries use naive diagnostics and profile CIs
Decision:
- Add naive occupancy diagnostics (site counts and exact binomial CI) to occupancy summaries.
- Report `psi` at mean covariate values with profile-likelihood CI on the state intercept when available; suppress site-level psi CIs in plots.

Rationale:
- With small numbers of sites and boundary estimates, Wald intervals can be misleading; naive occupancy makes sampling information explicit.

Consequences / follow-ups:
- Occupancy tables include additional diagnostics and a `psi_ci_method` indicator.
- Report text clarifies interpretability and design limitations.

---

## 2026-01-07 — Container base image and Quarto strategy
Decision:
- Use `rocker/r-ver:4.5.2` as the container base and install Quarto + TinyTeX during the build.
- Superseded on 2026-05-29 by the R 4.6.0 migration decision above.

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

---

## 2026-01-08 — Fixed-offset timezone for Judbury timestamps
Decision:
- Use `timezone_fixed_offset_hours = 10` for Judbury data to treat timestamps as fixed UTC+10 and ignore DST gaps.

Rationale:
- Camera clocks were recorded in local time without DST adjustments; fixed-offset parsing avoids false DST-gap flags.

Consequences / follow-ups:
- Time QC still flags backward jumps, but DST-gap counts should be zero for Judbury runs.

---

## 2026-01-08 — Diel classification defaults to flash
Decision:
- Keep `diel.method = "flash"` as the default for Judbury, with an optional `clock` method for users who prefer time-based classification.

Rationale:
- Flash metadata is more reliable than clock time for Judbury due to clock drift; clock-based classification remains approximate.

Consequences / follow-ups:
- Clock-based diel classification uses fixed day/night hours (configurable) and does not model sunrise/sunset.

---

## 2026-07-23 — Separate evidence invocation identity from equivalence

Decision:
- Allocate a unique filesystem-safe ID for every supported full invocation,
  including same-second and content-equivalent reruns.
- Keep source, raw/resolved configuration, engine, and composite SHA-256
  fingerprints as equivalence evidence; do not reuse or collapse runs.
- Retain configured `run_id` only as a report-facing compatibility label.

Rationale:
- Invocation provenance and content equivalence answer different questions.
  Collapsing them would erase execution history and make collision handling
  ambiguous.

Consequences / follow-ups:
- Completed bundles are immutable and non-overwriting.
- Engine equivalence includes the installed versions of packages named by
  `renv.lock`, not only the lockfile bytes.
- Explicit content reuse remains a later, separately authorized capability.

---

## 2026-07-23 — Completion record and regular latest pointer form the trust root

Decision:
- Inventory every payload file by relative path, byte size, and SHA-256 in a
  versioned manifest; write `COMPLETED.json` last and bind it to the manifest
  hash.
- Publish by same-filesystem directory rename, then atomically replace the
  regular-file `outputs/latest` pointer with the validated run ID.
- Reject pointer traversal, separators, symlinks, and unknown targets.
- Snapshot the raw YAML once and make both fingerprinting and scientific
  targets consume that exact payload.

Rationale:
- This order preserves prior evidence and prior latest bytes across failure,
  supports portable verification, and avoids platform-dependent symlink
  semantics.

Consequences / follow-ups:
- A valid completed bundle may remain discoverable if failure occurs after
  directory publication but before pointer replacement.
- Portable verification recomputes source, raw/resolved config, engine, and
  composite cross-links, including against checksum-reclosed inconsistencies.
- Internal hashes provide tamper evidence, not publisher authentication or
  signing.

---

## 2026-07-23 — Scientific runs consume snapshots and exclude dictionary maintenance

Decision:
- Materialize parser-consumed source bytes before analysis, including explicit
  local/remote CamtrapDP acquisition with pinned remote digests and a
  content-addressed cache.
- Preserve the CamtrapDP descriptor byte-for-byte in the parser snapshot;
  acquisition parsing must not replace it with a normalized serialization.
- Remove data-dictionary generation from the scientific target graph while
  retaining `scripts/update_data_dictionary.R` and the sync test.

Rationale:
- Parser inputs must remain fixed for the invocation, and scientific execution
  must not mutate tracked repository documentation.

Consequences / follow-ups:
- Pre-invocation byte changes create new source/composite fingerprints.
- Missing resources, digest mismatch, snapshot mutation, and path escape fail
  before publication.

---

## 2026-07-23 - Validation repair authority and source-row lineage

Decision:
- Run one immutable validation preflight before supported scientific analysis,
  with a validation-only mode that cannot publish completion or advance
  `outputs/latest`.
- Keep the public four-table input schema unchanged and assign deterministic
  internal resource and parsed-row identities in provenance sidecars.
- Default every semantic repair to preview without application. Approval is
  exact and proposal-specific; overriding explicit supplied evidence also
  requires a recorded reason.
- Ship no production fill-unknown or deployment-period inference rule.
- Publish new completed bundles as
  `camtrap-evidence-manifest/1.1`, while retaining portable verification of
  legacy manifest 1.0 bundles.
- Use `operational detection event` in current user-facing prose; preserve
  existing compatibility filenames and configuration keys.

Rationale:
- Scientific evidence should remain source-derived unless a reviewer has
  explicitly authorized the exact proposed change.
- Row dispositions, changed values, and operational event membership need
  auditable source links without changing scientific table columns.
- Validation previews must remain reviewable even when analysis is blocked.

Consequences / follow-ups:
- Integrity failures are non-waivable and stop before analysis.
- Declined or unresolved proposals leave source-derived values unchanged;
  analysis continues only when those values already satisfy the current
  contract.
- Manifest 1.1 cross-links the validation, repair, transformation,
  source-row, changed-field, and event-membership records.
- General selective module execution remains deferred to Phase 4.

---

## 2026-01-08 — Add spatial site map with interpolated covariate surface
Decision:
- Implement a spatial site map using interpolation of existing site covariates (default `ndvi`, fallback to `elevation_m` or `canopy_h_m`) and insert a new WP before Line 0.8 to satisfy the PI request for spatial overlays.

Rationale:
- Provides a terrain/vegetation-style background without relying on external basemap services, keeping runs self-contained while still offering spatial context.

Consequences / follow-ups:
- Map represents an interpolated surface, not measured continuous data; interpretation notes and report text should emphasize this.

---

## 2026-07-26 - Keep entity resolution as versioned audit evidence

Decision:
- Approve the exact Judbury 13-physical-to-nine-nominal crosswalk and four
  undirected move pairs under its recorded SHA-256 authority.
- Keep `nominal_grid_station`, `physical_location`, `deployment`, and
  `analysis_site` distinct. Judbury deployment identity/interval/chronology
  remain unresolved, and `analysis_site` remains unselected with zero
  memberships.
- Publish entity evidence in validation preview 1.1 and manifest 1.2 without
  joining or rerouting analytical inputs. Retain manifest 1.0/1.1 verification.

Rationale:
- Explicit factual evidence makes identity risks inspectable without turning
  suffixes, coordinates, effort runs, or legacy labels into unsupported
  deployment or grouping rules.
- Semantic reconstruction and exact sidecar authority prevent checksum
  reclosure from manufacturing new mapping authority.

Consequences / follow-ups:
- The existing four validated tables and 13 Judbury scientific keys remain the
  analytical contract.
- Purpose-specific grouping, deployment chronology, effort/event routing,
  public fields/API/migration, and full Phase 3 adapter/profile work require
  separate authority and evidence.

---

## 2026-07-27 - Bind approved Judbury deployment evidence as audit-only lineage

Decision:
- Accept the exact Goal 008 packet at commit
  `478832240e77388da299e55871bdeb6e386c90c5`, normalized service SHA-256
  `f33eeac9d70126966717c8e3f4731c00a97cbc3a34c2f44ce5c70d91c7d5283a`,
  deployment-ledger SHA-256
  `0921eb8845c2bb1ad5760271f283ab2783735b7739e254c67e9243bc906f3ebf`,
  and the recorded combined authority reference.
- Represent the 13 approved Judbury deployments, 75 ordered service events,
  and four directed predecessor/successor relations only in versioned entity
  provenance. Keep the Goal 007 crosswalk unchanged and keep direction out of
  the typed-link namespace.
- Retain `data/jc_op.csv` as daily-operation authority and `sN.run_days` as
  audit-only metadata. Forbid analytical routing and keep `analysis_site`
  unselected.

Rationale:
- Exact immutable source and ledger evidence can resolve deployment identity
  and declared day-precision spans without turning service metadata into
  effort or inventing within-day routing.
- Separate source, ledger, operation, and approval identities make the
  deployment evidence reconstructable and reject checksum-reclosed changes.

Consequences / follow-ups:
- Goal 008 uses deployment-lineage 1.1 within the unchanged five-file entity
  namespace, validation preview 1.1, and manifest 1.2.
- Local acceptance and independent implementation review passed for the exact
  SHA-pinned profile, with one non-blocking defence-in-depth note. The
  standalone service reader also accepts blank cells as missing in unused or
  initial service-date and corresponding `run_days` positions, although the
  packet requires literal `NA`. Exact authority and reconstruction gates make
  altered bytes unreachable for this approved source.
- Literal-`NA`-only rejection and negative blank-token tests are a hard gate
  before any different service source, generalized reader reuse, or new
  deployment-evidence profile is approved.
- The CamtrapDP exporter continues to derive its operational envelope from
  first/last active `jc_op` dates. Any substitution of declared deployment
  spans requires a separate compatibility decision and packet.
- Purpose-specific grouping, effort/event routing, public fields, profile
  precedence, and the remaining Phase 3 work stay deferred.
- Exact-path publication and exact-SHA CI remain pending.

---

## 2026-08-01 - Integrate one explicit selected-resolution ecological branch

Decision:
- Keep all legacy physical-location analyses unchanged and add one post-event
  branch selected explicitly by `analysis_unit`.
- Accept the fixed Judbury 13-physical-location to nine-analysis-site mapping
  only under its exact profile, authority, and SHA-256. Treat its four
  synthetic midpoints as mapping/separation coordinates only; do not pool or
  re-extract physical covariates.
- Define selected effort as confirmed active site-days after conservative
  member-location union. Report only observed, detection-limited richness and
  presence. Treat Jaccard as a descriptive observed-presence comparison, not
  standardized for unequal confirmed effort, completeness, or detectability.
- Publish explicit modes with preview 1.2, manifest 1.3, the closed four-file
  selected provenance namespace, an always-present status record, and four
  eligible paths or four explicit nulls. Retain manifest 1.0-1.2 and preview
  1.0-1.1 verification for their original contracts.

Rationale:
- Assigning already-defined events preserves source-row and event identity
  while allowing the reviewed analysis unit to support a small, interpretable
  ecological summary.
- Reconstructing status and outputs from bundled evidence prevents checksum
  reclosure from manufacturing eligibility or ecological results.

Consequences / follow-ups:
- Candidate content HEAD `6ca44dd6f8fd78ae9462cc6c80c0010f147a316f`
  passed local acceptance and was published as core implementation
  `3d0f23ac0cbabdeef780144a0fad261d2ce366be` under packet
  `183bb7a80e54abb8dd59ec7f2c2a31dda72e5bc4` and the approved mapping SHA-256.
  Independent reconstruction passed 26/26; final review returned `I1_CLOSED`,
  `SPEC_PASS`, `SCIENCE_PASS`, `QUALITY_PASS`, and `PUBLISH`.
- First CI run `30713505836` failed only at one platform-dependent bundle-test
  assertion. Test-only repair `d0594861e8941f4496989de4ab1c8a6e66f9b889`
  then passed exact-SHA workflow `30716777969`, completing Goal 009 closeout.
- RAI, diel, occupancy, traits, functional diversity, rarefaction, exports,
  physical community outputs, and the broad site map remain on their existing
  physical-location inputs.
- The selected branch does not estimate unseen richness, standardise coverage,
  make abundance/density claims, pool covariates, generalize concurrency or
  grouping, or support inferential turnover conclusions.
- A public analysis-unit API, profile precedence, and migration policy remain
  deferred.
- Goal 009 is complete, accepted, published, and exact-SHA-CI-confirmed at the
  final repair SHA; the core scientific implementation remains
  `3d0f23ac0cbabdeef780144a0fad261d2ce366be`.

---

## 2026-08-02 - Audit test value and runtime before further feature work

Decision:
- Goal 010 will ruthlessly audit the test suite before further feature work.
  Default to subtraction; no test is presumed necessary because it exists.
- Retain a test only when it identifies the real failure prevented, beneficiary,
  run occasion, understandable purpose, and runtime/resource trade-off. Remove,
  combine, simplify, or demote tests wherever practical; distinguish fast
  everyday and slower release-grade integration only when value warrants it.
- Require concrete current-project justification for compatibility,
  provenance, bundle, tamper, and publication tests while preserving
  proportionate safeguards for scientific correctness, data integrity,
  destructive or irreversible publication, and reproducibility.

Consequences / follow-ups:
- Barry authorized the bounded Goal 010 packet and implementation. The suite is
  now split into fast everyday and explicit release profiles; ordinary CI owns
  one separate target smoke, while the full Judbury evidence run is release
  only.
- The implemented test surface is 4,929 lines and 121 blocks, down from 7,556
  lines and 179 blocks. Production-runner invocations inside tests fell from 26
  to two validation-only release calls.
- Independent re-review found no material scientific or data-integrity loss.
  Historical schemas, nominal-station compatibility, plot existence, repeated
  reclosure, and duplicated production-runner matrices have no retained current
  beneficiary.
- Exact-SHA ordinary workflow `30731537537` passed with a 21-second fast-test
  step and 3-minute-2-second complete job. Manual release workflow
  `30731649136` passed the full Judbury run, verifier, and artefact upload at
  the same implementation SHA.
- Independent reconstruction from emitted run
  `20260802T040631Z-9e69f0844de14465` reproduced the 13-to-nine mapping, 9,639
  operation rows, 11,572 events, 15,672 source memberships, presence OR,
  richness row sums, all 81 observed Jaccard cells, protected physical outputs,
  and visible report limits. Goal 010 is complete and published.
- Production repair remains deferred for zero-row selected-event preview
  serialization and CamtrapDP deployment lineage that omits the physical-
  location identifier required by grouped-site concurrency.
