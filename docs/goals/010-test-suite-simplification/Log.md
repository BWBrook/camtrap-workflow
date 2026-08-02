# Goal 010 - Packet and execution log

Date: 2026-08-02

- **Goal state:** `COMPLETE_PUBLISHED`
- **Design:** `PRUNE_AND_TIER`
- **Production-code boundary:** `PROTECTED`
- **Baseline SHA:** `d0594861e8941f4496989de4ab1c8a6e66f9b889`
- **Baseline CI:** `30716777969`
- **Packet branch baseline:** `cd5ec2df72e8c6fca4a9ba512a5b566fd935fcb3`

## Barry authority

Barry directed a ruthless test-value and runtime audit before further feature
work, with default subtraction and an explicit cost/value explanation for every
retained test family. After Goal 009 closeout, Barry stated:

> proceed with goal 010, "The Promise"!

The authorized interpretation is the bounded prune-and-tier design in
`Goal.md`. Broader production-architecture simplification is a likely later
goal, not part of this execution.

## Baseline diagnosis

Read-only reconnaissance found:

- 33 test files, 179 test blocks, 782 lexical expectation calls, and 7,556
  lines;
- a 4,315.2-second testthat duration in the accepted Linux run;
- 2,476.8 seconds in `test_run_bundle.R`;
- 1,799.5 seconds in `test_validation_ledger.R`;
- 99.1% of test runtime in those two files;
- 38.9 seconds across every other test file;
- repeated production-scale validation-only runs inside tests, followed by a
  separate full evidence run and bundle verification in CI; and
- no Git tag, repository version `0.7.0`, and no approved public API or migration
  policy that would justify historical schema compatibility.

## Chosen route

Tiering alone was rejected because it would preserve the overbuilt suite out of
sight. A production rewrite was rejected as too broad. Goal 010 will delete the
clear low-value surface, consolidate the retained current contract, and make
the expensive real-data evidence run an explicit release action.

## Execution record

Append only material decisions, measured results, independent review findings,
repairs, publication SHAs, and CI evidence here. Do not narrate every edit or
test invocation.

### 2026-08-02 - Task 1 test-value audit

- Accounted for all 33 current test files once in `Audit.md`; the inventory
  reconciles to 179 `test_that()` blocks and 7,556 lines.
- Froze the default-subtraction decisions: delete ten plot-existence groups,
  historical manifest/preview compatibility, unused resolution-mode matrices,
  static DAG preservation, repeated checksum-reclosure permutations, and
  repeated production-runner fixture construction.
- Reserved fast coverage for small current ecological, input-safety,
  provenance, claim-limit, and protected-physical-output contracts.
- Reserved release coverage for exactly one ready and one blocked current
  validation runner, one current publish/copy/reopen bundle, one ordinary
  payload mutation, and one failed publication that preserves the prior
  latest. The real Judbury evidence build remains a single later release action
  rather than test setup.
- Cross-walked every non-negotiable invariant in `Goal.md` to retained fast,
  release, and independent reconstruction evidence. Test counts remain
  implementation-volume descriptors, not a quality claim.
- Deferred production schema dispatch, runner decomposition, resolution-mode
  policy, provenance-boundary consolidation, target-graph modularity, and
  semantic plot testing to later architecture work; no production behavior was
  authorized or changed.

### 2026-08-02 - Tasks 2 and 3: tier and prune

- Added explicit `fast`, `release`, and `all` profiles; no argument defaults to
  `fast`. Ordinary CI now runs lint, fast tests, and one separate target smoke.
  Quarto, full evidence publication, verification, and artefact upload moved to
  an explicit manual release job.
- Removed ten plot-existence groups, historical preview/manifest matrices,
  speculative resolution modes, duplicated arithmetic and repair cases, and
  exact old-DAG snapshots. `test_spatial_outputs.R` was deleted.
- Consolidated current presence, richness, Jaccard, mapping, event-lineage, and
  authority protection. The final fast routing guard follows the complete
  target dependency graph and rejects any `selected_*` ancestor of protected
  physical-location outputs.
- Commits: `4e122cd`, `afddb60`, `b415bf4`, and `21e8911`.

### 2026-08-02 - Task 4: replace the hour-scale matrices

- Replaced the 2,510-line bundle/manifest/validation surface with small fast
  units and two release files. Current publication evidence covers manifest
  1.3 publish/open/copy, non-overwrite, one ordinary payload mutation, a failed
  publication preserving prior `latest`, one ready validation preview, and one
  unauthorized-mapping hard stop.
- Root fast tests contain no `run_full_evidence_run()` or `tar_make()` call.
  The release tree contains exactly two validation-only runner calls and never
  repeats the full Judbury run.
- The complete release profile ran once in 8.54 seconds before review repair.
  After repair, the bundle file passed 16 assertions in 7.1 seconds and the
  validation-runner file passed 15 assertions in 2.8 seconds.
- Review repair added honest `session_info.txt`, exact collision-inventory
  preservation, and seeded latest-byte preservation. Commits: `f126866` and
  `7461ae8`.

### 2026-08-02 - Review, reduction, and honest residuals

- Current test surface: 35 files (33 fast, two release), 4,929 lines, 121
  `test_that()` blocks, 660 lexical expectation references, two runner calls,
  and zero `tar_make()` calls. Baseline was 33 files, 7,556 lines, 179 blocks,
  782 expectation references, and 26 executed production-runner invocations.
- The final complete local fast attempt finished in 5.19 seconds but could not
  pass in the partial global library because `camtrapdp`, `FD`, `frictionless`,
  and `unmarked` are absent (557 checks passed, three skipped, two failed for
  missing packages). No packages were installed; dependency-complete
  exact-SHA CI is the acceptance environment.
- Independent re-review returned `SCIENCE SPEC: PASS` and `SCIENCE QUALITY:
  PASS`, finding no material ecological or data-integrity loss introduced by
  Goal 010. Engineering re-review found the repair correctly scoped.
- Two fail-closed production debts were exposed and not mocked away: an
  authorized orphan mapping cannot serialize a zero-row event map into a
  blocked preview, and CamtrapDP deployment lineage lacks the physical-location
  identifier needed to reconstruct genuine grouped-site concurrency. The old
  deleted “ineligible” fixture used legacy nominal-station mode and was not
  evidence for current analysis-site concurrency.
- Exact implementation commit: `ee084d8ad439483149435a9db6471b126dca1907`.

### 2026-08-02 - Exact-SHA CI and release evidence

- Ordinary push workflow `30731537537` passed at the exact implementation
  SHA. The fast-test step took 21 seconds, the separate target smoke took 7
  seconds, and the complete job took 3 minutes 2 seconds. The baseline unit
  step was 1 hour 11 minutes 59 seconds and the baseline complete job was 1
  hour 49 minutes 58 seconds.
- Manual release workflow `30731649136` passed at the same exact SHA. Release
  tests took 27 seconds, the one full Judbury evidence run took 33 minutes 43
  seconds, published-bundle verification took 5 minutes 37 seconds, and the
  release job took 41 minutes 48 seconds. Artefact `immutable-evidence-bundle`
  was uploaded as GitHub artefact `8828554925`.
- The emitted run was `20260802T040631Z-9e69f0844de14465`. Its manifest
  SHA-256 `f2773aed6d5ddca99be5afb5b7e96d75f6f5be603a2be10f7f15cc2cfd7b95cb`
  matched `COMPLETED.json`, and its engine identity recorded the clean exact
  implementation SHA.
- Independent reconstruction from the uploaded bundle reproduced 13 physical
  locations grouped into nine analysis sites; four exact midpoint
  representatives; 9,639 daily operation rows comprising 7,644 active, 1,995
  inactive, and zero unknown rows; one approved `jc_co1` same-day handover;
  no unexplained temporal overlap; and the 134-day plus 85-day `jc_pm14`
  inactive periods.
- All 11,572 events, 15,672 source-row memberships, event times, physical
  locations, species, and per-species totals were conserved. Presence was the
  exact member OR, collapsing 27 duplicated physical-location presences;
  richness was its row sum; and all 81 Jaccard values reconstructed to maximum
  absolute error `5.6e-17`, with symmetry, bounds, and zero diagonals.
- Protected outputs retained all 13 physical identifiers. Physical RAI used
  7,645 camera-days while the grouped branch used 7,644 site-days, correctly
  counting the approved handover once only in the grouped branch. The report
  visibly stated the mapping, midpoint, effort, detection, completeness,
  covariate, and inferential limits.
- No Judbury selected community is empty, so the real artefact cannot exercise
  the empty-union Jaccard convention; the exact-SHA fast suite supplies that
  synthetic edge-case evidence. GitHub emitted only non-blocking Node 20
  deprecation annotations for `actions/checkout@v4` and
  `actions/upload-artifact@v4`.

Goal 010 is complete and published. The two fail-closed production debts remain
deferred to the next architecture decision; no further Goal 010 polishing is
justified under the agreed stopping rule.
