# Analysis-Site Ecological Vertical Slice Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a bounded, provenance-rich branch that reports Judbury effort,
observed richness, presence composition, and Jaccard turnover at the approved
nine-analysis-site resolution without changing the existing physical-location
analyses.

**Architecture:** Preserve the current physical-location graph through
`obs_events` and add a parallel branch after event construction. A new
`R/selected_resolution.R` owns selection, membership, operation union, event
mapping, route eligibility, and selected-resolution provenance; existing
community, alpha, and beta helpers receive only narrow presence/richness/
Jaccard additions. Explicit analysis-unit configurations advance preview and
manifest schemas, while a genuinely omitted block retains the legacy path and
schemas.

**Tech Stack:** R 4.6.1, `targets`, `testthat`, `readr`, `jsonlite`, YAML,
Quarto, immutable CSV/JSON/RDS provenance, SHA-256 bundle verification.

## Global Constraints

- This packet is `PACKET_DRAFT_AWAITING_EXACT_APPROVAL`; implementation does
  not begin until the exact authority gate in `Runbook.md` passes.
- The mapping file is immutable during implementation at SHA-256
  `6490d7f7021e5c727b9be1c7d6dfbf44ba50a1ef5b0396c66e1dd813a9c77083`.
- Keep `analysis_unit` absent from `default_config()`. A genuinely omitted
  block retains legacy physical-location behaviour, preview 1.1, and manifest
  1.2.
- Every explicit `analysis_unit` mode uses preview 1.2 and manifest 1.3,
  including mapped or identity `analysis_site`, direct `physical_location`,
  and direct `nominal_station`.
- Separate the global `integrity_ok` hard gate from selected-route
  `route_eligible`. Concurrency is fail-soft for the selected route; invalid
  authority, membership, fixity, or provenance is a global stop.
- Always emit selected-resolution status/provenance for an explicit mode.
  When `route_eligible` is false, omit the four selected data files and store
  null manifest links while the legacy graph continues.
- Build the preflight event map from
  `validation_state$event_lineage$obs_events`, never from the compact event
  ledger, and cross-link the existing Phase 2 source-row membership.
- Do not change event construction, the Goal 007/008 entity namespace, Goal
  008 service parsing, CamtrapDP export, shared physical `op_long`,
  `obs_events`, or `events_per_day`, or any excluded analytical module.
- Use no new package or public schema commitment. The mapping interface remains
  provisional and internal.
- Perform one focused independent review and at most one material repair pass.
  Stop at the verified high-value core.

---

## File Structure and Closed Future Allowlist

The implementation may create or modify only these paths:

### Runtime and pipeline

- Create `R/selected_resolution.R`: selection normalization, mapping
  validation, membership resolution, operation union, event mapping,
  conservation, route status, provenance write/read/verification.
- Modify `R/config.R`: validate explicit raw selection and normalize it into
  resolved provenance without adding a default.
- Modify `R/source_inventory.R`: immutable mapping acquisition and the closed
  non-parser role `analysis_site_mapping_input`.
- Modify `R/community_matrices.R`: selected presence/absence OR-union helper.
- Modify `R/alpha_diversity.R`: observed-richness-from-presence helper only.
- Modify `R/beta_diversity.R`: descriptive Jaccard-from-presence helper only.
- Modify `R/run_bundle.R`: preview 1.2 and manifest 1.3 selected-provenance
  validation while retaining legacy verification.
- Modify `R/run_manifest.R`: manifest 1.3 link block and nullable selected
  output links.
- Modify `scripts/run_full_evidence_run.R`: preflight selected state,
  provenance, and separate integrity/route status.
- Modify `_targets.R`: parallel selected branch and five selected output
  records.

### Configuration

- Modify `config.yml`.
- Modify `config.camtrapdp_export.yml`.
- Modify `config.template_example.yml`.
- Modify `config.forest_example.yml`.
- Modify `config.camtrapdp_example.yml`.

### Focused report surfaces

- Modify `analysis/report.qmd`.
- Modify `analysis/methods.qmd`.

### Tests

- Create `tests/testthat/test_selected_resolution.R`.
- Modify `tests/testthat/test_config_identity.R`.
- Modify `tests/testthat/test_source_inventory.R`.
- Modify `tests/testthat/test_community_matrices.R`.
- Modify `tests/testthat/test_alpha_diversity.R`.
- Modify `tests/testthat/test_beta_diversity.R`.
- Modify `tests/testthat/test_validation_ledger.R`.
- Modify `tests/testthat/test_run_bundle.R`.
- Modify `tests/testthat/test_run_manifest.R`.
- Modify `tests/testthat/test_pipeline_smoke.R`.

Synthetic identity, invalid-mapping, unknown-operation, same-day-handover,
gap, concurrency, duplicate-presence, and empty-community controls must be
constructed inside the focused tests. The approved packet mapping is the
Judbury fixture; do not create a divergent copy.

### References and records

- Modify `docs/reference/config.md`.
- Modify `docs/reference/input_schema_v0.1.md`.
- Modify `docs/reference/output_schema_v0.1.md`.
- Modify `docs/reference/run_manifest.md`.
- Modify `docs/decisions.md`.
- Modify `docs/roadmap.md`.
- Modify `docs/design/004-product-blueprint/decision_register.md`.
- Modify `docs/design/004-product-blueprint/development_roadmap.md`.
- Modify `docs/goals/009-analysis-site-vertical-slice/Log.md`.
- Create `docs/log/670_goal009_analysis_site_vertical_slice.md`.

`Goal.md`, `Plan.md`, `Runbook.md`, and
`judbury_analysis_site_mapping.csv` are immutable implementation authorities.
All unlisted paths are protected. A necessary unlisted edit is a stop and
scope-review condition, not permission to widen the allowlist.

## Locked Internal Interfaces

The raw provisional selection is:

```yaml
analysis_unit:
  resolution: "analysis_site"
  mapping_profile_id: "judbury-analysis-site/1.0.0-proposed"
  mapping_path: "docs/goals/009-analysis-site-vertical-slice/judbury_analysis_site_mapping.csv"
  mapping_sha256: "6490d7f7021e5c727b9be1c7d6dfbf44ba50a1ef5b0396c66e1dd813a9c77083"
  authority_reference: "goal009-judbury-analysis-site-mapping-sha256-6490d7f7021e5c727b9be1c7d6dfbf44ba50a1ef5b0396c66e1dd813a9c77083"
```

`resolution` is closed to `analysis_site`, `physical_location`, and
`nominal_station`. For `analysis_site`, the four mapping fields are either all
selected or all null. All-null means the fixed built-in one-to-one identity:

```text
scheme_id: camtrap-physical-location-identity
scheme_version: 1.0.0
authority_reference: camtrap-workflow-built-in-physical-location-identity/1.0.0
```

`read_config()` must retain the raw selection and add a deterministic resolved
provenance record to the effective configuration. Direct physical or nominal
selection requires four null mapping fields. Physical selection resolves to
the built-in physical identity above; nominal selection requires authoritative
Goal 007/008 membership evidence at runtime. An omitted block produces neither
selection nor resolved record.

`R/selected_resolution.R` exposes these implementation interfaces:

```text
analysis_unit_selection(config) -> NULL or normalized selection
resolve_selected_resolution(config, snapshot, validation_state, entity_state)
  -> selected state with integrity_ok, route_eligible, reasons, membership,
     operation, event_map, and summary
write_selected_resolution_artifacts(state, root) -> four-path named list
validate_selected_resolution_artifacts(root, paths, require_integrity = TRUE)
  -> reconstructed selected state summary
build_selected_presence(event_map, analysis_units, species) -> 0/1 data frame
build_selected_effort_coverage(operation, membership) -> data frame
```

The closed provenance namespace is:

```text
provenance/selected_resolution/membership.csv
provenance/selected_resolution/operation.csv
provenance/selected_resolution/event_map.csv
provenance/selected_resolution/summary.json
```

The completed-run output names are:

```text
tables/selected_effort_coverage.csv
tables/selected_community_presence.csv
tables/selected_observed_richness.csv
tables/selected_jaccard.csv
tables/selected_resolution_status.json
```

The status file always exists for an explicit mode. The four CSV files exist
only when `route_eligible` is true.

### Task 1: Freeze Authority and Write the Complete RED Contract

**Files:**
- Test: all ten focused test files in the allowlist.
- Read only: packet authorities, approved Goal 007/008 evidence, current
  configs, current runtime and analytical helpers.

**Interfaces:**
- Consumes: the exact configuration, provenance, output, and status contracts
  above.
- Produces: one complete failing-test contract for Tasks 2-5 and a captured
  accepted physical baseline.

- [ ] **Step 1: Pass the authority and clean-baseline gate**

Run the Git, SHA-256, packet-approval, preview, full-run, bundle-verification,
latest-pointer, validated-input, Goal 007/008, Phase 2, event, effort, and
excluded-output capture in `Runbook.md`. Stop before editing if any gate fails.

- [ ] **Step 2: Write all focused failing tests before production edits**

Name tests for raw/normalized configuration, omitted legacy behaviour, all
four explicit resolution forms, exact source snapshot, mapping integrity,
operation truth table, full-event lineage links, same-day handover,
`jc_pm14` gap, concurrency fail-soft status, OR collapse, event conservation,
richness row sums, Jaccard edge cases, schema compatibility, output omission,
and legacy invariance.

- [ ] **Step 3: Run one RED pass**

```sh
Rscript -e 'for (f in c(
  "tests/testthat/test_config_identity.R",
  "tests/testthat/test_source_inventory.R",
  "tests/testthat/test_selected_resolution.R",
  "tests/testthat/test_community_matrices.R",
  "tests/testthat/test_alpha_diversity.R",
  "tests/testthat/test_beta_diversity.R",
  "tests/testthat/test_validation_ledger.R",
  "tests/testthat/test_run_bundle.R",
  "tests/testthat/test_run_manifest.R",
  "tests/testthat/test_pipeline_smoke.R"
)) testthat::test_file(f, stop_on_failure = FALSE)'
```

Expected: failures are limited to absent Goal 009 functions, config fields,
schema links, selected outputs, and report/bundle contracts. A malformed
fixture, existing-test regression, or unrelated failure must be repaired in
the tests or escalated before production code changes.

- [ ] **Step 4: Record the checkpoint**

Write RED command, counts, failure classes, baseline run IDs, bundle paths,
hashes, and latest-pointer evidence to ignored
`outputs/goal009_acceptance/{pre,fixtures}/` and
`docs/goals/009-analysis-site-vertical-slice/Log.md`. Do not commit ignored
evidence.

### Task 2: Configuration and Immutable Mapping Acquisition

**Files:**
- Modify: `R/config.R`, `R/source_inventory.R`, five config YAML files.
- Test: `test_config_identity.R`, `test_source_inventory.R`,
  `test_selected_resolution.R`.

**Interfaces:**
- Consumes: raw `analysis_unit` block and exact mapping authority.
- Produces: normalized selection/effective provenance and either zero mapping
  snapshots or exactly one inventoried `analysis_site_mapping_input`.

- [ ] **Step 1: Make configuration tests GREEN**

Implement closed field validation, all-selected/all-null rules, built-in
identity normalization, direct-resolution rules, and true omitted-block
compatibility. Put the exact mapped selection in `config.yml` and
`config.camtrapdp_export.yml`; put explicit physical selection with four nulls
in the three example configs.

- [ ] **Step 2: Make immutable acquisition tests GREEN**

Snapshot a selected mapping under
`source_snapshot/analysis_site_mapping/`, inventory exactly one non-parser
record, and verify configured, repository, snapshot, inventory, and
reconstructed SHA-256 values agree. Reject extra sidecars, path escape,
mutation, missing selection, and checksum reclosure.

- [ ] **Step 3: Run the focused GREEN checkpoint**

```sh
Rscript -e 'for (f in c(
  "tests/testthat/test_config_identity.R",
  "tests/testthat/test_source_inventory.R",
  "tests/testthat/test_selected_resolution.R"
)) testthat::test_file(f)'
```

Expected: PASS with omitted configs retaining legacy semantics and every
explicit mode carrying deterministic resolved provenance.

- [ ] **Step 4: Record the checkpoint**

Append exact tests, mapping digest, source role/path, and any material
assumption to the Goal Log.

### Task 3: Selected Membership, Operation, Event, and Status Evidence

**Files:**
- Create: `R/selected_resolution.R`.
- Modify: `scripts/run_full_evidence_run.R`, `R/run_bundle.R`.
- Test: `test_selected_resolution.R`, `test_validation_ledger.R`,
  `test_run_bundle.R`.

**Interfaces:**
- Consumes: normalized selection, immutable source snapshot,
  `validation_state$event_lineage$obs_events`, Phase 2 source-row membership,
  entity/deployment evidence, validated site/op tables.
- Produces: the closed four-file provenance namespace plus independent
  `integrity_ok` and `route_eligible` status.

- [ ] **Step 1: Resolve and validate membership**

Implement mapped analysis-site, built-in identity, direct physical, and
authoritative nominal routes. Reject duplicate, orphan, incomplete,
conflicting-coordinate, unauthorized, or altered membership as
`integrity_ok = false`.

- [ ] **Step 2: Union operation and classify handover/concurrency**

Apply active if any active, inactive only if all relevant members are known
inactive, otherwise unknown. Use exact Goal 008 lineage to recognize an
approved same-date predecessor/successor handover once. Preserve the
`jc_pm14` gap. Mark genuine concurrent active members
`route_eligible = false` without changing `integrity_ok`.

- [ ] **Step 3: Map full preflight events and source-row evidence**

Build `event_map.csv` from the full preflight `obs_events` object. Cross-link
each event to its existing Phase 2 source-row membership and selected unit;
prove one selected membership per event, unchanged event ID, species, time,
source-row digest/membership, and exact total and per-species conservation.

- [ ] **Step 4: Publish and reconstruct provenance in both modes**

Write the same four provenance files during validation-only and full preflight.
Advance every explicit mode to preview 1.2, retain preview 1.0/1.1
verification, and validate the exact namespace, payload fixity, identities,
semantics, and route status.

- [ ] **Step 5: Run the focused GREEN checkpoint**

```sh
Rscript -e 'for (f in c(
  "tests/testthat/test_selected_resolution.R",
  "tests/testthat/test_validation_ledger.R",
  "tests/testthat/test_run_bundle.R"
)) testthat::test_file(f)'
```

Expected: PASS for exact Judbury membership, operation union, handover, gap,
unknown and concurrency controls, event conservation, preview parity, and
legacy preview verification.

- [ ] **Step 6: Record the checkpoint**

Append provenance schemas, status truth table, test results, and any
ineligible-route evidence to the Goal Log.

### Task 4: Add the Parallel Ecological Branch

**Files:**
- Modify: `R/community_matrices.R`, `R/alpha_diversity.R`,
  `R/beta_diversity.R`, `_targets.R`.
- Test: `test_selected_resolution.R`, `test_community_matrices.R`,
  `test_alpha_diversity.R`, `test_beta_diversity.R`,
  `test_pipeline_smoke.R`.

**Interfaces:**
- Consumes: validated selected provenance, unchanged `obs_events`, and
  selected `route_eligible`.
- Produces: four selected CSVs when eligible and one status JSON always,
  without changing any legacy target input.

- [ ] **Step 1: Add narrow ecological helpers**

Build analytical-unit rows and species columns by logical OR, observed
richness by row sum, and symmetric pairwise Jaccard dissimilarity with
nonempty diagonals zero and empty-union comparisons `NA`. Do not call or
rename legacy Shannon/Simpson, Bray-Curtis, or distance-decay functions.

- [ ] **Step 2: Add only the post-event target branch**

Start after `obs_events`; validate the preflight event map against the runtime
events and do not use `events_per_day` as lineage input. Write the five named
selected outputs. On ineligibility write only status, expose null links for
the four CSVs, and allow every legacy target to continue.

- [ ] **Step 3: Prove ecological and routing invariants**

Test nine Judbury units, exact OR reconstruction, exact richness sums,
Jaccard reconstruction/bounds/symmetry/empty cases, expected duplicate
presence collapse, and exact event conservation. Prove the legacy
`op_long`, `obs_events`, `events_per_day`, community/alpha/beta, RAI, diel,
occupancy, rarefaction, traits, functional diversity, event diagnostics,
exports, covariates, and broad maps retain their original inputs.

- [ ] **Step 4: Run the focused GREEN checkpoint**

```sh
Rscript -e 'for (f in c(
  "tests/testthat/test_selected_resolution.R",
  "tests/testthat/test_community_matrices.R",
  "tests/testthat/test_alpha_diversity.R",
  "tests/testthat/test_beta_diversity.R",
  "tests/testthat/test_pipeline_smoke.R"
)) testthat::test_file(f)'
```

Expected: PASS with no selected data files for the valid-concurrent fixture
and no changed legacy branch.

- [ ] **Step 5: Record the checkpoint**

Append output dimensions, conservation totals, OR-collapse reconciliation,
Jaccard checks, and legacy target-input evidence to the Goal Log.

### Task 5: Manifest, Report, and Reference Integration

**Files:**
- Modify: `R/run_manifest.R`, `R/run_bundle.R`, `_targets.R`,
  `analysis/report.qmd`, `analysis/methods.qmd`, four reference documents,
  `docs/decisions.md`.
- Test: `test_run_manifest.R`, `test_run_bundle.R`,
  `test_pipeline_smoke.R`.

**Interfaces:**
- Consumes: selected provenance/status and nullable selected output paths.
- Produces: manifest 1.3, portable reconstruction, and a focused,
  plain-language report/methods addition.

- [ ] **Step 1: Add schema 1.3 and nullable output links**

Every explicit mode links the closed selected provenance block and status.
Eligible runs link four selected data files; ineligible runs carry four
explicit null links and no files. Retain verification of manifest 1.0-1.2;
only genuinely omitted-block legacy runs remain manifest 1.2.

- [ ] **Step 2: Add the focused report and methods text**

State that Judbury combines 13 physical locations into nine analysis sites,
four coordinates are fixed synthetic midpoints, physical covariates were not
pooled, effort is confirmed active site-days, richness is observed, and
Jaccard turnover is descriptive. Do not redesign the report or relabel
legacy physical outputs.

- [ ] **Step 3: Document the provisional contract**

Document explicit selection, built-in identity, mapping fixity, preview 1.2,
manifest 1.3, selected provenance/output fields, status semantics, claim
limits, retained legacy schemas, and deferred public API/migration.

- [ ] **Step 4: Run the focused GREEN checkpoint**

```sh
Rscript -e 'for (f in c(
  "tests/testthat/test_run_manifest.R",
  "tests/testthat/test_run_bundle.R",
  "tests/testthat/test_pipeline_smoke.R"
)) testthat::test_file(f)'
```

Expected: PASS for explicit eligible/ineligible modes, copied-bundle
verification, checksum reclosure rejection, and manifest/preview legacy
compatibility.

- [ ] **Step 5: Record the checkpoint**

Append schema paths, report claims inspected, verifier controls, and reference
updates to the Goal Log.

### Task 6: Full Acceptance, Independent Review, and Publication

**Files:**
- Modify: Goal Log, project log, decisions, and both roadmaps within the
  closed allowlist.
- Evidence only: ignored `outputs/goal009_acceptance/{post,review}/`.

**Interfaces:**
- Consumes: the complete implementation and pre-edit comparator.
- Produces: one accepted implementation commit and exact-SHA CI evidence, or a
  bounded blocker report.

- [ ] **Step 1: Run the complete local gate**

```sh
Rscript scripts/run_lint.R
Rscript scripts/run_tests.R
Rscript scripts/run_full_evidence_run.R --config config.yml --validate-only
Rscript scripts/run_full_evidence_run.R --config config.yml
Rscript scripts/run_full_evidence_run.R --verify-bundle "outputs/runs/<run_id>"
```

Copy the completed bundle to a new temporary root and verify that copy. Replace
`<run_id>` only with the run ID emitted by the immediately preceding full run.

- [ ] **Step 2: Reconstruct the scientific evidence independently**

From immutable mapping, `jc_op`, Goal 008 lineage, full event membership, and
the selected presence matrix, independently reproduce mapping, operation
union, `jc_co1` handover once, `jc_pm14` gap, event conservation, OR collapse,
richness, Jaccard, metadata, nullable ineligible links, and preview/full
provenance parity.

- [ ] **Step 3: Prove compatibility and publication boundaries**

Compare all protected legacy targets and excluded module outputs to the
captured baseline; verify validation-only never completes or advances latest,
only a verified full bundle advances latest, partial runs remain unpublished,
and the changed-path set is a subset of the closed allowlist.

- [ ] **Step 4: Obtain one independent review**

Review scientific meaning, selection authority, source-row event provenance,
integrity versus route eligibility, schema compatibility, output omission,
legacy invariance, and portable reconstruction. Apply at most one focused
material repair, then rerun affected checks and the full required gate.

- [ ] **Step 5: Close out and publish**

After acceptance, the orchestrator stages exact allowlisted paths, commits
with subject:

```text
feat: add analysis-site ecological slice
```

Push the exact accepted SHA and require matching GitHub Actions `ci` success
before marking Goal 009 final. Record all SHAs, run IDs, verdict, residual
limitations, and the highest-value next tranche.

## Stopping Boundary

Stop rather than widening into automatic grouping, generalized repeated
deployment handling, concurrent-camera aggregation, covariate pooling,
coverage-standardized or unseen richness, inferential turnover, RAI/diel/
occupancy/rarefaction/trait migration, exporter changes, report redesign,
public API/migration, GUI work, or Phase 3 completion.

Two consecutive attempts without material new evidence trigger a blocker
handoff. Cosmetic polish after the complete acceptance gate does not justify
another iteration.
