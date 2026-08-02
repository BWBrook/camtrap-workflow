# Container

The container supplies R 4.6, Quarto, system libraries, and the locked `renv`
environment needed for the HTML-only workflow.

## Build

```sh
docker build -t camtrap-workflow .
```

## Run The Included Configuration

```sh
docker run --rm \
  -v "$PWD/outputs:/app/outputs" \
  camtrap-workflow
```

## Run Another Configuration

Mount the configuration and source-data directory read-only, plus a writable
output directory. Paths in the YAML are resolved inside the container.

```sh
docker run --rm \
  -v "$PWD/config.template_example.yml:/app/config.external.yml:ro" \
  -v "$PWD/data/template_dataset:/app/data/template_dataset:ro" \
  -v "$PWD/outputs:/app/outputs" \
  camtrap-workflow \
  Rscript scripts/run_full_evidence_run.R --config config.external.yml
```

The completed bundle contains its captured sources, effective configuration,
engine identity, session information, and payload fixity. The container does
not need host Git metadata to publish a verifiable current-contract run.
