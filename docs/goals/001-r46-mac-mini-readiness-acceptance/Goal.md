# Goal 001 - R 4.6.0 Mac mini readiness acceptance

## Completed-state objective

Accept the existing R 4.6.0 portability bundle as an auditable project baseline after proving that it restores and runs on the Mac mini's forward-compatible R 4.6.1 host, passes the repository quality gates, completes clean native runs for all five supported example configurations, and passes equivalent Docker gates with explicit source provenance.

## Scope

- Review and classify every path already dirty at Goal 001 start.
- Validate `renv.lock` as the R 4.6.0 documented and container minimum while exercising it on host R 4.6.1.
- Validate the changed CI workflow, Dockerfile, manifest provenance fallback, generated-state policy, and readiness documentation.
- Create and maintain this goal packet and reconcile `docs/log/620_r46_mac_mini_readiness.md` with evidence rerun on 2026-07-18.
- Make only narrow repairs directly required for readiness acceptance.

## Non-goals

- No scientific-method, output-semantics, public-interface, roadmap, release-version, tag, or release-bundle changes.
- No unrelated refactoring or dependency upgrades.
- No machine-level installation or configuration changes.
- No commit, push, tag, pull request, branch switch, reset, stash, or source cleanup beyond the authorized `.DS_Store` removal.

## Review surface

- Runtime declarations and dependency state: `AGENTS.md`, `README.md`, `renv.lock`.
- Linux and container portability: `.github/workflows/ci.yml`, `Dockerfile`, `docs/container.md`.
- Provenance behavior: `R/run_manifest.R`, `tests/testthat/test_run_manifest.R`.
- Generated-state policy: `.gitignore`, `_targets/.gitignore`, deletion of `_targets/meta/meta`.
- Decision and evidence records: `docs/decisions.md`, `docs/reproducibility_benchmark.md`, `docs/log/620_r46_mac_mini_readiness.md`, and this directory.

## Validation gates

1. Capture branch, HEAD, remote, full status, diff shape, host/tool versions, and Docker daemon state.
2. Explain every inherited modified, deleted, and untracked path.
3. Parse `renv.lock`, verify its declared R version and package count, then run `renv::restore()` and `renv::status()` under host R 4.6.1.
4. Pass `scripts/run_lint.R`, `scripts/run_tests.R`, and `actionlint .github/workflows/ci.yml`.
5. From empty `_targets/` state and without relying on prior output files, complete the default, forest, template, Camtrap DP input, and Camtrap DP export pipelines. Inspect manifests and representative reports, tables, and export artefacts.
6. With a live Docker daemon, build the R 4.6.0 image with `GIT_COMMIT=b13c7fe708373cd305843a81542c047777791448-dirty`; pass container lint, tests, and a clean default pipeline; inspect manifest provenance plus HTML, PDF, and methods outputs.
7. Perform one focused diff/status self-review and record the exact publication set, proposed commit message, residual risks, and commit/push recommendation.

## Permission boundaries

- Work only in `/Users/bwbrook/git/camtrap-workflow`.
- Preserve all inherited substantive work.
- Generated and ignored `_targets/`, `outputs/`, project-library, and Docker image/cache state may be rebuilt.
- Remove the untracked root `.DS_Store` and add a narrow ignore rule.
- Do not commit or publish.

## Stop rules

Stop and report rather than repair if validation reveals a scientific-method, data-integrity, release-version, or public-contract choice; if a repair would broaden beyond portability or reproducibility; if Docker requires machine-level changes; or if two attempts produce no material new evidence.

## Final response contract

Return a status of `DONE`, `DONE_WITH_CONCERNS`, `NEEDS_CONTEXT`, or `BLOCKED`; a one-paragraph conclusion; exact changed and created paths; the `Log.md` path; commands and outcomes including warnings and artefact evidence; assumptions and uncertainty; the exact publication recommendation; and whether escalation is justified.
