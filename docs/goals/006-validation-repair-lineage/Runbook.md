# Goal 006 execution runbook - validation, repair, and lineage

## Purpose and authorization

This runbook governs the proposed Phase 2 implementation. It creates a
validation preview and auditable repair/lineage evidence while preserving the
Goal 005 immutable evidence-run trust root and current scientific results.

The packet is currently `DRAFT_FOR_BARRY_REVIEW`. Framing it does not
authorize packet publication or implementation. Barry must approve execution.
After approval, the orchestrator may publish the exact six-path packet with
subject:

```text
docs: define Goal 006 validation repair lineage
```

Implementation may begin only after the baseline gate below passes. Clean
local acceptance and one independent review authorize the implementation
commit/push within the closed allowlist; exact-SHA CI is the final remote
confirmation. A missing or failed matching CI run leaves the goal
`NOT_FINAL`.

## Baseline gate

From `/Users/bwbrook/git/camtrap-workflow`, run:

```sh
pwd
git branch --show-current
git rev-parse HEAD
git rev-parse HEAD^
git rev-parse origin/main
git status --short --branch
git show -s --format=%s HEAD
git diff --name-status HEAD^..HEAD
```

Require:

- branch `main`, clean index/worktree, and synchronized `origin/main`;
- `HEAD^` =
  `b9934a116c41ab2250c7975daf6d19f1c70effb1`;
- exact packet publication subject above; and
- exactly the six paths recorded in `Log.md`, with no other parent diff.

Do not fetch, reset, clean, stash, merge, or reconcile a mismatch. Stop and
return the exact state.

## Pre-edit baseline capture

Before editing implementation files, create ignored raw evidence beneath:

```text
outputs/goal006_acceptance/pre/
outputs/goal006_acceptance/fixtures/
outputs/goal006_acceptance/post/
outputs/goal006_acceptance/review/
```

Record the packet commit/parent/subject/path diff, status, raw pointer bytes,
relevant source/config file SHA-256 values, target metadata, session/package
versions, row/key ordering, and comparator canonicalisation rules. Then run
the full default Judbury workflow at the packet-publication state.

Preserve raw logs and copies of these 10 stable tables:

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
```

Also preserve the three occupancy tables:

```text
occupancy_summary.csv
occupancy_aic.csv
occupancy_predictions.csv
```

Retain normalized methods text, current source row counts, current event
membership inputs, full output path/hash inventory, and the exact successful
command output. Stop before editing if the baseline run or evidence capture
fails. Do not commit acceptance evidence.

## Roles and mutation boundary

The implementation owner may modify only the closed allowlist in `Goal.md`.
The three optional new R modules and three named new test files are the only
new code files. Tests may create temporary files and ignored acceptance
evidence. No new package may be added.

The orchestrator owns acceptance, exact-path staging, commit, push, and CI
confirmation. Barry owns any public schema, entity grouping, scientific
method, threshold, operational-inference, module-planner, or interface
decision. Use one independent read-only implementation review and at most one
focused repair.

## Contract details

### Resource and source-row identity

Define one versioned logical resource registry for parser-consumed tabular
resources. At minimum, a resource record carries:

- audit schema and resource kind;
- logical resource name and input mode;
- exact byte SHA-256 and deterministic `resource_id`;
- parsed record count and parser/adapter version; and
- link to the Goal 005 source inventory record.

Derive each `source_row_id` only from `resource_id` plus its one-based parsed
record ordinal. Do not use an absolute path, run ID, config fingerprint, user
key, timestamp, physical file line claim, or downstream entity identifier.
The same unchanged logical resource bytes produce the same row IDs; changed
bytes produce a new resource and new row IDs.

Every parser-consumed table row receives exactly one row-ledger record.
Disposition values must be closed and documented, such as retained,
transformed, or excluded, with rule/reason when not retained unchanged.
Counts must reconcile per resource:

```text
parsed = retained + transformed + excluded
```

No row may appear twice, disappear, or resolve to more than one source-row
identity. Descriptor and schema bytes remain in source inventory but are not
invented as tabular rows.

### Finding ledger

Use a versioned machine-readable finding schema with stable rule IDs. At
minimum each finding records:

- finding schema, stable rule ID/version, category, and severity;
- deterministic finding ordering and a reproducible instance identity;
- resource, source-row, field, or dataset scope;
- observed state without mutating it;
- affected domain and immediate execution consequence; and
- user-facing explanation and remediation.

`integrity` is non-waivable even if a display severity is changed. `semantic`
may yield a repair proposal or a recorded unresolved consequence. `advisory`
does not alter execution. Do not encode Phase 4 module eligibility/status.

### Proposal, decision, and application

Keep three immutable record types:

1. A proposal identifies the rule, source-row/field, original value/state,
   proposed value/state, repair class, rationale, and algorithm version.
2. A decision records the exact proposal ID and `approved` or `declined`.
   Missing decisions remain unresolved. `override_explicit` also requires a
   non-empty proposal-specific reason.
3. An application records whether the proposal was applied, the exact
   before/after state, decision link, and post-validation outcome.

Proposal identity excludes run ID and raw/resolved config hashes so a preview
can be approved in a later invocation. It includes enough proposal content
that changed source, rule version, field, or proposed value produces a
different ID.

The provisional immutable-config decision block is an exact list of decisions,
not a wildcard or class-wide switch. Reject an unknown/stale ID, duplicate ID,
conflicting decision, changed proposal digest, malformed reason, or any
attempt to authorize `override_explicit` broadly. Recompute and verify all
ledger links in a completed bundle.

### Bounded repair demonstration

Implement only:

- one deterministic, meaning-preserving representation normalization suitable
  for a focused fixture; and
- synthetic/fixture-only coverage of filling a genuinely unknown value.

Both repair demonstrations default to preview and require exact approval
before application. Fixture coverage is not a production rule. No production
fill-unknown, last-image, camera-failure, deployment-end, or operational-period
inference is added. The protected-override fixture proves that explicit source
evidence remains unchanged without exact proposal authority and reason; it
does not establish a broad production override policy.

### Adapter transformations

Record representation changes made by both four-table ingest and CamtrapDP
adaptation. A mapping may remain transformation-only only when it is strictly
meaning-preserving and neither fills an unknown nor replaces supplied
evidence. Record its exact source and resolved representations, rule/version,
and reversibility basis.

Classify any adapter behaviour that fills an unknown as `fill_unknown` and any
behaviour that replaces supplied evidence as `override_explicit`. Both are
semantic proposals requiring an exact proposal-specific decision through the
same repair state machine. Existing code does not grandfather automatic
authority. In particular, copying a known deployment endpoint into a missing
endpoint, replacing a missing count with `1`, or replacing missing flash with
`0` may not auto-apply merely because the adapter previously supplied those
defaults. Goal 006 defines no production algorithm that authorizes these
fills. The unresolved source values remain unchanged, and the full run stops
before analysis if the current input contract cannot accept them.

Generated codes, absent optional resources, joins, and exclusions must be
classified by the same rule. If a mapping collides, merges distinct meanings,
drops a row without a valid disposition, or cannot be reversed/explained from
its record, fail integrity before analysis. Do not introduce fuzzy matching.

An observation that is legitimately excluded by an existing explicit
scientific/operational rule remains in the source-row ledger with its reason.
This is distinct from silent adapter loss.

### Event membership sidecar

Keep source-row IDs out of current analytical output columns. Produce a
sidecar membership record linking every retained operational detection event
to one or more observation `source_row_id` values. Prove:

- every current retained event appears in membership;
- every membership source row exists and is an observation row;
- excluded observations are not silently used in an event;
- every current observation exclusion has a rule and reason; and
- no event-gap value or grouping rule changed.

Field-level sidecars are required only where a value was changed. Do not
construct per-cell lineage for aggregate ecological outputs in this goal.

### Preflight-only execution

Extend the existing supported runner rather than adding a script. A
validation-only invocation:

- uses Goal 005 unique run identity and immutable source/config snapshots;
- performs acquisition, row identity, validation, proposal matching, and
  post-validation checks;
- publishes an immutable non-overwriting preview record in a namespace
  separate from completed scientific runs;
- records proposal, decision/application preview, transformations, row
  dispositions, consequences, and relevant fixity;
- does not render the scientific report, execute ecological analysis targets,
  create `COMPLETED.json`, publish under `outputs/runs/`, or update latest.

A clean full run invokes the same validation logic before analysis and embeds
the same classes of records in its completed bundle. A declined or unresolved
repair never changes a value. Continue only if the unchanged data satisfy the
current contract; otherwise stop before analysis and report affected domains.
Do not claim selective completion or omission.

### Manifest 1.1 and compatibility

For new completed full runs, write
`camtrap-evidence-manifest/1.1`. It retains the Goal 005 fields and exact
payload inventory and adds semantic links to:

- resource/source-row inventory and disposition;
- validation findings;
- transformation records;
- repair proposals, decisions, applications, and post-validation state;
- changed-field lineage; and
- operational-event membership.

The portable verifier must recompute payload fixity and validate all Phase 2
schemas, IDs, counts, links, decision authority, application results, and
event membership. A checksum-reclosed but internally inconsistent bundle must
fail.

Dispatch verification by manifest schema. Existing 1.0 bundles must continue
to verify under their original contract and are not failed for absent 1.1
artefacts. Do not rewrite old bundles.

### Terminology without method change

Use `operational detection event` in changed user-facing report, methods, and
reference prose. Retain compatibility file/column/function/config names where
renaming would create a public migration. Tests must prove that the numeric
gap parameter, event membership, event counts, and downstream scientific
values remain unchanged.

## Acceptance ladder

### A. Static and scope checks

```sh
git status --short --branch
git diff --name-only
git diff --check
Rscript scripts/run_lint.R
Rscript scripts/run_tests.R
```

Require an exact subset of the closed allowlist, no generated/raw output, no
new dependency, lint PASS, and the authoritative suite PASS. Preserve raw
logs, not summary booleans.

### B. Clean and preview fixtures

1. Run a clean four-table preflight. It creates one immutable preview record,
   proposes no semantic repair, executes no analytical/report target, creates
   no `COMPLETED.json`, and leaves latest bytes unchanged.
2. Run the supported full command on the same clean fixture. It performs the
   same preflight, completes normally, and publishes latest only after bundle
   verification.
3. Run a fixture with the bounded normalization proposal without a decision.
   Confirm source bytes and scientific outputs are untouched, the proposal is
   deterministic across invocations, the consequence is explicit, and
   preflight never changes latest.
4. Re-run with exact approval in the immutable config snapshot. Confirm one
   application, exact before/after/decision/post-validation links, no source
   mutation, and no unrelated application.
5. Re-run with explicit decline. Confirm no application and deterministic
   affected-domain consequence.

### C. Authority and integrity fixtures

1. Attempt wildcard/class-wide repair approval and broad explicit override;
   neither may authorize application.
2. Exercise proposal-specific protected override with a reason in a synthetic
   fixture only; mutate the proposal/source and prove the old approval becomes
   stale rather than applying.
3. Exercise unknown, duplicate, conflicting, malformed, and checksum-reclosed
   tampered decisions; each fails before analysis and latest remains unchanged.
4. Exercise broken keys, ambiguous/colliding representation, lossy mapping,
   unexplained row loss, duplicate source-row ID, missing disposition, orphan
   changed-field link, and orphan event membership; each is a non-waivable
   integrity failure.
5. Inject a post-preflight failure; prove the prior completed bundle, prior
   preview, and latest pointer bytes remain unchanged.

### D. Four-table and CamtrapDP lineage

For both four-table and local/mocked CamtrapDP fixtures, preserve raw resource
and row-ledger records and prove:

- every parser-consumed table row is accounted for exactly once;
- resource and source-row IDs reproduce from their defined inputs;
- source byte mutation changes the affected resource/row identities;
- no absolute path, cache path, run ID, or config identity appears in row ID
  inputs;
- a strictly meaning-preserving mapping is recorded as transformation-only
  with no repair proposal;
- missing deployment endpoint copying, missing count -> `1`, and missing flash
  -> `0` do not auto-apply in production CamtrapDP paths;
- those semantic defaults are classified as `fill_unknown` proposals, remain
  unresolved without exact proposal-specific approval, preserve the source
  value, and stop before analysis when the current contract rejects it;
- a supplied-value replacement is classified as `override_explicit` and
  cannot apply without exact proposal-specific approval plus reason;
- collision/lossiness or missing referenced resources stop safely; and
- no mandatory live network is used.

### E. Event and scientific invariance

For the pre/post default Judbury pair:

1. Require no semantic proposal or applied repair.
2. Reconcile all parsed rows and observation dispositions.
3. Require every retained operational detection event to have at least one
   valid observation source-row member.
4. Compare the 10 stable tables by exact parsed equality and byte equality,
   including names, key order, dimensions, and missingness.
5. Compare the three occupancy tables by exact keys/dimensions/missingness and
   zero numerical difference.
6. Review the methods diff. Permit only declared provenance additions and the
   term `operational detection event`; reject parameter, threshold, gap-rule,
   estimand, or interpretation changes. Do not claim binary HTML/PDF/RDS
   equality.

### F. Manifest, portability, and legacy compatibility

1. Inspect a completed 1.1 manifest and exact payload inventory. Recompute all
   Phase 2 links and hashes with the portable verifier.
2. Copy the bundle to an unrelated temporary root; verification must pass
   without repository or original absolute paths.
3. Remove, alter, orphan, duplicate, or checksum-reclose each Phase 2 ledger
   class; verification must fail with attributable evidence.
4. Verify an unchanged Goal 005 `camtrap-evidence-manifest/1.0` fixture. It
   must pass without Phase 2 fields.
5. Present an unknown manifest schema. It must fail explicitly, not fall
   through to a permissive path.

### G. Pointer-state and execution boundary

Capture pointer bytes before and after:

1. a direct partial-target smoke using the existing template config;
2. validation-only clean, proposal, declined, and integrity-failure runs; and
3. a supported clean full run.

The partial run cannot publish preview/completion/latest. Preflight-only runs
may publish immutable previews but never completion/latest. A failed full run
cannot change latest. Only the verified clean full run advances latest.

### H. Full local run and review

Run the supported default Judbury preflight and full execution, then rerun:

```sh
Rscript scripts/run_lint.R
Rscript scripts/run_tests.R
git diff --check
git status --short --branch
```

Retain raw command logs, bundle inventories, ledger extracts, comparator
outputs, pointer bytes, and target metadata under ignored acceptance
directories. Obtain one independent review of source identity, approval
authority, integrity stopping, row accounting, event membership, 1.0/1.1
verification, scientific comparison, and changed-path scope. Apply at most one
focused repair and rerun only affected checks plus the full required gate.

## Publication and CI

After Barry has authorized execution and local acceptance/review are clean,
the orchestrator stages exact allowed paths, inspects the staged diff, commits,
and pushes. Bind CI to that exact SHA:

```sh
PUBLISH_SHA="$(git rev-parse HEAD)"
gh run list --workflow ci.yml --branch main --limit 50 \
  --json databaseId,headSha,status,conclusion
RUN_ID="$(gh run list --workflow ci.yml --branch main --limit 50 \
  --json databaseId,headSha \
  --jq '.[] | [.databaseId,.headSha] | @tsv' |
  awk -v sha="$PUBLISH_SHA" '$2 == sha {print $1; exit}')"
test -n "$RUN_ID"
test "$(gh run view "$RUN_ID" --json headSha --jq '.headSha')" = "$PUBLISH_SHA"
gh run watch "$RUN_ID" --exit-status
gh run view "$RUN_ID" --json databaseId,headSha,status,conclusion,url
gh run view "$RUN_ID" --log-failed
```

The existing CI must prove lint, tests, and supported full-run verification.
Because the workflow file is outside this goal's allowlist, stop and request a
new authorization if CI itself must change. A failed/missing exact-SHA run
leaves status `NOT_FINAL`; allow one narrow correction only for material new
evidence and only within the existing allowlist.

## Stop and return

Stop immediately for a failed baseline, out-of-scope path, new dependency,
silent/ambiguous row loss, unapproved application, explicit evidence
overwrite, unverifiable lineage, scientific drift, a broken Goal 005 trust
root, or a deferred authority decision. Preserve the last trustworthy raw
evidence.

Return: conclusion; exact changed paths; validation/repair/lineage design
implemented; raw commands and outcomes; clean/fixture/comparator/pointer/
manifest evidence; review verdict and repair; commit/push/exact-SHA CI state;
material assumptions or residual risks; and final Git status. Stop after one
strong implementation pass and one focused review/repair pass unless material
new evidence justifies escalation.
