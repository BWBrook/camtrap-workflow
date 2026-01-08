# Interpretation notes

This file is the running “lab notebook” for interpreting key artefacts produced by the pipeline.
For each major output, record what it shows, what it suggests, and anything surprising.

---

## 2025-12-18 — MVP bootstrap artefacts

Artefacts:
- `outputs/runs/latest/report/report.html` — rendered exemplar report (HTML, embedded resources)
- `outputs/runs/latest/figures/rarefaction.png` — species accumulation (rarefaction-style) curve
- `outputs/runs/latest/session_info.txt` — package/session provenance

Notes:
- `outputs/figures/rarefaction.png` shows increasing richness with additional camera sites; the curve has not fully saturated by the final site, suggesting either (a) imperfect site coverage or (b) low-frequency species still accruing.
- The uncertainty band is wide for low site counts and narrows with more sites, consistent with permutation variability in `vegan::specaccum()`.
- Next: add effort and event-spacing diagnostic plots to the report so we can sanity-check effort standardisation and event clustering assumptions visually (per `docs/workflow.md`).

---

## 2025-12-18 — Effort artefacts (WP-0.3.7)

Artefacts:
- `outputs/runs/latest/tables/effort_summary.csv` — effort metrics per site.
- `outputs/runs/latest/figures/effort_histogram.png` — distribution of trap nights per site.
- `outputs/runs/latest/figures/effort_heatmap.png` — site-by-date effort heatmap.

Notes:
- Effort histogram shows a right-skewed distribution with some sites having notably higher trap-night totals; this suggests uneven effort and reinforces the need for effort-standardised metrics.
- The heatmap highlights blocks of inactivity at specific sites; these align with known downtime patterns in the `jc_op.csv` matrix.
- No obvious negative or impossible effort values were observed in the summary table.

---

## 2026-01-06 — Time QC artefacts (WP-0.3.8)

Artefacts:
- `outputs/runs/latest/tables/time_qc_summary.csv` — per-site time QC summary.
- `outputs/runs/latest/tables/time_qc_flags.csv` — row-level flags for DST gaps and backward jumps.
- `outputs/runs/latest/figures/time_qc_backward_jumps.png` — backward-jump counts by site.

Notes:
- With `timezone_fixed_offset_hours` set, DST gaps are not expected; the summary shows zero DST-gap flags and no unparseable datetime strings.
- Backward time jumps are present at most sites (typically 1–7 per site) with large negative deltas; this likely reflects camera clock resets or image sequence resets between deployments rather than single-file errors.
- Because the backward jumps are flagged (not corrected), downstream analyses remain transparent; any site with many resets should be reviewed if temporal patterns are critical.

---

## 2026-01-08 — Fixed-offset timezone + diel method options

Artefacts:
- `outputs/runs/latest/tables/time_qc_summary.csv`
- `outputs/runs/latest/tables/diel_overall.csv`
- `outputs/runs/latest/figures/diel_overall.png`

Notes:
- Judbury runs now parse datetimes using a fixed UTC+10 offset; DST-gap counts remain at zero while backward-jump flags still surface clock resets.
- Diel classification defaults to `flash` (camera metadata) for Judbury, with an optional `clock` method using fixed day/night hours for other studies.

---

## 2026-01-08 — Spatial site map (interpolated surface)

Artefacts:
- `outputs/runs/latest/figures/site_map.png`

Notes:
- The map displays site locations over an interpolated NDVI surface (fallback to other covariates if NDVI is missing); it provides spatial context rather than a measured continuous surface.
- Site points align with the expected spatial clustering in the Judbury data; no outliers or coordinate anomalies were observed.
- The default map includes a north arrow and 1 km scale bar; site labels are optional via `spatial_map.label_sites`. The surface buffer extends beyond the site hull to keep points comfortably within the map extent.
- The map extent is computed as a square bounding box around sites with a small fractional buffer so the region of interest fills most of the canvas.

---

## 2026-01-06 — Event spacing diagnostics (WP-0.3.9)

Artefacts:
- `outputs/runs/latest/tables/events_per_day.csv` — independent event counts per site/species/day.
- `outputs/runs/latest/tables/event_spacing.csv` — per-event spacing (hours) between successive events.
- `outputs/runs/latest/figures/event_spacing.png` — event-gap histogram.

Notes:
- Event spacing shows a right-skewed distribution: most gaps are on the order of hours to days, with a long tail reflecting multi-month gaps between detections.
- Median gap is ~33 hours with a 75th percentile around ~119 hours, which is consistent with intermittent detections and uneven effort.
- No evidence that event counts exceed detections (invariants validated); the spacing plot provides a visual sanity check for clustering threshold effects.
- Event spacing histogram is shown on a log10-hours axis to make short gaps visible alongside long tails.

---

## 2026-01-06 — Descriptives (RAI, diel, rarefaction) (WP-0.3.10)

Artefacts:
- `outputs/runs/latest/tables/rai_species.csv` — pooled RAI with Poisson CIs.
- `outputs/runs/latest/figures/rai_species.png` — top species RAI plot with CIs.
- `outputs/runs/latest/tables/diel_overall.csv` — overall day/night proportions.
- `outputs/runs/latest/figures/diel_overall.png` — overall diel proportions plot.
- `outputs/runs/latest/tables/rarefaction.csv` — rarefaction curve data.
- `outputs/runs/latest/figures/rarefaction.png` — rarefaction plot (existing).

Notes:
- Pooled RAI highlights a small set of dominant species (e.g., `pos`, `pad`, `wal`) with clear separation from rarer taxa; CI widths are tight for abundant species and wider for rare ones, as expected from Poisson uncertainty.
- Overall diel proportions show a strong night bias (~76% night vs ~24% day), consistent with camera-trap detections of nocturnal species.
- Rarefaction table confirms richness increases to ~28 species by 13 sites, with diminishing gains at higher site counts.

---

## 2026-01-06 — Event threshold sensitivity (WP-0.3.14)

Artefacts:
- `outputs/runs/latest/tables/event_threshold_sensitivity.csv` — events per trap night vs threshold.
- `outputs/runs/latest/figures/event_threshold_sensitivity.png` — sensitivity curve.

Notes:
- Event rates decline as the threshold increases, as expected for more aggressive clustering.
- The curve is smooth across 5–60 minutes, suggesting no abrupt threshold artifacts for this dataset.
- Sensitivity output provides a baseline for choosing thresholds in later occupancy work.

---

## 2026-01-07 — Detection history output (WP-0.4.1)

Artefacts:
- `outputs/runs/latest/tables/detection_history.csv` — site × species × occasion detections with effort.

Notes:
- Detection histories show no detections during zero-effort occasions (alignment check passed).
- Occasions are 7-day windows starting from the first effort date.

---

## 2026-01-07 — Occupancy outputs (WP-0.4.2–0.4.5)

Artefacts:
- `outputs/runs/latest/tables/occupancy_summary.csv` — psi/p summaries for exemplar species.
- `outputs/runs/latest/tables/occupancy_aic.csv` — candidate model AIC table.
- `outputs/runs/latest/tables/occupancy_predictions.csv` — site-level occupancy predictions.
- `outputs/runs/latest/figures/occupancy_pred_<species>.png` — prediction plots.
- `outputs/runs/latest/models/occu_<species>_<model>.rds` — fitted models.

Notes:
- Best models for exemplar species often include effort and/or NDVI covariates; AIC tables show clear separation from the null model.
- Occupancy estimates for dominant species (`pos`, `pad`, `wal`) are high, as expected given widespread detections.
- Site-level prediction plots show limited spatial contrast for these dominant species; consider additional covariates in later WPs.

---

## 2026-01-07 — Occupancy predictions sanity fix (pad/pos/wal + cat/sbb)

Artefacts:
- `outputs/runs/latest/figures/occupancy_pred_pad.png`
- `outputs/runs/latest/figures/occupancy_pred_pos.png`
- `outputs/runs/latest/figures/occupancy_pred_wal.png`
- `outputs/runs/latest/figures/occupancy_pred_cat.png`
- `outputs/runs/latest/figures/occupancy_pred_sbb.png`

Notes:
- Point estimates are now visible (psi near 1 for pad/wal; pos slightly lower at some sites), and intervals are wide but bounded by data‑driven effort filtering.
- Rarer species (cat, sbb) show lower psi and wider uncertainty, consistent with fewer detections.

---

## 2026-01-07 — Occasion-length sensitivity (WP-0.4.4)

Artefacts:
- `outputs/runs/latest/tables/occasion_length_sensitivity.csv`
- `outputs/runs/latest/figures/occasion_length_sensitivity.png`

Notes:
- Naive occupancy remains stable across 3–30 day occasions for the top species, indicating robustness to occasion length in this dataset.
- Detection rates increase modestly with longer occasions, as expected from aggregation.

---

## 2026-01-07 — Community matrices (WP-0.5.1)

Artefacts:
- `outputs/runs/latest/tables/community_abundance.csv`
- `outputs/runs/latest/tables/community_presence.csv`

Notes:
- The exemplar community matrix has 13 sites × 28 species, with non-zero event totals at every site.
- Total event counts per site are highly right-skewed (median ~561 vs max ~2901), indicating uneven activity among sites that should be considered in downstream diversity comparisons.

---

## 2026-01-07 — Alpha diversity (WP-0.5.2)

Artefacts:
- `outputs/runs/latest/tables/alpha_diversity.csv`
- `outputs/runs/latest/figures/alpha_diversity.png`

Notes:
- Richness ranges from 4–19 species across sites; sites `jc_cen`, `jc_pm12`, `jc_pm14`, and `jc_pm23` are highest (richness = 19).
- Lowest richness occurs at `jc_co1_s1` (4) and `jc_pm14_s1` (6), consistent with smaller or more isolated deployments.

---

## 2026-01-07 — Beta diversity (WP-0.5.3)

Artefacts:
- `outputs/runs/latest/tables/beta_diversity.csv`
- `outputs/runs/latest/figures/beta_diversity_distance_decay.png`

Notes:
- Pairwise Bray–Curtis dissimilarity is generally high (median ~0.64, mean ~0.65), indicating substantial turnover between sites.
- Geographic distances span ~0.03–0.79 km; the distance–decay trend is weakly positive with wide scatter, suggesting limited spatial structuring at this scale.

---

## 2026-01-07 — Trait alignment (WP-0.5.4)

Artefacts:
- `outputs/runs/latest/tables/traits_clean.csv`
- `outputs/runs/latest/tables/traits_aligned.csv`
- `outputs/runs/latest/tables/traits_missing.csv`

Notes:
- No community species are missing trait records in the exemplar dataset (`traits_missing.csv` is empty).
- Trait categories are standardised to lowercase and cleaned of placeholder values before alignment.

---

## 2026-01-07 — Functional diversity (WP-0.5.5)

Artefacts:
- `outputs/runs/latest/tables/functional_diversity.csv`
- `outputs/runs/latest/tables/functional_diversity_dropped_species.csv`
- `outputs/runs/latest/figures/functional_diversity.png`

Notes:
- Functional richness (FRic) varies from 1–6 across sites; `jc_co2` and `jc_pm23` are highest (FRic = 6).
- Functional dispersion (FDis) is low to moderate (0–0.37), indicating modest trait spread within sites.
- Functional divergence (FDiv) now ranges from ~0.51–0.76 after dummy-encoding categorical traits; interpret cautiously given categorical trait inputs.

---

## 2026-01-07 — Trait–environment associations (WP-0.5.6)

Artefacts:
- `outputs/runs/latest/tables/trait_site_proportions.csv`
- `outputs/runs/latest/tables/trait_env_associations.csv`
- `outputs/runs/latest/figures/trait_env_associations.png`

Notes:
- BH-adjusted p-values are all > 0.1 in the exemplar dataset (no associations pass FDR), reinforcing that results are exploratory.
- Heatmap patterns show some alignment between canopy/elevation and diet/activity categories, but no single covariate dominates across traits.

---

## 2026-01-07 — Camtrap DP example run (WP-0.6.2)

Artefacts:
- `outputs/runs/camtrapdp_example/report/report.html`
- `outputs/runs/camtrapdp_example/report/report.pdf`
- `outputs/runs/camtrapdp_example/tables/occupancy_summary.csv`
- `outputs/runs/camtrapdp_example/figures/occupancy_pred_*.png`
- `outputs/runs/camtrapdp_example/figures/functional_diversity.png`

Notes:
- The Camtrap DP example contains only 4 deployments and no site covariates, so occupancy models fall back to base/effort-only and yield constant psi estimates across sites.
- The “unknown” taxon dominates detections in the example, leading to psi ≈ 1 with wide uncertainty; named taxa show lower psi (~0.25–0.52) and broad intervals given sparse detections.
- Functional diversity metrics are not computed because traits are missing; the plot is a placeholder indicating no available metrics.

---

## 2026-01-07 — Camtrap DP export (WP-0.6.3)

Artefacts:
- `outputs/runs/camtrapdp_export_example/camtrapdp_export/datapackage.json`
- `outputs/runs/camtrapdp_export_example/camtrapdp_export/validation.txt`

Notes:
- Export validates via `camtrapdp`/`frictionless` and produces deployments/media/observations tables.
- With the fixed-offset timezone setting, no unparseable datetimes were dropped in the exemplar export; if drops occur in other datasets, they are recorded in the audit file.

---

## 2026-01-07 — Template dataset dry run (WP-0.7.4)

Artefacts:
- `outputs/runs/template_example/report/report.html`
- `outputs/runs/template_example/figures/rarefaction.png`

Notes:
- Template run completes end‑to‑end; rarefaction ribbon warns about sparse rows (expected with tiny datasets).
- All core tables/figures are produced, confirming the template dataset is runnable.

## 2026-01-07 — RAI denominator semantics (WP-0.7.1.2)

- `outputs/runs/latest/tables/rai_species.csv`
- `outputs/runs/latest/figures/rai_species.png`

Notes:
- Pooled RAI now divides total events per species by total trap nights across all included sites, so `trap_nights` is constant across species within a run.
- This lowers pooled RAI for species detected at only a subset of sites (as expected) and aligns interpretation with survey-wide effort.

## 2026-01-07 — Occupancy summary detection probabilities (WP-0.7.1.3)

- `outputs/runs/latest/tables/occupancy_summary.csv`
- `outputs/runs/latest/figures/occupancy_pred_*.png`

Notes:
- Detection probability summaries (`p`, `p_lower`, `p_upper`) are now non-missing for the exemplar species; values fall within [0, 1] as expected.
- Rare species (`cat`, `sbb`) have lower mean detection probabilities than common taxa, consistent with sparse detections.

## 2026-01-07 — Run manifest portability (WP-0.7.1.4)

- `outputs/runs/latest/run_manifest.json`

Notes:
- Manifest paths are now stored relative to the run directory, avoiding absolute machine paths.
- Config file md5 and path are recorded to improve provenance.

## 2026-01-07 — Camtrap DP export audit log (WP-0.7.1.5)

- `outputs/runs/camtrapdp_export_example/camtrapdp_export/validation.txt`

Notes:
- When unparseable datetimes occur (e.g., DST gaps without a fixed offset), an audit file `dropped_observations.csv` is written alongside `validation.txt`. With the fixed offset setting, the exemplar export reports zero dropped observations.
