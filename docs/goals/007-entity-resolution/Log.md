# Goal 007 - Packet log

- **Canonical packet state:** `APPROVED_IMPLEMENTED_LOCAL_REPAIRED`
- **Framing/publication authority:** `AUTHORIZED_2026-07-26`
- **Crosswalk approval state:** `APPROVED_EXACT_SHA256`
- **Execution state:** `AUTHORIZED_FOCUSED_REPAIR_COMPLETE`
- **Publication state:** `IMPLEMENTATION_NOT_COMMITTED`
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

## Packet-publication handoff (historical)

Following clean authoring verification, the packet was published through the
exact subject/parent/path gate in `Goal.md`. Barry then reviewed the packet's
plain-language objective, exact factual matrix, deployment non-resolution,
zero `analysis_site` membership, closed implementation allowlist,
scientific-invariance comparator, and stop rules before supplying the
implementation authority recorded below.

## Authorized implementation record

Barry approved the published packet commit
`3d42c1cb9ad74bff107de42200122f93505e21e6`, the exact crosswalk version and
SHA-256 above, and the stable authority reference
`goal007-judbury-crosswalk-sha256-553abada14493f3a5f0ae3c072523b6d5cc0d0c6a6c6480ca17a9e3331f2d8ec`.
Implementation retained the matrix unchanged.

The bounded implementation:

- snapshots the selected sidecar as non-parser `entity_resolution_input`;
- publishes deterministic entity, link, deployment-lineage, summary, and
  join-readiness records in both supported modes;
- keeps Judbury at 13 physical locations, nine nominal stations, four
  undirected move pairs, zero deployments, and zero `analysis_site`
  memberships;
- keeps optional CamtrapDP identity/interval absence unresolved while
  stopping duplicate, competing, reversed, and orphan evidence;
- advances previews to schema 1.1 and completed bundles to manifest 1.2 while
  retaining 1.0/1.1 verification; and
- does not route, join, filter, aggregate, or mutate scientific inputs.

Local acceptance on 2026-07-26:

- final preview `20260726T020035Z-9105b7497a6f440d`: ready, latest unchanged;
- final bundle `20260726T020411Z-d034ea6eb0164fcd`: 91 targets completed,
  42 skipped, manifest 1.2, 89 payload files, portable verification PASS;
- validation/full copies of all five entity records: byte-identical;
- 13 frozen scientific tables and all 11 Phase 2 artefacts: byte-identical to
  the pre-edit manifest-1.1 baseline;
- `validated_inputs.rds`: object-identical with only `site`, `op`, `obs`, and
  `taxa`; all occupancy numerical differences zero;
- lint PASS and authoritative tests 520 PASS, zero failures, one expected
  CamtrapDP export warning;
- checksum-reclosed crosswalk mutation rejected at exact approved authority;
- actual manifest 1.1 baseline and final manifest 1.2 bundle verified, with
  manifest 1.0 retained in the authoritative fixture suite; and
- direct partial, validation-only, integrity-blocked, and failed-full pointer
  boundaries preserved prior `outputs/latest` bytes.

## Independent implementation review and focused repair

Independent review found four material verifier/evidence gaps. The single
authorized focused repair:

- makes explicit null require zero entity sidecars and no dedicated snapshot
  path, makes selected Judbury authority four-table-only, and requires exactly
  one matching inventoried and reconciled entity sidecar;
- closes preview 1.1 and manifest 1.2 to the exact canonical five-file entity
  namespace, including after payload/completion reclosure;
- retains one deployment-lineage row and source-row link for every
  duplicate/competing CamtrapDP evidence row without resolving the mapping; and
- binds join readiness to the immutable source SHA-256 as well as the entity
  ledger digest.

RED controls reproduced all four gaps before production edits. Final focused
suites, lint, 520-test authoritative execution, fresh preview/full parity,
portable verification, legacy 1.1 verification, and the frozen scientific
comparator all pass. Review confirmation, publication, and CI remain
orchestrator-owned.

Raw ignored evidence and the implementation-owner report are under
`outputs/goal007_acceptance/`. Independent implementation review, exact-path
staging, commit, push, and exact-SHA CI remain orchestrator-owned.
