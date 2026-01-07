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
- The summary shows 1 DST-gap flag (site `jc_pm12`) and no unparseable datetime strings, consistent with the known 2021 spring DST jump in Tasmania.
- Backward time jumps are present at most sites (typically 1–7 per site) with large negative deltas; this likely reflects camera clock resets or image sequence resets between deployments rather than single-file errors.
- Because the backward jumps are flagged (not corrected), downstream analyses remain transparent; any site with many resets should be reviewed if temporal patterns are critical.

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
