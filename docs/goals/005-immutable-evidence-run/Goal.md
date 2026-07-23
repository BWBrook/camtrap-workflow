# Goal 005 - Immutable evidence run

## Objective

Implement the already-authorized Phase 1 immutable evidence-run foundation.
Every completed full evidence-run invocation receives a unique,
filesystem-safe identity and publishes a self-verifying evidence bundle.
Source bytes, effective configuration, engine metadata, reports, exports, and
status are tied together by SHA-256 fixity records. A later invocation may be
recognised as equivalent by content fingerprints, but invocations are never
collapsed, overwritten, or silently reused by this goal.

This packet is executor-ready. It defines behaviour and an implementation
boundary; it does not implement the workflow. After orchestrator review and
publication of this four-file packet, execution may begin without another
Barry approval gate. Local acceptance plus orchestrator review authorizes the
implementation commit and push; post-push CI is the final remote confirmation.

## Baseline and operating mode

- Work only in `/Users/bwbrook/git/camtrap-workflow`.
- Packet authoring was performed from clean `main` at
  `17761af107dc43399e223e35e2fd130f24ab05e6`; this is the `HEAD^` required
  after packet publication, not the execution HEAD itself.
- Execution starts only after a packet-publication commit. At that point
  require clean synchronized `main`, `HEAD^` exactly
  `17761af107dc43399e223e35e2fd130f24ab05e6`, HEAD subject exactly
  `docs: define Goal 005 immutable evidence run`, and an exact four-file
  `HEAD^..HEAD` diff containing only this packet. If any check differs, stop.
- The current ecological methods, analytical estimands, report content, and
  output meanings remain unchanged.
- No raw data or generated run output is committed to this repository.
- No live network is required for tests; CamtrapDP tests use local fixtures or
  mocked acquisition responses.

## Accepted identity policy

The supported full-run entrypoint is the definition of an invocation. A
successful invocation receives one unique ID even when it has the same source
bytes, configuration, and engine as an earlier invocation. IDs are created for
the invocation and are not derived solely from a content hash. A same-second
rerun therefore receives a different ID. Content and composite hashes identify
equivalent evidence and may enable a future, explicit reuse operation; reuse
is not implemented here.

The legacy configuration field `run_id` is retained as a compatibility label
and may be displayed in reports. It is not authoritative for filesystem
identity, latest selection, manifest identity, or collision handling.

## Required behavioural contracts

1. The supported full-run entrypoint defines a complete invocation. Partial,
   debug, or ad-hoc `tar_make()` calls cannot publish `completion` or update
   `latest`.
2. One filesystem-safe ID agrees exactly across the run directory, report,
   canonical effective configuration, manifest, status record, and latest
   pointer target.
3. Before parsing, materialise an immutable input snapshot and make parsers
   consume it. Record an explicit SHA-256 inventory of every data/package byte
   actually consumed by parsers, plus schema/version files as applicable;
   report templates are not source inputs. Changed bytes invalidate the source
   identity and all ingest descendants; post-snapshot mutation or pinned-digest
   mismatch is an integrity failure.
4. CamtrapDP local and remote acquisition modes are explicit. Cached resources
   and every parser-consumed referenced resource are inventoried. Ordinary
   pre-invocation byte changes create a new valid source/composite identity;
   missing or unavailable resources, post-snapshot mutation, or pinned-digest
   mismatch fail integrity checks before analysis.
5. The bundle stores canonical current effective configuration with both raw
   and resolved SHA-256 values. Phase-3 profile/schema negotiation is out of
   scope.
6. A versioned manifest contains the exact relative payload inventory (all
   payload files except `run_manifest.json` and `COMPLETED.json`), with path,
   byte size, and SHA-256, including report, `report_inputs.rds`, and exports.
   `COMPLETED.json` is written last in staging and records manifest SHA-256,
   manifest schema, and run ID; directory publication then occurs atomically.
   The verifier checks completion -> manifest -> exact payload set and rejects
   extras. These internal hashes provide tamper evidence, not authenticity or
   signing.
7. Completion is published last. A failure after directory publication but
   before `latest` may leave a valid discoverable completed bundle while the
   prior pointer remains unchanged; report this state and never mutate either
   bundle.
8. Completed directories are immutable and non-overwriting. Collisions,
   failure cleanup, tampering, and pointer traversal are handled explicitly.
9. `latest` is updated atomically only after successful completion and is
   resolved through a portable, traversal-safe resolver.
10. Scientific execution leaves tracked repository files unchanged. Remove
    data-dictionary generation from the scientific DAG while retaining
    `scripts/update_data_dictionary.R` and a maintenance sync test.

## Scope and permitted implementation boundary

Implementation may modify only this closed allowlist (existing files are
listed explicitly; new files are listed explicitly):

- `_targets.R`;
- existing `R/config.R`, `R/input_loader.R`, `R/camtrapdp_adapter.R`, and
  `R/run_manifest.R`;
- new focused `R/run_identity.R`, `R/source_inventory.R`,
  `R/config_identity.R`, `R/run_bundle.R`, and `R/fixity.R` (omit a listed
  new file if unused; do not invent another module);
- `scripts/run_full_evidence_run.R`; `analysis/report.qmd`;
- `config.yml`, `config.template_example.yml`, `config.forest_example.yml`,
  `config.camtrapdp_example.yml`, and `config.camtrapdp_export.yml`;
- `README.md`, `GETTING_STARTED.md`, `docs/reference/config.md`,
  `docs/reference/run_manifest.md`, `docs/reference/output_schema_v0.1.md`,
  `docs/container.md`, `Dockerfile`, `.github/workflows/ci.yml`, and
  conditional `renv.lock`;
- existing focused tests `tests/testthat/test_run_manifest.R`,
  `tests/testthat/test_camtrapdp_adapter.R`,
  `tests/testthat/test_pipeline_smoke.R`; new
  `tests/testthat/test_run_identity.R`,
  `tests/testthat/test_source_inventory.R`,
  `tests/testthat/test_config_identity.R`, and
  `tests/testthat/test_run_bundle.R`;
- prefix `tests/testthat/fixtures/goal005/`;
- `docs/goals/005-immutable-evidence-run/Log.md`,
  `docs/log/630_goal005_immutable_evidence_run.md`, `docs/decisions.md`, and
  `docs/roadmap.md`.

Any other path requires stop and escalation. Require exact changed-path
subset proof and no generated or raw output. Do not add a Phase-3 profile or
schema, new ecological methods, inferential thresholds, GUI, hosted service,
or network dependency.

## Required evidence ladder

The implementation is accepted only when all of the following evidence is
available:

- an injectable/fixed-clock allocator test proves same-second uniqueness,
  followed by two sequential supported full invocations with distinct safe
  IDs; concurrent full runs are not required;
- an unchanged rerun preserves the first completed bundle and records matching
  source/config/engine equivalence fingerprints;
- a one-byte source mutation changes source and composite identity and reruns
  ingest descendants;
- an injected failure leaves the prior `latest` pointer unchanged;
- collision, bundle tamper, and pointer traversal tests fail safely;
- directory, report, manifest, status, and pointer identities agree;
- semantically equivalent resolved configurations share a resolved hash while
  distinct raw serialisations may have different raw hashes;
- a portable verifier validates a copied bundle without repository paths;
- local and mocked CamtrapDP acquisition, cache, inventory, and missing/
  changed-resource failure paths are covered;
- data-dictionary generation is absent from the scientific DAG while its
  maintenance script and sync test remain functional;
- deterministic pre/post comparisons show scientific outputs and methods are
  unchanged;
- lint and the authoritative full `Rscript scripts/run_tests.R` pass, followed
  by one full default Judbury run and a direct partial-target smoke using the
  existing template config that cannot advance completion or `latest`;
- post-publication `.github/workflows/ci.yml` completes with the new bundle
  contract.

No live external network call is a mandatory test condition.

## Acceptance and review rules

Use the acceptance ladder in `Runbook.md` in dependency order. The packet has
one independent read-only review and this single permitted repair. The
implementation has one independent review and at most one focused repair.
Static packet checks only are permitted while preparing this packet: no R,
tests, builds, workflow runs, or Git publication.

Local acceptance plus the independent implementation review authorizes the
orchestrator to stage, commit, and push. Post-push GitHub Actions is the final
remote confirmation. If CI fails, preserve honest `NOT_FINAL` state and allow
one narrowly CI-driven correction only when it is material new evidence.

## Authority, stop conditions, and final return

Barry retains authority over any change to ecological methods, estimands,
public schemas, profile membership, thresholds, GUI/deployment, or reuse
semantics. Stop and escalate if the baseline differs, source or artifact
integrity cannot be represented, a required behaviour conflicts with the
current engine, or the permitted path boundary is insufficient.

The implementation return reports changed paths, local acceptance evidence,
review verdict, commit/push and CI state, raw comparator evidence, remaining
caveats, and final Git state. Identity-only differences are allowed; binary
HTML/PDF/RDS equality is not claimed. Packet-authoring evidence remains in
`Log.md`.
