# Interpretation notes

This file is the running “lab notebook” for interpreting key artefacts produced by the pipeline.
For each major output, record what it shows, what it suggests, and anything surprising.

---

## 2025-12-18 — MVP bootstrap artefacts

Artefacts:
- `outputs/report/report.html` — rendered exemplar report (HTML, embedded resources)
- `outputs/figures/rarefaction.png` — species accumulation (rarefaction-style) curve
- `outputs/session_info.txt` — package/session provenance

Notes:
- `outputs/figures/rarefaction.png` shows increasing richness with additional camera sites; the curve has not fully saturated by the final site, suggesting either (a) imperfect site coverage or (b) low-frequency species still accruing.
- The uncertainty band is wide for low site counts and narrows with more sites, consistent with permutation variability in `vegan::specaccum()`.
- Next: add effort and event-spacing diagnostic plots to the report so we can sanity-check effort standardisation and event clustering assumptions visually (per `docs/workflow.md`).

