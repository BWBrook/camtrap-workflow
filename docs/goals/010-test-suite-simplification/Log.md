# Goal 010 - Packet and execution log

Date: 2026-08-02

- **Goal state:** `AUTHORIZED_FOR_EXECUTION`
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
- Exact implementation commit, push CI, manual release workflow, emitted-bundle
  reconstruction, and final runtime evidence remain pending.
