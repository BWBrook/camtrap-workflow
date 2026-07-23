# Goal 006 - Packet log

- **Canonical packet state:** `APPROVED_AND_PUBLISHED`
- **Execution state:** `COMPLETE`
- **Publication state:** `PUBLISHED_CI_CONFIRMED`
- **Packet date:** 2026-07-23 AEST
- **Packet-authoring baseline:** clean synchronized `main` at
  `b9934a116c41ab2250c7975daf6d19f1c70effb1`.
- **Implementation baseline:** clean synchronized `main` at
  `9c7c70d2e722015347e9afaeec28574c0dc498ce`.
- **Intended packet subject:** `docs: define Goal 006 validation repair lineage`

## Exact packet paths

This framing task owns exactly six paths:

- `docs/goals/006-validation-repair-lineage/Goal.md`
- `docs/goals/006-validation-repair-lineage/Plan.md`
- `docs/goals/006-validation-repair-lineage/Runbook.md`
- `docs/goals/006-validation-repair-lineage/Log.md`
- `docs/design/004-product-blueprint/decision_register.md`
- `docs/design/004-product-blueprint/development_roadmap.md`

No implementation, generated output, raw data, acceptance evidence, or other
project file is part of the draft packet.

## Accepted policy recorded

Barry resolved D004-02 on 2026-07-23:

- semantic repair defaults to preview without application;
- filling a genuinely unknown value requires exact reviewed approval;
- explicit deployment/operational evidence cannot be overridden by broad
  opt-in, and any exact override needs proposal-specific approval plus reason;
- original, proposal, decision, application, and post-validation states remain
  audit-preserved; and
- Goal 006 adds no production fill-unknown or operational-period inference
  algorithm.

Declined or unresolved proposals record deterministic affected-domain
consequences. Goal 006 does not claim selective module execution; that remains
Phase 4.

## Packet boundaries

The packet proposes an internal source-row audit identity, structured findings,
proposal-specific approvals, immutable preflight previews, event-membership
sidecars, and manifest schema 1.1 with 1.0 verification compatibility. It does
not choose public fields, Judbury grouping, new ecological methods, production
operational inference, module-planner behaviour, interface technology, or a
new dependency.

Packet publication and implementation both require subsequent authorization.
No local acceptance can substitute for Barry's execution gate.

## Independent packet review and focused repair

- Independent verdict: `REPAIR_PACKET`.
- Material finding: the first draft allowed existing CamtrapDP defaults to be
  described as transformations or findings, which could bypass the accepted
  proposal-specific repair authority.
- One focused repair closed that gap. Only strictly meaning-preserving
  mappings may now remain transformation-only. Filling an unknown is
  `fill_unknown`; replacing supplied evidence is `override_explicit`; both
  require exact proposal-specific approval. Legacy defaults receive no
  automatic authority, and focused CamtrapDP fixtures must prove they do not
  auto-apply.
- No second repair or implementation work was undertaken.

## Static authoring record

- Baseline gate: PASS - branch `main`, HEAD and `origin/main` both
  `b9934a116c41ab2250c7975daf6d19f1c70effb1`, clean worktree before edits.
- Repo-local `AGENTS.md`, Goal 004 blueprint/roadmap/capability/Judbury
  artefacts, Goal 005 packet/closeout, architecture audit, reference
  contracts, and current validation/adapter/manifest surfaces were read.
- Final line counts: Goal 255, Plan 41, Runbook 459, Log 89.
- Exact six-path scope: PASS; the modified/untracked path set is exactly the
  six paths listed above.
- UTF-8 decoding, no tabs, no trailing whitespace, balanced Markdown fences,
  current cross-reference existence, per-new-file no-index whitespace checks,
  and `git diff --check`: PASS.
- No R, tests, lint, targets, Quarto, container, CI, network acquisition,
  generated artefact, stage, commit, push, fetch, reset, clean, or stash was
  performed.

## Handoff

The packet was subsequently approved, published exactly as specified at
`9c7c70d2e722015347e9afaeec28574c0dc498ce`, and separately authorized for
execution. The implementation record follows.

## Implementation outcome

The supported runner now has a validation-only mode that atomically publishes
an immutable `PREVIEW.json` outside completed runs. It never writes
`COMPLETED.json`, renders a scientific report, or changes `outputs/latest`.
A supported full run executes the same preflight and enters the analytical
graph only through the verified `validated_inputs.rds`.

Phase 2 records deterministic resource and parsed-row identities, every row
disposition, structured findings, meaning-preserving transformations, exact
repair proposals/decisions/applications, changed fields, post-validation
state, and operational detection event membership. Semantic repairs default
to preview without application. Broad, stale, unknown, duplicate,
conflicting, or tampered authority fails integrity; an explicit-evidence
override additionally requires a non-empty reason. Historical CamtrapDP
fills remain non-applicable production proposals and cannot auto-apply.

New completed runs use `camtrap-evidence-manifest/1.1`. Portable verification
retains the Goal 005 manifest 1.0 path and, for 1.1, reconstructs every Phase 2
record and all four analytical tables from immutable source bytes plus the
exact raw-config decisions.

## Local acceptance evidence

Raw evidence is ignored beneath `outputs/goal006_acceptance/`.

- Pre-edit baseline bundle:
  `20260723T100735Z-198a9df77af1446e`, manifest 1.0, 72 payload files.
- Clean validation-only invocation:
  `20260723T105546Z-f692b617b4ae4487`, ready preview, 19 payload files,
  with latest-pointer bytes unchanged.
- Clean supported full invocation:
  `20260723T105817Z-6ed71ceea2ee4f15`, 90 completed and 42 skipped targets,
  manifest 1.1, 83 payload files, manifest SHA-256
  `3eb073b64f934a4c112fb66f1868e6e17be88aab5a3912d4b9edb0bfe14c5273`.
- The clean preflight and full run have identical hashes for all 11 Phase 2
  artifacts.
- All 16,806 parsed rows reconcile: 16,784 retained and 22 excluded with
  explicit rules/reasons. The 15,694 observation rows yield 11,572
  operational detection events and 15,672 source-row memberships.
- The default Judbury run has zero proposals, decisions, applications, or
  changed fields.
- All 10 stable tables are byte- and value-identical to baseline. All three
  occupancy tables have identical shape, missingness, text, and numeric
  values, with maximum absolute difference zero.
- The real manifest 1.1 bundle and preserved manifest 1.0 bundle both verify
  after the focused repair.
- Final lint is clean. The authoritative suite reports 406 PASS, 0 FAIL,
  0 SKIP, and one expected existing CamtrapDP export warning.

## Independent implementation review and single repair

The independent audit returned `REPAIR_IMPLEMENTATION`. It demonstrated that
a checksum-reclosed `validated_inputs.rds` could alter a non-event scientific
value while the first verifier checked only proposal targets and operational
event membership.

The single permitted repair now reconstructs all four analytical tables and
every Phase 2 document from the immutable source snapshot plus exact config
decisions, then requires semantic equivalence. A new regression changes
`obs$count` by 1,000, recloses payload and completion fixity, and is rejected.
The first post-repair full-suite attempt exposed one incomplete low-level test
fixture that lacked the raw config/source inventory required by the portable
contract. The fixture was completed; covering tests and the authoritative
suite then passed.
The focused verifier suite passes 50 checks; the combined validation/verifier
coverage passes 68 and 50 checks; the full gate and real bundle checks above
also pass. No second broad review or repair was performed.

## Publication and exact-SHA CI

Implementation commit `584d3766d47ddbdd14d8dee34fc9df1d59255393`
(parent packet commit `9c7c70d2e722015347e9afaeec28574c0dc498ce`,
subject `feat: add validation repair lineage`) was pushed successfully and
matched `origin/main` before this administrative closeout. Its committed
footprint is exactly 39 allowlisted paths, with 5,265 insertions and 87
deletions.

GitHub Actions workflow `ci` run
[`30003868386`](https://github.com/BWBrook/camtrap-workflow/actions/runs/30003868386)
completed successfully against exact head SHA
`584d3766d47ddbdd14d8dee34fc9df1d59255393`. Job `r-workflow`
(`89195141980`) succeeded in about 20m02s. Lint, unit tests, pipeline smoke,
the full immutable evidence run, published-bundle verification, and artifact
upload all succeeded. The only annotation was a non-failing infrastructure
notice that GitHub forced the Node.js-20-targeting `checkout@v4` and
`upload-artifact@v4` actions onto Node.js 24.
