# Goal 011 - Kill Your Darlings: full product and architecture simplification

Date: 2026-08-02

State: `COMPLETE_PUBLISHED`

## Purpose

Turn Camtrap Workflow from an accumulated research codebase into a smaller,
faster, and easier-to-understand ecological product.

The retained workflow will take already-labelled camera-trap records, check and
prepare them, form defensible detection events, run a restrained set of useful
ecological summaries, explain which analyses were possible, and produce a
concise report plus reproducibility evidence.

This is not a cosmetic cleanup. It is an intentional reduction of both product
scope and implementation complexity. Capabilities that do not yet earn their
scientific, user, maintenance, or runtime cost will be deleted rather than kept
behind flags or compatibility layers.

## Authority and review state

Barry approved the full simplification direction on 2026-08-02, including:

- direct deletion rather than an audit-only recommendation;
- one coherent refactor followed by one end-of-refactor review stage comprising
  one scientific and one architecture review;
- no backward-compatibility obligation for old run bundles;
- regeneration of historical outputs from source data when needed;
- removal of scientifically weak or insufficiently justified modules; and
- a lean user-facing product as the controlling objective.

Barry named this operating posture **Kill Your Darlings Mode**.

Barry approved this written specification and authorized implementation on
2026-08-02. The orchestrator may execute the coherent refactor, conduct the two
specified end reviews, make at most one focused repair pass, and publish the
accepted result within the boundaries below.

## North Star

Camtrap Workflow should let an ecologist or land manager turn a labelled
camera-trap dataset into a clear, reproducible ecological report without
needing to write or understand R code.

The software should:

- use only analyses supported by the supplied data;
- explain plainly why an analysis ran, ran with warnings, or was omitted;
- distinguish ecological observations from stronger inference;
- retain enough provenance to reproduce and audit consequential results;
- protect private data by supporting a fully local workflow; and
- remain simple enough to operate, maintain, explain, and extend.

Judbury is the validating demonstration: a data-rich but bounded case with
camera moves, incomplete operation, variable effort, and an explicit 13-location
to nine-site analysis policy. It is not permission to make Judbury-specific
assumptions the generic product default.

## Why simplify now

The current repository proves that rigorous evidence and a complete workflow
are possible, but it carries too much machinery for its present ecological
value and sole current user. Building new capabilities on that foundation would
make each subsequent change slower and harder to reason about.

At the Goal 010 closeout baseline:

- production `R/` code comprises 37 files and about 14,000 lines;
- `_targets.R` contains 141 targets in about 1,900 lines;
- the runner globally sources 16 modules and coordinates stages through an
  environment-variable and runtime-JSON handshake;
- selected-resolution and event-construction semantics are duplicated;
- old manifest, preview, resolution, and bundle compatibility branches have no
  external consumer;
- the ordinary CI workflow takes about three minutes, but the accepted manual
  release took 41 minutes 48 seconds;
- the full evidence run took 33 minutes 43 seconds and the subsequent verifier
  took 5 minutes 37 seconds; and
- validation and provenance gates account for most recorded target time, while
  the ecological calculations are comparatively cheap.

These observations make simplification a product prerequisite, not an aesthetic
preference. The aim is to preserve consequential scientific and data-integrity
protection while removing repeated reconstruction, compatibility scaffolding,
weak analyses, and ceremony that users do not benefit from.

## Retained product surface

### Input and preparation

Retain:

- the current simple four-table CSV input route for labelled records and their
  supporting site, effort/deployment, and taxonomic information;
- current-format CamtrapDP interoperability through an adapter, without making
  the full CamtrapDP schema mandatory;
- immutable source inputs;
- validation with clear, actionable messages;
- optional audited normalization or repair, controlled by the user;
- entity resolution for camera, deployment, physical location, and taxon;
- conservative deployment and confirmed-operation evidence;
- optional, explicitly labelled inference of observation intervals;
- timestamp quality information, including support for coarse day/night use
  where exact clock time is unreliable; and
- source-row lineage into derived detection events.

The workflow begins after image labelling. Image classification, object
detection, and species labelling remain the responsibility of tools such as
MEWC, MegaDetector, human review, or another upstream process.

### Spatial and event foundations

Retain:

- event construction at resolved physical locations before any spatial
  grouping;
- configurable event-gap thresholds and a compact sensitivity summary;
- `physical_location` as the explicit generic spatial analysis unit;
- `analysis_site` as an explicit purpose-specific grouping when an
  authoritative mapping is supplied; and
- nominal station as survey-design metadata, not an analytical route.

No analysis-site grouping may be inferred silently from names, suffixes,
coordinates, proximity, chronology, or effort patterns.

The retained modules use spatial resolution as follows:

| Module | Goal 011 spatial route |
| --- | --- |
| confirmed effort and coverage | the one selected resolution: `physical_location` or an explicitly mapped `analysis_site` |
| observed presence and richness | the one selected resolution |
| descriptive Jaccard dissimilarity | the one selected resolution |
| operational-event detection rate | `physical_location` only |
| coarse day/night summary | `physical_location` only |
| species-accumulation diagnostic | `physical_location` only |
| point/site map | physical locations, with an optional explicit analysis-site grouping overlay |

A run does not automatically duplicate a selected-resolution module at both
resolutions. When `analysis_site` is selected, the report may contain both
analysis-site core results and clearly labelled physical-location diagnostics.
The map may show approved representative analysis-site positions or membership
links as orientation aids, but it must retain the contributing physical
locations and must not treat synthetic positions as environmental observations.

### Core ecological outputs

Retain a restrained core:

- confirmed sampling effort and coverage;
- observed species presence and observed richness;
- descriptive Jaccard community dissimilarity;
- operational-event detection rate, formerly described as RAI;
- coarse day/night summaries when supported by the records;
- a species-accumulation diagnostic, replacing ambiguous rarefaction claims;
  and
- a simple point or site map.

The scientific claims are deliberately bounded:

- observed richness is detection-limited, not an estimate of unseen richness;
- Jaccard is a descriptive comparison of detected composition, not a causal
  environmental model;
- operational-event detection rate is not abundance or density and will not
  carry decorative inferential intervals;
- day/night summaries do not imply reliable fine-scale diel timing when camera
  clocks may drift;
- species accumulation diagnoses sampling accumulation and does not promise a
  complete community estimate; and
- maps show supplied or approved representative locations, not interpolated
  environmental surfaces.

### Outputs

Retain three distinct output layers:

1. one concise HTML ecological report for the ordinary user;
2. a separate detailed audit bundle; and
3. machine-readable results and status records.

The primary report should lead with ecological findings, sampling context,
omissions, and limitations. Engineering provenance belongs mainly in the audit
and machine-readable layers.

## Product surface to delete

Delete the current implementations of:

- occupancy modelling;
- detection-history machinery used by that occupancy implementation;
- event-count Shannon and Simpson diversity;
- Bray-Curtis distance-decay analysis;
- functional diversity;
- trait-environment correlations;
- first-detection and multi-species-image miscellany;
- broad exploratory summaries without a clear core-report role;
- automatic methods-manuscript rendering;
- default PDF and TinyTeX report machinery; and
- the large serialized occupancy-model payload.

Deletion means absence from active production code, targets, configuration,
tests, reports, current user/developer documentation, release artefacts, and
dependencies that no longer serve retained functionality. Historical Goal
records and Git history remain as provenance and are exempt from deletion
scans. Do not leave dormant code, hidden options, compatibility shims, or a
disabled-module museum.

This decision rejects the current implementations, not the ecological methods
for all time. A future expert module may reintroduce a method only with a clear
user question, defensible assumptions, eligibility rules, interpretation, and
evidence proportional to its cost.

## Target architecture

The product should have one legible flow:

```text
ingest
  -> validate and optionally repair
  -> resolve entities and effort
  -> form physical-location events
  -> run eligible core modules
  -> report
  -> publish
```

### Stage boundaries

Each stage receives and returns explicit data or a compact typed context. The
architecture must remove global sourcing and environment-variable/runtime-JSON
coordination between ordinary internal stages.

Validation, entity resolution, operation/effort resolution, event lineage, and
selected-resolution state are each built once and reused. The publication
verifier checks emitted artefacts and consequential invariants; it must not
re-run the workflow several times under different wrappers.

`_targets.R` becomes a small top-level composer over bounded target families.
The exact file layout belongs in the implementation plan, but target names and
dependencies must make the ecological flow visible.

### One post-refactor current contract

Goal 011 may make one documented breaking transition to a simpler current
manifest, repair-preview, configuration, and bundle contract. It must preserve
the scientific meaning of the simple four-table inputs, immutable authorities,
and current CamtrapDP interoperability, while migrating the maintained examples
and user commands to the new contract.

After that transition, support exactly one current contract. Remove dispatch
branches whose only purpose is reading pre-Goal 011 internal formats.
Historical bundles remain historical evidence; when a current output is
required, regenerate it from source data and documented configuration.

Internal stage schemas may be freely replaced. User-facing fields may be
simplified only when the change is explicit in current documentation and does
not weaken input integrity or silently reinterpret ecological data. No external
consumer migration layer is required.

### Module status contract

Every candidate ecological module reports one of:

- `completed`;
- `completed_with_warnings`;
- `omitted`; or
- `failed`.

The meanings are:

- `completed`: prerequisites were met and valid output was produced;
- `completed_with_warnings`: valid output was produced with a named ecological
  or data limitation that does not invalidate it;
- `omitted`: prerequisites or scientific eligibility were absent, so no
  analytical payload was produced; and
- `failed`: an attempted module encountered a technical or integrity failure.

Each record must state the required evidence, actual spatial resolution, and a
plain-language reason for any non-completed state. Ineligible analyses are
omitted while viable modules continue. Independent work may finish after a
module failure to preserve diagnostic evidence, but a `failed` module cannot be
published as a completed run or advance the latest-completed pointer. Integrity
failures must never be relabelled as harmless analytical omissions.

### Run and publication integrity

Preserve the smallest implementation that provides:

- immutable captured inputs;
- resolved configuration;
- stable current run identity;
- source-row and event lineage;
- fail-closed integrity checks;
- fail-soft analytical eligibility;
- atomic publication of a completed run; and
- an unambiguous pointer to the latest completed run.

Use one internal pre-publication verification and one independent release
verification. The current pattern of repeated inventories and repeated full
semantic reconstruction must be removed.

Do not add content-addressed caching in this goal. First remove duplicated work
and measure the simplified workflow.

## Two required correctness repairs

The refactor must fix two known defects rather than preserving them:

1. A mapped dataset with zero operational events must emit a valid typed
   blocked or empty evidence artefact, not a structurally invalid object.
2. Current CamtrapDP deployment lineage must carry physical-location identity
   far enough to support correct event construction and explicit analysis-site
   grouping.

These repairs must be proved with small current-format fixtures. They are not
grounds for retaining old compatibility scaffolding.

## Judbury scientific invariants

The simplified workflow must reproduce the accepted Judbury foundation:

- 13 resolved physical locations;
- the explicit, approved mapping to nine analysis sites;
- 9,639 operation-state rows;
- 11,572 physical-location detection events;
- 15,672 source-record memberships in those events;
- event conservation through analysis-site mapping;
- analysis-site presence formed by logical OR;
- observed richness equal to the row sum of presence;
- the accepted 9 by 9 Jaccard result; and
- protected physical-location provenance and covariates.

The comparison oracle is `tables/selected_jaccard.csv` in accepted Goal 010
bundle `20260802T040631Z-9e69f0844de14465`, whose manifest SHA-256 is
`f2773aed6d5ddca99be5afb5b7e96d75f6f5be603a2be10f7f15cc2cfd7b95cb`.
After sorting on the two analysis-unit identifiers, the refactored output must
have the same 81 ordered pairs and agree within absolute tolerance `1e-12`.
Symmetry, `[0, 1]` bounds, zero nonempty diagonals, and `NA` for empty unions
remain independent semantic checks; Judbury has no empty selected community,
so the empty-union case uses a small fixture.

Protected physical provenance means that all 13 physical-location identifiers,
their coordinates, and supplied physical covariate values remain unchanged from
the immutable input evidence. No analysis-site covariate value may be pooled,
interpolated, or extracted from a representative midpoint.

The four grouped Judbury analysis sites retain their approved representative
midpoints for mapping and inter-site distance only. These synthetic positions
must not be used to invent pooled environmental covariates.

The standard Judbury report must state that the nine-site grouping is explicit,
purpose-specific, and supported by non-overlapping replacement histories. It
must not present that bespoke policy as a general default.

## Implementation boundary

Goal 011 implementation may change or delete:

- production R modules;
- the targets graph and runner;
- current configuration and internal schemas, subject to the one documented
  post-refactor contract above;
- reports and render orchestration;
- tests and fixtures;
- dependencies and lockfile entries made unused by deletion;
- CI and release orchestration;
- user and developer documentation; and
- Goal 011 records and project roadmaps.

It must preserve source datasets and accepted authority files. In particular,
do not alter the Judbury entity crosswalk, deployment ledger, operation table,
or approved analysis-site mapping merely to make implementation easier.

No external consumer migration is required because Barry is the sole current
consumer. User-facing changes must nevertheless be documented clearly so the
new current workflow can be run without inspecting R code.

## Non-goals

Do not use this goal to add:

- a Shiny interface;
- hosted or cloud analysis;
- AI-written ecological interpretation;
- image labelling or classification;
- automated analysis-site inference;
- LocalMap integration or spatial covariate extraction;
- ALA or regional gamma-diversity comparison;
- fine-scale diel analysis;
- population trend, abundance, density, causal habitat, or unseen-richness
  inference;
- a replacement occupancy implementation;
- new expert modules; or
- content-addressed caching.

These may be evaluated after the lean foundation is proven.

## Verification measurement

The implementation plan must record the Goal 011 starting test surface before
production edits. For this goal, test surface means:

- tracked R test-file count under `tests/testthat/`, separated into fast and
  release tiers; and
- total tracked lines across those test files, also separated by tier.

Expectation counts may be reported as context but are not a quality target.
The final test surface must not exceed either starting file count or starting
line count, and retained tests must still cover the explicit success criteria.

The 15-minute release decision bar is measured once on the manual exact-SHA
GitHub Actions release runner. Timing starts immediately before the full
Judbury publisher command and ends after the independent published-bundle
verifier. Runner type, dependency-cache state, commands, SHA, and phase timings
must be recorded. Job provisioning, dependency installation, and network-bound
artefact upload are timed and reported separately because they do not measure
the product architecture. Artefact upload must still succeed.

## Success criteria

Goal 011 is complete when:

1. The repository implements the explicit seven-stage flow from ingest through
   publication without the global environment/JSON stage handshake.
2. The deleted product surface is absent from active code, targets,
   configuration, dependencies, tests, reports, current user/developer
   documentation, and new release artefacts; historical Goal records remain.
3. Only `physical_location` and explicitly mapped `analysis_site` are analytical
   spatial resolutions; nominal station remains metadata.
4. Validation, entity/effort resolution, event construction, and selected
   resolution are each computed once per run and consumed through explicit
   stage contracts.
5. The retained ecological modules use the approved names and claim limits.
6. Every candidate module emits a clear status and explanation, and an
   unavailable module does not prevent viable modules from completing.
7. The zero-event and current CamtrapDP lineage defects are repaired and proved
   with small fixtures.
8. The accepted Judbury counts, mapping, lineage, presence, richness, and
   Jaccard invariants are independently reconstructed from the emitted bundle.
9. The concise HTML report is ecologist-facing, while detailed provenance and
   machine-readable results remain available separately.
10. Fast tests complete in under two minutes and neither defined test-surface
    measure exceeds its recorded Goal 011 starting baseline.
11. One final exact-SHA release completes the full Judbury build, publication,
    and independent verification within the defined 15-minute measurement
    window, then successfully uploads its artefact.
12. One scientific review and one architecture review find no material defect,
    with at most one focused repair pass before final release proof.

Runtime limits are measured decision bars, not flaky timing assertions embedded
in tests. Missing the 15-minute release bar requires diagnosis and a Barry
decision; repeated unchanged reruns are not acceptable evidence.

## Closeout evidence

Accepted implementation `f62c11e370b04c91008454b781920b1c000754cf`
passed ordinary exact-SHA workflow `30753378488`. Its fast-test step took 35
seconds and the complete Linux job took 2 minutes 32 seconds. The local gate at
the same product state reported 516 passes with no failures, warnings, or skips
in 15.58 seconds wall time; lint, `actionlint`, `renv::status()`, and diff
hygiene were clean.

Manual exact-SHA workflow `30753489524` then passed one full Judbury publisher,
one independent emitted-bundle reconstruction, and artefact upload. The
publisher took 156.80 seconds and the verifier 21.30 seconds, for a measured
release path of 178.10 seconds (2 minutes 58.1 seconds) against the 15-minute
bar. The corresponding Goal 010 path was 39 minutes 20 seconds, so the retained
path is about 13.3 times faster.

The emitted run `20260802T150751Z-98a49af832994d80` has manifest SHA-256
`b98e0602fb065c8a313fefb205199daed45aa2d0604a4a3ff2b1e6b33f921bea`.
Independent reconstruction confirmed 13 physical locations, nine eligible
analysis sites, 9,639 operation rows, 11,572 physical events, 15,672 source
memberships, presence by logical OR, richness by presence row sums, all 81
accepted Jaccard values, and unchanged physical coordinates. All nine retained
module records were `completed`. GitHub artefact `8835273351` contains the
51-payload bundle and report; its uploaded archive digest is
`047a9b925f3f500eaa6ee57c60b884c471db57a6b2d385ad576bda563e0b1658`.

The final surface is seven targets, 26 production R files and 10,476 lines, and
21 fast test files and 4,201 lines. The Goal 011 diff removes 16,141 lines and
adds 6,167, a net subtraction of 9,974 lines while preserving the accepted
Judbury foundation.

One initial exact-SHA CI attempt exposed a missing Linux GLPK runtime needed by
the cached `igraph` binary. Restoring `libglpk-dev` in both CI jobs produced the
accepted exact SHA; no full Judbury release was spent before ordinary CI was
green.

Two non-blocking presentation and subtraction residues remain. The report is
scientifically bounded and complete, but its 243-row day/night table is longer
than the intended concise primary view; a future report pass should summarise
that table while retaining the full machine-readable result. A few old
diagnostic helpers still have no production caller and can be reconsidered in a
later value-led deletion pass. Neither changes the accepted ecological results,
publication integrity, or runtime decision.

## Delivery and stopping policy

Implement this as one coherent refactor. Small internal commits are encouraged
where they preserve understandable checkpoints, but there is no requirement to
return to Barry between technical tranches.

The implementation sequence should maintain a runnable core as far as
practical, but it should optimize the final architecture rather than preserving
temporary backward compatibility.

After the core implementation:

1. run the proportionate fast checks;
2. conduct one scientific review and one architecture review;
3. make at most one focused repair pass for material findings; and
4. run one exact-SHA release and independent reconstruction.

Stop when the retained product works, consequential invariants are proved, the
runtime bar is met, and remaining changes are mainly naming, layout, or marginal
polish. Do not spend repeated passes chasing an idealized architecture.

Stop early and return to Barry only if:

- a proposed deletion would remove scientifically necessary information rather
  than an implementation or derived product;
- evidence contradicts an approved Judbury interpretation;
- a retained ecological claim cannot be defended;
- the simplified architecture cannot meet the release bar without a materially
  different product decision;
- source data or an accepted authority artefact would need destructive change;
  or
- implementation reveals a material strategic choice outside this
  specification.

## Next gate

Implementation is authorized. The next human gate is Barry's review of the
completed Goal 011 evidence and recommendation after the end reviews and exact-
SHA release proof. Return earlier only for a stop condition named above.
