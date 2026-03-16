# AGENTS: camtrap-workflow (AI-assisted software delivery harness)

This file defines how you, the Codex CLI agent, must operate **in this repository**.
If global agent instructions exist, follow them unless they conflict with this file.
If there is a conflict, **this file wins** for this repo.

## Mission

Deliver a reproducible, well-tested, end-to-end camera-trap analysis workflow in R that:
- starts from labelled detection + site + effort + taxa tables,
- runs through QC → effort standardisation → independent events → analyses,
- produces coherent scientific artefacts (tables/figures/report),
- and can be re-run by others with minimal friction.

## Operating principles

### 1) Autonomy with discipline
- Work autonomously; minimise questions to the human.
- Use `docs/roadmap.md` as a living document that details a plan suitable for long-term autonomy.
- Only ask if blocked after multiple attempts or if an irreversible choice has high ambiguity.
- Record decisions in `docs/decisions.md` and open questions in `docs/questions_for_human.md`.

### 2) Outcome-oriented changes
- Prefer small, reviewable commits that each deliver an end-to-end improvement:
  - a fixed test,
  - a new target with an artefact,
  - a new validation check,
  - a report section with output + interpretation.

### 3) Reproducibility is non-negotiable
- `renv.lock` must be complete and committed.
- The repo must have a documented, one-command run path:
  - restore deps, then run the pipeline.
- Capture session info in outputs for traceability.

### 4) Artefact Review Cycle (mandatory)
For each milestone feature that creates scientific output, follow the loop:
1) Build artefacts (pipeline + report + tables/figures)
2) Sanity checks (domain + technical)
3) Interpretation notes (what the artefacts mean)
4) Iterate until coherent

Details are in `docs/workflow.md`. This is not optional.

## Required repository hygiene

- Keep `docs/roadmap.md` current (milestones, backlog, priorities). When the user says "Follow the plan" they mean this.
- Maintain a chronological log in `docs/log/` (create if missing).
  - Example filenames: `000_bootstrap.md`, `010_mvp_qc.md`, `020_mvp_events.md`, ...
- Keep tests running locally and in CI (once CI exists).
- Do not commit large derived outputs; keep outputs in `outputs/` (gitignored).
  - Commit only small “golden” fixtures needed for tests.

## Technical constraints and defaults

- Primary language: R (R 4.5.3).
- Reproducibility: `renv` + (optional) `pak` for faster installs.
- Pipeline: `targets` (and `tarchetypes` for report rendering if adopted).
- Prefer tidyverse-style data handling (`dplyr`, `tidyr`, `readr`).
- Prefer explicit, parameterised functions over ad-hoc scripts.

## Quality gates (must pass before requesting a PI review)

Before preparing a ZIP snapshot for PI review:
- `renv.lock` is updated and non-empty.
- All tests pass (unit + integration/smoke).
- Lint passes (at least on `R/` and `scripts/`).
- A full pipeline run succeeds on the exemplar dataset.
- `docs/decisions.md` and `docs/log/<latest>.md` reflect what changed.

## Deliverable for the next PI review round

Prepare a repo snapshot that includes:
- Updated harness docs
- Working pipeline producing artefacts under `outputs/`
- Logs and decisions updated
- A short “what changed” note in `docs/log/`
