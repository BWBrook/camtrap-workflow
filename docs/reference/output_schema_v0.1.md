# Output schema v0.1 (MVP)

All outputs are written under a **canonical run folder**:

```
outputs/
  latest                   (regular file containing one validated run ID)
  preflight/
    <run_id>/
      source_snapshot/
      provenance/
        phase2/
        entity_resolution/
        selected_resolution/
      PREVIEW.json
  runs/
    <run_id>/
      source_snapshot/
      provenance/
        phase2/
        entity_resolution/
        selected_resolution/
      figures/
      tables/
      report/
      models/           (reserved for Beta+)
      run_manifest.json
      COMPLETED.json
      session_info.txt
```

`<run_id>` is a unique filesystem-safe invocation identity allocated by
`scripts/run_full_evidence_run.R`. The configured `run_id` is retained only as
a compatibility label. Repeated equivalent invocations receive different IDs.
Direct or partial target calls write under `outputs/work/` and are never
complete evidence bundles.

Validation-only execution publishes an immutable preview under
`outputs/preflight/<run_id>/`. It never writes a terminal completion record,
renders a report, publishes a completed run, or changes `outputs/latest`.

## Tables (MVP)

Expected (current MVP):
- `tables/effort_summary.csv` — per-site effort metrics (trap nights, dates, proportion active).
- `tables/time_qc_summary.csv` — per-site datetime QC summary (parse failures, DST gaps, backward jumps).
- `tables/time_qc_flags.csv` — row-level flags for parse failures, DST gaps, and backward jumps.
- `tables/events_per_day.csv` — operational detection event counts per site/species/day.
- `tables/event_spacing.csv` — gap (hours) between successive operational detection events.
- `tables/event_threshold_sensitivity.csv` — event totals per threshold and events per trap night.
- `tables/occasion_length_sensitivity.csv` — naive occupancy and detection rates by occasion length.
- `tables/detection_history.csv` — detection histories in long format (site × species × occasion).
- `tables/occupancy_summary.csv` — occupancy estimates (psi at mean covariate values, profile-likelihood CI when available), detection probability summaries, and naive occupancy diagnostics (n_sites, n_sites_detected, exact binomial CI). Includes `psi_ci_method` to indicate how psi intervals were computed.
- `tables/occupancy_aic.csv` — AIC table for candidate occupancy models.
- `tables/occupancy_predictions.csv` — site-level occupancy predictions for exemplar species (point estimates; CIs may be NA if disabled).
- `tables/community_abundance.csv` — site × species abundance matrix (events).
- `tables/community_presence.csv` — site × species presence–absence matrix.
- `tables/alpha_diversity.csv` — per-site richness, Shannon, Simpson indices.
- `tables/beta_diversity.csv` — pairwise Bray-Curtis and geographic distances.
- `tables/traits_clean.csv` — cleaned trait table (taxa metadata).
- `tables/traits_aligned.csv` — traits aligned to community species.
- `tables/traits_missing.csv` — species missing trait records.
- `tables/functional_diversity.csv` — functional diversity metrics per site.
- `tables/functional_diversity_dropped_species.csv` — species excluded from functional diversity (missing traits).
- `tables/trait_site_proportions.csv` — abundance-weighted trait proportions by site.
- `tables/trait_env_associations.csv` — trait–environment association results (Spearman rho, p-values, BH-adjusted p-values).
- `tables/rai_site_species.csv` — RAI per site/species with Poisson CIs.
- `tables/rai_species.csv` — pooled RAI per species with Poisson CIs (denominator is total trap nights across all included sites).
- `tables/diel_site.csv` — diel proportions per site/species.
- `tables/diel_site_season.csv` — diel proportions per site/species/season.
- `tables/diel_overall.csv` — overall day/night proportions.
- `tables/species_summary.csv` — consolidated exploratory species summary (sites detected, pooled event rate, active-day coverage, diel mix, group size).
- `tables/first_detection_wait_time.csv` — site × species wait time from the first active day to the first independent detection, counted in active days only.
- `tables/first_detection_wait_time_species.csv` — species-level summaries of first-detection wait times across sites.
- `tables/multi_species_images.csv` — images containing more than one detected species, with a compact species list per image.
- `tables/multi_species_pairs.csv` — pairwise co-occurrence counts across qualifying multi-species images.
- `tables/rarefaction.csv` — rarefaction curve data (sites, richness, se).
- `tables/selected_effort_coverage.csv` — confirmed active, inactive, and
  unknown selected-unit days; written only for an eligible explicit route.
- `tables/selected_community_presence.csv` — selected-unit x species observed
  presence; written only for an eligible explicit route.
- `tables/selected_observed_richness.csv` — row sums of observed selected-unit
  presence. Richness is detection- and effort-limited, not estimated unseen
  richness; written only for an eligible explicit route.
- `tables/selected_jaccard.csv` — full symmetric descriptive Jaccard
  dissimilarity table based on observed presences. It is not standardized for
  unequal confirmed effort, sampling completeness, or species detectability;
  empty-union comparisons are recorded as missing. Written only for an
  eligible explicit route.
- `tables/selected_resolution_status.json` — always written for an explicit
  selection. It records integrity and route eligibility, reasons, resolution,
  scheme/version/authority, contributing physical locations and deployments,
  exact event conservation, claim limits, and four nullable ecological links.
  An ineligible route has four JSON null links and no selected CSV files.

## Figures (MVP)

- `figures/rarefaction.png` — species accumulation curve.
- `figures/effort_histogram.png` — histogram of trap nights per site.
- `figures/effort_heatmap.png` — site-by-date effort heatmap (active/inactive).
- `figures/site_map.png` — spatial overview with an interpolated covariate surface and site locations.
- `figures/time_qc_backward_jumps.png` — per-site count of backward time jumps.
- `figures/event_spacing.png` — distribution of time gaps between operational detection events.
- `figures/event_threshold_sensitivity.png` — sensitivity of event rate to threshold choice.
- `figures/occasion_length_sensitivity.png` — sensitivity of naive occupancy to occasion length.
- `figures/occupancy_pred_<species>.png` — site-level occupancy predictions for each modelled species.
- `figures/alpha_diversity.png` — per-site richness plot.
- `figures/beta_diversity_distance_decay.png` — distance–decay plot (Bray-Curtis vs distance).
- `figures/functional_diversity.png` — functional diversity metrics by site.
- `figures/trait_env_associations.png` — heatmap of trait–environment associations.
- `figures/rai_species.png` — pooled RAI by species with confidence intervals.
- `figures/diel_overall.png` — overall day/night event proportions.

## Report

- `report/report.html` — rendered Quarto report.
- `report/report.pdf` — rendered Quarto report (PDF).
- `report/report_inputs.rds` — inputs passed to the report (for reproducibility).

## Manuscript (skeleton)

- `manuscript/methods.html` — methods manuscript skeleton (HTML).
- `manuscript/methods.pdf` — methods manuscript skeleton (PDF).

## Models (Beta)

- `models/occu_<species>_<model>.rds` — fitted occupancy models for exemplar species.

## Provenance

- `source_snapshot/` — immutable parser bytes plus explicitly selected
  non-parser audit evidence, including schema files, materialised CamtrapDP
  resources, the Goal 007 crosswalk, and the Goal 008 service source and
  deployment ledger when selected.
- `provenance/source_inventory.json` — sorted SHA-256 inventory of
  immutable source bytes, with parser-consumption and evidence-role state.
- `provenance/config.raw.yml` — byte-exact YAML snapshot consumed by the
  supported target invocation.
- `provenance/effective_config.json` — canonical effective configuration with
  raw and resolved configuration hashes.
- `provenance/phase2/resource_registry.json` — logical parser resources and
  their deterministic content-derived identities.
- `provenance/phase2/source_row_ledger.json` — one record for every parsed
  source row, its parser ordinal, disposition, and observation mapping.
- `provenance/phase2/validation_findings.json` — structured integrity,
  semantic, and advisory findings.
- `provenance/phase2/transformations.json` — recorded meaning-preserving
  mappings between source resources and internal tables.
- `provenance/phase2/repair_proposals.json` — deterministic proposal-specific
  repair records.
- `provenance/phase2/repair_decisions.json` — exact reviewed approval,
  decline, or unresolved records.
- `provenance/phase2/repair_applications.json` — applied or not-applied state
  for every proposal.
- `provenance/phase2/changed_fields.json` — field-level lineage for values
  actually changed under exact authority.
- `provenance/phase2/event_membership.json` — retained operational detection
  events and their observation source-row memberships.
- `provenance/phase2/post_validation.json` — compact analysis-readiness and
  row/event accounting summary.
- `provenance/phase2/validated_inputs.rds` — the analysis-ready four-table
  object consumed by supported full runs.
- `provenance/entity_resolution/entity_resolution.csv` — versioned entity
  ledger with deterministic IDs and explicit resolved/unresolved states.
- `provenance/entity_resolution/entity_links.csv` — closed typed links,
  including undirected service-history move pairs.
- `provenance/entity_resolution/deployment_lineage.csv` — explicit deployment
  identity, location, interval, chronology, and readiness evidence. Duplicate
  or competing CamtrapDP evidence retains one attributable row per
  participating source row while remaining integrity-stopped or ambiguous.
  Explicit Goal 008 configurations use
  `camtrap-deployment-lineage/1.1`; its nullable additions carry the canonical
  physical identifier, date precision, endpoint semantics, start/end service
  labels, ordered event count and digest, predecessor/successor IDs, service
  and ledger row/fixity evidence, approval reference, daily-operation
  authority, and audit-only `run_days` disposition. Legacy omitted-block
  evidence retains the lineage 1.0 column contract.
- `provenance/entity_resolution/entity_resolution_summary.json` — profile,
  authority, counts, integrity findings, selected deployment evidence totals,
  and the explicit unselected `analysis_site` state.
- `provenance/entity_resolution/join_readiness.json` — audit-only
  unique/unresolved/ambiguous counts, bound to both the entity-ledger digest
  and the immutable source SHA-256. Goal 008 records zero joined analytical
  rows and forbids analytical routing. It is not an analytical join.
- `provenance/selected_resolution/membership.csv` — exact physical-location to
  selected-unit membership, scheme/version/authority, physical coordinates,
  and representative-coordinate basis.
- `provenance/selected_resolution/operation.csv` — conservative selected-unit
  day states with member-location and deployment contribution digests.
- `provenance/selected_resolution/event_map.csv` — unchanged operational event
  IDs assigned after event construction, retaining physical location,
  source-row membership, and deployment attribution.
- `provenance/selected_resolution/summary.json` — integrity, route eligibility,
  reasons, counts, claim limits, and SHA-256 links for the three CSV records.
- `run_manifest.json` — exact relative payload inventory with byte sizes and
  SHA-256 values plus source/config/engine/composite fingerprints.
- `COMPLETED.json` — terminal record written last; binds the run ID, manifest
  schema, and manifest SHA-256.
- `session_info.txt` — `sessionInfo()` output for the run.

The entity-resolution directory is a closed namespace: supported preview 1.1
and manifests 1.2-1.3 must contain exactly these five canonical paths, with no
missing, renamed, redirected, symlinked, nested, or extra entry. The selected
resolution directory is likewise a closed four-file namespace for preview 1.2
and manifest 1.3. Its manifest links and the five selected table/status links
are canonical and relative. `report/report_inputs.rds` stores the parsed
selected tables and status, never staging paths.

## Camtrap DP export (optional)

- `camtrapdp_export/datapackage.json` — Camtrap Data Package export of the internal tables.
- `camtrapdp_export/dropped_observations.csv` — audit log of observations dropped due to unparseable datetimes (e.g., DST gaps).
- `camtrapdp_export/deployments.csv` — deployment metadata derived from site/effort.
- `camtrapdp_export/media.csv` — media metadata (one row per observation by default).
- `camtrapdp_export/observations.csv` — observation records with eventStart/eventEnd.
- `camtrapdp_export/validation.txt` — validation log from `camtrapdp`/`frictionless`.

The current exporter still derives its deployment envelope from the first and
last `jc_op == 1` dates. Goal 008 does not substitute its declared deployment
spans into export output. Reconciling those distinct operational and
deployment meanings is deferred to a separate compatibility decision and
implementation packet.

## Notes

- Output names should be stable across runs to enable comparisons.
- A completed run directory is immutable and never overwritten.
- `outputs/latest` is replaced only after completion and bundle verification.
- `PREVIEW.json` is a validation record, not a completion record.
- Existing output filenames containing `event` remain compatibility names;
  current prose uses `operational detection event`.
- Changes to output schema require doc updates and sanity/regression tests.
