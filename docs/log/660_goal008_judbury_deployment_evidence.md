# Goal 008 - Judbury deployment and service evidence

Date: 2026-07-27

Status: `COMPLETE_PUBLISHED` / `PUBLISHED_CI_CONFIRMED`

## Authority

Barry approved implementation against:

- packet commit
  `478832240e77388da299e55871bdeb6e386c90c5`;
- normalized service SHA-256
  `f33eeac9d70126966717c8e3f4731c00a97cbc3a34c2f44ce5c70d91c7d5283a`;
- deployment-ledger SHA-256
  `0921eb8845c2bb1ad5760271f283ab2783735b7739e254c67e9243bc906f3ebf`;
- frozen Goal 007 crosswalk SHA-256
  `553abada14493f3a5f0ae3c072523b6d5cc0d0c6a6c6480ca17a9e3331f2d8ec`;
- unchanged `data/jc_op.csv` SHA-256
  `28222586fa232fccc46bfab5e8c07e0c453f07387ebe4eb95b9a90e4687033a3`;
  and
- the combined source-and-ledger authority reference recorded in the Goal
  packet and selected configuration.

## Local implementation

The bounded audit-evidence core is implemented:

- a separate exact six-field `deployment_evidence` selection or explicit null
  selection;
- immutable service and ledger copies under two non-parser source-inventory
  roles;
- closed readers for the exact SHA-pinned source, including 13 aliases, 75
  ordered service dates, 62 retained `run_days` literals, and the 13-row
  deployment ledger;
- 13 resolved deployment entities, 13
  `deployment_to_physical_location` links, and 13 deployment-lineage 1.1 rows;
- four reciprocal directed predecessor/successor relations retained in
  lineage only, alongside the unchanged four undirected Goal 007 move pairs;
- portable reconstruction from immutable source, ledger, crosswalk,
  operation, and configuration evidence; and
- audit-only join readiness with zero joined analytical rows, no analytical
  routing, and `analysis_site` unselected.

Explicit Goal 008 configurations use
`camtrap-deployment-lineage/1.1`. Legacy configurations that omit the new
block retain the lineage 1.0 column and digest contract. Validation preview
1.1, manifest 1.2, and the existing five-file entity namespace are unchanged.

## Focused evidence

Ignored evidence under `outputs/goal008_acceptance/` currently records:

- pre-edit validation-only and full baselines;
- 65 passing configuration assertions;
- 32 passing immutable-source assertions;
- 104 passing entity and normalization assertions;
- a passing validation-ledger suite with selected/null analytical-input
  identity;
- a passing target-graph smoke suite with no Goal 008 scientific route;
- six passing portable source/copy/reclosed-mutation assertions;
- two passing checksum-reclosed lineage semantic-reconstruction assertions;
- a complete authoritative result of 611 passes, zero failures, zero skips,
  and one expected CamtrapDP absent-data warning;
- validation-only run `20260727T082010Z-4bf28cf2a3ff4361`, with no completion
  record and no `outputs/latest` change;
- completed run `20260727T082247Z-fc187bae5fa44144`, with 91 verified payload
  files and manifest SHA-256
  `1d0461ae1e1073e45b0723104fbfb5e76b33b27fc4d5c8b2074ff5b170923e08`;
  and
- exact validation/full five-file parity and scientific invariance for all
  four validated inputs, 11 Phase 2 artefacts, and 13 comparator tables.

The local acceptance evidence reproduces the approved
`13/13/9/4/75/62/0` structure, three same-day move-pair boundaries, one pm14
gap pair, lineage 1.1 provenance, false analytical routing, and zero joined
analytical rows. The same 13 physical-location site keys remain the scientific
input.

One focused compatibility repair was required. The first authoritative pass
showed that the standalone legacy CamtrapDP adapter suite loaded source
inventory without the entity-resolution helper. Omitted and explicit-null
deployment selection are now self-contained; strict selected-profile
resolution still requires the full authority helpers. The affected suite
passed 36 assertions and the complete local gate reran green.

## Independent implementation review

The independent read-only review returned `PASS_WITH_NON_BLOCKING_NOTES`, and
the orchestrator accepted that verdict for the exact SHA-pinned Goal 008
profile.

The review confirmed the exact authority hashes, two closed non-parser
snapshot roles, `13/13/9/4/75/62/0` evidence, portable verification of both the
91-payload final bundle and 89-payload pre-edit bundle, complete scientific
invariance, validation/full entity parity, the 29-path allowlist, and rejection
of explicit-null, omitted, duplicate-role, and selected checksum-reclosure
attacks.

One defence-in-depth debt remains. The standalone service reader accepts blank
cells as missing in unused or initial service-date and corresponding
`run_days` positions, although the packet defines literal `NA` as the missing
token. Exact configuration authority, snapshot hashes, inventory
reconciliation, and portable reconstruction make this unreachable for the
approved service SHA-256. No second repair was authorized because the focused
compatibility-repair allowance is spent.

Before approving a different service source, reusing this reader generally, or
adding another deployment-evidence profile, the reader must explicitly reject
blank missing tokens and negative blank-token tests must pass.

## Scientific boundary

Goal 008 does not change the four analytical inputs, effort, operational
detection event membership, methods, thresholds, denominators, comparator
tables, or scientific target graph. `data/jc_op.csv` remains daily-operation
authority. `sN.run_days` remains audit-only metadata and is not effort
authority.

The CamtrapDP exporter still derives its operational envelope from the first
and last `jc_op == 1` dates. Substituting declared Goal 008 deployment spans
into export behavior is explicitly deferred to a separate compatibility
decision and packet.

## Publication and exact-SHA CI closeout

The reviewed implementation was published as exactly one commit:

- packet commit
  `478832240e77388da299e55871bdeb6e386c90c5`
  (`docs: define Goal 008 Judbury deployment evidence`);
- implementation commit
  `377c0fd4f78513885a3f2b53308e788bfa8d1cb4`
  (`feat: add Judbury deployment evidence`);
- sole parent: the exact packet commit;
- committed implementation scope: exactly 29 reviewed paths; and
- publication: normal push of `main` to `origin/main`.

Exact-SHA GitHub Actions completed successfully:

- workflow `ci`;
- event `push` to `main`;
- run
  [`30253764770`](https://github.com/BWBrook/camtrap-workflow/actions/runs/30253764770);
- job `89937521084`;
- head SHA exactly
  `377c0fd4f78513885a3f2b53308e788bfa8d1cb4`;
- conclusion `success`;
- duration `1h1m57s`; and
- every step passed through artefact upload.

The accepted evidence for that exact implementation SHA includes lint PASS,
611 authoritative-test passes, zero failures, one expected warning, zero
skips, completed bundle `20260727T082247Z-fc187bae5fa44144`, manifest SHA-256
`1d0461ae1e1073e45b0723104fbfb5e76b33b27fc4d5c8b2074ff5b170923e08`,
91 verified payloads, exact scientific invariance, and audit-only
`13/13/9/4/75/62/0` evidence with diagnostic `run_days` total 7842 and false
analytical routing.

GitHub emitted a non-failing platform annotation that `actions/checkout@v4`
and `actions/upload-artifact@v4` still target deprecated Node.js 20 and are
being forced to Node.js 24. This is workflow-maintenance information, not a
Goal 008 defect.

Goal 008 is closed as complete, published, and exact-SHA-CI-confirmed. It does
not complete Phase 3, select `analysis_site`, route effort or events, change a
scientific output, or perform a nine-station analysis. The blank-token
defence-in-depth debt remains subject to the hard future gate above.
