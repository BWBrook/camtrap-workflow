# Camtrap DP mapping v0.1

This document records how Camtrap Data Package (DP) inputs are mapped to the internal four‑table contract.

## Source

Camtrap DP `datapackage.json` read via `camtrapdp::read_camtrapdp()`.

## Mapping overview

| Internal table | Camtrap DP source | Mapping notes |
| --- | --- | --- |
| `site` | `deployments` | `site` = `deploymentID`; `lat/long` from `latitude/longitude`; `type` from `featureType`; `location` from `locationName`; remaining fields set to `NA`. |
| `op` | `deployments` | Daily effort from `deploymentStart` → `deploymentEnd` per `deploymentID`. |
| `obs` | `observations` (+ `media`) | `site` = `deploymentID`; `datetime` = `eventStart` (fallback `media.timestamp`); `species` derived from `scientificName`; `count` from `count` (default 1). |
| `taxa` | `observations` | Distinct `scientificName` rows; `short` is a slug of scientificName; `genus/species` parsed from scientificName; trait columns set to `NA`. |

## Key assumptions

- Each `deploymentID` is treated as a unique site.
- Observations are not filtered by `observationLevel` in the adapter; event‑level duplication should be handled by event clustering.
- Trait fields are not available in Camtrap DP examples and are left `NA` (user may extend mapping).
- Environmental covariates used in occupancy models (`canopy_h_m`, `ndvi`, etc.) are not present in Camtrap DP 1.0.1 and remain `NA`; occupancy automatically drops covariates with all-NA or zero variance, falling back to base/effort-only models.

## Outputs

Mapped tables are validated against the existing input schema (`input_schema_v0.1`) before entering the pipeline.

---

## Export mapping (internal → Camtrap DP)

| Camtrap DP table | Internal source | Mapping notes |
| --- | --- | --- |
| `deployments` | `site` + `op` | `deploymentID` = `site`; `deploymentStart/End` from min/max effort dates; `latitude/longitude` from site; other fields set to `NA`. |
| `media` | `obs` | One media row per observation; `mediaID` from `imageid`/`index`; `timestamp` from `obs$datetime`; `filePath` set to `media/<filename>`. |
| `observations` | `obs` + `taxa` | `observationID` from `index`; `deploymentID` from `site`; `eventStart/End` from `obs$datetime`; `scientificName` from taxa (genus+species or short). |

Notes:
- Export requires valid `lat/lon` and non‑empty effort for each site.
- Observations are exported at `observationLevel = "media"` with `observationType = "animal"` by default.
