# Architecture

## Product Boundary

Camtrap Workflow is an R analysis project, not a package or hosted service. It
accepts already-labelled records and publishes a local ecological evidence
bundle. `targets` provides orchestration; Quarto renders one HTML report.

## Data Flow

```text
workflow request
  -> immutable ingest
  -> validation and controlled repair
  -> entity, deployment, effort, and spatial foundation
  -> physical-location events and source membership
  -> eligible ecological modules and status records
  -> HTML report
  -> internal verification and atomic publication
  -> independent emitted-bundle reconstruction
```

`_targets.R` is a seven-target composer. `R/workflow_stages.R` owns the stage
boundaries. Scientific arithmetic and evidence validation stay in focused
modules under `R/`.

## Contracts

- `camtrap-workflow-request/2.0` carries run identity, paths, creation time,
  target store, and acquisition function into the graph.
- `camtrap-workflow-stage/2.0` identifies each returned stage value.
- `camtrap-module-status/2.0` records eligibility and outcome per module.
- `camtrap-run-bundle/2.0` is the only supported completed-run manifest.
- `camtrap-run-completion/2.0` binds a published run to its manifest digest.

Historical bundles remain evidence but are not read through compatibility
dispatch. Regenerate a current bundle from immutable sources when needed.

## Integrity Boundary

The publisher performs one internal verification before publication. It then
renames the staged directory into `outputs/runs/<run_id>/`, writes
`COMPLETE.json`, verifies again at the publication boundary, and atomically
updates `outputs/latest`.

The independent verifier reads only emitted artefacts. It checks payload
fixity, source/event lineage, physical-location identity and source fields,
selected event conservation, presence/richness arithmetic, Jaccard semantics,
module status, and report existence. The Judbury release also checks fixed
foundation counts and the accepted 81-pair Jaccard oracle.

## Scientific Boundary

The pipeline distinguishes observation from inference:

- effort is confirmed active time; unknown operation is not filled;
- events are deterministic groupings of source detections under a configured
  gap rule;
- presence and richness are observed, effort- and detection-bounded values;
- Jaccard is descriptive detected composition;
- event detection rate is not abundance or density;
- day/night is a coarse clock-evidence category;
- accumulation is a sampling diagnostic; and
- maps display supplied physical points and approved grouping overlays only.

Nominal station may be retained in entity provenance, but only
`physical_location` and an explicitly approved `analysis_site` are analytical
routes.
