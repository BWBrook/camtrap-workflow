# 2026-01-07 — Functional diversity tempdir fix

## Summary

- Prevented `FD::dbFD()` from writing `vert.txt` into the repo root by running the call in `tempdir()`.

## Sanity checks

- Re-ran functional diversity computation; `vert.txt` no longer appears in the repo.
