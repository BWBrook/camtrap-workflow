# 000 — Bootstrap: truthful baseline audit

Date: 2025-12-18

This entry records the **starting line** for `camtrap-workflow` before advancing the MVP work packages. The goal is to make the repo’s current state *truthful* (what runs, what fails, and why), so subsequent fixes are measurable.

## What currently runs

- The repository opens in R/RStudio and `renv` auto-activates via `.Rprofile`.
- The exemplar input data files exist under `data/`:
  - `data/jc_site.csv`
  - `data/jc_op.csv`
  - `data/jc_obs.csv`
  - `data/jc_taxa.csv`
- The generated dictionary CSV already exists at `data/data_dictionary.csv`.

## What currently fails (repro + tests + pipeline)

### `renv` state

- `renv.lock` exists but is effectively empty (`"Packages": {}`).
- `renv::status()` reports the project as out-of-sync because many packages are *used* by the codebase but not recorded/installed.
- R startup prints a warning that the project is configured for `renv` **1.1.4** while the project library contains **1.1.5** (version mismatch via `renv/activate.R` vs installed library).

### Tests

Attempted:

```sh
Rscript -e 'testthat::test_dir("tests/testthat")'
```

Result:

- Fails immediately because `testthat` is not installed in the project library.
- Even once dependencies are installed, `tests/testthat/test_dictionary_sync.R` is currently broken:
  - references `md_df` outside its defining scope, and
  - uses `expect_false()` without importing it.

### Pipeline (`targets`)

Attempted:

```sh
Rscript -e 'targets::tar_make()'
```

Result:

- Fails immediately because `targets` is not installed.
- `_targets.R` also declares a number of heavy dependencies (e.g. `sf`, `spOccupancy`, `unmarked`, `camtrapR`) that are not yet required for the current MVP targets. This is likely to make restore/build fragile on fresh machines.

## Top blockers to an MVP (restore → tar_make with coherent artefacts)

1) **Empty lockfile**: `renv.lock` has no packages recorded, so a collaborator cannot restore a working environment.
2) **No single non-interactive test entry point**: there is no `scripts/run_tests.R` (or equivalent) and the existing dictionary-sync test is broken.
3) **Pipeline dependency bloat**: `_targets.R` and `bootstrap_env.R` reference heavy packages that are not needed for the current pipeline outputs, increasing the chance of restore failures (system libraries, compilation).
4) **Docs not yet truthful**: README claims the pipeline renders a report under `outputs/report/`, but the current `_targets.R` only writes a rarefaction plot and does not render any report artefact.
5) **No CI quality gates**: no automated restore/lint/test/smoke pipeline checks exist yet.

## Next actions (aligned to roadmap WPs)

- WP-0.3.2: Populate `renv.lock` with the minimal set of packages required for the current MVP pipeline + tests + lint; verify `renv::restore()` from a clean state.
- WP-0.3.4: Fix dictionary sync tests and add unit tests for QC / effort / events / RAI+diel invariants.
- WP-0.3.12: Add CI to run restore + lint + tests + pipeline smoke and upload at least a report + one plot as artefacts.

---

## Status update (after bootstrap fixes on 2025-12-18)

As of 2025-12-18, the baseline issues above have been addressed:

- `renv.lock` is now populated and `renv::restore(prompt = FALSE)` succeeds.
- Tests pass via `Rscript scripts/run_tests.R`.
- Lint passes via `Rscript scripts/run_lint.R`.
- Pipeline runs end-to-end on the exemplar dataset via `Rscript -e 'targets::tar_make()'` and produces:
  - `outputs/figures/rarefaction.png`
  - `outputs/report/report.html`
  - `outputs/session_info.txt`
