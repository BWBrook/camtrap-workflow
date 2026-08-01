# Goal 009 - Packet log

- **Canonical packet state:** `APPROVED_AWAITING_EXACT_PUBLICATION`
- **Scientific specification state:** `BARRY_APPROVED_WRITTEN_GOAL`
- **Exact mapping state:** `APPROVED_EXACT_SHA256`
- **Execution state:** `AUTHORIZED_CONDITIONAL_ON_EXACT_PACKET_PUBLICATION`
- **Publication state:** `NOT_PUBLISHED`
- **Packet date:** 2026-07-31 AEST
- **Packet-authoring baseline:** clean synchronized `main` at
  `c0ed40377af4aa0162098913e2c097da65eadc42`
- **Proposed packet subject:**
  `docs: define Goal 009 analysis-site vertical slice`

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

The mapping remains non-runtime evidence until the exact packet-publication
condition in the approval receipt is satisfied.

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
unauthorized until renewed approval.

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
- the packet remains unpublished and execution authority remains conditional
  on exact packet publication.

## Future execution record

No execution evidence exists. Later implementation closeout must record:

- exact approval receipt and packet SHA;
- baseline preview/full run IDs and comparator evidence;
- RED and GREEN results;
- selected preview/full parity and independent reconstruction;
- local lint, tests, full run, bundle and copied-bundle verification;
- independent review and any single focused repair;
- accepted implementation SHA;
- exact-SHA CI URL, run/job IDs, and conclusion; and
- material residual limitations and highest-value next tranche.
