# Goal 006 - Validation, repair preview, and source-row lineage

## Date

2026-07-23 AEST

## Outcome

The supported evidence runner now provides a validation-only preflight:

```sh
Rscript scripts/run_full_evidence_run.R --config config.yml --validate-only
```

It publishes an immutable `outputs/preflight/<run_id>/PREVIEW.json` without
creating a completion record, rendering a report, publishing a completed run,
or changing `outputs/latest`. A supported full run executes the same
preflight and consumes only its verified analytical RDS.

The Phase 2 evidence surface records content-derived resource identities,
parser-row identities and dispositions, structured findings,
meaning-preserving transformations, proposal-specific repair state,
changed-field lineage, and observation-source membership for every retained
operational detection event. The public four-table input schema remains
v0.1.

Semantic repairs default to preview without application. Every application
requires an exact matching approval; overriding explicit evidence also
requires a recorded reason. Broad or stale authority fails integrity.
Historical CamtrapDP fill defaults are preview-only, non-applicable production
proposals and cannot auto-apply.

New completed bundles use `camtrap-evidence-manifest/1.1`; existing manifest
1.0 bundles remain verifiable. The 1.1 verifier reconstructs every Phase 2
document and all four analytical tables from immutable source bytes plus exact
config decisions, rather than trusting reclosable internal hashes.

## Scientific scope

No event threshold, gap rule, effort calculation, ecological model, estimand,
or downstream value was changed. Current prose uses `operational detection
event`; compatibility filenames and configuration keys remain.

The default Judbury run proposes and applies no repair. Its 16,806 parsed rows
reconcile, 22 observation rows have explicit exclusion reasons, and 15,672
retained observation memberships resolve to 11,572 operational detection
events.

## Evidence

Ignored raw evidence is under `outputs/goal006_acceptance/`.

- Baseline manifest 1.0 run:
  `20260723T100735Z-198a9df77af1446e`.
- Clean ready preview:
  `20260723T105546Z-f692b617b4ae4487`; latest bytes unchanged.
- Clean full manifest 1.1 run:
  `20260723T105817Z-6ed71ceea2ee4f15`; 90 completed, 42 skipped, 83 payload
  files, and all 11 Phase 2 hashes equal to the preview.
- The real manifest 1.1 and preserved 1.0 bundles verify after repair.
- All 10 stable tables are byte- and value-identical to baseline; all three
  occupancy tables have zero numerical difference.
- Final lint is clean; the authoritative suite reports 406 PASS, 0 FAIL,
  0 SKIP, and one expected existing export warning.

## Review and publication state

The independent implementation review returned `REPAIR_IMPLEMENTATION` after
demonstrating a checksum-reclosed non-event value change in
`validated_inputs.rds`. The single focused repair added complete
source/config reconstruction and a regression that mutates `obs$count`; the
tampered bundle is now rejected. Focused and authoritative gates pass.

Local implementation and acceptance are complete. Nothing was staged,
committed, pushed, or submitted to CI; publication and exact-SHA CI
confirmation remain with the orchestrator.
