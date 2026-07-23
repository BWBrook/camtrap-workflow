# Goal 006 - Packet log

- **Canonical packet state:** `DRAFT_FOR_BARRY_REVIEW`
- **Execution state:** `NOT_AUTHORIZED`
- **Packet date:** 2026-07-23 AEST
- **Packet-authoring baseline:** clean synchronized `main` at
  `b9934a116c41ab2250c7975daf6d19f1c70effb1`.
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

The orchestrator should critically review the draft against the accepted
policy and Phase 2 boundary. If accepted, Barry may authorize packet
publication and execution. Until then, canonical execution state remains
`NOT_AUTHORIZED`.
