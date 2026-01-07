# Detection history schema v0.1 (planned for WP-0.4.1)

This document defines the **planned** detection history output contract to be
implemented in WP-0.4.1. It is locked in early to prevent downstream refactors.

## Output format (long table)

One row per site × species × occasion.

Required columns:
- `site` (chr) — site identifier.
- `species` (chr) — species short code.
- `occasion` (int) — sequential occasion index (1..N).
- `detected` (int) — 0/1 detection indicator.
- `effort` (int) — 0/1 effort indicator for the occasion.
- `occasion_start` (dttm or date) — start of occasion window.
- `occasion_end` (dttm or date) — end of occasion window (exclusive).

## Alignment rules

- `detected == 1` implies `effort == 1`.
- `effort` must be 0/1 with no `NA`.
- Occasions are consecutive and non-overlapping within a site.

## Notes

- This long format is the canonical output. Model-specific wide matrices
  (site × occasion) will be derived from it for occupancy fitting.
- Occasions are defined via configuration (length, start date) in WP-0.4.1.
