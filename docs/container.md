# Container recipe

This repo includes a Dockerfile for reproducible pipeline execution.

## Build

```sh
docker build -t camtrap-workflow:latest .
```

To preserve commit provenance in `outputs/runs/<run_id>/run_manifest.json`,
pass the current commit at build time:

```sh
docker build \
  --build-arg GIT_COMMIT="$(git rev-parse HEAD)" \
  -t camtrap-workflow:latest .
```

## Run (default)

```sh
docker run --rm -v "$PWD/outputs:/app/outputs" camtrap-workflow:latest
```

The container command uses the supported full-run publisher. It writes a
unique bundle under `outputs/runs/<run_id>/`, writes `COMPLETED.json` last, and
updates the regular-file pointer `outputs/latest` only after verification.

Verify a mounted bundle with the same image:

```sh
RUN_ID="$(tr -d '\n' < outputs/latest)"
docker run --rm -v "$PWD/outputs:/app/outputs" \
  camtrap-workflow:latest \
  Rscript scripts/run_full_evidence_run.R \
  --verify-bundle "outputs/runs/${RUN_ID}"
```

## Notes

- The container installs Quarto and TinyTeX to support PDF rendering.
- System dependencies include GLPK and libjq for `igraph` and `camtrapdp`.
- The Quarto installer is architecture-aware for both `linux/amd64` and `linux/arm64` builds.
- If you want to skip PDF output, set `analysis.report: false` in your config or remove TinyTeX installation from the Dockerfile.
