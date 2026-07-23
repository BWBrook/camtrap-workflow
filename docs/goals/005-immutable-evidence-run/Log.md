# Goal 005 — Packet Log

- **Canonical status:** `PACKET_READY`
- **Packet date:** 2026-07-23 AEST
- **Execution status:** `NOT_STARTED`
- **Packet-authoring baseline:** clean `main` at
  `17761af107dc43399e223e35e2fd130f24ab05e6`.
- **Execution gate:** after publication, clean synchronized `main` with
  `HEAD^` exactly that hash, HEAD subject exactly the packet commit subject,
  and exact four-file `HEAD^..HEAD` diff.
- **Packet publication commit:** `docs: define Goal 005 immutable evidence run`

## Exact packet paths

- `docs/goals/005-immutable-evidence-run/Goal.md`
- `docs/goals/005-immutable-evidence-run/Plan.md`
- `docs/goals/005-immutable-evidence-run/Runbook.md`
- `docs/goals/005-immutable-evidence-run/Log.md`

No raw data, generated outputs, execution artefacts, or other goal files are
part of this packet.

## Accepted authority and policy

Barry authorized the Phase 1 immutable evidence-run implementation. Every
completed supported full-run invocation receives a unique filesystem-safe ID.
Equivalent source/config/engine content is represented by fingerprints; runs
are never collapsed or overwritten, and explicit reuse is not implemented.
The legacy `run_id` configuration field remains a compatibility label only.

The packet covers source SHA-256 inventories before parsing, explicit local or
mocked-remote CamtrapDP acquisition and resource fixity, canonical raw and
resolved configuration hashes, versioned relative artifact manifests,
completion-last publication, non-overwriting bundles, and atomic portable
`latest` resolution. It also separates data-dictionary maintenance from the
scientific DAG while preserving the script and sync test.

## Static authoring record

- Authoring mode: documentation/static checks only.
- Baseline gate observed: clean `main` at the required hash with upstream
  `origin/main`; no fetch or reconciliation performed.
- Required paths created: exactly the four packet files above.
- Review allowance: one independent packet review and at most one repair;
  implementation receives one independent review and at most one focused
  repair.
- Independent packet review: `REPAIR_PACKET`.
- Repair record: one permitted material packet repair applied; no second repair
  or implementation work started.
- Permitted implementation surface is listed in `Goal.md`; no implementation
  has started.
- No R/runtime, test, build, targets execution, network acquisition, stage,
  commit, push, or GitHub publication occurred while creating this packet.

## Validation record

Static packet checks completed before handoff:

- line counts after `REPAIR_PACKET`: Goal 184, Plan 38, Runbook 311, Log 78;
- exact directory scope: four expected files and no other packet path;
- UTF-8 decoding, no tabs, no trailing whitespace, balanced Markdown fences,
  and forbidden marker scan: PASS;
- `git diff --check`: PASS;
- per-file `git diff --no-index --check /dev/null` checks for each packet file:
  PASS;
- final status: `main...origin/main` with only the untracked packet directory
  and an empty index.

The orchestrator must review and publish this exact packet before execution;
the packet executor must not stage, commit, or push.

## Handoff and stop rule

After packet publication, execution may begin without another Barry gate. Stop
for a failed baseline, scope expansion, integrity ambiguity, mandatory live
network dependency, or any scientific/product decision not already accepted.
Final execution reporting must include raw acceptance evidence, changed paths,
commit/push and CI state, residual caveats, and final Git status.
