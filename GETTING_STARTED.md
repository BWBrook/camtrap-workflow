# Getting Started

## Install

Install R 4.6 and Quarto, then restore the locked project library from the
repository root:

```sh
Rscript bootstrap_env.R
quarto --version
```

`bootstrap_env.R` activates `renv` and restores the versions recorded in
`renv.lock`.

## Validate First

Run an immutable validation preview before an ecological analysis:

```sh
Rscript scripts/run_full_evidence_run.R \
  --validate-only --config config.yml
```

The preview is written to `outputs/preflight/<run_id>/`. It reports whether
analysis can proceed and records any proposed normalization. It cannot publish
a completed run or change `outputs/latest`.

## Publish A Run

```sh
Rscript scripts/run_full_evidence_run.R --config config.yml
```

The seven stages capture immutable inputs, validate them, resolve entities and
effort, construct physical-location events, run eligible ecological modules,
render one HTML report, and publish the verified bundle atomically.

Read the current run ID and open its report:

```sh
RUN_ID="$(tr -d '\n' < outputs/latest)"
open "outputs/runs/${RUN_ID}/report/report.html"
```

Verify the published artefacts without calling the workflow again:

```sh
Rscript scripts/verify_published_bundle.R "outputs/runs/${RUN_ID}"
```

For the standard Judbury configuration, include the accepted comparison
oracle shown in `README.md`.

## Use Another Dataset

Start with `config.template_example.yml` and `data/template_dataset/`, then
follow `docs/bring_your_own_data.md`. Current CamtrapDP input uses
`config.camtrapdp_example.yml`.

## Contributor Checks

```sh
Rscript scripts/run_lint.R
Rscript scripts/run_tests.R --profile fast
actionlint .github/workflows/ci.yml
```

The fast suite includes a real seven-stage fixture publication and independent
bundle verification. Full Judbury publication is a separate manual release
operation.
