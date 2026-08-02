# Goal 010 - The Promise: simplify and tier the test suite

Date: 2026-08-02

## Why

The accepted Goal 009 CI spent 4,315.2 seconds in `testthat`; two files consumed
99.1% of that time. The suite had accumulated historical schemas, repeated
publication mutations, plot-existence checks, and production-scale fixture
construction that no longer earned their everyday cost.

## What changed

- Routine development now runs a fast profile; publication contracts live in a
  separate release profile.
- Ordinary CI runs lint, fast tests, and one explicit target smoke. The manual
  release job adds release tests, the full Judbury evidence run, bundle
  verification, and artefact upload.
- Historical compatibility matrices, ten plot-existence groups, duplicated
  calculations and repairs, repeated runner setup, and exact old-DAG snapshots
  were deleted rather than hidden.
- Current ecological guards remain for input validity, effort states and gaps,
  physical event formation, the approved 13-to-nine mapping, event/source
  conservation, presence/richness/Jaccard arithmetic, claim limits, and
  physical-location routing of protected analyses.
- Current publication guards retain one portable manifest 1.3 bundle, one
  payload mutation, one failed-publication preservation case, one ready
  preview, and one unauthorized-mapping hard stop.

## Measured reduction

| Measure | Before | Implemented |
|---|---:|---:|
| Test lines | 7,556 | 4,929 |
| `test_that()` blocks | 179 | 121 |
| Lexical expectation references | 782 | 660 |
| Executed production-runner invocations in tests | 26 | 2 |
| `tar_make()` calls inside testthat | at least 1 | 0 |

The release profile ran once in 8.54 seconds before review repair. The repaired
release files then passed separately in 7.1 and 2.8 seconds. The final local
fast attempt took 5.19 seconds; 557 checks passed, three skipped, and two failed
because the partial global library lacks four locked packages. Exact-SHA CI
after `renv` restoration remains authoritative.

## Review and limits

Independent re-review found no material ecological or data-integrity loss from
the pruning. Two production defects remain fail closed and are deferred:

- zero-row selected event maps cannot yet serialize a useful blocked preview;
- CamtrapDP deployment lineage does not carry the physical-location identifier
  needed for authentic grouped-site concurrency reconstruction.

The writer still reports valid concurrency as status-only, but end-to-end
genuine-concurrency bundle publication is not claimed. The real Judbury release
workflow and independent bundle reconstruction remain the final Goal 010 gate.
