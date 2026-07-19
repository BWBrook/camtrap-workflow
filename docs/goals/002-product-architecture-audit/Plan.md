# Goal 002 execution plan

## Phase 1 - Establish the evidence baseline

- [ ] Read repository-local `AGENTS.md`, the complete Goal 001 packet, and the accepted readiness log first.
- [ ] Capture Camtrap Workflow branch, HEAD, tracking state, clean status, remotes, and top-level source/document structure without mutating Git or generated state.
- [ ] Record whether representative ignored Goal 001 artefacts remain available and treat absence as an evidence limitation rather than a reason to rebuild.
- [ ] Define the audit's fact, inference, recommendation, and uncertainty labels plus its inventory-status thresholds before classifying the system.

Outcome: a stable audit baseline and explicit evidence standard.

## Phase 2 - Reconstruct the current system

- [ ] Inventory every `R/*.R` file, every target declared in `_targets.R`, every configuration profile, relevant test and report source, public entrypoint, schema, and principal output surface.
- [ ] Trace the actual data flow and target DAG from external data and configuration through validation, event derivation, effort, analyses, reports, manifests, and reusable artefacts.
- [ ] Reconstruct the current user journey, recording all requirements for R knowledge, shell knowledge, network access, manual intervention, mutable state, and hidden assumptions.
- [ ] Reconcile implementation against tests, documentation, and existing artefacts; record contradictions and orphaned surfaces.
- [ ] Complete `module_inventory.csv` and report coverage counts and exclusions.

Outcome: an evidence-backed current-state architecture and complete coverage reconciliation.

## Phase 3 - Evaluate product and scientific fitness

- [ ] Map every agreed product-contract requirement to current evidence, a concrete gap, or an explicitly deferred choice.
- [ ] Evaluate configuration-only use, progressive CSV and CamtrapDP inputs, immutable raw data and runs, fail-soft modules, repair auditing, spatial and temporal schemes, effort semantics, reporting, provenance, offline operation, and interface neutrality.
- [ ] Build the Judbury question-evidence matrix for sampling adequacy, richness, turnover, selected-species patterns, and regional-context extension.
- [ ] Classify each proposed Judbury use as defensible, illustrative only, underpowered, unsuitable, or a candidate extension.
- [ ] Explicitly assess nine-site inference, occupancy, relative-abundance language, clock drift, relocations, unequal effort, missingness, and regional-record biases.

Outcome: a restrained scientific demonstration envelope and a product-contract conformance map.

## Phase 4 - Define the LocalMap_Tas boundary

- [ ] Confirm LocalMap_Tas state without reconciling it and read its `AGENTS.md` before the authorized bounded documentation and public-interface surface.
- [ ] Identify the smallest useful site/covariate and provenance interchange based on existing evidence.
- [ ] Allocate ownership for coordinate validation, extraction, transformation, map production, identifiers, versioning, errors, and provenance without coupling repositories.
- [ ] Record missing contracts as gaps rather than inventing final schemas or APIs.
- [ ] Complete `localmap_boundary.md` with explicit non-goals and decisions deferred to later work.

Outcome: a bounded upstream integration model that preserves independent repositories and responsibilities.

## Phase 5 - Rank debt and recommend renovation

- [ ] Consolidate evidence-backed gaps in `gap_register.csv` and rank them by scientific risk, user friction, architectural leverage, and estimated effort.
- [ ] Distinguish working domain knowledge to protect from obsolete, duplicated, tightly coupled, Judbury-specific, documentation-only, and missing surfaces.
- [ ] Draw an implementation-neutral recommended architecture with one engine shared by standard, guided, advanced, CLI, and future graphical interfaces.
- [ ] Define a no-regrets first renovation tranche that can proceed before Goal 003.
- [ ] Separate decisions that require the external horizon scan, Barry's scientific judgment, stakeholder discovery, or a future implementation spike.
- [ ] Complete `renovation_roadmap.md` with measurable acceptance evidence and stop rules for each phase.

Outcome: a decision-ready renovation strategy rather than a broad rewrite mandate.

## Phase 6 - Package, validate, and stop

- [ ] Complete `Audit.md` with current and recommended architecture diagrams, current user journey, major findings, coverage reconciliation, recommendation, and deferred decisions.
- [ ] Validate Markdown paths and internal cross-references.
- [ ] Validate CSV headers, rectangular shape, primary-key uniqueness, enum values, and required evidence fields using static tools only.
- [ ] Scan the audit package for unresolved markers and empty required sections.
- [ ] Run `git diff --check` and prove that only the authorized audit directory and Goal 002 log changed during execution.
- [ ] Perform one focused review and repair pass for material defects.
- [ ] Update `Log.md` with exact evidence, validation outcomes, residual uncertainty, and publication recommendation; do not commit or push.

Outcome: a coherent audit package ready for orchestrator review.

The execution stops without implementation. It also stops and reports rather than broadening scope when a material conclusion requires external research, runtime validation, sensitive-data inspection, or a decision reserved for Barry or Goal 003.
