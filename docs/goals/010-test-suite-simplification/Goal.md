# Goal 010 - The Promise: simplify the test suite

Date: 2026-08-02

State: `BARRY_AUTHORIZED_FOR_EXECUTION`

## Purpose

Make routine development fast and understandable by deleting, combining, or
demoting tests that no longer earn their cost. Retain only proportionate
evidence for current ecological correctness, user-data safety, reproducibility,
and consequential publication behavior.

This is not a contest to maximize assertion counts. It is a reduction goal.

## Baseline evidence

The accepted Goal 009 SHA
`d0594861e8941f4496989de4ab1c8a6e66f9b889` passed GitHub Actions run
`30716777969`, but the job took `1h49m58s`:

- the unit-test step took `1h11m59s` and reported 881 passing expectations;
- `test_run_bundle.R` took 2,476.8 seconds;
- `test_validation_ledger.R` took 1,799.5 seconds;
- those two files consumed 99.1% of test runtime;
- every other test file together took 38.9 seconds;
- the later full evidence run and bundle verification took another 35m42s.

The suite contains 33 files, 179 `test_that()` blocks, 782 lexical expectation
calls, and 7,556 lines. These counts describe implementation volume, not
scientific assurance.

## Chosen design

Use **prune and tier**:

1. Delete historical-schema, speculative compatibility, repeated checksum-
   reclosure, plot-file-existence, and static wiring tests that have no current
   user or scientific beneficiary.
2. Combine repeated current-contract checks around small fixtures.
3. Make the fast profile the default local and push/PR suite.
4. Keep a small release-only profile for current bundle publication,
   portability, failure preservation, and one meaningful mutation control.
5. Run the real Judbury evidence build and bundle verification only in an
   explicit release workflow, not on every ordinary push.

Tiering alone is insufficient because it would merely hide the existing test
mass. Production-architecture refactoring is deferred because it is a separate
goal.

## Non-negotiable evidence

The retained suite must demonstrate, in plain ecological terms:

- labelled inputs, keys, timestamps, taxa, and effort fail clearly when invalid;
- operation union preserves active, inactive, and unknown states, retains
  downtime gaps, counts a same-day handover once, and classifies genuine
  concurrency without inventing effort;
- camera events are formed at physical locations before any site grouping;
- the approved Judbury mapping is explicit and never inferred from names or
  proximity;
- event counts and source membership are conserved through analysis-site
  mapping;
- selected presence is logical OR, richness is its row sum, and Jaccard handles
  symmetry, bounds, diagonals, and empty communities correctly;
- reports identify the analysis unit, confirmed-effort basis, contributors, and
  limits on detection, completeness, abundance, density, and inference;
- duplicate, orphaned, incomplete, or unauthorized mapping hard-stops; only a
  valid mapping with genuine concurrency may omit the selected route while
  unrelated outputs continue with an explanation;
- only the four selected outputs use `analysis_site`; RAI, diel, occupancy,
  rarefaction, traits, exports, covariates, and maps remain on physical
  locations, while synthetic midpoint coordinates are mapping/distance aids
  only and physical covariates are never pooled or re-extracted;
- validation cannot overwrite source data or advance the latest completed run;
  and
- a published current-format bundle can be copied and reopened, while one
  ordinary payload mutation and one publication failure are rejected safely.

## Scope

Allowed work is limited to:

- test files and small test fixtures;
- `scripts/run_tests.R`;
- GitHub Actions test/release orchestration;
- documentation of test purpose, commands, decisions, runtime, and results;
- exact Goal 010 records and project roadmaps.

Production `R/` behavior, scientific calculations, input/output schemas,
configuration semantics, and dependencies are protected. Evidence suggesting a
production simplification belongs in a later architecture goal.

## Success criteria

Goal 010 is complete when:

1. Every retained test file is classified as fast or release-only and has a
   plain-language purpose, beneficiary, failure prevented, and run occasion.
2. Obsolete compatibility and repeated adversarial permutations are deleted,
   not merely skipped.
3. The default command is fast and the release command is explicit.
4. Push and pull-request CI run lint, fast tests, and one small target smoke;
   expensive release work is manually invoked.
5. The exact-SHA CI fast test step completes in no more than two minutes and the
   whole ordinary CI job in no more than ten minutes. Missing either bar
   requires explicit Barry review rather than Goal completion.
6. One manual exact-SHA release workflow passes the retained release tests, full
   Judbury evidence run, copied/published bundle verification, and artifact
   upload.
7. Independent reconstruction from that emitted Judbury bundle confirms the
   13-to-nine mapping, operation-state union, event conservation, presence OR
   collapse, richness row sums, Jaccard values and edge cases, protected
   physical-location outputs, and visible report claim limits.
8. One independent review finds no material loss of scientific or data-integrity
   protection.
9. Broader architecture debt is recorded without being implemented.

Runtime targets are decision evidence, not brittle timing assertions.

## Stopping rule

Perform the high-value deletion and one focused review/repair pass. Stop when
the fast/release distinction is clear, the measured reduction is material, and
remaining changes are mainly taste or marginal line-count polishing.

Stop and return to Barry if a proposed cut requires changing scientific
behavior, public compatibility commitments, or irreversible data/publication
policy.

## Authority

After Goal 009 closeout and the agreed test-retention questions, Barry stated:

> proceed with goal 010, "The Promise"!

This authorizes the bounded prune-and-tier goal above. It does not authorize a
production-architecture rewrite or a new scientific capability.
