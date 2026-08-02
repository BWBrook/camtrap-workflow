# Goal 010 - Test value and runtime audit

Date: 2026-08-02

State: `TASK_1_DECISIONS_FROZEN`

## Reading this audit

This audit starts from subtraction. A test earns retention only when a current
developer, data custodian, ecologist, report reader, or bundle recipient can
name the failure it prevents. Historical implementation volume is not evidence
of scientific value.

The accepted Linux baseline is 4,315.2 seconds for all tests. Rows 20 and 32
alone took 2,476.8 and 1,799.5 seconds, or 99.1% of that time. The other 31
files together took 38.9 seconds; the accepted log does not preserve reliable
per-file timings for them. In the table, `remainder` means membership in that
38.9-second group. Line and `test_that()` block counts describe maintenance
surface only. They do not measure quality, assurance, or importance.

Decision meanings:

- **retain fast**: keep a small current-contract test in the default suite;
- **retain release**: keep the case only in the explicit release suite;
- **simplify/combine**: keep the named protection but delete duplication,
  historical cases, or implementation-detail assertions;
- **delete**: remove the current test without replacement; and
- **none**: no resulting run profile.

## File-by-file decisions

| ID | Current test file | Purpose and beneficiary | Real failure prevented | Observed cost | Frozen decision, resulting profile, and rationale |
|---:|---|---|---|---|---|
| 1 | `tests/testthat/test_alpha_diversity.R` | Checks ordinary alpha-diversity output and selected observed richness for ecologists. | Negative or incorrectly summed richness reaching tables and reports. | 40 lines, 3 blocks; remainder. | **simplify/combine**, fast. Retain one ordinary alpha calculation. Move the selected row-sum contract into the single selected-community test at row 5 and delete the plot-existence block. |
| 2 | `tests/testthat/test_beta_diversity.R` | Checks ordinary pairwise beta output and selected Jaccard behavior for ecologists. | Malformed pairwise output or invalid selected dissimilarities. | 67 lines, 3 blocks; remainder. | **simplify/combine**, fast. Retain one ordinary pairwise calculation. Move Jaccard symmetry, bounds, diagonal, and empty-community behavior into row 5 and delete the plot-existence block. |
| 3 | `tests/testthat/test_camtrapdp_adapter.R` | Checks CamtrapDP ingestion, explicit unknowns, references, and acquisition for CamtrapDP users and data custodians. | Silent imputation, row/reference loss, or analysis of unpinned input bytes. | 422 lines, 9 blocks; remainder. | **simplify/combine**, fast. Keep one minimal mapping case, one combined no-silent-default case, one broken-reference/collision failure, and one pinned snapshot/acquisition failure. Delete descriptor-byte duplication, repeated endpoint/default variants, and the separate cache proof once those boundaries are covered. |
| 4 | `tests/testthat/test_camtrapdp_export.R` | Checks CamtrapDP export shape and the audit trail for dropped timestamps for data recipients. | Exporting unusable tables or silently dropping invalid observations. | 145 lines, 5 blocks; remainder. | **simplify/combine**, fast. Replace three required-column blocks and the final package block with one small end-to-end export contract plus one DST-drop assertion. Make the expected warning explicit if the case remains; delete a duplicate warning path. |
| 5 | `tests/testthat/test_community_matrices.R` | Checks physical-event conservation and the four selected ecological outputs for ecologists and report readers. | Double-counted/lost events, non-OR presence, wrong richness/Jaccard, or selected output on an ineligible route. | 276 lines, 5 blocks; remainder. | **simplify/combine**, fast. Make this the one home for selected presence OR, richness row sums, Jaccard edge cases, canonical event conservation, contributor metadata, claim limits, and eligible versus concurrency status-only output. Remove duplicate arithmetic from rows 1, 2, and 23 and collapse the current writer permutations. |
| 6 | `tests/testthat/test_config_identity.R` | Checks immutable configuration identity and exact current authorities for workflow operators. | Running different bytes than recorded or accepting a partial/unauthorized current selection. | 418 lines, 11 blocks; remainder. | **simplify/combine**, fast. Keep raw-versus-resolved identity, immutable snapshot binding, and one exact rejection for each current repair, entity, deployment, and analysis-site authority. Delete legacy-default compatibility and omitted/identity/nominal mode matrices. |
| 7 | `tests/testthat/test_descriptive_outputs.R` | Checks current RAI confidence limits and diel proportions for ecologists. | Negative/incoherent RAI or proportions that do not form a distribution. | 55 lines, 4 blocks; remainder. | **simplify/combine**, fast. Retain the two calculation contracts and delete both plot-file-existence blocks. |
| 8 | `tests/testthat/test_detection_history_builder.R` | Checks occasion aggregation and effort alignment for occupancy analysts. | Detections assigned to the wrong occasion or counted without effort. | 34 lines, 1 block; remainder. | **retain fast**. It is one small behavioral case with a direct scientific beneficiary and no duplicate end-to-end builder check. |
| 9 | `tests/testthat/test_detection_history_checks.R` | Checks the explicit detection-without-effort guard for occupancy analysts. | Fitting occupancy models to detections on zero-effort occasions. | 26 lines, 2 blocks; remainder. | **retain fast**. Keep one failing and one valid alignment case; the tiny validator boundary is clearer separate from construction. |
| 10 | `tests/testthat/test_dictionary_sync.R` | Checks that the two shipped data dictionaries agree for data providers. | Users labelling columns from stale or placeholder documentation. | 27 lines, 2 blocks; remainder. | **retain fast**. This is cheap user-data safety, not scientific DAG preservation. |
| 11 | `tests/testthat/test_entity_resolution.R` | Checks explicit Judbury and CamtrapDP entity/deployment evidence for data custodians and downstream analysts. | Inferring relocations from names/proximity, accepting ambiguous deployments, or routing orphaned identities. | 947 lines, 14 blocks; remainder. | **simplify/combine**, fast. Retain the exact Judbury resolution, a generic no-inference control, one explicit CamtrapDP resolution, one duplicate/orphan failure, and one current deployment-ledger reconciliation. Delete optional-mode permutations, repeated malformed-field matrices, and repeated Goal 007/008 fixity proofs covered at rows 25 and 32. |
| 12 | `tests/testthat/test_event_outputs.R` | Checks event spacing and a basic event-count invariant for ecologists. | Misreported temporal separation or more event rows than detections. | 52 lines, 3 blocks; remainder. | **simplify/combine**, fast. Retain both computations and delete the plot-file-existence block. |
| 13 | `tests/testthat/test_exploratory_outputs.R` | Checks current species, first-detection, and multi-species-image summaries for ecologists. | Inflated image/species counts, calendar-day rather than active-day waits, or incorrect descriptive summaries. | 144 lines, 3 blocks; remainder. | **retain fast**. The three cases cover distinct current outputs with small fixtures and no retained publication runner. |
| 14 | `tests/testthat/test_functional_diversity.R` | Checks functional-diversity output shape and finite metrics for trait analysts. | Returning missing site rows or unusable functional metrics. | 25 lines, 1 block; remainder. | **retain fast**. One bounded current calculation earns its small cost. |
| 15 | `tests/testthat/test_input_contract.R` | Checks required labels, taxa fields, effort values, and timestamps for data providers and operators. | Invalid tables entering analysis without a clear early error. | 71 lines, 5 blocks; remainder. | **retain fast**. These are named non-negotiable user-data failures; keep the valid fixture and the four distinct invalid boundaries. |
| 16 | `tests/testthat/test_occasion_length_sensitivity.R` | Checks the current occasion-length sensitivity calculation for occupancy analysts. | Missing species/occasion combinations in sensitivity results. | 44 lines, 2 blocks; remainder. | **simplify/combine**, fast. Keep the calculation and delete the plot-file-existence block. |
| 17 | `tests/testthat/test_occupancy_models.R` | Checks species selection, effort-aware model frames, covariate screening, fitted detection probability, and naive occupancy for occupancy analysts. | Misaligned effort/model matrices or invalid current occupancy summaries. | 98 lines, 5 blocks; remainder. | **retain fast**. Each case covers a distinct current model boundary and the whole 31-file remainder is already cheap. |
| 18 | `tests/testthat/test_pipeline_smoke.R` | Previously mixed target execution, graph snapshots, report wording, and legacy preservation for developers and report readers. | The valuable failures are missing claim limits or analysis-site routing leaking transitively into protected physical outputs. | 341 lines, 9 blocks; remainder, plus duplicated target work in CI. | **simplify/combine**, fast plus the separate ordinary-CI target smoke. Retain one report/method claim-limit contract and one transitive dependency guard: protected RAI, diel, occupancy, rarefaction, trait, export, covariate, and map targets may not inherit any `selected_*` target, and spatial carriers must retain `site_raw`. Delete the duplicate `tar_make()` test and exact old-DAG snapshots. |
| 19 | `tests/testthat/test_repair_ledger.R` | Checks explicit, digest-bound repair decisions for data custodians. | Broad/stale authority changing source values or losing changed-field lineage. | 187 lines, 6 blocks; remainder. | **simplify/combine**, fast. Keep deterministic identity, one approved/declined application, one unauthorized decision, and one tamper case. Collapse the five-way adversarial matrix and fixture-only variants. |
| 20 | `tests/testthat/test_run_bundle.R` | Currently exercises publication, portability, schemas 1.0-1.3, and many checksum-reclosed mutations for publishers and bundle recipients. | The current valuable failures are overwrite/latest corruption, a non-portable current bundle, and acceptance of an ordinary changed payload. | 1,424 lines, 20 blocks; 2,476.8 seconds. | **simplify/combine**, fast and release. Delete this monolithic file after extraction. Keep only the pure machine-epsilon comparator in fast tests. In release tests keep one current-format publish/copy/reopen case, one ordinary payload mutation rejection, and one injected publication failure that preserves the prior latest. Delete historical manifest cases, downgrade dispatch, symlink/path matrices, Goal 008-only bundles, schema-per-ledger loops, and checksum-reclosure permutations. |
| 21 | `tests/testthat/test_run_identity.R` | Checks unique filesystem-safe run IDs for workflow operators. | Run collision or path traversal through a run identifier. | 29 lines, 2 blocks; remainder. | **retain fast**. Keep the fixed-clock uniqueness case and one unsafe-path rejection group. |
| 22 | `tests/testthat/test_run_manifest.R` | Previously checked historical manifest construction and commit metadata for publishers. | Publishing a non-portable current eligible bundle or losing container-provided commit identity. | 391 lines, 4 blocks; remainder. | **simplify/combine**, fast and release. Keep the cheap commit-metadata unit and one semantically reconstructed current manifest 1.3 eligible publication contract. The retained writer test proves status-only omission; the deleted nominal-station “ineligible” fixture was not evidence for current analysis-site concurrency. Authentic concurrency publication remains recorded production/testability debt rather than a mocked test. |
| 23 | `tests/testthat/test_selected_resolution.R` | Checks the approved mapping, effort union, handover/concurrency, event lineage, and selected artifacts for Judbury ecologists. | Inferred or malformed grouping, invented effort, double-counted handovers/events, or treating concurrency as valid selected output. | 473 lines, 10 blocks; remainder. | **simplify/combine**, fast. Retain current mapped analysis-site behavior only: exact 13-to-nine membership, no inference, three-state operation union and gaps, same-day handover once, genuine concurrency ineligible, physical event formation before mapping, source-membership/event conservation, and one grouped mapping hard-stop covering duplicate, orphaned, incomplete, and unauthorized inputs. Keep one current artifact reconstruction case. Delete pre-implementation scaffolding, fixture-shape assertions, legacy omitted/identity/direct/nominal modes, parity re-writes, and duplicate presence arithmetic. |
| 24 | `tests/testthat/test_sensitivity_outputs.R` | Checks monotonic event-threshold sensitivity for ecologists. | Reporting more independent events after widening the grouping threshold. | 38 lines, 2 blocks; remainder. | **simplify/combine**, fast. Keep the monotonic calculation and delete the plot-file-existence block. |
| 25 | `tests/testthat/test_source_inventory.R` | Checks immutable parser, entity, deployment, and approved mapping inputs for data custodians and bundle recipients. | Analysis using changed, undeclared, missing, or unauthorized source bytes. | 492 lines, 12 blocks; remainder. | **simplify/combine**, fast. Keep one four-table snapshot, one exact analysis-site mapping snapshot and authority failure, one combined current sidecar snapshot, and one source mutation. Delete omitted/identity/nominal inventory modes, reclosed mapping records, and repeated duplicate/symlink/fixity permutations once each boundary has one meaningful failure. |
| 26 | `tests/testthat/test_source_row_lineage.R` | Checks deterministic source-row identity for four-table and CamtrapDP users. | Losing the link from an analytical observation back to its immutable source row. | 218 lines, 4 blocks; remainder. | **simplify/combine**, fast. Retain deterministic identity, one changed-source control, one malformed/duplicate lineage rejection, and a minimal CamtrapDP parser-order case; reduce repeated identity assertions. |
| 27 | `tests/testthat/test_spatial_outputs.R` | Only checks that a site-map PNG exists for a developer. | It does not establish that the map is correct, legible, or scientifically honest. | 20 lines, 1 block; remainder. | **delete**, none. The release evidence build already exercises map creation; semantic map review belongs to artifact review, not a file-existence assertion. |
| 28 | `tests/testthat/test_template_dataset.R` | Checks that both shipped example datasets satisfy the input contract for new users. | A documented starter dataset failing on first use. | 27 lines, 2 blocks; remainder. | **retain fast**. Both examples are current user surfaces and cheap to validate. |
| 29 | `tests/testthat/test_time_qc.R` | Checks backward clocks, parse failures, DST gaps, and fixed offsets for data custodians. | Invalid or ambiguously shifted event times entering analysis unnoticed. | 59 lines, 3 blocks; remainder. | **retain fast**. The three cases are distinct timestamp-safety boundaries named in the goal. |
| 30 | `tests/testthat/test_trait_environment.R` | Checks the current trait-environment association result for trait analysts. | Returning invalid adjusted probabilities or an unusable association table. | 27 lines, 1 block; remainder. | **retain fast**. One small current scientific calculation earns retention. |
| 31 | `tests/testthat/test_traits.R` | Checks trait normalization and species alignment for trait analysts. | Mis-cased taxa or silently omitted species contaminating trait analyses. | 23 lines, 2 blocks; remainder. | **retain fast**. These are two cheap, distinct data-alignment failures. |
| 32 | `tests/testthat/test_validation_ledger.R` | Previously mixed pure preflight/lineage checks, historical previews, repair permutations, and repeated full validation-runner calls for operators and data custodians. | The current valuable failures are analysis of invalid inputs, mutation of source evidence, or advancement of an existing latest pointer by validation. | 695 lines, 10 blocks; 1,799.5 seconds. | **simplify/combine**, fast and release. Keep small pure preflight, event-membership, and artifact round-trip controls in fast tests. Retain one current ready preview and one unauthorized-mapping hard stop in release; both preserve source bytes and seeded latest bytes. An authorized orphan mapping currently fails closed before a blocked preview can serialize and is recorded as production debt. Delete historical previews, duplicate CamtrapDP/repair cases, Goal 008 selected-versus-null comparisons, and repeated runner permutations. |
| 33 | `tests/testthat/test_workflow_primitives.R` | Checks core keys, effort, events, RAI, diel, rarefaction, and effort summaries for ecologists and developers. | Orphan keys, invented trap nights, detections outside effort, or incoherent core summaries. | 221 lines, 13 blocks; remainder. | **simplify/combine**, fast. Retain the behavioral calculations and fail-fast effort/key checks. Delete the rarefaction and effort plot-file-existence blocks and remove any exact duplicate already retained at rows 7, 9, 12, or 15. |

## High-value deletion groups

These groups are frozen for deletion or consolidation. A later task may change
the mechanics, but it may not restore a group merely to preserve historical
coverage volume.

1. **Ten plot-existence groups.** Remove alpha, distance-decay, RAI, diel,
   event-spacing, occasion-sensitivity, threshold-sensitivity, site-map,
   rarefaction, and effort-plot checks. File existence is not visual or
   scientific validation. The site-map-only file disappears completely.
2. **Historical schema compatibility.** Remove manifest 1.0-1.2 and validation
   preview 1.0/1.1 construction, relocation, downgrade, unknown-dispatch, and
   schema-per-ledger matrices. Current publication evidence uses manifest 1.3
   and the current selected preview only. No tag, public API, migration policy,
   or concrete historical consumer justifies the older matrix.
3. **Unused and legacy resolution modes.** Remove omitted analysis-unit,
   analysis-site identity-without-mapping, nominal-station, and other
   speculative compatibility permutations. Retain the current physical
   baseline behavior and the one explicitly approved Judbury mapping.
4. **Static graph preservation.** Remove exact target command/input lists,
   target-name snapshots, and string-level wiring proofs. Replace them with one
   small target smoke in CI and one compact transitive dependency guard for the
   protected physical-output routes.
5. **Repeated checksum reclosure.** Remove provenance-fingerprint matrices,
   every-ledger schema mutations, entity/deployment reclosure variants, and
   symlink/path permutations. Keep one ordinary payload mutation at release
   plus one meaningful fast fixity/authority failure at each input boundary.
6. **Repeated full runner setup.** Do not invoke a production validation run
   merely to manufacture fixtures for many bundle cases. Retain only one ready
   and one blocked current runner at release. The real Judbury build remains a
   later single release-workflow action, not test setup.
7. **Duplicated current contracts.** Collapse selected presence, richness, and
   Jaccard arithmetic; unknown CamtrapDP defaults; target-manifest checks;
   immutable-source checks; and repair-decision adversarial permutations to one
   comprehensible behavioral case per protected boundary.

## Non-negotiable invariant coverage

This is the acceptance crosswalk for later implementation. Row references point
to the table above; manual release reconstruction is evidence in addition to,
not a substitute for, the retained tests.

| Non-negotiable behavior | Retained evidence and run occasion |
|---|---|
| Labels, keys, timestamps, taxa, and effort fail clearly. | Rows 3, 15, 28, 29, and 33 in fast; one invalid-input runner control at row 32 in release. |
| Operation union retains active, inactive, and unknown, preserves gaps, counts a same-day handover once, and distinguishes genuine concurrency without invented effort. | Row 23 in fast; eligible versus status-only selected writing at row 5 in fast; Judbury's non-overlapping operation history is independently reconstructed from the release bundle. |
| Events form at physical locations before grouping. | Physical event definition at row 33 and the `obs_events`-to-event-map contract at row 23 in fast; reconstructed from the release bundle. |
| The Judbury mapping is explicit and never inferred from names or proximity. | Exact authority and no-inference controls at rows 6, 11, 23, and 25 in fast. |
| Event counts and source membership are conserved through mapping. | Rows 5, 23, and 26 in fast; independently reconstructed from the release bundle. |
| Presence is logical OR, richness is its row sum, and Jaccard has correct symmetry, bounds, diagonals, and empty-community behavior. | One consolidated current contract at row 5 in fast; independently reconstructed from the release bundle. |
| Reports name the analysis unit, confirmed-effort basis, contributors, and limits on detection, completeness, abundance, density, and inference. | Report/method contract at row 18 and output metadata at row 5 in fast; rendered claims inspected and reconstructed from the release artifact. |
| Duplicate, orphaned, incomplete, or unauthorized mapping blocks analysis; genuine concurrency only omits the selected route while unrelated outputs continue with an explanation. | Grouped mapping failures and concurrency at row 23 in fast; unauthorized-mapping hard stop at row 32 in release; status-only writer at row 5. Full genuine-concurrency bundle publication remains explicitly unclaimed production/testability debt. |
| Only effort coverage, presence, richness, and Jaccard use `analysis_site`; RAI, diel, occupancy, rarefaction, traits, exports, covariates, and maps stay physical. Synthetic midpoints are mapping/distance aids only; physical covariates are neither pooled nor re-extracted. | Transitive protected-route guard and report limits at row 18 in fast, with representative-coordinate provenance at row 23; protected outputs and midpoint behavior independently reconstructed from the release bundle. |
| Validation cannot overwrite source data or advance the latest completed run. | Immutable inputs at rows 6, 25, and 26 in fast; ready and blocked runner controls at row 32 and failed-publication preservation at row 20 in release. |
| A current bundle copies and reopens, while one ordinary payload mutation and one publication failure are rejected safely. | The three retained release contracts at row 20. |

No lexical assertion, file, block, or pass count will be used as a proxy for
this coverage. Goal completion still requires the exact-SHA timing bars, one
manual release workflow, independent reconstruction from its emitted Judbury
bundle, and independent review.

## Deferred production-architecture debt

The audit found real production complexity, but Goal 010 does not authorize
changing it:

- Manifest and preview dispatch still carry historical versions without a
  stated public compatibility policy. Removing their tests does not remove the
  production branches; a later deprecation goal must decide that policy.
- The full evidence runner sources many production modules and currently does
  validation, staging, rendering, publication, and verification orchestration.
  Pure fixture/build interfaces would make release contracts cheaper, but that
  is a production refactor.
- Bundle, validation-ledger, selected-resolution, source-inventory, and entity-
  resolution logic repeat literal schemas, authority records, and semantic
  reconstruction. Consolidating those boundaries is later architecture work.
- Production configuration still exposes omitted, identity, nominal, and
  physical selection branches beyond the approved mapped Judbury slice.
- Authorized mappings with a zero-row selected event map fail closed during
  artifact serialization (`replacement has 1 row, data has 0`) instead of
  publishing a useful blocked preview.
- CamtrapDP entity resolution does not currently carry
  `physical_location_identifier` into deployment lineage, so authentic
  analysis-site concurrency cannot be reconstructed or publication-tested from
  a CamtrapDP fixture without a production repair.
  Test subtraction does not silently deprecate those behaviors.
- The target graph mixes legacy physical analyses with the additive selected
  route. Goal 010 protects behavior with a comparison; separating graph modules
  or renaming targets would be a production change.
- Plot functions mostly expose path creation rather than a testable semantic
  specification. Future visual assurance should use deliberate artifact review
  or image regression under a separately approved design, not revive existence
  checks.

Any proposed cut that requires a scientific-behavior change, a public
compatibility decision, or a new publication policy is a stop condition and
returns to Barry.
