# Goal 009 - Analysis-site ecological vertical slice

Date: 2026-08-02

Status: `COMPLETE_PUBLISHED` / `PUBLISHED_CI_CONFIRMED`

## Authority and candidate

The implementation follows exact packet commit
`183bb7a80e54abb8dd59ec7f2c2a31dda72e5bc4`, subject
`docs: define Goal 009 analysis-site vertical slice`, and mapping SHA-256
`6490d7f7021e5c727b9be1c7d6dfbf44ba50a1ef5b0396c66e1dd813a9c77083`.

The locally accepted candidate content was HEAD
`6ca44dd6f8fd78ae9462cc6c80c0010f147a316f`. It was published as core
implementation `3d0f23ac0cbabdeef780144a0fad261d2ce366be`, subject
`feat: add analysis-site ecological slice`. The final accepted publication HEAD
is test-only repair `d0594861e8941f4496989de4ab1c8a6e66f9b889`, subject
`test: make manifest drift control portable`.

## Implemented slice

Goal 009 adds one explicit selected-resolution branch after physical event
construction while preserving the legacy physical-location routes. For the
approved Judbury profile it maps 13 physical locations to nine purpose-specific
analysis sites, unions confirmed member operation without filling unknown
periods, conserves already-defined events, and produces confirmed effort,
observed richness, presence, and Jaccard outputs with portable provenance.

The branch does not recluster events, infer grouping, pool physical covariates,
or reroute the excluded modules. Genuine concurrency can omit the selected
route without weakening the global mapping and provenance integrity gate.

## Local acceptance evidence

The final local gate recorded:

- validation-only preview `20260801T174838Z-9c2f4e49de784718`;
- completed full run `20260801T175415Z-2cdc56dfaa02443b`;
- manifest schema 1.3 with 101 payloads and SHA-256
  `bc88e0af859ffb9529e85ed3d10989eb3fece894c91cffc26541db144d971336`;
- lint PASS;
- authoritative suite `[ FAIL 0 | WARN 1 | SKIP 0 | PASS 881 ]`, with the sole
  understood warning from the CamtrapDP unparseable-datetime fixture;
- direct, copied, and accepted-baseline bundle verification PASS;
- protected legacy comparison PASS at 6/6 global checks and 8/8 protected
  objects; the ignored macOS derivative changed only the absent-path
  `Sys.readlink` guard; and
- independent scientific reconstruction PASS at 26/26 checks.

The independent reconstruction recovered 13 physical locations to nine sites,
9,639 unit-days comprising 7,644 active and 1,995 inactive days, 11,572
conserved events, 177 physical presence cells to 150 selected cells, and 81
Jaccard rows.

## Review and scientific boundary

After the final claim repair, independent review returned `I1_CLOSED`,
`SPEC_PASS`, `SCIENCE_PASS`, `QUALITY_PASS`, and `PUBLISH`. The final token is a
review disposition for the pending publication step, not a publication or CI
receipt.

Interpretation remains bounded to confirmed effort and observed,
detection-limited richness and presence.
Jaccard is a descriptive observed-presence comparison, not standardized for
unequal confirmed effort, completeness, or detectability. The slice makes no
pooled-covariate,
abundance/density, unseen-richness, inferential, or generalized
concurrency/grouping claim.

## Publication and exact-SHA CI closeout

Core implementation `3d0f23ac0cbabdeef780144a0fad261d2ce366be` has packet
`183bb7a80e54abb8dd59ec7f2c2a31dda72e5bc4` as its sole parent. Its first
exact-SHA workflow run `30713505836`, job `91405028902`, ran against that exact
core SHA and failed after `1h22m36s` at one platform-dependent
`test_run_bundle` assertion. Unit tests recorded
`[ FAIL 1 | WARN 1 | SKIP 0 | PASS 880 ]`; the sole warning was the expected
CamtrapDP unparseable-datetime fixture warning, and later workflow steps were
skipped. The failure was confined to test portability and did not implicate
the Goal 009 implementation.

The test-only portability repair
`d0594861e8941f4496989de4ab1c8a6e66f9b889` has the core implementation as its
sole parent. Final exact-SHA workflow
[`30716777969`](https://github.com/BWBrook/camtrap-workflow/actions/runs/30716777969),
job `91413569305`, ran against that exact repair SHA and concluded `success` in
`1h49m58s`.

The passing workflow recorded:

- lint success in 19 seconds;
- unit tests in `1h11m59s` with
  `[ FAIL 0 | WARN 1 | SKIP 0 | PASS 881 ]` and the sole expected CamtrapDP
  unparseable-datetime fixture warning;
- `test_run_bundle` PASS at 99/99 and pipeline smoke PASS in 8 seconds;
- full immutable run `20260801T213517Z-e179fbf11da94f40` in `30m40s`;
- bundle verification in `5m02s`, `valid = true`, with 101 payloads and
  manifest SHA-256
  `d931901848bdba29777653a910fd2e2ec13327784dd9018c54c1b040e18da53c`;
  and
- artifact `8824757010`: 39,917,667 bytes, 104 files, ZIP SHA-256
  `57b3380c6b4b1517e581e678b5083cbeb92f088d6529dcf5dfd9a64946e14fe4`.

Goal 009 is complete, accepted, published, and exact-SHA-CI-confirmed at final
repair SHA `d0594861e8941f4496989de4ab1c8a6e66f9b889`. The scientific implementation
is core commit `3d0f23ac0cbabdeef780144a0fad261d2ce366be`; the final commit changes only
the platform-dependent manifest-drift test control. The scientific limits above
remain unchanged.

## Approved next-goal direction

Barry directed Goal 010 to audit test value and runtime ruthlessly before any
further feature work. No test receives a presumption of necessity merely
because it exists. Each retained test must identify the real failure prevented,
the beneficiary, its run occasion, an explanation a user or developer can
understand, and its runtime and resource cost.

The audit should remove, combine, simplify, or demote tests wherever practical,
using default subtraction, and separate a fast everyday suite from slower
release-grade integration only where retained value justifies the cost.
Compatibility, provenance, bundle, tamper, and publication tests require
concrete current-project justification; engineering best practice alone is
insufficient. Proportionate safeguards for scientific correctness, data
integrity, destructive or irreversible publication, and reproducibility must
remain.

This is approved next-goal direction only. No Goal 010 packet has been authored,
and no Goal 010 test-suite change is authorized or implemented here.
