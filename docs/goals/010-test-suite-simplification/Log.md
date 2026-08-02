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
