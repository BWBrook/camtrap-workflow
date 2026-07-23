# Goal 005 - Immutable evidence-run foundation

## Date

2026-07-23 AEST

## Outcome

The workflow now has a supported full-run publisher:

```sh
Rscript scripts/run_full_evidence_run.R --config config.yml
```

Each invocation receives a unique filesystem-safe identity. Before analysis,
the publisher snapshots every parser-consumed four-table or CamtrapDP byte and
records SHA-256 fixity. It keeps raw/resolved configuration, engine, and
composite fingerprints separate from invocation identity.

Completed output is staged, inventoried in
`camtrap-evidence-manifest/1.0`, bound by a terminal `COMPLETED.json`, verified,
and renamed atomically into `outputs/runs/<run_id>/`. Existing run directories
are never overwritten. The regular-file `outputs/latest` pointer moves only
after verification.

Direct or partial `tar_make()` calls write under `outputs/work/` and cannot
publish completion or advance latest. Data-dictionary generation is no longer
part of the scientific DAG; the explicit maintenance script and sync test are
retained.

## Scientific scope

No ecological calculation, estimand, threshold, report result, or methods
meaning was intentionally changed. The report adds authoritative evidence-run
identity beside the legacy configured compatibility label.

## Evidence

The required pre-change Judbury comparator and all generated acceptance
artefacts are ignored under `outputs/goal005_acceptance/`.

Final repaired evidence:

- sequential runs `20260723T070047Z-231de4a8bec242d8` and
  `20260723T070142Z-89bd0cc6bade4c0a` have distinct IDs, matching content
  fingerprints, 72-file manifests, and a byte-immutable first bundle;
- portable verification passes after copying the bundle away from its original
  output root;
- the exact raw config is a payload, the engine records 139 installed lockfile
  package versions, and verification recomputes every provenance cross-link;
- a one-byte source mutation changes source/composite identity and target
  metadata proves ingest descendants reran;
- failure, collision, tamper, pointer traversal, internal symlink, missing/
  changed CamtrapDP resource, and checksum-reclosed inconsistency cases fail
  safely;
- all 10 stable scientific tables are parsed- and byte-identical to the
  pre-change baseline, all three model tables have maximum absolute difference
  zero, and normalized methods text is equal;
- direct partial execution cannot publish; dictionary maintenance remains
  explicit and byte-stable;
- lint and `git diff --check` pass; the authoritative suite reports 245 PASS,
  0 FAIL, 1 expected warning, and 0 SKIP.

## Review and publication state

The independent implementation review first returned
`REPAIR_IMPLEMENTATION`. The single permitted repair bound analysis to an
immutable config snapshot, added cross-fingerprint verification, preserved
exact CamtrapDP descriptors, included installed dependency versions, and fixed
internal-symlink detection. Its bounded recheck returned
`ACCEPT_IMPLEMENTATION` with no material findings.

Local acceptance and publication are complete. Commit
`d40689c883d00d6d71740a440196507a558461f2`
(`feat: add immutable evidence runs`) was pushed to `origin/main`.
Exact-SHA GitHub Actions run
[`29987722220`](https://github.com/BWBrook/camtrap-workflow/actions/runs/29987722220)
completed successfully for that commit. Job `89143227550` succeeded in 3m51s
with checkout, system dependencies, Quarto, TinyTeX, R, `renv` restore, lint,
unit tests, pipeline smoke, the full immutable evidence run, bundle
verification, and artifact upload all green. Unexpired artifact
`immutable-evidence-bundle` has ID `8555780919`, size 7,089,890 bytes, and
expires 2026-10-21.
