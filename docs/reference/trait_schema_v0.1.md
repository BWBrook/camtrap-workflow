# Trait schema v0.1

The workflow derives traits from the taxa table (default: `data/jc_taxa.csv`), using the
species short code (`short`) to align traits with observations and community matrices.

## Required columns

- `short` — species short code (matches `obs.species`).

## Trait columns (default)

Configured in `config.yml` under `traits.columns`. For the exemplar dataset:

- `diet`
- `sec_diet`
- `activity`
- `habitat`
- `status`
- `body_size`
- `sociality`
- `mobility`

## Cleaning rules

- Trait values are trimmed and converted to lowercase.
- Placeholder values (`na`, `n/a`, `unknown`, `none`, empty) are converted to `NA`.
- Duplicate `short` codes are not allowed.

## Alignment rules

- Traits are aligned to species present in the community matrix.
- Species without trait records are reported in `tables/traits_missing.csv`.

## Outputs

See `docs/reference/output_schema_v0.1.md` for the derived trait outputs.
