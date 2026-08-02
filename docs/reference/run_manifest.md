# Run Bundle 2.0

`run_manifest.json` supports exactly `camtrap-run-bundle/2.0`.

## Fields

- `run_id`, `status`, and `created_utc` identify one completed invocation.
- `spatial_resolution` is `physical_location` or `analysis_site`.
- `fingerprints` contains source, raw/resolved config, engine, and composite
  SHA-256 identities.
- `engine` records included engine files and installed package versions.
- `config` links the captured YAML and resolved configuration.
- `source_inventory` links the immutable captured-source inventory.
- `audit` links validation, entity, selected-resolution, and event evidence.
- `module_status` links the complete candidate-module status set.
- `outputs` names the produced ecological tables and figures.
- `report` and `session_info` link the user report and runtime record.
- `payload` inventories every regular payload file with bytes and SHA-256.

Payload inventory excludes the manifest itself and the publication markers.

## Publication Markers

`READY` records successful internal verification in staging. Publication then
atomically renames the staged directory to `outputs/runs/<run_id>/`.

`COMPLETE.json` uses `camtrap-run-completion/2.0` and binds the published run ID
to the manifest SHA-256. `outputs/latest` is a regular text file containing
exactly one completed run ID. It is updated only after the published bundle has
passed verification.

Existing completed run directories are immutable and never overwritten.

## Verification

```sh
Rscript scripts/verify_published_bundle.R outputs/runs/<run_id>
```

The independent verifier checks emitted bytes and scientific consequences; it
does not rerun the target graph. Standard Judbury release verification must
also supply `tests/fixtures/goal011/judbury_selected_jaccard_oracle.csv`.

Pre-Goal 011 formats are historical evidence. The current reader does not
dispatch on old schemas.
