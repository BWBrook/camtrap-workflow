# Camtrap Workflow

Camtrap Workflow turns labelled camera-trap records, taxonomic identities,
camera-operation evidence, and physical-location metadata into a concise HTML
ecological report and an auditable, machine-readable run bundle.

The workflow starts after image labelling. It does not classify images, infer
analytical sites from names or coordinates, or make population-level claims.

## Ecological Product

The retained summaries are deliberately restrained:

- confirmed sampling effort and coverage;
- observed species presence and observed richness;
- descriptive Jaccard dissimilarity of detected composition;
- physical-location operational-event detection rate;
- coarse day/night summaries when clock evidence supports them;
- a species-accumulation diagnostic;
- event-gap sensitivity; and
- a physical-location point map.

Observed richness is detection-limited. Jaccard describes detected
composition. Operational-event detection rate is not abundance or density.
The point map uses supplied coordinates and does not create environmental
surfaces.

Every candidate module records `completed`, `completed_with_warnings`,
`omitted`, or `failed`, together with its required evidence, actual spatial
resolution, claim limit, and a reason when it did not complete cleanly.

## Inputs

Two input modes use the same downstream checks:

- four CSV tables: physical locations (`site`), daily operation (`op`),
  labelled detections (`obs`), and taxonomic identities (`taxa`); or
- a current Camtrap Data Package through the input adapter.

The generic analytical unit is `physical_location`. An `analysis_site` may be
selected only with an exact approved mapping. Nominal station remains survey
metadata and is never an analytical route.

See [the input contract](docs/reference/input_schema_v0.1.md),
[configuration reference](docs/reference/config.md), and
[own-data guide](docs/bring_your_own_data.md).

## Quick Start

Requirements are R 4.6, Quarto, and the locked R environment.

```sh
Rscript bootstrap_env.R
Rscript scripts/run_full_evidence_run.R --validate-only --config config.yml
Rscript scripts/run_full_evidence_run.R --config config.yml
```

Validation-only runs publish an immutable preview under
`outputs/preflight/<run_id>/`. They do not run ecological modules or update
`outputs/latest`. Repairs require an exact recorded proposal decision.

A successful full run publishes `outputs/runs/<run_id>/`, writes
`COMPLETE.json` last, and atomically updates the plain-text `outputs/latest`
pointer. The main user result is `report/report.html`; detailed evidence stays
in `provenance/`, `tables/`, `results/`, and `run_manifest.json`.

Verify a generic published bundle independently:

```sh
RUN_ID="$(tr -d '\n' < outputs/latest)"
Rscript scripts/verify_published_bundle.R "outputs/runs/${RUN_ID}"
```

The Judbury release additionally compares all 81 Jaccard values with the
accepted Goal 010 oracle:

```sh
Rscript scripts/verify_published_bundle.R "outputs/runs/${RUN_ID}" \
  --oracle tests/fixtures/goal011/judbury_selected_jaccard_oracle.csv
```

Alternative maintained examples are:

```sh
Rscript scripts/run_full_evidence_run.R --config config.template_example.yml
Rscript scripts/run_full_evidence_run.R --config config.forest_example.yml
Rscript scripts/run_full_evidence_run.R --config config.camtrapdp_example.yml
```

## Development

The top-level graph in `_targets.R` exposes seven stages: ingest, validate,
foundation, events, modules, report, and publish. Stage implementations live in
`R/workflow_stages.R`; reusable scientific and integrity functions live under
`R/`.

```sh
Rscript scripts/run_lint.R
Rscript scripts/run_tests.R --profile fast
actionlint .github/workflows/ci.yml
```

Ordinary CI runs lint, the compact fast suite, workflow-syntax checking, and a
small real publication smoke. The manually dispatched release runs one full
Judbury publisher and one independent reconstruction against the accepted
oracle.

See [workflow](docs/workflow.md), [architecture](docs/architecture.md),
[bundle contract](docs/reference/run_manifest.md), and
[container use](docs/container.md).

## License And Citation

Code is MIT licensed. The exemplar data are CC BY 4.0; see
`data_dictionary.md` and `CITATION.cff`.
