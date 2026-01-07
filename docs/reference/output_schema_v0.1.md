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
- `tables/rai_site_species.csv` — RAI per site/species with Poisson CIs.
- `tables/rai_species.csv` — pooled RAI per species with Poisson CIs.
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
- `figures/rai_species.png` — pooled RAI by species with confidence intervals.
- `figures/diel_overall.png` — overall day/night event proportions.

## Report

- `report/report.html` — rendered Quarto report.
- `report/report.pdf` — rendered Quarto report (PDF).
- `report/report_inputs.rds` — inputs passed to the report (for reproducibility).

## Provenance

- `run_manifest.json` — run parameters, schema version, outputs, timestamp.
- `session_info.txt` — `sessionInfo()` output for the run.

## Notes

- Output names should be stable across runs to enable comparisons.
- Changes to output schema require doc updates and sanity/regression tests.
