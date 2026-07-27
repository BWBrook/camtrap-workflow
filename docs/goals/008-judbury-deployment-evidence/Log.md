# Goal 008 - Packet log

- **Canonical packet state:** `REVIEWED_AWAITING_BARRY_EXACT_APPROVAL`
- **Evidence interpretation:** `BARRY_SUPPLIED_2026-07-27`
- **Normalized source approval:** `PENDING_EXACT_BARRY_APPROVAL`
- **Deployment-ledger approval:** `PENDING_EXACT_BARRY_APPROVAL`
- **Implementation state:** `NOT_AUTHORIZED`
- **Publication state:** `NOT_PERFORMED`
- **Independent packet review:** `PASS_PACKET`
- **Packet date:** 2026-07-27 AEST
- **Packet-authoring baseline:** clean synchronized `main` at
  `e26c2a5a53e1a3283097ba8c6b193d2b7adf5a78`, with only Barry's untracked
  `data/jc_services.csv`.
- **Intended packet subject:**
  `docs: define Goal 008 Judbury deployment evidence`

## Exact packet paths

This authoring task owns exactly ten paths:

- `data/jc_services.csv`
- `data/jc_services_readme.txt`
- `docs/goals/008-judbury-deployment-evidence/Goal.md`
- `docs/goals/008-judbury-deployment-evidence/Plan.md`
- `docs/goals/008-judbury-deployment-evidence/Runbook.md`
- `docs/goals/008-judbury-deployment-evidence/Log.md`
- `docs/goals/008-judbury-deployment-evidence/judbury_deployment_ledger.csv`
- `docs/design/004-product-blueprint/decision_register.md`
- `docs/design/004-product-blueprint/development_roadmap.md`
- `docs/roadmap.md`

No runtime code, configuration, test, fixture, reference document, project
log, decision log, generated output, acceptance directory, dependency, stage,
commit, publication, or remote action is part of this authoring task.

## Source normalization record

Barry supplied `data/jc_services.csv` with:

- SHA-256
  `5c9db8f65cc11f9acf2447fa6c0354e52da6553227c618fae26a4d3942384d8f`;
- mode 0700;
- 14 CRLF record terminators and no stray CR bytes;
- 13 data rows and the exact 16-column source header; and
- 75 non-NA service dates.

The only source-file edits were CRLF to LF and mode 0700 to 0644. The
normalized file has:

- SHA-256
  `f33eeac9d70126966717c8e3f4731c00a97cbc3a34c2f44ce5c70d91c7d5283a`;
- mode 0644;
- 14 LF record terminators and zero CR bytes;
- the same 13 rows, fields, values, and order;
- 75 non-NA service dates; and
- 62 retained non-NA `run_days` values with diagnostic total 7842.

No field, value, row, or column was changed or reordered.

## Proposed deployment ledger

`judbury_deployment_ledger.csv` has:

- schema `camtrap-deployment-evidence-ledger/1.0`;
- version `judbury-deployment-evidence-ledger/1.0.0-proposed`;
- state `proposed_for_barry_exact_approval` on all 13 rows;
- SHA-256
  `0921eb8845c2bb1ad5760271f283ab2783735b7739e254c67e9243bc906f3ebf`;
- 13 unique stable deployment IDs;
- 13 unique raw service rows and canonical physical locations;
- nine nominal stations;
- four Goal 007 move-pair IDs;
- four unique directed predecessor-to-successor relations;
- exact day-precision start/end service labels and ISO dates;
- service counts summing to 75;
- exact operation authority at `data/jc_op.csv`; and
- `run_days_disposition = audit_only_not_effort_authority` on every row.

The service-count vector in Goal 007 physical order is:

```text
8,7,2,8,2,7,8,8,6,2,8,3,6
```

The exact `data/jc_op.csv` authoring-baseline SHA-256 is:

```text
28222586fa232fccc46bfab5e8c07e0c453f07387ebe4eb95b9a90e4687033a3
```

## Authority boundary

Barry supplied these interpretations:

- first non-NA service date is deployment start at that physical location;
- intermediate dates are services;
- last non-NA date is deployment end/final service/removal/move/study end;
- original locations start at S0 and moved locations start at their first
  non-NA service;
- `jc_op` is authoritative daily operation, with observed operating-at-service
  status overriding last-image inference;
- daily 1 means operation for at least part of the day and 0 means no
  operation; no failure cause is required; and
- `sN.run_days` is source metadata, not effort authority.

These facts authorize packet framing only. The source, ledger, packet commit,
and exact combined authority reference remain pending Barry's separate exact
approval. The packet does not mark them approved.

The proposed exact authority reference is:

```text
goal008-judbury-deployment-evidence-source-sha256-f33eeac9d70126966717c8e3f4731c00a97cbc3a34c2f44ce5c70d91c7d5283a-ledger-sha256-0921eb8845c2bb1ad5760271f283ab2783735b7739e254c67e9243bc906f3ebf
```

## Packet design

Goal 008 proposes:

- separate deployment-span, service-event, and daily-operation evidence;
- a new six-field internal `deployment_evidence` selection independent from
  the frozen Goal 007 `entity_resolution` selection;
- immutable service and ledger snapshots with separate source-inventory roles;
- exact, non-parser raw-to-canonical aliases;
- deterministic normalization of all 75 service events without a new event
  CSV;
- exactly 13 deployment entities, physical links, and lineage rows after
  approval;
- a narrow deployment-lineage schema bump from 1.0 to 1.1;
- four directed predecessor/successor relations without changing the four
  undirected Goal 007 move pairs;
- day precision, inclusive endpoint semantics, and explicit same-day boundary
  limits;
- a documented pm14 interval with no paired-location deployment;
- audit-only deployment join readiness;
- the unchanged five-file entity namespace, validation preview 1.1, completed
  manifest 1.2, semantic reconstruction, checksum-reclosure rejection, and
  legacy 1.0/1.1 verification;
- exact preservation of `jc_op`, four validated inputs, all Phase 2 evidence,
  event membership, effort, methods, thresholds, and 13 comparator tables; and
- an explicit deferral of the CamtrapDP exporter's first/last-active envelope.

`analysis_site` remains unselected with zero memberships. No nine-station
analysis, scientific routing, malfunction inference, effort reconciliation,
adapter/export change, public contract, target-graph edit, or scientific
output change is proposed.

## Goal 007 closeout correction

Goal 007 is already accepted and published:

- implementation SHA
  `bbe5c36f4b6f138f7ae5cdf2bd947e1bf42b0c30`;
- independent verdict `PASS_IMPLEMENTATION`; and
- exact-SHA CI run `30184741535`, conclusion `success`.

This packet marks the stale Goal 007 independent-review/publication/CI
checkbox complete and updates the blueprint roadmap from local-only acceptance
to accepted publication. It does not change Goal 007 evidence or authority.

## Authoring verification completed before independent review

- Baseline gate: PASS.
- Raw arrival hash, mode, and CRLF count: PASS.
- CRLF-to-LF-only normalized hash and mode: PASS.
- Structured service parse: PASS at 13 rows, 75 dates, 62 `run_days` values,
  and diagnostic total 7842.
- Structured ledger parse: PASS at 13 unique deployments, 13 physical
  locations, nine nominal stations, four move pairs, four directed relations,
  and 75 service events.
- Source, ledger, operation, and Goal 007 crosswalk hash identities: PASS.
- Exact final scope: PASS at the ten owned paths with an empty index.
- Whitespace: PASS for tracked changes with `git diff --check` and for every
  new file with no-index checks.
- Text integrity: PASS. New files are valid UTF-8 and ASCII-only with LF
  endings, no tabs or trailing whitespace; added lines in existing UTF-8
  documents are clean.
- Packet text: PASS. Markdown fences are balanced, current cross-references
  exist, and no drafting placeholder remains.
- Runtime/scientific verification: intentionally not run by this
  documentation-only task.

## Independent packet review and handoff

One independent read-only packet review returned `PASS_PACKET`. It found no
fatal, major, or minor material defect and recommended no focused repair.

The reviewer independently confirmed:

- exact baseline, ten-path scope, and empty index;
- all four source/ledger/crosswalk/operation hashes;
- 13 source rows, the closed header, 75 dates, 62 non-NA `run_days` values,
  and diagnostic total 7842;
- 13 unique deployments and physical locations, nine nominal stations, four
  move pairs, and four directed chronology relations;
- every raw alias, row ordinal, physical/nominal mapping, start/end label and
  date, service count, and move-pair value;
- ordered service dates and contiguous populated service labels;
- no `jc_op == 1` day outside the proposed deployment span for its physical
  location;
- authority, scope, non-routing, exporter deferral, allowlist, invariance, and
  stop boundaries; and
- clean `git diff --check`.

Residual limits are intentional: the received CRLF bytes no longer exist for
an independent post-normalization byte comparison, so the raw arrival hash and
line-ending-only transformation remain recorded provenance; Barry's exact
approval is pending; and runtime feasibility and scientific invariance were
not executed in this documentation-only task.

Barry must next review and explicitly approve the complete packet, exact
source and ledger SHA-256 values, packet commit SHA, and combined authority
reference before implementation. No action in this authoring task substitutes
for that approval.

No R, renv, tests, lint, targets, Quarto, Docker, build, pipeline, network,
generated scientific artefact, Git stage, commit, push, fetch, reset, clean,
stash, checkout, or merge was performed.
