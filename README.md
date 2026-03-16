# camtrap-workflow

Reproducible camera-trap workflow for end-to-end analysis in R.

This repository provides a **targets-based** pipeline that starts from labelled camera-trap detections plus site and effort metadata, performs validation and standardisation, constructs independent events, and produces core ecological analyses (including community diversity and trait summaries) and a rendered report.

The Judbury Conservation Reserve (Tasmania) dataset included in `data/` is the exemplar case study.

## What this repo is (and is not)

**It is:**
- a reproducible analysis pipeline (`targets`)
- a set of reusable functions (`R/`)
- a rendered report (Quarto/Rmd) built from pipeline outputs

**It is not:**
- an image labelling or ML system (labelling happens upstream)
- a database or data platform
- a Shiny app (out of scope for now)

## Quickstart

### 1) Prerequisites
- R 4.5.3
- Quarto (for report rendering). Verify with: `quarto --version`
- LaTeX/TinyTeX (for PDF report rendering)
- System build tools appropriate for your OS (some R packages compile from source)

### 2) Restore the locked environment
From the project root, run:

```r
renv::restore(prompt = FALSE)
```

If you do not have `renv` installed yet:

```r
install.packages("renv")
renv::restore(prompt = FALSE)
```

### 3) Run the pipeline

In R:

```r
targets::tar_make()
```

Or from the shell (non-interactive):

```sh
Rscript -e 'targets::tar_make()'
```

To run with an alternate config file:

```sh
CAMTRAP_CONFIG=config.camtrapdp_example.yml Rscript -e 'targets::tar_make()'
```

### 4) View outputs

Outputs are written to `outputs/` (gitignored). Look for:

* `outputs/runs/<run_id>/report/` for the rendered report
  - HTML: `report.html`
  - PDF: `report.pdf`
* `outputs/runs/<run_id>/figures/` for plots
* `outputs/runs/<run_id>/tables/` for community matrices, diversity, and trait summaries
* `outputs/runs/<run_id>/session_info.txt` for session provenance
* `outputs/runs/<run_id>/run_manifest.json` for run provenance

## Running on your own dataset

This workflow assumes you already have:

* site metadata (`site`)
* camera operation/effort (`op`)
* labelled detections (`obs`)
* taxa/traits (`taxa`)

Start with the template dataset in `data/template_dataset/` and follow the step-by-step guide:
`docs/bring_your_own_data.md`.

Camtrap DP datasets are also supported via `camtrapdp` (see the Camtrap DP section in `docs/bring_your_own_data.md`).
You can optionally export your cleaned data back to Camtrap DP by enabling `camtrapdp_export` in `config.yml`.

See `docs/product_brief.md` and `docs/reference/input_schema_v0.1.md` for required columns and formats.
Update `config.yml` to point to your input file paths and parameters (timezone, fixed offset if DST is ignored, event threshold).

## Example datasets

- **Judbury exemplar** (default): `data/jc_*` with `config.yml` (run_id `latest`).
- **Template dataset**: `data/template_dataset/` with `config.template_example.yml`.
- **Forest example (synthetic)**: `data/forest_example/` with `config.forest_example.yml`.

Run an example dataset by setting the config:

```sh
CAMTRAP_CONFIG=config.forest_example.yml Rscript -e 'targets::tar_make()'
```

## Development workflow

* The pipeline is defined in `_targets.R`.
* Reusable functions live in `R/`.
* Tests live in `tests/`.
* Project decisions and milestones live in `docs/`.

Run quality gates locally:

```sh
Rscript scripts/run_lint.R
Rscript scripts/run_tests.R
Rscript -e 'targets::tar_make()'
```

Container users: see `docs/container.md` for build/run instructions.

Before contributing changes, please read:

* `docs/workflow.md`
* `docs/roadmap.md`
* `docs/decisions.md`
* `docs/teaching_module.md` (guided exercises)

## License

Code: MIT License (see `LICENSE`).

Data (exemplar): CC-BY 4.0 (see `data_dictionary.md` for citation guidance).

## Citing

See `CITATION.cff` for the recommended citation metadata.
