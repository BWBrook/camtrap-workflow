# 2026-01-07 — CI disabled pending GLPK dependency fix

## Summary

- Disabled GitHub Actions on push/PR due to `igraph` failing to load without `libglpk.so.40`.
- CI can be run manually via `workflow_dispatch` until dependency strategy is implemented.

## Error observed

- `libglpk.so.40: cannot open shared object file: No such file or directory` during `renv::restore()`.

## Follow-up

- Re-enable push/PR CI after adding system dependency installation (e.g., GLPK) or switching to binaries.
