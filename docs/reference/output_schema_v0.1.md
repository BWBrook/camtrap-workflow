# Output schema v0.1 (MVP)

All outputs are written under a **canonical run folder**:

```
outputs/
  runs/
    <run_id>/
      figures/
      tables/
      report/
      models/           (reserved for Beta+)
      run_manifest.json
      session_info.txt
```

`<run_id>` is configured in `config.yml` (default: `latest`).

## Tables (MVP)

Expected (current MVP):
- `tables/effort_summary.csv` — per-site effort metrics (trap nights, dates, proportion active).
- `tables/time_qc_summary.csv` — per-site datetime QC summary (parse failures, DST gaps, backward jumps).
- `tables/time_qc_flags.csv` — row-level flags for parse failures, DST gaps, and backward jumps.
- `tables/events_per_day.csv` — independent event counts per site/species/day.
- `tables/event_spacing.csv` — gap (hours) between successive independent events.
- `tables/event_threshold_sensitivity.csv` — event totals per threshold and events per trap night.
- `tables/occasion_length_sensitivity.csv` — naive occupancy and detection rates by occasion length.
- `tables/detection_history.csv` — detection histories in long format (site × species × occasion).
- `tables/occupancy_summary.csv` — occupancy estimates (psi, p) for exemplar species; `p` is the mean predicted detection probability across observed occasions with effort > 0.
- `tables/occupancy_aic.csv` — AIC table for candidate occupancy models.
- `tables/occupancy_predictions.csv` — site-level occupancy predictions for exemplar species.
- `tables/community_abundance.csv` — site × species abundance matrix (events).
- `tables/community_presence.csv` — site × species presence–absence matrix.
- `tables/alpha_diversity.csv` — per-site richness, Shannon, Simpson indices.
- `tables/beta_diversity.csv` — pairwise Bray-Curtis and geographic distances.
- `tables/traits_clean.csv` — cleaned trait table (taxa metadata).
- `tables/traits_aligned.csv` — traits aligned to community species.
- `tables/traits_missing.csv` — species missing trait records.
- `tables/functional_diversity.csv` — functional diversity metrics per site.
- `tables/functional_diversity_dropped_species.csv` — species excluded from functional diversity (missing traits).
- `tables/trait_site_proportions.csv` — abundance-weighted trait proportions by site.
- `tables/trait_env_associations.csv` — trait–environment association results (Spearman rho, p-values, BH-adjusted p-values).
- `tables/rai_site_species.csv` — RAI per site/species with Poisson CIs.
- `tables/rai_species.csv` — pooled RAI per species with Poisson CIs (denominator is total trap nights across all included sites).
- `tables/diel_site.csv` — diel proportions per site/species.
- `tables/diel_site_season.csv` — diel proportions per site/species/season.
- `tables/diel_overall.csv` — overall day/night proportions.
- `tables/rarefaction.csv` — rarefaction curve data (sites, richness, se).

## Figures (MVP)

- `figures/rarefaction.png` — species accumulation curve.
- `figures/effort_histogram.png` — histogram of trap nights per site.
- `figures/effort_heatmap.png` — site-by-date effort heatmap (active/inactive).
- `figures/time_qc_backward_jumps.png` — per-site count of backward time jumps.
- `figures/event_spacing.png` — distribution of time gaps between independent events.
- `figures/event_threshold_sensitivity.png` — sensitivity of event rate to threshold choice.
- `figures/occasion_length_sensitivity.png` — sensitivity of naive occupancy to occasion length.
- `figures/occupancy_pred_<species>.png` — site-level occupancy predictions for each modelled species.
- `figures/alpha_diversity.png` — per-site richness plot.
- `figures/beta_diversity_distance_decay.png` — distance–decay plot (Bray-Curtis vs distance).
- `figures/functional_diversity.png` — functional diversity metrics by site.
- `figures/trait_env_associations.png` — heatmap of trait–environment associations.
- `figures/rai_species.png` — pooled RAI by species with confidence intervals.
- `figures/diel_overall.png` — overall day/night event proportions.

## Report

- `report/report.html` — rendered Quarto report.
- `report/report.pdf` — rendered Quarto report (PDF).
- `report/report_inputs.rds` — inputs passed to the report (for reproducibility).

## Manuscript (skeleton)

- `manuscript/methods.html` — methods manuscript skeleton (HTML).
- `manuscript/methods.pdf` — methods manuscript skeleton (PDF).

## Models (Beta)

- `models/occu_<species>_<model>.rds` — fitted occupancy models for exemplar species.

## Provenance

- `run_manifest.json` — run parameters, schema version, outputs, timestamp.
- `session_info.txt` — `sessionInfo()` output for the run.

## Camtrap DP export (optional)

- `camtrapdp_export/datapackage.json` — Camtrap Data Package export of the internal tables.
- `camtrapdp_export/dropped_observations.csv` — audit log of observations dropped due to unparseable datetimes (e.g., DST gaps).
- `camtrapdp_export/deployments.csv` — deployment metadata derived from site/effort.
- `camtrapdp_export/media.csv` — media metadata (one row per observation by default).
- `camtrapdp_export/observations.csv` — observation records with eventStart/eventEnd.
- `camtrapdp_export/validation.txt` — validation log from `camtrapdp`/`frictionless`.

## Notes

- Output names should be stable across runs to enable comparisons.
- Changes to output schema require doc updates and sanity/regression tests.
