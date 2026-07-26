# Camtrap DP mapping v0.1

This document records how Camtrap Data Package (DP) inputs are mapped to the
internal four-table contract.

## Source

Camtrap DP `datapackage.json` read via `camtrapdp::read_camtrapdp()`.

## Mapping overview

| Internal table | Camtrap DP source | Mapping notes |
| --- | --- | --- |
| `site` | `deployments` | `site` = `deploymentID`; `lat/long` from `latitude/longitude`; `type` from `featureType`; `location` from `locationName`; remaining fields set to `NA`. |
| `op` | `deployments` | Daily effort expands each explicit closed interval from `deploymentStart` through `deploymentEnd` per `deploymentID`. Both endpoints are required for analysis. |
| `obs` | `observations` (+ `media`) | One output row per observation source ordinal; `site` = `deploymentID`; `datetime` = `eventStart`; `species` is a deterministic slug of `scientificName`; `count` and `flash` retain supplied values; `filename` is joined by exact `mediaID`. |
| `taxa` | `observations` | Distinct `scientificName` rows; `short` is a slug of scientificName; `genus/species` parsed from scientificName; trait columns set to `NA`. |

## Key assumptions

- Each `deploymentID` is treated as a unique site.
- Deployment, observation, and media identifiers must be non-missing and
  unique. Observation references to deployments and media must resolve
  exactly.
- Observations are not filtered by `observationLevel`; the operational
  detection event rule groups retained observation rows downstream.
- Adapter joins must preserve observation row count. Ambiguous keys, taxon
  code collisions, lossy mappings, and silent row deletion are integrity
  failures.
- Trait fields are not available in Camtrap DP examples and are left `NA` (user may extend mapping).
- Environmental covariates used in occupancy models (`canopy_h_m`, `ndvi`, etc.) are not present in Camtrap DP 1.0.1 and remain `NA`; occupancy automatically drops covariates with all-NA or zero variance, falling back to base/effort-only models.

## Missing values and repair authority

Missing source values remain missing. The adapter does not:

- copy a supplied deployment endpoint into a missing endpoint;
- copy `media.timestamp` into a missing `eventStart`;
- replace missing `count` with `1`;
- replace missing `flash` with `0`; or
- create an `unknown` taxon for missing `scientificName`.

For audit visibility, these historical behaviours are classified as
non-applicable production `fill_unknown` proposals. Goal 006 provides no
production algorithm or authority to apply them. Any proposal that fills an
unknown value requires exact proposal-specific approval; any proposal that
replaces explicit supplied evidence is `override_explicit` and also requires a
non-empty recorded reason. A missing value that leaves the internal contract
invalid blocks analysis.

Strictly meaning-preserving field mappings and explicit interval expansion are
recorded as transformations. Source rows, transformations, proposals,
decisions, applications, changed fields, and operational event membership are
kept as separate provenance records.

## Entity evidence

Before adaptation discards source fields, the Goal 007 resolver retains exact
supplied `locationID`, `deploymentID`, `deploymentStart`, and `deploymentEnd`
as audit evidence. Opaque identifiers are accepted without parsing. A
deployment becomes routing-ready evidence only when its ID, one explicit
location link, and both ordered endpoints are supplied uniquely. Missing
optional location or interval evidence remains unresolved; duplicates,
competing evidence, reversed intervals, and orphan observation references
stop analysis. Every source row participating in duplicate or competing
deployment evidence remains separately attributable in deployment lineage;
the resolver does not collapse to the first row or fabricate a resolved link.
CamtrapDP does not supply or imply a nominal grid station or `analysis_site`.

## Outputs

Mapped tables are validated against the existing input schema
(`input_schema_v0.1`) before entering the analytical target graph. The public
four-table schema is unchanged; parser resource and source-row identities are
stored in Phase 2 sidecars.

---

## Export mapping (internal → Camtrap DP)

| Camtrap DP table | Internal source | Mapping notes |
| --- | --- | --- |
| `deployments` | `site` + `op` | `deploymentID` = `site`; `deploymentStart/End` from min/max effort dates; `latitude/longitude` from site; other fields set to `NA`. |
| `media` | `obs` | One media row per observation; `mediaID` from `imageid`/`index`; `timestamp` from `obs$datetime`; `filePath` set to `media/<filename>`. |
| `observations` | `obs` + `taxa` | `observationID` from `index`; `deploymentID` from `site`; `eventStart/End` from `obs$datetime`; `scientificName` from taxa (genus+species or short). |

Notes:
- Export requires valid `lat/lon` and non-empty effort for each site.
- Observations are exported at `observationLevel = "media"` with `observationType = "animal"` by default.
- Observations with unparseable local datetimes (e.g., DST gaps) are dropped and recorded in `camtrapdp_export/dropped_observations.csv` with a count reported in `validation.txt`.
