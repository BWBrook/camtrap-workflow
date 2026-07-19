# Implementation-neutral renovation roadmap

## Direction

Renovate around the working engine; do not begin with a rewrite. The target is one deterministic analytical engine behind explicit ingest, capability, result, and run contracts. Existing R functions and Goal 001 technical evidence are assets to preserve.

This roadmap is a recommendation only. Goal 002 implements none of it.

## Highest-leverage first tranche

Authorize one bounded no-regrets tranche before Goal 003 only if the audit is accepted:

1. **Explicit input inventory:** make each local input or acquired package a tracked content source and hash it before parsing (`G001`, `G016`).
2. **Immutable unified run identity:** create a new run directory for each run, use the same ID in directory/report/manifest, and update `latest` only as a pointer (`G002`).
3. **Versioned manifest envelope:** record engine/profile/config/input identities, module statuses, warnings, repairs, outputs and hashes (`G017`).
4. **Capability/status shell:** evaluate module prerequisites and return exactly `completed`, `completed_with_warnings`, `omitted`, or `failed`, initially wrapping current modules without changing their methods (`G003`, `G026`).
5. **Remove hidden repository mutation:** take data-dictionary generation out of the scientific run path (`G028`).

This tranche deliberately excludes a new public schema, location/deployment migration, method change, GUI, package selection, hosted service, AI, or deprecation.

## Phase 0 - Accept and freeze the evidence baseline

**Outcome:** A reviewed audit and an implementation goal with a bounded change surface.

**Included:** Goal 002 deliverables, packet HEAD, accepted Goal 001 evidence, current compatibility behavior.

**Excluded:** all code changes and public claims.

**Acceptance evidence:**

- audit package parses and cross-references resolve;
- all 27 R files and 130 targets remain reconciled;
- Barry/orchestrator explicitly accepts or amends the no-regrets tranche;
- decisions reserved for Goal 003 remain marked deferred.

**Risks controlled:** renovation does not destroy validated behavior or silently turn audit recommendations into decisions.

**Stop/escalation:** stop if reviewers dispute the product contract, nine-location frame, or input/run-identity findings.

## Phase 1 - Secure source and run identity

**Outcome:** Every run is bound to explicit source bytes and one immutable identity.

**Included gaps:** `G001`, `G002`, `G016`, `G017`, `G028`.

**Implementation candidates:** adapter acquisition boundary, file/content targets, SHA-256 inventory, immutable staging/finalization, atomic latest pointer, versioned manifest, repository-maintenance command separation.

**Excluded/deferred:** public input schema redesign, analysis changes, UI, deployment substrate.

**Objective acceptance evidence:**

- changing any input byte invalidates ingest and all affected descendants;
- unchanged input/config/engine identities produce a traceable equivalent run without reusing a wrong source;
- local and remote-package inputs record path/URL, acquisition/cache state, timestamp and checksum;
- directory run ID, report run ID and manifest run ID are identical;
- a completed run directory cannot be overwritten by normal execution;
- `latest` resolves to an immutable run and can be replaced without changing that run;
- manifest lists input, config, engine and output hashes;
- a full run creates no tracked-repository modification.

**Risks controlled:** stale target cache, irreproducible URL input, overwritten evidence, split identity, hidden side effects.

**Stop/escalation:** stop if compatibility requires changing scientific data semantics or if a run-ID choice would commit a public API before Goal 003.

## Phase 2 - Capability, lineage and fail-soft modules

**Outcome:** Global integrity remains strict while analytically ineligible modules are omitted transparently.

**Included gaps:** `G003`, `G006`, `G008`, `G020`, `G021`, `G026`.

**Implementation candidates:** source-row IDs, immutable ingest snapshot, repair preview/ledger, ternary effort state, operational-event membership table, module prerequisite evaluator, structured result envelope.

**Excluded/deferred:** final location/deployment public schema, new analytical methods, UI technology.

**Objective acceptance evidence:**

- core corruption/key failures stop the run;
- each requested module emits exactly one allowed status;
- omission records prerequisites, consequences and remediation;
- one module failure does not erase successful unrelated results;
- every operational event resolves to one or more immutable source rows;
- safe normalization and approved semantic/destructive repair are distinguishable;
- each applied repair records source identity, before/after, rule, reason and approval basis;
- zero detection is emitted only under confirmed effort; unknown operation remains missing;
- public output language uses operational detection event, not independent animal.

**Risks controlled:** false zeros, opaque row loss, misleading file placeholders, global failure from optional science, biological overstatement.

**Stop/escalation:** stop for any repair default that changes data meaning, any destructive automatic action, or any need to infer camera-failure time from last detection.

## Phase 3 - Progressive internal model and profiles

**Outcome:** Current inputs map through compatibility adapters to a small core plus optional capability extensions.

**Included gaps:** `G004`, `G005`, `G007`, `G018`, `G023`, `G027`.

**Dependencies:** Goal 003 comparison and Barry decisions on public schema/identifiers and spatial group semantics.

**Implementation candidates:** internal location/deployment/analysis-site entities, selection-scope enum, optional verification/labelling provenance, named spatial and temporal scheme objects, versioned standard profile, resolved configuration record.

**Excluded/deferred:** removal of the existing four-table profile, final public API without comparison, Tasmania-specific core fields.

**Objective acceptance evidence:**

- existing four-table and CamtrapDP examples pass through explicit versioned adapters;
- minimal valid core data can complete core QC/effort/event outputs without Judbury covariates or traits;
- missing optional metadata remains unknown and results in capability warnings/omissions rather than global failure;
- location, deployment interval and analysis-site identifiers are distinct and auditable;
- every result names spatial resolution and temporal scheme;
- standard, guided, advanced and CLI invocations resolve byte-equivalent engine configuration for the same choices;
- input selection and verification provenance survive into the manifest and reusable outputs.

**Risks controlled:** Judbury lock-in, relocation pseudo-replication, schema fragmentation, configuration drift.

**Stop/escalation:** stop before public field/API commitment without Goal 003; require Barry for grouping and consequential sampling semantics.

## Phase 4 - Scientific profile and output partition

**Outcome:** Judbury demonstrates a restrained evidence profile and separates decisions from diagnostics.

**Included gaps:** `G009`, `G010`, `G011`, `G013`, `G022`; `G024` remains candidate-only.

**Implementation candidates:** eligibility thresholds, minimum-cell suppression, named Judbury profile, concise report, detailed audit bundle, result index, retain/omit rules for exploratory modules.

**Excluded/deferred:** new occupancy method, covariate model, ALA/gamma method, paper claims.

**Objective acceptance evidence:**

- primary profile includes effort/QC, operational events/sensitivity, observed richness/turnover, relative detection rates and coarse day/night with explicit claim boundaries;
- occupancy and covariate inference are omitted for the unresolved nine-location design unless Barry approves a documented eligibility rule;
- RAI is labelled relative detection rate and never abundance/density;
- trait-environment output is absent from primary evidence unless an objective design gate passes;
- primary report, audit bundle and reusable artefacts are distinct and manifest-linked;
- every caution/omission is consistent across report and machine status.

**Risks controlled:** runnable-but-unsuitable inference, report dilution, abundance overclaim, smooth-map overinterpretation.

**Stop/escalation:** Barry decides consequential methods, grouped-site science and paper claims. Stop if the nine-location/13-ID mapping remains unresolved for inferential use.

## Phase 5 - LocalMap interchange

**Outcome:** Camtrap consumes analysis-ready spatial covariates/maps with complete upstream provenance while both repositories remain independent.

**Included gap:** `G015` and the candidate in [localmap_boundary.md](localmap_boundary.md).

**Dependencies:** Goal 003/file-format comparison and a synthetic interface spike.

**Objective acceptance evidence:**

- versioned files plus manifest are the only coupling;
- Camtrap performs no GIS acquisition and no LocalMap network call;
- location identity and content hashes round-trip;
- placeholder state blocks ecological extraction/inference;
- result provenance resolves to LocalMap source, method, CRS and resolution;
- each repository can rerun and version independently.

**Risks controlled:** hidden code dependency, duplicate GIS ownership, untraceable covariates, Tasmania leakage.

**Stop/escalation:** stop if integration requires repository merger, shared cache/DAG, implicit site/deployment equivalence, or final public schema commitment without review.

## Phase 6 - Product interface and optional extensions

**Outcome:** A non-programmer can validate, configure, run and review the same engine through a selected local-first interface.

**Included gaps:** `G012`, `G025`, and any Goal 003 recommendations.

**Dependencies:** Goal 003 external horizon scan and explicit platform decisions.

**Candidates, not decisions:** thin local CLI/launcher, future graphical guided/advanced views, deployment bundle, optional downstream AI interpretation.

**Objective acceptance evidence:**

- user can supply data plus configuration without reading/writing R or opening RStudio;
- validation and capability preview occur before the expensive run;
- standard/guided/advanced paths use the same resolved engine configuration;
- local/offline core operation remains possible;
- any AI layer consumes completed structured results, separates computation from interpretation/speculation, records provider/model/prompt/review, and discloses egress before use.

**Risks controlled:** duplicated engines, interface lock-in, hidden data egress, hosted-service creep.

**Stop/escalation:** Barry chooses GUI/deployment posture and stakeholder commitments after Goal 003. Do not preselect Shiny, Docker-as-GUI, hosted service, or AI provider.

## Deprecation and migration rule

Goal 002 recommends no removal. A later implementation goal may label a surface deprecated only after:

- replacement behavior is accepted and evidenced;
- compatibility/migration is documented;
- retained Judbury and non-Judbury profiles reconcile;
- Barry approves consequential scientific or public-interface changes;
- rollback remains possible for at least the agreed transition period.

## Stop rule

After the no-regrets tranche and one focused repair pass, stop if further work mainly chooses public schema, method, GUI, deployment, or polish without Goal 003/Barry evidence. Change approach if two attempts produce no material new evidence or improvement.
