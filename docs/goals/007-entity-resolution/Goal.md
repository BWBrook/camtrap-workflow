# Goal 007 - Versioned entity-resolution evidence

## Objective

Add a narrow production-path entity resolver that makes camera-trap identity
evidence inspectable without changing the analysis.

Today the compatibility key `site` can stand for a survey label, a physical
camera position, a deployment, and an analytical grouping. That ambiguity can
eventually misroute effort, merge operational detection events, or create
pseudoreplication. Goal 007 separates the factual evidence needed to inspect
those risks while preserving the existing four analytical tables, all current
scientific inputs, and every scientific output exactly.

The resolver must run in both supported validation-only and full evidence
paths. It must publish reconstructable entity records, typed links,
deployment-evidence state, and join-readiness diagnostics in immutable
evidence bundles. It does not select an `analysis_site`, reroute effort or
observations, or change an ecological module.

## Authority and packet state

Barry authorized framing and packet publication on 2026-07-26 after approving
the narrow entity-resolution concept. That authority does not authorize
implementation.

Before implementation, Barry must review and explicitly approve:

1. this complete Goal 007 packet; and
2. the 13-row Judbury crosswalk in
   `judbury_entity_crosswalk.csv`.

Approval of the factual crosswalk approves only the proposed 13 physical
locations to nine nominal stations and four undirected move-pair relations. It
does not approve deployment identities, deployment order or intervals,
`analysis_site` membership, effort routing, event routing, an analytical
denominator, or a public schema.

The crosswalk CSV is a packet review artefact at publication time. It is not a
runtime input until Barry approves its exact version and the authorized
implementation selects it through the provisional internal configuration
reference described below.

## Baseline and future publication gate

- Work only in `/Users/bwbrook/git/camtrap-workflow`.
- Packet authoring starts from clean synchronized `main` at
  `7ad07e936be33b82d9c0423324f6867d541a22bd`.
- The intended packet publication subject is
  `docs: define Goal 007 entity resolution`.
- Before implementation, require clean synchronized `main`, `HEAD^` exactly
  the authoring baseline above, HEAD subject exactly the intended publication
  subject, and an exact seven-path `HEAD^..HEAD` diff containing only the
  paths recorded in `Log.md`.
- If Barry changes any crosswalk row during review, revise the packet and its
  gate before publication. Do not repair or reinterpret the matrix during
  implementation.
- No raw Judbury data, generated output, acceptance evidence, or runtime
  artefact may be committed by this authoring task.
- Tests implemented later must use repository-local or mocked inputs and
  require no live network.

## Accepted entity and scientific decisions

### Distinct concepts

The internal evidence contract keeps these concepts distinct:

- `nominal_grid_station`: a survey-design label;
- `physical_location`: a camera position;
- `deployment`: a supplied camera-deployment identity with explicit interval
  evidence and exactly one physical-location link; and
- `analysis_site`: a purpose-specific derived grouping.

`analysis_site` is explicitly `unselected` in Goal 007. There are zero
memberships. It must never be inferred from a nominal station, a suffix,
coordinates, proximity, deployment identity, current legacy `site`, or any
combination of those fields.

### Judbury facts proposed for approval

The proposed factual matrix has:

- nine nominal stations;
- 13 physical locations;
- four undirected move-pair relations; and
- no authoritative deployment identities, chronology, or intervals.

The live physical identifiers are:

```text
jc_cen
jc_co1
jc_co1_s1
jc_co2
jc_co3
jc_co3_s16
jc_co4
jc_pm12
jc_pm14
jc_pm14_s1
jc_pm23
jc_pm34
jc_pm34_s15
```

Each unsuffixed identifier maps to the same nominal identifier. Each suffixed
identifier maps to its base nominal identifier. The four pairs are:

```text
jc_co1 <-> jc_co1_s1
jc_co3 <-> jc_co3_s16
jc_pm14 <-> jc_pm14_s1
jc_pm34 <-> jc_pm34_s15
```

Barry supplied the Judbury-specific fact that `_S<n>` and the live lowercase
`_s<n>` encode service history for moved camera positions. Never-moved
locations may have no suffix. This is case-study evidence only. It is not a
parser, grouping rule, deployment ordinal, chronology rule, or reusable naming
convention.

In the observed effort order, each suffixed ID is active earlier and its
unsuffixed base is active later. That ordering cannot establish deployment
chronology. A zero means inactive or malfunctioning, and the current effort
matrix contains 40 contiguous active-day runs. Neither a suffix number nor a
contiguous run of ones may create a deployment identity or interval.

### Compatibility and source-specific evidence

- A generic four-table input without an explicit sidecar resolves each legacy
  `site` identifier only to one `physical_location` compatibility identity.
  Its nominal station and deployment remain explicitly unresolved.
- A CamtrapDP input may use supplied `locationID`, `deploymentID`,
  `deploymentStart`, and `deploymentEnd` retained in parsed preflight
  evidence. It must not invent a nominal station.
- Missing optional evidence stays unknown or unresolved. A unique explicit
  absence does not fabricate an entity.
- A duplicate, conflict, collision, orphan reference, ambiguous mapping, or
  tampered evidence record is an integrity failure and stops before analysis.

## Required behavioural contract

### 1. Provisional internal evidence selection

Do not add fields to the public v0.1 input contract or make a public API or
migration commitment.

The internal resolver may add a small provisional `entity_resolution`
configuration block containing only:

- a stable profile identifier that binds the sidecar schema/version;
- a path to one versioned sidecar or an explicit null selection;
- the exact Barry-approved sidecar SHA-256; and
- the stable approval reference needed to bind the selection.

The 13 mappings must not be encoded inline in YAML. When selected, the sidecar
is copied into the immutable source snapshot, included in source fixity, and
linked to the raw and resolved configuration. Before copying, its bytes must
match the configured approved SHA-256; the snapshotted bytes must match again.
A missing, changed, mismatched, unapproved, or extra sidecar fails before
resolution. The default Judbury selection may bind the exact approved packet
CSV; a generic configuration uses an explicit null sidecar.

The sidecar has a distinct `entity_resolution_input` inventory role. It does
not become a fifth analytical table or enter the Goal 006 logical-resource,
source-row, repair, transformation, or event-membership ledgers. Its own row
accounting and evidence links live in the Goal 007 records. Selecting it is
expected to change source/composite fingerprints while leaving all 11 Phase 2
artefacts semantically unchanged.

### 2. Versioned records and deterministic identity

Use closed, versioned internal schemas for entity records, entity links,
deployment lineage, the resolution summary, and join readiness.

An entity record must carry at least:

- record schema and resolver algorithm version;
- entity type;
- deterministic entity ID when resolved;
- exact source identifier and logical evidence namespace;
- resolution state;
- evidence basis and evidence-state classification;
- source-inventory and source-row links where available; and
- a content digest independent of invocation identity.

Allowed resolution states are exactly:

- `resolved`;
- `unresolved`;
- `ambiguous`; and
- `integrity_failure`.

`unresolved` is the honest state for absent optional evidence and may coexist
with the unchanged compatibility analysis. `ambiguous` and
`integrity_failure` are non-waivable integrity stops.

Entity IDs are deterministic from the versioned identity algorithm, entity
type, logical evidence namespace, and exact supplied or approved stable key.
They exclude run IDs, invocation timestamps, absolute paths, cache paths,
mutable labels, coordinates, proximity, and inferred suffix parsing. Link IDs
are deterministic from the versioned link type and exact endpoint identities;
an undirected relation canonicalizes endpoint order without inventing
direction.

### 3. Typed links and deployment evidence

Link types are closed and versioned. Goal 007 needs only:

- `physical_location_to_nominal_grid_station`;
- `deployment_to_physical_location`;
- `service_history_move_pair`; and
- `analysis_site_membership`.

`service_history_move_pair` is undirected and carries no old/new, before/after,
or interval meaning. `analysis_site_membership` has zero records.

Factual crosswalk resolution and deployment resolution are separate. A
supplied deployment is routing-ready only when:

- its supplied deployment identity resolves uniquely;
- it links to exactly one explicit physical location;
- both interval endpoints are explicit, ordered, and attributable to source
  evidence; and
- no competing link or interval exists.

Missing deployment identity, location evidence, or interval evidence remains
unresolved. A non-empty orphan, duplicate, competing interval for the same
deployment identity, reversed interval, or ambiguous observation-to-deployment
mapping is an integrity failure. Overlap between two distinct explicitly
identified deployments is not by itself a merge rule or integrity failure.
Active-day runs, current effort zeros, suffixes, coordinates, and observation
dates never supply missing deployment evidence.

### 4. Supported-path integration

Entity resolution runs after immutable source acquisition and parser-audit
capture, while CamtrapDP source identifiers and endpoints remain available,
and before the supported path can enter the scientific target graph.

Validation-only and full execution from the same source, raw configuration,
and approved sidecar snapshots must produce semantically identical entity
evidence. Goal 007 previews use `camtrap-validation-preview/1.1` with a
required entity-resolution link map while existing 1.0 previews remain
verifiable. A validation preview never creates `COMPLETED.json`, enters
completed runs, renders scientific output, or changes `outputs/latest`.

A supported full run embeds the same entity evidence in its completed bundle.
Direct or partial target execution cannot publish entity evidence as a
validated preview or completed trust record.

The existing `validated_inputs.rds` retains exactly four objects named
`site`, `op`, `obs`, and `taxa`. Entity evidence is sidecar-only and cannot
enter, filter, reorder, regroup, or mutate those objects.

### 5. Audit-level join readiness only

`join_readiness.json` may classify effort and observation evidence against a
named entity level as:

- `unique`;
- `unresolved`; or
- `ambiguous`.

It records counts, rule/version, exact evidence basis, and attributable source
scope. It is an audit diagnostic, not a joined analytical table. `unique`
means only that the explicit evidence supports one mapping at that named
level. `unresolved` cannot be converted to a zero, an exclusion, or a fallback
deployment. `ambiguous` is an integrity stop.

No join-readiness result may change effort cells, observation membership,
event construction, denominators, estimands, thresholds, module eligibility,
or any scientific input or output.

### 6. Review artefacts and semantic verification

Both supported evidence modes publish these reconstructable records under one
versioned entity evidence namespace:

```text
entity_resolution.csv
entity_links.csv
deployment_lineage.csv
entity_resolution_summary.json
join_readiness.json
```

`entity_resolution_summary.json` records entity and link counts by type/state,
the selected evidence profile, unresolved and ambiguous counts, integrity
findings, and:

```text
analysis_site_status = unselected
analysis_site_membership_count = 0
```

The other records cross-link to the immutable source inventory, parsed
source-row evidence where available, raw/resolved configuration, and selected
crosswalk version. CSV ordering and JSON ordering are deterministic.

New completed Goal 007 bundles use
`camtrap-evidence-manifest/1.2`. Schema 1.2 retains the complete 1.1 Phase 2
contract and adds a required entity-resolution link block. A distinct schema
version is preferred because entity evidence is now mandatory and must be
semantically reconstructed; silently adding optional payloads to 1.1 would
make the contract ambiguous.

The portable verifier dispatches 1.2 explicitly and reconstructs all five
records from immutable parser evidence, raw/resolved configuration, and the
snapshotted sidecar when selected. Rewriting hashes around altered entity
records must fail. It also requires the configured approved SHA-256, source
inventory SHA-256, summary SHA-256, and reconstructed sidecar SHA-256 to agree;
reclosing payload hashes around altered crosswalk bytes cannot create new
authority. Existing manifest 1.1 and 1.0 bundles continue to verify under their
original contracts and are not required to contain Goal 007 records.

## Scientific invariance

Goal 007 must preserve exactly:

- validated `site`, `op`, `obs`, and `taxa`, including names, values, types,
  keys, row and column order, dimensions, and missingness;
- every Goal 006 Phase 2 document, repair decision, transformation, parsed-row
  disposition, exclusion reason, and post-validation result;
- operational detection event membership and excluded-observation accounting;
- effort values and summaries;
- operational event counts and grouping;
- the configured event gap rule and every method, threshold, parameter,
  estimand, denominator, and interpretation;
- all 10 stable comparator tables named in `Runbook.md`; and
- all three occupancy comparator tables named in `Runbook.md`, with zero
  numerical difference.

The current scientific engine continues to consume the legacy 13 physical
`site` keys for Judbury. A resolved nominal-station crosswalk is audit evidence
only. It does not collapse those keys, change a grouping, or authorize a
nine-station analysis.

## Closed implementation allowlist

Implementation may modify only:

- `_targets.R`;
- existing `R/config.R`, `R/source_inventory.R`, `R/input_loader.R`,
  `R/camtrapdp_adapter.R`, `R/validation_ledger.R`, `R/run_manifest.R`, and
  `R/run_bundle.R`;
- optional new `R/entity_resolution.R` only;
- `scripts/run_full_evidence_run.R`;
- `config.yml`, `config.template_example.yml`, `config.forest_example.yml`,
  `config.camtrapdp_example.yml`, and `config.camtrapdp_export.yml`, and only
  where the provisional internal selection must be explicit;
- `docs/reference/config.md`, `docs/reference/input_schema_v0.1.md`,
  `docs/reference/camtrapdp_mapping_v0.1.md`,
  `docs/reference/run_manifest.md`, and
  `docs/reference/output_schema_v0.1.md`;
- existing `tests/testthat/test_config_identity.R`,
  `tests/testthat/test_source_inventory.R`,
  `tests/testthat/test_input_contract.R`,
  `tests/testthat/test_camtrapdp_adapter.R`,
  `tests/testthat/test_validation_ledger.R`,
  `tests/testthat/test_run_manifest.R`,
  `tests/testthat/test_run_bundle.R`, and
  `tests/testthat/test_pipeline_smoke.R`;
- new `tests/testthat/test_entity_resolution.R`;
- prefix `tests/testthat/fixtures/goal007/`;
- `docs/goals/007-entity-resolution/Log.md`;
- `docs/log/650_goal007_entity_resolution.md`;
- `docs/decisions.md` and `docs/roadmap.md`; and
- `docs/design/004-product-blueprint/decision_register.md` and
  `docs/design/004-product-blueprint/development_roadmap.md`.

The approved packet crosswalk may be read and snapshotted exactly but not
edited during implementation. Any needed mapping change returns to Barry and
requires packet revision.

Any other modified path requires stop and escalation. In particular, do not
modify `R/custom_funcs.R`, `R/event_outputs.R`, effort, detection-history,
occupancy, community, diversity, traits, sensitivity, or other ecological
modules; reports; raw Judbury data; `renv.lock`; Docker files; or
`.github/workflows/ci.yml`.

## Non-goals

Do not:

- choose or populate `analysis_site`;
- infer a crosswalk, move direction, deployment identity, chronology, or
  interval;
- reroute effort, observations, events, or ecological analyses;
- change four-table fields, public API, migration, or compatibility policy;
- create a production repair or operational-period inference rule;
- add a dependency, new runner, GUI, LocalMap, ALA, AI, hosted service, or
  network acquisition;
- implement resolved profile precedence, a module planner, or a module-status
  envelope;
- complete the full Phase 3 CamtrapDP, profile, effort, or event work; or
- change CI workflow definitions.

## Acceptance, review, and stop rules

Use the complete evidence ladder in `Runbook.md`. Capture the default Judbury
baseline before the first implementation edit. Require focused four-table,
crosswalk, negative-control, and opaque-ID CamtrapDP fixtures; validation/full
parity; semantic reclosure and tamper rejection; legacy 1.0/1.1 verification;
the full scientific comparator; lint; authoritative tests; and a full default
run.

After Barry separately authorizes execution, obtain one independent
implementation review and allow at most one focused repair. Clean local
acceptance plus that review authorizes exact-path staging, commit, and push.
An exact-SHA GitHub Actions run is final remote confirmation.

Stop immediately for:

- an inferred crosswalk, suffix rule, coordinate merge, move direction,
  deployment identity, chronology, or interval;
- any populated `analysis_site` membership;
- any scientific input, output, Phase 2, event-membership, effort, method, or
  threshold drift;
- ambiguous evidence treated as resolved;
- a public contract decision or production repair rule;
- a new dependency, runner, CI edit, or out-of-allowlist path; or
- a packet, baseline, sidecar, or authority mismatch.

Apply the 80/20 rule: complete and verify the high-value vertical slice,
perform one focused self-review and one independent review with at most one
material repair, then return concise raw evidence rather than polishing
minutiae.
