# Workflow

## Supported Run Path

Use the publisher for validation previews and complete runs:

```sh
Rscript scripts/run_full_evidence_run.R --validate-only --config config.yml
Rscript scripts/run_full_evidence_run.R --config config.yml
```

The runner creates one explicit `camtrap-workflow-request/2.0` value and passes
it into a private targets environment. Stages exchange their returned values
directly; environment variables and intermediate runtime JSON are not part of
the stage contract.

## Seven Stages

1. `ingest_stage` captures the raw configuration and immutable source files,
   then computes source, resolved-config, engine, and composite fingerprints.
2. `validation_stage` validates the input contract and records findings,
   proposal decisions, changed fields, and source-row lineage.
3. `foundation_stage` resolves entity/deployment evidence and the selected
   spatial unit, including confirmed operation.
4. `events_stage` forms operational detection events at physical locations and
   records every contributing source row.
5. `modules_stage` runs each eligible retained ecological summary and writes a
   status for every candidate module.
6. `report_stage` renders one concise HTML ecological report from precomputed
   machine-readable results.
7. `bundle_stage` writes the current manifest, verifies the staged bundle,
   publishes it atomically, writes completion evidence, and advances
   `outputs/latest` only after final verification.

Validation, entity/effort resolution, event construction, and selected spatial
resolution are each computed once and reused downstream.

## Failure Semantics

Input or lineage integrity failures stop the run. Ecological eligibility is
fail-soft: an unavailable module is `omitted`, while valid independent modules
continue. A technical module error is `failed`; any failed module prevents a
completed publication and leaves `outputs/latest` unchanged.

A mapped dataset with no operational events remains structurally valid. It
publishes empty core tables with `completed_with_warnings` where appropriate.

## Spatial Semantics

Events are always formed at resolved physical locations before grouping. The
selected analytical resolution is either:

- `physical_location`; or
- `analysis_site` with one exact approved membership mapping.

No grouping is inferred from identifiers, coordinates, proximity, chronology,
or operation patterns. Supplied physical coordinates and covariates remain
attached to physical locations. Representative grouped coordinates are for map
orientation only.

## Artefact Review

For a change that affects scientific output:

1. run the smallest focused tests at the changed seam;
2. run `Rscript scripts/run_lint.R` and the complete fast suite;
3. inspect the HTML report, module-status records, and affected tables or
   figures from a small fixture run;
4. run the independent emitted-bundle verifier; and
5. use the manual exact-SHA Judbury release only after review.

Do not use a full release to debug ordinary unit failures.

## Development Commands

```sh
Rscript scripts/run_lint.R
Rscript scripts/run_tests.R --profile fast
actionlint .github/workflows/ci.yml
```

The fast suite must remain below two minutes. It includes a compact real
publication smoke; there is no separate local release-test tier.
