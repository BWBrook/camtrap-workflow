# Roadmap v2 (post–0.7.0 PI review)

This roadmap extends the completed 0.3–0.7 lines with a short hardening line and a v1.0 release candidate line.

## 1) Opening contract

When the human says **“Follow the roadmap”**, Codex must:

1) Pick the **first unchecked Work Package (WP)** in the **Priority Queue** (strict order).
2) Complete it **end-to-end** (code + tests + docs + artefacts) to WP-DoD.
3) Produce the required evidence in the repo, then **mark the WP checkbox as complete**.
4) Proceed to the next unchecked WP.

Reordering priorities is allowed **only** if:
- a rationale is recorded in `docs/decisions.md`, and
- a log entry is added to `docs/log/` documenting what changed and why.

If the Priority Queue is empty, Codex **stops** and reports that more work must be promoted.

## 2) Work Package Definition of Done (WP‑DoD)

A WP is done only when all of the following are true:

- **Acceptance criteria** are met and tested.
- **Docs are updated**, at minimum:
  - configuration/reference updates (what knobs exist and what they mean),
  - interpretation of outputs + assumptions/limitations relevant to the WP.
- **Artefact Review Cycle** is completed and logged:
  - build/run artefacts exist (as applicable),
  - canonical run artefact folder(s) exist,
  - sanity inspection notes are written to `docs/interpretation_notes.md` (or a WP-specific log note).
- If **schema changes**: bump `schema_version.txt` + add migration + migration tests.
- If **output schema changes**: document it + add regression/sanity tests that lock it.

## 3) Priority Queue

### Line 0.7.1 — Hardening + correctness patch (must-fix before v1.0)

- [x] **WP-0.7.1.1 — Re-enable CI with required system deps**
- [x] **WP-0.7.1.2 — Fix pooled RAI denominator + align report definition**
- [x] **WP-0.7.1.3 — Fix occupancy summary `p` missingness + define semantics**
- [x] **WP-0.7.1.4 — Make run manifests portable + document real schema**
- [x] **WP-0.7.1.5 — Camtrap DP export: DST-gap handling and auditable drop log**

### Line 0.8.0 — v1.0 release candidate gate

- [ ] **WP-0.8.0.1 — Fresh-clone reproducibility verification (clean machine or container)**
- [ ] **WP-0.8.0.2 — Release-candidate artefacts regenerated from the RC commit**
- [ ] **WP-0.8.0.3 — Update v1 readiness gate with evidence + close outstanding items**

### Line 0.9.0 — Methods manuscript + “paper-ready” polish (optional but recommended)

- [ ] **WP-0.9.0.1 — Methods manuscript: fill critical methodological sections and citations** *(large)*
- [ ] **WP-0.9.0.2 — Report interpretation: add “what to conclude / what not to conclude” panels**
- [ ] **WP-0.9.0.3 — BYO-data robustness: add one additional non-Judbury example dataset** *(large)*

## 4) Detailed Work Package specs

---

## WP-0.7.1.1 — Re-enable CI with required system deps

**Outcome**  
CI runs automatically on PR/push and enforces the repo’s quality gates, including system dependencies required by the dependency stack.

**Scope**
- In-scope:
  - CI enabled for lint + tests + a minimal pipeline smoke.
  - System deps installed in CI runner (or CI runs in the repo’s container).
  - CI produces an auditable log/artifact on failure.
- Out-of-scope:
  - Full exemplar `tar_make()` on every PR (allowed only if runtime is acceptable or on a scheduled/manual workflow).

**Acceptance criteria**
- CI is enabled and runs on PR/push to main.
- CI passes on a clean runner with:
  - lint green,
  - unit tests green,
  - minimal pipeline smoke green.
- Failures are actionable (logs clearly identify missing deps vs R errors vs test failures).

**Artefact evidence**
- A CI workflow file exists and is active (not disabled).
- A successful CI run is visible for the current commit.
- `docs/v1_readiness.md` updated: CI no longer listed as disabled.

**Stop condition**
- CI is green for at least one PR or push on the current mainline state.

---

## WP-0.7.1.2 — Fix pooled RAI denominator + align report definition

**Outcome**  
The pooled Relative Abundance Index (RAI) uses a denominator consistent with the stated definition and standard interpretation: events per trap night across the surveyed effort.

**Scope**
- In-scope:
  - `rai_species.csv` uses a denominator that reflects total included effort (not detection-only sites).
  - Documentation and report text match the implemented definition.
  - Regression tests lock the semantics.
- Out-of-scope:
  - New modelling approaches for abundance (N-mixture, SCR, etc.).

**Acceptance criteria**
- `outputs/.../tables/rai_species.csv` has trap_nights that are constant across species for a given run (equal to total effort of included sites).
- If a “detected-sites-only” RAI is retained, it is:
  - explicitly named as such,
  - documented in reference docs and report text,
  - not confused with pooled survey RAI.
- Tests fail if pooled RAI ever returns species-varying denominators again.

**Artefact evidence**
- Updated RAI tables in `outputs/runs/latest/tables/`.
- Updated `analysis/report.qmd` (or report text) describing the correct definition.
- Updated `docs/reference/output_schema_v0.1.md` if any output semantics changed.

**Stop condition**
- Pooled RAI definition and implementation are aligned, and tests cover the invariant.

---

## WP-0.7.1.3 — Fix occupancy summary `p` missingness + define semantics

**Outcome**  
Occupancy summary outputs are internally consistent and never silently produce missing detection probability summaries.

**Scope**
- In-scope:
  - `occupancy_summary.csv` contains valid, non-missing detection probability summaries OR explicitly documents when scalar p is not reported.
  - Tests enforce the chosen rule.
  - Report interpretation updated if needed.
- Out-of-scope:
  - Switching to advanced occupancy frameworks (spOccupancy/ubms) (explicitly deferred).

**Acceptance criteria**
- For each exemplar species in `occupancy_species`, `occupancy_summary.csv` has:
  - `psi`, `psi_lower`, `psi_upper` present and within [0, 1],
  - `p`, `p_lower`, `p_upper` present and within [0, 1], OR an explicitly documented rule for when p is not scalar (and then p/p_lower/p_upper are consistently omitted/NA).
- Tests detect the prior failure mode (p becoming NA due to summarisation/NA-handling).

**Artefact evidence**
- Updated `outputs/runs/latest/tables/occupancy_summary.csv`.
- Updated `docs/interpretation_notes.md` with a note about the new semantics and any changes in interpretation.

**Stop condition**
- Occupancy summary is stable and semantically explicit; tests lock it.

---

## WP-0.7.1.4 — Make run manifests portable + document real schema

**Outcome**  
Run manifests are portable across machines, clearly specify provenance, and have reference documentation that matches the actual schema.

**Scope**
- In-scope:
  - Run manifest paths are relative (repo-relative or run-relative), not absolute local filesystem paths.
  - Manifest schema documented in `docs/reference/run_manifest.md` (no longer “placeholder”).
  - Manifest includes enough provenance to reproduce runs (config identity, schema version, timestamp, git hash when available).
- Out-of-scope:
  - Building a full provenance graph for all targets (beyond the current manifest scope).

**Acceptance criteria**
- No manifest contains absolute paths (e.g., `/home/...`) for run outputs.
- `docs/reference/run_manifest.md` documents the actual manifest fields and interpretation rules.
- Tests enforce “no absolute paths” and presence of required fields.

**Artefact evidence**
- Updated `outputs/runs/latest/run_manifest.json` (and other example runs as relevant).
- Updated `docs/reference/run_manifest.md`.
- Updated tests that validate manifest invariants.

**Stop condition**
- Manifest docs match reality; path portability invariant is enforced by tests.

---

## WP-0.7.1.5 — Camtrap DP export: DST-gap handling and auditable drop log

**Outcome**  
Camtrap DP export is auditable when timestamps cannot be represented in local time (DST gaps) and does not silently discard records.

**Scope**
- In-scope:
  - Handle DST-gap timestamps explicitly by either:
    - converting via a UTC parse fallback, or
    - dropping with an explicit, saved audit log (count + example rows/IDs + reason).
  - Ensure the export folder contains provenance and the audit evidence.
  - Documentation updated.
- Out-of-scope:
  - Perfect automatic correction of camera clock drift/reset (only flagging/auditing required here).

**Acceptance criteria**
- Export run produces a durable, reviewable record of any dropped/adjusted observations:
  - audit file exists in the export output folder, and/or validation text includes the counts.
- `docs/PI_review_cover.md` and any export docs match the behaviour.

**Artefact evidence**
- Export artefact folder includes:
  - datapackage outputs,
  - validation output,
  - audit evidence for DST-gap/drop handling.
- Tests cover the DST-gap scenario (at least at the unit-test level).

**Stop condition**
- Export is auditable and behaviour is documented; no silent dropping.

---

## WP-0.8.0.1 — Fresh-clone reproducibility verification (clean machine or container)

**Outcome**  
A cold run from a clean environment is demonstrated and recorded as evidence, reducing “works on my machine” risk.

**Scope**
- In-scope:
  - Run protocol executed from a clean environment (container or fresh clone).
  - Evidence recorded and linked in docs.
- Out-of-scope:
  - Optimising runtime further unless regressions are found.

**Acceptance criteria**
- The cold-run protocol succeeds end-to-end and produces the canonical outputs.
- Evidence is recorded in `docs/reproducibility_benchmark.md` (date, environment, run time, any warnings).

**Artefact evidence**
- Updated benchmark doc.
- Updated manifests/session info for the fresh run.

**Stop condition**
- A reproducibility record exists for a clean environment run.

---

## WP-0.8.0.2 — Release-candidate artefacts regenerated from the RC commit

**Outcome**  
The release candidate is internally consistent: artefacts correspond exactly to the repo state being released.

**Scope**
- In-scope:
  - Regenerate exemplar outputs from the RC commit.
  - Ensure manifests reflect the RC commit identity.
- Out-of-scope:
  - Publishing releases to registries (human maintainer task).

**Acceptance criteria**
- Example run artefacts are regenerated and match the current code behaviour.
- Manifests and docs reflect the RC commit.

**Artefact evidence**
- Updated `outputs/runs/latest/` and other example runs (as required).
- Updated `docs/release_bundle.md` if the bundle contents changed.

**Stop condition**
- Artefacts and commit state are aligned and auditable.

---

## WP-0.8.0.3 — Update v1 readiness gate with evidence + close outstanding items

**Outcome**  
`docs/v1_readiness.md` becomes a true release gate with all items either complete or explicitly deferred.

**Scope**
- In-scope:
  - Update v1 readiness list and evidence summary.
  - Close or defer items with explicit rationale in `docs/decisions.md`.
- Out-of-scope:
  - New features not required for release.

**Acceptance criteria**
- v1 readiness outstanding list is empty or has explicitly deferred items with decisions logged.
- CI is enabled and listed as passing.
- Questions for human are either answered or explicitly defaulted with a decision.

**Artefact evidence**
- Updated `docs/v1_readiness.md`.
- Updated `docs/decisions.md` if defaults/deferments were chosen.

**Stop condition**
- v1 readiness gate is satisfied for the intended release scope.

---

## WP-0.9.0.1 — Methods manuscript: fill critical methodological sections and citations (large)

**Outcome**  
The methods manuscript becomes sufficient to support a real methods/results submission: complete methodological description tied to pipeline artefacts.

**Scope**
- In-scope:
  - Expand methods text for: data contract, event definition, effort handling, RAI, occupancy modelling, diversity metrics, trait/functional diversity.
  - Add citations and explicit limitations.
  - Ensure manuscript outputs render reproducibly from the pipeline.
- Out-of-scope:
  - Writing the full discussion/results narrative (can be separate later).

**Acceptance criteria**
- Methods manuscript renders cleanly (HTML+PDF) and is meaningfully complete (no major placeholders).
- All major pipeline outputs referenced in the manuscript are produced and linked to artefacts.
- Citations are present for key methodological choices.

**Artefact evidence**
- Updated `analysis/methods.qmd` plus rendered outputs in `outputs/runs/latest/manuscript/`.
- Interpretation notes updated with any new methodological implications.

**Stop condition**
- Methods document is “submission-grade” for methods section completeness.

---

## WP-0.9.0.2 — Report interpretation: add “what to conclude / what not to conclude” panels

**Outcome**  
The report actively prevents misinterpretation by stating valid conclusions and limitations adjacent to key plots/tables.

**Scope**
- In-scope:
  - Add short interpretation panels for RAI, occupancy, diversity, traits.
  - Include warnings around unknown taxa, DST issues, effort heterogeneity, and event threshold sensitivity.
- Out-of-scope:
  - Additional analyses beyond interpretation.

**Acceptance criteria**
- Report contains explicit interpretation guidance for major sections.
- Limitations match actual implementation choices and logged known issues.

**Artefact evidence**
- Updated `outputs/runs/latest/report/` with updated rendered report.
- Updated `docs/interpretation_notes.md`.

**Stop condition**
- Report is safer and more self-explanatory for non-expert users.

---

## WP-0.9.0.3 — BYO-data robustness: add one additional non-Judbury example dataset (large)

**Outcome**  
The workflow demonstrates portability: at least one additional dataset runs end-to-end without Judbury-specific assumptions.

**Scope**
- In-scope:
  - Add a small example dataset (or synthetic but realistic) in the four-table contract.
  - Add a config for it and run it through the pipeline.
  - Document any edge cases discovered.
- Out-of-scope:
  - Supporting every camera trap schema under the sun.

**Acceptance criteria**
- New example dataset runs end-to-end and produces outputs.
- Documentation describes differences/assumptions relative to Judbury.

**Artefact evidence**
- New dataset files under `data/` (or a separate example data directory).
- New outputs under `outputs/runs/<example_id>/`.
- Updated docs describing how/why this example is representative.

**Stop condition**
- A second dataset proves portability and surfaces generalizable failure modes.
