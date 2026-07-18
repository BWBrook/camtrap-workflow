# Goal 001 evidence log

## Starting state

- Started: 2026-07-18 16:57 AEST.
- Repository: `/Users/bwbrook/git/camtrap-workflow`.
- Branch and tracking: `main...origin/main`, synchronized at start.
- HEAD: `b13c7fe708373cd305843a81542c047777791448`.
- Remote: `origin` at `git@github.com:BWBrook/camtrap-workflow.git`.
- Inherited dirty paths: modified `.github/workflows/ci.yml`, `AGENTS.md`, `Dockerfile`, `R/run_manifest.R`, `README.md`, `_targets/.gitignore`, `docs/container.md`, `docs/decisions.md`, `docs/reproducibility_benchmark.md`, `renv.lock`, and `tests/testthat/test_run_manifest.R`; deleted `_targets/meta/meta`; untracked `.DS_Store` and `docs/log/620_r46_mac_mini_readiness.md`.
- Starting diff: 12 tracked paths, 442 insertions and 493 deletions. The 176-line tracked target metadata deletion accounts for most removals.

## Initial classification

- Accepted readiness bundle: R 4.6.0 declarations, CI dependencies/runtime, R 4.6.0 Docker base and architecture-aware Quarto install, lock refresh, container documentation, decision/benchmark records, and readiness log.
- Accepted focused behavior change: `CAMTRAP_WORKFLOW_GIT_COMMIT` fallback in `R/run_manifest.R`, with its focused test, preserves provenance when `.git/` is absent from the Docker build context.
- Accepted generated-state change: `_targets/.gitignore` moves to a commit-nothing policy and `_targets/meta/meta` is deleted. The deleted tracked file contains stale `/home/bwbrook/git/camtrap-workflow` paths and is unsuitable as portable source evidence.
- Local-only state: root `.DS_Store`; removed under the explicit Goal 001 permission and covered by a narrow root ignore rule.
- Unexplained or blocking inherited paths: none at orientation.

## Host and lock facts

- Host check at 2026-07-18 17:00 AEST: macOS 26.5.2 build 25F84 on arm64.
- Host R/Rscript: 4.6.1 (2026-06-24), used as a forward patch compatibility check for the declared 4.6.0 minimum.
- Quarto 1.9.37; Pandoc 3.10; actionlint 1.7.12; Docker CLI 29.6.1.
- Docker daemon gate passed: Docker Desktop server 29.6.1, aarch64, 10 CPUs, 8,321,515,520 bytes assigned memory.
- `renv.lock` parses as JSON, declares R 4.6.0, uses `https://cloud.r-project.org`, and contains 139 packages.

## Chronology and outcomes

1. Captured orientation, full status, diff stat/name-status, runtime versions, Docker state, lock summary, configuration paths, and current generated state.
2. Reviewed every inherited diff. No branch/HEAD/dirty-shape mismatch and no scientific, release, data-integrity, or public-contract decision was exposed.
3. Added `.DS_Store` to the root ignore policy, removed the untracked file, and created the Goal 001 packet.
4. `Rscript -e 'renv::restore(prompt = FALSE)'` exited 0 and reported that the project library was already synchronized with the lockfile.
5. `Rscript -e 'renv::status()'` exited 0 with `No issues found -- the project is in a consistent state.` The active project library is the macOS R-4.6 arm64 library; `renv` is 1.1.5, `targets` is 1.12.0, and `testthat` is 3.3.2. A dependency scan found 308 source records against 139 locked packages.
6. `Rscript scripts/run_lint.R` exited 0 with no lints.
7. `Rscript scripts/run_tests.R` exited 0 after 40.1 seconds: 165 pass, 0 fail, 0 skip, and 1 warning.
8. The one test warning is expected and asserted by the Camtrap DP export audit test: `Dropping 1 observations with unparseable datetime for Camtrap DP export.` It is data-audit behavior, not a readiness failure.
9. `actionlint .github/workflows/ci.yml` exited 0 with no findings.
10. Each native pipeline run began with `rm -rf _targets outputs/runs/<run_id>` and therefore rebuilt 130 targets with 0 skipped; no run could pass from an old target cache or old rendered files.
11. Default `config.yml` completed in 83.61 seconds wall time. It produced 65 files, including non-empty report HTML (4,104,713 bytes), report PDF (1,670,039), methods HTML (1,204,843), and methods PDF (46,439). Representative tables contained 13 effort rows, 28 RAI rows, and 5 occupancy rows.
12. Forest `config.forest_example.yml` completed in 70.83 seconds and produced 65 files, including all four non-empty renders. Representative tables contained 6 effort rows, 6 RAI rows, and 5 occupancy rows.
13. Template `config.template_example.yml` completed in 65.57 seconds and produced 59 files, including all four non-empty renders. Representative tables contained 2 effort rows, 2 RAI rows, and 2 occupancy rows.
14. Camtrap DP input `config.camtrapdp_example.yml` fetched the upstream example, completed in 72.25 seconds, and produced 61 files, including all four non-empty renders. Representative tables contained 4 effort rows, 11 RAI rows, and 3 occupancy rows.
15. Camtrap DP export `config.camtrapdp_export.yml` completed in 87.51 seconds and produced 69 files, including all four non-empty renders. Its package validation file reports `Camtrap DP export validation: OK` and zero dropped observations. The package contains `datapackage.json`, `deployments.csv` (13 rows), `media.csv` (15,514 rows), `observations.csv` (15,694 rows), and `validation.txt`; metadata names version 1.0.1, CC-BY-4.0, and the three expected resources.
16. Every native run manifest records schema 0.1.0, the correct relative config path and MD5, relative session/output paths, and Git HEAD `b13c7fe708373cd305843a81542c047777791448`. Each `session_info.txt` records host R 4.6.1 and the arm64 macOS platform.

## Native warnings reviewed

- Default and export runs: occupancy profile confidence-interval endpoints on the boundary and functional-diversity zero distances.
- Forest: small-site LOESS span/pseudoinverse warnings in `site_map_plot` and occupancy interval endpoints on boundaries.
- Template: two rarefaction ribbon rows omitted, singular occupancy Hessians, and occupancy interval endpoints on boundaries.
- Camtrap DP input: two occupancy interval endpoints on boundaries.
- These are confined to the documented small example datasets and analysis targets. None indicates restore, path, provenance, rendering, export validation, or runtime failure.

## Docker evidence

17. A fresh `docker build --progress=plain --build-arg GIT_COMMIT=b13c7fe708373cd305843a81542c047777791448-dirty -t camtrap-workflow:goal001-r46 .` exited 0 in 1,700.14 seconds. It resolved `rocker/r-ver:4.6.0`, installed the expanded Ubuntu dependency set, selected `quarto-1.9.37-linux-arm64.deb`, installed TinyTeX 2026.07 for Linux arm64, downloaded 132 non-base lock packages, and compiled the complete R 4.6.0 project library from source.
18. Material Linux build checkpoints passed for `V8`, `jqr`, `xml2`, `curl`, `RcppEigen`, `TMB`, `ape`, `vegan`, `FD`, `igraph`, `camtrapdp`, `data.table`, `stringi`, `targets`, `testthat`, and `unmarked`. There was no repository rate-limit, compiler, linker, ABI, or resource failure.
19. Image inspection records image ID `sha256:9561f9f7db2f71a7d3d7a6386384d862a06d94a105a99a52ce42e14648621cb2`, Linux arm64, 1,184,988,221 bytes, R 4.6.0, Quarto 1.9.37, Pandoc 3.1.3, and `CAMTRAP_WORKFLOW_GIT_COMMIT=b13c7fe708373cd305843a81542c047777791448-dirty`.
20. Container lint exited 0. Container tests completed in 62.2 seconds with 165 pass, 0 fail, 0 skip, and the same one expected Camtrap DP dropped-observation audit warning.
21. The container default pipeline ran in a new container with the image's empty target store and a freshly recreated host output mount. It completed 130 targets with 0 skipped in 102.51 seconds. The only first-use informational event was TinyTeX generating its font database before successful LaTeX rendering.
22. The container run produced 65 files, including report HTML (3,295,325 bytes), report PDF (1,562,596), methods HTML (1,204,843), and methods PDF (46,413). Representative tables contain 13 effort rows, 28 RAI rows, and 5 occupancy rows.
23. The container `session_info.txt` records R 4.6.0 on `aarch64-unknown-linux-gnu`, Ubuntu 24.04.4 LTS. The manifest records schema 0.1.0, the expected config MD5 and relative paths, and exactly `b13c7fe708373cd305843a81542c047777791448-dirty`; an explicit shell assertion of that provenance passed.
24. The focused review detected that the native cold-run command `rm -rf _targets` had also removed the tracked `_targets/.gitignore`; `targets` then regenerated its default template and `meta/meta`. The intended six-line commit-nothing policy was restored, the generated tracked metadata was removed again, and the runbook was corrected to preserve `_targets/.gitignore` while clearing all other target-store contents. No scientific or runtime output was changed.

## Docker warnings reviewed

- The clean default pipeline emitted the same four occupancy profile boundary messages and five functional-diversity zero-distance messages as the native default run, summarized as two warning-producing targets.
- No Docker architecture, dependency, Quarto, TinyTeX, path, mount, manifest, or rendering warning remains unresolved.

## Final status

- Status: `DONE` at 2026-07-18 17:48 AEST.
- `git diff --check` passed with no whitespace errors.
- Final branch/HEAD remain `main` at `b13c7fe708373cd305843a81542c047777791448`, tracking `origin/main`; no fetch, commit, push, tag, pull request, branch switch, reset, or stash occurred.
- Final source shape is 13 tracked dirty paths (443 insertions, 493 deletions) plus 5 untracked publication files. Generated `_targets/` and `outputs/` contents are ignored; `.DS_Store` is absent and ignored; the local Docker image is runtime-only state.
- Every inherited dirty path is explained and accepted. The only Goal 001 repair beyond evidence/docs is the narrow root `.DS_Store` ignore rule; the focused review also restored the inherited `_targets` policy after the validation command temporarily regenerated it.

## Exact publication recommendation

Recommend staging exactly these paths after orchestrator review:

```text
.github/workflows/ci.yml
.gitignore
AGENTS.md
Dockerfile
R/run_manifest.R
README.md
_targets/.gitignore
_targets/meta/meta (deletion)
docs/container.md
docs/decisions.md
docs/goals/001-r46-mac-mini-readiness-acceptance/Goal.md
docs/goals/001-r46-mac-mini-readiness-acceptance/Log.md
docs/goals/001-r46-mac-mini-readiness-acceptance/Plan.md
docs/goals/001-r46-mac-mini-readiness-acceptance/Runbook.md
docs/log/620_r46_mac_mini_readiness.md
docs/reproducibility_benchmark.md
renv.lock
tests/testthat/test_run_manifest.R
```

Proposed commit message: `chore: accept R 4.6.0 Mac mini readiness baseline`

The evidence justifies a commit of that exact set. Push is justified after orchestrator review and commit; the resulting GitHub Actions run should be treated as the independent Ubuntu amd64 post-publication gate.

## Residual risks and escalation

- Docker acceptance directly covers Linux arm64; the architecture-aware amd64 branch and changed CI packages are syntax-checked by `actionlint` but remain unexecuted until GitHub Actions runs on `ubuntu-latest`.
- Native manifests record clean HEAD even when the source tree is dirty; for the container acceptance run, the explicit `-dirty` build argument correctly distinguishes the tested bundle. This goal does not broaden the public manifest contract to hash an arbitrary dirty diff.
- Small-data scientific warnings remain visible and documented. Goal 001 validates execution and artefact integrity, not the inferential strength of tiny exemplar occupancy or functional-diversity results.
- The remote Camtrap DP example depends on its upstream URL remaining available; it was reachable and validated during this run.
- No escalation is justified: no scientific-method, release, data-integrity, public-contract, or machine-level decision was exposed.
