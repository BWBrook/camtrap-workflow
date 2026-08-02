# Bring Your Own Data

## Start From The Template

Use `data/template_dataset/` and `config.template_example.yml` as the smallest
working four-table example. Keep source files outside `outputs/`, which is
reserved for captured and derived run artefacts.

The required tables are:

- `site.csv`: physical-location identity, latitude, longitude, and the current
  site metadata contract;
- `op.csv`: one date column plus one zero/one operation column per physical
  location;
- `obs.csv`: labelled detections with physical location, camera time, species
  code, and record metadata; and
- `taxa.csv`: taxonomic identity and the `short` species code used by
  observations.

See `docs/reference/input_schema_v0.1.md` for exact columns and types.

## Configure A Physical-Location Run

Copy `config.template_example.yml`, update the four input paths and timezone,
and keep the spatial selection at its generic default:

```yaml
analysis_unit:
  resolution: physical_location
  mapping_profile_id: null
  mapping_path: null
  mapping_sha256: null
  authority_reference: null
```

Do not encode camera moves as new analytical groupings unless the physical
locations truly differ. Conversely, do not merge physical locations into a
nominal survey station. Purpose-specific `analysis_site` grouping requires a
reviewed, exact authority and is not inferred by the software.

## Validate Before Analysis

```sh
Rscript scripts/run_full_evidence_run.R \
  --validate-only --config config.my_dataset.yml
```

Inspect the preview findings. A normalization is applied only when the config
records its exact proposal ID, proposal digest, decision, and optional reason.
Integrity findings cannot be waived.

Then publish:

```sh
Rscript scripts/run_full_evidence_run.R --config config.my_dataset.yml
```

## CamtrapDP Input

Use `config.camtrapdp_example.yml` as the current adapter example. Local
descriptors must reference local resources. Remote descriptors and every
remote resource require pinned SHA-256 evidence. Deployment identity and
physical-location identity remain separate throughout event construction.

The adapter still applies the same validation, event, spatial, module-status,
and publication contracts as four-table input.

## Interpret The Result

Open `report/report.html` in the latest completed bundle. Check
`results/module_status.json` before interpreting a missing table or figure: the
record distinguishes an ecological omission from a technical failure.

Treat supplied physical covariates as attributes of those physical locations.
The point map does not estimate values between cameras, and grouped
representative positions do not create new environmental observations.
