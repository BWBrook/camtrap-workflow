# PI review cover — Lines 0.6 & 0.7

## Scope completed

Lines **0.6** and **0.7** are complete under the approved review‑gate override. This includes:

- Camtrap DP ingestion + export (validated) and mapping docs.
- Teaching module (guided exercises).
- Reproducibility benchmark + cold‑run protocol.
- Release discipline: VERSION, CHANGELOG, CITATION, release bundle definition.
- Container recipe (Dockerfile + docs).
- Methods manuscript skeleton tied to pipeline artefacts.
- Template dataset dry run + failure‑mode notes.
- v1 readiness checklist and evidence summary.

## Where to find things

### Key docs

- Roadmap status: `docs/roadmap.md`
- Decisions: `docs/decisions.md`
- Interpretation notes (artefact sanity notes): `docs/interpretation_notes.md`
- Logs for each WP: `docs/log/`
- Teaching module: `docs/teaching_module.md`
- Reproducibility benchmark: `docs/reproducibility_benchmark.md`
- Template dry‑run notes: `docs/template_dry_run.md`
- v1 readiness summary: `docs/v1_readiness.md`
- Release bundle definition: `docs/release_bundle.md`
- Container usage: `docs/container.md`

### Camtrap DP

- Ingestion mapping: `docs/reference/camtrapdp_mapping_v0.1.md`
- Example config (ingest): `config.camtrapdp_example.yml`
- Example run outputs: `outputs/runs/camtrapdp_example/`

### Camtrap DP export

- Export code: `R/camtrapdp_export.R`
- Export config (Judbury exemplar): `config.camtrapdp_export.yml`
- Export outputs: `outputs/runs/camtrapdp_export_example/camtrapdp_export/`

### Methods manuscript

- Source: `analysis/methods.qmd`
- Rendered outputs: `outputs/runs/latest/manuscript/methods.html` + `methods.pdf`

### Release discipline

- Version: `VERSION`
- Changelog: `CHANGELOG.md`
- Citation metadata: `CITATION.cff`

### Container

- Dockerfile: `Dockerfile`
- Build/run instructions: `docs/container.md`

## How to run / validate

### Tests + lint

```sh
Rscript scripts/run_lint.R
Rscript scripts/run_tests.R
```

### Exemplar pipeline

```sh
Rscript -e 'targets::tar_make(callr_function = NULL)'
```

### Camtrap DP ingestion example

```sh
CAMTRAP_CONFIG=config.camtrapdp_example.yml Rscript -e 'targets::tar_make(callr_function = NULL)'
```

### Camtrap DP export example

```sh
CAMTRAP_CONFIG=config.camtrapdp_export.yml Rscript -e 'targets::tar_make(names = "camtrapdp_export", callr_function = NULL)'
```

### Template dry run

```sh
CAMTRAP_CONFIG=config.template_example.yml Rscript -e 'targets::tar_make(callr_function = NULL)'
```

## Known limitations / notes

- CI remains disabled pending system deps (GLPK/libjq); local lint/tests/pipeline are green.
- Camtrap DP export drops observations with unparseable datetimes (1 row in Judbury example; logged).
- Template dataset run shows a rarefaction ribbon warning due to small sample size.

## Artefacts for review

Primary artefacts are in `outputs/runs/`:

- `outputs/runs/latest/` — exemplar run with report + figures + tables.
- `outputs/runs/camtrapdp_example/` — DP ingestion run.
- `outputs/runs/camtrapdp_export_example/` — DP export package.
- `outputs/runs/template_example/` — template dataset run.

Each run includes `run_manifest.json` and `session_info.txt` for provenance.
