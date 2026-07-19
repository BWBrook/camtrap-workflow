# Candidate LocalMap_Tas boundary

## Status

This is an implementation-neutral candidate interchange, not a final public schema or API. Goal 002 makes no changes to either repository.

**Observed LocalMap state.** The authorized checkout was clean at `297a2b09af9f6ce83054d9d522d922ea6ecefa10`, on `main...origin/main [ahead 18]`. The inherited ahead state was not reconciled.

**Observed product boundary.** LocalMap_Tas is a settings-first R package and `targets` workflow that converts site coordinates, an AOI, and spatial-layer choices into maps, site-attribute tables, caches, attribution, and provenance (LocalMap_Tas `README.md:3`; `docs/product_brief.md:5`). Its installed public route is `localmap::run_settings()` and its checkout wrapper calls the same route (LocalMap_Tas `README.md:40`; `R/settings_runner.R:283`; `scripts/run_project.R:16`).

**Recommendation.** LocalMap_Tas should remain an independently runnable, independently versioned upstream GIS/covariate provider. Camtrap Workflow should consume versioned files and a provenance manifest, never LocalMap code or internal targets.

## Observed LocalMap surfaces

### Inputs and invocation

- The real-data settings route requires `site.csv` with `site`, `lat`, and `lon`; `obs.csv` and `op.csv` are optional (LocalMap_Tas `docs/settings.md:26`).
- Settings resolve a base profile, rewrite output paths, write a resolved `run_config.yaml`, and invoke the standard pipeline (LocalMap_Tas `docs/settings.md:64`; `R/settings_runner.R:283`).
- Network and large-download access are explicit constraints; offline fixtures and placeholders must remain distinguishable from live data (LocalMap_Tas `docs/product_brief.md:66`).

### Spatial products

- LocalMap owns AOI definition, source acquisition/cache, CRS operations, raster/vector processing, maps, site extraction, and source attribution (LocalMap_Tas `docs/architecture.md:7`).
- The current canonical long site-attribute table contains `site_id`, `layer_id`, `layer_type`, `attribute_name`, `value`, `units`, `source_id`, and `provenance_path` (LocalMap_Tas `R/site_attributes.R:71`; `R/site_attributes.R:510`).
- A wide CSV is a convenience representation; the long table is the primary audit surface (LocalMap_Tas `docs/output_schema_v1.md:106`).

### Provenance

- The LocalMap run manifest records active profile and timestamp, configuration path/schema/hash, output-schema path/version/hash, source parameters, output paths, provenance paths, cache paths, and attribution (LocalMap_Tas `R/provenance_outputs.R:107`).
- Layer sidecars distinguish placeholders, offline fixtures, cache hits, and other acquisition state. Placeholder pixels must not support ecological interpretation or extraction (LocalMap_Tas `docs/output_schema_v1.md:106`).
- LocalMap can query ALA by year, spatial boundary, latitude, state, and selected fields (LocalMap_Tas `R/ala_fetch_occurrences.R:1`). That capability is regional context only; it is not a Camtrap gamma-diversity estimator.

## Ownership allocation

| Responsibility | LocalMap_Tas owns | Camtrap Workflow owns |
| --- | --- | --- |
| Location input | Validate coordinate form needed for GIS; hash the received location file | Create and preserve immutable `location_id`; decide which locations enter a run |
| Deployment and relocation | None | Deployment intervals, camera moves/swaps, location links, operational evidence and uncertainty |
| Analysis-site grouping | May map supplied group identifiers but does not invent them | Define named spatial resolution and location-to-analysis-site mapping |
| AOI and CRS | AOI, projection, extraction CRS and transformation evidence | Declare ecological analysis extent/resolution required by each module |
| Layer acquisition | URLs/services/files, cache, licences, credits, version/vintage and acquisition state | Decide whether a supplied covariate is eligible for a requested analysis |
| Spatial processing | Crop/mask/resample/extract/derive; record method and source resolution | Any post-handoff analytical normalization; record it in the run repair/transform ledger |
| Covariate values | Value, unit, missingness/quality, layer identity and provenance | Join by immutable location; select named spatial resolution; never silently impute |
| Maps | GIS/context maps and their sidecars | Select eligible maps for reports and retain LocalMap provenance |
| ALA context | Taxon resolution/query, occurrence export, extent/window and query provenance | Taxonomic reconciliation to the study, bias caveats, analytical use and claim limits |
| Ecological analysis | None | Effort, event derivation, richness, turnover, selected-species modules and inference |
| Claims | Source/processing facts only | Scientific interpretation and report claims |

## Candidate file interchange

The smallest useful handoff is:

```text
localmap_handoff/
  locations_received.csv
  site_covariates_long.parquet (or CSV profile)
  maps/
  provenance/
    localmap_manifest.yml
    sources.csv
    attribution.md
```

`locations_received.csv` is a round-trip acknowledgement of the location identity and coordinates LocalMap processed. It is not a deployment or analysis-site table.

### Candidate covariate fields

These fields are recommendations for later schema design, not committed names:

- `interchange_schema_version`
- `location_id`
- `covariate_id`
- `value_numeric` and/or `value_text`
- `units`
- `layer_id`, `layer_type`, `source_id`
- `extraction_method`, `extraction_crs`
- `source_resolution`, `source_vintage`
- `quality_status`, `missingness_reason`
- `provenance_id`

The current LocalMap long-table fields map naturally to much of this surface, but numeric/text typing, quality status, source resolution/vintage, and stable external location identity need explicit comparison and implementation validation (LocalMap_Tas `R/site_attributes.R:71`).

### Candidate manifest additions

- immutable `localmap_run_id`;
- LocalMap release/version and Git commit where available;
- settings/config and output-schema versions plus hashes;
- input-location-file identity and content hash;
- acquisition timestamp and state (`live`, `cache_hit`, `offline_fixture`, `placeholder`, or failure);
- source URL/service/layer version, licence and credit;
- output paths plus content hashes;
- processing method, CRS, resolution/resampling and derivation chain;
- warnings, missingness, fallback and quality state.

## Camtrap ingestion behavior

**Recommendation.** Camtrap should validate the handoff without invoking LocalMap:

1. Verify manifest/schema compatibility and file hashes.
2. Require every covariate row to map to a known immutable `location_id`.
3. Reject duplicate primary keys within the declared extraction resolution.
4. Preserve source units and quality/missingness state.
5. Block placeholder pixels and unknown provenance from inferential modules.
6. Record the LocalMap run identity in Camtrap's immutable run manifest.
7. Apply Camtrap analytical transforms only through its own previewable repair/transform ledger.
8. Let module capability checks decide whether covariate coverage and resolution are adequate.

## Non-goals

- No repository merger, submodule, package dependency, shared target DAG, or shared cache.
- No Camtrap import of LocalMap R functions or internal configuration profiles.
- No `obs`, `op`, event, RAI, occupancy, or claim fields in the LocalMap covariate interchange.
- No implicit equivalence among `site_id`, `deploymentID`, `location_id`, or a named analysis site.
- No LocalMap inference of relocations, effort, camera failure, ecological grouping, zero detection, or missing operation.
- No Tasmania-specific column names or LIST-layer IDs in Camtrap's canonical core model.
- No duplication in Camtrap of GIS acquisition, raster/vector processing, spatial cache, or map-provenance responsibility.
- No use of placeholder pixels or layout-only imagery for extraction or ecological inference.
- No interpretation of ALA counts as absence-adjusted richness, camera-grid gamma diversity, or comparable effort.
- No final public interchange schema/API commitment during Goal 002.

## Deferred decisions and validation

Goal 003 or a later implementation spike must decide file format profiles, public field names, identifiers, schema versioning, categorical-value representation, geometry delivery, accepted CRS/resolution semantics, and manifest compatibility rules.

Before adoption, a synthetic round trip should prove:

- identical immutable location identities on both sides;
- explicit behavior for missing values, duplicate values, stale sources and placeholders;
- traceability from a Camtrap result to LocalMap source/provenance;
- no network call by Camtrap;
- no source-code or cache dependency between repositories;
- independent rerun/versioning of each repository.

Stop and escalate if a proposed integration needs LocalMap internals, redefines sampling design, hides a Tasmania-specific assumption, or requires consequential scientific interpretation of a covariate or ALA context.
