# Goal 009 - Packet log

- **Canonical goal state:** `COMPLETE_PUBLISHED`
- **Scientific specification state:** `BARRY_APPROVED_WRITTEN_GOAL`
- **Exact mapping state:** `APPROVED_EXACT_SHA256`
- **Packet state:** `PUBLISHED_EXACT_PACKET`
- **Execution state:** `COMPLETE`
- **Implementation publication state:** `PUBLISHED`
- **Exact-SHA CI state:** `PUBLISHED_CI_CONFIRMED`
- **Independent implementation review:**
  `I1_CLOSED / SPEC_PASS / SCIENCE_PASS / QUALITY_PASS / PUBLISH`
- **Packet date:** 2026-07-31 AEST
- **Packet-authoring baseline:** clean synchronized `main` at
  `c0ed40377af4aa0162098913e2c097da65eadc42`
- **Exact packet commit:**
  `183bb7a80e54abb8dd59ec7f2c2a31dda72e5bc4`
- **Packet subject:**
  `docs: define Goal 009 analysis-site vertical slice`
- **Locally accepted candidate content HEAD:**
  `6ca44dd6f8fd78ae9462cc6c80c0010f147a316f`
- **Core implementation commit:**
  `3d0f23ac0cbabdeef780144a0fad261d2ce366be`
- **Final accepted repair commit:**
  `d0594861e8941f4496989de4ab1c8a6e66f9b889`

## Exact packet paths

This authoring task owns exactly eight paths:

- `docs/goals/009-analysis-site-vertical-slice/Goal.md`
- `docs/goals/009-analysis-site-vertical-slice/Plan.md`
- `docs/goals/009-analysis-site-vertical-slice/Runbook.md`
- `docs/goals/009-analysis-site-vertical-slice/Log.md`
- `docs/goals/009-analysis-site-vertical-slice/judbury_analysis_site_mapping.csv`
- `docs/design/004-product-blueprint/decision_register.md`
- `docs/design/004-product-blueprint/development_roadmap.md`
- `docs/roadmap.md`

No implementation, configuration, runtime code, test, report, reference,
generated output, acceptance evidence, dependency, stage, commit, push, or
execution is part of packet authoring.

## Approval receipt

On 2026-08-01, after receiving the exact eight-path packet and mapping-hash
summary plus the ecologist-facing Goal explanation, Barry stated:

> We're in good standing. I approve you to proceed to execute goal 009 on that
> basis.

This is exact conditional approval of the reviewed packet, mapping SHA-256
`6490d7f7021e5c727b9be1c7d6dfbf44ba50a1ef5b0396c66e1dd813a9c77083`,
closed allowlist, packet subject, implementation subject, and mutation and
publication boundary. Execution authority becomes operable only if packet
publication produces one exact eight-path commit with parent
`c0ed40377af4aa0162098913e2c097da65eadc42`, unchanged mapping digest, and
subject `docs: define Goal 009 analysis-site vertical slice`. A mismatch stops
execution and requires renewed authority; no additional Barry message is
required when every condition matches.

## Scientific decision recorded

Goal 009 proposes the first ecological use of the resolved Judbury evidence:

- preserve all 13 physical locations and their deployment histories;
- group them explicitly into nine purpose-specific analysis sites for this
  bounded descriptive slice;
- union sequential member operation without filling downtime;
- map already-defined physical events without reclustering;
- report confirmed sampling coverage, observed richness, presence composition,
  and descriptive Jaccard turnover; and
- leave every other module on its existing physical-location route.

The generic default is a built-in one-to-one physical-location identity.
Grouping is never inferred from suffixes, nominal membership, proximity,
coordinates, dates, or effort patterns.

## Exact approved mapping

`judbury_analysis_site_mapping.csv` has:

- schema `camtrap-analysis-site-mapping/1.0`;
- scheme `judbury-analysis-site`;
- version `1.0.0-proposed`;
- state `proposed_for_barry_exact_approval`;
- 13 unique physical-location memberships;
- nine unique analysis sites;
- four explicit sequential pairs;
- four fixed synthetic midpoint coordinates;
- actual physical coordinates for five unmoved sites;
- no covariate field; and
- SHA-256
  `6490d7f7021e5c727b9be1c7d6dfbf44ba50a1ef5b0396c66e1dd813a9c77083`.

The proposed immutable authority reference is:

```text
goal009-judbury-analysis-site-mapping-sha256-6490d7f7021e5c727b9be1c7d6dfbf44ba50a1ef5b0396c66e1dd813a9c77083
```

At packet authoring, the mapping remained non-runtime evidence until the exact
packet-publication condition in the approval receipt was satisfied.

## Packet architecture

The packet requires:

- no `analysis_unit` entry in `default_config()`;
- true omitted-block legacy compatibility;
- explicit mapped, identity, physical, and nominal resolution modes;
- deterministic built-in identity provenance in effective configuration;
- preview 1.2 and manifest 1.3 for every explicit mode;
- retained verification of preview 1.0/1.1 and manifest 1.0/1.1/1.2;
- a parallel branch after full physical event construction;
- a closed four-file `provenance/selected_resolution/` namespace;
- event mapping from
  `validation_state$event_lineage$obs_events` with Phase 2 source-row links;
- separate global `integrity_ok` and selected `route_eligible`;
- fail-soft selected omission for genuine concurrency;
- four selected data outputs only when eligible and a status record always;
- exact event conservation and explicit OR-collapse reconciliation;
- focused report/methods additions; and
- one independent review with at most one focused material repair.

## Conditional authority gate

Barry's approval receipt is recorded above. Before implementation, the
orchestrator must verify the resulting packet commit, parent, exact eight-path
diff, subject, mapping bytes and digest, closed allowlist, and publication
boundary against that receipt. Passing the exact gate activates execution
authority without another Barry message. Any mismatch leaves implementation
unauthorized until renewed approval. The gate later passed as recorded in
Task 6.

## Authoring boundary

Packet authoring used read-only repository inspection plus edits to the eight
packet paths only. It did not run R, `renv`, tests, lint, targets, Quarto,
Docker, documentation builds, pipeline execution, bundle verification, data
processing, staging, commit, push, fetch, reset, clean, stash, merge, or
artifact generation.

## Static authoring verification

One focused static review passed:

- the final worktree change set is exactly the eight packet paths and the
  index is empty;
- the mapping digest is exactly
  `6490d7f7021e5c727b9be1c7d6dfbf44ba50a1ef5b0396c66e1dd813a9c77083`;
- structured checks find 13 rows, 13 unique physical locations, nine analysis
  sites, and one consistent schema/scheme/version/state;
- Goal 009 Markdown fences are balanced and all referenced existing paths
  resolve;
- newly authored Goal 009 files are ASCII-compatible and have no tabs,
  trailing whitespace, incomplete drafting markers, or placeholder text;
- tracked-diff whitespace validation passes;
- the packet explicitly includes omitted-block legacy behaviour, identity
  normalization in effective config, schema advancement for every explicit
  mode, separate integrity and route eligibility, fail-soft output omission,
  and full preflight-event/source-row provenance; and
- at packet authoring, the packet remained unpublished and execution authority
  remained conditional on exact packet publication.

## Future execution record

The packet-authoring checklist below is superseded by the local acceptance
record in Task 6 and the publication closeout below.

- exact approval receipt and packet SHA;
- baseline preview/full run IDs and comparator evidence;
- RED and GREEN results;
- selected preview/full parity and independent reconstruction;
- local lint, tests, full run, bundle and copied-bundle verification;
- independent review and any single focused repair;
- accepted implementation SHA;
- exact-SHA CI URL, run/job IDs, and conclusion; and
- material residual limitations and highest-value next tranche.

## Task 1B foundational RED contract

On 2026-08-01, the bounded Goal 009 RED contract was repaired in
`tests/testthat/test_selected_resolution.R` (current focused file: 334 lines).
The test file parses and its production-shaped synthetic fixture sanity checks pass before
the expected missing-interface failures are evaluated. It snapshots the
approved Judbury mapping bytes through the canonical
`analysis_site_mapping_input` inventory role, and uses inline synthetic
operation/event controls; no second tracked fixture was created.

The exact ten-file RED command from the Task 1 brief was run once with
`RENV_PATHS_LIBRARY=/Users/bwbrook/git/camtrap-workflow/renv/library`; the
complete definitive output is retained at
`outputs/goal009_acceptance/fixtures/red-command-repair-final.log`.
Existing focused files remained green: `test_config_identity.R`,
`test_source_inventory.R`, `test_community_matrices.R`,
`test_alpha_diversity.R`, `test_beta_diversity.R`,
`test_validation_ledger.R`, `test_run_bundle.R`, `test_run_manifest.R`, and
`test_pipeline_smoke.R` (the aggregate summaries were 65, 32, 4, 2, 2, 82,
68, 14, and 10 passes respectively, with no failures, warnings, or skips).
The repaired file reported 7 failures, 0 warnings,
0 skips, and 16 passes (including fixture-shape checks), all failures solely
from absent Goal 009 interfaces:

- `analysis_unit_selection` (one failure);
- `resolve_selected_resolution` (two call sites, two failures);
- `build_selected_effort_coverage` (one failure);
- `build_selected_presence` (one failure);
- `write_selected_resolution_artifacts` (one failure); and
- `validate_selected_resolution_artifacts` (one failure).

The accepted baseline remains validation-only run
`20260801T015452Z-69b995f2fc7e4f97`, full run
`20260801T015728Z-c053969875e3421d`, bundle
`outputs/runs/20260801T015728Z-c053969875e3421d`, and manifest digest
`73cede63fc9fb93ee4fa0a9e032d929d83a8e6f3ca1b84697f1a6126c4458f2e` from
`.superpowers/sdd/Plan/task-1-baseline-report.md`. The protected production
surface remains byte-identical to the baseline; the only tracked changes are
the owned test file and this log.

This RED checkpoint establishes selection, mapping integrity, operation union,
event conservation, presence OR/richness, and the closed provenance/status
contract. Jaccard edge cases are intentionally deferred to the existing
beta-diversity RED cycle in Task 4; no unlisted beta helper is locked here.
Production implementation, configuration, targets, reports, and other tests
remain out of scope for Task 1B.

## Task 2 configuration and mapping acquisition

On 2026-08-01, Task 2 added focused tests before production edits. The RED
checkpoint used:

```sh
RENV_PATHS_LIBRARY=/Users/bwbrook/git/camtrap-workflow/renv/library \
Rscript -e 'for (f in c("tests/testthat/test_config_identity.R", \
  "tests/testthat/test_source_inventory.R")) \
  testthat::test_file(f, stop_on_failure = FALSE)'
```

Before implementation, `test_config_identity.R` reported 6 failures and 66
passes for the absent `analysis_unit_selection` interface; the source-inventory
file reported 4 failures and 38 passes for absent mapping acquisition and
validation. These failures were the expected Task 2 RED classes.

The Task 2 implementation retains omitted configuration as a true legacy path,
normalizes explicit selections in `analysis_unit_resolved`, and adds the exact
mapped selection to `config.yml` and `config.camtrapdp_export.yml`. The three
example configurations use explicit `physical_location` with four null mapping
fields. Mapped runs copy one immutable
`source_snapshot/analysis_site_mapping/judbury_analysis_site_mapping.csv`
record with role `analysis_site_mapping_input`; omitted, identity, physical,
and nominal selections acquire none.

Task-scoped GREEN verification passed with 96 passes in
`test_config_identity.R` and 57 passes in `test_source_inventory.R`, with no
failures, warnings, or skips. The inventory controls cover omitted, built-in
identity, direct physical, and direct nominal selections; source symlink,
post-copy mutation with inventory reclosure, duplicate role, and extra
namespace rejection. `test_selected_resolution.R` was run with
`stop_on_failure = FALSE`: its Task 2 selection group passed, while exactly six
later Task 3/4 interface checks remained intentionally RED (the six absent
selected-resolution interfaces). The approved mapping digest remained
`6490d7f7021e5c727b9be1c7d6dfbf44ba50a1ef5b0396c66e1dd813a9c77083`.

### Task 2 focused symlink repair

The acquisition path now checks the lexical configured path before
`normalizePath()` can hide an in-root intermediate-directory symlink. A focused
test links `docs/goals/009-analysis-site-vertical-slice` to another in-root
directory containing the exact approved mapping bytes and confirms acquisition
fails closed. The focused tests remain green (96 config passes and 57 source
inventory passes, no failures/warnings/skips); the selected-resolution scope
check remains 23 passes plus exactly six intentional later-interface failures.

## Task 3 selected-resolution provenance

On 2026-08-01, Task 3 added selected-resolution provenance after physical
event construction. The immutable Judbury mapping is checked for exact bytes,
schema, complete 13-row membership, and coordinate consistency. Operation is
joined by analysis unit using a three-state union (active, inactive, unknown)
without filling gaps. Existing Phase 2 event/source-row membership is mapped
key-by-key with conservation counts and canonical digests; no event is
reclustered or renamed. Reciprocal deployment chronology authorizes only an
approved same-day boundary. Genuine simultaneous active members preserve
integrity but make the selected route ineligible with an explicit reason.

The selected-resolution membership, operation, event-map, and summary files
are published atomically under the exact four-file namespace and reconstructed
with fixity and semantic validation. Explicit validation previews use schema
1.2 while omitted legacy previews remain supported. Focused verification
passed the Task 3 selection, operation, event mapping, route-status, and
tamper checks. The remaining selected-resolution RED is the intentional Task
4 presence helper assertion.

### Task 3 bounded repair

Independent review identified four provenance gaps: nominal selections were
passing through the analysis-site reader, concurrency was not date-specific,
the four files lacked compact member/coordinate/deployment evidence, and
portable validation did not reconstruct selected state. A bounded repair added
resolution-specific nominal membership from authoritative entity links,
per-unit-date handover classification, stable coordinate/member-state/deployment
columns, canonical minimum event times, and immutable-source semantic
reconstruction during preview verification. Focused RED controls now cover
nominal positive/missing/conflicting authority, off-boundary and wrong-
precision handovers, missing lineage, row-order event times, and content/status
tampering. Task 4 ecological outputs remain deferred.

The repaired real-data validation-only run
`20260801T123456Z-0000000000000095` completed with `analysis_ready = true`.
Final focused verification reported 88 passes in
`test_validation_ledger.R` and 40 passes in `test_run_bundle.R`, with no
failures, warnings, or skips. `test_selected_resolution.R` reported 92 passes,
no warnings or skips, and exactly one intentional failure for the deferred
`build_selected_presence` Task 4 interface. The portable tamper control
reclosed membership, summary, and preview checksums and then failed at semantic
reconstruction as required.

A focused independent rereview found the four runtime/scientific findings
closed: semantic reconstruction, authoritative nominal membership,
date-specific exact-boundary handover classification, and sufficient
member/coordinate/deployment/event evidence. It identified only two
test-fixture writes that needed to unlink the deliberately tampered immutable
JSON files before recreating them. After those bounded test repairs, the full
validation-ledger replay passed. No further Task 3 architectural repair is
justified under the 80/20 stopping rule.

## Task 4 parallel ecological branch

On 2026-08-01, Task 4 added a post-event selected-resolution branch while
leaving the legacy physical-location commands unchanged. The branch validates
the four Task 3 provenance files, compares their event map directly with the
unchanged runtime `obs_events`, and writes the four selected CSVs only when
`route_eligible` is true. An explicit selected mode always writes
`selected_resolution_status.json`; an ineligible route exposes four null data
links and writes no selected CSV. Omitted legacy mode returns null selected
targets and creates no selected status file.

The inherited first RED was retained exactly: `test_selected_resolution.R`
reported 92 passes and one failure solely for the missing
`build_selected_presence()` interface. The expanded tests-only RED then failed
only for the absent Task 4 helpers and targets: selected resolution had one
failure and 92 passes; community matrices had two missing-function errors and
four passes; alpha and beta diversity each had one missing-function error and
two passes; pipeline smoke had three missing-target assertions and 13 passes.

The exact focused GREEN command was:

```sh
RENV_PATHS_LIBRARY=/Users/bwbrook/git/camtrap-workflow/renv/library \
Rscript -e 'for (f in c(
  "tests/testthat/test_selected_resolution.R",
  "tests/testthat/test_community_matrices.R",
  "tests/testthat/test_alpha_diversity.R",
  "tests/testthat/test_beta_diversity.R",
  "tests/testthat/test_pipeline_smoke.R"
)) testthat::test_file(f)'
```

It passed 157 assertions: 94 selected-resolution, 31 community-matrix, five
alpha-diversity, ten beta-diversity, and 17 pipeline-smoke assertions, with no
failures, warnings, or skips.

The production-shaped Task 3 fixture reconstructs 13 physical locations as
nine analysis units, two observed species, two conserved events, an 18-cell
selected presence matrix with two presences, richness sum two, and 27 selected
unit-date operation rows. Its full symmetric Jaccard table has 81 rows: 17
defined comparisons satisfy symmetry and bounds with the nonempty diagonal
zero, while 64 empty-union comparisons are `NA`. A separate OR-collapse
control maps three physical-location/species presences to two selected
unit/species presences, exactly reconciling one expected duplicate collapse.
The runtime-event control maps three source rows to two unchanged event IDs and
matches event ID, physical location, species, minimum event time, total count,
and per-species count exactly.

Every CSV carries explicit analytical-unit fields, scheme/version/authority,
analysis-unit count, temporal scope, effort definition, claim limit, and a
binding reference to the status record. That status record retains the
contributing physical locations and deployments for every analytical unit.
Observed richness is only the selected presence row sum. Jaccard is descriptive
presence/absence dissimilarity; no Shannon, Simpson, Bray-Curtis,
distance-decay, coverage standardisation, unseen richness, abundance,
inference, or covariate pooling enters the selected branch.

The static legacy-input control fingerprints the target inputs for `op_long`,
`obs_events`, `events_per_day`, event diagnostics, detection history,
occupancy, community/alpha/beta, traits, functional diversity, trait
associations, RAI, diel, rarefaction, CamtrapDP export, and the broad site map.
All matched the accepted Task 3 baseline, and the selected targets contain no
`events_per_day` lineage input. Task 4 did not run the full suite, a full
evidence run, lint, Quarto outside the existing focused smoke behavior, or any
external/network workflow; those remain outside this task boundary.

Independent read-only review found two bounded status-routing defects in the
first GREEN implementation. Validated selected states expose reasons under
`summary$reasons`, and integrity-failure states could reach event comparison
before status publication. The repair falls back to summary reasons and records
event conservation as explicitly unchecked only when `integrity_ok` is false;
every integrity-valid eligible or route-ineligible state still requires exact
runtime-event conservation. A deliberately nonmatching integrity-failure
fixture now produces status only with four null links. Bounded rereview closed
both findings and reported no remaining material defect.

## Task 5 manifest, report, and reference integration

On 2026-08-01, Task 5 integrated every explicit selected-resolution mode into
`camtrap-evidence-manifest/1.3`. The manifest retains the complete Phase 2 and
entity contracts, adds the exact top-level `selected_resolution` links
`membership`, `operation`, `event_map`, and `summary`, and adds five links
under `outputs.tables`. Eligible routes link the four selected CSVs plus the
status JSON. Ineligible routes retain four explicit JSON nulls, create no
selected CSVs, and still link the status record. A genuinely omitted
`analysis_unit` block remains manifest 1.2; schemas 1.0-1.2 continue to verify
under their original contracts.

Portable verification now authorizes `analysis_site_mapping_input` only for
preview 1.2 or manifest 1.3 and reconstructs selected provenance from bundled
immutable evidence. It independently reconstructs status eligibility,
reasons, contributor lists, event conservation, claim limits, link/file
cardinality, and the four ecological tables. Focused checksum-reclosed controls
changed selected membership coordinates, status eligibility, manifest null
cardinality, and observed richness; every semantic change was rejected after
payload and completion hashes were reclosed. Both eligible and ineligible
bundles verified after copying to a different root under the same run-ID
basename.

One focused independent review found that a checksum-reclosed explicit config
could initially be relabelled as preview 1.1 or manifest 1.2 and thereby evade
selected verification. Verification now derives explicit-selection state from
the bundled immutable raw config and requires preview 1.2 or manifest 1.3 in
both directions. The new downgrade controls reject both relabelled records.
The same repair moved all ecological and Judbury-specific report claims behind
the route-eligibility gate and completed the selected-resolution directory in
the documented finished-run tree.

`report/report_inputs.rds` now stores parsed selected tables and status rather
than staging paths. Report and methods sources were inspected and smoke
rendered with one explicit-mode conditional section: legacy mode omits it,
ineligible mode prints reasons without data, and eligible mode prints the four
tables. The Judbury-only sentence is gated on scheme
`judbury-analysis-site/1.0.0-proposed`: 13 physical locations are combined into
nine analysis sites, four coordinates are fixed synthetic midpoints used only
for mapping/separation, and physical covariates are not pooled. Both documents
state that effort means confirmed active site-days, richness is observed and
detection-limited, and Jaccard is a descriptive observed-presence comparison,
not standardized for unequal confirmed effort, completeness, or detectability.

The provisional contract was updated in exactly
`docs/reference/config.md`, `docs/reference/input_schema_v0.1.md`,
`docs/reference/output_schema_v0.1.md`, and
`docs/reference/run_manifest.md`; `docs/decisions.md` records the bounded
scientific route and deferred public API/migration policy.

The strict tests-first RED checkpoint reported 14 manifest passes plus one
missing-argument error, 28 bundle passes plus the expected missing manifest
1.3 integration errors, and 17 pipeline-smoke passes plus 11 absent wiring and
prose assertions. One test-only runtime-event fixture shape was corrected
before production implementation. The exact focused GREEN command was:

```sh
RENV_PATHS_LIBRARY=/Users/bwbrook/git/camtrap-workflow/renv/library \
Rscript -e 'for (f in c(
  "tests/testthat/test_run_manifest.R",
  "tests/testthat/test_run_bundle.R",
  "tests/testthat/test_pipeline_smoke.R"
)) testthat::test_file(f)'
```

It passed 156 assertions: 27 manifest, 96 bundle, and 33 pipeline-smoke, with
no failures, warnings, or skips. `git diff --check` passed. Task 5 did not run
the full suite, a full evidence run, standalone Quarto, lint, CI/network
workflows, or a generated acceptance build.

## Task 6 local acceptance and publication boundary

Goal 009 reached local acceptance on 2026-08-02. The exact packet authority is
commit `183bb7a80e54abb8dd59ec7f2c2a31dda72e5bc4`, subject
`docs: define Goal 009 analysis-site vertical slice`, with mapping SHA-256
`6490d7f7021e5c727b9be1c7d6dfbf44ba50a1ef5b0396c66e1dd813a9c77083`.
The locally accepted candidate content was HEAD
`6ca44dd6f8fd78ae9462cc6c80c0010f147a316f`. At this checkpoint, its eventual
implementation publication commit was not yet known because the reviewed
candidate was to be squashed later.

The final local gate recorded:

- validation-only preview `20260801T174838Z-9c2f4e49de784718`;
- completed full run `20260801T175415Z-2cdc56dfaa02443b`;
- manifest schema 1.3 with 101 payloads and SHA-256
  `bc88e0af859ffb9529e85ed3d10989eb3fece894c91cffc26541db144d971336`;
- lint PASS and authoritative suite
  `[ FAIL 0 | WARN 1 | SKIP 0 | PASS 881 ]`, with the sole understood warning
  from the CamtrapDP unparseable-datetime fixture;
- direct, copied, and accepted-baseline bundle verification PASS;
- protected legacy comparison PASS at 6/6 global checks and 8/8 protected
  objects; the ignored macOS derivative changed only the absent-path
  `Sys.readlink` guard; and
- independent scientific reconstruction PASS at 26/26 checks: 13 physical
  locations became nine sites; 9,639 unit-days comprised 7,644 active and
  1,995 inactive days; 11,572 events were conserved; 177 physical presence
  cells became 150 selected cells; and the full Jaccard output contained 81
  rows.

After the final claim repair, independent review returned `I1_CLOSED`,
`SPEC_PASS`, `SCIENCE_PASS`, `QUALITY_PASS`, and `PUBLISH`. `PUBLISH` is the
review disposition for the later closeout step, not evidence that publication
or CI has occurred.

Ecological interpretation remains deliberately narrow. Effort means confirmed
effort only; richness and presence are observed and detection-limited; and
Jaccard is a descriptive observed-presence comparison, not standardized for
unequal confirmed effort, completeness, or detectability. Goal 009 makes no
claim about pooled covariates, abundance or density, unseen richness,
inference, or generalized concurrency or grouping.

At this local-acceptance checkpoint, exact-path squash, publication, and
exact-SHA GitHub Actions remained pending. The publication closeout below
supersedes that historical state.

## Approved next-goal direction

Barry directed that Goal 010 must be a ruthless test-value and runtime audit
before further feature work. No test is presumed necessary because it exists.
Each retained test must state the real failure it prevents, who or what
benefits, when it runs, why a user or developer can understand it, and its
runtime and resource trade-off. Tests should be removed, combined, simplified,
or demoted wherever practical under a default subtraction rule; a fast everyday
suite and slower release-grade integration should remain distinct only where
retained value justifies cost.

Compatibility, provenance, bundle, tamper, and publication tests require
concrete current-project justification; engineering best practice alone is
insufficient. The audit must preserve proportionate safeguards for scientific
correctness, data integrity, destructive or irreversible publication, and
reproducibility. This records approved next-goal direction only: no Goal 010
Goal, Plan, or Runbook is authored here, and no test change is authorized or
implemented.

## Publication and exact-SHA CI closeout

Goal 009 was published as core implementation commit
`3d0f23ac0cbabdeef780144a0fad261d2ce366be`, subject
`feat: add analysis-site ecological slice`, with packet
`183bb7a80e54abb8dd59ec7f2c2a31dda72e5bc4` as its sole parent. The core
commit contains the locally accepted candidate content recorded at
`6ca44dd6f8fd78ae9462cc6c80c0010f147a316f`.

The first exact-SHA workflow run `30713505836`, job `91405028902`, ran against
head SHA exactly `3d0f23ac0cbabdeef780144a0fad261d2ce366be` and failed after
`1h22m36s` at one platform-dependent `test_run_bundle` assertion. The unit-test
summary was `[ FAIL 1 | WARN 1 | SKIP 0 | PASS 880 ]`; the warning was the sole
expected CamtrapDP unparseable-datetime fixture warning, and later workflow
steps were skipped. The failure was a test portability defect and did not
implicate the Goal 009 implementation.

A test-only repair was published as
`d0594861e8941f4496989de4ab1c8a6e66f9b889`, subject
`test: make manifest drift control portable`, with the core implementation as
its sole parent. Exact-SHA GitHub Actions then completed successfully in
[`30716777969`](https://github.com/BWBrook/camtrap-workflow/actions/runs/30716777969),
job `91413569305`, head SHA exactly
`d0594861e8941f4496989de4ab1c8a6e66f9b889`, duration `1h49m58s`.

The passing workflow recorded:

- lint success in 19 seconds;
- unit tests in `1h11m59s` with
  `[ FAIL 0 | WARN 1 | SKIP 0 | PASS 881 ]` and the sole expected CamtrapDP
  unparseable-datetime fixture warning;
- `test_run_bundle` PASS at 99/99 and pipeline smoke PASS in 8 seconds;
- full immutable run `20260801T213517Z-e179fbf11da94f40` in `30m40s`;
- bundle verification in `5m02s`, `valid = true`, with 101 payloads and
  manifest SHA-256
  `d931901848bdba29777653a910fd2e2ec13327784dd9018c54c1b040e18da53c`;
  and
- uploaded artifact `8824757010`: 39,917,667 bytes, 104 files, ZIP SHA-256
  `57b3380c6b4b1517e581e678b5083cbeb92f088d6529dcf5dfd9a64946e14fe4`.

Goal 009 is complete, accepted, published, and exact-SHA-CI-confirmed at final
repair SHA `d0594861e8941f4496989de4ab1c8a6e66f9b889`. The core scientific
implementation remains `3d0f23ac0cbabdeef780144a0fad261d2ce366be`; the final
commit changes only the platform-dependent test control.

Scientific interpretation is unchanged: confirmed effort only; observed,
detection-limited richness and presence; and descriptive Jaccard not
standardized for unequal confirmed effort, completeness, or detectability.
Goal 009 makes no abundance, density, inference, pooled-covariate, or
generalized-grouping claim. The approved Goal 010 test-value/runtime audit
direction remains unchanged, with no Goal 010 packet or implementation yet.
