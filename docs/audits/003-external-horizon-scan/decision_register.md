# Goal 003 material decision register

This register contains only choices that need Barry's scientific, strategic or stakeholder authority. None blocks the recommended immutable evidence-run tranche. All remain open.

## B001 - Public input and standards posture

- **Why it matters:** Camtrap DP is the strongest camera-specific exchange standard, but forcing its full package as the only input would undermine the agreed progressive practitioner experience [E001] [E004] [E005].
- **Options:** require Camtrap DP; use a simple versioned canonical profile plus Camtrap DP adapters; or expose several equal canonical formats.
- **Recommendation:** use a simple versioned canonical profile with pinned Camtrap DP import/export and conditional Darwin Core/media adapters.
- **Trade-off and uncertainty:** this maximizes usability and interoperability but creates a project-owned schema and adapter maintenance burden. The exact public fields have not been designed or tested.
- **Confidence:** high.
- **Reversibility:** high before public v1; lower after external adoption.
- **Consequence of delay:** none for Goal 004, but it blocks the later public schema and onboarding journey.
- **Decision owner:** Barry.
- **Status:** open.

## B002 - First guided local interface

- **Why it matters:** Biowatch demonstrates that cross-platform local desktop use is possible, while Tauri documents a plausible thin sidecar route [E030] [E031] [E034] [E035]. A GUI choice made before the engine contract is stable would create avoidable coupling.
- **Options:** self-opening localhost UI; thin Tauri desktop sidecar; container-first UI; or CLI only for the initial release.
- **Recommendation:** after the evidence-run and capability contracts exist, run one bounded comparison of localhost UI versus Tauri sidecar against the same CLI/machine contract. Keep containers as an expert fallback.
- **Trade-off and uncertainty:** localhost delivery is architecturally thin but browser/process lifecycle can be awkward; a desktop sidecar can improve installation but adds packaging, signing and cross-OS work. No option has been run here.
- **Confidence:** moderate.
- **Reversibility:** moderate if the engine/UI boundary remains strict.
- **Consequence of delay:** the product remains technical-user-only, but no immediate architecture work is blocked.
- **Decision owner:** Barry.
- **Status:** open.

## B003 - Agency distribution and lifecycle target

- **Why it matters:** deployment suitability depends on actual operating systems, managed-desktop controls, network policy, procurement and licence constraints; generic product research cannot supply those facts [E028] [E031] [E032] [E035].
- **Options:** target unmanaged researcher desktops first; target one named agency estate; or design for Windows/macOS/Linux parity from the first public installer.
- **Recommendation:** obtain a small requirements sample from immediate Tasmanian stakeholders before selecting the distribution channel, while keeping exported research artefacts platform-independent.
- **Trade-off and uncertainty:** early stakeholder targeting may narrow reach but reduces packaging risk; universal parity costs more and may solve requirements no stakeholder has.
- **Confidence:** high that direct evidence is needed; low on the eventual platform choice.
- **Reversibility:** moderate before signed public releases.
- **Consequence of delay:** interface and installer acceptance criteria remain incomplete; core evidence-run work can continue.
- **Decision owner:** Barry.
- **Status:** open.

## B004 - ALA regional-context scientific claim

- **Why it matters:** ALA can provide a citable occurrence context, but heterogeneous effort, bias, taxonomy and detectability make a raw species count scientifically indefensible as Judbury gamma diversity [E039] [E041] [E042] [E043] [E044].
- **Options:** omit regional context; publish a carefully filtered descriptive recorded pool; or develop a model-based regional richness analysis.
- **Recommendation:** later test a clearly labelled descriptive regional-context appendix with prespecified extent, taxa, time, filters and sensitivity. Do not call it gamma diversity unless a separately approved model supports that claim.
- **Trade-off and uncertainty:** descriptive context is interpretable and reproducible but scientifically modest; model-based estimation could be richer but substantially expands methods and validation scope.
- **Confidence:** high on rejecting raw counts; moderate on the value of a descriptive appendix.
- **Reversibility:** high before manuscript claims are fixed.
- **Consequence of delay:** no effect on core product work; the eventual Judbury demonstration has less regional context.
- **Decision owner:** Barry.
- **Status:** open.

## B005 - Optional AI interpretation boundary

- **Why it matters:** AI may assist non-specialist readers, but privacy, egress, factual reliability and accountable ecological review are material risks [E045] [E046] [E048] [E049] [E050].
- **Options:** no AI; local model only; remote provider adapter; or a provider-neutral contract supporting both.
- **Recommendation:** retain a complete deterministic report and defer implementation. If later authorized, test a provider-neutral downstream draft contract with payload preview, no raw imagery by default, complete provenance and mandatory expert disposition.
- **Trade-off and uncertainty:** remote models may be capable but create egress and provider dependency; local models reduce egress but not hallucination or maintenance risk. The actual labour saving is unknown.
- **Confidence:** high on the governance boundary; low on provider or deployment choice.
- **Reversibility:** high while AI remains a downstream optional adapter.
- **Consequence of delay:** none for scientific reproducibility; non-specialist interpretation remains human-led.
- **Decision owner:** Barry.
- **Status:** open.

## B006 - Software-note claim and validation bar

- **Why it matters:** current journal guidance expects a maintained, tested, documented contribution positioned relative to existing software [E036] [E037] [E038]. Judbury is a strong demonstration but cannot alone prove generality.
- **Options:** a repository-specific case study; a software-method note with Judbury plus independent validation; or a broader methods paper claiming new ecological analyses.
- **Recommendation:** aim for a software-method/product note after the product contract is implemented, using Judbury plus one independent or synthetic Camtrap DP case, repeatability and failure-fixture evidence, and numerical comparisons with established references.
- **Trade-off and uncertainty:** this is a narrower claim than a new-method paper but is better supported. Journal fit may shift as the product matures.
- **Confidence:** high on the claim boundary; moderate on eventual venue.
- **Reversibility:** high before drafting and journal selection.
- **Consequence of delay:** none for Goal 004; validation work may be less efficiently accumulated if the bar is never stated.
- **Decision owner:** Barry.
- **Status:** open.
