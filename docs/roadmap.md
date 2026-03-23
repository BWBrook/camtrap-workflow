# Roadmap (Work Queue): camtrap-workflow

This roadmap is designed to enable long autonomous runs by an engineering agent (Codex CLI) while keeping scientific outputs trustworthy and reproducible.

---

## 1) Opening contract (how to follow this roadmap)

When the human says **“Follow the roadmap”**, Codex must:

1. Select the **first unchecked Work Package (WP)** in the **Priority Queue** (strict order).
2. Complete it **end-to-end**: code + tests + docs + artefacts, meeting the WP-DoD and the WP’s acceptance criteria.
3. Perform the **Artefact Review Cycle** and log it.
4. Mark the WP checkbox as complete (`[x]`) and add a short entry to `docs/log/` summarising:
   - what changed,
   - what artefacts were produced,
   - what sanity checks were inspected,
   - and what decisions (if any) were recorded.

### Reordering / reprioritisation
- Reordering WPs is allowed **only** if:
  - the rationale is recorded in `docs/decisions.md`, **and**
  - a corresponding log entry is added to `docs/log/`.
- If a WP reveals a new prerequisite or missing work:
  - Codex may **add a new WP** immediately **after the current WP** (or at the end of its line), with a clear title and acceptance criteria.
  - Codex may **not** skip ahead to later WPs unless the ordering contract is satisfied.

### When the queue is empty
- If the **Priority Queue has no unchecked WPs**, Codex must **stop** and report that more work must be promoted into the queue.

---

## 2) Work Package Definition of Done (WP-DoD)

A WP is not complete until **all** of the following are true:

1) **Acceptance criteria met and tested**
- All WP acceptance criteria are satisfied.
- Tests cover the change:
  - unit tests where feasible,
  - integration/smoke tests where appropriate,
  - and domain sanity tests for scientific outputs.

2) **Docs updated**
At minimum:
- configuration/reference docs updated (inputs/config/outputs affected by the WP), and
- interpretation of outputs/assumptions updated (methods limitations, definitions, caveats).

3) **Artefact Review Cycle completed and logged**
Codex must produce and inspect artefacts, then log the results:
- **Build artefacts:** pipeline outputs + report outputs + any exported tables/figures/models.
- **Canonical run artefact folder:** one run folder per WP completion (or per milestone), containing the WP’s evidence artefacts and a manifest.
- **Sanity inspection notes:** what was inspected and whether anything looked suspicious.

4) **Schema discipline**
- If the **input schema** changes:
  - bump `schema_version`,
  - provide a migration (or a documented breaking change policy),
  - and add migration tests (at least one “old → new” fixture or transform test).
- If the **output schema** changes:
  - document the change (outputs reference),
  - and add regression/sanity tests for the changed outputs (e.g., invariants, shape checks, known-value checks on exemplar).

---

## 3) Priority Queue (strict order)

Notes:
- Each WP is intended to be **1–3 hours** unless explicitly marked **(Large)**.
- “Line” identifiers reflect release/review phases (0.3.x, 0.4.x, …). Completing a line triggers a PI review gate (see Section 5).

### Line 0.3.x — Reproducible MVP: QC → Effort → Events → Descriptives → Report

- [x] **WP-0.3.1** Baseline audit + make exemplar run path real (restore → pipeline)  
- [x] **WP-0.3.2** Lock the environment (renv) with verified restore + deterministic dependency story  
- [x] **WP-0.3.3** Input data contract v0.1 + `schema_version` + validation layer that fails early and clearly  
- [x] **WP-0.3.4** Fix and harden the test baseline (dictionary sync, QC, smoke)  
- [x] **WP-0.3.5** Central configuration + run manifest (parameters, provenance, session info)  
- [x] **WP-0.3.6** Output contract + canonical run folder structure + output schema reference  
- [x] **WP-0.3.7** Effort processing hardened + effort artefacts (tables + plots)  
- [x] **WP-0.3.8** Time handling & clock diagnostics: timezone/DST strategy + drift flags + report section  
- [x] **WP-0.3.9** Independent event definition hardened + spacing diagnostics + invariants tests  
- [x] **WP-0.3.10** Descriptives pack: RAI (+ uncertainty), diel summaries, rarefaction (standardised outputs)  
- [x] **WP-0.3.11** MVP report as a first-class artefact (rendered via pipeline) + methods + limitations  
- [x] **WP-0.3.12** CI quality gates + artefact upload (restore, lint, tests, pipeline smoke)  
- [x] **WP-0.3.13** “Bring your own data” guide + template dataset folder + contract checklist  
- [x] **WP-0.3.14** Pre-occupancy prep: detection history contract + alignment checks + event-threshold sensitivity  

### Line 0.4.x — Beta: occupancy-ready data + single-species occupancy modelling

- [x] **WP-0.4.1** Detection history builder (configurable occasion) + alignment checks vs effort  
- [x] **WP-0.4.2** Single-species occupancy modelling interface (unmarked) + stable outputs  
- [x] **WP-0.4.3** Occupancy diagnostics + predictions + report integration  
- [x] **WP-0.4.4** Sensitivity suite (occasion length + event threshold) with explicit artefacts  
- [x] **WP-0.4.5** Model comparison outputs (AIC tables / candidate set discipline) + guardrails  
- [x] **WP-0.4.6** Decide on “advanced occupancy” track (spOccupancy / ubms): adopt vs defer (Decision WP)  

### Line 0.5.x — Community & traits: diversity + functional ecology

- [x] **WP-0.5.1** Community matrices (presence/abundance) derived from events + validated outputs  
- [x] **WP-0.5.2** Alpha diversity outputs + site summaries + report integration  
- [x] **WP-0.5.3** Beta diversity + distance–decay artefacts + sanity tests  
- [x] **WP-0.5.4** Trait table cleaning/alignment + trait reference + test coverage  
- [x] **WP-0.5.5** Functional diversity indices outputs (e.g., FDis/FRic/etc.) + interpretation notes  
- [x] **WP-0.5.6** Trait–environment association method (RLQ/fourth-corner or stable alternative) + artefacts  
- [x] **WP-0.5.7** Stabilise functional diversity (dummy-encoded traits) + trait–environment FDR filter  

### Line 0.6.x — Interoperability & pedagogy

- [x] **WP-0.6.1** WildObsR evaluation for this repo (matrix generation / Camtrap DP) + adopt/defer decision  
- [x] **WP-0.6.2** Camtrap DP ingestion adapter (via WildObsR and/or frictionless) **(Large)**  
- [x] **WP-0.6.3** Optional: Camtrap DP export (publish-ready package) **(Large)**  
- [x] **WP-0.6.4** Teaching module: guided exercises + “change params → observe outputs” harness  
- [x] **WP-0.6.5** Reproducibility benchmark: cold-run protocol + runtime notes + CI strategy for heavy runs  

### Line 0.7.x — Release + manuscript readiness

- [x] **WP-0.7.1** Release discipline: versioning, changelog, citation, release artefact bundle definition  
- [x] **WP-0.7.2** Container recipe (Docker or equivalent) **(Large)**  
- [x] **WP-0.7.3** Methods manuscript skeleton (Quarto) tied to pipeline artefacts + figures/tables mapping  
- [x] **WP-0.7.4** End-to-end “new dataset” dry run (template → run → report) with documented failure modes  
- [x] **WP-0.7.5** Tag v1.0 readiness gate: final QC, docs completeness, and evidence checklist  

---

## 4) Detailed WP specifications

> For every WP: do not add implementation steps here. This section defines outcomes, scope, acceptance criteria, artefact evidence, and stop conditions only.

---

### WP-0.3.1 — Baseline audit + make exemplar run path real (restore → pipeline)

**Outcome**  
A truthful baseline: the repo can be run end-to-end on the exemplar dataset, or failures are precisely identified with actionable error messages and logged. This WP establishes the “starting line” and removes ambiguity about what currently works.

**Scope**
- In: audit of current pipeline/test/doc state; establish a single canonical run story for the exemplar.
- Out: adding new scientific methods beyond what is necessary to get a coherent baseline run.

**Acceptance criteria**
- A single documented “canonical run” path exists (setup → run → where outputs appear).
- If the pipeline fails, failure is early, explicit, and points to missing prerequisites (not cryptic stack traces).
- A baseline log entry exists capturing what worked/failed and why.

**Artefact evidence**
- `docs/log/` entry for this WP, including baseline status.
- A baseline run manifest or placeholder documenting what the manifest will contain (full manifest implemented in WP-0.3.5).

**Stop condition**
- You can point to one of:
  - a successful exemplar end-to-end run, **or**
  - a clearly documented and reproducible failure that will be fixed by the next WPs.

---

### WP-0.3.2 — Lock the environment (renv) with verified restore + deterministic dependency story

**Outcome**  
Reproducibility becomes real: dependencies are locked, restore works, and the dependency strategy is stable and documented.

**Scope**
- In: populate/repair `renv.lock`; ensure restore works; document dependency expectations.
- Out: containerisation (later).

**Acceptance criteria**
- `renv.lock` is non-empty and matches the codebase dependencies.
- A clean restore succeeds (documented evidence in logs; CI support comes in WP-0.3.12).
- Dependency installation approach (renv + optional pak) is documented clearly.

**Artefact evidence**
- Updated `renv.lock`.
- Log entry demonstrating restore success and any platform caveats.

**Stop condition**
- A fresh environment can restore and load required packages without manual “install this one extra thing” steps.

---

### WP-0.3.3 — Input data contract v0.1 + `schema_version` + validation layer that fails early and clearly

**Outcome**  
The workflow has an explicit, testable input contract for the four-table mode (site/op/obs/taxa). Violations are caught early with actionable messages, and schema changes are governed by `schema_version`.

**Scope**
- In: schema reference docs; a validation layer; versioning rules.
- Out: Camtrap DP ingestion (later).

**Acceptance criteria**
- A documented input schema exists (required columns, types, keys, and allowed ranges).
- A `schema_version` exists and is surfaced in run manifests.
- Validation failures are precise (which table, which column, what rule, how to fix).
- Validation is tested with at least:
  - one valid fixture (exemplar),
  - one invalid fixture per table (minimal).

**Artefact evidence**
- `docs/reference/` (or equivalent) containing **input schema v0.1**.
- Tests covering schema validation, including failure-mode tests.
- `schema_version` file and mention in docs.

**Stop condition**
- Any dataset that violates the contract fails fast with clear remediation guidance.

---

### WP-0.3.4 — Fix and harden the test baseline (dictionary sync, QC, smoke)

**Outcome**  
Tests become a reliable guardrail. Existing broken tests are repaired; baseline coverage exists for the most failure-prone steps (schema/QC/events).

**Scope**
- In: repair existing tests; add minimal domain sanity tests; add a pipeline smoke test.
- Out: heavy model tests (later).

**Acceptance criteria**
- Test suite runs non-interactively and passes on exemplar.
- Dictionary sync test is correct and meaningful (catches real drift).
- At least one smoke/integration test confirms the pipeline can execute a minimal target set.

**Artefact evidence**
- Passing test run recorded in logs.
- Test files updated/added with clear naming for unit vs integration checks.

**Stop condition**
- Tests fail when key invariants are violated, and pass on the exemplar dataset.

---

### WP-0.3.5 — Central configuration + run manifest (parameters, provenance, session info)

**Outcome**  
All critical knobs live in one place; runs are auditable. Each run records parameters, schema_version, outputs produced, session/package versions, and commit hash (when available).

**Scope**
- In: config system; manifest file; session info capture.
- Out: complex UI or configuration management system.

**Acceptance criteria**
- A single configuration surface exists for at least:
  - timezone,
  - event threshold,
  - key paths (inputs/outputs),
  - and analysis toggles for MVP outputs.
- Every run writes a machine-readable manifest (and a human-readable summary is acceptable as a supplement).
- Manifest includes: schema_version, parameter snapshot, timestamp, session/package versions.

**Artefact evidence**
- `outputs/` contains a run manifest and session info for a canonical run.
- Config reference documentation updated.

**Stop condition**
- Two runs with different parameters can be distinguished and audited from manifests alone.

---

### WP-0.3.6 — Output contract + canonical run folder structure + output schema reference

**Outcome**  
Outputs are consistent and predictable. A canonical run folder layout exists, outputs have stable names, and the output “schema” is documented (tables/figures/models, shapes, and semantics).

**Scope**
- In: output directory structure; naming conventions; output schema docs; basic regression/sanity checks.
- Out: publishing/export formats beyond CSV/PNG/HTML/PDF.

**Acceptance criteria**
- A canonical run folder convention exists (e.g., `outputs/runs/<run_id>/...`).
- Output schema reference documents:
  - expected tables (names, columns),
  - expected figures (names, what they show),
  - and model artefacts (names/types) where relevant.
- Output changes trigger test updates or explicit regression checks.

**Artefact evidence**
- A canonical run folder containing MVP outputs + manifest.
- Output schema reference doc updated.

**Stop condition**
- A user can locate and interpret outputs without reading code.

---

### WP-0.3.7 — Effort processing hardened + effort artefacts (tables + plots)

**Outcome**  
Effort is correctly interpreted, summarised, and visualised (including downtime censoring rules). Effort becomes a first-class denominator for downstream analyses.

**Scope**
- In: robust effort parsing; effort summaries; effort plots; sanity checks.
- Out: advanced spatial covariate enrichment.

**Acceptance criteria**
- Effort metrics are computed per site and overall (trap-days/trap-nights as defined).
- Effort is joined to observations with clear censoring rules.
- Effort artefacts exist: at least one table + two plots (e.g., histogram + calendar/heatmap).
- Sanity checks ensure:
  - no negative effort,
  - no detections counted on inactive days (post-censoring).

**Artefact evidence**
- `outputs/.../tables/effort_*.csv`
- `outputs/.../figures/effort_*.png`
- Sanity test coverage and inspection notes.

**Stop condition**
- Effort artefacts are coherent and align with the raw effort matrix expectations.

---

### WP-0.3.8 — Time handling & clock diagnostics: timezone/DST strategy + drift flags + report section

**Outcome**  
Temporal handling is explicit and defensible. Timezone assumptions are documented; DST issues are handled intentionally; clock drift is detected and flagged rather than silently “fixed”.

**Scope**
- In: datetime parsing rules; timezone configuration; drift diagnostics; report narrative.
- Out: automatic correction unless explicitly configured and justified.

**Acceptance criteria**
- Timezone is configurable and documented.
- Datetime parsing is robust (clear failure on unparseable values).
- Clock drift diagnostics produce a clear artefact (table/plot) and warnings/flags.
- Report includes a “Time handling & limitations” section.

**Artefact evidence**
- `outputs/.../tables/time_qc_*.csv` and/or `outputs/.../figures/time_qc_*.png`
- Report section present with explicit assumptions.

**Stop condition**
- Temporal artefacts and report text make the project’s time assumptions transparent and reviewable.

---

### WP-0.3.9 — Independent event definition hardened + spacing diagnostics + invariants tests

**Outcome**  
The workflow consistently converts detections into independent events using a configurable threshold, produces spacing diagnostics, and enforces invariants through tests.

**Scope**
- In: event construction; event-spacing diagnostics; threshold parameterisation; invariants tests.
- Out: individual identification or SCR workflows.

**Acceptance criteria**
- Independent-event definition is explicit and configurable (default threshold documented).
- Event-spacing diagnostic plot exists and is interpretable.
- Invariants are tested, including:
  - event counts do not exceed detection row counts,
  - increasing threshold does not increase events for identical input.

**Artefact evidence**
- `outputs/.../tables/events_*.csv` (or equivalent)
- `outputs/.../figures/event_spacing_*.png`
- Tests implementing event invariants.

**Stop condition**
- Event creation is stable, test-guarded, and produces reviewable diagnostics.

---

### WP-0.3.10 — Descriptives pack: RAI (+ uncertainty), diel summaries, rarefaction (standardised outputs)

**Outcome**  
The MVP scientific outputs exist as standardised, reproducible artefacts with documented assumptions.

**Scope**
- In: RAI definition and uncertainty; diel summaries (flash/day proxy); rarefaction.
- Out: occupancy/community inference (later).

**Acceptance criteria**
- RAI is defined explicitly (numerator, denominator, event basis) and documented.
- RAI uncertainty method is stated and produces CIs or comparable uncertainty bands.
- Diel summaries are produced with explicit limitations documented.
- Rarefaction/species accumulation artefact exists and is reproducible.
- Domain sanity tests exist:
  - non-negative values,
  - proportions sum correctly,
  - expected shapes/dimensions.

**Artefact evidence**
- `outputs/.../tables/rai_*.csv`, `diel_*.csv`, `rarefaction_*.csv` (or equivalents)
- `outputs/.../figures/rai_*.png`, `diel_*.png`, `rarefaction_*.png`
- Interpretation notes referencing these artefacts.

**Stop condition**
- The MVP outputs are coherent and defensible enough to serve as a baseline exemplar.

---

### WP-0.3.11 — MVP report as a first-class artefact (rendered via pipeline) + methods + limitations

**Outcome**  
A single report ties together data contract, QC, outputs, and interpretation. It is produced by the pipeline and is reproducible.

**Scope**
- In: Quarto/Rmd report integrated into pipeline; narrative structure; methods; limitations; links to artefacts.
- Out: manuscript polish (later).

**Acceptance criteria**
- Report renders successfully from a clean run and is placed in the canonical output folder.
- Report includes, at minimum:
  - dataset summary,
  - QC summary,
  - effort summary,
  - events definition + diagnostics,
  - descriptives outputs + interpretation,
  - limitations/assumptions section.
- Report references run manifest / provenance information.

**Artefact evidence**
- `outputs/.../report/` containing rendered report (HTML and/or PDF).
- Log entry confirming render success and basic visual inspection.

**Stop condition**
- A reviewer can read the report and understand what was done without opening code.

---

### WP-0.3.12 — CI quality gates + artefact upload (restore, lint, tests, pipeline smoke)

**Outcome**  
Quality gates run automatically. CI produces reviewable artefacts (at least the report and a minimal figure set) for each change.

**Scope**
- In: CI workflows; linting; tests; pipeline smoke; artefact upload.
- Out: heavyweight full-pipeline CI if runtime is prohibitive (can be added as nightly later).

**Acceptance criteria**
- CI runs:
  - restore dependencies,
  - lint,
  - tests,
  - a pipeline smoke run.
- CI uploads artefacts sufficient for review (report + at least one key plot).
- Failures are actionable (clear logs, no silent skips).

**Artefact evidence**
- CI configuration files present and passing on main branch.
- Log entry referencing a passing CI run.

**Stop condition**
- CI reliably blocks regressions and provides artefacts for inspection.

---

### WP-0.3.13 — “Bring your own data” guide + template dataset folder + contract checklist

**Outcome**  
A user can adapt the workflow to new data by following a checklist and using templates, without changing code.

**Scope**
- In: documentation and templates; contract checklist; common failure modes.
- Out: implementing new adapters (later).

**Acceptance criteria**
- A documented step-by-step guide exists for users to:
  - format their four tables,
  - validate them,
  - run the pipeline,
  - and interpret outputs.
- A template dataset folder (with dummy data or schemas) exists.
- Common validation errors are documented with “how to fix”.

**Artefact evidence**
- Docs pages for “Bring your own data” + templates.
- Optional: a minimal synthetic dataset used in tests to verify contract handling.

**Stop condition**
- A new user can prepare data and run the workflow without reading source code.

---

### WP-0.3.14 — Pre-occupancy prep: detection history contract + alignment checks + event-threshold sensitivity

**Outcome**  
The interface for detection histories is locked down before modeling begins, alignment checks are defined and tested, and a light sensitivity harness exists to understand event-threshold effects.

**Scope**
- In: detection history schema + alignment checks; decision on occupancy package; event-threshold sensitivity outputs.
- Out: full detection history builder and occupancy modeling (WP-0.4.x).

**Acceptance criteria**
- A documented detection history schema (columns, types, definitions).
- Alignment checks are implemented and unit-tested (no detections on inactive effort).
- A sensitivity harness produces a table + plot for event threshold effects.
- The occupancy package choice is recorded in `docs/decisions.md`.

**Artefact evidence**
- `docs/reference/detection_history_schema_v0.1.md`
- `outputs/.../tables/event_threshold_sensitivity.csv`
- `outputs/.../figures/event_threshold_sensitivity.png`

**Stop condition**
- Detection history interfaces are documented and enforced by tests; event-threshold sensitivity outputs are produced.

---

## Line 0.4.x — Beta: occupancy-ready data + single-species occupancy modelling

### WP-0.4.1 — Detection history builder (configurable occasion) + alignment checks vs effort

**Outcome**  
The pipeline produces detection/non-detection histories suitable for occupancy modelling, with explicit occasion definitions and alignment checks against effort.

**Scope**
- In: detection history outputs; occasion definition config; alignment checks.
- Out: fitting models (next WPs).

**Acceptance criteria**
- Detection histories can be generated with configurable occasion length/start.
- Histories are validated against effort:
  - no detections on inactive occasions,
  - missing effort is handled consistently and documented.
- Outputs are documented and versioned in the output schema reference.

**Artefact evidence**
- `outputs/.../tables/detection_history_*.csv` (or RDS) and metadata describing occasion definition.
- Tests verifying alignment invariants.

**Stop condition**
- Detection histories can be used as direct inputs to a standard occupancy modelling package.

---

### WP-0.4.2 — Single-species occupancy modelling interface (unmarked) + stable outputs

**Outcome**  
Single-season occupancy models can be fit in a repeatable way for exemplar species, producing stable, well-documented outputs.

**Scope**
- In: modelling interface; saved model objects; stable summary outputs.
- Out: multi-species/hierarchical community occupancy (later/decision WP).

**Acceptance criteria**
- A clear modelling contract exists:
  - how species are selected,
  - what covariates are allowed,
  - what outputs are produced.
- At least 2–3 exemplar species can be modelled end-to-end with saved outputs.
- Model failures produce clear messages (convergence, insufficient data, etc.).

**Artefact evidence**
- `outputs/.../models/occu_<species>_*.rds` (or equivalent)
- `outputs/.../tables/occu_summary_*.csv`
- Report includes a concise occupancy results section (expanded in WP-0.4.3).

**Stop condition**
- Occupancy models run reliably for exemplar species and produce interpretable summaries.

---

### WP-0.4.3 — Occupancy diagnostics + predictions + report integration

**Outcome**  
Occupancy outputs are reviewable and interpretable: diagnostics, predictions, and uncertainty are presented in artefacts and the report.

**Scope**
- In: diagnostics artefacts; prediction artefacts; report narrative.
- Out: extensive model selection workflows (next WP).

**Acceptance criteria**
- Diagnostics exist (and are documented), such as:
  - convergence/fit warnings,
  - detection probability sanity,
  - residual or goodness-of-fit proxy where appropriate.
- Predictions are produced (e.g., occupancy probability by site/covariate) with uncertainty.
- Report explains assumptions and limitations (imperfect detection, closure, sampling design).

**Artefact evidence**
- `outputs/.../figures/occu_diagnostics_*.png`
- `outputs/.../figures/occu_predictions_*.png`
- Report section updated with interpretation notes.

**Stop condition**
- A reviewer can assess whether models are trustworthy from artefacts alone.

---

### WP-0.4.4 — Sensitivity suite (occasion length + event threshold) with explicit artefacts

**Outcome**  
The workflow quantifies how sensitive occupancy outcomes are to key design choices (occasion length, event threshold), producing explicit sensitivity artefacts.

**Scope**
- In: sensitivity runs; comparison tables/plots; interpretation notes.
- Out: broad parameter sweeps beyond a small, purposeful set.

**Acceptance criteria**
- Sensitivity artefacts exist comparing at least:
  - two occasion definitions,
  - and two event thresholds (including the default).
- Results are summarised and interpreted (what changes, what is stable).

**Artefact evidence**
- `outputs/.../tables/sensitivity_*.csv`
- `outputs/.../figures/sensitivity_*.png`
- Interpretation notes explicitly discuss implications.

**Stop condition**
- Key modelling decisions are defended with empirical sensitivity evidence.

---

### WP-0.4.5 — Model comparison outputs (AIC tables / candidate set discipline) + guardrails

**Outcome**  
Model comparison is disciplined and reproducible: candidate sets are explicit, outputs are stable, and guardrails prevent p-hacking-by-default.

**Scope**
- In: candidate set specification; AIC summaries; guardrails and documentation.
- Out: exhaustive automated search.

**Acceptance criteria**
- Candidate model sets are explicit and documented (what is compared and why).
- AIC (or equivalent) summary tables are produced as artefacts.
- Guardrails exist (e.g., minimum data requirements per covariate, warnings for over-parameterisation).
- Report includes a short “model comparison policy” statement.

**Artefact evidence**
- `outputs/.../tables/model_comparison_*.csv`
- Report section updated with candidate set explanation.

**Stop condition**
- Model comparison outputs are reproducible and do not encourage uncontrolled fishing.

---

### WP-0.4.6 — Decide on “advanced occupancy” track (spOccupancy / ubms): adopt vs defer (Decision WP)

**Outcome**  
A recorded decision about whether to include a more advanced occupancy framework (e.g., spOccupancy multispecies or ubms Bayesian single-species) in-scope for v1.0.

**Scope**
- In: evaluate feasibility, runtime, robustness, pedagogical value, and CI implications.
- Out: implementing advanced models in this WP.

**Acceptance criteria**
- A decision is recorded in `docs/decisions.md` with clear rationale and consequences.
- If adopted:
  - a new WP is added in the next line describing the implementation in testable terms.
- If deferred:
  - document what would be needed to un-defer later.

**Artefact evidence**
- Decision entry + log entry referencing evaluation inputs (e.g., package docs, minimal trial outcomes).

**Stop condition**
- The project has a clear stance: adopt now with bounded scope, or defer with a clear path.

---

## Line 0.5.x — Community & traits: diversity + functional ecology

### WP-0.5.1 — Community matrices (presence/abundance) derived from events + validated outputs

**Outcome**  
Stable community matrices are produced from event-based data, enabling downstream diversity analyses.

**Scope**
- In: matrix generation; presence vs abundance variants; validation.
- Out: network/co-occurrence inference (later, optional).

**Acceptance criteria**
- Community matrices exist in at least two forms:
  - presence/absence,
  - event-based abundance (documented definition).
- Matrices are validated (dimensions, non-negativity, site/species alignment).
- Output schema docs updated accordingly.

**Artefact evidence**
- `outputs/.../tables/community_matrix_pa_*.csv`
- `outputs/.../tables/community_matrix_abund_*.csv`
- Tests verifying invariants.

**Stop condition**
- Matrices can be consumed by standard diversity functions without manual reshaping.

---

### WP-0.5.2 — Alpha diversity outputs + site summaries + report integration

**Outcome**  
Alpha diversity is summarised per site (and optionally per habitat grouping), with clear artefacts and interpretation.

**Scope**
- In: richness and alpha indices outputs; summary plots; report narrative.
- Out: complex hierarchical diversity models.

**Acceptance criteria**
- At least two alpha metrics are produced and documented (e.g., richness + Shannon).
- Outputs include tables and plots.
- Domain sanity checks exist (non-negative, expected ranges).

**Artefact evidence**
- `outputs/.../tables/alpha_diversity_*.csv`
- `outputs/.../figures/alpha_diversity_*.png`
- Report section with interpretation notes.

**Stop condition**
- Alpha diversity results are coherent and reproducible from community matrices.

---

### WP-0.5.3 — Beta diversity + distance–decay artefacts + sanity tests

**Outcome**  
Beta diversity and spatial turnover are quantified and visualised with defensible checks.

**Scope**
- In: dissimilarity matrices; distance–decay plots; basic ordination if stable.
- Out: advanced spatial modelling of turnover.

**Acceptance criteria**
- Beta diversity matrix exists (method documented).
- Distance–decay artefact exists linking compositional dissimilarity to spatial distance (with caveats).
- Sanity checks ensure matrix symmetry and valid ranges.

**Artefact evidence**
- `outputs/.../tables/beta_diversity_matrix_*.csv`
- `outputs/.../figures/distance_decay_*.png`
- Tests validating matrix properties.

**Stop condition**
- A reviewer can verify that turnover analyses are computed correctly and interpretable.

---

### WP-0.5.4 — Trait table cleaning/alignment + trait reference + test coverage

**Outcome**  
The taxa/trait table becomes a reliable input for functional and trait–environment analyses.

**Scope**
- In: trait cleaning rules; missingness policy; alignment with species codes; trait reference docs.
- Out: complex imputation (unless explicitly chosen and documented).

**Acceptance criteria**
- Trait alignment is validated (species codes match observation codes).
- Trait missingness is summarised and documented.
- Tests cover alignment and key trait constraints (types, allowed levels).

**Artefact evidence**
- `outputs/.../tables/trait_qc_*.csv`
- Trait reference doc (definitions, units, allowed values).
- Tests for alignment and missingness reporting.

**Stop condition**
- Trait data is “analysis-ready” with transparent limitations.

---

### WP-0.5.5 — Functional diversity indices outputs (e.g., FDis/FRic/etc.) + interpretation notes

**Outcome**  
Functional diversity indices are computed reproducibly from trait and community matrices, producing stable outputs and interpretation.

**Scope**
- In: functional diversity indices; tables/plots; interpretation.
- Out: bespoke indices without clear justification.

**Acceptance criteria**
- At least two functional diversity metrics are produced and documented.
- Outputs include per-site summaries and at least one diagnostic (e.g., trait space coverage / missingness impact).
- Interpretation notes explicitly state assumptions and data limitations.

**Artefact evidence**
- `outputs/.../tables/functional_diversity_*.csv`
- `outputs/.../figures/functional_diversity_*.png`
- Interpretation notes updated.

**Stop condition**
- Functional diversity outputs are reproducible and defensible for the exemplar.

---

### WP-0.5.6 — Trait–environment association method (RLQ/fourth-corner or stable alternative) + artefacts

**Outcome**  
A trait–environment hypothesis test/association method is implemented with clear inputs/outputs and interpretation.

**Scope**
- In: one primary method (RLQ/fourth-corner or a stable alternative); artefacts; docs.
- Out: multiple competing methods in parallel.

**Acceptance criteria**
- Method choice is documented and justified.
- Inputs to the method are explicitly defined (site covariates, trait matrix, community matrix).
- Outputs include:
  - a main results table,
  - a visual summary,
  - and an interpretation section explaining what can/cannot be inferred.

**Artefact evidence**
- `outputs/.../tables/trait_env_results_*.csv`
- `outputs/.../figures/trait_env_summary_*.png`
- Report includes limitations (multiple testing, dependence, etc.).

**Stop condition**
- Trait–environment results are produced and interpreted with appropriate caveats.

---

## Line 0.6.x — Interoperability & pedagogy

### WP-0.6.1 — WildObsR evaluation for this repo (matrix generation / Camtrap DP) + adopt/defer decision

**Outcome**  
A clear, recorded decision about whether and how to integrate WildObsR into this workflow (as an adapter and/or as matrix-generation backend).

**Scope**
- In: evaluate WildObsR capabilities relevant to this repo:
  - Camtrap DP schema validation,
  - detection matrix generation for occupancy,
  - covariate generation utilities.
- Out: full integration (next WP).

**Acceptance criteria**
- Decision recorded in `docs/decisions.md` addressing:
  - benefits (time saved, standardisation),
  - risks (dependency weight, API stability),
  - fit with this repo’s four-table contract.
- If adopting:
  - specify which surfaces are integrated (ingestion only? matrix generation only? both?).
- If deferring:
  - specify why and what would change the decision.

**Artefact evidence**
- Decision entry + log entry referencing evaluation evidence (small prototype outcomes allowed, but not required here).

**Stop condition**
- The project has a clear integration stance with explicit boundaries.

---

### WP-0.6.2 — Camtrap DP ingestion adapter (via WildObsR and/or frictionless) (Large)

**Outcome**  
The workflow can ingest a Camtrap DP dataset and convert it into the internal contract (or operate directly on DP resources), producing equivalent MVP artefacts.

**Scope**
- In: ingestion path; mapping to internal schema; validation; documentation.
- Out: pulling media files by default (should be optional), and building a full data portal.

**Acceptance criteria**
- At least one Camtrap DP example dataset can be ingested and run through MVP outputs.
- Adapter mapping is documented and test-covered.
- Schema_version policy clearly addresses DP→internal mapping.

**Artefact evidence**
- Adapter docs and mapping reference.
- Tests for at least one DP ingestion scenario.
- Artefacts showing MVP outputs from DP ingestion.

**Stop condition**
- DP ingestion produces the same class of outputs as four-table mode, with transparent mapping.

---

### WP-0.6.3 — Optional: Camtrap DP export (publish-ready package) (Large)

**Outcome**  
The workflow can export (or package) its cleaned/standardised data into Camtrap DP for sharing/publishing, including validation.

**Scope**
- In: export mapping; validation; documentation.
- Out: automated GBIF publication steps.

**Acceptance criteria**
- Export produces a valid Camtrap DP (validated by an available validator).
- Mapping rules are documented and versioned.
- Export includes required metadata fields or a documented minimal subset.

**Artefact evidence**
- Exported DP folder/package in outputs (not committed to repo).
- Validation evidence (logs + output).

**Stop condition**
- A user can produce a standards-compliant DP package for sharing.

---

### WP-0.6.4 — Teaching module: guided exercises + “change params → observe outputs” harness

**Outcome**  
The repo becomes pedagogically useful: guided exercises allow learners to explore parameter impacts and modelling choices.

**Scope**
- In: a small number of exercises tied to MVP/Beta/Community outputs; docs; expected outcomes.
- Out: full courseware.

**Acceptance criteria**
- At least 5 guided exercises exist with:
  - a “what you change” instruction,
  - expected qualitative outcomes,
  - and where to find evidence artefacts.
- Exercises cover at least:
  - event threshold,
  - effort censoring implications,
  - an occupancy modelling choice,
  - and a community/trait choice.

**Artefact evidence**
- Teaching module docs section.
- Optional: an “exercise run” output bundle demonstrating expected outcomes.

**Stop condition**
- A student can learn by making controlled changes and observing outputs.

---

### WP-0.6.5 — Reproducibility benchmark: cold-run protocol + runtime notes + CI strategy for heavy runs

**Outcome**  
The repo documents and enforces reproducibility under realistic conditions, including runtime expectations and CI strategy for heavy computations.

**Scope**
- In: benchmark protocol; runtime notes; CI plan (smoke vs nightly).
- Out: performance micro-optimisation.

**Acceptance criteria**
- A documented “cold run” protocol exists and is repeatable.
- Runtime and memory expectations are recorded for exemplar.
- CI strategy explicitly distinguishes:
  - fast checks (PR),
  - heavier runs (nightly or manual).

**Artefact evidence**
- Benchmark docs and logs showing at least one cold run result.

**Stop condition**
- Reproducibility expectations are explicit and operational.

---

## Line 0.7.x — Release + manuscript readiness

### WP-0.7.1 — Release discipline: versioning, changelog, citation, release artefact bundle definition

**Outcome**  
The project can ship releases with consistent artefacts and clear provenance, and can be cited correctly.

**Scope**
- In: version policy; changelog policy; citation file; release artefact definition.
- Out: public repository governance beyond this project.

**Acceptance criteria**
- Versioning policy is explicit (semver).
- Changelog exists and is maintained.
- Citation metadata exists (e.g., CITATION file) and is documented.
- Release artefact bundle definition is explicit (what is included for each release).

**Artefact evidence**
- Updated docs + files for versioning/changelog/citation.
- Release checklist aligns with evidence requirements.

**Stop condition**
- A release can be cut without ambiguity about what “done” means.

---

### WP-0.7.2 — Container recipe (Docker or equivalent) (Large)

**Outcome**  
A containerised run is possible: users can build/run a container to reproduce the pipeline outputs without local dependency pain.

**Scope**
- In: container recipe; documentation; proof-of-run.
- Out: multi-arch optimisation and registry publishing.

**Acceptance criteria**
- Container build is documented and reproducible.
- Running the container can produce the canonical outputs for exemplar.
- Container run produces the same manifest/session info structure as native runs.

**Artefact evidence**
- Container recipe files.
- Logs and outputs demonstrating a successful container run.

**Stop condition**
- Containerised reproducibility is proven end-to-end.

---

### WP-0.7.3 — Methods manuscript skeleton (Quarto) tied to pipeline artefacts + figures/tables mapping

**Outcome**  
A manuscript scaffold exists that directly maps methods/results to pipeline artefacts, making the “methods paper” arc clear.

**Scope**
- In: manuscript skeleton; figure/table mapping; methods text placeholders with citations.
- Out: final writing polish.

**Acceptance criteria**
- Manuscript structure exists (Intro/Methods/Results/Discussion/Supplement).
- Each major result references a pipeline artefact (table/figure) and defines how it is produced.
- Methods explicitly define:
  - event definition,
  - effort standardisation,
  - RAI,
  - occupancy approach (if Beta complete),
  - community/trait approaches (if complete).

**Artefact evidence**
- Manuscript source file(s) in repo.
- Mapping table between manuscript figures/tables and output artefact paths.

**Stop condition**
- The manuscript arc is unambiguous and grounded in reproducible artefacts.

---

### WP-0.7.4 — End-to-end “new dataset” dry run (template → run → report) with documented failure modes

**Outcome**  
The workflow is demonstrated on a second dataset (synthetic or real) using the documented “bring your own data” path, and failure modes are documented.

**Scope**
- In: a second dataset run; capturing and documenting errors and resolutions; updating docs.
- Out: broad benchmarking across many datasets.

**Acceptance criteria**
- A second dataset can run through at least MVP outputs.
- If issues arise, they are documented and resolved (or documented as limitations).
- Documentation is updated to reflect discovered pitfalls.

**Artefact evidence**
- A run bundle (not committed) and a log entry summarising the new dataset run.
- Updated “bring your own data” docs with new failure-mode guidance.

**Stop condition**
- The repo proves it is not “Judbury-only”.

---

### WP-0.7.5 — Tag v1.0 readiness gate: final QC, docs completeness, and evidence checklist

**Outcome**  
A final readiness assessment ensures v1.0 is truly reproducible, documented, and scientifically coherent.

**Scope**
- In: final QC pass; docs completeness; evidence checklist completion.
- Out: adding new features.

**Acceptance criteria**
- All required WPs for v1.0 scope are complete (or explicitly deferred with rationale).
- Release checklist is satisfied with concrete evidence artefacts.
- A PI-readable summary is produced: “what v1.0 includes, and what it intentionally does not include”.

**Artefact evidence**
- Completed checklist + summary log entry + final run bundle evidence.

**Stop condition**
- v1.0 can be tagged with high confidence and minimal surprises.

---

## 5) Milestone / review gates (when to stop and request a PI review ZIP)

Codex must stop and request a **PI review ZIP** when any of the following triggers occurs:

1) **End of a line/milestone**: upon completing all WPs in 0.3.x, 0.4.x, 0.5.x, 0.6.x, or 0.7.x.
2) **Large WP completed**: immediately after any WP marked **(Large)**.
3) **Schema boundary**: immediately after any WP that bumps `schema_version` or introduces a migration.
4) **Autonomy cadence**: after completing **6 WPs** without a PI review ZIP, even if mid-line.
5) **Major scientific interpretation risk**: if artefact review reveals outputs that seem scientifically incoherent (e.g., obvious time-shift artefacts, impossible effort/detection relationships), stop and request PI review with evidence.

The PI review ZIP must include:
- updated roadmap checkboxes,
- `docs/log/` entries for completed WPs,
- any new decisions in `docs/decisions.md`,
- and a canonical run folder under `outputs/` showing evidence artefacts (or a pointer to where it was generated if outputs are gitignored and bundled separately).

---

## References (for context; not requirements)

- WildObsR (Camtrap DP support, matrix generation for occupancy, schema validation): https://github.com/WildObs/WildObsR
- Camtrap DP standard (Frictionless Data Package for camera trap data): https://camtrap-dp.tdwg.org/
- GBIF camera trap best practices guide: https://docs.gbif.org/camera-trap-guide/en/
- camtrapR (detection history tooling, broader camera-trap workflow ecosystem): https://cran.r-project.org/package=camtrapR
- Camtrap DP paper (open standard for FAIR exchange): https://zslpublications.onlinelibrary.wiley.com/doi/10.1002/rse2.374

---

## Roadmap v2 (mirror status)

See `docs/roadmap_v2.md` for full WP specs. Status mirrored here for completion tracking.

- [x] WP-0.7.1.1 — Re-enable CI with required system deps
- [x] WP-0.7.1.2 — Fix pooled RAI denominator + align report definition
- [x] WP-0.7.1.3 — Fix occupancy summary p missingness + define semantics
- [x] WP-0.7.1.4 — Make run manifests portable + document real schema
- [x] WP-0.7.1.5 — Camtrap DP export: DST-gap handling and auditable drop log
- [x] WP-0.7.1.6 — Apply human data assumptions (fixed offset + diel method + report ordering)
- [x] WP-0.7.1.7 — Spatial overlay map (interpolated terrain/veg context)
- [x] WP-0.8.0.1 — Fresh-clone reproducibility verification (clean machine or container)
- [x] WP-0.8.0.2 — Release-candidate artefacts regenerated from the RC commit
- [x] WP-0.8.0.3 — Update v1 readiness gate with evidence + close outstanding items
- [x] WP-0.9.0.1 — Methods manuscript: fill critical methodological sections and citations
- [x] WP-0.9.0.2 — Report interpretation: add what to conclude / what not to conclude panels
- [x] WP-0.9.0.3 — BYO-data robustness: add one additional non-Judbury example dataset
- [x] WP-0.9.1.1 — Occupancy diagnostics surfaced
- [x] WP-0.9.1.2 — Replace psi CI method + fix summary semantics
- [x] WP-0.9.1.3 — Forest example updated to non-degenerate occupancy
- [x] WP-0.9.1.4 — Report/manuscript provenance path sanitization
- [x] WP-0.9.1.5 — Release docs sync
- [x] WP-0.9.1.6 — Exploratory summaries from legacy Camelot ideas
