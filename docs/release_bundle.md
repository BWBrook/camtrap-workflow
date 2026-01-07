# Release bundle definition

A release bundle is a ZIP (or equivalent archive) intended for external review and archival. It should include:

## Required contents

- `CHANGELOG.md`
- `CITATION.cff`
- `VERSION`
- `renv.lock`
- `README.md`
- `docs/decisions.md`
- `docs/interpretation_notes.md`
- `docs/log/` entries covering the release WPs
- Canonical run artefacts under `outputs/runs/<run_id>/`:
  - `report/` (HTML + PDF)
  - key plots under `figures/`
  - key tables under `tables/`
  - `session_info.txt` and `run_manifest.json`
- Optional exports (if enabled): `outputs/runs/<run_id>/camtrapdp_export/`

## Exclusions (non‑reviewable)

- `renv/`
- `.git/`
- `.github/`
- `.vscode/`
- `_targets/`

## Notes

- Bundle size should remain reviewable; avoid including raw media.
- If multiple runs are included, document which run is the primary reference.
