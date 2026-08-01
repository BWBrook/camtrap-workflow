# Configuration reference (config.yml)

The pipeline is configured via a single YAML file at the project root: `config.yml`.

## Fields

- `schema_version_path`  
  Path to `schema_version.txt`.

- `run_id`  
  Legacy compatibility label shown in reports (default: `latest`). It is not
  the evidence directory name, manifest identity, collision key, or latest
  selector. The supported publisher allocates a unique invocation ID.

- `timezone`  
  Olson timezone string used for datetime parsing (e.g., `Australia/Hobart`).

- `timezone_fixed_offset_hours`  
  Optional fixed offset in hours (e.g., `10` for UTC+10). When provided, datetimes are parsed using a fixed offset (`Etc/GMT±H`) and DST gaps are ignored.

- `event_threshold_minutes`  
  Gap threshold (minutes) for operational detection event clustering.

- `input_mode`  
  Input mode selector: `four_table` (default) or `camtrapdp`.

- `camtrapdp_acquisition.mode`
  Explicit acquisition mode: `local` for a local descriptor or `remote` for an
  HTTP(S) descriptor.

- `camtrapdp_acquisition.cache_dir`
  Controlled content-addressed cache used by remote acquisition.

- `camtrapdp_acquisition.descriptor_sha256`
  Required pinned SHA-256 for a remote `datapackage.json`; null for local
  acquisition.

- `camtrapdp_acquisition.resource_sha256`
  Named map from each remote resource path to its required SHA-256. A SHA-256
  declared by the resource may be used when present.

- `paths.inputs`  
  Input table paths for the four-table contract:
  - `site`
  - `op`
  - `obs`
  - `taxa`
  - `camtrapdp` (local path or HTTP(S) URL consistent with the explicit
    acquisition mode)

- `paths.outputs`  
  Base output directory for all artefacts (default `outputs`).

- `validation.repair_decisions`
  Provisional Phase 2 list of exact proposal decisions. Each record requires
  `proposal_id`, `proposal_digest`, and `decision` (`approved` or `declined`);
  `reason` is optional except that an approved `override_explicit` proposal
  requires a non-empty reason. Unknown fields, wildcard/class-wide authority,
  stale digests, duplicates, and conflicts fail safely. The block may be
  omitted by legacy configurations; shipped configurations use an empty list.

- `entity_resolution`
  Provisional internal evidence selection, not a public v0.1 input field.
  The block contains exactly `profile_id`, `sidecar_path`, `sidecar_sha256`,
  and `authority_reference`. All four values must either be explicit `null`,
  or bind one approved profile and sidecar exactly. The default Judbury
  configuration selects
  `judbury-entity-crosswalk/1.0.0-proposed` with SHA-256
  `553abada14493f3a5f0ae3c072523b6d5cc0d0c6a6c6480ca17a9e3331f2d8ec`.
  That selected profile is valid only with `input_mode = four_table`;
  CamtrapDP configurations must use the explicit null selection. Explicit
  null requires zero entity sidecars and no dedicated snapshot path. Selection
  requires exactly one matching non-parser inventory record whose configured,
  inventoried, snapshotted, and reconstructed SHA-256 values agree. Inline
  mappings, wildcard authority, unapproved digests, extra fields, and unused
  sidecars are rejected. The selected sidecar changes source identity but
  never becomes a fifth analytical table.

- `deployment_evidence`
  Provisional internal deployment/service audit selection, separate from
  `entity_resolution` and not a public v0.1 input field. The block contains
  exactly `profile_id`, `service_sidecar_path`, `service_sidecar_sha256`,
  `deployment_ledger_path`, `deployment_ledger_sha256`, and
  `authority_reference`. All six values must be explicit `null`, or they must
  bind the exact approved Judbury profile
  `judbury-deployment-evidence/1.0.0-proposed`. The approved service and
  ledger SHA-256 values are
  `f33eeac9d70126966717c8e3f4731c00a97cbc3a34c2f44ce5c70d91c7d5283a`
  and
  `0921eb8845c2bb1ad5760271f283ab2783735b7739e254c67e9243bc906f3ebf`.
  Selection is valid only for `input_mode = four_table` with the exact
  selected Goal 007 crosswalk. The supported runner requires either this
  complete selection or the explicit null block. Selected files are
  snapshotted and inventoried separately as non-parser
  `deployment_service_input` and `deployment_ledger_input` evidence. They do
  not become analytical tables and cannot route observations, effort, events,
  denominators, or modules. `config.yml` and
  `config.camtrapdp_export.yml` select this audit profile; generic and
  CamtrapDP-ingestion examples use explicit nulls.

- `analysis_unit`
  Provisional internal selection for the one Goal 009 ecological branch; it
  is not a public v0.1 field or a general migration API. A present block must
  contain exactly `resolution`, `mapping_profile_id`, `mapping_path`,
  `mapping_sha256`, and `authority_reference`. Supported resolutions are
  `analysis_site`, `physical_location`, and `nominal_station`. The four
  mapping fields must be either all selected or all explicit nulls.

  The approved mapped selection is
  `judbury-analysis-site/1.0.0-proposed`, fixed to
  `docs/goals/009-analysis-site-vertical-slice/judbury_analysis_site_mapping.csv`
  at SHA-256
  `6490d7f7021e5c727b9be1c7d6dfbf44ba50a1ef5b0396c66e1dd813a9c77083`.
  Its 13 physical-location memberships, nine analysis sites, and four fixed
  synthetic midpoint coordinates are immutable evidence for this profile.
  Midpoints are for mapping and separation only; physical covariates are not
  pooled. A null-mapping `analysis_site` or `physical_location` selection uses
  the built-in physical-location identity. A null-mapping `nominal_station`
  selection requires authoritative runtime membership and is ineligible when
  that authority is unavailable. Grouping is never inferred from suffixes,
  proximity, or nominal station labels.

  Every explicit mode publishes preview schema 1.2 and completed manifest
  schema 1.3, with a status record even when the ecological route is
  ineligible. A genuinely omitted `analysis_unit` block retains the legacy
  preview/manifest path and creates no selected status or tables. A YAML null
  block is invalid. Public profile registration, precedence, and migration of
  older configurations remain deferred.

- `analysis.rarefaction`  
  Toggle rarefaction/species accumulation outputs (TRUE/FALSE).

- `analysis.report`  
  Toggle report rendering (TRUE/FALSE). Requires `analysis.rarefaction = TRUE`.

- `spatial_map.enable`  
  Toggle the spatial site map (TRUE/FALSE). Requires `site` table lat/lon.

- `spatial_map.surface_var`  
  Preferred site covariate to interpolate for the background surface (e.g., `ndvi`, `elevation_m`). Falls back to the first available non-missing variable if absent.

- `spatial_map.resolution`  
  Grid resolution (number of steps per axis) used for interpolation.

- `spatial_map.buffer_deg`  
  Minimum buffer in decimal degrees around the site extent.

- `spatial_map.buffer_frac`  
  Buffer as a fraction of the site extent (used to build a square bounding box around sites).

- `spatial_map.label_sites`  
  Toggle site name labels adjacent to points.

- `spatial_map.label_size`  
  Text size for site labels, north arrow, and scale bar.

- `spatial_map.label_nudge_frac`  
  Fraction of the map range used to offset labels from points.

- `spatial_map.show_north_arrow`  
  Toggle the north arrow annotation.

- `spatial_map.show_scale_bar`  
  Toggle the scale bar annotation.

- `spatial_map.scale_bar_km`  
  Scale bar length in kilometers.

- `time_qc.backward_jump_threshold_hours`  
  Threshold (hours) for flagging backward time jumps as potential clock drift.

- `diel.method`  
  Diel classification method: `flash` (default) uses `flash == 1` as night; `clock` uses event time and fixed day/night hours.

- `diel.day_start_hour` / `diel.day_end_hour`  
  Daytime window for `clock` method (hours, 0–23). Events outside this window are classified as night.

- `sensitivity.event_threshold_minutes`  
  Vector of event-threshold values (minutes) to use in sensitivity outputs.

- `sensitivity.occasion_length_days`  
  Vector of occasion lengths (days) to use in sensitivity outputs.

- `detection_history.occasion_length_days`  
  Length of each detection-history occasion in days.

- `detection_history.start_date`  
  Optional start date for occasions (ISO `YYYY-MM-DD`); defaults to the first effort date.

- `occupancy.species`  
  Optional character vector of species short codes for occupancy modeling. If `null`, the top `occupancy.top_n` species by event count are used.

- `occupancy.top_n`  
  Number of top species (by events) to model when `occupancy.species` is null.

- `occupancy.covariates`  
  Vector of site covariate names to include in occupancy candidate models. Covariates with all-NA values or zero variance are dropped automatically (models fall back to base/effort-only if none remain).

## Camtrap DP export

- `camtrapdp_export.enable`  
  Set `true` to export the internal tables to a Camtrap Data Package under `outputs/runs/<run_id>/camtrapdp_export/`.

- `camtrapdp_export.name`  
  Data Package name (machine-friendly identifier).

- `camtrapdp_export.title`  
  Human-readable title for the export.

- `camtrapdp_export.description`  
  Description of the export (shown in `datapackage.json`).

- `camtrapdp_export.version`  
  Camtrap DP version string (default `1.0.1`).

- `camtrapdp_export.license`  
  License name for the exported data (default `CC-BY-4.0`).

- `camtrapdp_export.id`  
  Optional UUID for the export; if `null`, one is generated.

- `camtrapdp_export.created`  
  Optional ISO timestamp; if `null`, the export time is used.
- `traits.species_column`  
  Column in the taxa table that identifies the species short code used by observations.

- `traits.columns`  
  Vector of trait columns to clean and retain for community/functional analyses.

- `traits.association_traits`  
  Subset of trait columns used for trait–environment associations.

- `traits.environment_vars`  
  Vector of site-level environmental covariates used in trait–environment associations.

## Notes

- Changes to `config.yml` invalidate downstream targets.
- The publisher snapshots the YAML once at
  `provenance/config.raw.yml`. Fingerprinting and the target graph both consume
  that immutable copy, while `provenance/effective_config.json` records its
  resolved meaning. YAML formatting and key order can change the raw hash
  without changing the resolved hash.
- When outputs are disabled via toggles, a placeholder file is written to keep the pipeline consistent.
