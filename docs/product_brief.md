# Product brief: camtrap-workflow

## Summary

camtrap-workflow is a reproducible, teaching-friendly R workflow for end-to-end analysis of camera-trap data **after** images have been labelled and site metadata has been assembled. It turns a set of correctly formatted tables into validated derived datasets, ecological summary metrics, population/community analyses, and a rendered report.

The exemplar dataset is camera trapping from Judbury Conservation Reserve (Tasmania). The workflow is designed so other practitioners can reuse it with their own camera-trap projects by conforming to the documented input contract.

## Target users

- Ecologists and conservation practitioners running camera-trap surveys
- Students learning modern reproducible ecological workflows
- Research teams wanting a “reference implementation” for camera-trap analysis

## Problem statement

Camera-trap projects often produce results that are difficult to reproduce:
- ad-hoc scripts,
- inconsistent definitions of “independent events,”
- unclear handling of effort/downtime,
- fragile model code,
- and missing provenance for figures and tables.

This repo aims to provide a canonical, transparent workflow that:
- enforces data integrity early,
- encodes analysis steps as a pipeline,
- produces inspectable artefacts,
- and makes it easy to re-run and extend analyses.

## Goals

### Scientific goals
- Provide a coherent tiered analysis path:
  1) Effort and detection processing (effort offsets, independent events)
  2) Descriptive summaries (RAI, diel patterns, accumulation curves)
  3) Population inference (occupancy models)
  4) Community and trait-informed analyses (diversity, functional indices)

### Engineering goals
- One-command reproducible runs after setup
- Automated validation + testing
- CI quality gates
- Clear documentation and a release process

## Non-goals (explicit)

- Image classification / ML labelling (assumed done upstream)
- Building a database or full data management platform
- A Shiny web application (may be a future extension, not in scope)
- Making claims about absolute abundance without defensible study design

## Inputs and data contract

### Primary input mode: tabular CSVs
A dataset is provided as four CSV tables:
- `site` table: site identifier + spatial/environmental covariates
- `op` table: effort matrix (date × site columns) with 0/1 operational status
- `obs` table: labelled detections with datetime, species code, flash/day-night proxy, etc.
- `taxa` table: species traits and metadata

The workflow must validate:
- required columns exist and types are compatible,
- keys align between tables,
- effort coverage is sensible (no negative/NA, expected ranges),
- species codes in observations exist in taxa.

### Optional input mode: Camtrap DP / WildObsR adapter
Optionally, the workflow may support ingestion of camera-trap data as a Camtrap Data Package (Frictionless spec) via WildObsR, converting it into the internal contract.

This is an adapter layer, not a replacement for the tabular contract.

## Outputs

Outputs are produced under `outputs/` and include:
- Derived tables: effort summaries, event tables, detection histories, community matrices
- Figures: effort summaries, RAI plots, diel plots, rarefaction curves, maps (if enabled)
- Models: fitted occupancy objects and summaries (Beta+)
- Report: rendered Quarto (HTML/PDF), with interpretation text and linked artefacts
- Provenance: session info and run metadata

## UX principles

- Default workflow runs on the exemplar dataset without edits.
- Running on new data should require:
  - placing new input files in a documented location, and
  - editing a single configuration file (or clearly documented parameter list).
- Fail early with actionable error messages (especially for QC).

## Success definition

A user who is not an R expert can:
- set up the environment,
- run the pipeline end-to-end,
- open a report with coherent artefacts,
- and repeat with their own dataset (if formatted correctly).
