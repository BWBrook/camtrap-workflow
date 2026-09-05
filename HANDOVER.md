# Camtrap Workflow successor handover

Current as of 2026-09-05. This is a fast bootstrap, not a second source of
truth. Verify live Git state, then let the current code, `README.md`,
`docs/roadmap.md`, and `docs/decisions.md` override any stale detail here.

## Start here

Read, in order:

1. the global and repository `AGENTS.md` files;
2. this note and `README.md`;
3. `docs/roadmap.md`, `docs/architecture.md`, and `docs/workflow.md`;
4. `docs/goals/012-practitioner-report/ImplementationReport.md`; and
5. only the relevant parts of `docs/decisions.md` or earlier goal records when
   a present decision needs its evidence.

Do not begin by reading every historical goal. Goals 001-010 explain how the
current product was reached, but they are not the current product contract.
The former `chief_of_staff` and `goal_composer` repositories are retired
workflow machinery, not required control planes for this project.

Use these personal skills when the work warrants them:

- `/Users/bwbrook/.codex/skills/twilight-laboratory/SKILL.md` for programme
  framing, scientific decision gates, delegation, evidence review, and the
  human-collaboration cadence;
- `/Users/bwbrook/.codex/skills/kill-your-darlings/SKILL.md` whenever features,
  tests, provenance machinery, or CI begin accumulating faster than current
  scientific or user value.

The governing working principle with Barry is:

> Rigour at the scientific decision boundary; proportional engineering
> everywhere else.

Make reversible technical choices autonomously. Consult Barry when his answer
could materially change the ecological question, scientific interpretation,
public contract, strategic direction, substantial resource commitment, or an
irreversible external action. One focused self-review and one material repair
pass are normally enough; "could be more polished" is not a reason to continue.

## North star

Camtrap Workflow should let a practitioner provide already-labelled camera
records and supporting site/effort data, choose a configuration, and receive a
clear, reproducible ecological report without writing R code or sending
private data outside their machine or agency network.

The Judbury study is the validating exemplar and eventual open dataset, not a
universal schema. The intended publication is primarily a software-method
paper, with Judbury demonstrating what the workflow can do. A second public
dataset may later test portability, but none has been selected.

This project begins after labelling. Image classification, MegaDetector, MEWC,
and human-review workflows are upstream concerns. Image-level records are
welcome; operational detection events are derived downstream under an explicit
time-gap rule.

## Current product

At commit `79d64ad753b00c9dd6c6c5e706bd6710e0a4428c`, the supported flow is:

```text
labelled inputs
  -> immutable ingest
  -> validation and controlled repair
  -> entity, effort, and spatial resolution
  -> operational detection events with source-row membership
  -> eligible ecological summaries with explicit statuses
  -> concise HTML report plus audit and machine-readable evidence
  -> verified, atomic publication
```

The public input routes are either four CSV tables (`site`, daily `op`, `obs`,
and `taxa`) or a Camtrap Data Package adapter. The generic analytical unit is
`physical_location`. `analysis_site` is permitted only through an explicit,
approved mapping; it is never inferred from names, coordinates, or proximity.

The retained ecological outputs are deliberately modest:

- confirmed effort and coverage;
- observed presence and detection-limited richness;
- descriptive Jaccard dissimilarity of detected composition;
- physical-location operational-event detection rates;
- coarse day/night summaries;
- species-accumulation and event-gap diagnostics; and
- a supplied-point location map.

Every candidate result is `completed`, `completed_with_warnings`, `omitted`,
or `failed`, with its evidence, resolution, claim limit, and reason. Missing
scientific prerequisites omit one module without erasing viable results;
input, lineage, or publication-integrity failures stop the run.

The primary report only displays and reshapes emitted results. It must not
quietly become a second ecological calculation layer. Complete tables remain
in the bundle.

## Scientific invariants

Protect these unless Barry explicitly changes the scientific policy:

- Unknown camera operation is not zero effort. A sampled zero is evidence; an
  unsampled or unknown interval is not an ecological absence.
- Deployment intervals are the conservative effort basis. Any inferred
  operating interval or repair must be optional, reviewable, and auditable.
- An operational detection event is a reproducible grouping of records, not a
  claim about an independent animal visit.
- Observed richness does not estimate unseen richness.
- Jaccard describes detected composition and is not standardized for unequal
  effort, completeness, or detectability.
- Operational-event rate is neither abundance nor density.
- Day/night is a coarse light or clock category, not precise diel activity.
- Supplied coordinates may be mapped, but the workflow does not fabricate
  habitat surfaces or causal environmental explanations.
- Source data remain unchanged; approved repairs create a traceable derived
  view.

Judbury implements the intended three-by-three grid as nine `analysis_site`
units while preserving 13 distinct physical camera locations created by four
relocations. Events are formed at physical locations first, then assigned by
the exact approved mapping. The grouping is specific to this study and there
was no temporal overlap among the paired replacement locations. Physical
covariates are not pooled across moved locations.

## How the project reached this state

- Goals 001-004 established runtime readiness, audited the irregular inherited
  repository, scanned comparable products, and set the product direction.
- Goals 005-009 built immutable runs, controlled repair and lineage, separated
  station/location/deployment/site identities, resolved Judbury deployment
  evidence, and implemented the approved nine-site analytical route.
- Goal 010 cut redundant testing and separated the fast change gate from the
  single explicit release proof.
- Goal 011 was the major "kill your darlings" refactor. It removed speculative
  occupancy, traits, functional-diversity, export, reporting, compatibility,
  and orchestration surfaces; reduced the workflow to seven targets; and made
  the retained path roughly 13 times faster than the preceding release path.
- Goal 012 turned the existing results into a practitioner-facing report and
  proved the same engine on Judbury and the maintained synthetic forest
  example. A proposed report-only pooled rate was rejected: new ecological
  metrics belong in the engine after an explicit scientific decision.

The live code surface is still substantial: seven targets, 26 production R
files (10,477 lines), and 21 fast-test files (4,216 lines). Treat these as
diagnostic counts, not accomplishments or automatic deletion targets. Remove
only complexity that no current workflow, scientific claim, or material
failure mode can justify.

## Last accepted evidence

- `main` and `origin/main` were clean and synchronized at `79d64ad` when this
  note was written.
- GitHub Actions run `31103807969` passed ordinary CI for that exact SHA in
  2 minutes 20 seconds.
- Goal 012 recorded 518 fast checks with no failures, warnings, or skips.
- The accepted Judbury release reconstructed 13 physical locations, nine
  analysis sites, 9,639 operation rows, 11,572 events, 15,672 source
  memberships, and all 81 approved Jaccard cells.
- The forest example reconstructed six units, 366 operation rows, 90 events,
  92 memberships, and 36 Jaccard cells.

Generated `outputs/` are ignored and may be absent or stale in a new checkout.
Regenerate evidence before making a current claim; do not infer current status
from an old `outputs/latest` pointer.

## Where to head next

No Goal 013 is approved. The next substantive conversation should decide which
current bottleneck deserves one bounded tranche:

1. **Recommended scientific move:** add one effort-adjusted temporal summary
   for a small, predeclared set of species, using broad seasons or another
   defensible named interval. Judbury contains roughly three years of data, and
   the current report collapses most of that temporal information. This must be
   designed as a real engine module with explicit eligibility and claim limits,
   not calculated opportunistically in the report.
2. **Competing product move:** make effort input easier for practitioners. The
   four-table route currently expects a daily operation table, while generic
   deployment/service evidence and optional, audited last-observation inference
   remain incomplete. If input preparation is the dominant user burden, this
   may provide more value than another analysis.

My recommendation is to show Barry the current Goal 012 report, then ask which
gap matters more in practice: temporal ecological insight or effort-data
preparation. That is a substantive choice worth his attention. Do not begin a
GUI, Docker installer, hosted service, LocalMap integration, AI interpretation,
occupancy revival, regional ALA comparison, or public schema redesign merely
because it appears later in an old roadmap.

LocalMap_Tas should remain a sister product that can supply mapped covariates
and visualizations through a future file-plus-manifest boundary. Camtrap
Workflow should continue to assume that site data arrive ready for analysis.

## Useful commands

```sh
git status --short --branch
git fetch --prune origin
Rscript bootstrap_env.R
Rscript scripts/run_tests.R --profile fast
Rscript scripts/run_lint.R
actionlint .github/workflows/ci.yml
Rscript scripts/run_full_evidence_run.R --validate-only --config config.yml
Rscript scripts/run_full_evidence_run.R --config config.yml
```

Use the independent bundle verifier for consequential output changes. Reserve
the full Judbury release for a reviewed exact SHA; do not spend it debugging
ordinary implementation failures.
