# Goal 006 - Validation, repair preview, and source-row lineage

## Objective

Implement the Phase 2 foundation that lets a practitioner see what is wrong
with supplied data, review any proposed change before it is used, and trace
retained operational detection events back to immutable source rows.

A supported validation-only preflight must publish an immutable,
non-overwriting preview record without creating `COMPLETED.json`, publishing a
scientific evidence bundle, or advancing `outputs/latest`. A supported full
run performs the same preflight before analysis. Non-waivable integrity
failures stop before analysis; semantic findings and proposed repairs follow
the explicit policy below. Clean inputs continue through the existing
scientific workflow unchanged.

This is an executor-ready draft, not implementation authority. Barry must
separately approve execution after reviewing the packet. Packet publication is
also outside this authoring task.

## Baseline and future publication gate

- Work only in `/Users/bwbrook/git/camtrap-workflow`.
- Packet authoring starts from clean synchronized `main` at
  `b9934a116c41ab2250c7975daf6d19f1c70effb1`.
- The packet may be published only after Barry approves it. The intended
  publication subject is
  `docs: define Goal 006 validation repair lineage`.
- Before implementation, require clean synchronized `main`, `HEAD^` exactly
  the authoring baseline above, HEAD subject exactly the intended publication
  subject, and an exact six-path `HEAD^..HEAD` diff containing only the four
  Goal 006 packet files and the two Goal 004 design updates named in `Log.md`.
  If the final reviewed packet cannot meet this gate, revise the gate before
  publication rather than guessing during execution.
- No raw data, generated output, preview record, or acceptance artefact may be
  committed.
- Tests must use local or mocked inputs and require no live network.

## Accepted repair authority

The default posture is preview without application.

1. Every proposed repair is proposal-specific. There is no broad
   `apply all repairs` authority.
2. A genuinely unknown value may be filled only after explicit reviewed
   approval of that exact proposal.
3. Explicit supplied deployment or operational evidence may never be
   overwritten by a broad opt-in. An `override_explicit` proposal requires
   proposal-specific approval and a recorded reason.
4. Goal 006 ships no automatic operational-period inference algorithm and no
   general rule for overriding explicit evidence.
5. Original source, proposal, decision, application, and post-validation
   states remain distinct and audit-preserved.
6. A declined or unresolved proposal leaves the source-derived value
   unchanged and records deterministic affected-domain consequences. The
   current full run may continue only when that unchanged state already
   satisfies the current scientific contract; otherwise it stops before
   analysis. General selective module omission belongs to Phase 4.

Approvals use a small provisional control block in the immutable configuration
snapshot. It is an internal Phase 2 evidence-run surface, not a public input
schema or compatibility commitment. Unknown, stale, duplicate, conflicting,
or tampered approval records fail safely.

## Required behavioural contract

### 1. One preflight contract

- The supported runner exposes a validation-only mode by extending
  `scripts/run_full_evidence_run.R`; do not create a second entrypoint.
- Validation-only execution receives a unique invocation identity and
  atomically publishes an immutable preview under a dedicated preflight
  namespace. It never creates `COMPLETED.json`, publishes under completed
  runs, renders a scientific report, or changes `outputs/latest`.
- A normal full run evaluates the same rules and repair decisions from the
  same immutable source and configuration snapshots. A clean run continues;
  an integrity failure stops before analytical targets; unresolved semantic
  consequences follow the accepted policy above.
- Direct or partial target execution remains unable to publish a preview,
  completion record, completed bundle, or latest pointer.

### 2. Internal source-row identity

- A versioned internal audit identity is introduced without changing the
  public v0.1 input schema.
- `resource_id` is deterministic from a logical resource identity and its
  exact content hash. It excludes absolute paths, cache locations, run IDs,
  timestamps, and mutable user labels.
- `source_row_id` is deterministic from `resource_id` and the one-based parsed
  record ordinal. It excludes absolute path, run ID, configuration identity,
  and user-supplied keys.
- Parsed record ordinal means the record order presented by the parser after
  reading the resource. It is not claimed to be a physical file line number or
  a stable semantic entity identity across content-changing runs.

### 3. Structured findings

Findings use versioned machine-readable records and deterministic ordering.
Each record includes a stable rule ID and version, category, severity,
resource/source-row link where applicable, affected field or scope,
consequence, and remediation. Categories are:

- `integrity`: non-waivable corruption, ambiguity, collision, lossy mapping,
  broken key, lineage loss, or unsafe identity;
- `semantic`: scientifically meaningful uncertainty or a proposal that
  requires a decision; and
- `advisory`: information that does not alter or block the run.

Severity does not make an integrity finding waivable. Human-readable messages
may improve without changing stable rule identity.

### 4. Repair state machine

- Repair classes are `representation_normalization`, `fill_unknown`, and
  `override_explicit`.
- Proposal IDs are deterministic from the stable rule, source-row/field scope,
  original state, proposed state, repair class, and proposal algorithm
  version. They exclude invocation and configuration identity.
- Each proposal has a separate decision record (`approved`, `declined`, or
  unresolved) and a separate application record (`applied` or `not_applied`
  with reason). Post-validation records the resulting value and finding state.
- Every application requires an exact approval match. An
  `override_explicit` decision additionally requires a non-empty reason and
  cannot be authorized by any broad setting.
- Approval drift, unknown proposal IDs, duplicate/conflicting decisions,
  changed proposal content, or ledger/fixity tamper is an integrity failure.
- Goal 006 demonstrates one bounded, meaning-preserving representation
  normalization and synthetic/fixture-only `fill_unknown` behaviour. It adds
  no production fill-unknown or operational-period inference algorithm.

### 5. Recorded transformations and lineage

- An adapter mapping may be transformation-only only when it is strictly
  meaning-preserving: it neither fills an unknown nor replaces supplied
  evidence. Any behaviour that fills an unknown is a `fill_unknown` semantic
  proposal; any behaviour that replaces supplied evidence is an
  `override_explicit` semantic proposal. Both require exact proposal-specific
  approval through the repair state machine.
- A collision, ambiguous mapping, or lossy conversion is an integrity failure.
  There is no silent row deletion, fuzzy matching, or grandfathered automatic
  semantic default.
- Sidecar ledgers keep audit identity out of existing scientific table
  columns. Every parser-consumed data row has exactly one source-row ledger
  record and a disposition.
- Every retained operational detection event maps to one or more observation
  source rows. Every excluded observation has an explicit reason and rule.
- Field-level lineage is required for changed values only: original,
  proposal, decision, applied value, and post-validation state.
- Goal 006 does not promise per-cell provenance for downstream aggregate
  tables. Event membership and row/value sidecars are the Phase 2 boundary.

### 6. Manifest and terminology

- Completed Goal 006 bundles use
  `camtrap-evidence-manifest/1.1` and semantically cross-link the validation,
  repair, transformation, row-disposition, changed-field, and event-membership
  artefacts. The portable verifier recomputes their fixity and rejects broken
  cross-links, missing rows, unexplained exclusions, and orphan memberships.
- Existing `camtrap-evidence-manifest/1.0` Goal 005 bundles remain verifiable.
  They are not retroactively required to contain Phase 2 artefacts.
- Current user-facing prose uses `operational detection event`, not
  `independent animal` or an unqualified `independent event`. Existing
  compatibility names may remain until a public migration decision. The
  event-gap rule and its numeric configuration are unchanged.

## Scientific invariance

The clean default Judbury run must propose and apply no semantic repairs. Its
row accounting and operational-event membership must be complete. The
pre/post comparator must preserve:

- exact parsed values, keys, dimensions, missingness, and byte content for the
  10 stable tables named in `Runbook.md`;
- exact keys, dimensions, missingness, and numerical values for the three
  occupancy tables;
- existing methods meaning, parameters, thresholds, and gap rule, apart from
  declared provenance additions and the bounded terminology correction.

Both four-table and local/mocked CamtrapDP fixtures must cover source-row
lineage. Strictly meaning-preserving CamtrapDP mappings may be recorded as
transformations. Existing semantic defaults, including copying a missing
deployment endpoint, replacing missing count with `1`, or replacing missing
flash with `0`, may not auto-apply. They are `fill_unknown` proposals, but Goal
006 adds no production algorithm or authority to apply them. Unresolved source
values remain unchanged, and the run stops before analysis when the current
contract cannot accept them.

## Closed implementation allowlist

Implementation may modify only these paths:

- `_targets.R`;
- existing `R/config.R`, `R/input_loader.R`, `R/camtrapdp_adapter.R`,
  `R/source_inventory.R`, `R/qc_schema.R`, `R/time_qc.R`,
  `R/event_outputs.R`, `R/run_manifest.R`, and `R/run_bundle.R`;
- optional new `R/source_row_lineage.R`, `R/validation_ledger.R`, and
  `R/repair_ledger.R` (omit an unused file; invent no other module);
- `scripts/run_full_evidence_run.R`;
- `config.yml`, `config.template_example.yml`, `config.forest_example.yml`,
  `config.camtrapdp_example.yml`, and `config.camtrapdp_export.yml`;
- `analysis/report.qmd` and `analysis/methods.qmd`;
- `README.md`, `GETTING_STARTED.md`, `docs/reference/config.md`,
  `docs/reference/input_schema_v0.1.md`,
  `docs/reference/camtrapdp_mapping_v0.1.md`,
  `docs/reference/run_manifest.md`, and
  `docs/reference/output_schema_v0.1.md`;
- existing `tests/testthat/test_input_contract.R`,
  `tests/testthat/test_camtrapdp_adapter.R`,
  `tests/testthat/test_source_inventory.R`,
  `tests/testthat/test_config_identity.R`,
  `tests/testthat/test_time_qc.R`,
  `tests/testthat/test_event_outputs.R`,
  `tests/testthat/test_run_manifest.R`,
  `tests/testthat/test_run_bundle.R`, and
  `tests/testthat/test_pipeline_smoke.R`;
- new `tests/testthat/test_source_row_lineage.R`,
  `tests/testthat/test_validation_ledger.R`, and
  `tests/testthat/test_repair_ledger.R`;
- prefix `tests/testthat/fixtures/goal006/`;
- `docs/goals/006-validation-repair-lineage/Log.md`,
  `docs/log/640_goal006_validation_repair_lineage.md`,
  `docs/decisions.md`, and `docs/roadmap.md`.

Any other path requires stop and escalation. In particular, do not modify
`R/custom_funcs.R`, ecological analysis modules, `.github/workflows/ci.yml`,
Docker files, or `renv.lock`; add a dependency; or create another runner.

## Non-goals

Do not redesign nominal station, physical location, deployment, or
`analysis_site`; choose Judbury grouping; add public input fields/API or a
migration policy; change effort, event, ecological method, estimand, threshold,
or gap rule; implement an operational-period inference algorithm; implement
general module statuses or selective execution; add a GUI, LocalMap or ALA
integration, AI interpretation, hosted/network service, signing, or
authentication.

## Acceptance, authority, and stop rules

Use the evidence ladder in `Runbook.md`. Capture the full pre-change Judbury
baseline before the first implementation edit. Require focused fixture proof,
the full scientific comparator, direct partial/full/preflight pointer checks,
lint, the authoritative full test suite, and a full default Judbury run.

One independent implementation review and at most one focused repair are
allowed. Barry must separately authorize execution. After that authorization,
clean local acceptance plus the independent review authorizes exact-path
staging, commit, and push; exact-SHA GitHub Actions is final confirmation.

Stop for a baseline mismatch, a path outside the allowlist, a new dependency,
any unexplained scientific difference, a repair applied without exact
authority, silent row loss, unverifiable lineage, a 1.0 compatibility
regression, or a request for a deferred scientific/product decision. Apply the
80/20 rule: complete the high-value contract, perform one focused review and
repair pass, then report rather than polishing minutiae.
