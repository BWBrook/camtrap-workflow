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

New completed runs use
`manifest_schema = "camtrap-evidence-manifest/1.1"`. The main fields are:

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

Existing `camtrap-evidence-manifest/1.0` bundles remain supported by the
portable verifier. They are verified under their original contract and are
not required to contain Phase 2 records.

## Validation preview

`PREVIEW.json` uses schema `camtrap-validation-preview/1.0`. It records the
invocation identity, `ready` or `blocked` status, the same provenance
fingerprint domains used by a full run, the complete Phase 2 link map, and an
exact payload inventory. A blocked preflight is still published for review
before the command exits unsuccessfully.

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
