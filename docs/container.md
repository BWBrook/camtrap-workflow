# Container recipe

This repo includes a Dockerfile for reproducible pipeline execution.

## Build

```sh
docker build -t camtrap-workflow:latest .
```

## Run (default)

```sh
docker run --rm -v "$PWD/outputs:/app/outputs" camtrap-workflow:latest
```

## Notes

- The container installs Quarto and TinyTeX to support PDF rendering.
- System dependencies include GLPK and libjq for `igraph` and `camtrapdp`.
- If you want to skip PDF output, set `analysis.report: false` in your config or remove TinyTeX installation from the Dockerfile.
