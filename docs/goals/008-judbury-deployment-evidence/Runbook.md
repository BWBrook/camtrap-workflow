# Goal 008 execution runbook - Judbury deployment evidence

## Purpose and authorization

This runbook governs a proposed audit-only Phase 3 slice. It binds the exact
Judbury service source and proposed deployment ledger into the existing entity
evidence path while preserving analysis exactly.

Packet authoring does not authorize publication or implementation. Before any
implementation edit, require Barry's approval receipt naming:

- the complete published packet and packet commit SHA;
- normalized service-source SHA-256
  `f33eeac9d70126966717c8e3f4731c00a97cbc3a34c2f44ce5c70d91c7d5283a`;
- deployment-ledger SHA-256
  `0921eb8845c2bb1ad5760271f283ab2783735b7739e254c67e9243bc906f3ebf`;
- Goal 007 crosswalk SHA-256
  `553abada14493f3a5f0ae3c072523b6d5cc0d0c6a6c6480ca17a9e3331f2d8ec`;
- the exact authority reference in `Goal.md`; and
- approval limited to the enumerated deployment/service evidence.

A missing or non-exact receipt leaves the goal `NOT_AUTHORIZED`.

## Packet-publication gate

The authoring task does not run this gate or publish. A later authorized
publisher runs from `/Users/bwbrook/git/camtrap-workflow`:

```sh
pwd
git branch --show-current
git rev-parse HEAD
git rev-parse origin/main
git status --short --branch --untracked-files=all
git diff --name-status
git diff --cached --name-status
shasum -a 256 data/jc_services.csv
shasum -a 256 \
  docs/goals/008-judbury-deployment-evidence/judbury_deployment_ledger.csv
```

Require:

- branch `main`;
- pre-publication HEAD and origin/main exactly
  `e26c2a5a53e1a3283097ba8c6b193d2b7adf5a78`;
- empty index;
- exactly the ten packet paths in `Log.md`;
- no other worktree change;
- exact source and ledger hashes above; and
- one packet commit with subject
  `docs: define Goal 008 Judbury deployment evidence`.

After publication, require `HEAD^` to equal the authoring baseline and
`git diff --name-status HEAD^..HEAD` to contain exactly the ten packet paths.
Do not fetch, reset, clean, stash, amend, merge, or reconcile a mismatch.

## Exact authority and source gate

Before implementation, inspect Barry's approval receipt and run:

```sh
git status --short --branch
git rev-parse HEAD
git rev-parse origin/main
git show -s --format='%H%n%P%n%s' HEAD
git diff --name-status HEAD^..HEAD
shasum -a 256 data/jc_services.csv
shasum -a 256 \
  docs/goals/008-judbury-deployment-evidence/judbury_deployment_ledger.csv
shasum -a 256 \
  docs/goals/007-entity-resolution/judbury_entity_crosswalk.csv
shasum -a 256 data/jc_op.csv
```

Require clean synchronized `main`, the exact packet commit and paths, and:

```text
data/jc_services.csv
f33eeac9d70126966717c8e3f4731c00a97cbc3a34c2f44ce5c70d91c7d5283a

judbury_deployment_ledger.csv
0921eb8845c2bb1ad5760271f283ab2783735b7739e254c67e9243bc906f3ebf

judbury_entity_crosswalk.csv
553abada14493f3a5f0ae3c072523b6d5cc0d0c6a6c6480ca17a9e3331f2d8ec

data/jc_op.csv
28222586fa232fccc46bfab5e8c07e0c453f07387ebe4eb95b9a90e4687033a3
```

The receipt must name the exact authority reference:

```text
goal008-judbury-deployment-evidence-source-sha256-f33eeac9d70126966717c8e3f4731c00a97cbc3a34c2f44ce5c70d91c7d5283a-ledger-sha256-0921eb8845c2bb1ad5760271f283ab2783735b7739e254c67e9243bc906f3ebf
```

An approval of Goal 007, a filename, a generic profile, an abbreviated hash,
or this packet's proposed state is not Goal 008 execution authority.

## Structured evidence gate

Use a structured CSV parser against the immutable files. Require the service
source to have exactly the closed 16-column header in `Goal.md`, 13 data rows,
the exact raw IDs below, 75 non-NA dates, 62 non-NA `run_days` values, and the
diagnostic run-days total 7842:

```text
jc_cen
jc_co_1
jc_co_1_s1
jc_co_2
jc_co_3
jc_co_3_s1-6
jc-co-4
jc-pm-12
jc-pm-14
jc-pm-14_s1
jc-pm-23
jc-pm-34
jc-pm-34_s1-5
```

Require the ledger to have its exact closed header, 13 data rows, 13 unique
deployment IDs, 13 unique physical IDs, nine nominal IDs, four move-pair IDs,
four unique directed predecessor-to-successor edges, and service counts
summing to 75.

Require this service-count vector in Goal 007 physical order:

```text
8,7,2,8,2,7,8,8,6,2,8,3,6
```

For every row, reconstruct the exact alias, first and last service labels,
ISO endpoints, ordered event list, physical/nominal/move-pair values,
predecessor/successor relation, operation authority, and run-days disposition.
Compare them field-by-field with the ledger. Do not accept count-only
agreement.

Require the pm14 paired rows to document no paired-location deployment between
2019-10-14 and 2020-02-26. Require co1, co3, and pm34 same-day boundaries to
carry no full-day-overlap or routing claim.

Stop rather than repairing any disagreement.

## Pre-edit baseline capture

Create ignored acceptance directories only after authority passes:

```sh
mkdir -p \
  outputs/goal008_acceptance/pre \
  outputs/goal008_acceptance/fixtures \
  outputs/goal008_acceptance/post \
  outputs/goal008_acceptance/review
```

Capture raw Git, packet, approval, and hash evidence. Preserve the exact bytes
or absence of `outputs/latest`.

Run and retain a default validation-only baseline:

```sh
Rscript scripts/run_full_evidence_run.R \
  --config config.yml \
  --validate-only \
  2>&1 | tee outputs/goal008_acceptance/pre/validate-only.log
```

Run and retain a default full baseline:

```sh
Rscript scripts/run_full_evidence_run.R \
  --config config.yml \
  2>&1 | tee outputs/goal008_acceptance/pre/full-run.log
BASELINE_RUN_ID="$(tr -d '\r\n' < outputs/latest)"
Rscript scripts/run_full_evidence_run.R \
  --verify-bundle "outputs/runs/$BASELINE_RUN_ID" \
  2>&1 | tee outputs/goal008_acceptance/pre/verify-bundle.log
```

Require Goal 007 manifest 1.2 evidence and retain:

- all five entity artefacts;
- exact `validated_inputs.rds`;
- all 11 Phase 2 artefacts;
- source/configuration inventory and hashes;
- event membership and exclusion reasons;
- effort, methods, thresholds, gap rule, and parameters;
- all 13 scientific comparator tables in `Goal.md`;
- exact output inventory and SHA-256 values;
- latest-pointer bytes;
- target metadata; and
- raw successful command logs.

Stop before editing if either supported command, portable verification, or
evidence capture fails.

## Roles and mutation boundary

The implementation owner may modify only the closed future allowlist in
`Goal.md`. The approved service source, readme, deployment ledger, Goal, Plan,
Runbook, Goal 007 crosswalk, and Goal 007 authority are immutable.

The orchestrator owns:

- authority and baseline acceptance;
- one independent implementation review;
- exact-path staging and publication; and
- exact-SHA CI confirmation.

Barry owns any changed source fact, deployment/service interpretation,
`analysis_site`, analytical routing, failure diagnosis, inference/repair rule,
public contract, ecological method, adapter/export change, or expanded scope.

## Provisional internal configuration

The new block has exactly this semantic shape:

```yaml
deployment_evidence:
  profile_id: "judbury-deployment-evidence/1.0.0-proposed"
  service_sidecar_path: "data/jc_services.csv"
  service_sidecar_sha256: "f33eeac9d70126966717c8e3f4731c00a97cbc3a34c2f44ce5c70d91c7d5283a"
  deployment_ledger_path: "docs/goals/008-judbury-deployment-evidence/judbury_deployment_ledger.csv"
  deployment_ledger_sha256: "0921eb8845c2bb1ad5760271f283ab2783735b7739e254c67e9243bc906f3ebf"
  authority_reference: "goal008-judbury-deployment-evidence-source-sha256-f33eeac9d70126966717c8e3f4731c00a97cbc3a34c2f44ce5c70d91c7d5283a-ledger-sha256-0921eb8845c2bb1ad5760271f283ab2783735b7739e254c67e9243bc906f3ebf"
```

`config.yml` and `config.camtrapdp_export.yml` use this exact selection. The
template, forest, and CamtrapDP-ingestion configurations use six explicit
nulls. Selection in the export configuration changes only entity evidence;
the current exporter remains unchanged. Reject partial selection, unknown
fields, inline mappings, unapproved values, wrong input mode, selected Goal
008 evidence without the exact Goal 007 selection, or more than one selected
evidence source.

Do not change the spelling or meaning of the existing `entity_resolution`
block.

## Immutable evidence acquisition

Before parsing, verify and copy the two selected files into distinct immutable
source-snapshot locations. Inventory relative path, byte size, SHA-256, role,
and consumed state.

Required roles:

```text
deployment_service_input
deployment_ledger_input
```

The immutable parser reads only the snapshots. It must not reread repository
paths. Portable reconstruction uses only bundle-relative paths. Reject a
symlink, directory, path escape, absent file, changed source, post-snapshot
mutation, duplicate role, extra selected file, or expected/observed digest
mismatch.

These roles do not enter the analytical parser collection or Goal 006 logical
resources. Source and composite fingerprints change; analytical content does
not.

## Service normalization and lineage

For each immutable service row:

1. match one exact raw alias and one ledger source row;
2. inspect S0 through S7 in source-column order;
3. parse every non-NA date strictly and retain its exact service label;
4. retain each associated `run_days` literal or missing state without
   arithmetic use;
5. mark first, intermediate, and last events under the roles in `Goal.md`;
6. hash the canonical ordered event list;
7. compare count and endpoints with the ledger; and
8. require one unique approved deployment and physical link.

Use `camtrap-deployment-lineage/1.1` only. Preserve existing lineage fields and
add the exact fields listed in `Goal.md`. Goal 008 rows must carry both
immutable source and ledger evidence, exact approval, operation authority,
service digest, and chronology. Goal 008-specific fields are nullable for
existing generic and CamtrapDP evidence.

Require exactly:

- 13 resolved deployment entities;
- 13 `deployment_to_physical_location` links;
- 13 deployment-lineage rows;
- four directed predecessor/successor relations;
- 75 service events represented by row counts and digests;
- nine nominal stations and four undirected Goal 007 move pairs;
- no competing or orphan evidence; and
- zero `analysis_site` memberships.

## Existing five-file and manifest contract

Retain exactly:

```text
provenance/entity_resolution/entity_resolution.csv
provenance/entity_resolution/entity_links.csv
provenance/entity_resolution/deployment_lineage.csv
provenance/entity_resolution/entity_resolution_summary.json
provenance/entity_resolution/join_readiness.json
```

Validation-only and full runs from identical snapshots must produce
semantically identical five-file evidence. The directory is closed: missing,
renamed, redirected, symlinked, nested, or extra entries fail.

Retain validation preview 1.1 and completed manifest 1.2. Do not edit
`R/run_manifest.R`. Reconstruct all five artefacts, including exact Goal 008
source/ledger hashes and service-event digests. Reject altered or
checksum-reclosed evidence. Verify copied bundles without repository or
original source paths. Legacy manifest 1.0 and 1.1 fixtures remain unchanged
and verifiable.

## Acceptance ladder

### A. Static scope and authoritative checks

Run:

```sh
git status --short --branch
git diff --name-only
git diff --check
git diff --stat
git diff -- renv.lock
git diff -- .github/workflows/ci.yml
Rscript scripts/run_lint.R
Rscript scripts/run_tests.R
```

Require only allowlisted paths, no dependency or runner change, clean
whitespace, lint PASS, and authoritative tests PASS. Retain raw logs.

### B. Focused Goal 008 checks

Run:

```sh
Rscript -e \
  'testthat::test_file("tests/testthat/test_config_identity.R")'
Rscript -e \
  'testthat::test_file("tests/testthat/test_source_inventory.R")'
Rscript -e \
  'testthat::test_file("tests/testthat/test_entity_resolution.R")'
Rscript -e \
  'testthat::test_file("tests/testthat/test_validation_ledger.R")'
Rscript -e \
  'testthat::test_file("tests/testthat/test_run_bundle.R")'
Rscript -e \
  'testthat::test_file("tests/testthat/test_pipeline_smoke.R")'
```

Require proof of exact selection/null semantics, two immutable inventory roles,
13/13/9/4/75/62/0 counts, exact aliases/endpoints/relations, lineage 1.1,
service-digest reconstruction, validation/full parity, manifest 1.2, legacy
verification, and non-routing.

### C. Negative controls

Exercise:

1. duplicate source row or raw ID;
2. duplicate deployment or physical ID;
3. unknown alias;
4. missing or extra source/ledger row;
5. malformed or reversed date;
6. source/ledger endpoint or service-count conflict;
7. orphan or conflicting predecessor/successor;
8. orphan or competing physical link;
9. wrong schema, version, profile, hash, or authority reference;
10. source or ledger mutation after snapshot;
11. extra selected sidecar or closed-namespace file;
12. path escape or symlink;
13. `run_days` effort-use attempt;
14. same-day-boundary observation/effort routing attempt;
15. pm14 gap fill or cause-inference attempt;
16. populated `analysis_site`;
17. changed `jc_op`; and
18. checksum-reclosed entity or source mutation.

All fail before analysis with attributable integrity evidence, except that a
clean same-day boundary and the declared pm14 gap remain valid audit facts
when they perform no routing or inference.

### D. Validation/full parity and scientific invariance

Run a fresh validation-only and full invocation from identical source/config
snapshots. Compare the five entity artefacts semantically and by bytes where
deterministic serialization permits.

Compare pre/post:

- `data/jc_op.csv` hash and structured values;
- all four `validated_inputs.rds` objects;
- all 11 Phase 2 artefacts;
- event membership and exclusions;
- effort, methods, thresholds, gap rule, denominators, and parameters;
- ten stable comparator tables by exact existing canonical comparison; and
- three occupancy tables with zero numerical difference.

Require the same 13 legacy physical site keys and no nine-station output.
Join readiness may change only from unresolved to exact audit-only deployment
uniqueness. It must publish no joined analytical rows.

### E. Full local gate

Run:

```sh
Rscript scripts/run_full_evidence_run.R \
  --config config.yml \
  --validate-only
Rscript scripts/run_full_evidence_run.R \
  --config config.yml
POST_RUN_ID="$(tr -d '\r\n' < outputs/latest)"
Rscript scripts/run_full_evidence_run.R \
  --verify-bundle "outputs/runs/$POST_RUN_ID"
Rscript scripts/run_lint.R
Rscript scripts/run_tests.R
git diff --check
git status --short --branch
```

Validation-only cannot complete or advance latest. Integrity failures cannot
enter analysis or advance latest. Only the verified full manifest 1.2 bundle
may advance latest.

## Independent review and one-repair limit

Before implementation, obtain one read-only packet review covering exact
source facts, aliases, ledger rows, chronology, authority/fixity, non-routing,
scientific invariance, allowlist, and stop rules. Apply at most one focused
material packet repair, repeat the static and structured packet checks, then
obtain Barry's exact approval.

After implementation acceptance, obtain one independent read-only review
covering authority, immutable acquisition, event normalization, lineage 1.1,
entity/link counts, reconstruction/reclosure, manifest compatibility,
scientific invariance, and changed-path scope.

Apply at most one focused material implementation repair. Rerun affected
checks and the complete local gate. Do not begin repeated polish passes.

## Publication and exact-SHA CI

Only after authorized implementation, clean local acceptance, and independent
review may the orchestrator stage exact allowlisted paths, commit, and push.
Bind the existing CI run to the exact implementation SHA. Do not edit CI.

A failed or missing exact-SHA run leaves status `NOT_FINAL`. If existing CI
cannot exercise Goal 008 without a workflow edit, stop and request a revised
packet.

## Stop and return

Stop for any condition in `Goal.md`, especially a source/ledger/authority
mismatch, extra scientific interpretation, analytical drift, adapter/export
change, new schema beyond lineage 1.1, new artefact, manifest change, or
out-of-allowlist path.

Return:

- conclusion and exact changed paths;
- approved source, ledger, packet, and authority identities;
- structured 13/13/9/4/75/62/0 evidence;
- validation/full five-file parity;
- negative-control and semantic-reconstruction outcomes;
- legacy verification and scientific comparator outcomes;
- independent review verdict and any single repair;
- commit, push, and exact-SHA CI state;
- material uncertainty or deferred technical debt; and
- final Git state.

After the complete core gate, one focused self-review, and one independent
review, return the evidence rather than adding low-value polish.
