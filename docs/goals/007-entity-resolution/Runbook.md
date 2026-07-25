# Goal 007 execution runbook - entity-resolution evidence

## Purpose and authorization

This runbook governs the proposed first bounded Phase 3 slice. It integrates
versioned entity-resolution evidence into the supported validation-only and
full evidence paths while preserving all existing analytical inputs and
scientific outputs.

Barry authorized framing and packet publication on 2026-07-26 after approving
the narrow concept. Framing and publication do not authorize implementation.
After the authoring checks pass, the orchestrator may publish the exact
seven-path packet under that existing authority with subject:

```text
docs: define Goal 007 entity resolution
```

Implementation additionally requires Barry's explicit approval of both the
published packet and the exact 13-row crosswalk in
`judbury_entity_crosswalk.csv`. It begins only after the Git, crosswalk, and
baseline-evidence gates below pass. Clean local acceptance and one independent
implementation review authorize the implementation commit and push within the
closed allowlist. Exact-SHA CI is final remote confirmation. A missing or
failed matching CI run leaves the goal `NOT_FINAL`.

## Packet-publication gate

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

- branch `main`;
- empty index and worktree;
- `HEAD` equal to the locally known `origin/main`;
- `HEAD^` exactly
  `7ad07e936be33b82d9c0423324f6867d541a22bd`;
- HEAD subject exactly `docs: define Goal 007 entity resolution`; and
- exactly the seven packet paths listed in `Log.md`, with no other parent
  diff.

Do not fetch, reset, clean, stash, merge, amend, or reconcile a mismatch. Stop
and return the exact observed state.

## Crosswalk authority gate

Require a Barry-provided approval receipt that names the exact packet commit,
crosswalk version, file SHA-256, and immutable configuration authority
reference. Approval is for the factual 13-to-nine mapping and four undirected
move-pair relations only.

Record the file hash:

```sh
shasum -a 256 \
  docs/goals/007-entity-resolution/judbury_entity_crosswalk.csv
```

Then run this read-only matrix check:

```sh
Rscript - <<'RS'
path <- "docs/goals/007-entity-resolution/judbury_entity_crosswalk.csv"
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = "")

expected_physical <- c(
  "jc_cen", "jc_co1", "jc_co1_s1", "jc_co2", "jc_co3",
  "jc_co3_s16", "jc_co4", "jc_pm12", "jc_pm14", "jc_pm14_s1",
  "jc_pm23", "jc_pm34", "jc_pm34_s15"
)
expected_nominal <- c(
  "jc_cen", "jc_co1", "jc_co1", "jc_co2", "jc_co3",
  "jc_co3", "jc_co4", "jc_pm12", "jc_pm14", "jc_pm14",
  "jc_pm23", "jc_pm34", "jc_pm34"
)
expected_pairs <- c(
  "judbury_move_pair_co1",
  "judbury_move_pair_co3",
  "judbury_move_pair_pm14",
  "judbury_move_pair_pm34"
)

stopifnot(
  nrow(x) == 13L,
  identical(x$source_physical_id, expected_physical),
  identical(x$proposed_physical_location_id, expected_physical),
  identical(x$proposed_nominal_grid_station_id, expected_nominal),
  length(unique(x$source_physical_id)) == 13L,
  length(unique(x$proposed_nominal_grid_station_id)) == 9L,
  identical(sort(unique(stats::na.omit(x$move_pair_id))), expected_pairs),
  all(x$chronology_state == "unresolved_no_authoritative_order"),
  all(x$deployment_state ==
    "unresolved_no_authoritative_id_or_interval"),
  !"analysis_site" %in% names(x)
)
RS
```

Also inspect the approval receipt and file directly. Require:

- schema `camtrap-entity-crosswalk/1.0`;
- one internally consistent crosswalk version;
- four non-empty service markers only on the four suffixed physical IDs;
- no coordinates;
- no deployment ID, direction, ordinal, start, or end;
- no `analysis_site` field or membership; and
- every row still marked as proposed for Barry review in the source packet,
  with the separate approval receipt supplying execution authority.

If the approved matrix differs in any way, stop. Revise and republish the
packet rather than editing a mapping during implementation.

## Pre-edit baseline capture

Before the first implementation edit, create ignored evidence directories:

```sh
mkdir -p \
  outputs/goal007_acceptance/pre \
  outputs/goal007_acceptance/fixtures \
  outputs/goal007_acceptance/post \
  outputs/goal007_acceptance/review
```

Capture raw Git and authority evidence:

```sh
git status --short --branch \
  > outputs/goal007_acceptance/pre/git-status.txt
git rev-parse HEAD HEAD^ origin/main \
  > outputs/goal007_acceptance/pre/git-identities.txt
git show -s --format='%H%n%P%n%s' HEAD \
  > outputs/goal007_acceptance/pre/packet-commit.txt
git diff --name-status HEAD^..HEAD \
  > outputs/goal007_acceptance/pre/packet-paths.txt
shasum -a 256 \
  docs/goals/007-entity-resolution/judbury_entity_crosswalk.csv \
  > outputs/goal007_acceptance/pre/crosswalk-sha256.txt
```

Preserve the exact prior `outputs/latest` bytes or its absence before any
supported invocation:

```sh
if test -f outputs/latest; then
  cp outputs/latest outputs/goal007_acceptance/pre/latest.before
else
  printf '%s\n' ABSENT \
    > outputs/goal007_acceptance/pre/latest.before
fi
```

Run and retain a default validation-only baseline:

```sh
Rscript scripts/run_full_evidence_run.R \
  --config config.yml \
  --validate-only \
  2>&1 | tee outputs/goal007_acceptance/pre/validate-only.log
```

Require an immutable ready preview, manifest-independent Phase 2 evidence, no
scientific target execution, no `COMPLETED.json`, and unchanged latest bytes.

Run and retain a default full baseline:

```sh
Rscript scripts/run_full_evidence_run.R \
  --config config.yml \
  2>&1 | tee outputs/goal007_acceptance/pre/full-run.log
```

Resolve and verify the baseline bundle:

```sh
BASELINE_RUN_ID="$(tr -d '\r\n' < outputs/latest)"
BASELINE_BUNDLE="outputs/runs/$BASELINE_RUN_ID"
Rscript scripts/run_full_evidence_run.R \
  --verify-bundle "$BASELINE_BUNDLE" \
  2>&1 | tee outputs/goal007_acceptance/pre/verify-bundle.log
printf '%s\n' "$BASELINE_RUN_ID" \
  > outputs/goal007_acceptance/pre/baseline-run-id.txt
```

Require a valid `camtrap-evidence-manifest/1.1` bundle. Copy raw comparator
evidence into the ignored baseline directory. Preserve exact files, hashes,
parsed values, key order, dimensions, types, missingness, and canonical
comparison rules for these 10 stable tables:

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

Preserve the three occupancy tables:

```text
occupancy_summary.csv
occupancy_aic.csv
occupancy_predictions.csv
```

Also preserve:

- exact `validated_inputs.rds`;
- all 11 Phase 2 artefacts and their link map;
- source-row counts and disposition reconciliation;
- operational event membership and excluded-observation reasons;
- effective and raw configuration;
- source inventory and source hashes;
- report methods text and configured parameters;
- exact output inventory and SHA-256 values;
- current target metadata;
- R and package/session versions; and
- raw successful command logs.

Stop before editing if either supported command, portable verification,
pointer check, or evidence capture fails. Do not commit acceptance evidence.

## Roles and mutation boundary

The implementation owner may modify only the closed allowlist in `Goal.md`.
`R/entity_resolution.R` and
`tests/testthat/test_entity_resolution.R` are the only new code/test files.
Fixture additions stay under `tests/testthat/fixtures/goal007/`. No new
package is allowed.

The approved packet crosswalk is immutable input evidence during
implementation. It may be read and snapshotted but not modified.

The orchestrator owns:

- baseline and authority acceptance;
- independent review;
- exact-path staging;
- implementation commit and push; and
- exact-SHA CI confirmation.

Barry owns any changed crosswalk, deployment chronology, `analysis_site`,
effort/event routing, analytical grouping, public schema/API/migration,
scientific method, threshold, profile, module-status, or interface decision.

## Internal configuration contract

The implementation may add one provisional internal block with this semantic
shape:

```yaml
entity_resolution:
  profile_id: "judbury-entity-crosswalk/1.0.0-proposed"
  sidecar_path: "docs/goals/007-entity-resolution/judbury_entity_crosswalk.csv"
  sidecar_sha256: "553abada14493f3a5f0ae3c072523b6d5cc0d0c6a6c6480ca17a9e3331f2d8ec"
  authority_reference: "goal007-judbury-crosswalk-sha256-553abada14493f3a5f0ae3c072523b6d5cc0d0c6a6c6480ca17a9e3331f2d8ec"
```

This spelling is an internal implementation surface, not a public v0.1 field
or migration commitment. A generic profile uses explicit null values rather
than a guessed default. The selected profile, path, expected SHA-256, and
authority reference must resolve exactly and be included in raw/effective
configuration identity. The profile binds the allowed sidecar schema/version,
which must agree with the values parsed from the selected file. The approval
receipt must name the exact `authority_reference`; a generic or pending label
is not authority.

The YAML may reference the 13-row sidecar but may not reproduce its mappings.
Reject:

- a sidecar without an exact profile selection;
- a selected profile without a sidecar;
- an absent or malformed expected SHA-256;
- a schema/version mismatch;
- an absent or path-escaping file;
- a duplicate or conflicting row;
- an unknown field or unrecognized authority state;
- a sidecar not present in source inventory;
- source bytes that differ from the configured approved SHA-256;
- changed bytes after snapshot; and
- more than one selected mapping source.

## Immutable evidence acquisition

Copy the selected sidecar into a dedicated source-snapshot location before
parsing. Include its relative path, byte size, SHA-256, role, and consumed
state in the Goal 005 source inventory and source fingerprint.

Before copying, require the source bytes to match
`entity_resolution.sidecar_sha256`. Verify the immutable copy against the same
expected value before parsing. The immutable parser uses only the snapshotted
copy. The original repository path is not read again after acquisition.
Portable reconstruction uses only the copied bundle and relative source/config
paths.

Use the distinct inventory role `entity_resolution_input`. Do not add the
sidecar to the analytical `parser_paths`/`parser_files` collection or treat it
as a fifth analytical table or Goal 006 logical resource. Carry its immutable
path in a dedicated entity-evidence snapshot field. Goal 007 records account
for every sidecar row and its digest. The source/composite fingerprints change
when this declared evidence is selected, but all 11 Phase 2 artefacts retain
the same semantic rows, transformations, repair state, event membership, and
validated inputs.

Four-table and CamtrapDP acquisitions with an explicit null sidecar still
record the null selection in effective configuration and summary evidence.
Do not invent an empty crosswalk file or treat an unselected nearby file as
input.

## Entity evidence contract

### Resolution records

`entity_resolution.csv` is a versioned resolution ledger. Each row carries:

- `entity_record_schema`;
- `resolver_version`;
- `entity_type`;
- nullable deterministic `entity_id`;
- `source_namespace`;
- nullable `source_identifier`;
- `resolution_state`;
- `evidence_state`;
- stable `evidence_basis`;
- nullable source-inventory and source-row references; and
- `record_digest`.

Allowed `entity_type` values are:

```text
nominal_grid_station
physical_location
deployment
analysis_site
```

Allowed `resolution_state` values are:

```text
resolved
unresolved
ambiguous
integrity_failure
```

Allowed `evidence_state` values are:

```text
supplied
approved_sidecar
compatibility_identity
absent
```

An unresolved record has no fabricated `entity_id`. `ambiguous` and
`integrity_failure` block both analytical entry and any resolved/readiness
claim. The ledger is deterministically ordered by entity type, logical source
namespace, source identifier, and evidence basis.

Entity ID preimages contain only:

- identity schema and algorithm version;
- entity type;
- logical evidence namespace; and
- exact supplied or approved stable key.

They exclude invocation/run identity, timestamps, absolute paths, cache
locations, raw/resolved config digests, coordinates, proximity, source row
ordinal, and suffix parsing. A stable explicit key therefore reproduces across
equivalent invocations and portable copies.

### Typed links

`entity_links.csv` carries:

- link schema and algorithm version;
- deterministic `link_id`;
- one closed `link_type`;
- typed source and target entity IDs;
- resolution and evidence state;
- stable evidence basis;
- nullable source-inventory/source-row references; and
- record digest.

Allowed links are exactly:

```text
physical_location_to_nominal_grid_station
deployment_to_physical_location
service_history_move_pair
analysis_site_membership
```

`service_history_move_pair` is undirected. Canonically sort its two physical
location endpoints before computing identity. It does not carry direction,
ordinal, chronology, or deployment meaning.

No `analysis_site_membership` row may exist. The summary must independently
assert zero memberships so absence cannot be mistaken for an omitted check.

Reject an orphan endpoint, wrong endpoint type, self-pair, duplicate logical
link, competing nominal mapping, competing deployment-location link, or
inconsistent evidence digest.

### Deployment lineage

`deployment_lineage.csv` carries:

- deployment record schema and resolver version;
- supplied deployment identifier and deterministic entity ID;
- exactly one physical-location entity ID when resolved;
- explicit start and end values when supplied;
- interval evidence state;
- chronology state;
- resolution state;
- exact source evidence links; and
- record digest.

A deployment is routing-ready only if identity, unique physical-location link,
and both ordered endpoints are explicit. Without those facts, the relevant
state is unresolved. A supplied non-empty orphan location, conflicting link,
reversed interval, duplicate deployment ID, or ambiguous evidence is an
integrity failure.

For Judbury, the file has its versioned header and zero resolved deployment
records. The summary and crosswalk evidence explicitly report deployment
identity, interval, and chronology as unresolved. Do not create 13 synthetic
deployment records or 40 active-run deployments.

For CamtrapDP, retain and use only explicit parsed `locationID`,
`deploymentID`, `deploymentStart`, and `deploymentEnd`. Arbitrary opaque IDs
must work. A suffix-like token has no special meaning. Do not derive a nominal
station from `locationName`, coordinates, or any identifier.

### Resolution summary

`entity_resolution_summary.json` carries:

- summary schema and resolver version;
- selected profile and sidecar source-inventory reference or explicit null;
- counts by entity type, resolution state, evidence state, and link type;
- unresolved and ambiguous scopes;
- integrity findings;
- exact crosswalk schema/version/hash when selected;
- configured approved SHA-256 and authority reference;
- deterministic digests of the three CSV ledgers;
- `analysis_site_status = "unselected"`; and
- `analysis_site_membership_count = 0`.

Counts must reproduce from the CSV records. The approved Judbury case must
report 13 distinct physical locations, nine distinct nominal stations, four
service-history move pairs, zero resolved deployments, and zero
`analysis_site` memberships.

### Join readiness

`join_readiness.json` records audit-only classifications for effort and
observation source scopes against named physical-location and deployment
levels. Each result carries:

- rule and schema version;
- source table or effort-column scope;
- requested entity level;
- exact evidence basis;
- counts of `unique`, `unresolved`, and `ambiguous`; and
- source and entity ledger digests.

The only classifications are:

```text
unique
unresolved
ambiguous
```

For generic four-table inputs, legacy `site` may be unique at
`physical_location` and must remain unresolved at `deployment`. For Judbury,
approved nominal links may also be unique audit evidence, but the scientific
path still uses the original 13 `site` keys. An ambiguity is an integrity
stop.

This file cannot provide joined rows to the target graph. It cannot filter,
reorder, aggregate, impute, assign zero, choose a fallback, alter an event, or
authorize routing.

## Input-mode rules

### Generic four-table mode

Without an explicit sidecar:

- each exact legacy `site` key maps one-to-one to a compatibility
  `physical_location`;
- nominal station is unresolved;
- deployment identity and interval are unresolved;
- coordinates are retained only as existing site metadata and do not
  participate in identity; and
- `analysis_site` remains unselected.

Two identifiers such as `plot` and `plot_s1` remain separate physical
locations. Two rows at close or identical coordinates remain separate.

With an approved sidecar, every source physical key must match exactly one
sidecar row. Extra, missing, duplicate, or conflicting keys fail integrity.
No fuzzy or case-normalized matching is allowed unless the sidecar itself
supplies the exact live key and explicit stable key.

### CamtrapDP mode

Use parser-audit evidence before the adapter discards source fields:

- exact `locationID` creates or refers to `physical_location`;
- exact `deploymentID` creates or refers to `deployment`;
- explicit ordered endpoints create interval evidence;
- the deployment's exact supplied `locationID` supplies the only
  deployment-to-location link; and
- nominal station and `analysis_site` remain unresolved/unselected.

A missing optional source identity remains unresolved. A non-empty reference
to a missing location, duplicate identity, conflicting deployment-location
relation, or invalid interval is an integrity failure. Observations must still
reference an exact supplied deployment under the existing integrity contract.

## Supported-path integration

Load the new module in the existing supported runner and target graph only.
Resolve after immutable source acquisition and parsed audit capture, and
before `validated_inputs.rds` can enter the scientific graph.

Validation-only and full modes from identical evidence must produce
semantically identical copies of all five Goal 007 artefacts. Goal 007
validation previews use `camtrap-validation-preview/1.1` with a mandatory
entity-resolution link map. Preserve verification of existing 1.0 preview
records.

`validated_inputs.rds` must still be a list with names exactly:

```text
site
op
obs
taxa
```

Do not add an entity object or column. Do not mutate table order or attributes
used by the scientific path.

Direct or partial `targets` execution cannot publish a validation preview,
entity trust record, completion record, or latest pointer. A failed
entity-resolution preflight may publish an immutable blocked preview but must
stop before the scientific graph and preserve latest.

## Manifest 1.2 and portable verification

New completed Goal 007 runs use:

```text
camtrap-evidence-manifest/1.2
```

Manifest 1.2 retains every Goal 005 and Goal 006 field and the complete
manifest 1.1 `phase2` link map. It adds one required
`entity_resolution` link map with exactly:

```text
entity_resolution
entity_links
deployment_lineage
entity_resolution_summary
join_readiness
```

Each link is a safe relative path to the five records under a dedicated
provenance namespace. The files are exact payload members. The manifest
cross-links the selected sidecar to raw/effective configuration, source
inventory, and the entity summary.

Use a distinct 1.2 schema because these records and semantic checks are
mandatory for Goal 007 bundles. Do not silently make them optional additions
to manifest 1.1.

The verifier dispatches exactly by schema:

- 1.0 verifies the Goal 005 contract;
- 1.1 verifies the Goal 006 Phase 2 contract; and
- 1.2 verifies the entire 1.1 contract plus Goal 007 reconstruction.

For 1.2, reparse immutable source/config/sidecar evidence and reconstruct all
five entity records. Require exact semantic equivalence, deterministic
ordering, counts, IDs, digests, links, states, and null selections. Reject:

- a missing or extra entity artefact;
- payload or source fixity change;
- wrong schema or link map;
- absolute path, traversal, or symlink;
- source/crosswalk mutation;
- disagreement among configured approved SHA-256, source inventory SHA-256,
  summary SHA-256, and reconstructed sidecar bytes;
- orphan, collision, duplicate, or state mismatch;
- summary or join-readiness count mismatch;
- populated `analysis_site`;
- checksum-reclosed entity or validated-input mutation; and
- an unknown manifest schema.

A portable copied bundle must verify without the repository, original source
root, or original absolute paths. Existing 1.0 and 1.1 fixtures must continue
to pass unchanged and must not be retrofitted with Goal 007 evidence.

## Acceptance ladder

### A. Static scope and dependency checks

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

Require:

- every changed path is in the closed allowlist;
- no raw input, generated output, acceptance evidence, lockfile, Docker, CI,
  report, ecological module, or unlisted file changed;
- no new dependency or runner;
- `git diff --check` PASS;
- lint PASS; and
- authoritative suite PASS.

Retain raw logs rather than only summary booleans.

### B. Focused entity fixtures

Run the focused file:

```sh
Rscript -e \
  'testthat::test_file("tests/testthat/test_entity_resolution.R")'
```

Require proof that:

1. the approved Judbury fixture resolves exactly 13 physical locations and
   nine nominal stations;
2. exactly four undirected move-pair IDs exist;
3. Judbury deployment identity, interval, and chronology remain unresolved;
4. `analysis_site` is unselected and has zero membership;
5. generic four-table `site` resolves only to physical location;
6. suffix-like opaque identifiers never merge;
7. close and identical coordinates never merge;
8. orphan, duplicate, conflicting, ambiguous, and tampered mappings fail;
9. arbitrary opaque CamtrapDP location/deployment IDs resolve from explicit
   evidence;
10. CamtrapDP without a nominal station invents none;
11. reversed or conflicting deployment intervals fail;
12. absent optional deployment evidence stays unresolved; and
13. contiguous active runs cannot create deployment records or intervals.

### C. Source/config and mode integration

Run the focused existing suites:

```sh
Rscript -e \
  'testthat::test_file("tests/testthat/test_config_identity.R")'
Rscript -e \
  'testthat::test_file("tests/testthat/test_source_inventory.R")'
Rscript -e \
  'testthat::test_file("tests/testthat/test_input_contract.R")'
Rscript -e \
  'testthat::test_file("tests/testthat/test_camtrapdp_adapter.R")'
Rscript -e \
  'testthat::test_file("tests/testthat/test_validation_ledger.R")'
```

Require:

- raw and effective configuration bind the exact profile/null selection;
- selected evidence binds the exact approved SHA-256 and receipt reference;
- no inline mapping is accepted;
- sidecar bytes are snapshotted and included in source identity;
- post-snapshot mutation fails;
- generic four-table and CamtrapDP paths obey their source-specific rules;
- parser source fields remain available to the resolver;
- validation-only and full preparation produce equivalent entity records; and
- all Goal 006 repairs, transformations, row dispositions, findings, and
  validated inputs remain unchanged.

### D. Negative controls and integrity stopping

Exercise each case through the supported preflight:

1. opaque suffix-like IDs;
2. close coordinates;
3. identical coordinates;
4. duplicate source or stable physical ID;
5. one physical location mapped to competing nominal stations;
6. one deployment mapped to competing physical locations;
7. orphan location, deployment, or link endpoint;
8. reversed deployment endpoints;
9. competing explicit intervals for the same deployment identity;
10. sidecar schema/version/profile mismatch;
11. expected sidecar SHA-256 or authority-reference mismatch;
12. sidecar mutation after snapshot;
13. active-day-run deployment inference attempt;
14. populated `analysis_site` membership; and
15. checksum-reclosed entity artefact mutation.

The first three remain distinct and valid without merging. Cases 4-15 fail
with attributable integrity evidence, do not enter analysis, do not complete,
and do not alter prior previews, completed bundles, or latest.

### E. Audit join readiness without routing

For clean generic four-table, approved Judbury, and opaque CamtrapDP fixtures,
inspect `join_readiness.json` and require:

- counts reconcile to the exact source scopes;
- physical-location, nominal-station, and deployment levels are reported
  separately;
- only explicit evidence can classify a mapping `unique`;
- semantic absence is `unresolved`;
- competing evidence is `ambiguous` and stops;
- no fallback key is emitted;
- no joined analytical table is produced; and
- validated inputs, effort, observations, and events are byte/value-identical
  with and without the diagnostics.

### F. Validation-only and full parity

For identical fixture snapshots:

1. run `--validate-only`;
2. retain all five entity artefacts and their hashes;
3. run the supported full command;
4. retain the corresponding completed entity artefacts; and
5. compare parsed semantic content and deterministic ordering.

Require exact semantic equality. Invocation-specific preview/manifest
metadata may differ only outside the five entity artefacts. Validation-only
never renders analysis, creates `COMPLETED.json`, publishes to completed runs,
or changes latest.

### G. Manifest, reconstruction, and legacy compatibility

Run:

```sh
Rscript -e \
  'testthat::test_file("tests/testthat/test_run_manifest.R")'
Rscript -e \
  'testthat::test_file("tests/testthat/test_run_bundle.R")'
```

Require:

1. a completed 1.2 fixture with the exact entity link map;
2. semantic reconstruction of all five artefacts;
3. portable verification after copying to an unrelated temporary root;
4. rejection of missing, extra, orphaned, reordered, altered, or
   checksum-reclosed Goal 007 evidence;
5. rejection of an altered crosswalk even after reclosed payload hashes;
6. rejection of an altered configured sidecar digest or approval reference
   without the exact authorized profile evidence;
7. exact continued verification of unchanged 1.1 and 1.0 fixtures; and
8. explicit rejection of an unknown manifest schema.

### H. Scientific invariance

For the pre/post default Judbury full runs:

1. Compare `validated_inputs.rds` object-by-object. Require exact names, class,
   attributes relevant to analysis, keys, row/column order, dimensions,
   types, values, and missingness for `site`, `op`, `obs`, and `taxa`.
2. Compare every Phase 2 artefact by exact semantic content and require
   unchanged source-row accounting, exclusion reasons, repair state,
   transformations, event membership, and post-validation result.
3. Compare the 10 stable tables by exact parsed equality and byte equality.
4. Compare the three occupancy tables by exact keys, dimensions, text,
   missingness, and zero numerical difference.
5. Compare effort values/summaries and operational-event membership/counts
   exactly.
6. Review methods/configuration. Reject any changed threshold, parameter,
   gap rule, grouping, denominator, estimand, or interpretation.
7. Require the scientific target graph still receives the same 13 Judbury
   legacy `site` keys in the same order.

Do not claim binary identity for rendered HTML, PDF, or RDS serialization when
the scientific comparator is the relevant contract. Retain the raw comparison
evidence and state the exact comparison used.

### I. Execution and pointer boundaries

Capture latest bytes before and after:

1. direct partial-target smoke;
2. clean validation-only;
3. unresolved optional-evidence validation-only;
4. each integrity-failure validation-only;
5. failed full run after preflight;
6. successful full run; and
7. portable verification.

Partial execution cannot publish trusted entity evidence. Validation-only may
publish an immutable preview but cannot complete or advance latest. Failed
full runs cannot advance latest. Only the successfully verified full 1.2
bundle advances latest.

### J. Full local gate and review

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

Retain raw logs, entity artefacts, bundle inventories, source/config hashes,
legacy verification, comparator results, pointer bytes, and target metadata
under ignored acceptance directories.

Obtain one independent read-only implementation review covering:

- exact crosswalk authority and no inference;
- deterministic IDs and closed states;
- source-specific four-table and CamtrapDP behaviour;
- deployment separation;
- zero `analysis_site` membership;
- join-readiness non-routing;
- source snapshot and semantic reconstruction;
- 1.0/1.1/1.2 dispatch;
- scientific invariance; and
- changed-path scope.

Apply at most one focused repair for material evidence. Rerun affected focused
checks and the complete local gate. Do not start repeated polish passes.

## Publication and exact-SHA CI

After Barry has authorized execution and local acceptance/review are clean,
stage exact allowlisted paths only, inspect the staged diff, commit, and push.
Bind CI to the exact implementation SHA:

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
gh run view "$RUN_ID" \
  --json databaseId,headSha,status,conclusion,url
gh run view "$RUN_ID" --log-failed
```

The existing workflow must prove lint, authoritative tests, supported full
run, and bundle verification. `.github/workflows/ci.yml` is outside the
allowlist. If the existing CI cannot exercise Goal 007 without a workflow
change, stop and request separate authorization.

A failed or missing exact-SHA run leaves status `NOT_FINAL`. Permit one narrow
correction only for material new evidence and only within the existing
allowlist.

## Stop and return

Stop immediately for:

- a packet, baseline, authority, or crosswalk mismatch;
- any inferred crosswalk, suffix parser, coordinate merge, move direction,
  deployment identity, chronology, or interval;
- any populated `analysis_site`;
- ambiguity treated as resolution;
- scientific, Phase 2, event, effort, method, threshold, or gap-rule drift;
- an out-of-scope path, new dependency, runner, public contract, production
  repair rule, module planner/status, report change, or CI edit; or
- unverifiable, non-portable, or checksum-only entity evidence.

Return concisely:

- conclusion;
- exact changed paths;
- implemented resolver/config/source-mode design;
- crosswalk counts and authority evidence;
- validation/full parity and five artefact summaries;
- negative-control and semantic-reconstruction outcomes;
- legacy verification and scientific comparator outcomes;
- independent review verdict and any single repair;
- commit/push/exact-SHA CI state;
- material assumptions and unresolved deployment/analysis-site risks; and
- final Git state.

Apply the 80/20 stop rule. After the complete core gate, one focused
self-review, and one independent review with at most one material repair,
return rather than spending additional cycles on low-value polish.
