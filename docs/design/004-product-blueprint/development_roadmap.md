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
  and all scientific outputs are preserved. Barry approved the exact Goal 008
  packet, source, ledger, packet commit, and authority reference on
  2026-07-27. Its 13-deployment audit-evidence core is accepted and published
  as implementation `377c0fd4f78513885a3f2b53308e788bfa8d1cb4`;
  independent review passed with non-blocking notes and exact-SHA workflow
  `ci` run `30253764770` concluded `success`.
  Goal 009 is the accepted and published third bounded slice. Core
  implementation `3d0f23ac0cbabdeef780144a0fad261d2ce366be` was followed by
  test-only portability repair `d0594861e8941f4496989de4ab1c8a6e66f9b889`;
  that final repair SHA passed workflow `30716777969` with conclusion `success`.
- **Exit evidence:** Both adapters complete core QC/effort/event paths;
  optional fields remain unknown; profile precedence and named scales persist;
  zero versus unknown is invariant; reviewed inference is uncertain and
  overrideable.
- **Non-goals:** Selecting final public fields, extending Judbury grouping
  beyond the exact bounded Goal 009 proposal, selecting inferential
  thresholds, or removing the strict compatibility profile.
- **Decision gate:** Barry approved the exact factual
  13-physical-to-nine-nominal Judbury crosswalk for Goal 007 and the separate
  exact Judbury deployment/service packet for Goal 008. Goal 008 keeps
  `analysis_site` grouping and analytical routing forbidden; full resolved
  profiles, adapter completion, and public schema/API commitments remain later
  Phase 3 work with their own evidence and authority gates. Literal-`NA`-only
  rejection and blank-token negative tests are required before approving a
  different service source, generalized reader reuse, or another deployment
  profile.
  Barry approved the exact Goal 009 mapping, packet, allowlist, subjects, and
  boundaries on 2026-08-01. Exact packet commit
  `183bb7a80e54abb8dd59ec7f2c2a31dda72e5bc4` activated implementation; Goal
  009 is now complete, published, and exact-SHA-CI-confirmed.

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

## Current closeout and next-goal direction

Phases 1 and 2 are complete, and Goal 007 is accepted and published as the
first bounded Phase 3 slice.

Goal 008 is the second completed bounded Phase 3 slice. Barry approved the
complete packet, normalized service source, deployment ledger, packet commit,
and combined authority reference. Published implementation
`377c0fd4f78513885a3f2b53308e788bfa8d1cb4` binds the service dates to 13
explicit day-precision deployments and four directed chronology relations
while keeping daily operation separate. Local acceptance and independent
review passed with one non-blocking direct-reader note; exact-SHA workflow
`ci` run `30253764770` concluded `success`.

Goal 008 keeps `analysis_site` unselected with zero memberships and does not
reroute effort, observations, operational events, denominators, or analytical
modules. Resolved profile precedence, conservative scientific routing, the
CamtrapDP exporter envelope, full adapter completion, and purpose-specific
grouping remain later work with their own authority and evidence gates.
Before any different deployment source or broader reader reuse, the service
reader must reject blank missing tokens and test literal-`NA`-only behavior.

Goal 008 is closed.

Goal 009 is accepted and published under packet
`183bb7a80e54abb8dd59ec7f2c2a31dda72e5bc4` and mapping SHA-256
`6490d7f7021e5c727b9be1c7d6dfbf44ba50a1ef5b0396c66e1dd813a9c77083`.
Core implementation `3d0f23ac0cbabdeef780144a0fad261d2ce366be`
preserves the legacy graph and adds the bounded post-event route. First CI run
`30713505836` failed only at a platform-dependent bundle-test assertion;
test-only repair `d0594861e8941f4496989de4ab1c8a6e66f9b889` passed final exact-SHA
workflow `30716777969`. The slice remains limited to confirmed effort,
observed detection-limited richness/presence, and descriptive Jaccard not
standardized for unequal effort, completeness, or detectability. It makes no
abundance, density, inferential, pooled-covariate, or generalized-grouping
claim and does not complete Phase 3.

Barry authorized and implementation has completed for Goal 010's ruthless
test-value and runtime audit. The default suite is now the pruned fast profile;
current publication contracts run explicitly at release, and the real Judbury
evidence run is no longer repeated inside test fixtures. The surface fell from
7,556 to 4,929 lines and from 26 executed production-runner invocations to two.
Independent review found no Goal010-introduced scientific or data-integrity
loss. Exact-SHA CI, manual release, and emitted-bundle reconstruction remain
pending. The next architecture decision should address the fail-closed zero-row
preview serializer and missing physical-location identity in CamtrapDP
deployment lineage, without reopening deleted historical coverage.
