# General plan

This outlines a general plan for development. It is a precis of the detailed living plan for camtrap-workflow in `docs/roadmap.md`. 
It is organised into milestones with explicit stop conditions to prevent scope creep.

## Milestones

### Milestone 1 — MVP: reproducible descriptive workflow
Goal: from validated tables to core descriptive artefacts + report, reproducibly.

Deliverables:
- Locked environment (`renv.lock` populated)
- Data contract + QC layer with clear errors
- Effort processing and independent events (configurable)
- Descriptive outputs:
  - effort summary plots (histogram + calendar/heatmap)
  - RAI (with uncertainty)
  - diel activity summaries
  - rarefaction/species accumulation plot
- Targets-rendered report with interpretation
- Tests + lint baseline
- CI that runs restore + lint + tests + pipeline smoke test

Stop condition:
- A fresh clone can run `renv::restore()` then `targets::tar_make()` and obtain coherent outputs and a report, with CI green.

### Milestone 2 — Beta: population-level inference
Goal: occupancy modelling outputs suitable for ecological interpretation.

Deliverables:
- Detection history builder (occasion definition configurable)
- Single-species occupancy models (unmarked) for selected exemplar species
- Model summaries, diagnostics, predictions and plots
- Extended report sections on occupancy assumptions and limitations
- Additional domain sanity checks (convergence, alignment with effort)

Stop condition:
- At least 2–3 exemplar species produce stable, interpretable occupancy results with diagnostics included in the report.

### Milestone 3 — 1.0: community + traits + generalisable workflow
Goal: community and trait-informed analyses + teaching-friendly exemplar.

Deliverables:
- Community metrics:
  - alpha diversity per site
  - beta diversity matrix + distance–decay
  - optional co-occurrence/network analysis (only if stable and documented)
- Trait & functional diversity:
  - trait cleaning + alignment
  - functional diversity indices + plots
  - at least one trait–environment association method
- Optional adapter for Camtrap DP / WildObsR ingestion
- Pedagogical hooks: guided exercises that modify config and re-run
- Hardened docs, release checklist, tagged v1.0 release artefacts

Stop condition:
- A new dataset that conforms to the contract can be analysed end-to-end with comparable outputs, without changing code.

## Backlog (prioritised)

### P0 — must for MVP
- Fix and expand tests (dictionary sync + QC + events)
- Make `renv.lock` real (non-empty) and enforce restore in CI
- Central config for key parameters (timezone, event threshold)
- Produce outputs in a consistent `outputs/` structure
- Add report rendering as a pipeline artefact
- Implement effort heatmap + event-spacing diagnostic

### P1 — should for Beta
- Detection history builder + unmarked occupancy models
- Uncertainty quantification (bootstrap for RAI, CIs for model outputs)
- Model diagnostics surfaced in report (convergence, residual checks where applicable)

### P2 — should for 1.0
- Diversity and distance–decay analyses
- Functional diversity + trait–environment analysis
- WildObsR adapter layer (if it improves interoperability)
- Teaching exercises and “what to try next” sections in the report

### P3 — nice-to-have
- Containerisation (Docker/Singularity)
- pkgdown site or rendered docs site
- Additional models (e.g., spOccupancy multispecies) if justified and stable

## Working rules

- Do not start Beta features until MVP stop conditions are met.
- Do not start 1.0 features until Beta stop conditions are met.
- Any major addition must include:
  - tests/sanity checks,
  - artefact outputs,
  - and interpretation notes.
