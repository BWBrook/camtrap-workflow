# Goal 007 - Packet log

- **Canonical packet state:** `DRAFT_FOR_BARRY_REVIEW`
- **Framing/publication authority:** `AUTHORIZED_2026-07-26`
- **Crosswalk approval state:** `PENDING_BARRY_REVIEW`
- **Execution state:** `NOT_AUTHORIZED`
- **Publication state:** `NOT_PUBLISHED`
- **Packet date:** 2026-07-26 AEST
- **Packet-authoring baseline:** clean synchronized `main` at
  `7ad07e936be33b82d9c0423324f6867d541a22bd`
- **Intended packet subject:** `docs: define Goal 007 entity resolution`

## Exact packet paths

This framing task owns exactly seven paths:

- `docs/goals/007-entity-resolution/Goal.md`
- `docs/goals/007-entity-resolution/Plan.md`
- `docs/goals/007-entity-resolution/Runbook.md`
- `docs/goals/007-entity-resolution/Log.md`
- `docs/goals/007-entity-resolution/judbury_entity_crosswalk.csv`
- `docs/design/004-product-blueprint/decision_register.md`
- `docs/design/004-product-blueprint/development_roadmap.md`

No implementation, configuration, test, generated output, raw data,
acceptance evidence, dependency, stage, commit, or publication is part of this
authoring task.

## Authority recorded

Barry authorized framing and packet publication on 2026-07-26 after approving
the narrow entity-resolution concept. Implementation remains separately
gated.

Before implementation, Barry must explicitly approve:

- the complete packet; and
- the exact enumerated crosswalk file, version, and SHA-256.

Crosswalk approval can approve only the factual 13-physical-to-nine-nominal
mapping and four undirected move-pair relations. It does not select
deployment identity or chronology, `analysis_site`, effort/event routing,
analytical grouping, public fields/API/migration, or an ecological method.

## Enumerated crosswalk

`judbury_entity_crosswalk.csv` is a packet review artefact with:

- 13 data rows and 13 unique source physical IDs;
- 13 unchanged proposed stable physical IDs;
- nine unique proposed nominal station IDs;
- four unique move-pair IDs;
- four literal nullable service-history markers;
- SHA-256
  `553abada14493f3a5f0ae3c072523b6d5cc0d0c6a6c6480ca17a9e3331f2d8ec`;
- explicit mapping basis and pending Barry authority on every row;
- unresolved deployment identity/interval and chronology on every row;
- no coordinates; and
- no `analysis_site` field or membership.

The matrix proposes that each unsuffixed physical ID maps to the same nominal
ID and each suffixed physical ID maps to its base nominal ID. `_s1`, `_s16`,
and `_s15` are literal Judbury service-history evidence only. Their numbers
are not deployment ordinals, and the pair identifiers carry no direction or
chronology.

The crosswalk remains non-runtime evidence until its exact version is approved
and selected through the provisional internal configuration reference during
an authorized implementation.

## Packet design

Goal 007 is the first bounded Phase 3 vertical slice. It proposes:

- versioned internal entity-resolution records;
- deterministic entity and typed-link IDs that exclude run IDs, timestamps,
  absolute paths, coordinates, proximity, and suffix parsing;
- closed resolved, unresolved, ambiguous, and integrity-failure states;
- generic four-table compatibility resolution to physical location only;
- exact CamtrapDP use of supplied location, deployment, and interval evidence;
- a separately snapshotted and hashed case-study sidecar;
- immutable configuration binding to the exact Barry-approved sidecar SHA-256
  and approval reference;
- audit-only effort/observation join readiness without analytical routing;
- identical entity evidence in supported validation-only and full paths;
- five reconstructable review artefacts;
- manifest schema 1.2 with retained 1.1 and 1.0 verification;
- exact preservation of four validated analytical inputs, all Goal 006 Phase
  2 evidence, event membership, row accounting, effort, methods, thresholds,
  gap rule, and 13 scientific comparator tables; and
- one independent implementation review with at most one focused repair.

`analysis_site` remains explicitly unselected with zero membership. Judbury
deployment identity, interval, direction, and chronology remain explicitly
unresolved.

## Design-record changes

The decision register now separates:

1. approval of the factual 13-to-nine crosswalk; from
2. authoritative deployment chronology and purpose-specific
   `analysis_site` grouping.

D004-04 remains unresolved for the second decision. The roadmap now names Goal
007 as the first bounded Phase 3 slice and explicitly leaves resolved profiles,
effort/event routing, and full CamtrapDP adapter completion for later Phase 3
work. It does not mark Phase 3 complete.

## Independent packet review and focused repair

- Independent verdict: `REPAIR_PACKET`.
- Material finding: the first draft required Barry's approval receipt to name
  the crosswalk SHA-256 but selected only profile/path/schema/generic authority
  at runtime. Source inventory would prove which bytes were used without
  proving they were the bytes Barry approved, leaving the crosswalk reclosure
  rejection under-specified.
- One focused repair now binds the exact approved sidecar SHA-256 and stable
  approval reference into immutable raw/effective configuration, checks the
  bytes before and after snapshotting, cross-links the expected and observed
  digests in summary/manifest evidence, and requires portable reconstruction
  to reject disagreement.
- Narrow confirmation by the same reviewer: `CLOSED`.
- Crosswalk recount and seven-path scope otherwise passed independent review.
  No second broad review or additional repair was initiated.

## Static authoring record

- Baseline gate: PASS. Branch `main`, HEAD
  `7ad07e936be33b82d9c0423324f6867d541a22bd`, locally known upstream `0/0`,
  and clean index/worktree before the first edit.
- Exact authoring scope: PASS. The final modified/untracked set contains the
  seven paths above and the index remains empty.
- Crosswalk: PASS. Automated read-only checks confirm 13 unique physical
  rows, nine unique nominal IDs, four move-pair IDs each appearing twice,
  four service markers, the exact proposed mapping, no `analysis_site`
  column, and unresolved chronology/deployment state on all rows.
- Packet text: PASS. Current cross-references exist; Markdown fences are
  balanced per file; new files decode as UTF-8 and contain ASCII-compatible
  text; no tabs, trailing whitespace, incomplete drafting markers, or
  unbalanced records were found.
- Whitespace gate: PASS. `git diff --check` is clean for tracked changes and
  per-new-file no-index checks are clean.
- No R, renv, tests, lint, targets, Quarto, Docker, build, pipeline, CI,
  network acquisition, generated artefact, stage, commit, push, fetch, reset,
  clean, stash, or merge was performed.

## Handoff

Following clean authoring verification, the packet may be published through
the exact subject/parent/path gate in `Goal.md` under Barry's existing
publication authority. Barry should then review the published packet's
plain-language objective, exact factual matrix, deployment non-resolution,
zero `analysis_site` membership, closed implementation allowlist,
scientific-invariance comparator, and stop rules. Implementation still
requires his explicit packet/crosswalk approval and separate execution
authorization.
