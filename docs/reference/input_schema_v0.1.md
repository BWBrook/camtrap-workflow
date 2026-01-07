# Input schema v0.1 (four-table contract)

This document defines the **required** input contract for the MVP workflow.
Tables must match the required columns and types below. Validation is strict and fails fast.

Schema version: **0.1.0** (see `schema_version.txt`).

## 1) `jc_site.csv` — site metadata

Required columns:
- `site` (chr) — unique site identifier
- `lat` (dbl)
- `lon` (dbl)
- `type` (chr)
- `location` (chr)
- `cover` (chr)
- `vegclass` (chr)
- `elevation_m` (dbl)
- `slope_d` (dbl)
- `canopy_h_m` (dbl)
- `ndvi` (dbl)
- `nbr` (dbl)
- `fire_flam` (chr)
- `fire_sens` (chr)

Rules:
- `site` must be non-missing.

## 2) `jc_taxa.csv` — taxa/traits

Required columns:
- `class` (chr)
- `order` (chr)
- `family` (chr)
- `genus` (chr)
- `species` (chr)
- `common` (chr)
- `short` (chr)
- `diet` (chr)
- `sec_diet` (chr)
- `activity` (chr)
- `habitat` (chr)
- `status` (chr)
- `body_size` (chr)
- `sociality` (chr)
- `mobility` (chr)
- `reproductive` (chr)
- `litter` (chr)

Rules:
- `short` must be non-missing and is the lookup key for `obs$species`.

## 3) `jc_op.csv` — effort matrix

Required columns:
- `date` (date; format `DD/MM/YYYY`)
- one column per site (must match `jc_site.csv$site`)

Rules:
- All effort columns must be **0/1 only**, with no `NA`.
- Effort column names must match the site identifiers in `jc_site.csv`.

## 4) `jc_obs.csv` — detection records

Required columns:
- `index` (int)
- `site` (chr)
- `datetime` (dttm; format `DD/MM/YYYY hh:mm:ss`)
- `flash` (int, must be 0/1)
- `count` (int)
- `species` (chr)
- `filename` (chr)
- `age` (chr)
- `sex` (chr)
- `imageid` (int)

Rules:
- `site` must exist in `jc_site.csv$site`.
- `species` must exist in `jc_taxa.csv$short`.
- `datetime` must be parseable (timezone handled downstream via `config.yml`).
- `flash` must be 0/1.

Notes:
- `datetime` values are interpreted in the configured timezone and may be flagged if they fall in DST gaps.
- Unparseable datetimes fail validation immediately.
- Camtrap DP ingestion uses a mapping adapter before validation (see `docs/reference/camtrapdp_mapping_v0.1.md`).

## Validation failures

Validation fails early with explicit table/column messages and suggested fixes.
See `R/qc_schema.R` for implementation details.
