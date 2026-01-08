# PI review cover — 0.7.1 hardening line

## Scope completed

Line **0.7.1** is complete. This hardening pass resolves the PI‑flagged correctness and provenance blockers:

- CI re‑enabled with required system deps (GLPK/JQ) and smoke tests.
- Pooled RAI denominator fixed to use total survey effort.
- Occupancy summary `p` values restored (non‑missing) with explicit semantics.
- Run manifests now portable (run‑relative paths + config hash) and documented.
- Camtrap DP export now logs any dropped observations (e.g., unparseable datetimes) via an audit file when present.
- Judbury runs use fixed‑offset timezone parsing (DST ignored) with configurable diel method (`flash`/`clock`).
- Added a spatial site map with interpolated covariate surface for context.

## Where to find things

### Key docs

- Roadmap status: `docs/roadmap_v2.md` (mirrored in `docs/roadmap.md`)
- Decisions: `docs/decisions.md`
- Interpretation notes: `docs/interpretation_notes.md`
- Logs for each WP: `docs/log/`

### CI

- Workflow: `.github/workflows/ci.yml`
- v1 readiness: `docs/v1_readiness.md`

### Outputs + provenance

- Exemplar run: `outputs/runs/latest/`
- Camtrap DP ingest example: `outputs/runs/camtrapdp_example/`
- Camtrap DP export example: `outputs/runs/camtrapdp_export_example/`
- Template dataset run: `outputs/runs/template_example/`
- Spatial map: `outputs/runs/latest/figures/site_map.png`
- Run manifest schema: `docs/reference/run_manifest.md`

### Camtrap DP export audit

- Audit file (if any): `outputs/runs/camtrapdp_export_example/camtrapdp_export/dropped_observations.csv`
- Validation: `outputs/runs/camtrapdp_export_example/camtrapdp_export/validation.txt`

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
CAMTRAP_CONFIG=config.camtrapdp_export.yml Rscript -e 'targets::tar_make(callr_function = NULL)'
```

### Template dry run

```sh
CAMTRAP_CONFIG=config.template_example.yml Rscript -e 'targets::tar_make(callr_function = NULL)'
```

## Known limitations / notes

- Rarefaction ribbons can be sparse for tiny datasets (see template run warning).
- Unparseable datetimes in the configured timezone are logged and excluded from Camtrap DP exports (audit file included when drops occur).

## Artefacts for review

Primary artefacts are in `outputs/runs/`:

- `outputs/runs/latest/` — exemplar run with report + figures + tables.
- `outputs/runs/camtrapdp_example/` — DP ingestion run.
- `outputs/runs/camtrapdp_export_example/` — DP export package + audit file.
- `outputs/runs/template_example/` — template dataset run.

Each run includes `run_manifest.json` and `session_info.txt` for provenance.
