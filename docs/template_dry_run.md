# Template dataset dry run

This document records the end‑to‑end run of the template dataset and known failure modes.

## Run summary

- Config: `config.template_example.yml`
- Run ID: `template_example`
- Status: success (1 warning)
- Artefacts: `outputs/runs/template_example/`

## Observed warnings

- `geom_ribbon()` removed 2 rows with missing values (likely from rarefaction confidence bands with sparse data).

## Known failure modes

- Missing or malformed `obs$datetime` causes time parsing failures.
- Missing `lat/lon` in `site.csv` will block Camtrap DP export.
- Trait tables with no variation yield `NA` functional diversity metrics.
- Very small datasets may produce sparse rarefaction curves or wide uncertainty.
