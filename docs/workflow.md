# Workflow: Artefact Review Cycle

This document specifies how development and scientific output validation must be done in this repository.
Code that runs is not enough. Outputs must be technically correct, reproducible, and ecologically coherent.

## 1) When this workflow applies

Apply the workflow whenever you:
- change data ingestion / QC logic,
- change the definition of effort, events, or derived tables,
- add or modify an analysis method (metrics, models, diversity),
- or produce a new report section and associated artefacts.

## 2) Standard iteration loop (engineering + science)

### Step A — Plan
- Update `docs/roadmap.md` if priorities changed.
- Create/append a log entry under `docs/log/` describing:
  - the intended change,
  - expected artefacts,
  - and expected sanity checks.

### Step B — Implement
- Implement in small increments.
- Keep functions modular and testable.
- Avoid hard-coded parameters outside the central configuration.

### Step C — Build artefacts
Run the pipeline (or relevant subset) to generate artefacts.

Expected artefacts (by milestone):
- MVP:
  - QC summaries
  - effort plots
  - event-spacing plot
  - RAI table + plot
  - diel table + plot
  - rarefaction plot
  - rendered report
- Beta:
  - detection histories
  - occupancy model objects + summaries + plots
- 1.0:
  - community matrices
  - alpha/beta diversity outputs
  - functional diversity outputs

### Step D — Sanity checks (domain + technical)
Sanity checks must be explicit, not implicit.

#### Technical sanity
- No errors or warnings that indicate partial failure.
- No `NA` explosions or silent row drops without explanation.
- Outputs written where expected; filenames stable.

#### Domain sanity (examples)
Effort:
- Total effort per site is non-negative and plausible.
- Effort coverage matches input date ranges.

Events:
- Increasing the event threshold should not increase the number of independent events for identical input.
- Event counts should be less than or equal to raw detection row counts.

RAI:
- RAI values are non-negative.
- Species with zero events have zero RAI.

Diel:
- Proportions sum to 1 within grouping units.
- If using flash as a night proxy, document its limitations.

Occupancy (Beta+):
- Detection histories align with effort (no detections on inactive days).
- Model convergence diagnostics are checked and surfaced.

Encode as:
- unit tests (`tests/testthat/`),
- or dedicated sanity scripts under `tests/` if they are more integration-like.

### Step E — Interpretation (mandatory “lab notebook” step)
For each major artefact (figure/table/model output):
- Add a short section to `docs/interpretation_notes.md` (create if missing) with:
  - Artefact ID and path (e.g., `outputs/figures/rai_species.png`)
  - 2–5 bullets:
    - what it shows,
    - what it suggests,
    - what looks surprising or concerning,
    - next questions.

This is required even if results “look fine”.

### Step F — Iterate
- If sanity fails: fix logic/tests, rebuild.
- If interpretation raises questions: add follow-up tasks to roadmap, implement, rebuild.
- Stop only when artefacts are coherent and tests capture the main assumptions.

## 3) Quality gates before a PI review ZIP

Before handing a snapshot back for PI review:
- `renv.lock` is updated and complete
- lint passes (`Rscript scripts/run_lint.R`)
- tests pass (`Rscript scripts/run_tests.R`)
- tests pass locally
- lint is clean (or documented exceptions)
- pipeline runs end-to-end on exemplar data
- `docs/log/` has an entry summarising what changed
- `docs/decisions.md` reflects any major decisions
- `docs/interpretation_notes.md` exists and has notes for new/changed artefacts

## 4) Artefact checklist (what to inspect)

For each run, the agent must inspect:
- Rendered report (does it render? do figures show?)
- Key plots:
  - effort summaries
  - event-spacing
  - RAI (species and site)
  - diel summaries
  - rarefaction
- Key tables:
  - QC outputs (counts, missingness, exclusions)
  - trap effort summaries
  - events_per_day summaries
- Model summaries (Beta+):
  - convergence
  - parameter estimates
  - predicted occupancy/detection

Record findings in `docs/interpretation_notes.md` and/or the phase log.

## 5) Relationship to other docs

- `docs/product_brief.md` defines what we are building and what is out of scope.
- `docs/architecture.md` describes modules, interfaces, and data flow.
- `docs/roadmap.md` defines milestones and priorities.
- `docs/decisions.md` records key irreversible choices.
- `docs/release_checklist.md` defines what must be true before tagging a release.
