# Current Output Contract

## Validation Preview

`outputs/preflight/<run_id>/` contains captured source and validation evidence
plus `validation_preview.json`. A preview has no completion record and never
changes `outputs/latest`.

## Completed Run

`outputs/runs/<run_id>/` contains one `camtrap-run-bundle/2.0` bundle:

```text
run_manifest.json
READY
COMPLETE.json
report/
  report.html
  report.qmd
  report_inputs.rds
results/
  module_status.json
tables/
figures/
provenance/
source_snapshot/
```

The exact payload is enumerated with byte sizes and SHA-256 digests in
`run_manifest.json`.

## Core Tables

- `physical_events.csv`: one physical-location operational event with source
  membership count and digest.
- `selected_effort_coverage.csv`: confirmed active, inactive, and unknown days
  at the selected analytical resolution.
- `selected_community_presence.csv`: zero/one observed presence formed by
  logical OR over conserved physical-location events.
- `selected_observed_richness.csv`: row sums of observed presence.
- `selected_jaccard.csv`: all ordered pairs of descriptive detected-composition
  dissimilarity; empty unions are `NA`.
- `selected_resolution_status.json`: selected membership, temporal scope,
  contributors, conservation result, and scientific claim limits.
- `operational_event_detection_rate.csv`: physical-location events per
  confirmed active day.
- `coarse_day_night.csv`: supported coarse temporal categories.
- `species_accumulation.csv`: sampling-accumulation diagnostic when eligible.
- `event_gap_sensitivity.csv`: dependence on candidate event-gap thresholds.

Eligible figures are `species_accumulation.png`,
`physical_location_map.png`, and `event_gap_sensitivity.png`.

## Evidence

`results/module_status.json` has one record for each candidate module. Detailed
validation, entity, selected-resolution, event-membership, captured-source,
configuration, engine, and session evidence lives under `provenance/` and
`source_snapshot/`.

Paths must be read from the manifest rather than assumed when building an
external audit tool.
