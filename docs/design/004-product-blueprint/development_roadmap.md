# Goal 004 development roadmap

This dependency order is implementation-neutral. It preserves the current
engine, uses compatibility adapters around existing functions, and leaves
Barry-owned scientific and product choices reversible. The capability map's
`target_phase` values follow this order; a capability never depends on a later
phase.

## Phase 1 — Immutable evidence run and maintenance separation

- **Outcome:** Every run has explicit source/content identities, one traceable
  invocation identity, a versioned manifest, a replaceable `latest` pointer,
  and no scientific-run mutation of repository-maintenance artefacts.
- **Dependencies:** Baseline gate and acceptance of this blueprint.
- **Exit evidence:** Changed input bytes are visible in the source inventory;
  prior evidence is preserved; directory, manifest, and result identities
  agree; output/configuration identities and maintenance separation are
  recorded.
- **Non-goals:** Public schema/API, analytical method changes, GUI,
  deployment, or removal of current engine surfaces.
- **Decision gate:** Accepted policy is one unique run ID per invocation;
  content hashes identify equivalent inputs and may support explicit evidence
  reuse, but distinct invocations are never collapsed or erased. Barry has
  authorized this Phase 1 implementation goal.

## Phase 2 — Validation, repair preview, and source-row lineage

- **Outcome:** Core integrity checks stop unsafe runs; proposed semantic repair
  is previewed and approved; every retained event/value remains traceable to a
  source row.
- **Dependencies:** Phase 1 source inventory and run identity.
- **Exit evidence:** Clean, repair, and integrity-failure fixtures show a
  before/after ledger, approval basis, row lineage, and allowed stop behaviour.
- **Non-goals:** New ecological methods, automatic destructive repair, or a
  public field list.
- **Decision gate:** Accepted 2026-07-23. Semantic repair defaults to preview;
  filling an unknown requires exact reviewed approval; explicit supplied
  deployment/operational evidence requires proposal-specific approval plus a
  reason and cannot be overridden broadly. Original, proposal, decision,
  application, and post-validation states remain auditable. Phase 2 adds no
  production operational-period inference algorithm.

## Phase 3 — Entities, profiles, effort, events, and CamtrapDP adapter

- **Outcome:** CSV and CamtrapDP adapters resolve a small core while keeping
  nominal station, physical location, deployment, and analysis_site distinct;
  effort/time QC and operational events use conservative interval evidence.
- **Dependencies:** Phases 1–2 and compatibility boundaries; public fields
  and ecological grouping remain unselected.
- **Delivery state:** Phase 3 is not complete. Goal 007, its first bounded
  vertical slice, is accepted and published: versioned entity records, typed
  links, explicit unresolved states, immutable bundle evidence, and audit-only
  join readiness run in both supported paths. Independent review passed and
  exact-SHA CI confirmed implementation
  `bbe5c36f4b6f138f7ae5cdf2bd947e1bf42b0c30`. Current effort/event routing
  and all scientific outputs are preserved.
- **Exit evidence:** Both adapters complete core QC/effort/event paths;
  optional fields remain unknown; profile precedence and named scales persist;
  zero versus unknown is invariant; reviewed inference is uncertain and
  overrideable.
- **Non-goals:** Selecting final public fields, Judbury grouping, thresholds,
  or removing the strict compatibility profile.
- **Decision gate:** Barry approved the exact factual
  13-physical-to-nine-nominal Judbury crosswalk for Goal 007. Authoritative
  deployment/service evidence is now proposed in Goal 008 under separate exact
  source, ledger, packet, and authority-reference gates. Independent packet
  review returned `PASS_PACKET`, but the packet is not yet published, approved,
  or implemented. `analysis_site` grouping, effort/event routing, full resolved
  profiles, adapter completion, and public schema/API commitments remain later
  Phase 3 work with their own evidence and authority gates.

## Phase 4 — Capability planner and module-status envelope

- **Outcome:** A pre-run capability plan evaluates prerequisites and each
  requested module returns `completed`, `completed_with_warnings`, `omitted`,
  or `failed` without erasing unrelated successes.
- **Dependencies:** Phase 3 resolved entities, profile, effort, and event
  contracts.
- **Exit evidence:** Clean, omission, and integrity-failure fixtures show
  prerequisites, consequences, remediation, warnings, inputs, outputs, and
  named spatial/temporal schemes.
- **Non-goals:** Changing scientific methods, selecting inferential thresholds,
  or adding interface technology.
- **Decision gate:** Confirm the status vocabulary and the accepted invariant
  that analytical omission is fail-soft while integrity failure stops.

## Phase 5 — Standard evidence modules and output partition

- **Outcome:** Effort/time QC, operational-event sensitivity, observed
  richness, descriptive turnover, within-survey relative detection, and
  coarse day/night form a bounded standard profile with separate primary,
  audit, and machine layers; occupancy and traits remain conditional.
- **Dependencies:** Phase 4 capability and status contracts.
- **Exit evidence:** Every module names analytical unit, spatial/temporal
  resolution, effort basis, minimum-cell or eligibility checks, claim limits,
  and consistent cross-layer status; inferential modules omit when gates fail.
- **Non-goals:** New occupancy/trait methods, ALA/gamma estimation, paper
  claims, or AI interpretation.
- **Decision gate:** Barry resolves exact standard-profile membership,
  eligibility thresholds, and consequential claim boundaries.

## Phase 6 — Independent LocalMap file-plus-manifest boundary

- **Outcome:** Spatial/covariate inputs are consumed only through validated
  files plus a manifest with fixity, provenance, CRS, and explicit error states.
- **Dependencies:** Phase 3 entity contract and Phase 5 output/status layers.
- **Exit evidence:** JUD-16-style mutation blocks the affected capability with
  attributable status; both repositories remain independently versioned and
  no shared DAG/cache or hidden network call is needed.
- **Non-goals:** Repository merger, service coupling, or automatic regional
  inference.
- **Decision gate:** Barry selects the final interchange format after the
  manifest evidence is reviewed.

## Phase 7 — Authoritative CLI and local-interface comparison

- **Outcome:** The CLI and machine-readable contract are authoritative; a
  bounded comparison tests local interface approaches against the same
  resolved engine contract.
- **Dependencies:** Phases 1–6 and stakeholder operating-system evidence.
- **Exit evidence:** Standard/guided/advanced views resolve identical engine
  choices; pre-run validation/capability preview is visible; local/offline
  operation and lifecycle implications are documented for each candidate.
- **Non-goals:** Selecting a GUI toolkit, universal installer, hosted service,
  or container-first practitioner workflow in this blueprint.
- **Decision gate:** Barry selects interface and deployment posture after the
  comparison and stakeholder evidence.

## Phase 8 — Portability, software-note bar, and later optional extensions

- **Outcome:** Judbury plus an independent or synthetic CamtrapDP case and a
  LocalMap boundary case support a bounded software-product validation claim;
  ALA/regional and AI extensions remain downstream options only.
- **Dependencies:** Phases 1–6 and stable reference fixtures; Phase 7 only
  if an interface claim is made.
- **Exit evidence:** Repeatability, failure/omission fixtures, numerical
  comparisons where appropriate, provenance audits, and any egress/review
  controls are recorded without first/only or universal claims.
- **Non-goals:** Journal selection, publication submission, raw ALA counts as
  gamma diversity, unreviewed AI prose, or broad agency certification.
- **Decision gate:** Barry decides the independent case, software-note claim
  and release bar, and whether either optional extension should proceed.

## Recommended next implementation goal

Phases 1 and 2 are complete, and Goal 007 is accepted and published as the
first bounded Phase 3 slice.

Goal 008 is the proposed next slice. It binds Barry-supplied Judbury service
dates to 13 explicit day-precision deployments and four directed chronology
relations while keeping daily operation separate. Implementation remains
gated by packet publication and Barry's exact approval of the complete packet,
normalized service source, deployment ledger, packet commit, and combined
authority reference. The independent packet review has passed.

Goal 008 keeps `analysis_site` unselected with zero memberships and does not
reroute effort, observations, operational events, denominators, or analytical
modules. Resolved profile precedence, conservative scientific routing, the
CamtrapDP exporter envelope, full adapter completion, and purpose-specific
grouping remain later work with their own authority and evidence gates.
