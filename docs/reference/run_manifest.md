# Immutable evidence manifest

The supported command

```sh
Rscript scripts/run_full_evidence_run.R --config config.yml
```

publishes `outputs/runs/<run_id>/run_manifest.json`. A direct or partial
`tar_make()` call is not a publisher and cannot write a terminal completion
record or update `outputs/latest`.

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

`manifest_schema` is `camtrap-evidence-manifest/1.0`. The main fields are:

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
