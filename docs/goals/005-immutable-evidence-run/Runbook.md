# Goal 005 execution runbook — immutable evidence run

## Purpose and publication gate

This runbook governs implementation of the authorized Phase 1 immutable
evidence-run foundation. It turns the current targets workflow into a
reproducible evidence publisher while preserving all ecological calculations,
methods prose, estimands, and existing output meanings.

The packet itself is documentation-only. Before implementation, the
orchestrator must review and publish the four packet files with the exact
message `docs: define Goal 005 immutable evidence run`. Packet preparation and
review do not run R, tests, builds, targets, network acquisition, or Git
publication. The packet executor never stages, commits, or pushes.

Implementation may start without another Barry gate only after that packet
publication. The implementation commit and push are authorized by local
acceptance plus one independent implementation review. Post-push GitHub
Actions is the final remote confirmation; a CI failure leaves status
`NOT_FINAL` and permits one narrowly CI-driven correction only when it is
material new evidence.

## Baseline gate

Run the following read-only checks from `/Users/bwbrook/git/camtrap-workflow`:

```sh
pwd
git branch --show-current
git rev-parse HEAD
git status --short --branch
git rev-parse --abbrev-ref --symbolic-full-name @{u}
```

The packet-authoring baseline was branch `main` at
`17761af107dc43399e223e35e2fd130f24ab05e6`. At execution, require branch
`main`, synchronized upstream, clean index/worktree, `HEAD^` exactly that
hash, HEAD subject exactly `docs: define Goal 005 immutable evidence run`,
and an exact four-file `HEAD^..HEAD` diff containing only this packet. The
execution HEAD is intentionally not required to equal the authoring hash.
Use `git diff --name-status HEAD^..HEAD` and `git show -s --format=%s HEAD` to
prove the gate. Do not fetch, reset, clean, merge, or reconcile; if any check
differs, stop and return exact state.

Before the first implementation edit, capture this packet-publication code
state (commit, status, path list, and relevant source/config hashes) into an
ignored temporary evidence directory. Then run the full default Judbury
pipeline at that exact code state with `Rscript -e 'targets::tar_make(callr_function = NULL)'`.
Retain the named stable CSV set, model-summary tables, normalized methods text,
RNG/session/package versions, row/key ordering, canonicalisation details, and
raw comparator hashes. Stop before implementation if run or capture fails;
these ignored artefacts are the pre/post baseline, not committed outputs.

## Current defect anchors to preserve in the design

The implementation should address these bounded defects without changing
scientific behaviour:

- `R/config.R:7-24,107-148`: `run_id = "latest"` is a compatibility label,
  not a unique filesystem identity; current validation must remain compatible.
- `_targets.R:210-253`: data-dictionary generation is currently in the
  scientific DAG and can mutate tracked repository state.
- `_targets.R:1434-1508`: current run manifest inventories named outputs but
  lacks immutable bundle identity, source fixity, and complete artifact list.
- `R/run_manifest.R:13-65`: current manifest generates a timestamp-derived ID
  and MD5 config field; it must gain SHA-256 identity while preserving the
  legacy field interpretation.
- `analysis/report.qmd:37-44`: report currently displays legacy config run ID;
  add authoritative bundle identity without altering methods or results.
- `scripts/update_data_dictionary.R:15-23`: retain as explicit maintenance
  command; it must no longer be invoked by scientific targets.
- `tests/testthat/test_run_manifest.R:8-39`: extend focused manifest tests for
  identity, fixity, relative inventory, and compatibility fields.

## Roles and mutation boundary

The implementation owner may edit only the closed allowlist in `Goal.md`:
`_targets.R`; the four existing R files; the five named new R files (omitting
unused ones); `scripts/run_full_evidence_run.R`; `analysis/report.qmd`; the
five configs; the named README/reference/container/Docker/CI files;
`tests/testthat/test_run_manifest.R`, `tests/testthat/test_camtrapdp_adapter.R`,
`tests/testthat/test_pipeline_smoke.R`, `tests/testthat/test_run_identity.R`,
`tests/testthat/test_source_inventory.R`, `tests/testthat/test_config_identity.R`,
and `tests/testthat/test_run_bundle.R`; `tests/testthat/fixtures/goal005/`; and
the four named project-log/decision/roadmap paths. Any other path requires
escalation. Tests may create temporary/local fixtures, but no raw/generated
output may be committed; prove exact changed-path subset. The orchestrator
owns review, staging, commit, and push; Barry owns scientific/product choices.

Use one independent implementation review and at most one focused repair.
Reviewers must inspect raw manifests, inventories, pointer bytes, and test
fixtures rather than relying on summary booleans.

## Behavioural contract

### Invocation and identity

The supported full-run runner is the only publisher. It allocates a
collision-resistant filesystem-safe ID, copied verbatim into directory,
report, canonical config, manifest, status, and latest target. `config$run_id`
remains a compatibility label only. Partial/debug `tar_make()` calls may build
intermediate targets but cannot write completion, status `completed`, or latest.

### Source inventory and invalidation

Before parsing, materialise an immutable input snapshot and make parsers
consume it. Hash only data/package bytes consumed by parsers plus applicable
schema/version files (not report templates); record sorted relative path,
size, and SHA-256, with mtime diagnostic only. Pre-invocation byte changes
create a new identity; post-snapshot mutation, pinned-digest mismatch, path
escape, or unreadable file is an integrity failure before analysis.

### CamtrapDP acquisition

Acquisition mode is explicit (`local` or `remote`) and captured in config and
manifest. Materialise local packages and remote responses in a controlled
cache; inventory every parser-consumed referenced resource. Remote
acquisition must be pinned/content-identified and cached or fail before
analysis. Missing/changed/stale resources fail before analysis. Tests use
local fixtures and mocked responses, never mandatory live network.

### Four fingerprint domains

Keep four non-recursive domains separate: (1) input/acquisition bytes consumed
by parsers; (2) exact raw and canonical resolved configuration (equivalent
resolved values share a hash despite raw formatting/key order); (3)
version-controlled workflow sources/templates, lockfile, Git commit, dirty
state, and bounded content/diff hash; and (4) a canonical composite of the
first three. Exclude invocation ID, timestamps, absolute paths, mtimes, and
cache locations from equivalence. Record engine/package/session identity; no
Phase-3 profile/schema negotiation.

### Bundle and manifest

Use a versioned manifest with an exact relative payload set (every payload
except `run_manifest.json` and `COMPLETED.json`), each path/size/SHA-256,
including report, `report_inputs.rds`, and exports. Record source/config/
engine/composite identities, ID, legacy label, and status. In staging write
and validate the manifest first, then write `COMPLETED.json` last with manifest
SHA-256/schema/ID, atomically rename the directory, and verify completion ->
manifest -> exact payload set (reject extras/missing files). Internal hashes
are tamper evidence, not authenticity/signing.

### Completion and latest

Stage under the output root, validate identities, write completion last, and
atomically rename; only then atomically replace `latest` with a validated
relative ID. Resolver rejects absolute/`..`/separator/symlink/unknown targets.
Never overwrite a completed directory. Collision fails with prior evidence
preserved. Failure removes only unpublished staging and leaves prior latest
byte-for-byte unchanged. A failure after directory publication but before
latest may leave a valid discoverable bundle while prior latest is unchanged;
report it, never mutate it. Tampered bundles/pointers are detected, not fixed.

### Maintenance separation

Remove data-dictionary generation from the scientific target graph. The
maintenance command `Rscript scripts/update_data_dictionary.R` and its sync
test remain available and documented. A scientific run must leave tracked
`data_dictionary.md` and `data/data_dictionary.csv` unchanged; dictionary
updates are a separate, explicit maintenance action.

## Implementation sequence

1. Add identity/fingerprint, canonicalisation, source snapshot, and
   deterministic unit-test primitives.
2. Add explicit CamtrapDP cache/inventory guards and config/engine snapshots.
3. Add versioned manifest, completion trust root, portable verifier, staging,
   collision handling, status, and atomic latest resolver.
4. Integrate runner, `_targets.R`, and report; remove dictionary generation
   from the DAG while retaining maintenance script/sync test and methods.
5. Add acceptance fixtures, comparator evidence, documentation, and only
   conditional CI artifact-access migration.

## Baseline comparator contract

Capture raw comparator evidence before/after with identical input/configuration,
recording RNG seed/state, session/package versions, row/key ordering, and
canonicalisation. For stable CSVs (`effort_summary`, `time_qc_summary`,
`time_qc_flags`, `events_per_day`, `event_spacing`, `detection_history`,
`community_presence`, `community_abundance`, `alpha_diversity`, `beta_diversity`),
require exact parsed equality by names, keys, dimensions, and NA semantics.
Model summaries require documented-tolerance numerical equality plus exact
keys/dimensions/NA checks. Normalize methods text and compare excluding
identity metadata; make no binary HTML/PDF/RDS equality claim. Identity-only
differences are allowed; scientific differences stop and escalate. Store raw
comparators in ignored temporary evidence.

## Acceptance ladder and commands

Run these checks in order. Capture raw evidence in the implementation log;
do not replace it with a single PASS flag.

### A. Static and focused checks

```sh
Rscript scripts/run_lint.R
Rscript scripts/run_tests.R
git diff --check
```

`Rscript scripts/run_tests.R` is authoritative and exercises the focused tests;
confirm temporary/local fixtures, no live network requirement, and exact
changed-path subset.

### B. Identity and invalidation evidence

1. Use an injectable/fixed-clock allocator test for same-second uniqueness,
   then run two sequential supported full runs; show distinct IDs and matching
   directory/report/manifest/status/pointer identities (concurrency is not
   required).
2. Rerun unchanged inputs; show the first bundle remains byte-for-byte intact,
   the new invocation ID differs, and source/config/engine equivalence
   fingerprints match.
3. Mutate exactly one source byte; show changed source/composite hashes and
   target metadata proving ingest descendants reran.
4. Inject a failure after staging begins; show the previous `latest` bytes and
   prior completed bundle are unchanged.
5. Attempt a deliberate ID collision; show a non-overwrite failure.

### C. Integrity and portability evidence

1. Modify one completed artifact; the verifier must report path/hash/size
   mismatch and status must not be promoted.
2. Replace or edit `latest` with absolute, traversal, separator, symlink, or
   unknown targets; resolver must reject each case.
3. Copy a complete bundle to an unrelated temporary root and run the portable
   verifier; it must pass using only relative inventory paths.
4. Confirm manifest inventory includes report, `report_inputs.rds`, and export
   files with exact bytes, sizes, and SHA-256 values.

### D. Configuration and CamtrapDP evidence

1. Provide two YAML serialisations with equivalent resolved values; raw hashes
   differ while resolved hashes match.
2. Exercise local CamtrapDP fixture and mocked remote/cache fixture; show all
   resources inventoried before parse.
3. Remove or mutate a referenced resource; show fail-before-analysis and no
   completion/latest publication.

### E. Scientific and maintenance invariance

1. Apply the baseline comparator contract to pre/post default Judbury runs;
   identity metadata differences are expected, scientific differences stop.
2. Run a direct partial-target smoke with existing `config.template_example.yml`
   (for example `tar_make(names = c("config"), callr_function = NULL)`); assert
   it cannot advance completion or latest. Do not invent `--profile smoke`.
3. Run the maintenance script and dictionary sync test separately. Confirm a
   scientific run leaves tracked repository files unchanged.

### F. Full local run, review, and acceptance

```sh
Rscript scripts/run_full_evidence_run.R --config config.yml
CAMTRAP_CONFIG=config.template_example.yml Rscript -e 'targets::tar_make(names = c("config"), callr_function = NULL)'
git status --short --branch
```

The default Judbury run must publish one complete bundle. The partial target
smoke must not publish completion or advance latest. After publication,
the independent implementation reviewer checks raw inventories, hashes,
identity agreement, failure preservation, and scientific-output comparisons.
Apply at most one focused repair, rerun affected local checks, and record local
acceptance before staging. Local acceptance plus this review authorizes commit
and push; CI is not a local acceptance substitute.

### G. Post-push CI confirmation

After commit and push, bind CI inspection to the just-published SHA:

```sh
PUBLISH_SHA="$(git rev-parse HEAD)"
gh run list --workflow ci.yml --branch main --limit 50 --json databaseId,headSha,status,conclusion
RUN_ID="$(gh run list --workflow ci.yml --branch main --limit 50 --json databaseId,headSha --jq '.[] | [.databaseId,.headSha] | @tsv' | awk -v sha="$PUBLISH_SHA" '$2 == sha {print $1; exit}')"
test -n "$RUN_ID"
test "$(gh run view "$RUN_ID" --json headSha --jq '.headSha')" = "$PUBLISH_SHA"
gh run watch "$RUN_ID" --exit-status
gh run view "$RUN_ID" --json databaseId,headSha,status,conclusion,url
gh run view "$RUN_ID" --log-failed
```

`.github/workflows/ci.yml` must restore dependencies, run
`Rscript scripts/run_tests.R` and lint, and expose/download the documented
bundle path. Select only the run whose `headSha` equals the current published
SHA; require a nonempty matching run ID before `gh run watch --exit-status`.
A failed or missing matching run leaves the release `NOT_FINAL` and allows one
narrowly CI-driven correction only when it is material new evidence.

## Stop conditions

Stop immediately for a failed baseline; any path outside the allowed boundary;
network-only test dependence; an integrity mismatch that cannot be attributed;
scientific output or methods changes; a completion/latest update before
validation; a collision that overwrites evidence; a traversal escape; or a
request to choose Barry-owned schema, profile, threshold, method, interface,
deployment, or reuse policy. Preserve all prior evidence and report exact raw
failure output.

## Publication boundary and final return

Before orchestrator publication, implementation changes remain uncommitted and
the worktree may contain only allowed source/test/docs modifications plus
ignored local output. No raw/generated bundle is committed. The orchestrator
stages exact permitted paths, reviews the diff, commits, and pushes only after
acceptance. If CI artifact access requires a workflow change, that change is
included only within the explicitly approved CI boundary.

Final return must include: completed action and changed files; identity,
fixity, bundle, acquisition, maintenance, and invariance implementation notes;
commands and raw verification outcomes; exact commit/push and CI evidence;
remaining caveats or escalation; and final `git status --short --branch`.
