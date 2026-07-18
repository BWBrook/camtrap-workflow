# 620 — R 4.6.0 Mac mini readiness sweep

Date: 2026-05-29

## What changed

- Migrated the local project baseline from stale R 4.5.x pinning to R 4.6.0.
- Refreshed `renv.lock` under R 4.6.0 with 139 locked packages.
- Updated repo, CI, README, and agent guidance to use R 4.6.0.
- Updated the Dockerfile to use `rocker/r-ver:4.6.0`, Quarto 1.9.37, architecture-aware Quarto downloads, and the Linux system libraries needed for arm64 source builds.
- Added container commit provenance via `GIT_COMMIT` / `CAMTRAP_WORKFLOW_GIT_COMMIT`.
- Stopped tracking generated `_targets/meta/meta` metadata because it contained stale WSL absolute paths and is regenerated locally.

## Mac mini tooling

- Homebrew R 4.6.0 is the active R runtime.
- GLPK and the required R package system dependencies are available.
- Docker Desktop is available. The Mac CLI needed Docker credential helper symlinks under `~/.local/bin` pointing at `/Applications/Docker.app/Contents/Resources/bin/`.
- Docker credential storage was switched from the hanging `desktop` helper to the working `osxkeychain` helper in `~/.docker/config.json`.

## Validation

- `git fetch --prune origin`; `main` was current with `origin/main`.
- `Rscript -e 'renv::restore(prompt = FALSE)'` succeeded.
- `Rscript -e 'renv::status()'` reported the project is synchronized.
- `Rscript scripts/run_lint.R` passed.
- `Rscript scripts/run_tests.R` passed: 165 pass, 0 fail, 1 expected warning from the Camtrap DP dropped-observation audit.
- Full default pipeline passed under R 4.6.0 on macOS in about 60 seconds.
- Full pipelines also passed for `config.forest_example.yml`, `config.template_example.yml`, `config.camtrapdp_example.yml`, and `config.camtrapdp_export.yml`.
- `docker build --build-arg GIT_COMMIT=<current commit>-dirty -t camtrap-workflow:r46-mac .` passed on Apple Silicon with the normal Docker Desktop configuration.
- Container lint passed.
- Container tests passed: 165 pass, 0 fail, 1 expected warning.
- Full container default pipeline passed in about 52 seconds, including HTML/PDF report and methods renders.

## Warnings reviewed

- Occupancy profile confidence-interval boundary warnings remain expected for the tiny exemplar datasets.
- Functional-diversity zero-distance warnings remain expected for duplicated trait distances in the small fixture.
- Forest/template example warnings remain small-data artefacts rather than setup failures.

## 2026-07-18 Goal 001 acceptance rerun

The sections above preserve the original 2026-05-29 readiness evidence. They are historical claims, not a representation of the later host state. Goal 001 independently reran the acceptance ladder on 2026-07-18; the durable command and evidence record is `docs/goals/001-r46-mac-mini-readiness-acceptance/Log.md`.

### Current host and lock correction

- The active Homebrew host runtime is now R 4.6.1 (2026-06-24), not the R 4.6.0 runtime recorded in May.
- R 4.6.0 remains the documented, lockfile, CI, and container minimum. The July run therefore proves forward patch compatibility on host R 4.6.1 without changing the declared baseline.
- The lock still parses as R 4.6.0 with 139 packages. `renv::restore(prompt = FALSE)` reported the library synchronized and `renv::status()` reported no issues.

### Fresh July validation

- Native lint and `actionlint .github/workflows/ci.yml` passed.
- Native tests passed: 165 pass, 0 fail, 0 skip, and 1 expected Camtrap DP dropped-observation audit warning.
- All five native configurations ran after deleting `_targets/` and their own prior output directories. Each rebuilt 130 targets with 0 skipped and produced its expected manifest plus non-empty report and methods HTML/PDF.
- Native wall times were 83.61 seconds (default), 70.83 (forest), 65.57 (template), 72.25 (Camtrap DP input), and 87.51 (Camtrap DP export).
- Camtrap DP export validation reported OK with zero dropped observations and produced 13 deployment rows, 15,514 media rows, and 15,694 observation rows.
- A fresh Linux arm64 Docker image build completed in 1,700.14 seconds from `rocker/r-ver:4.6.0`; the architecture-aware installer selected Quarto 1.9.37 and TinyTeX 2026.07 arm64 artefacts. No Docker credential-helper or machine configuration change was needed for the July run.
- Container lint passed. Container tests passed with the same 165/0/1 expected-warning result.
- A clean container default pipeline rebuilt 130 targets with 0 skipped in 102.51 seconds and produced 65 files, including report and methods HTML/PDF.
- The container manifest recorded `b13c7fe708373cd305843a81542c047777791448-dirty`, exactly matching the explicit build argument and distinguishing the tested uncommitted readiness bundle from the clean HEAD.

### July warning interpretation

- Default/export and container warnings remain occupancy interval-boundary and functional-diversity zero-distance effects in small examples.
- Forest warnings add six-site LOESS span/pseudoinverse limitations; template warnings add omitted rarefaction ribbon rows and singular occupancy Hessians for its two-site fixture; the Camtrap DP input adds occupancy boundary warnings only.
- These warnings do not affect dependency restore, input validation, path portability, render completion, export validation, or manifest provenance. They remain scientific small-data limitations and are not suppressed or reclassified as setup failures.
