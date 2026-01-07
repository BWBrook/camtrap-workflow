# Teaching module: guided exercises

These exercises walk through key workflow choices by changing parameters and observing artefacts. Each exercise is designed for ~10–20 minutes.

## Setup

1) Restore dependencies:

```r
renv::restore(prompt = FALSE)
```

2) Run the baseline pipeline (exemplar dataset):

```sh
Rscript -e 'targets::tar_make(callr_function = NULL)'
```

All outputs appear under `outputs/runs/<run_id>/` (default `latest`).

---

## Exercise 1 — Event threshold sensitivity (events)

**Change**
- Edit `config.yml` → `event_threshold_minutes` from `15` to `5` and re-run the pipeline.

**Run**
```sh
Rscript -e 'targets::tar_make(names = "event_threshold_sensitivity_plot", callr_function = NULL)'
```

**Expected outcome**
- `figures/event_threshold_sensitivity.png` shifts upward for smaller thresholds (more events per trap night).

---

## Exercise 2 — Effort censoring implications (effort + QC)

**Change**
- Temporarily set one site column in `data/jc_op.csv` to all zeros (simulate a camera never active).

**Run**
```sh
Rscript -e 'targets::tar_make(names = c("effort_summary_csv", "effort_heatmap_plot"), callr_function = NULL)'
```

**Expected outcome**
- `tables/effort_summary.csv` shows 0 trap nights for that site.
- `figures/effort_heatmap.png` shows an all‑inactive row for that site.

---

## Exercise 3 — Occupancy model choice (occupancy)

**Change**
- In `config.yml`, set `occupancy.covariates` to only one covariate (e.g., `["ndvi"]`).

**Run**
```sh
Rscript -e 'targets::tar_make(names = c("occupancy_aic_csv", "occupancy_predictions_csv"), callr_function = NULL)'
```

**Expected outcome**
- `tables/occupancy_aic.csv` contains a smaller candidate set.
- Prediction plots change only if the remaining covariate contains variation.

---

## Exercise 4 — Community vs. presence matrices (community)

**Change**
- No parameter change; compare presence vs abundance matrices.

**Run**
```sh
Rscript -e 'targets::tar_make(names = c("community_abundance_csv", "community_presence_csv"), callr_function = NULL)'
```

**Expected outcome**
- `community_abundance.csv` contains event counts.
- `community_presence.csv` contains 0/1 values only.

---

## Exercise 5 — Trait choice (functional diversity)

**Change**
- In `config.yml`, set `traits.columns` to a smaller subset (e.g., `["diet", "activity"]`).

**Run**
```sh
Rscript -e 'targets::tar_make(names = c("functional_diversity_csv", "functional_diversity_plot"), callr_function = NULL)'
```

**Expected outcome**
- Functional diversity values shift, reflecting a narrower trait space.
- If a chosen trait has a single level, FRic/FDiv/FDis may become `NA`.

---

## Exercise 6 — Occasion length (detection history)

**Change**
- Adjust `detection_history.occasion_length_days` from `7` to `14`.

**Run**
```sh
Rscript -e 'targets::tar_make(names = "detection_history_csv", callr_function = NULL)'
```

**Expected outcome**
- `tables/detection_history.csv` has fewer occasions (longer aggregation windows).
- Naive occupancy should be similar, but detection rates may increase.
