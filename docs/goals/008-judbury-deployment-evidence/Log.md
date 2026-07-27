# Goal 008 - Packet log

- **Canonical packet state:** `PUBLISHED_EXACT_PACKET_APPROVED_FOR_IMPLEMENTATION`
- **Evidence interpretation:** `BARRY_SUPPLIED_2026-07-27`
- **Normalized source approval:** `APPROVED_EXACT_SHA256`
- **Deployment-ledger approval:** `APPROVED_EXACT_SHA256`
- **Implementation state:** `LOCAL_ACCEPTANCE_AND_REVIEW_PASS_WITH_NON_BLOCKING_NOTES`
- **Publication state:** `NOT_PERFORMED`
- **Independent packet review:** `PASS_PACKET`
- **Independent implementation review:** `PASS_WITH_NON_BLOCKING_NOTES`
- **Packet date:** 2026-07-27 AEST
- **Packet-authoring baseline:** clean synchronized `main` at
  `e26c2a5a53e1a3283097ba8c6b193d2b7adf5a78`, with only Barry's untracked
  `data/jc_services.csv`.
- **Intended packet subject:**
  `docs: define Goal 008 Judbury deployment evidence`

## Authorized implementation checkpoint

Barry explicitly authorized implementation on 2026-07-27 against published
packet commit `478832240e77388da299e55871bdeb6e386c90c5`, the exact normalized
source and ledger SHA-256 values recorded below, the frozen Goal 007 crosswalk
and `jc_op` SHA-256 values, and the exact combined authority reference.
Implementation and verification remain bounded by the closed allowlist. Git
publication remains owned by the orchestrator and has not been performed.

The required ignored pre-edit baseline passed:

- validation-only run `20260727T053606Z-ec3fbd1eb0ca4255`;
- full run `20260727T053858Z-9c84e12e94704972`;
- manifest `camtrap-evidence-manifest/1.2`;
- manifest SHA-256
  `d4d1599014456a624e41b5f1c094b40e371de1389fdc129183de100acb525f50`;
  and
- structured baseline `13/13/9/4/75/62/0`.

Strict TDD RED evidence is retained under
`outputs/goal008_acceptance/fixtures/`. Before any production edit, the six
focused files failed only for the absent Goal 008 contract:

- configuration: 21 failures;
- immutable source inventory: three failures;
- entity normalization/resolution: 15 failures;
- supported validation runner: three failures;
- portable bundle/source reconstruction: three failures;
- checksum-reclosed Goal 008 lineage: one failure; and
- pipeline non-routing/configuration selection: one failure.

The failures established the missing six-field selection, two non-parser
roles, strict source/ledger readers, 13 deployment entities/links/lineage rows,
lineage 1.1 fields, audit-only readiness, runner gate, portable
reconstruction, and current-config selection. Existing pre-Goal-008 assertions
remained green.

The first production slices are green:

- the focused configuration suite passed at 65 assertions with exact selected,
  explicit-null, legacy-omission, authority, mode, and Goal 007 coupling
  coverage;
- the focused source-inventory suite passed at 32 assertions with exact
  two-role acquisition, parser exclusion, pre/post-copy fixity, source
  mutation, duplicate-role, path-root, and symlink controls;
- the focused entity-resolution suite passed at 104 assertions with closed
  service and ledger schemas, exact aliases and endpoints, retained service
  events and `run_days` states, 13 resolved deployments, 13 physical links,
  13 lineage 1.1 rows, four reciprocal directed relations, legacy lineage 1.0
  compatibility, and audit-only join readiness;
- the focused validation-ledger suite passed with selected/null analytical
  input identity, supported-runner explicit-selection gating, 13 selected
  lineage 1.1 rows, and no `latest` advance; and
- the pipeline smoke suite passed with the selected configuration visible but
  no Goal 008 scientific target or analytical route;
- the portable selected bundle and copied bundle both verified, and a
  checksum-reclosed service-source mutation was rejected in six focused
  assertions; and
- a checksum-reclosed service-event digest, with enclosing entity, readiness,
  and manifest checksums also reclosed, was rejected by semantic
  reconstruction in two focused assertions.

Evidence is retained under `outputs/goal008_acceptance/post/` in
`green-test_config_identity.log`,
`green-test_source_inventory.log`,
`green-test_entity_resolution.log`,
`green-test_validation_ledger.log`, and
`green-test_pipeline_smoke.log`, plus
`green-test_run_bundle-source.log` and
`green-test_run_bundle-lineage.log`.

## Local implementation acceptance

The authorized implementation completed its local core gate:

- authoritative suite: 611 passes, zero failures, zero skips, and the one
  expected CamtrapDP absent-data warning;
- final lint: PASS;
- validation-only run `20260727T082010Z-4bf28cf2a3ff4361`, with
  `PREVIEW.json`, no `COMPLETED.json`, and byte-identical `outputs/latest`
  before and after;
- full run `20260727T082247Z-fc187bae5fa44144`, which advanced
  `outputs/latest` only after completion and verification;
- portable verification: PASS for 91 payload files, with manifest SHA-256
  `1d0461ae1e1073e45b0723104fbfb5e76b33b27fc4d5c8b2074ff5b170923e08`;
- validation/full parity: all five entity artefacts byte-identical;
- scientific invariance: all four validated input objects and 11 Phase 2
  artefacts byte-identical, all ten stable tables byte-identical, and the three
  occupancy tables identical in schema, missingness, non-numeric content, and
  numeric values with maximum difference zero;
- analytical site keys: the same 13 physical-location keys in the same order,
  with no nine-station output; and
- deployment evidence: exact `13/13/9/4/75/62/0`, lineage 1.1, three same-day
  move-pair boundaries, one pm14 gap pair, audit-only `run_days`, false
  analytical routing, and zero joined analytical rows.

The first authoritative pass exposed one standalone load-order compatibility
defect: the legacy CamtrapDP adapter suite loaded source inventory without the
entity-resolution helper. A single focused repair made omitted and explicit
null deployment selection self-contained while retaining the selected
profile's strict helper requirement. The legacy adapter suite then passed 36
assertions, and the complete authoritative suite, lint, validation/full pair,
portable verification, and scientific comparator all reran green.

Raw evidence is retained in `outputs/goal008_acceptance/post/`, especially
`authoritative-tests.log`, `final-lint.log`, `validate-only.log`,
`full-run.log`, `verify-bundle.log`, and `scientific-invariance.log`.
Git publication and exact-SHA CI remain pending and are not claimed here.

## Independent implementation review and adjudication

One independent read-only implementation review returned
`PASS_WITH_NON_BLOCKING_NOTES`. It independently confirmed:

- exact authority and live service, ledger, crosswalk, and operation hashes;
- exactly two dedicated non-parser deployment snapshot roles;
- exact `13/13/9/4/75/62/0` evidence, three same-day move-pair boundaries, one
  pm14 gap pair, and zero analysis-site or joined analytical rows;
- portable verification of the final 91-payload bundle and frozen 89-payload
  pre-edit bundle;
- validation/full parity and complete scientific invariance;
- rejection of checksum-reclosed deployment roles under explicit-null,
  omitted, duplicate-role, and selected configurations; and
- the 29-path closed allowlist, empty index, and unchanged prohibited files.

The review found one real defence-in-depth defect in the standalone service
reader. It recognizes literal `NA`, as required by the packet, but also accepts
blank cells as missing for unused or initial service dates and corresponding
`run_days`. A blank `run_days` value attached to a populated service event is
rejected. Exact authority/configuration, pre/post snapshot hashes, inventory
reconciliation, and portable reconstruction reject altered or checksum-reclosed
source bytes before this direct-reader behavior is reachable for the approved
profile.

The orchestrator accepted the verdict for this exact SHA-pinned profile and
authorized no second repair. The single focused compatibility-repair allowance
is spent. A hard future gate remains: explicit literal-`NA`-only rejection and
negative blank-token tests must be implemented before approving a different
service source, reusing the reader generally, or introducing another
deployment-evidence profile.

Independent-review evidence and adjudication are recorded in
`outputs/goal008_acceptance/review/implementer-report.md`. Publication remains
`NOT_PERFORMED`; exact-SHA CI remains `NOT_RUN`.

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

At packet-authoring time, these facts authorized packet framing only. The
source, ledger, packet commit, and exact combined authority reference then
remained pending Barry's separate exact approval. The authorized checkpoint
above records the later exact approval.

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

Residual limits at packet-review time were intentional: the received CRLF
bytes no longer existed for an independent post-normalization byte comparison,
so the raw arrival hash and line-ending-only transformation remain recorded
provenance; runtime feasibility and scientific invariance were not executed in
that documentation-only task. Barry subsequently supplied the exact approval
recorded above.

During packet authoring, no R, renv, tests, lint, targets, Quarto, Docker,
build, pipeline, network, generated scientific artefact, Git stage, commit,
push, fetch, reset, clean, stash, checkout, or merge was performed.
