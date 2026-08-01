# Immutable evidence manifest

The supported command

```sh
Rscript scripts/run_full_evidence_run.R --config config.yml
```

publishes `outputs/runs/<run_id>/run_manifest.json`. A direct or partial
`tar_make()` call is not a publisher and cannot write a terminal completion
record or update `outputs/latest`.

The same runner also provides a validation-only preflight:

```sh
Rscript scripts/run_full_evidence_run.R --config config.yml --validate-only
```

It publishes an immutable `outputs/preflight/<run_id>/PREVIEW.json` record.
Preflight never creates `COMPLETED.json`, publishes a completed run, renders
the report, or changes `outputs/latest`.

## Identity model

`run_id` identifies one invocation. It is unique, filesystem-safe, and copied
without transformation into the directory name, effective configuration,
report, manifest, `COMPLETED.json`, and latest-pointer target. The YAML
`run_id` field remains a `legacy_run_label` only.

The manifest keeps four separate SHA-256 domains:

1. `source`: exact parser-consumed source, package, and schema bytes;
2. `config`: exact raw YAML and canonical resolved configuration;
3. `engine`: version-controlled workflow files, templates, lockfile, Git
   commit/dirty state, bounded diff hash, R version/platform, and the installed
   versions of packages named by the lockfile;
4. `composite`: canonical combination of the first three domains.

Invocation IDs, timestamps, absolute paths, mtimes, and cache locations are
excluded from equivalence fingerprints.

## Manifest schema

Completed runs with an explicit `analysis_unit` selection use
`manifest_schema = "camtrap-evidence-manifest/1.3"`. Manifest 1.3 inherits
the complete 1.2 contract. A genuinely omitted selection remains manifest
1.2. The main fields are:

- `run_id` and `legacy_run_label`;
- `status`;
- `created_utc` and `input_schema_version`;
- `fingerprints` for source, raw/resolved config, engine, and composite;
- `config.raw`, pointing to the exact immutable YAML consumed by the target
  graph at `provenance/config.raw.yml`;
- `config.effective`, pointing to
  `provenance/effective_config.json`;
- `source_inventory`, pointing to
  `provenance/source_inventory.json`;
- `engine`, with Git/R/file inventory metadata;
- `phase2`, linking the validation, repair, row-lineage, changed-field,
  transformation, event-membership, and post-validation records described
  below;
- `entity_resolution`, linking the five entity-evidence records described
  below;
- `selected_resolution`, linking the exact `membership`, `operation`,
  `event_map`, and `summary` records for manifest 1.3;
- `outputs`, the named compatibility map used by reports and readers;
- `session_info`;
- `payload`, the exact sorted relative set of every bundle file except
  `run_manifest.json` and `COMPLETED.json`.

Every payload record contains `path`, byte size, and SHA-256. The verifier
rejects missing files, extra files, size/hash changes, absolute paths,
traversal, and symlinks. It also recomputes the source inventory, exact raw and
canonical resolved configuration hashes, engine record, installed-package
record, and composite fingerprint. Rewriting the manifest and completion hash
around inconsistent provenance does not make a bundle valid.

### Phase 2 records

Manifest 1.1 requires these cross-linked files under `provenance/phase2/`:

- `resource_registry.json`;
- `source_row_ledger.json`;
- `validation_findings.json`;
- `transformations.json`;
- `repair_proposals.json`;
- `repair_decisions.json`;
- `repair_applications.json`;
- `changed_fields.json`;
- `event_membership.json`;
- `post_validation.json`; and
- `validated_inputs.rds`.

The portable verifier checks each wrapper schema and identity, source-row
accounting, decision authority, repair applications, changed-field links,
event membership, and the analysis-ready RDS record. Missing or orphaned
records, unexplained exclusions, stale approvals, changed proposal content,
or a mismatch between recorded and recomputed operational detection events
invalidate the bundle.

It also reconstructs every Phase 2 document and all four analytical tables
from the immutable source snapshot plus the exact decisions in the raw
configuration. A checksum-reclosed change to any scientific value therefore
fails even when it does not alter operational event membership.

Existing `camtrap-evidence-manifest/1.0`, 1.1, and 1.2 bundles remain supported
by the portable verifier. They are verified under their original contracts;
only 1.3 requires selected-resolution evidence and outputs.

### Entity-resolution records

Manifest 1.2 retains the complete manifest 1.1 Phase 2 contract and requires
exact links under `provenance/entity_resolution/` for:

- `entity_resolution.csv`;
- `entity_links.csv`;
- `deployment_lineage.csv`;
- `entity_resolution_summary.json`; and
- `join_readiness.json`.

The verifier reconstructs all five from the immutable parser evidence, raw
configuration, the selected Goal 007 crosswalk, and, when selected, the Goal
008 service source and deployment ledger. The latter two use distinct
non-parser inventory roles, must occupy their closed
`source_snapshot/deployment_evidence/` paths, and must match their separately
configured approved SHA-256 values. It rejects altered source, ledger, entity,
link, lineage, summary, or readiness records even after payload hashes are
reclosed. A selected Goal 008 run reconstructs 13 deployment records, 13
physical links, 13 deployment-lineage 1.1 rows, 75 ordered service events, and
four directed predecessor/successor relations. The link values and directory
entries remain a closed canonical five-file namespace; missing, renamed,
redirected, symlinked, nested, or extra entries fail even after payload and
completion hashes are reclosed.
`join_readiness.json` also records the exact source-inventory SHA-256 used for
semantic reconstruction. Goal 008 does not change manifest 1.2 or preview 1.1
schema identifiers. Manifest 1.1 and 1.0 continue to dispatch under their
original contracts and do not require Goal 007 or Goal 008 records.

### Selected-resolution records

Manifest 1.3 retains Phase 2 and entity reconstruction, then requires the
closed `provenance/selected_resolution/` namespace:

- `membership.csv`;
- `operation.csv`;
- `event_map.csv`; and
- `summary.json`.

The exact top-level manifest keys are `membership`, `operation`, `event_map`,
and `summary`. Under `outputs.tables`, every explicit mode links
`selected_resolution_status`. An eligible route also links
`selected_effort_coverage`, `selected_community_presence`,
`selected_observed_richness`, and `selected_jaccard`; an ineligible route
retains those four keys as explicit JSON nulls and contains none of the four
CSV files.

Portable verification reconstructs selected membership, effort union, and
event assignment from the immutable source snapshot and raw configuration. It
then reconstructs the status record, eligibility/link cardinality, contributor
lists, event conservation, claim limits, and all four ecological tables. A
checksum-reclosed change to provenance, status, or an ecological value remains
invalid. Richness is observed and detection-limited. Jaccard is descriptive
and based on observed presences; it is not standardized for unequal confirmed
effort, sampling completeness, or species detectability. The selected branch
does not pool physical covariates. Public profile registration, precedence,
and migration remain deferred.

## Validation preview

Explicit selected `PREVIEW.json` records use schema
`camtrap-validation-preview/1.2`. They retain the complete 1.1 contract and add
the four selected-resolution links. A genuinely omitted selection remains
preview 1.1; existing 1.0 and 1.1 previews remain verifiable. Preview 1.1 adds
the required entity-resolution link map with the same closed canonical
namespace rules as manifests 1.2-1.3. A preview records the
invocation identity, `ready` or `blocked` status, the same provenance
fingerprint domains used by a full run, the complete Phase 2 link map, and an
exact payload inventory. A blocked preflight is still published for review
before the command exits unsuccessfully.

Only preview 1.2 and manifest 1.3 authorize the non-parser
`analysis_site_mapping_input` source role.

The preview is evidence of validation and repair state, not a scientific
completion record. It is immutable, non-overwriting, and deliberately outside
`outputs/runs/`.

## Terminal trust record

`COMPLETED.json` uses schema `camtrap-completed/1.0` and is written last in
staging. It records the run ID, manifest schema, manifest SHA-256, completion
status, and completion time. The verified staging directory is then renamed
atomically to `outputs/runs/<run_id>/`; the existing directory is never
overwritten.

Only after directory publication and verification is `outputs/latest`
atomically replaced with the validated relative run ID. A failure after
directory publication may therefore leave a valid discoverable bundle while
the prior pointer remains unchanged.

## Portable verification

The verifier uses only the copied directory, relative inventory paths, the raw
configuration snapshot, and internal SHA-256 records:

```sh
Rscript scripts/run_full_evidence_run.R \
  --verify-bundle /path/to/copied/<run_id>
```

These hashes provide tamper evidence. They are not a digital signature and do
not establish authenticity against a hostile publisher.
