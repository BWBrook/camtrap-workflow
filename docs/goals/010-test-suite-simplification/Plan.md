# Goal 010 Test-Suite Simplification Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> `superpowers:subagent-driven-development` or
> `superpowers:executing-plans`. Steps use checkbox syntax for tracking.

**Goal:** Replace one undifferentiated 72-minute test step with a pruned fast
suite and a small explicit release gate, without changing scientific behavior.

**Architecture:** Root-level `tests/testthat/test_*.R` files form the fast
profile. Expensive current-format publication and runner cases live under
`tests/testthat/release/` and run only through an explicit profile. GitHub push
and PR events run the fast path; manual release dispatch adds release tests, the
full evidence run, bundle verification, and artifact upload.

**Tech stack:** R 4.6, `testthat`, `targets`, GitHub Actions, `renv`, Quarto.

## Global constraints

- Default to deletion, combination, or demotion; do not preserve a test merely
  because it exists.
- Do not modify production `R/` code, scientific outputs, schemas, configuration
  behavior, dependencies, or data.
- Do not retain compatibility tests for unpublished manifest/preview versions
  unless a concrete current consumer is identified.
- Keep one meaningful failure per protected boundary, not a combinatorial
  mutation matrix.
- Fast tests use small fixtures and may not invoke a full production evidence
  run or render the full report.
- Release evidence uses only the current supported configuration and schema.
- Use existing accepted CI logs as the baseline; do not rerun the old 72-minute
  suite merely to measure it again.
- Apply one focused independent review and at most one material repair pass.

## Planned file surface

Create:

- `tests/testthat/release/test_evidence_bundle_release.R`
- `tests/testthat/release/test_validation_runner_release.R`
- `docs/goals/010-test-suite-simplification/Audit.md`
- `docs/log/680_goal010_test_suite_simplification.md`

Modify:

- `scripts/run_tests.R`
- `.github/workflows/ci.yml`
- the existing tests named in the audit where deletion or consolidation is
  justified;
- `README.md`, `GETTING_STARTED.md`, `docs/release_checklist.md`,
  `docs/roadmap.md`, `docs/decisions.md`, and the product-blueprint roadmap and
  decision register where needed;
- the Goal 010 Log.

Delete when their only contract is removed:

- `tests/testthat/test_spatial_outputs.R`

An unlisted production edit is a stop condition, not permission to widen scope.

## Task 1: Complete the audit and freeze decisions

- [x] Record all 33 current test files in `Audit.md` with purpose, beneficiary,
  prevented failure, current cost evidence, decision, and run profile.
- [x] Mark historical schemas, unused modes, plot-existence checks, repeated
  reclosure cases, and static DAG preservation for deletion or consolidation.
- [x] Mark broader production complexity as deferred architecture debt.
- [x] Verify the decisions retain every non-negotiable invariant in `Goal.md`.

## Task 2: Add explicit fast and release profiles

- [x] Change `scripts/run_tests.R` to accept `--profile fast`, `release`, or
  `all`; default to `fast`; reject unknown arguments clearly.
- [x] Make `fast` run only root test files and `release` run only
  `tests/testthat/release/`; make `all` run both in that order.
- [x] Add focused argument/profile tests without invoking the expensive suite.
- [x] Rework CI so push/PR uses lint, fast tests, and one target smoke.
- [x] Make Quarto, TinyTeX, release tests, full evidence, bundle verification,
  and artifact upload conditional on manual `release` dispatch.
- [x] Validate YAML with `actionlint` and test invalid profile handling.

## Task 3: Delete low-value fast-suite tests

- [x] Remove ten plot-file-existence groups and delete the now-empty spatial
  test file.
- [x] Remove old preview/manifest compatibility and schema-downgrade tests.
- [x] Remove legacy omitted-mode and exact-old-DAG preservation tests with no
  current user, replacing them with a transitive target-graph guard proving
  protected physical outputs cannot inherit `selected_*` inputs.
- [x] Preserve explicit checks that synthetic midpoints are used only for
  mapping/distance and physical covariates are never pooled or re-extracted.
- [x] Collapse duplicate presence/richness/Jaccard, adapter-unknown, target
  manifest, and fixity proofs to one meaningful check per boundary.
- [x] Convert the expected CamtrapDP warning to an explicit expectation or
  delete the duplicate case.
- [x] Run only affected fast files, then the complete fast profile once.

## Task 4: Replace the two dominant files with small release contracts

- [x] Remove the production-data and historical-schema matrices from
  `test_run_bundle.R` and `test_validation_ledger.R`.
- [x] Move the retained current-format publication cases into the two release
  files and delete the obsolete originals if no fast contract remains.
- [x] Retain one ready and one blocked validation runner, one publish/copy/open
  bundle, one ordinary payload mutation, and one failed-publication preservation
  case.
- [x] Make invalid or unauthorized mapping a hard-stop control; keep valid
  concurrency as the distinct status-only omission control.
- [x] Keep the pure floating-point comparator in a fast, in-memory test.
- [x] Confirm release tests do not repeat the later real Judbury full run.
- [x] Run the release-only profile once and record its observed duration.

## Task 5: Verify, review, publish, and close

- [ ] Run lint, the fast profile, one target smoke, and `actionlint`.
- [ ] Measure fast test and total ordinary CI duration against the 4,315.2-second
  baseline; do not encode the duration as a flaky test.
- [x] Obtain one independent scientific and engineering review of the actual
  diff and retained audit.
- [x] Apply at most one focused material repair and rerun affected checks.
- [ ] Commit and push the accepted implementation with subject
  `test: simplify and tier the test suite`.
- [ ] Require exact-SHA push CI success.
- [ ] Manually dispatch the release profile on that exact main SHA and require
  release tests, full evidence, bundle verification, and artifact upload to
  succeed.
- [ ] Independently reconstruct from the emitted release bundle the 13-to-nine
  mapping, active/inactive/unknown operation union and gaps, same-day handover,
  event conservation, presence OR collapse, richness row sums, Jaccard values
  and edge cases, protected physical outputs, and rendered claim limits.
- [ ] Record exact SHAs, run IDs, durations, deleted/retained decisions,
  scientific limits, residual architecture debt, and the next decision.

## Acceptance summary

The root reviewer must be able to answer five questions from the final diff:

1. What became faster, and by how much?
2. What was deleted rather than hidden?
3. What ecological or user failure does each retained family prevent?
4. What expensive evidence remains, and exactly when does it run?
5. What architecture problem was deliberately deferred?
