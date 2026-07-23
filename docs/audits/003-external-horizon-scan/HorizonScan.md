# Goal 003 external horizon scan

## Executive recommendation

Camtrap Workflow should continue, but with a narrower product claim than the broad idea of a local or no-code camera-trap analysis tool. Current counterexamples already provide substantial local R analysis, guided cloud analytics, and a cross-platform offline desktop experience [E025] [E027] [E030]. The defensible opportunity is a **governed evidence run**: pre-labelled inputs, an explicit resolved configuration, immutable source and run identity, eligibility-gated analyses, structured module outcomes, and separate primary, audit, and machine-readable outputs.

The existing analytical engine and deterministic reporting are worth preserving. Goal 002 found a substantial 130-target workflow with broad technical evidence, but also hidden input dependencies, mutable run identity, a Judbury-shaped global schema, no fail-soft result contract, and R/shell-only operation (`docs/audits/002-product-architecture/Audit.md:7`, `docs/audits/002-product-architecture/Audit.md:81`, `docs/audits/002-product-architecture/Audit.md:85`, `docs/audits/002-product-architecture/Audit.md:95`). External evidence strengthens the renovation case; it does not justify a rewrite or immediate GUI choice.

**Project recommendation:** `continue`

## Methods and stopping evidence

This was a decision-led horizon scan, not a systematic review. Eleven fixed domains were searched through:

1. normative or official owner documentation;
2. peer-reviewed or credible independent checks where scientific, adoption, or positioning claims mattered;
3. bounded follow-up passes to test the leading conclusion and resolve version or scope contradictions.

Serious candidates were capped at approximately three to five per domain. Product installation, runtime trials, accounts, source-code archaeology, stakeholder contact, private data, and implementation were excluded. The evidence register records 50 retained source surfaces, versions or release states, access date `2026-07-20`, claims, limitations, and URL status.

The final two standards confirmations added no recommendation change after testing current versions, entity alternatives, provenance packaging and geospatial envelopes. The final two product/interface searches returned duplicates, historical tools, annotation or AI-only systems, or unsupported marketing claims and did not change the conclusion. The ALA and AI extensions likewise reached two consecutive no-change follow-ups after official and scholarly coverage. Further broad search is unlikely to improve the decisions; direct product spikes or stakeholder-environment evidence would.

## Evidence quality and currency

- Normative standards lead `D01`-`D04` and `D08`: Camtrap DP 1.0.2, current TDWG vocabularies, Data Package v2, CSVW, PROV-O, RO-Crate 1.3 and JSON Schema 2020-12 [E001] [E006] [E008] [E009] [E010] [E011] [E016].
- Product claims use official documentation, release records and licences, corroborated by peer-reviewed papers where available [E025] [E026] [E027] [E028] [E029] [E030] [E031] [E032]. Runtime usability, installation friction and offline behavior were not independently tested.
- ALA and AI decisions use official or institutional guidance plus peer-reviewed evidence about occurrence bias and ecological-report limitations [E039] [E041] [E042] [E044] [E045] [E046] [E050].
- Unknown publication dates and status-unclear sources are explicit. No marketing-tier source supports a recommendation.

Absence claims are bounded non-discoveries across the selected products and public documentation, not proof that no other tool exists.

## Decision summary

| Decision domain | Outcome | Recommendation |
| --- | --- | --- |
| `D01_interchange_standards` | `adapt` | Keep a simple progressive canonical input; add pinned Camtrap DP import/export and selected biodiversity adapters. |
| `D02_labelled_input_provenance` | `build` | Own a complete source-row, selection-scope and label-history record while adapting PROV and tabular concepts. |
| `D03_spatiotemporal_entities` | `build` | Implement four distinct internal entities and export only compatible subsets. |
| `D04_progressive_configuration` | `build` | Adapt JSON Schema and composition patterns, but build the resolved configuration and capability preview. |
| `D05_existing_product_whitespace` | `build` | Build the narrower governed evidence-run niche; reject broad first/only claims. |
| `D06_local_interface_delivery` | `later_spike` | Keep one authoritative CLI/machine contract; later compare localhost and thin desktop sidecar delivery. |
| `D07_operational_lifecycle` | `barry_decision` | Define acceptance criteria now; choose distribution only after agency OS/procurement evidence. |
| `D08_localmap_interchange` | `adapt` | Use an independent Data Package-style file-plus-manifest profile with stronger fixity. |
| `D09_ala_gamma_extension` | `later_spike` | Test documented regional occurrence context, not a raw gamma estimator. |
| `D10_ai_interpretation` | `later_spike` | Preserve a complete deterministic report; later test an optional, review-gated downstream draft contract. |
| `D11_software_note_positioning` | `adapt` | Position around reproducibility, governance and validation relative to existing tools. |

## Domain findings

### D01_interchange_standards

Camtrap DP is the strongest camera-specific exchange adapter. It packages deployments, media and observations, retains image-level links, and is recommended by current GBIF guidance where camera-trap detail matters [E001] [E002] [E004] [E005]. It should not become the mandatory canonical input: its archive/publication surface is broader than a progressively disclosed practitioner template.

Use Data Package v2 and CSVW mechanics for resource inventory, schemas, keys, source references and hashes [E008] [E009]. Darwin Core remains a conditional publication adapter; Audiovisual Core fields are optional media provenance rather than core deployment semantics [E006] [E007].

### D02_labelled_input_provenance

No retained standard fully preserves the agreed combination of input selection scope and complete label-revision history. Camtrap DP records useful classification method, actor, time and probability, but retains the latest classification rather than a revision ledger [E001] [E002]. CSVW can support source-row references, and PROV-O supplies durable Entity-Activity-Agent concepts without requiring RDF internally [E009] [E010].

Build a project-owned record containing source file hash, source record or row ID, original label, selection scope, annotator or classifier identity/version, timestamp, confidence where supplied, verification state, supersession links and repair lineage. RO-Crate is a later export option for rich run provenance, not the sole fixity or row-lineage layer [E011] [E013].

### D03_spatiotemporal_entities

The internal model should distinguish:

- `nominal_grid_station`: intended study-design position;
- `physical_location`: immutable coordinate-bearing position;
- `deployment`: time-bounded camera operation at one physical location;
- `analysis_site`: versioned derived grouping for a named analytical purpose.

Camtrap DP directly supports physical locations and deployments, while Darwin Core can publish hierarchical events [E002] [E004] [E006]. Neither supplies the complete internal hierarchy or a provenance-controlled analysis grouping. OGC OMS is conceptually helpful but disproportionate as an implementation dependency [E015].

Barry-provided context, not externally verified: Judbury has nine nominal grid stations, 13 physical locations created by four relocations, and potentially more deployment intervals (`docs/goals/003-external-horizon-scan/Goal.md:51`). Goal 003 makes no ecological grouping decision. Coordinates, suffixes or proximity must not silently determine station or analysis-site membership.

### D04_progressive_configuration

JSON Schema can express a minimal core, optional fields and conditional requirements, but its `default` keyword is annotation rather than an audited mutation instruction [E016] [E017]. Hydra and Snakemake demonstrate useful named-profile composition, precedence and resolved-config inspection patterns, but neither should become a runtime dependency [E018] [E019].

Build one resolver that records profile versions, source values, applied defaults, precedence and the final normalized configuration. On that same object, build a pre-run capability plan stating which modules are eligible, blocked or omitted, why, and what data would unlock them. Standard, guided and advanced modes must be views over that identical resolved contract.

### D05_existing_product_whitespace

Broad whitespace is false:

- camtrapR is a current, substantial local R analysis package [E025] [E026];
- Wildlife Insights provides guided hosted analytics and visual exports [E027] [E029];
- Biowatch is a current no-account, cross-platform local desktop application with Camtrap DP import and exploratory outputs [E030] [E031];
- Camera Base is a historical local analysis counterexample, though current status is unclear [E033].

Across their retained public documentation, none demonstrated the full combination of immutable source/run identity, persisted resolved configuration, explicit analysis eligibility, structured fail-soft statuses, and separate evidence/audit/machine outputs. That bounded non-discovery supports a narrower build opportunity, not a uniqueness claim.

Recommended product sentence:

> Camtrap Workflow should become a local-first, configuration-resolved and provenance-preserving workflow that converts pre-labelled camera-trap records and deployment metadata into eligibility-gated ecological evidence with immutable, inspectable run artifacts.

### D06_local_interface_delivery

The CLI and machine-readable contract should remain authoritative. The highest-value later interface spike should compare:

1. a self-opening localhost interface that controls the same engine;
2. a thin Tauri desktop shell bundling or invoking that engine.

Tauri documents external sidecars and signed update artifacts, establishing feasibility but not product suitability [E034] [E035]. Biowatch proves that current cross-platform local desktop delivery is possible in this domain [E030] [E031]. Containers remain useful for expert reproducibility, but should not be presumed to be the primary non-programmer installer. No GUI or deployment substrate is selected here.

### D07_operational_lifecycle

A practitioner product needs signed and checksummed installers, explicit opt-in update behavior, a retained prior installer and rollback procedure, schema-migration backup/recovery, network-disabled testing, a Windows/macOS/Linux compatibility matrix, durable export, and clean uninstall behavior. Current release and updater patterns show pieces of this lifecycle [E031] [E035].

The target agencies' operating systems, managed-desktop restrictions, network policy, procurement and acceptable licences remain unknown. Those are material Barry/stakeholder inputs, not questions further generic web search can answer. The product contract can proceed before the distribution choice.

### D08_localmap_interchange

Retain LocalMap_Tas as an independently runnable, independently versioned upstream GIS/covariate provider. Camtrap should consume validated files plus a manifest, never LocalMap source code, targets, cache or a live service. This remains consistent with Goal 002's ownership boundary (`docs/audits/002-product-architecture/localmap_boundary.md:33`).

Adapt Data Package resource inventory and schema mechanics, require SHA-256, and record generator/version, input-location hash, CRS, spatial/temporal coverage, source/licence, processing parameters, output semantics and file hashes [E008] [E021]. RO-Crate or BagIt may later enrich provenance or archival transfer [E011] [E022]. STAC API coupling is rejected; GeoParquet is conditional only where geometry is genuinely transferred [E023] [E024].

### D09_ala_gamma_extension

ALA can provide a citable and filterable regional occurrence context, but not a plug-in gamma-diversity estimate. Its records combine heterogeneous sources; ALA explicitly leaves fitness-for-purpose choices to users, and occurrence-data bias is well established [E039] [E040] [E041] [E042] [E044].

A later spike must pre-specify spatial/habitat extent, time window, taxonomic reconciliation, quality filters, sensitive-data behavior, licences, DOI, camera-detectable taxa and scale sensitivity. It must distinguish observed Judbury richness, an occurrence-derived recorded regional pool, and any modelled richness estimate. Coverage-based diversity tools can inform comparisons but do not remove ALA-camera sampling mismatch [E043]. A raw distinct-species count labelled gamma diversity is rejected.

### D10_ai_interpretation

The deterministic report must remain complete and authoritative. Any later AI layer should consume only a completed structured result bundle, default to no raw imagery or sensitive records, show the exact payload before egress, and produce a labelled draft. Record provider, model/version, date, prompt/template hash, input/output hashes, settings, egress state, reviewer, review time and disposition [E045] [E046] [E049].

Human expert review is mandatory. Published ecological evidence shows that generated ecological reports may require substantial revision, particularly for inference and recommendations [E050]. Local models may reduce egress but do not remove hallucination or review risk. Provider and local-versus-remote deployment remain unselected.

### D11_software_note_positioning

Current software-note criteria expect maintained open software, documentation, tests, an out-of-box example, a meaningful contribution and a clear relationship to existing software [E036] [E037] [E038].

Demonstrated now: a technically exercised analytical engine, deterministic report and Judbury reference workflow (`docs/audits/002-product-architecture/Audit.md:7`). Plausible but unvalidated: immutable evidence runs, progressive labelled-input adapters, eligibility-gated fail-soft modules, CLI/UI equivalence, offline operation and cross-OS delivery. Indefensible now: first/only or all-in-one claims; novelty of established ecological methods; replacement of Camtrap DP; agency-ready, publication-ready or universally fail-soft claims; and scientific generality from Judbury alone.

The likely paper is a software-method/product card, with Judbury as the validating demonstration and at least one independent or synthetic Camtrap DP dataset testing portability. Journal selection and the final paper claim remain later decisions.

## Goal 002 gap reconciliation

| gap_id | external_evidence_ids | outcome | recommendation | residual_authority |
| --- | --- | --- | --- | --- |
| `G004` | E001; E016; E017 | build | Keep a small versioned core, a Judbury compatibility profile and conditional extensions validated through one resolved configuration. | Final public schema and required fields remain unselected. |
| `G005` | E001; E009; E010; E011 | build | Preserve source-row identity, selection scope, supplied label provenance and full supersession history in project-owned lineage records. | Public field names and export profiles remain unselected. |
| `G007` | E002; E004; E006; E015 | build | Separate nominal station, physical location, deployment and versioned analysis-site mapping internally. | Barry retains consequential ecological grouping decisions. |
| `G012` | E030; E031; E034; E035 | later_spike | Preserve one CLI/machine contract and later compare localhost UI with a thin Tauri sidecar. | GUI, packaging and deployment platform remain unselected. |
| `G015` | E008; E011; E021; E022 | adapt | Use a strict file-plus-manifest boundary with schemas, SHA-256 fixity and generator/source provenance. | Final interchange schema and file formats remain unselected. |
| `G023` | E002; E004; E006; E016 | build | Add named, versioned spatial and temporal schemes selected and reported per module. | No Judbury grouping or temporal scheme is selected here. |
| `G024` | E039; E040; E041; E042; E044 | later_spike | Test documented regional occurrence context only after extent, taxonomy, bias, detectability and sensitivity gates are defined. | Consequential gamma method and ecological claim require later scientific approval. |
| `G025` | E045; E046; E049; E050 | later_spike | Keep deterministic reporting complete; later test an optional provider-neutral, review-gated downstream draft contract. | Provider, egress, deployment and publication use remain unselected. |

## Contradictions, rejected patterns and uncertainty

- Camtrap DP is the best domain interchange but is intentionally not the mandatory simple input contract [E001] [E005].
- Camtrap DP retains current classification metadata, while the product needs full supplied revision lineage [E001].
- Data Package v2 and the Camtrap DP profile have separately pinned conventions; adapters must not assume one validator covers both [E003] [E008].
- JSON Schema annotates defaults; applying them must be a separate recorded resolver step [E016] [E017].
- RO-Crate provides rich context but does not guarantee exhaustive inventory/fixity [E011].
- STAC API/service coupling, raw ALA counts as gamma, unreviewed AI prose and broad first/only product claims are rejected [E023] [E041] [E044] [E050].
- Current documentation cannot prove external product usability, maintenance quality, numerical equivalence, installation friction or offline operation. Those require later direct tests.

## Explicit non-decisions

Goal 003 does not choose or implement a public schema/API, GUI toolkit, container strategy, desktop substrate, AI provider, ALA/gamma method, stakeholder commitment, licence/procurement posture, Judbury ecological grouping, data publication venue, journal, paper claim or deprecation. It does not certify current analyses scientifically or claim that a competitor with the full proposed contract cannot exist.

## Highest-value next tranche

Goal 004 should implement and verify the **immutable evidence-run foundation**, not a GUI or wholesale refactor:

1. expose every local/remote source as an explicit content-identified input before parsing;
2. create one immutable run identity and new run directory, with `latest` only an updateable pointer;
3. persist source hashes, resolved configuration identity, engine/profile versions and output hashes in a versioned manifest;
4. preserve current analysis behavior behind compatibility paths and prove that stale source changes invalidate the correct work;
5. stop before redesigning the public schema, Judbury grouping, module eligibility or interface.

This is the highest data-integrity return, supports every later interface and standard adapter, and directly addresses Goal 002's critical finding (`docs/audits/002-product-architecture/Audit.md:160`). The next tranche after that should separate spatiotemporal entities and capability/module-status contracts before any GUI spike.

## Evidence that would overturn the recommendation

Reconsider `continue` in favor of `narrow`, `integrate` or `stop` if:

- a maintained product is verified to deliver the same local, configuration-resolved, immutable, eligibility-gated evidence-run contract with a sustainable integration path;
- immutable source/run identity cannot be added without discarding the verified analytical engine or introduces unacceptable reproducibility regression;
- Judbury plus an independent dataset exposes material numerical or scientific unreliability in the retained modules;
- target agencies show no demand for post-labelling analysis or cannot deploy any acceptable local runtime; or
- maintenance, distribution and support burden materially exceeds the project's research and stakeholder value.
