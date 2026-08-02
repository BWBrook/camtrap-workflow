# Goal 011 Implementation Plan - Kill Your Darlings

Date: 2026-08-02

State: `COMPLETE_PUBLISHED`

Goal contract: `docs/goals/011-kill-your-darlings/Goal.md`

## Delivery posture

Execute one coherent refactor on `codex/goal011-kill-your-darlings`. Keep one
implementation owner for the coupled production surface. Internal commits are
checkpoints, not review gates. Do not preserve obsolete formats, modules, or
compatibility branches.

The root orchestrator owns final acceptance, publication, and scientific
judgement. The implementation owner must stop for a material scientific or
destructive decision, but may resolve ordinary engineering choices within the
Goal contract. No full Judbury release or remote publication occurs until the
end reviews are complete.

## Recorded starting evidence

- Branch start: `eb0c9d1da96e8834ca8478657344df97557796d5`.
- Starting test surface: 35 tracked R test files and 4,929 lines, including the
  two release-test files.
- Fast suite: 573 passes in 13.63 seconds wall time on the local Mac mini.
- Lint: clean in 5.42 seconds wall time.
- Accepted Goal 010 release: 41 minutes 48 seconds, including a 33 minute
  43 second publisher and 5 minute 37 second verifier.

These figures are comparison evidence, not targets to optimize independently.
The retained scientific workflow and its integrity protections control.

## Work package 1 - Correct the two known evidence failures

Use focused tests at existing seams before changing production behavior.

1. Add a typed empty selected-event result and carry it through resolution,
   writing, presence, richness, Jaccard, and module status. A valid mapped run
   with no operational events must complete with a plain warning, not become an
   integrity failure.
2. Keep CamtrapDP deployment identity distinct from physical-location identity
   through ingestion, entity lineage, effort resolution, event construction,
   source membership, and later analysis-site grouping. Never infer a missing
   physical location from names, coordinates, or chronology.
3. Prove both repairs with compact fixtures in the existing adapter, entity,
   selected-resolution, and community test families.

Checkpoint: the focused tests pass and event/source membership is conserved.

## Work package 2 - Delete the unearned product surface

Delete the implementations, targets, configuration, tests, report sections,
dependencies, and current documentation for:

- occupancy and detection-history modelling;
- Shannon/Simpson event-count diversity and Bray-Curtis distance decay;
- functional diversity, traits, and trait-environment analysis;
- first-detection and broad exploratory miscellany;
- automatic methods manuscripts;
- PDF/TinyTeX delivery; and
- CamtrapDP export. CamtrapDP interoperability in this release is an input
  adapter only; there is no approved export consumer or output contract.

Retain and name plainly:

- selected-resolution effort and coverage;
- observed presence and richness;
- descriptive Jaccard turnover;
- physical-location operational-event detection rate without decorative
  confidence intervals or abundance claims;
- coarse day/night summaries;
- species-accumulation diagnostics;
- a simple physical-location point map with optional explicit analysis-site
  overlay; and
- one concise HTML ecological report plus separate audit and machine-readable
  outputs.

Every candidate module must emit `completed`, `completed_with_warnings`,
`omitted`, or `failed`, with prerequisites, resolution, and a plain-language
reason. One unavailable module must not block viable modules. A failed run must
not advance `latest`.

Checkpoint: static searches and focused tests show that deleted surface is
absent from active product paths while the retained summaries preserve their
claim limits.

## Work package 3 - Make the workflow stages explicit

Implement the seven-stage flow:

1. ingest;
2. validate and optionally repair;
3. resolve entities and effort;
4. form physical-location events;
5. run eligible retained modules;
6. render report and machine-readable evidence; and
7. publish atomically.

Replace the global environment-variable/runtime-JSON handshake with an
explicit typed run request passed into a private targets environment or an
equally small explicit contract. Split the target declaration into a few
cohesive stage families if that improves legibility; do not introduce a package
or framework merely to move code around.

Compute validation, entity/effort resolution, event construction, and selected
resolution once per run. Consumers receive those products directly. Keep the
minimum defensible run identity, immutable inputs, resolved configuration,
source/event lineage, fail-closed integrity checks, fail-soft eligibility,
atomic publication, and latest-completed pointer. Remove reconstruction and
schema compatibility that serves only old bundles.

Perform one internal bundle verification before publication. The independent
release verifier later reconstructs the published scientific invariants; do
not repeatedly rebuild the same state inside one run and call that extra
assurance.

Checkpoint: a small targets smoke run executes the explicit path and publishes
a current-contract bundle without the old handshake.

## Work package 4 - Make verification and guidance match the product

Prune and consolidate tests around consequential behaviors. Delete tests whose
only purpose was removed functionality, unsupported compatibility, or repeated
structural detail. Keep high-value fixtures for validation/repair, identity and
effort, event lineage, analysis-site semantics, retained ecological arithmetic,
module statuses, and atomic publication.

Use two verification tiers:

- ordinary CI: lint, the compact fast suite, action/workflow syntax, and a small
  end-to-end smoke path, completing in under two minutes for the R fast suite;
- manual release: one exact-SHA full Judbury publisher, one independent
  published-bundle reconstruction, recorded phase timings, and successful
  artefact upload.

Remove redundant release-test scaffolding when the same protection is already
proved by the fast fixtures and final release verifier. Prune direct and
transitive dependencies only after confirming retained code no longer uses
them. Keep current user documentation compact; mark historical planning and
Goal records as historical rather than rewriting them into false currency.

Checkpoint: the test surface is no larger than 35 files or 4,929 lines, the
fast suite stays below two minutes, CI has no PDF/TinyTeX path, and active docs
describe only the retained workflow.

## Final acceptance sequence

1. Run lint, fast tests, CI syntax checks, dependency status, the small target
   smoke, deleted-surface scans, and test-surface counts.
2. Conduct one read-only ecological/scientific review and one read-only
   architecture/product review against the Goal contract.
3. Send any material findings to the implementation owner in one focused repair
   packet. Do not start a second polish cycle unless a consequential defect is
   discovered.
4. Re-run affected checks and the complete fast tier, then commit the accepted
   exact state.
5. Push the feature branch and obtain ordinary CI evidence for that SHA.
6. Run one manual exact-SHA release. Time from the start of the full Judbury
   publisher through the end of the independent verifier; provisioning,
   dependency installation, and upload are reported separately.
7. Independently reconstruct from the emitted bundle: 13 physical locations,
   nine mapped analysis sites, 9,639 operation rows, 11,572 events, 15,672
   source memberships, presence by logical OR, richness by presence row sums,
   all 81 accepted Jaccard values within `1e-12`, and unchanged physical
   covariates.
8. Require the HTML report, module-status evidence, atomic/latest semantics,
   under-15-minute measured release path, and successful artefact upload.

If the release misses the runtime bar, diagnose once and return the evidence
and decision to Barry. Do not rerun an unchanged slow path. Publish to canonical
`main` only when the accepted SHA and repository state make a non-destructive
fast-forward safe; otherwise report the feature branch and exact blocker.

## Required handoff

Report ecological meaning first: what a practitioner can now provide, what the
workflow returns, which analyses were deliberately removed, and what Judbury
proves. Then report exact SHA, checks, review outcomes, runtime evidence,
remaining material limitations, and the highest-value next tranche. Stop when
the approved core and explicit acceptance criteria are met; defer marginal
polish to Barry's next 80/20 decision.
