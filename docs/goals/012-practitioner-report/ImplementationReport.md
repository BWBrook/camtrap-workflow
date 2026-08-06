# Goal 012 Implementation Report

Date: 2026-08-06

Status: `ACCEPTED_PUBLICATION_AUTHORIZED`

## Delivered

Commit `9f54a17` replaces the broad technical report with one practitioner-facing
flow built from the existing emitted tables:

- physical sampling locations and the selected analytical resolution;
- confirmed effort, unknown operation, and observed richness shown together;
- a descriptive Jaccard heatmap of detected composition;
- the highest emitted physical-location/species operational-event rates, with
  each confirmed-effort denominator visible;
- compact day/night proportions for a displayed subset of emitted
  physical-location/species rows; and
- sampling-accumulation and event-gap diagnostics with nearby claim limits.

The full detailed tables remain in the bundle. No ecological output table,
analysis module, schema, dependency, or public configuration was added or
changed. The report receives only the configured day/night method as extra
display metadata.

## Verification

- `git diff --check`: passed.
- `Rscript scripts/run_lint.R`: passed.
- `actionlint .github/workflows/ci.yml`: passed.
- `Rscript scripts/run_tests.R --profile fast`: 518 passed, zero failures,
  warnings, or skips in 15.0 seconds.
- `renv::status()`: no issues found after excluding generated output bundles
  from dependency discovery.

Final forest-example run:

- run ID: `20260806T124919Z-14d37a9153aa4c33`;
- independent verifier: valid;
- six physical and analytical units, 366 operation rows, 90 events, 92 source
  memberships, and 36 Jaccard cells.

Final Judbury run:

- run ID: `20260806T124934Z-099ebaf906334100`;
- independent verifier and Goal 011 Jaccard oracle: valid;
- 13 physical locations, nine analysis sites, 9,639 operation rows, 11,572
  events, 15,672 source memberships, and all 81 accepted Jaccard cells.

Recursive comparison of every final `tables/` file with the corresponding
pre-report proof bundle produced no differences for either dataset. The report
changed communication, not scientific results.

## Visual review

Both reports were inspected in Chrome through Playwright at 1440 by 1000 CSS
pixels. The accepted full-page evidence is ignored, not tracked:

- `outputs/review/goal012/judbury-report.png`;
- `outputs/review/goal012/forest-report.png`.

The maps, effort/richness panels, heatmaps, rate bars, day/night bars, and
diagnostics fit the content column; text and labels do not overlap; the primary
flow is legible; and the browser console has zero errors or warnings. The
former 243-row day/night table is absent. Judbury's 13-to-nine mapping text
appears only in the Judbury report.

## Review and repair

The single serious review/repair pass closed two material issues:

1. An initial draft pooled physical-location rates and day/night counts inside
   the report. Those report-only ecological summaries were removed. The final
   figures display selected rows of already-emitted location-level results.
2. Initial visual evidence exposed three plots that were constructed but not
   printed and an effort facet that obscured richness. Explicit plot printing,
   equal-width facets, and block-level explanatory text fixed the report flow.

## Ecological meaning and residuals

The report now lets a practitioner see the survey footprint, sampling
inequality, detection-limited richness, detected-community differences,
effort-standardized location/species detection rates, and broad light-period
patterns without reading machine tables. Limits remain next to the affected
result: these outputs do not estimate unseen richness, abundance, density,
population trend, fine-scale diel activity, environmental cause, or habitat
surfaces.

Residuals are deliberately bounded: species use supplied identifiers rather
than a new display-name contract; rate and day/night panels show selected
location/species rows rather than inventing pooled survey metrics; the generic
proof is synthetic; and visual review was desktop-only. None alters the current
ecological decision or justifies more Goal 012 engineering.

## Boundary confirmation

No seasonal/trend, occupancy, unseen-richness, habitat, LocalMap, GUI,
installer, Docker, AI, schema/API, compatibility, provenance, theme,
interactive-dashboard, source-data, or dependency work was performed. No
push, merge, canonical-checkout edit, reset, clean, or stash was performed.
