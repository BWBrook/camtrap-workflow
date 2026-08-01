# Goal 009 execution runbook - analysis-site ecological vertical slice

## Purpose and current authority

This runbook governs a proposed bounded Phase 3 ecological slice. It selects a
named spatial resolution for four descriptive outputs while preserving every
existing physical-location analytical path.

The packet state is:

```text
AUTHORIZED_CONDITIONAL_ON_EXACT_PACKET_PUBLICATION
```

On 2026-08-01, after receiving the exact packet/hash summary and
ecologist-facing Goal explanation, Barry approved:

1. the reviewed eight-path Goal 009 packet;
2. the exact mapping bytes, schema, scheme ID, version, state, SHA-256, and
   authority reference;
3. the closed future implementation allowlist in `Plan.md`;
4. packet publication subject
   `docs: define Goal 009 analysis-site vertical slice`; and
5. later implementation publication subject
   `feat: add analysis-site ecological slice`.

This is exact conditional execution authority. It becomes operable only after
packet publication satisfies every exact commit, parent, path, subject, and
mapping-fixity condition below. No additional Barry message is required when
all conditions match.

## Packet-publication gate

Barry's recorded receipt authorizes the orchestrator to publish the exact
packet through this gate. From `/Users/bwbrook/git/camtrap-workflow`, require:

```sh
pwd
git branch --show-current
git rev-parse HEAD
git rev-parse origin/main
git status --short --branch --untracked-files=all
git diff --name-status
git diff --cached --name-status
shasum -a 256 \
  docs/goals/009-analysis-site-vertical-slice/judbury_analysis_site_mapping.csv
```

Before publication require:

- branch `main`;
- HEAD and locally known `origin/main` exactly
  `c0ed40377af4aa0162098913e2c097da65eadc42`;
- empty index;
- exactly the eight packet paths listed in `Log.md`;
- no other worktree change; and
- mapping SHA-256 exactly
  `6490d7f7021e5c727b9be1c7d6dfbf44ba50a1ef5b0396c66e1dd813a9c77083`.

Publish one commit with subject:

```text
docs: define Goal 009 analysis-site vertical slice
```

After publication require `HEAD^` equal to the authoring baseline,
`git diff --name-status HEAD^..HEAD` equal to the exact eight packet paths,
the subject unchanged, and the mapping digest unchanged. Do not fetch, reset,
clean, stash, amend, merge, or reconcile a mismatch.

## Exact implementation-authority gate

Before the first implementation edit, verify the publication outcome against
Barry's recorded conditional approval:

```sh
git status --short --branch
git rev-parse HEAD
git rev-parse HEAD^
git rev-parse origin/main
git show -s --format='%H%n%P%n%s' HEAD
git diff --name-status HEAD^..HEAD
shasum -a 256 \
  docs/goals/009-analysis-site-vertical-slice/judbury_analysis_site_mapping.csv
shasum -a 256 \
  docs/goals/007-entity-resolution/judbury_entity_crosswalk.csv
shasum -a 256 \
  docs/goals/008-judbury-deployment-evidence/judbury_deployment_ledger.csv
shasum -a 256 data/jc_op.csv
```

Require clean synchronized `main`, HEAD equal to `origin/main`, parent exactly
`c0ed40377af4aa0162098913e2c097da65eadc42`, subject exactly
`docs: define Goal 009 analysis-site vertical slice`, exactly the eight packet
paths in the parent diff, and:

```text
judbury_analysis_site_mapping.csv
6490d7f7021e5c727b9be1c7d6dfbf44ba50a1ef5b0396c66e1dd813a9c77083

judbury_entity_crosswalk.csv
553abada14493f3a5f0ae3c072523b6d5cc0d0c6a6c6480ca17a9e3331f2d8ec

judbury_deployment_ledger.csv
0921eb8845c2bb1ad5760271f283ab2783735b7739e254c67e9243bc906f3ebf

data/jc_op.csv
28222586fa232fccc46bfab5e8c07e0c453f07387ebe4eb95b9a90e4687033a3
```

The recorded receipt binds this exact mapping authority:

```text
schema: camtrap-analysis-site-mapping/1.0
scheme: judbury-analysis-site
version: 1.0.0-proposed
state: proposed_for_barry_exact_approval
authority: goal009-judbury-analysis-site-mapping-sha256-6490d7f7021e5c727b9be1c7d6dfbf44ba50a1ef5b0396c66e1dd813a9c77083
```

The receipt already approves the closed allowlist and publication boundaries
conditionally on this exact publication outcome. A changed parent, path set,
subject, packet, or mapping does not satisfy the authority and must stop for a
revised packet and renewed exact approval.

## Structured mapping gate

Use a structured CSV parser against the immutable packet file:

```sh
Rscript - <<'RS'
path <- "docs/goals/009-analysis-site-vertical-slice/judbury_analysis_site_mapping.csv"
x <- read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)

expected_physical <- c(
  "jc_cen", "jc_co1", "jc_co1_s1", "jc_co2", "jc_co3",
  "jc_co3_s16", "jc_co4", "jc_pm12", "jc_pm14", "jc_pm14_s1",
  "jc_pm23", "jc_pm34", "jc_pm34_s15"
)
expected_analysis <- c(
  "jc_cen", "jc_co1", "jc_co1", "jc_co2", "jc_co3",
  "jc_co3", "jc_co4", "jc_pm12", "jc_pm14", "jc_pm14",
  "jc_pm23", "jc_pm34", "jc_pm34"
)
expected_midpoints <- data.frame(
  analysis_site_id = c("jc_co1", "jc_co3", "jc_pm14", "jc_pm34"),
  representative_latitude = c(
    -42.9974400, -43.0004650, -42.9996600, -43.0012590
  ),
  representative_longitude = c(
    146.9394450, 146.9477700, 146.9401500, 146.9447415
  )
)

stopifnot(
  identical(
    names(x),
    c(
      "analysis_site_mapping_schema", "scheme_id", "scheme_version",
      "authority_state", "analysis_site_id", "physical_location_id",
      "representative_latitude", "representative_longitude",
      "coordinate_basis"
    )
  ),
  nrow(x) == 13L,
  identical(x$physical_location_id, expected_physical),
  identical(x$analysis_site_id, expected_analysis),
  length(unique(x$physical_location_id)) == 13L,
  length(unique(x$analysis_site_id)) == 9L,
  all(x$analysis_site_mapping_schema ==
    "camtrap-analysis-site-mapping/1.0"),
  all(x$scheme_id == "judbury-analysis-site"),
  all(x$scheme_version == "1.0.0-proposed"),
  all(x$authority_state == "proposed_for_barry_exact_approval")
)

observed_midpoints <- unique(x[
  x$analysis_site_id %in% expected_midpoints$analysis_site_id,
  c(
    "analysis_site_id", "representative_latitude",
    "representative_longitude"
  )
])
observed_midpoints <- observed_midpoints[
  match(expected_midpoints$analysis_site_id, observed_midpoints$analysis_site_id),
]
rownames(observed_midpoints) <- NULL
stopifnot(isTRUE(all.equal(
  observed_midpoints,
  expected_midpoints,
  tolerance = 0,
  check.attributes = TRUE
)))
RS
```

Also inspect all nine analysis sites directly. Require unmoved coordinates to
equal their physical coordinates, grouped coordinate bases to be fixed
synthetic midpoints, unmoved bases to be actual physical coordinates, and no
covariate field.

## Locked configuration contract

The standard Judbury and CamtrapDP-export profiles select:

```yaml
analysis_unit:
  resolution: "analysis_site"
  mapping_profile_id: "judbury-analysis-site/1.0.0-proposed"
  mapping_path: "docs/goals/009-analysis-site-vertical-slice/judbury_analysis_site_mapping.csv"
  mapping_sha256: "6490d7f7021e5c727b9be1c7d6dfbf44ba50a1ef5b0396c66e1dd813a9c77083"
  authority_reference: "goal009-judbury-analysis-site-mapping-sha256-6490d7f7021e5c727b9be1c7d6dfbf44ba50a1ef5b0396c66e1dd813a9c77083"
```

The template, forest, and CamtrapDP-ingestion examples select:

```yaml
analysis_unit:
  resolution: "physical_location"
  mapping_profile_id: null
  mapping_path: null
  mapping_sha256: null
  authority_reference: null
```

The resolution vocabulary is closed to:

```text
analysis_site
physical_location
nominal_station
```

For `analysis_site`, all four mapping fields are selected or all four are
null. All-null resolves to:

```text
scheme_id: camtrap-physical-location-identity
scheme_version: 1.0.0
state: built_in_default
authority: camtrap-workflow-built-in-physical-location-identity/1.0.0
```

`read_config()` must normalize that identity into deterministic resolved
provenance written to effective configuration. It must not add
`analysis_unit` to `default_config()`. A truly omitted block remains absent
and preserves legacy physical behaviour and schemas.

Direct physical and nominal selections require four null mapping fields.
Physical selection cites the built-in physical identity. Nominal selection
must resolve authoritative nominal membership from the selected entity
evidence; absent authority makes only the selected route ineligible, while
malformed or conflicting evidence is an integrity failure. No direct
resolution may carry an analysis-site mapping profile.

Every explicit mode uses:

```text
camtrap-validation-preview/1.2
camtrap-evidence-manifest/1.3
```

Only omitted-block legacy invocations retain current schema selection.
Portable verification must continue accepting preview 1.0/1.1 and manifest
1.0/1.1/1.2.

## Pre-edit baseline capture

After exact authority passes and before production edits, create ignored
evidence directories:

```sh
mkdir -p \
  outputs/goal009_acceptance/pre \
  outputs/goal009_acceptance/fixtures \
  outputs/goal009_acceptance/post \
  outputs/goal009_acceptance/review
```

Capture Git, approval, mapping, config, and latest-pointer evidence:

```sh
git status --short --branch \
  > outputs/goal009_acceptance/pre/git-status.txt
git rev-parse HEAD HEAD^ origin/main \
  > outputs/goal009_acceptance/pre/git-identities.txt
git show -s --format='%H%n%P%n%s' HEAD \
  > outputs/goal009_acceptance/pre/packet-commit.txt
git diff --name-status HEAD^..HEAD \
  > outputs/goal009_acceptance/pre/packet-paths.txt
shasum -a 256 \
  docs/goals/009-analysis-site-vertical-slice/judbury_analysis_site_mapping.csv \
  docs/goals/007-entity-resolution/judbury_entity_crosswalk.csv \
  docs/goals/008-judbury-deployment-evidence/judbury_deployment_ledger.csv \
  data/jc_op.csv \
  > outputs/goal009_acceptance/pre/authority-sha256.txt

if test -f outputs/latest; then
  cp outputs/latest outputs/goal009_acceptance/pre/latest.before
else
  printf '%s\n' ABSENT \
    > outputs/goal009_acceptance/pre/latest.before
fi
```

Run and retain a fresh validation-only baseline:

```sh
Rscript scripts/run_full_evidence_run.R \
  --config config.yml \
  --validate-only \
  2>&1 | tee outputs/goal009_acceptance/pre/validate-only.log
```

Require ready preview 1.1, no scientific targets, no completion record, and
unchanged latest bytes.

Run, retain, resolve, and verify a fresh full baseline:

```sh
Rscript scripts/run_full_evidence_run.R \
  --config config.yml \
  2>&1 | tee outputs/goal009_acceptance/pre/full-run.log

BASELINE_RUN_ID="$(tr -d '\r\n' < outputs/latest)"
BASELINE_BUNDLE="outputs/runs/$BASELINE_RUN_ID"
Rscript scripts/run_full_evidence_run.R \
  --verify-bundle "$BASELINE_BUNDLE" \
  2>&1 | tee outputs/goal009_acceptance/pre/verify-bundle.log
printf '%s\n' "$BASELINE_RUN_ID" \
  > outputs/goal009_acceptance/pre/baseline-run-id.txt
```

Require manifest 1.2 and preserve:

- all four validated input objects and exact `validated_inputs.rds`;
- every Phase 2 file, row disposition, source-row membership, repair state,
  and event-lineage record;
- all five Goal 007/008 entity artefacts and semantic reconstruction;
- exact `op_long`, `obs_events`, event membership, `events_per_day`, effort,
  methods, event threshold, and gap rule;
- all current legacy table output bytes where deterministic;
- semantic values, dimensions, types, missingness, and keys for RAI, diel,
  occupancy, rarefaction, traits, functional diversity, event diagnostics,
  exports, covariate results, broad maps, and physical community/alpha/beta
  outputs;
- manifest output map, payload, source/config/engine identities, latest bytes,
  target metadata, and raw command logs; and
- current report/methods text for later scoped-diff review.

Stop before editing if either supported path, portable verifier, latest
boundary, Goal 007/008 reconstruction, four-table identity, or comparator
capture fails.

## Roles and mutation boundary

The implementation owner may touch only the exact allowlist in `Plan.md`.
The mapping and `Goal.md`, `Plan.md`, and `Runbook.md` are immutable
implementation authorities. The Goal Log and project records may be updated
with observed evidence.

The orchestrator owns:

- authority and baseline acceptance;
- independent reconstruction and review;
- exact-path staging;
- implementation commit and push; and
- exact-SHA CI confirmation.

Barry owns any changed mapping, coordinate, scientific unit, concurrency
policy, effort definition, event semantics, additional module, inferential
claim, public API, or publication-boundary decision.

## One RED gate

Before production edits, add the complete focused contract and run:

```sh
Rscript -e 'for (f in c(
  "tests/testthat/test_config_identity.R",
  "tests/testthat/test_source_inventory.R",
  "tests/testthat/test_selected_resolution.R",
  "tests/testthat/test_community_matrices.R",
  "tests/testthat/test_alpha_diversity.R",
  "tests/testthat/test_beta_diversity.R",
  "tests/testthat/test_validation_ledger.R",
  "tests/testthat/test_run_bundle.R",
  "tests/testthat/test_run_manifest.R",
  "tests/testthat/test_pipeline_smoke.R"
)) testthat::test_file(f, stop_on_failure = FALSE)'
```

Record raw output under `outputs/goal009_acceptance/fixtures/`. Accept RED only
when failures are absent Goal 009 contracts. Existing-contract regression,
malformed synthetic evidence, or an unrelated error is not an acceptable RED
state.

## Runtime state and gate semantics

For an explicit mode, preflight must resolve and record:

```text
integrity_ok
route_eligible
resolution
scheme_id
scheme_version
authority_reference
membership_count
analysis_unit_count
physical_location_count
operation_state_counts
event_count
source_row_membership_count
reasons
claim_limits
```

`integrity_ok` is part of the global non-waivable analysis gate. It is false
for invalid configuration, source fixity, authority, membership, coordinates,
event conservation, source-row cross-links, namespace, or reconstruction.
The full run stops before targets.

`route_eligible` controls only the selected ecological branch. It is false for
a scientifically valid but unsupported route, including genuine concurrent
active member cameras or absent authoritative nominal membership. Legacy
physical analyses continue. The status and four provenance files still exist;
the four selected data files do not, and their manifest links are explicit
nulls.

Do not overload `can_analyze` to erase this distinction.

## Selected provenance contract

Every explicit validation-only and full preflight contains exactly:

```text
provenance/selected_resolution/membership.csv
provenance/selected_resolution/operation.csv
provenance/selected_resolution/event_map.csv
provenance/selected_resolution/summary.json
```

The preview/full files must be byte-identical for the same resolved inputs and
engine-independent semantics, apart from invocation identity fields that are
explicitly normalized in comparison.

`event_map.csv` must be derived from:

```text
validation_state$event_lineage$obs_events
```

It must not be derived from `events_per_day` or the compact event ledger. Each
event row cross-links the Phase 2 source-row membership and records unchanged
event ID, physical location, selected unit, species, event time, deployment
where resolved, and membership digest/reference. Reconstruct:

- one selected membership per event;
- identical unique event set;
- identical source-row memberships;
- identical total and per-species event counts; and
- no split, merge, reclustering, regeneration, or cross-boundary event ID.

Do not add a Goal 007/008 entity artefact or modify the five-file entity
namespace.

## Operation and concurrency reconstruction

Resolve daily operation at physical location from `jc_op` first. For each
selected unit-date:

| Member evidence | Selected state |
| --- | --- |
| at least one confirmed active (`1`) | active (`1`) |
| no active and every relevant member confirmed inactive (`0`) | inactive (`0`) |
| no active and at least one relevant member unknown/unresolved (`NA`) | unknown (`NA`) |

Confirmed effort is the count of unique selected-unit dates in state `1`, not
the sum of camera-days. Unknown is not inactive and is not confirmed effort.
Do not fill downtime.

Use exact Goal 008 predecessor/successor lineage to classify approved
same-date handovers. The `jc_co1` boundary contributes one active unit-day.
The `jc_pm14` interruption remains a gap. Suffixes, proximity, coordinates,
event dates, or effort runs cannot classify a handover.

A distinct pair of grouped physical members genuinely active on the same
date without an approved handover makes the selected route ineligible.
Do not collapse, sum, choose one member, or stop unrelated legacy analysis.

## Ecological-output contract

An eligible completed run writes:

```text
tables/selected_effort_coverage.csv
tables/selected_community_presence.csv
tables/selected_observed_richness.csv
tables/selected_jaccard.csv
tables/selected_resolution_status.json
```

An ineligible completed run writes only
`tables/selected_resolution_status.json`.

Every output or its bound status metadata records selected resolution, scheme,
version, authority, analytical unit, total unit count, temporal scope, effort
definition, contributing physical locations/deployments, and claim limits.

The presence table uses one row per analytical unit and one column per
species. A cell is the logical OR of member physical presences. Richness is its
row sum. The reduction in summed site-by-species occurrences must equal the
reconstructed number of member duplicate presences collapsed by OR.

Jaccard dissimilarity is:

```text
1 - shared presences / species present in either unit
```

For nonempty unions it is symmetric and bounded in `[0, 1]`; nonempty
diagonals are zero. Empty-union comparisons, including an empty unit with
itself, are `NA`.

Do not compute unseen richness, coverage standardization, abundance, Shannon,
Simpson, Bray-Curtis, distance-decay, ordination, PERMANOVA, or environmental
explanation in this branch.

## GREEN and full acceptance ladder

After implementation, run the focused gate once:

```sh
Rscript -e 'for (f in c(
  "tests/testthat/test_config_identity.R",
  "tests/testthat/test_source_inventory.R",
  "tests/testthat/test_selected_resolution.R",
  "tests/testthat/test_community_matrices.R",
  "tests/testthat/test_alpha_diversity.R",
  "tests/testthat/test_beta_diversity.R",
  "tests/testthat/test_validation_ledger.R",
  "tests/testthat/test_run_bundle.R",
  "tests/testthat/test_run_manifest.R",
  "tests/testthat/test_pipeline_smoke.R"
)) testthat::test_file(f)'
```

Then run:

```sh
Rscript scripts/run_lint.R \
  2>&1 | tee outputs/goal009_acceptance/post/lint.log
Rscript scripts/run_tests.R \
  2>&1 | tee outputs/goal009_acceptance/post/tests.log
```

Require zero failures and only already-understood warnings.

Run a fresh selected validation preview:

```sh
cp outputs/latest outputs/goal009_acceptance/post/latest.before-preview
Rscript scripts/run_full_evidence_run.R \
  --config config.yml \
  --validate-only \
  2>&1 | tee outputs/goal009_acceptance/post/validate-only.log
cmp \
  outputs/latest \
  outputs/goal009_acceptance/post/latest.before-preview
```

Require ready preview 1.2, exact selected provenance, no selected ecological
files, no completion record, and unchanged latest.

Run and verify a fresh full bundle:

```sh
Rscript scripts/run_full_evidence_run.R \
  --config config.yml \
  2>&1 | tee outputs/goal009_acceptance/post/full-run.log
GOAL009_RUN_ID="$(tr -d '\r\n' < outputs/latest)"
GOAL009_BUNDLE="outputs/runs/$GOAL009_RUN_ID"
Rscript scripts/run_full_evidence_run.R \
  --verify-bundle "$GOAL009_BUNDLE" \
  2>&1 | tee outputs/goal009_acceptance/post/verify-bundle.log
printf '%s\n' "$GOAL009_RUN_ID" \
  > outputs/goal009_acceptance/post/run-id.txt
```

Require manifest 1.3, terminal completion, five selected outputs, four
selected provenance files, verified payload, and latest equal to the verified
run ID.

Copy and verify portably:

```sh
PORTABLE_ROOT="$(mktemp -d)"
cp -R "$GOAL009_BUNDLE" "$PORTABLE_ROOT/bundle"
Rscript scripts/run_full_evidence_run.R \
  --verify-bundle "$PORTABLE_ROOT/bundle" \
  2>&1 | tee outputs/goal009_acceptance/post/verify-copy.log
rm -rf "$PORTABLE_ROOT"
```

Also run supported explicit identity, direct physical, direct nominal,
invalid-mapping, and valid-concurrency controls from test-owned temporary
configs. Require preview 1.2/manifest 1.3 for every explicit mode, identity
one-to-one behaviour, physical compatibility, authoritative nominal routing
or explained omission, global stop for invalid mapping, and fail-soft selected
omission for concurrency.

## Independent scientific reconstruction

Independently reconstruct from immutable inputs rather than trusting runtime
summary booleans:

1. exact 13-to-nine membership and four midpoint coordinates;
2. no synthetic covariate and unchanged physical coordinates/covariates;
3. daily operation union, unknown treatment, `jc_co1` handover once, and
   `jc_pm14` gap;
4. full event IDs, event times, species, source-row memberships, total events,
   and per-species event totals;
5. selected presence by OR and exact duplicate-presence reduction;
6. richness as presence row sums;
7. every Jaccard pair, symmetry, bounds, diagonals, and empty unions;
8. output metadata, claim limits, route status, and null-link behaviour; and
9. preview/full selected-provenance parity.

Store reconstruction scripts, raw comparisons, and conclusions only in
ignored `outputs/goal009_acceptance/review/`.

## Compatibility and boundary evidence

Prove the legacy branch still consumes the same physical:

```text
op_long
obs_events
events_per_day
```

Prove unchanged scientific behaviour for RAI, diel, occupancy, detection
history, rarefaction, traits, functional diversity, event diagnostics,
CamtrapDP export, environmental covariates, broad maps, and legacy community,
alpha, and beta outputs. The focused report/methods additions are the only
intended legacy artefact changes.

Require:

- validation-only never writes `COMPLETED.json` or advances latest;
- an integrity failure stops before target execution;
- selected-route ineligibility does not stop legacy targets;
- a partial target call remains unpublished;
- only a verified full bundle advances latest;
- mapping and source mutation fail even after payload checksum reclosure;
- preview 1.0/1.1 and manifest 1.0/1.1/1.2 fixtures still verify; and
- final changed paths are a subset of the closed future allowlist.

## Independent implementation review

Provide one reviewer the packet, mapping digest, exact diff, RED/GREEN logs,
baseline comparator, selected preview and bundle, reconstruction evidence, and
portable copy. Ask for a verdict on:

- scientific unit and claim meaning;
- mapping and authority fixity;
- physical operation before selected union;
- full-event and source-row provenance;
- integrity versus route eligibility;
- event and presence conservation;
- Jaccard edge cases;
- excluded-module invariance;
- schema compatibility and namespace closure;
- report language; and
- portable verification.

Apply at most one focused material repair. Rerun affected tests and the full
required gate. A second pass is allowed only for a remaining explicit
acceptance, scientific-integrity, data-integrity, or portability failure.

## Implementation publication and exact-SHA CI

After local acceptance and independent review, require:

```sh
git status --short --branch --untracked-files=all
git diff --name-status
git diff --cached --name-status
git diff --check
```

The orchestrator stages exact accepted allowlisted paths, commits once with:

```text
feat: add analysis-site ecological slice
```

Push the exact implementation SHA and inspect the matching GitHub Actions
`ci` run. Require workflow, branch, head SHA, test/lint/full-run/bundle steps,
artefact upload, and conclusion `success`. A successful run for another SHA is
not confirmation.

Record packet SHA, implementation SHA, mapping SHA, preview/full run IDs,
review verdict, CI URL/run/job IDs, residual limitations, and next tranche in
the Goal Log and project log. Only then mark Goal 009 accepted and published.

## Stop conditions

Stop and return evidence when:

- the packet, mapping, authority receipt, branch, SHA, or allowlist differs;
- a baseline, latest, Goal 007/008, Phase 2, event, effort, or excluded-module
  comparator fails;
- implementation needs an unlisted path or new dependency;
- invalid authority or evidence would require a fallback;
- event construction, deployment interpretation, covariates, excluded
  modules, or exporter behaviour would change;
- a second material repair would be needed without an explicit acceptance
  failure; or
- two consecutive attempts provide no material new evidence.

Do not widen into automatic/radius grouping, repeated-deployment
generalization, concurrent-camera aggregation, covariate pooling, new
ecological modules, public API/migration, GUI work, or report redesign.
