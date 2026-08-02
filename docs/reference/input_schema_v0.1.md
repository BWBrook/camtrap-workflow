# Four-Table Input Contract 0.1

Schema version is `0.1.0` in `schema_version.txt`. Validation is strict for the
required identity and analytical fields. Additional source columns are allowed
and remain in the immutable source snapshot.

## Site

Required columns:

| Column | Type | Meaning |
| --- | --- | --- |
| `site` | character | Unique physical-location identifier; non-missing. |
| `lat`, `lon` | double | Supplied physical coordinates. |
| `type`, `location`, `cover`, `vegclass` | character | Source location metadata. |
| `elevation_m`, `slope_d`, `canopy_h_m`, `ndvi`, `nbr` | double | Supplied physical-location covariates. |
| `fire_flam`, `fire_sens` | character | Supplied fire metadata. |

These values remain attached to their physical locations. Grouping never
pools them or treats representative group coordinates as measurements.

## Taxa

Required character columns are `class`, `order`, `family`, `genus`, `species`,
`common`, and `short`. `short` is non-missing and is the exact key referenced by
`obs.species`.

Other source taxonomic or ecological columns are accepted but are not required
by the retained summaries.

## Operation

`date` uses `DD/MM/YYYY`. Every other column is a physical-location identifier
that exactly matches `site.site`. Values are `0` or `1`, with no missing values:

- `1`: confirmed active on that date;
- `0`: confirmed inactive on that date.

Unknown operation may be represented in separate audited evidence; it is never
silently converted to active effort.

## Observations

Required columns:

| Column | Type | Meaning |
| --- | --- | --- |
| `index` | integer | Source record index. |
| `site` | character | Exact physical-location key. |
| `datetime` | datetime | `DD/MM/YYYY HH:MM:SS` camera time. |
| `flash` | integer | Zero or one. |
| `count` | integer | Recorded individual count. |
| `species` | character | Exact `taxa.short` key. |
| `filename` | character | Source media filename. |
| `age`, `sex` | character | Source observation metadata. |
| `imageid` | integer | Source image identifier. |

Datetimes are interpreted under the configured timezone or explicit fixed
offset. Unparseable values fail validation.

## Identity And Lineage

The public tables do not need internal provenance fields. In the bundle,
`resource_id` identifies exact resource content and `source_row_id` identifies
the parser resource plus one-based parsed row. Every observation row is linked
to an operational event or an explicit exclusion reason.

Camera/deployment identity, physical-location identity, nominal survey
metadata, and purpose-specific analysis sites are distinct. The software does
not derive one from another without explicit source evidence.

CamtrapDP input is converted to this internal meaning before the same
validation gates. See `docs/reference/camtrapdp_input.md`.
