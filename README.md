# camtrap-workflow

Reproducible camera-trap workflow for end-to-end analysis in R.

This repository provides a **targets-based** pipeline that starts from labelled camera-trap detections plus site and effort metadata, performs validation and standardisation, constructs independent events, and produces core ecological analyses and a rendered report.

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
- R 4.5.2
- System build tools appropriate for your OS (especially for spatial packages)

### 2) Restore the locked environment
From the project root, run:

```r
renv::restore()
````

If you do not have `renv` installed yet:

```r
install.packages("renv")
renv::restore()
```

### 3) Run the pipeline

In R:

```r
targets::tar_make()
```

### 4) View outputs

Outputs are written to `outputs/` (gitignored). Look for:

* `outputs/report/` for the rendered report
* `outputs/figures/` for plots
* `outputs/tables/` for derived tables

## Running on your own dataset

This workflow assumes you already have:

* site metadata (`site`)
* camera operation/effort (`op`)
* labelled detections (`obs`)
* taxa/traits (`taxa`)

See `docs/product_brief.md` and the data contract documentation (to be expanded) for required columns and formats.

## Development workflow

* The pipeline is defined in `_targets.R`.
* Reusable functions live in `R/`.
* Tests live in `tests/`.
* Project decisions and milestones live in `docs/`.

Before contributing changes, please read:

* `docs/workflow.md`
* `docs/roadmap.md`
* `docs/decisions.md`

## License

Code: MIT License (see `LICENSE`).

Data: see dataset documentation and `data_dictionary.md` for licensing and citation guidance.
