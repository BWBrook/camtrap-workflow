# Goal 004 - Product blueprint

## Objective

Produce a decision-ready product blueprint and dependency-ordered roadmap for
Camtrap Workflow before implementation. The blueprint turns the accepted
post-labelling workflow into a bounded product contract, capability map,
Judbury validation matrix, development roadmap, and decision register. It is a
documentation and design goal, not an implementation goal.

## Why this goal exists

The current engine is scientifically valuable but its product boundary is not
yet explicit. Goal 004 makes the intended journey, contracts, eligibility
rules, output layers, validation evidence, and sequencing reviewable while
preserving the current engine. It converts the prior horizon and internal
evidence into an executable design packet without prematurely fixing public
interfaces or implementation details.

## Operating mode

- Work only in `/Users/bwbrook/git/camtrap-workflow`.
- This is documentation/design work under a clean, synchronized `main` gate.
- Barry authorised Goal 004 execution on 2026-07-23. After the orchestrator
  reviews, commits, and pushes the four-file packet, execution may start
  without another Barry approval gate.
- Use static validation, one non-authoring review, and at most one material
  repair pass. Do not execute the workflow, run R/tests/builds, or create a
  commit or push while preparing or executing the design outputs. Execution
  outputs remain uncommitted and unpublished pending Barry's strategic review.
- Recommendations preserve reversibility and identify decisions that remain
  with Barry.

## Baseline gate

Before execution, confirm clean synchronized `main` at the later Goal 004
packet-publication commit, with all four packet files tracked and
`c33488b719d773fe8b181a54ebe7d01bfcd73599` as an ancestor. The accepted Goal
003 baseline is an ancestor, not the required execution HEAD. If the gate
differs, stop and report the exact branch, HEAD, tracking, and status; do not
fetch or reconcile.

## Accepted decisions

### Plain product promise

Camtrap Workflow takes labelled camera-trap records and turns them into clear, reproducible ecological reports. It runs the analyses the data can support, skips those they cannot, explains why, and keeps a complete record of how every result was produced.

### Product contracts

- Accept post-labelling image rows through a simple versioned CSV contract,
  with CamtrapDP compatibility through an adapter boundary.
- Inputs are immutable. Optional audited repair produces a preview and a
  traceable repaired view; it never silently changes source rows.
- Analytical eligibility is fail-soft: ineligible modules are omitted with
  explicit reasons. Integrity failures stop the workflow.
- Standard and advanced analysis use one engine and one resolved contract,
  not parallel analytical implementations.
- Local/private operation is first; no unrequested network egress is implied.
- Produce primary, audit, and machine-readable output layers.
- Keep `nominal_grid_station`, `physical_location`, `deployment`, and derived
  `analysis_site` distinct. Named spatial and temporal scales must be visible
  in resolved configuration and outputs.

### Judbury validation facts

Use Barry's accepted Judbury design as a validation fixture, not as a grouping
decision: nine nominal stations, 13 physical locations, four camera moves, and
no ecological grouping pre-decided. The matrix must test both successful
analysis and principled omission, including conservative deployment effort.

### Portability and provenance

LocalMap is an independent file-plus-manifest boundary with a manifest of
files, identifiers, checksums/versioning, provenance, explicit error states,
and no shared DAG/cache or hidden network dependency. The software-product
note must use Judbury plus at least one other portability case.

## Scope and non-goals

### In scope

Define the input-to-report journey, product promise, entity and effort
contracts, capability tiers and dispositions, eligibility/omission behaviour,
output layers, Judbury validation, LocalMap boundary, portability evidence,
roadmap sequencing, open decisions, and the recommended next goal.

### Non-goals

Do not write code, schemas, configuration files, public fields, grouping rules,
thresholds, GUI designs, ALA/regional extensions, AI behaviour, journal or
publication claims, or an engine rewrite/deletion commitment. Preserve the
current engine and describe adapters/refactors only at design level. Do not
implement or write the next goal; recommend it only.

## Exact deliverables

Create these exact paths under `docs/design/004-product-blueprint/`:

- `ProductBlueprint.md`
- `capability_map.csv`
- `judbury_validation_matrix.csv`
- `development_roadmap.md`
- `decision_register.md`

Also append the execution record to `docs/goals/004-product-blueprint/Log.md`.
The packet consists of the four contract files above. Execution outputs are
the five design files above plus the execution update to Log.md: six changed
paths total.

## Required content

The blueprint must express the functional flow:

`input -> immutable ingest -> validation/repair preview -> entity/effort/event resolution -> capability plan -> eligible modules -> primary/audit/machine outputs`.

The capability map must use exactly these tiers: `foundation`,
`standard_profile`, `conditional`, `later_option`; and exactly these current
dispositions: `retain`, `refactor`, `quarantine`, `replace`, `new`.

The design must document post-labelling rows, CSV/CamtrapDP compatibility,
immutable input and audited repair, fail-soft eligibility versus stopping
integrity failures, one standard/advanced engine, local/private-first
delivery, three output layers, named scales, conservative deployment effort,
and the independent LocalMap manifest boundary. Judbury must cover nine
nominal stations, 13 physical locations, four moves, no grouping, and both
successful analysis and principled omission. The roadmap has no more than
eight phases and recommends, without implementing or writing, the next goal.

## Acceptance

The execution deliverables are ready for Barry's strategic review when:

- all required sections and exact deliverable paths are stated;
- the plain promise, flow, tiers, dispositions, Judbury facts, LocalMap
  boundary, portability note, and non-goals are unambiguous;
- dependency order is explicit and the roadmap contains at most eight phases;
- no implementation, public-schema, grouping, threshold, GUI, ALA, AI, or
  journal decision is smuggled into the contract;
- validation is static only, with one non-authoring review and at most one
  material repair pass;
- during execution, no stage, commit, push, R run, test, or build is performed
  for the five design outputs or the execution Log update.

## Authority and escalation

The executor may structure and clarify the design contract and recommend
sequencing. Barry retains authority over public schema/API, GUI, deployment,
scientific methods, ecological grouping, thresholds, ALA/AI scope, software
note claims, and any irreversible engine or product commitment. Escalate if the
baseline gate differs, required evidence conflicts materially, or a decision
cannot remain documentation-only and reversible.

## Review and validation

Run Markdown/CSV contract checks, path and vocabulary checks, and
`git diff --check` only. A reviewer who did not author the durable packet must
perform one read-only review; the executor may make at most one material repair
pass. Do not run code, R, tests, builds, or the analytical workflow.

## Publication

The orchestrator must review, stage the exact four packet paths, commit, and
push all four packet files with `docs: define Goal 004 product blueprint`
before execution. No execution artefact or execution Log update may be
published pending Barry's strategic review.

## Final return

Return the five exact design paths plus the execution Log update, line counts,
static checks and results, final Git status, and any assumptions or escalation.
Confirm that no other execution artefacts were authored and that no execution
stage, commit, push, R run, test, or build occurred.
