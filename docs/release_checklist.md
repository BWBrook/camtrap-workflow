# Release checklist

This checklist defines what must be true before tagging a release (e.g., v0.1.0, v0.9.0, v1.0.0).

## 1) Reproducibility & build

- [x] `renv.lock` is present, non-empty, and matches the current codebase.
- [x] A fresh clone + `renv::restore()` succeeds on at least one clean machine/environment.
- [x] `targets::tar_make()` runs end-to-end on the exemplar dataset.
- [x] A rendered report exists under `outputs/runs/<run_id>/report/` from the release build.
- [x] `outputs/runs/<run_id>/session_info.txt` (or equivalent) is produced.

## 2) Quality gates

- [x] Tests pass (`testthat`).
- [x] Lint passes (`lintr`) or exceptions are documented and minimal.
- [x] Pipeline smoke test runs in CI (or documented reason why not).
- [ ] No new warnings/errors introduced (or documented as known limitations).

## 3) Scientific sanity

- [x] QC checks pass for exemplar dataset.
- [ ] Key descriptive artefacts are coherent:
  - [x] effort summaries
  - [x] event-spacing diagnostics
  - [x] RAI summaries
  - [x] diel summaries
  - [x] rarefaction curve
- [x] For Beta+ releases: occupancy results include diagnostics and are interpretable.
- [x] For 1.0: community and trait analyses outputs are produced and documented.

## 4) Documentation

- [x] README is accurate and includes:
  - setup steps,
  - how to run the pipeline,
  - where outputs are written,
  - how to adapt to new data.
- [x] `docs/product_brief.md`, `docs/architecture.md`, and `docs/roadmap.md` are consistent.
- [x] `docs/decisions.md` is up to date.
- [x] `docs/questions_for_human.md` has no stale blockers (resolved or explicitly deferred).

## 5) Versioning & release artefacts

- [ ] Version number updated (semver).
- [x] CHANGELOG updated with user-facing changes and known limitations.
- [ ] Tag created and pushed.
- [ ] Release bundle (see `docs/release_bundle.md`) includes or references:
  - [ ] rendered report artefact(s),
  - [ ] key tables/figures,
  - [ ] `renv.lock`,
  - [ ] session info.
