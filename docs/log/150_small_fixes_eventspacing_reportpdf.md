# 2026-01-06 — Event spacing log scale + PDF report output

## Summary

- Event spacing histogram now uses a log10-hours x-axis to resolve short-gap spikes.
- Quarto report renders both HTML and PDF by default; CI updated to support PDF output.

## Artefacts

- `outputs/runs/latest/figures/event_spacing.png` (log10 hours)
- `outputs/runs/latest/report/report.html`
- `outputs/runs/latest/report/report.pdf`

## Sanity checks

- Log-scale event spacing plot renders without errors.
- Report renders to HTML and PDF in the canonical run folder.
