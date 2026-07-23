# Goal 005 — Packet Log

- **Canonical status:** `COMPLETE`
- **Packet date:** 2026-07-23 AEST
- **Execution status:** `PUBLISHED_CI_CONFIRMED`
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

## 2026-07-23 implementation checkpoints

### Publication and baseline gate

- Clean synchronized `main` confirmed at
  `a1754da73c16d182a24bf343f872d12a03bfea11`, with required parent
  `17761af107dc43399e223e35e2fd130f24ab05e6`, exact publication subject, and
  exact four-file parent diff.
- The required pre-change default Judbury run completed 130 targets with zero
  skipped targets in 34.9 seconds. The model confidence-boundary and
  beta-distance warnings matched the established workflow behaviour.
- The legacy scientific run left tracked status clean. SHA-256 values for
  `data_dictionary.md` and `data/data_dictionary.csv` were unchanged.
- Ignored evidence under `outputs/goal005_acceptance/pre/` records the packet
  state, full target log, all 10 stable comparator CSVs, three occupancy model
  summary tables, normalized methods text, session/package and selected target
  seed metadata, row/order/canonicalisation policy, full output hashes, and
  raw input/config/schema/lockfile hashes.
- The shell capture wrapper attempted to assign zsh's read-only `status`
  variable after the successful target run. This did not affect the completed
  pipeline or captured stdout; the evidence status records the harness
  postamble defect explicitly.

### Core implementation

- Added distinct invocation allocation and content-equivalence fingerprints
  for parser-consumed source bytes, raw/resolved configuration, engine state,
  and their canonical composite.
- Added immutable four-table and CamtrapDP snapshots. Supported runs parse the
  snapshot, recheck it before publication, pin remote descriptor/resource
  digests, and use a SHA-256-addressed cache.
- Added exact payload manifests, terminal `COMPLETED.json`, collision-safe
  staging publication, portable verification, and a regular-file
  `outputs/latest` resolver that rejects traversal, separators, symlinks, and
  unknown targets.
- Integrated the supported publisher, authoritative report identity, legacy
  compatibility label, unpublished direct-target work area, dictionary DAG
  separation, container/CI migration, focused fixtures/tests, and user
  documentation.
- First supported template invocation completed the full graph and published a
  verifier-clean bundle at
  `outputs/runs/20260723T061226Z-7b6fc88ac95443c8/`. Its source, raw/resolved
  config, engine, and composite fingerprints were recorded in the ignored
  acceptance evidence.
- Initial authoritative test run: 219 passes, one expected warning, and one
  test-harness failure in a `tar_manifest()` call executed outside the project
  directory. The test was corrected to use the project directory and
  in-process manifest evaluation; the focused pipeline smoke then passed
  seven checks.

### Acceptance evidence

- The final repaired sequential pair is
  `20260723T070047Z-231de4a8bec242d8` and
  `20260723T070142Z-89bd0cc6bade4c0a`. The IDs differ; all 74 files in the
  first completed bundle remained byte-identical after the second invocation.
- Both runs record the same source
  `2f814da19bb8c1e6952ef73c2eed2d7fc0a8168b356116c64315afe963c31651`,
  raw config
  `7aaaebad92216e596d46d95e6e2c6b3e8da2ceb9c8bf33270a8414f5d5aa7cdd`,
  resolved config
  `1642cbb55dc60a8c112d79ef9a2cf760f41d820dbe5325f49ef11e8a95024765`,
  engine
  `f2d6b598e22c27c373974cb3f92ad43d81c02f82ff364bd894a9c694ccf21913`,
  and composite
  `09565ed2dfe26167b39019acf43d0375e9b90625edea14f1e575515117be9768`
  fingerprints.
- Each repaired manifest inventories 72 payload files, including the exact
  `provenance/config.raw.yml`; engine identity records 139 installed lockfile
  package versions. Both in-place bundles and an unrelated copied bundle pass
  portable verification.
- A same-size one-byte change in a copied observation file changed source and
  composite identity while raw/resolved config and engine identity stayed
  fixed. Target metadata showed source snapshot, raw ingest, validation,
  event, detection-history, report-input, and manifest descendants reran.
- Injected failure after snapshot creation and a deliberate completed-ID
  collision both failed without changing prior `latest` bytes or the prior
  completed bundle. The failed staging directory and runtime context were
  removed.
- Artifact tamper, exact-payload additions, absolute/traversal/separator/
  symlink/unknown pointers, internal payload symlinks, missing CamtrapDP
  resources, pinned-digest mismatch, and checksum-reclosed but internally
  inconsistent provenance all fail verification.
- Equivalent YAML fixtures have different raw hashes and the same resolved
  hash. Local and mocked-remote CamtrapDP fixtures inventory exact descriptor
  and resource bytes before parsing; a descriptor whitespace-only change
  changes source identity, and the second remote acquisition is cache-only.
- The final scientific comparator reports exact parsed and byte equality for
  all 10 stable tables, zero numerical difference in all three occupancy
  model tables, and equal methods text after removing only run-directory
  identity and whitespace wrapping. `scientific_equal` is `true`.
- The exact direct template-config partial target completed two targets,
  created no completion record, and left `outputs/latest` unchanged. The
  separate dictionary maintenance command and sync test passed with both
  tracked dictionary files byte-identical before and after.
- Final authoritative local checks: `Rscript scripts/run_lint.R` PASS;
  `Rscript scripts/run_tests.R` 245 PASS, 0 FAIL, 1 expected CamtrapDP export
  warning, 0 SKIP; `git diff --check` PASS.

### Independent review and repair

- The first independent implementation review returned
  `REPAIR_IMPLEMENTATION`. It found checksum closure without recomputed
  provenance cross-links, a live-config reread gap, reserialized CamtrapDP
  descriptor bytes, missing installed-package versions in engine identity,
  and incomplete internal-symlink rejection.
- One permitted focused repair addressed all five findings: the runner and
  target graph now share one exact raw-config snapshot; the verifier
  recomputes source/config/engine/composite and status cross-links; CamtrapDP
  preserves exact descriptor bytes; engine identity records installed
  lockfile package versions; and lexical path walking rejects internal
  symlinks. Adversarial tests cover each defect.
- The bounded repair recheck returned `ACCEPT_IMPLEMENTATION` with no remaining
  material findings. It independently reproduced bundle, fingerprint,
  immutability, scientific, methods, package-version, and portable-verifier
  evidence.

## Handoff and stop rule

Local implementation acceptance and publication are complete. Commit
`d40689c883d00d6d71740a440196507a558461f2`
(`feat: add immutable evidence runs`) was pushed to `origin/main`.

Exact-SHA GitHub Actions run
[`29987722220`](https://github.com/BWBrook/camtrap-workflow/actions/runs/29987722220)
completed successfully for that commit. Job `89143227550` succeeded in 3m51s:
checkout, system dependencies, Quarto, TinyTeX, R, `renv` restore, lint, unit
tests, pipeline smoke, the full immutable evidence run, bundle verification,
and artifact upload were all green. Unexpired artifact
`immutable-evidence-bundle` has ID `8555780919`, size 7,089,890 bytes, and
expires 2026-10-21.
