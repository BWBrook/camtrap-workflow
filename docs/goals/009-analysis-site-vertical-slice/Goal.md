# Goal 009 - Analysis-site ecological vertical slice

## Ecological outcome

Turn the resolved Judbury deployment history into a small set of useful
ecological summaries at an explicitly chosen spatial unit.

For the standard Judbury run, the 13 physical camera locations are grouped
into nine analysis sites. Close replacement locations contribute their
non-overlapping effort and already-defined detection events to the same
analysis site. This preserves the intended nine-point grid without discarding
short or interrupted deployments and without pretending that the original and
replacement coordinates were identical.

The first ecological slice is deliberately restrained:

- camera operation and sampling coverage;
- observed species richness;
- species presence/absence composition; and
- descriptive pairwise turnover using Jaccard dissimilarity.

These outputs describe what was detected, where, and under how much confirmed
sampling. They do not estimate unseen richness, abundance, causal habitat
effects, or population change.

## Authority and goal state

Barry approved this complete written Goal specification and on 2026-07-31
authorized this packet-authoring step toward implementation, subject to the
exact packet gates below.

That authority permits authoring this complete packet, including the proposed
mapping CSV, `Plan.md`, `Runbook.md`, `Log.md`, and the scoped roadmap and
decision records.

On 2026-08-01, after reviewing the exact eight-path packet and mapping-hash
summary plus the ecologist-facing Goal explanation, Barry gave exact
conditional approval to publish this packet and execute Goal 009. The approval
covers the reviewed packet, exact mapping schema, scheme, version, state,
bytes, digest and authority reference, `Plan.md`, `Runbook.md`, closed
implementation allowlist, packet and implementation subjects, and mutation
and publication boundaries.

Production implementation is authorized only if packet publication produces
one exact eight-path commit with parent
`c0ed40377af4aa0162098913e2c097da65eadc42`, subject
`docs: define Goal 009 analysis-site vertical slice`, and unchanged mapping
SHA-256
`6490d7f7021e5c727b9be1c7d6dfbf44ba50a1ef5b0396c66e1dd813a9c77083`.
The exact publication verification is a hard condition; a mismatch stops
execution and requires renewed authority. No additional Barry message is
required when every condition matches.

The drafting baseline is clean synchronized `main` at
`c0ed40377af4aa0162098913e2c097da65eadc42`. Goal 008 closeout workflow run
`30258491234` concluded successfully before drafting began.

## Accepted concepts and decisions

### Analysis site is purpose-specific

`analysis_site` is a derived grouping created for a named analytical purpose.
It is not a synonym for:

- `nominal_grid_station`, which records the intended survey design;
- `physical_location`, which records where a camera was actually placed; or
- `deployment`, which records a camera's bounded deployment interval.

Every analysis-site scheme is explicit, named, versioned, and attributable to
either supplied investigator authority or an approved built-in default.

### Generic default and explicit grouping

When no analysis-site mapping is supplied, each resolved physical location
maps one-to-one to its own analysis site. This identity fallback is the
general default. It is a deterministic built-in physical-location identity
scheme, not an anonymous absence of policy. Its stable scheme identity and
version must be recorded in resolved configuration and output metadata.

A supplied mapping reports that mapping's scheme identity, version, and
authority. Exact internal string values and configuration spelling for both
the supplied and built-in schemes remain implementation-packet decisions.

An investigator may instead supply an explicit mapping that groups physical
locations for a stated analytical purpose. Goal 009 must not infer grouping
from:

- identifier suffixes;
- nominal-station membership;
- coordinates or proximity;
- a radius;
- deployment chronology;
- effort patterns; or
- observation dates.

A selected mapping that is missing, malformed, incomplete, unauthorized, or
inconsistent must fail before analysis. It must never silently fall back to
the identity mapping. Automatic and radius-based grouping proposals are
deferred.

### One selected resolution per affected module

Each affected module runs at one explicitly selected spatial resolution:

- `analysis_site`;
- `physical_location`; or
- `nominal_station`, when authoritative nominal-station evidence is
  available.

The standard Judbury profile selects `analysis_site`. Physical-location and
nominal-station resolutions remain selectable alternatives. Producing
multiple resolutions together is a separate, explicit comparison or
sensitivity request; it is not automatic.

Direct `physical_location` selection cites the authoritative physical-location
entity schema and version. `nominal_station` selection cites the authoritative
nominal-station membership schema and version. These provenance identities are
not analysis-site mapping schemes and must not be presented as such.

Selecting a resolution that lacks authoritative membership evidence makes
the affected module ineligible with an explanation. It does not trigger an
implicit substitute resolution.

## Judbury analysis-site scheme

### Membership

The approved ecological design is an explicit 13-physical-location to
nine-analysis-site mapping:

| Analysis site | Contributing physical location(s) |
| --- | --- |
| `jc_cen` | `jc_cen` |
| `jc_co1` | `jc_co1`, `jc_co1_s1` |
| `jc_co2` | `jc_co2` |
| `jc_co3` | `jc_co3`, `jc_co3_s16` |
| `jc_co4` | `jc_co4` |
| `jc_pm12` | `jc_pm12` |
| `jc_pm14` | `jc_pm14`, `jc_pm14_s1` |
| `jc_pm23` | `jc_pm23` |
| `jc_pm34` | `jc_pm34`, `jc_pm34_s15` |

The analysis-site labels may resemble nominal-station labels, but the
entities and authority remain distinct. Nominal-station membership must not
be treated as an analysis-site mapping by implication.

Each participating physical location has exactly one membership in this
scheme. The four pairs represent non-overlapping sequential replacements.
Judbury has no genuine temporal overlap between member deployments. An
approved day-precision same-date handover, including the `jc_co1` handover,
is a boundary between deployments rather than evidence of full-day
concurrency.

### Representative coordinates

Unmoved analysis sites retain their physical-location coordinates.

The four grouped analysis sites use these fixed midpoint coordinates:

| Analysis site | Latitude | Longitude | Coordinate basis |
| --- | ---: | ---: | --- |
| `jc_co1` | -42.9974400 | 146.9394450 | midpoint of the two approved physical locations |
| `jc_co3` | -43.0004650 | 146.9477700 | midpoint of the two approved physical locations |
| `jc_pm14` | -42.9996600 | 146.9401500 | midpoint of the two approved physical locations |
| `jc_pm34` | -43.0012590 | 146.9447415 | midpoint of the two approved physical locations |

The approved values are fixed scheme evidence for mapping and inter-site
distance only. Runtime code must not choose a longest-running member or
recalculate a representative position from effort.

Synthetic midpoint coordinates must not be used to extract, interpolate, or
invent slope, vegetation, canopy, edge, or other environmental covariates.
Actual physical-location coordinates and covariates remain intact in the
audit evidence. Pooled covariate inference is deferred.

## Mapping contract

Goal 009 may introduce one optional simple CSV containing one row per
physical-location membership. Its minimal logical fields are:

- scheme identifier;
- scheme version;
- analysis-site identifier;
- physical-location identifier;
- representative latitude;
- representative longitude; and
- coordinate basis.

All rows in one file must identify the same scheme and version. Memberships
must be complete, unique, non-empty, and attributable to resolved physical
locations. Every grouped analysis site must have one internally consistent
representative coordinate and coordinate basis across its membership rows.

The selected file must be captured as immutable, checksum-bound input
evidence. The exact internal filename, field spelling, schema identifier,
configuration shape, and future public API remain implementation-packet
decisions. Goal 009 does not commit the public input contract to this
provisional representation.

No mapping file means the one-to-one physical-location identity fallback. An
explicitly selected invalid mapping is an integrity failure and never invokes
that fallback.

## Scientific data flow

The order of operations is:

```text
validated physical-location records
  -> physical-location operation and effort censoring
  -> physical-location operational detection events
  -> selected-resolution aggregation
  -> effort/coverage, richness, composition, and turnover outputs
```

Operational events must be fully defined before analysis-site aggregation.
Goal 009 maps already-defined events to an analysis site. It must not:

- recluster source records after grouping;
- merge two physical-location or deployment events;
- change the configured event-gap threshold;
- change source-row membership in an event; or
- manufacture a cross-boundary event identifier.

For Judbury, the current physical-location event construction satisfies this
order because each physical location has one deployment and the paired
locations do not overlap. This goal does not claim to solve the more general
case of repeated deployments at the same physical coordinates. That requires
deployment-aware event construction in a later goal.

### Operation union and coverage

Daily operation is resolved at physical location first using
`data/jc_op.csv`, which remains the Judbury operation authority.

For an analysis site and date:

- the site-day is active when any contributing member is confirmed active;
- the site-day is inactive only when all relevant contributing-member states
  are confirmed inactive;
- the site-day is unknown when none is confirmed active and at least one
  relevant member state is unknown or unresolved;
- sequential member histories are joined without filling downtime gaps; and
- an approved same-date handover contributes one active site-day, never two.

Operation is therefore a union of member site-days, not a sum of camera-days.
Unknown days are neither converted to confirmed inactivity nor counted as
confirmed effort; they are reported separately where relevant. The documented
`jc_pm14` gap remains a gap.

A valid mapping that produces genuine concurrent active member deployments
makes the standard analysis-site route analytically ineligible. The workflow
must omit the affected route and explain the overlap rather than silently
collapse or double-count it. Generic concurrent-camera aggregation is
deferred.

Invalid authority, duplicate membership, orphan membership, conflicting
coordinates, or another mapping-integrity defect stops before analysis.
Scientific ineligibility is fail-soft; evidence-integrity failure is not.

## First vertical-slice modules

### Effort and sampling coverage

Report confirmed active analysis-site days, the observed temporal extent,
inactive gaps, contributing physical locations and deployments, and a compact
coverage summary at the selected resolution.

The effort definition must be explicit: one confirmed active day per selected
analysis unit and calendar date after unioning sequential member locations.
Goal 009 does not replace `jc_op` with service-file `run_days`, infer failure
causes, or fill unknown periods.

### Observed species richness

Observed richness is the number of species with at least one already-defined
operational event in the selected analysis unit over the stated temporal
scope.

It is detection-limited and effort-bounded. Goal 009 must not label it as
estimated total richness, unseen richness, occupancy, abundance, density, or
sampling-standardized richness.

### Community composition and descriptive turnover

Community composition is represented by a matrix whose rows are selected
analytical units and whose columns are species. Each analysis-site presence
cell is the logical OR, or union, of the corresponding member
physical-location presence cells. Richness is the row sum of this selected
presence/absence matrix.

Event identities and event totals remain conserved through mapping, but
site-by-species presence occurrences are not additive. Their summed count may
decrease predictably when the same species was present at two physical
locations pooled into one analysis site. Event totals may support provenance
and conservation checks, but they are not the turnover measure.

Pairwise turnover uses Jaccard dissimilarity on the presence/absence matrix:

```text
Jaccard dissimilarity = 1 - shared presences / species present in either unit
```

The result is descriptive only. Comparisons with a nonempty species union must
be symmetric and remain between zero and one; a nonempty unit compared with
itself has a zero diagonal. A comparison whose species union is empty,
including an empty unit compared with itself, is not estimable and must be
reported as `NA` rather than forced to zero or one.

Turnover outputs must carry effort and observed-completeness cautions. This
goal does not include:

- PERMANOVA or another group-comparison test;
- distance-decay regression;
- environmental or causal explanation;
- ordination;
- coverage-standardized diversity;
- unseen-richness estimation;
- Shannon or Simpson indices from event totals; or
- migration of the existing abundance-based Bray-Curtis output.

## Selected-resolution branch and compatibility

Goal 009 adds a parallel selected-resolution branch after event construction.
It must not replace the physical-location inputs shared by unrelated modules.

Only these outputs may use the new branch:

- selected-resolution effort and coverage;
- selected-resolution presence/absence composition;
- selected-resolution observed richness; and
- selected-resolution Jaccard turnover.

The following retain their current physical-location inputs and scientific
behaviour:

- relative abundance indices;
- diel summaries;
- occupancy and detection histories;
- rarefaction;
- traits and functional diversity;
- event-spacing and event-threshold diagnostics;
- exports, including CamtrapDP;
- environmental-covariate analyses;
- existing broad spatial maps; and
- other exploratory summaries.

The focused report addition may show the four new outputs and their unit
definition. It must not redesign the report or silently mix selected and
physical-location results under one unexplained `site` label.

## Output contract

Every affected output must state, directly or through an output-bound compact
metadata record:

- spatial resolution;
- scheme identifier and version;
- scheme authority or authoritative evidence basis;
- analysis-unit identifier and total unit count;
- temporal scope;
- effort definition;
- contributing physical locations;
- contributing deployments; and
- the relevant claim limitation.

Affected tables must use an explicit analytical-unit field or define the
meaning of a retained compatibility field. A bare, unexplained `site` column
is not acceptable.

The primary report states in plain language that the Judbury results combine
13 physical locations into nine analysis sites, that four representative
coordinates are synthetic midpoints, and that actual physical covariates were
not pooled. Audit and machine-readable evidence retain the complete
membership, coordinate basis, operation contribution, and event provenance.

## Observed current implementation facts

These are current facts to preserve or change deliberately, not new
scientific authority:

- `_targets.R` loads the four validated analytical tables and validates the
  Goal 007/008 entity artefacts, but entity evidence does not yet enter the
  scientific graph.
- `R/custom_funcs.R` currently pivots operation, censors observations, and
  constructs events using the compatibility `site` key. Event clustering is
  grouped by `site` and species.
- `_targets.R` currently sends `events_per_day` to
  `R/community_matrices.R`, then sends the abundance matrix to
  `R/alpha_diversity.R` and `R/beta_diversity.R`.
- `R/alpha_diversity.R` currently also computes Shannon and Simpson indices
  from event totals. Those indices are outside this goal.
- `R/beta_diversity.R` currently computes abundance-based Bray-Curtis and a
  distance-decay table. Goal 009 adds descriptive presence/absence Jaccard;
  it does not silently relabel the existing method.
- `docs/goals/007-entity-resolution/Goal.md` and
  `docs/goals/008-judbury-deployment-evidence/Goal.md` deliberately leave
  `analysis_site` unselected and prohibit analytical routing.
- The approved factual sources remain
  `docs/goals/007-entity-resolution/judbury_entity_crosswalk.csv`,
  `docs/goals/008-judbury-deployment-evidence/judbury_deployment_ledger.csv`,
  `data/jc_site.csv`, and `data/jc_op.csv`.

Changing the shared `op_long`, `events_per_day`, or community-abundance
targets globally would also change excluded modules. The implementation must
therefore preserve a separate physical-location path.

## Acceptance evidence

An implementation packet must require direct evidence for all of the
following:

### Mapping and authority

- exactly 13 Judbury physical locations map to exactly nine analysis sites;
- each participating physical location has exactly one membership;
- the four grouped memberships and nine labels match this Goal;
- the four representative midpoint coordinates match this Goal exactly;
- unmoved analysis sites retain their actual coordinates;
- actual physical coordinates and covariates remain unchanged;
- no synthetic midpoint covariate exists; and
- selected mapping bytes, scheme identity, version, digest, and authority are
  immutable and reconstructable.

### Effort and events

- selected operation is the union of member site-days, not their sum;
- confirmed downtime, including the `jc_pm14` gap, remains present;
- a unit-date with no confirmed-active member and at least one unknown or
  unresolved member remains unknown, is excluded from confirmed effort, and
  is reported separately;
- approved same-day handovers count once;
- no unapproved concurrent member operation exists in Judbury;
- every physical event maps to exactly one selected unit;
- unique event identifiers, source-row memberships, event times, species,
  and total events are conserved;
- no event is reclustered, merged, split, or regenerated; and
- per-species event totals before and after aggregation reconcile exactly.

### Ecological outputs

- the selected Judbury effort, composition, and richness outputs contain nine
  analysis units;
- selected presence has analytical units as rows and species as columns;
- every selected presence cell reconstructs as the logical OR of its member
  physical-location cells;
- richness equals the row sum of the selected presence/absence matrix;
- event identities and per-species event totals reconcile exactly, while any
  reduction in summed site-by-species presence occurrences reconciles exactly
  to duplicate member presences collapsed by the OR rule;
- Jaccard values reconstruct from the selected presence/absence matrix;
- Jaccard symmetry and bounds pass for nonempty unions, nonempty diagonals are
  zero, and empty-union comparisons are `NA`;
- all affected outputs state the required resolution and provenance fields;
  and
- the report uses plain ecological language and the accepted claim limits.

### Compatibility and reproducibility

- selecting `physical_location` reproduces the accepted physical-resolution
  behaviour for the affected slice;
- identity fallback is one-to-one and is tested independently of Judbury;
- a selected invalid mapping stops rather than falling back;
- a valid concurrent-member fixture omits the standard analysis-site route
  with a clear explanation;
- validation preview and full execution produce equivalent mapping and
  selected-resolution evidence;
- the completed bundle verifies portably after copying;
- RAI, diel, occupancy, rarefaction, traits, functional diversity, event
  diagnostics, exports, covariate outputs, and broad maps remain unchanged;
- the required local test, lint, full-run, bundle-verification, and exact-SHA
  CI gates pass; and
- one focused independent review checks scientific meaning, routing scope,
  conservation, mapping authority, and bundle evidence.

## Non-goals and deferred work

Goal 009 does not:

- define automatic, radius, or proximity-based grouping;
- solve repeated deployments at the same physical coordinates;
- aggregate genuinely concurrent cameras;
- pool or infer environmental covariates;
- alter event construction or its threshold;
- change RAI, diel, occupancy, rarefaction, traits, functional diversity, or
  export behaviour;
- introduce inferential turnover modelling;
- standardize richness or turnover by coverage;
- estimate unseen richness;
- redesign the whole report;
- define a stable public mapping API or migration policy;
- build a GUI; or
- claim that the broader Phase 3 or standard evidence profile is complete.

## Review and stopping policy

The implementation should deliver this single vertical slice, run the
proportionate acceptance gate, and receive one focused independent review. At
most one focused repair pass should follow if the review identifies a
material defect. A second pass is justified only by a remaining failure in an
explicit acceptance criterion, scientific integrity, data integrity, or
portable reproducibility.

Stop once the high-value core is verified. Do not widen the goal into adjacent
modules, generalized deployment handling, covariate policy, automatic
grouping, report redesign, or residual cosmetic polish.
