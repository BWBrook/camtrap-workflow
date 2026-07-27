# Goal 008 - Documentation plan

This is a future implementation plan. It begins only after the packet is
published through the exact gate in `Goal.md` and Barry separately approves
the complete packet, normalized service source, deployment ledger, packet
commit, and exact authority reference.

## Work sequence

1. **Authority and baseline gate**
   - Require clean synchronized `main` at the exact published packet commit.
   - Verify the packet subject, authoring parent, exact ten-path packet diff,
     normalized service SHA-256, ledger SHA-256, Goal 007 crosswalk SHA-256,
     `data/jc_op.csv` SHA-256, and Barry's exact approval receipt.
   - Capture the default validation-only and full Goal 007 baseline, immutable
     bundle, latest-pointer bytes, five entity artefacts, four validated
     inputs, all Phase 2 evidence, 13 scientific comparator tables, methods,
     event membership, effort, row accounting, and target metadata.
   - Stop without editing if authority, source state, or baseline evidence is
     incomplete.

2. **Failing Goal 008 fixtures**
   - Add an exact approved 13-row service source and ledger fixture under
     `tests/testthat/fixtures/goal008/`.
   - Add duplicate raw ID, duplicate deployment ID, unknown alias, missing and
     extra row, source/ledger endpoint disagreement, reversed chronology,
     orphan predecessor/successor, conflicting physical link, malformed date,
     changed hash, checksum-reclosure, extra sidecar, and path-escape controls.
   - Add same-day boundary and pm14 documented-gap controls that cannot route
     observations or effort.
   - Add `run_days` controls proving exact retention without effort use.
   - Confirm focused tests fail for the absent Goal 008 contract rather than
     malformed fixture setup.

3. **Separate configuration and immutable acquisition**
   - Add only the six-field provisional `deployment_evidence` selection in
     `R/config.R`; do not modify the frozen Goal 007 `entity_resolution`
     selection.
   - Put the exact approved selection in `config.yml` and
     `config.camtrapdp_export.yml`; put explicit nulls in the template,
     forest, and CamtrapDP-ingestion configurations.
   - Snapshot and inventory the service source and ledger under their two
     dedicated non-parser roles in `R/source_inventory.R`.
   - Verify configured, repository, snapshotted, inventoried, and reconstructed
     hashes agree before parsing.

4. **Deterministic source and ledger validation**
   - Parse the exact 16-column service schema from the immutable copy.
   - Apply only the 13 explicit alias rows; implement no normalization rule.
   - Reproduce all 75 ordered non-NA service dates and all supplied
     `run_days` literals and missing states.
   - Cross-check every ledger ID, physical/nominal/move-pair value, start/end
     label and date, service count, chronology edge, source row, and authority
     field.
   - Stop on duplicate, orphan, conflict, reversal, tamper, or extra evidence.

5. **Narrow deployment-lineage 1.1**
   - Bump only `camtrap-deployment-lineage/1.0` to 1.1.
   - Extend each lineage row with exact physical, date-precision, endpoint,
     service-label/count/digest, predecessor/successor, source, ledger,
     operation-authority, approval, and run-days-disposition evidence.
   - Resolve exactly 13 deployment entities and 13
     `deployment_to_physical_location` links after all authority gates pass.
   - Reproduce four directed chronology relations while retaining the four
     Goal 007 move pairs as undirected.
   - Keep all other entity schema identifiers and `analysis_site` state
     unchanged.

6. **Supported validation and full-path integration**
   - Extend the existing preflight in `scripts/run_full_evidence_run.R` after
     immutable source acquisition and before scientific analysis.
   - Write the same five closed Goal 007 artefacts in validation-only and full
     modes; add no artefact or directory.
   - Keep `validated_inputs.rds` at exactly `site`, `op`, `obs`, and `taxa`.
   - Keep deployment join readiness audit-only and outside the target graph.

7. **Manifest 1.2 reconstruction**
   - Retain preview 1.1, manifest 1.2, and the current entity link block.
   - Reconstruct all five entity artefacts from immutable Goal 006 parser
     evidence, Goal 007 crosswalk evidence, Goal 008 source/ledger evidence,
     and raw/resolved configuration.
   - Reject missing or extra files, source or ledger mutation, altered service
     events or lineage, orphan links, path escape, schema drift, summary drift,
     and checksum reclosure.
   - Verify legacy manifest 1.0 and 1.1 bundles unchanged.

8. **Scientific invariance**
   - Prove `data/jc_op.csv` byte and semantic identity.
   - Prove exact identity of all four validated analytical inputs.
   - Prove exact Phase 2 evidence, row accounting, event membership, effort,
     events, methods, thresholds, gap rule, and all 13 comparator tables.
   - Prove the scientific graph still receives the same 13 legacy physical
     site keys and produces no nine-station analysis.
   - Prove validation-only cannot complete or advance latest, partial target
     execution cannot publish trusted evidence, and only a verified full run
     advances latest.

9. **Focused references and records**
   - Update only the four allowlisted reference documents for the provisional
     selection, immutable inputs, lineage 1.1 fields, and unchanged five-file
     namespace.
   - Record implementation in the Goal Log, project log, decisions, and
     roadmaps without claiming analysis, effort/event routing, adapter/export
     repair, or Phase 3 completion.
   - Record the CamtrapDP first/last-active export envelope as deferred
     technical debt without modifying it.

10. **Acceptance, review, and publication**
    - Run the full ladder in `Runbook.md` and retain raw ignored evidence.
    - Inspect the exact changed-path set against the closed future allowlist.
    - Obtain one independent implementation review of authority, source
      semantics, lineage, reconstruction, scientific invariance, and scope.
    - Apply at most one focused material repair and rerun affected checks plus
      the complete required gate.
    - After clean acceptance, stage exact paths, commit, push, and bind final
      confirmation to the exact implementation SHA in existing CI.

## Stopping boundary

Do not continue into `analysis_site`, nine-station analysis, effort or
observation routing, event or denominator changes, repair or inference rules,
CamtrapDP adapter/export changes, public schema/API work, target-graph changes,
GUI/report work, ecological methods, or another Phase 3 slice.

Stop on any condition in `Goal.md` or `Runbook.md`. Return the exact evidence
or decision that requires Barry instead of filling a gap by inference.
