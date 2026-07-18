# Reproducibility benchmark

This document defines the cold‑run protocol and records runtime/memory notes for the exemplar dataset.

## Cold‑run protocol

1) Start from a clean repo checkout.
2) Restore dependencies:
   ```r
   renv::restore(prompt = FALSE)
   ```
3) Remove any existing targets cache:
   ```r
   targets::tar_destroy()
   ```
4) Run the full pipeline (no callr isolation):
   ```r
   targets::tar_make(callr_function = NULL)
   ```
5) Record elapsed time and environment details (OS, R version, cores).

## Runtime notes (exemplar)

- Date: 2026-01-07
- Command: `targets::tar_destroy()` + `targets::tar_make(callr_function = NULL)`
- Elapsed time: **64.3 seconds** (elapsed; user+system 147.8s)
- Platform: Ubuntu (GitHub Codespace / local)
- R: 4.5.2

- Date: 2026-01-08
- Command: `renv::restore(prompt = FALSE)` + `targets::tar_destroy()` + `targets::tar_make(callr_function = NULL)`
- Elapsed time: **91.2 seconds** (elapsed; user+system 204.8s; max RSS 826612 KB)
- Platform: Linux 6.8.0-90-generic (clean clone on local host)
- R: 4.5.2 (2025-10-31); cores: 64
- Notes: `renv::restore()` initially failed due to a stale `00LOCK-renv` and succeeded after removal; restore warns that `libnode-dev` is missing (V8 builds may need it), but all packages linked from cache.

- Date: 2026-05-29
- Command: `targets::tar_destroy()` + `targets::tar_make(callr_function = NULL)` via `Rscript`
- Elapsed time: **60.0 seconds** (elapsed; max RSS 962854912 bytes)
- Platform: macOS 26.5 on Apple Silicon Mac mini
- R: 4.6.0 (2026-04-24)
- Notes: `renv.lock` refreshed to the R 4.6.0 package set. The default exemplar run completed with expected small-data warnings from `occupancy_summary` profile confidence intervals and `functional_diversity` zero distances.

- Date: 2026-05-29
- Command: `docker run --rm camtrap-workflow:r46-mac`
- Elapsed time: **52.5 seconds** (outer Docker process timing; memory is not comparable with in-R runs)
- Platform: macOS 26.5 Docker Desktop, `linux/arm64` image based on `rocker/r-ver:4.6.0`
- R: 4.6.0
- Notes: Full container pipeline completed from a fresh image target store, including HTML/PDF report and methods renders. The image was built with `GIT_COMMIT=<current commit>-dirty` so run manifests can retain source provenance without copying `.git/` into the image.

## CI strategy for heavy runs

- **Fast checks (PR/local)**: lint + unit tests + minimal target subset (e.g., `input_contract_validation`).
- **Full runs (manual/nightly)**: full `tar_make()` for the exemplar and any Camtrap DP example when validating releases.
