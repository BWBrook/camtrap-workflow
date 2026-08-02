# Configuration Contract

Goal 011 supports one strict YAML contract. Unknown fields are rejected. A
maintained example may omit fields and use the defaults in `R/config.R`, but a
resolved configuration always contains exactly the sections below.

## Core Fields

- `schema_version_path`: local schema-version text file.
- `timezone`: IANA timezone for camera-clock interpretation.
- `timezone_fixed_offset_hours`: optional fixed UTC offset when daylight-saving
  transitions must be ignored; otherwise `null`.
- `event_threshold_minutes`: non-negative gap used to form operational events.
- `input_mode`: `four_table` or `camtrapdp`.

## Validation Decisions

`validation.repair_decisions` is a list. Each entry contains an exact
`proposal_id`, `proposal_digest`, `decision` (`approved` or `declined`), and an
optional `reason`. There is no broad approval switch. An absent decision never
authorizes a change.

## Evidence Selections

`entity_resolution` contains exactly:

- `profile_id`;
- `sidecar_path`;
- `sidecar_sha256`; and
- `authority_reference`.

All four values are `null` for generic input. This build accepts only the exact
shipped Judbury authority when the values are populated.

`deployment_evidence` contains exactly:

- `profile_id`;
- `service_sidecar_path` and `service_sidecar_sha256`;
- `deployment_ledger_path` and `deployment_ledger_sha256`; and
- `authority_reference`.

All six values are `null` for generic input. Deployment evidence requires the
matching selected entity authority and applies only to four-table input.

## Analytical Resolution

`analysis_unit` contains exactly:

- `resolution`;
- `mapping_profile_id`;
- `mapping_path`;
- `mapping_sha256`; and
- `authority_reference`.

For the generic route:

```yaml
analysis_unit:
  resolution: physical_location
  mapping_profile_id: null
  mapping_path: null
  mapping_sha256: null
  authority_reference: null
```

`analysis_site` requires a complete exact approved mapping selection. This
release accepts the shipped Judbury mapping only. No names, coordinates,
distances, dates, or operation patterns are used to infer membership.

## Acquisition And Paths

`camtrapdp_acquisition` contains:

- `mode`: `local` or `remote`;
- `cache_dir`: local content cache;
- `descriptor_sha256`: required for remote acquisition; and
- `resource_sha256`: named SHA-256 map for remote resources.

`paths.outputs` selects the output root. `paths.inputs` always contains exactly
`site`, `op`, `obs`, `taxa`, and `camtrapdp`. Four-table mode supplies the first
four and sets `camtrapdp: null`; CamtrapDP mode does the reverse.

## Retained Module Settings

```yaml
map:
  label_locations: true

diel:
  method: flash
  day_start_hour: 6
  day_end_hour: 18

sensitivity:
  event_threshold_minutes: [5, 15, 30, 60]
```

`diel.method` is `flash` or `clock`. Clock hours must be ordered integers or
numbers from 0 to 23. Sensitivity thresholds are non-negative.

Ecological modules are candidates governed by their evidence, not feature
toggles. Each module writes a status explaining whether it completed, warned,
was omitted, or failed.
