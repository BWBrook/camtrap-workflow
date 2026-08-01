# Goal 009 - Analysis-site ecological vertical slice

Date: 2026-08-02

Status: `LOCAL_ACCEPTANCE_COMPLETE` / `AWAITING_EXACT_PUBLICATION`

## Authority and candidate

The implementation follows exact packet commit
`183bb7a80e54abb8dd59ec7f2c2a31dda72e5bc4`, subject
`docs: define Goal 009 analysis-site vertical slice`, and mapping SHA-256
`6490d7f7021e5c727b9be1c7d6dfbf44ba50a1ef5b0396c66e1dd813a9c77083`.

The locally accepted candidate content is HEAD
`6ca44dd6f8fd78ae9462cc6c80c0010f147a316f`. This is not the implementation
publication commit. That SHA will be known only after the reviewed candidate
content is squashed later.

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

## Remaining closeout

Goal 009 is locally accepted only. Exact-path squash and publication remain
pending, so the implementation publication SHA is not yet known. GitHub
Actions must then run against that exact published SHA. Neither publication nor
CI is claimed by this record.

## Approved next-goal direction

Barry directed Goal 010 to audit test value and runtime ruthlessly before any
further feature work. No test receives a presumption of necessity merely
because it exists. Each retained test must identify the real failure prevented,
the beneficiary, its run occasion, an explanation a user or developer can
understand, and its runtime and resource cost.

The audit should remove, combine, simplify, or demote tests wherever practical,
and separate a fast everyday suite from slower release-grade integration only
where retained value justifies the cost. Compatibility, provenance, bundle,
tamper, and publication tests require concrete current-project justification;
engineering best practice alone is insufficient. Proportionate safeguards for
scientific correctness, data integrity, destructive or irreversible
publication, and reproducibility must remain.

This is approved next-goal direction only. No Goal 010 Goal, Plan, or Runbook is
authored, and no test change is authorized or implemented here.
