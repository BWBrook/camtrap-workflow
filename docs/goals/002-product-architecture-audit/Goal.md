# Goal 002 - Product and architecture audit

## Completed-state objective

Produce a decision-ready, source-evidenced audit of Camtrap Workflow that reconstructs the system as it actually exists, evaluates it against the agreed product and scientific contract, and recommends a prioritized architectural renovation roadmap without refactoring or implementing the recommendations.

The completed audit must let Barry and the project orchestrator decide what to preserve, simplify, separate, retire, validate, or defer before a new implementation goal is authorized.

## Why this goal exists

Camtrap Workflow has accumulated useful domain knowledge and working capabilities over several years of intermittent development. Its present structure may also contain Judbury-specific assumptions, duplicated or obsolete surfaces, hidden coupling, uneven interfaces, and documentation that no longer matches implementation. A broad rewrite would risk destroying validated behavior before the intended product boundary and user journey are understood.

Goal 002 therefore establishes evidence before renovation. The repository is the product; the audit must judge whether its present engine, workflow, interfaces, reports, and provenance can support a non-programmer using data plus configuration to obtain trustworthy ecological evidence.

## Operating mode

- This is a static, read-only evidence audit of implementation and existing artefacts.
- It is not a runtime-validation, refactoring, implementation, release, or external-research goal.
- Work inside `/Users/bwbrook/git/camtrap-workflow`, except for the explicitly bounded, read-only LocalMap_Tas orientation below.
- Goal 002 will be executed through native Codex subagents under the project orchestrator. The retired `judbury` action-agent lane must not be used.
- Separate observed facts from interpretation and recommendation throughout.
- Apply the 80/20 stopping policy: complete the high-value evidence surface, perform one focused self-review and repair pass, then stop unless a material defect remains.

## Pre-execution publication gate

Before the audit begins, the orchestrator must separately review, commit, and push the four Goal 002 packet files. Execution must start on clean `main...origin/main`, with local HEAD equal to local `origin/main`, all four packet files tracked, and the accepted Goal 001 commit `39ade324b06264d003f7f920b69811dba4d0cbe3` present as an ancestor. That SHA is the accepted pre-packet base, not the required execution HEAD. The executor must append the observed packet-publication HEAD to `Log.md` at execution start. If any gate fails, stop and report without fetching or reconciling the repository.

## Agreed product and scientific contract

The audit must use the following contract as its evaluation frame. It must not silently alter, narrow, or extend it.

### Purpose and audience

- North Star: enable an ecologist to turn standards-compatible labelled camera-trap data into trustworthy, publication-ready ecological evidence through one reproducible, auditable workflow.
- The repository is the product. The paper is primarily a software/methods note. Judbury is the open reference implementation, validation case, and regression dataset.
- Agency and NGO users should supply data plus configuration; they should not need to read or write R or open RStudio.
- The workflow starts after image labelling and deployment-metadata assembly. Image detection and classification are categorically out of scope. MEWC and other upstream systems are potential adapters or data sources, not dependencies.

### Delivery and interoperability

- Local-first and offline-capable operation is primary. A hosted service is a possible future, separate extension.
- Docker is a candidate reproducibility and deployment substrate, not a predetermined graphical-interface shell.
- The audit must not preselect Shiny or another GUI technology.
- Simple, versioned CSV profiles are first-class. CamtrapDP compatibility is valuable but not mandatory. Multiple external input forms map into one rigorous internal model.
- LocalMap_Tas remains a separate upstream GIS and covariate provider. Camtrap Workflow begins with analysis-ready site and covariate data and consumes an explicit interchange and provenance contract.

### Data model and progressive capability

- A small required core makes the workflow usable; optional metadata progressively unlocks stronger validation, provenance, effort reconstruction, and analytical capabilities. Missing optional metadata is `unknown`, not an error.
- Input selection scope is explicit: `all_media`, `animal_records`, `selected_taxa`, or `unknown_or_legacy_extract`. These scopes permit different claims.
- Classifier confidence, human-verification status, labelling method, and model or annotator provenance are preserved when supplied, while missing values remain acceptable.
- Raw image-level records are accepted and preserved. Operational detection events are derived through configurable and audited rules, remain linked to source rows, and must not be described as biologically independent animals or observations.
- Optional media and activity records, including blanks, people, vehicles, test images, and unclassified captures, can strengthen effort and camera-health evidence but are not mandatory. Sensitive imagery itself is not required.

### Validation, repair, and module behavior

- Modules fail softly with explicit `completed`, `completed_with_warnings`, `omitted`, or `failed` states. Global integrity failures still stop the run.
- An omitted module identifies missing prerequisites, analytical consequences, and practical remediation.
- Raw inputs remain immutable.
- Cleaning has three policy levels: audit only; safe deterministic normalization; and explicitly approved semantic or destructive repair.
- Proposed changes are previewable and each applied change records source identity, before and after values, rule, reason, and approval basis.

### Space, time, and effort

- The spatial model distinguishes an immutable location, a deployment interval, and a derived analysis site.
- Named spatial resolutions are configuration objects selected explicitly by each module and reported with each result.
- The temporal model distinguishes deployment intervals, sampling occasions, and named temporal analysis schemes.
- Effort and zero-versus-missing semantics are first-class: no detection during confirmed operation may be a zero; unknown or failed operation is missing effort.
- Deployment intervals provide the conservative default effort assumption.
- Optional operational-period inference follows an evidence hierarchy, records uncertainty, and remains reviewable and overrideable. A last detection is not automatically a camera failure time.

### Interaction, reporting, and provenance

- Standard mode is an opinionated, named, versioned ecological-evidence profile.
- Guided and advanced modes expose the same configuration and analytical engine, not separate implementations.
- The deterministic report is complete without AI.
- Optional AI interpretation is downstream, provenance-aware, reviewable, provider-pluggable, and explicit about possible data egress. It distinguishes computed results from interpretation and speculation.
- Outputs are separated into a concise primary report, a detailed audit bundle, and reusable machine-readable artefacts.
- Completed runs are immutable and have stable run identifiers. `latest` is only a convenience pointer and never replaces or mutates an underlying run.

## Judbury evaluation frame

The Judbury case study should demonstrate a restrained subset of defensible capabilities, not every analysis that can be made to run. The audit must evaluate:

1. Sampling adequacy, effort, outages, relocations, data quality, and completeness.
2. Observed and estimated richness at location, grouped-site, and whole-grid scales.
3. Spatial assemblage turnover and beta diversity, with cautious descriptive relationships to slope, vegetation, and surrounding land-use edges.
4. Selected-species seasonal patterns, detection or relative-abundance-index limitations, and coarse day/night patterns rather than unsupported precise diel inference.
5. Regional Atlas of Living Australia and gamma-diversity context as a candidate extension, with explicit scale, taxonomy, detectability, and opportunistic-record bias caveats.

The audit must explicitly scrutinize occupancy and covariate inference with only nine camera locations, relative-abundance-index versus abundance claims, clock drift, point relocation, unequal effort, and missingness.

## In scope

### Camtrap Workflow reconstruction

- Reconstruct the actual architecture, data flow, target DAG, modules, configurations, schemas, tests, reports, output surfaces, and current user journey from source evidence.
- Account for every `R/*.R` file, every target declared in `_targets.R`, every configuration profile, relevant tests and documentation, and principal report and output surfaces.
- Identify all entrypoints and every point where a user needs R knowledge, network access, mutable output state, manual intervention, or an undocumented assumption.
- Compare documentation and stated intent with implemented and tested reality.
- Classify capabilities using the defined status vocabulary in the acceptance criteria.

### Scientific and product assessment

- Create a restrained Judbury question-evidence matrix covering the evaluation frame above.
- Distinguish analyses that are defensible, illustrative only, underpowered, or unsuitable.
- Produce a gap and debt register ranked by scientific risk, user friction, architectural leverage, and effort.
- Recommend a target architecture and a phased renovation roadmap.
- Separate no-regrets internal work from technology, schema, method, and product choices that should wait for Goal 003's external horizon scan or Barry's decision.

### LocalMap_Tas boundary

- Read only the bounded surface listed below in `/Users/bwbrook/git/localmap_tas`.
- Define a candidate interchange and provenance boundary in which LocalMap_Tas supplies analysis-ready site covariates and visual outputs while remaining independently runnable and independently versioned.
- State non-goals that prevent repository merging, hidden code dependency, duplicated GIS responsibilities, or Tasmania-specific assumptions leaking into Camtrap Workflow.

## Non-goals

- No code, configuration, schema, test, data, report, pipeline, or existing documentation changes.
- No refactor, feature implementation, API design finalization, deprecation, removal, migration, packaging, project release, or audit-result publication during execution. The separately reviewed and published Goal 002 packet is the pre-execution gate, not an audit deliverable.
- No R, `renv`, tests, lint, `targets`, Quarto, Docker, document builds, pipeline execution, data processing, or artefact regeneration.
- No external literature, software, competitor, service, or product horizon scan; that work is reserved for Goal 003.
- No broad audit of LocalMap_Tas and no edits, builds, tests, pipelines, history archaeology, or repository reconciliation there.
- No MEWC implementation review beyond treating its potential output as an upstream labelled-data source already established by the product contract.
- No consequential scientific-method selection, paper claim, stakeholder commitment, GUI choice, hosted-service design, or deployment-platform decision.
- No Git mutation: do not fetch, pull, checkout, switch, stage, commit, push, tag, reset, clean, stash, amend, rebase, or merge.

## Read-first and evidence surface

Read repository-local `AGENTS.md` first, then:

1. Goal 001 contract and evidence under `docs/goals/001-r46-mac-mini-readiness-acceptance/`, plus `docs/log/620_r46_mac_mini_readiness.md`.
2. `README.md`, `GETTING_STARTED.md`, `VERSION`, `_targets.R`, and all `R/*.R` files.
3. All configuration profiles, input schemas, templates, and schema or reference documentation.
4. Analysis QMDs, report sources, scripts, test inventory, and principal output-contract code.
5. Product, architecture, workflow, roadmap, decision, interpretation, bring-your-own-data, reproducibility, container, and release documentation that exists in the repository.
6. Representative ignored Goal 001 manifests, reports, and tables if still present. Their presence is optional; inspect without modifying or regenerating them and never treat absent ignored artefacts as a defect in this static goal.
7. Git history only where needed to resolve a material contradiction or explain a current structural decision. Avoid archaeology without decision value.

For LocalMap_Tas, read its `AGENTS.md` first, then only its README, product brief, architecture, settings or configuration documentation, output-schema documentation, public entrypoints, and manifest or provenance surfaces needed to define the integration boundary. If a named category is absent, record that absence and stop rather than broadening the read.

## Required deliverables

Create exactly this durable audit review surface during execution:

- `docs/audits/002-product-architecture/Audit.md`
  - Primary decision memo.
  - Current and recommended architecture diagrams.
  - Current end-to-end user journey.
  - Coverage reconciliation and module-status summary.
  - Major product, scientific, usability, provenance, and architecture findings.
  - Recommended direction and explicit decisions deferred to Barry or Goal 003.
- `docs/audits/002-product-architecture/module_inventory.csv`
  - One evidence-backed inventory covering modules, entrypoints, targets, inputs, outputs, configurations, tests, documentation, status, and concerns.
- `docs/audits/002-product-architecture/question_evidence_matrix.csv`
  - Judbury questions, units of inference, required data, relevant modules, proposed outputs, assumptions, limitations, and suitability.
- `docs/audits/002-product-architecture/gap_register.csv`
  - Ranked gap and debt register with category, severity, user or scientific risk, architectural leverage, estimated effort, evidence, recommendation, and disposition.
- `docs/audits/002-product-architecture/localmap_boundary.md`
  - Candidate data and provenance interchange, ownership boundary, assumptions, and non-goals.
- `docs/audits/002-product-architecture/renovation_roadmap.md`
  - Phased recommendations, no-regrets tranche, Goal-003-dependent choices, implementation candidates, acceptance evidence, and stop rules.
- `docs/goals/002-product-architecture-audit/Log.md`
  - Chronological execution record, evidence counts, deviations, static validation results, residual uncertainty, and exact publication recommendation.

Do not rename or substitute these files during execution. The fixed surface supports deterministic review.

## Acceptance criteria

### Evidence and epistemic discipline

- Every material claim and recommendation cites stable evidence: a repository-relative `file:line`, target or module identifier, test identifier, existing artefact path, or Git commit.
- Observed facts, inference, recommendations, and unresolved uncertainty are visibly distinguished.
- The audit does not treat documentation claims, test existence, or cached output existence as proof of runtime behavior without qualification.
- Contradictions between code, tests, documentation, configuration, and existing artefacts are recorded rather than silently resolved.

### Coverage reconciliation

- The audit reports counts for all `R/*.R` files, targets declared in `_targets.R`, configuration profiles, relevant test files, analysis/report sources, and principal output surfaces.
- Every counted `R/*.R` file and target has a corresponding inventory record or an explicit, evidence-backed exclusion.
- Configurations, tests, documentation, and output surfaces are mapped to modules or recorded as cross-cutting or orphaned.
- Inventory statuses use only:
  - `implemented_and_evidenced`
  - `implemented_unverified`
  - `partial`
  - `docs_only`
  - `obsolete_or_duplicated`
  - `not_present`
- Status definitions and the threshold for `implemented_and_evidenced` appear in `Audit.md`.

### Product and scientific fit

- The current user journey is traced from data and configuration through validation, targets, analysis, reports, audit artefacts, and rerun behavior.
- Every requirement in the agreed product and scientific contract is mapped to current evidence, a gap, or a deliberate future decision.
- The Judbury matrix covers all five question areas and explicitly classifies suitability as `defensible`, `illustrative_only`, `underpowered`, `unsuitable`, or `candidate_extension`.
- The audit directly addresses nine-site occupancy limitations, abundance language, clock drift, relocation, effort, missingness, and regional-data biases.
- The proposed architecture is sufficiently implementation-neutral for Goal 003 to alter technology choices.

### Recommendations and authority

- The gap register is ranked using explicit definitions for severity, scientific or user risk, leverage, and effort.
- The renovation roadmap identifies a bounded no-regrets first tranche and states objective acceptance evidence for each proposed phase.
- Decisions requiring external comparison, consequential methods judgment, public schema or API commitment, GUI or deployment choice, deprecation, repository merger, paper claims, or stakeholder commitments are explicitly deferred.
- No recommendation is implemented in Goal 002.

### Static validation and final state

- All seven execution deliverables exist at the exact paths above and contain no unresolved markers or empty required sections.
- CSV files parse as rectangular tables, have the documented headers, use the defined status or suitability enums, contain no duplicate primary keys, and contain evidence fields where required.
- Markdown cross-references resolve to existing audit or repository paths, except clearly labelled proposed future paths.
- `git diff --check` passes.
- The final Git status proves that execution changed only `docs/audits/002-product-architecture/` and `docs/goals/002-product-architecture-audit/Log.md` relative to the packet baseline.
- Validation is labelled static evidence-packaging validation, not runtime validation.
- One focused self-review and repair pass is complete; further work stops when it would add polish without material decision value.

## Decision authority and escalation

The executor may inventory, classify, rank, infer, and recommend from repository evidence. The executor may not decide consequential scientific methods, final public schemas or APIs, GUI technology, deployment platform, deprecations or removals, repository merger, paper claims, data-release terms, or stakeholder commitments.

Pause and report if:

- sensitive or unexpected data are encountered;
- the Camtrap Workflow or LocalMap_Tas state differs unexpectedly or mutates during the audit;
- external research is needed to support a material conclusion;
- implementation or runtime execution would be required to validate a recommendation;
- a requested read would exceed the authorized LocalMap_Tas boundary;
- two consecutive attempts yield no material new evidence or improvement.

Do not commit or push. After orchestrator review, return an exact publication recommendation for the audit deliverables and updated log.

## Final response contract

Return:

1. Status: `DONE`, `DONE_WITH_CONCERNS`, `NEEDS_CONTEXT`, or `BLOCKED`.
2. Decision summary and highest-leverage recommended renovation tranche.
3. Exact created or changed paths and coverage counts.
4. Static validation performed and outcomes.
5. Material assumptions, contradictions, residual uncertainty, and deferred decisions.
6. Exact staging and commit recommendation, with confirmation that no commit or push occurred.
7. Whether further work or escalation is justified.
