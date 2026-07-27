# Goal 008 - Authoritative Judbury deployment and service evidence

## Objective

Bind Barry-supplied Judbury deployment and service facts into immutable audit
evidence without changing the analysis.

Goal 007 established the identity framework but intentionally left Judbury
deployments unresolved. Barry has now supplied the service table and its
interpretation. Goal 008 proposes one explicit deployment for each of the 13
accepted physical locations, exact deployment-to-physical links, declared
day-precision spans, service-event evidence, and four directed
predecessor/successor relations.

Deployment spans, service events, and daily operation remain separate
concepts. The goal adds evidence only. It does not route effort, observations,
events, denominators, modules, or scientific targets.

## Packet and authority state

- **Packet state:** `REVIEWED_AWAITING_BARRY_EXACT_APPROVAL`
- **Authoring date:** 2026-07-27 AEST
- **Authoring baseline:** clean synchronized `main` at
  `e26c2a5a53e1a3283097ba8c6b193d2b7adf5a78`, with Barry's untracked
  `data/jc_services.csv` as the only initial worktree entry.
- **Implementation authority:** not granted.
- **Publication authority:** not exercised by this authoring task.

Barry has confirmed the scientific meaning of `data/jc_services.csv` and
`data/jc_op.csv` described below. That interpretation authorizes this packet
to be framed. It does not approve the packet bytes or authorize implementation.

Before implementation, Barry must separately and explicitly approve:

1. the complete published Goal 008 packet;
2. the LF-normalized `data/jc_services.csv` at exact SHA-256
   `f33eeac9d70126966717c8e3f4731c00a97cbc3a34c2f44ce5c70d91c7d5283a`;
3. `judbury_deployment_ledger.csv` at exact SHA-256
   `0921eb8845c2bb1ad5760271f283ab2783735b7739e254c67e9243bc906f3ebf`;
4. the exact authority reference:

```text
goal008-judbury-deployment-evidence-source-sha256-f33eeac9d70126966717c8e3f4731c00a97cbc3a34c2f44ce5c70d91c7d5283a-ledger-sha256-0921eb8845c2bb1ad5760271f283ab2783735b7739e254c67e9243bc906f3ebf
```

5. the packet commit SHA and exact ten-path packet diff recorded in `Log.md`.

Approval resolves only the 13 deployment identities, their unique physical
links, their declared spans and services, and the four directed chronology
relations enumerated here. It does not approve `analysis_site`, a nine-station
analysis, analytical routing, effort rewriting, a failure diagnosis, a
last-image algorithm, a public schema, or any ecological method.

## Proposed packet-publication gate

The intended packet subject is:

```text
docs: define Goal 008 Judbury deployment evidence
```

The authoring task must not stage, commit, push, fetch, reset, clean, stash, or
publish. A later publication action must require:

- branch `main`;
- clean index and no paths outside the exact ten paths in `Log.md`;
- `HEAD` and the locally known `origin/main` both equal to the authoring
  baseline above before the packet commit;
- one packet commit with the exact subject above;
- `HEAD^` equal to the authoring baseline;
- exactly the ten packet paths in `HEAD^..HEAD`; and
- the exact source and ledger hashes above.

If Barry requests any packet, source, or ledger change, revise the packet and
all affected hashes and gates before publication. Do not reinterpret or repair
the evidence during implementation.

## Accepted evidence

### Three separate concepts

`deployment_span`
  A declared interval for one stable deployment identity at exactly one
  physical location.

`service_event`
  A dated source event normalized from one non-NA `sN.date` cell. It carries
  the exact source row, service label, ISO date, event role, and supplied
  `sN.run_days` value when present.

`daily_operation`
  The existing day-level state in `data/jc_op.csv`. It is not a deployment
  span or a malfunction diagnosis.

These concepts may be cross-linked for audit but must never be collapsed into
one field or used to fill one another.

### Service-source interpretation

For each physical-location row in `data/jc_services.csv`:

- the first non-NA `sN.date` is deployment start at that location;
- intermediate non-NA dates are services; and
- the last non-NA date is deployment end and the final service, removal, move,
  or study-end boundary recorded by the source.

Original physical locations start at S0. Later moved locations start at their
first non-NA service label. Dates have day precision. Endpoints are inclusive
at day precision and event time within the day is unknown.

The source contains:

- 13 exact physical-location rows;
- 75 non-NA service dates; and
- 62 non-NA `sN.run_days` values.

`sN.run_days` is retained source metadata only. It does not exactly reproduce
`data/jc_op.csv` active totals and must not regenerate, override, reconcile,
validate as equivalent to, or route effort. Its parsed total of 7842 is only a
file-integrity diagnostic.

The exact raw-to-canonical aliases are:

```text
jc_cen       -> jc_cen
jc_co_1      -> jc_co1
jc_co_1_s1   -> jc_co1_s1
jc_co_2      -> jc_co2
jc_co_3      -> jc_co3
jc_co_3_s1-6 -> jc_co3_s16
jc-co-4      -> jc_co4
jc-pm-12     -> jc_pm12
jc-pm-14     -> jc_pm14
jc-pm-14_s1  -> jc_pm14_s1
jc-pm-23     -> jc_pm23
jc-pm-34     -> jc_pm34
jc-pm-34_s1-5 -> jc_pm34_s15
```

These are exact Judbury aliases. They are not a parser rule, punctuation
normalization, case normalization, suffix rule, or reusable naming
convention. Any unlisted raw identifier is an integrity failure.

### Daily-operation authority

`data/jc_op.csv` remains authoritative for daily operation:

- `1` means the camera operated for at least part of that calendar day; and
- `0` means the camera was not operating that day.

The table was inferred from the last image or observed operation at service.
Observed operating-at-service status overrides last-image inference. Goal 008
uses the existing table exactly as supplied. It does not rerun a last-image
algorithm, invent a failure cause, distinguish inactivity from malfunction,
or change a cell.

The authoring baseline SHA-256 of `data/jc_op.csv` is:

```text
28222586fa232fccc46bfab5e8c07e0c453f07387ebe4eb95b9a90e4687033a3
```

### Goal 007 identity authority

Goal 007 remains frozen at:

- crosswalk path
  `docs/goals/007-entity-resolution/judbury_entity_crosswalk.csv`;
- crosswalk schema `camtrap-entity-crosswalk/1.0`;
- crosswalk SHA-256
  `553abada14493f3a5f0ae3c072523b6d5cc0d0c6a6c6480ca17a9e3331f2d8ec`;
- 13 physical locations;
- nine nominal grid stations;
- four undirected service-history move pairs; and
- `analysis_site_status = unselected` with zero memberships.

Goal 008 consumes those exact resolved physical identities and move-pair facts.
It does not edit the crosswalk, change its authority reference, replace its
configuration selection, add direction to `service_history_move_pair`, or
fold deployment approval into Goal 007 authority.

## Proposed 13 deployments

The ledger order is the accepted Goal 007 physical-location order.

| Deployment ID | Raw service row | Physical location | Nominal station | Start | End | Service dates | Lineage |
| --- | --- | --- | --- | --- | --- | ---: | --- |
| `judbury_dep_jc_cen` | `jc_cen` | `jc_cen` | `jc_cen` | S0 2019-06-05 | S7 2022-05-10 | 8 | none |
| `judbury_dep_jc_co1` | `jc_co_1` | `jc_co1` | `jc_co1` | S1 2019-10-14 | S7 2022-05-10 | 7 | after `judbury_dep_jc_co1_s1` |
| `judbury_dep_jc_co1_s1` | `jc_co_1_s1` | `jc_co1_s1` | `jc_co1` | S0 2019-06-05 | S1 2019-10-14 | 2 | before `judbury_dep_jc_co1` |
| `judbury_dep_jc_co2` | `jc_co_2` | `jc_co2` | `jc_co2` | S0 2019-06-05 | S7 2022-05-10 | 8 | none |
| `judbury_dep_jc_co3` | `jc_co_3` | `jc_co3` | `jc_co3` | S6 2021-11-29 | S7 2022-05-10 | 2 | after `judbury_dep_jc_co3_s16` |
| `judbury_dep_jc_co3_s16` | `jc_co_3_s1-6` | `jc_co3_s16` | `jc_co3` | S0 2019-06-05 | S6 2021-11-29 | 7 | before `judbury_dep_jc_co3` |
| `judbury_dep_jc_co4` | `jc-co-4` | `jc_co4` | `jc_co4` | S0 2019-06-05 | S7 2022-05-10 | 8 | none |
| `judbury_dep_jc_pm12` | `jc-pm-12` | `jc_pm12` | `jc_pm12` | S0 2019-06-05 | S7 2022-05-10 | 8 | none |
| `judbury_dep_jc_pm14` | `jc-pm-14` | `jc_pm14` | `jc_pm14` | S2 2020-02-26 | S7 2022-05-10 | 6 | after `judbury_dep_jc_pm14_s1` |
| `judbury_dep_jc_pm14_s1` | `jc-pm-14_s1` | `jc_pm14_s1` | `jc_pm14` | S0 2019-06-05 | S1 2019-10-14 | 2 | before `judbury_dep_jc_pm14` |
| `judbury_dep_jc_pm23` | `jc-pm-23` | `jc_pm23` | `jc_pm23` | S0 2019-06-05 | S7 2022-05-10 | 8 | none |
| `judbury_dep_jc_pm34` | `jc-pm-34` | `jc_pm34` | `jc_pm34` | S5 2021-06-22 | S7 2022-05-10 | 3 | after `judbury_dep_jc_pm34_s15` |
| `judbury_dep_jc_pm34_s15` | `jc-pm-34_s1-5` | `jc_pm34_s15` | `jc_pm34` | S0 2019-06-05 | S5 2021-06-22 | 6 | before `judbury_dep_jc_pm34` |

The four directed predecessor-to-successor relations are:

```text
judbury_dep_jc_co1_s1   -> judbury_dep_jc_co1
judbury_dep_jc_co3_s16  -> judbury_dep_jc_co3
judbury_dep_jc_pm14_s1  -> judbury_dep_jc_pm14
judbury_dep_jc_pm34_s15 -> judbury_dep_jc_pm34
```

The co1, co3, and pm34 pairs share an end/start calendar date. Because time
within the day is unknown, that is a boundary fact, not a full-day overlap
claim. It cannot assign an observation or effort cell.

For pm14, the source documents no deployment at either paired physical
location between the predecessor end on 2019-10-14 and successor start on
2020-02-26. Goal 008 records that declared gap without rewriting the daily
operation table or inferring a cause.

## Exact packet evidence

### Normalized service source

- Path: `data/jc_services.csv`
- Logical schema: `judbury-camera-service-history/1.0`
- Proposed version: `judbury-jc-services/1.0.0-proposed`
- Raw arrival SHA-256 before CRLF normalization:
  `5c9db8f65cc11f9acf2447fa6c0354e52da6553227c618fae26a4d3942384d8f`
- LF-normalized SHA-256:
  `f33eeac9d70126966717c8e3f4731c00a97cbc3a34c2f44ce5c70d91c7d5283a`
- Authorized authoring change: CRLF to LF and mode 0700 to 0644 only.

### Proposed deployment ledger

- Path:
  `docs/goals/008-judbury-deployment-evidence/judbury_deployment_ledger.csv`
- Schema: `camtrap-deployment-evidence-ledger/1.0`
- Version: `judbury-deployment-evidence-ledger/1.0.0-proposed`
- State on every row: `proposed_for_barry_exact_approval`
- SHA-256:
  `0921eb8845c2bb1ad5760271f283ab2783735b7739e254c67e9243bc906f3ebf`

The packet ledger is review evidence, not runtime authority. Its proposed
state remains in the immutable file after approval; the separate Barry
receipt and exact configured authority reference provide runtime authority.

## Required behavioural contract

### 1. Separate provisional deployment-evidence selection

Do not alter or overload the existing `entity_resolution` block. Add a
separate provisional internal `deployment_evidence` selection with exactly:

```text
profile_id
service_sidecar_path
service_sidecar_sha256
deployment_ledger_path
deployment_ledger_sha256
authority_reference
```

All six values are either explicit nulls or one complete exact selection.
The selected Judbury profile is
`judbury-deployment-evidence/1.0.0-proposed`. Its two paths, two SHA-256
values, and authority reference must equal the Barry-approved receipt.

Mappings and dates must not be copied inline into YAML. Generic and CamtrapDP
ingestion configurations use the explicit null selection. `config.yml` and
`config.camtrapdp_export.yml` both use the selected profile because both are
Judbury four-table configurations with the separately approved Goal 007
crosswalk. Selection in the export configuration changes entity audit
evidence only; it does not change current CamtrapDP export behaviour.

### 2. Immutable acquisition and fixity

Before parsing:

- verify both repository files against the configured approved hashes;
- snapshot both into dedicated immutable source locations;
- inventory the service file as `deployment_service_input`;
- inventory the ledger as `deployment_ledger_input`;
- verify both snapshotted hashes again; and
- parse only the immutable copies.

Neither file becomes a fifth or sixth analytical table. Neither enters Goal
006 logical-resource, repair, transformation, changed-field, or operational
event-membership accounting. Goal 008 accounts for every source and ledger
row within the existing entity-evidence path.

A missing, changed, unapproved, path-escaping, symlinked, duplicate, extra, or
unselected deployment-evidence sidecar is an integrity failure. Selecting
deployment evidence is expected to change source, raw/resolved configuration,
and composite fingerprints. It must not change analytical input content.

### 3. Deterministic service-event normalization

Parse the exact closed source header:

```text
site,s0.date,s1.run_days,s1.date,s2.run_days,s2.date,s3.run_days,s3.date,s4.run_days,s4.date,s5.run_days,s5.date,s6.run_days,s6.date,s7.run_days,s7.date
```

For each row, inspect service labels S0 through S7 in order:

- treat the literal `NA` as missing;
- parse every non-NA date strictly from the supplied day/month/year format;
- emit a deterministic internal event with exact raw ID, canonical physical
  ID, source row ordinal, service label, ISO date, and literal `run_days`
  value or missing state;
- classify the first event as `deployment_start`, the last as
  `deployment_end`, and any intervening event as `service`;
- compute a content digest over the ordered event list; and
- compare start label/date, end label/date, and event count with the approved
  ledger row.

The last event remains attributable as the final service/removal/move/study
end even though the normalized role is `deployment_end`. No separate service
event CSV is added. The ordered event digest and count are carried in
`deployment_lineage.csv`.

Reject a malformed date, duplicate or missing service label, reversed date
order, unlisted raw alias, duplicate physical mapping, source/ledger count or
endpoint disagreement, orphan row, extra row, or conflicting lineage edge.
Retain every `run_days` literal and missing state in the normalized digest, but
never sum or compare it with effort during production execution.

### 4. Narrow deployment-lineage schema 1.1

Bump only the existing deployment-lineage record schema from
`camtrap-deployment-lineage/1.0` to
`camtrap-deployment-lineage/1.1`.

Retain the existing fields and add the minimum exact evidence needed for:

- canonical physical-location identifier as well as entity ID;
- date precision and endpoint semantics;
- start and end service labels;
- service-event count and ordered event digest;
- nullable predecessor and successor deployment identifiers;
- service-source schema, version, inventory path, SHA-256, row ordinal, and
  deterministic source-row identity;
- ledger schema, version, inventory path, SHA-256, row ordinal, and
  deterministic source-row identity;
- exact approval reference;
- daily-operation inventory path and SHA-256; and
- `run_days_disposition = audit_only_not_effort_authority`.

For the approved Judbury profile, publish exactly 13 resolved lineage rows.
For existing generic or CamtrapDP paths, Goal 008-specific service fields are
nullable and current explicit-source behaviour remains unchanged. Do not
change the CamtrapDP adapter or invent service evidence for those paths.

The existing entity record, entity link, entity summary, join-readiness,
preview, and completed-manifest schema identifiers remain unchanged. If
implementation proves another schema or manifest version unavoidable, stop
and return for packet revision before editing that contract.

### 5. Resolve exact deployments after approval only

After every authority and fixity gate passes:

- resolve 13 stable deployment entities from the explicit
  `judbury_dep_<physical_location_id>` identifiers;
- add exactly 13 `deployment_to_physical_location` links;
- link each deployment to exactly one accepted Goal 007 physical location;
- publish exactly 13 lineage rows with the approved spans;
- reproduce four unique directed predecessor/successor relations; and
- retain the four Goal 007 `service_history_move_pair` links as undirected.

Do not add a chronology link type. Direction lives only in the versioned
deployment-lineage evidence. Do not change nominal or physical identities.
`analysis_site` remains unselected with zero memberships.

### 6. Preserve the five Goal 007 artefacts

Use the existing closed namespace:

```text
provenance/entity_resolution/entity_resolution.csv
provenance/entity_resolution/entity_links.csv
provenance/entity_resolution/deployment_lineage.csv
provenance/entity_resolution/entity_resolution_summary.json
provenance/entity_resolution/join_readiness.json
```

Do not add, rename, nest, redirect, or remove an artefact. Validation-only and
full execution from the same immutable source and configuration must publish
semantically identical, preferably byte-identical, copies of all five.

Validation previews remain `camtrap-validation-preview/1.1`. New completed
bundles remain `camtrap-evidence-manifest/1.2`. The 1.2 entity link block and
closed five-file namespace remain unchanged. Portable verification must
continue to verify legacy manifest 1.0 and 1.1 bundles under their original
contracts.

Semantic reconstruction must rebuild the source events, deployment records,
physical links, lineage rows, summary counts, and join readiness from the
immutable service source, ledger, Goal 007 crosswalk, raw/resolved
configuration, and existing parser evidence. A checksum-reclosed change to a
source row, ledger row, service event, deployment span, lineage edge, entity,
link, summary, or readiness record must fail.

### 7. Join readiness remains audit-only

The 13 explicit one-to-one deployment links may make current Judbury source
keys unique at the deployment level for audit. That classification cannot:

- join or filter analytical rows;
- select observations by interval;
- change an effort cell or denominator;
- change event construction or membership;
- aggregate paired physical locations;
- select a nominal or nine-station analysis;
- set a module eligibility result; or
- enter the scientific target graph.

### 8. Defer the exporter envelope

`R/camtrapdp_export.R` currently derives export deployment start and end from
the first and last `jc_op == 1` dates. That is an operational envelope, not
the Goal 008 declared deployment span.

Record this as explicit deferred technical debt. Goal 008 does not modify the
adapter, exporter, CamtrapDP mapping, export output, or export tests. It does
not silently substitute the new ledger into export behaviour. Any future
export change requires its own packet, compatibility decision, and validation.

## Scientific invariance

Goal 008 must preserve exactly:

- `data/jc_op.csv` bytes, dimensions, row/column order, dates, column names,
  cell values, and daily-state meaning;
- validated `site`, `op`, `obs`, and `taxa`, including names, values, types,
  keys, order, dimensions, and missingness;
- all 11 Goal 006 Phase 2 artefacts, repair decisions, transformations,
  parsed-row dispositions, exclusions, post-validation results, and source-row
  accounting for the four analytical tables;
- operational detection event membership and excluded-observation reasons;
- effort values and summaries;
- event counts, grouping, gap rule, methods, thresholds, parameters,
  estimands, denominators, and interpretation; and
- these 13 scientific comparator tables:

```text
effort_summary.csv
time_qc_summary.csv
time_qc_flags.csv
events_per_day.csv
event_spacing.csv
detection_history.csv
community_presence.csv
community_abundance.csv
alpha_diversity.csv
beta_diversity.csv
occupancy_summary.csv
occupancy_aic.csv
occupancy_predictions.csv
```

The first ten tables must be byte- or canonical-value-identical under the
existing Goal 007 comparison rules. The three occupancy tables must have zero
numerical difference and identical non-numeric content.

The scientific engine continues to consume the same 13 legacy physical `site`
keys. Goal 008 changes only source/configuration fingerprints and the intended
existing entity-evidence records. It does not create a nine-station result.

## Closed future implementation allowlist

An authorized implementation may modify only:

- existing `R/config.R`;
- existing `R/source_inventory.R`;
- existing `R/entity_resolution.R`;
- existing `R/validation_ledger.R`;
- existing `R/run_bundle.R`;
- existing `scripts/run_full_evidence_run.R`;
- `config.yml`, `config.template_example.yml`, `config.forest_example.yml`,
  `config.camtrapdp_example.yml`, and `config.camtrapdp_export.yml`, only to
  add the separate exact selection or explicit nulls;
- existing `tests/testthat/test_config_identity.R`;
- existing `tests/testthat/test_source_inventory.R`;
- existing `tests/testthat/test_entity_resolution.R`;
- existing `tests/testthat/test_validation_ledger.R`;
- existing `tests/testthat/test_run_bundle.R`;
- existing `tests/testthat/test_pipeline_smoke.R`;
- prefix `tests/testthat/fixtures/goal008/`;
- `docs/reference/config.md`;
- `docs/reference/input_schema_v0.1.md`;
- `docs/reference/run_manifest.md`;
- `docs/reference/output_schema_v0.1.md`;
- `docs/goals/008-judbury-deployment-evidence/Log.md`;
- new `docs/log/660_goal008_judbury_deployment_evidence.md`;
- `docs/decisions.md`;
- `docs/roadmap.md`; and
- `docs/design/004-product-blueprint/decision_register.md` and
  `docs/design/004-product-blueprint/development_roadmap.md`.

The approved `data/jc_services.csv`, its readme, the packet ledger, Goal,
Plan, and Runbook are immutable implementation inputs and may not be modified.
The Goal 007 crosswalk and authority remain immutable.

Any need outside this allowlist requires stop and packet revision. In
particular, implementation must not modify:

- `_targets.R`;
- `R/input_loader.R`;
- `R/camtrapdp_adapter.R`;
- `R/camtrapdp_export.R`;
- `R/run_manifest.R`;
- any effort, event, detection-history, occupancy, community, diversity,
  traits, sensitivity, report, or ecological module;
- `docs/reference/camtrapdp_mapping_v0.1.md`;
- reports or generated scientific output;
- `renv.lock`, `DESCRIPTION`, dependencies, Docker files, or CI workflows; or
- manifest, preview, public input, or public output schema versions.

## Non-goals

Goal 008 does not:

- select or populate `analysis_site`;
- perform a nine-station analysis;
- route effort, observations, service events, operational detection events,
  denominators, thresholds, modules, or scientific targets;
- rewrite, reconcile, infer, fill, or validate effort from `sN.run_days`;
- classify malfunction, theft, inactivity cause, camera model, or service
  action;
- implement a last-image algorithm, inference rule, repair rule, or
  operational-period algorithm;
- add a public field, schema, API, migration, or compatibility commitment;
- alter CamtrapDP ingestion, adapter, export, or publication behaviour;
- change a GUI, report, ecological method, target graph, or scientific output;
  or
- complete the remaining Phase 3 profile, effort, event, adapter, or
  `analysis_site` work.

## Acceptance and stop rules

Implementation acceptance requires:

- exact approved source, ledger, packet, and authority-reference identity;
- 13 ledger rows and unique stable deployment IDs;
- exact 13 raw aliases and canonical physical IDs in Goal 007 order;
- 13 unique physical links, nine nominal stations, four move pairs, four
  unique directed predecessor/successor relations, and zero `analysis_site`
  memberships;
- exact start/end labels and dates, day precision, endpoint semantics, and 75
  normalized service events;
- all 62 supplied non-NA `run_days` values and missing states retained in
  event digests with audit-only disposition;
- rejection of duplicate, orphan, conflicting, reversed, tampered, changed,
  path-escaping, unapproved, or extra source evidence;
- unchanged `jc_op` bytes and semantics;
- validation/full parity for all five entity artefacts;
- portable semantic reconstruction and checksum-reclosure rejection;
- manifest 1.2 publication with retained legacy 1.0/1.1 verification;
- exact scientific invariance above;
- lint, focused tests, authoritative tests, validation-only execution, one
  full default run, portable verification, and latest-pointer safety;
- one independent packet review before Barry's exact approval;
- one independent implementation review after local acceptance; and
- at most one focused material repair at each review stage.

Stop immediately for:

- any source or ledger fact that cannot be reproduced exactly;
- any additional scientific interpretation beyond Barry's supplied service
  and daily-operation meanings;
- an inferred alias, deployment, span, event, failure cause, or routing rule;
- any populated `analysis_site` membership or nine-station result;
- scientific input, output, Phase 2, event-membership, effort, method,
  threshold, or comparator drift;
- a changed Goal 007 crosswalk or authority;
- a new artefact, manifest version, dependency, runner, CI edit, or
  out-of-allowlist path; or
- an authority, baseline, fixity, reconstruction, or review mismatch.

Complete the bounded evidence slice, perform one focused self-review and one
independent review, repair at most one material packet defect, then return the
exact evidence for Barry's decision. Do not implement while approval remains
pending.
