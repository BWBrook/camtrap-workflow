# v1.0 readiness gate

## Evidence summary

- **Environment**: `renv.lock` updated; cold run completed on 2026‑01‑07.
- **Quality gates**: lint and tests pass locally; CI enabled with system deps.
- **Pipeline**: full `tar_make()` runs end‑to‑end on the exemplar.
- **Artefacts**: reports (HTML+PDF), methods skeleton, and key figures/tables are produced.
- **Interoperability**: Camtrap DP ingestion and export both validated with example runs.

## Outstanding items

- Fresh clone restore has not been verified on a separate clean machine.
- `docs/questions_for_human.md` contains unresolved questions.
- Release tag and bundle still need creation once PI signs off.
