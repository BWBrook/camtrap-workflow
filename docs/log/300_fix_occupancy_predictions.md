# Fix occupancy prediction outputs

Date: 2026-01-07

## What changed
- Masked zero-effort occasions as NA in occupancy detection histories.
- Corrected site labels used for occupancy predictions.
- Updated occupancy prediction plots to show point estimates with error bars.
- Added rarer species (cat, sbb) to occupancy config and outputs.
- Updated occupancy tests for NA masking and site covariate ordering.

## Artefacts produced
- `outputs/runs/latest/figures/occupancy_pred_pad.png`
- `outputs/runs/latest/figures/occupancy_pred_pos.png`
- `outputs/runs/latest/figures/occupancy_pred_wal.png`
- `outputs/runs/latest/figures/occupancy_pred_cat.png`
- `outputs/runs/latest/figures/occupancy_pred_sbb.png`
- `outputs/runs/latest/tables/occupancy_predictions.csv`
- `outputs/runs/latest/tables/occupancy_summary.csv`

## Sanity checks
- psi estimates are high for pad/pos/wal (as expected), with visible point estimates.
- cat/sbb show lower psi estimates than dominant species and wider intervals.

## Decisions
- None.
