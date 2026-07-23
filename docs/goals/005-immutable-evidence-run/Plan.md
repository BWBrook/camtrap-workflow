# Goal 005 - Documentation plan

The implementation is dependency-ordered and preserves current analytical
behaviour. It starts only after the packet is reviewed and published.

1. **Post-publication baseline** — require clean synchronized `main`, exact
   `HEAD^` packet-authoring hash, exact publication subject, and exact
   four-file parent-to-HEAD diff. Before the first implementation edit, run
   the full default Judbury pipeline at that packet-publication code state and
   retain ignored comparator artefacts: the named stable CSV set, model-summary
   tables, normalized methods text, RNG/session/order/canonicalisation details,
   and raw hashes. Stop if the run or comparator capture fails.
2. **Invocation identity and four fingerprints** — define fixed-clock-tested
   unique IDs, input/acquisition bytes, raw/resolved config, engine/code/
   dependency, and composite equivalence domains with explicit exclusions.
3. **Immutable acquisition snapshot** — make four-table and CamtrapDP
   local/remote acquisition explicit; inventory only parser-consumed bytes,
   pin/cache remote resources, and make parsers consume the immutable snapshot.
4. **Bundle trust root** — write manifest payload hashes, then `COMPLETED.json`
   with manifest hash/schema/run ID, atomically publish the directory, and only
   then update a traversal-safe latest pointer; reject extras and collisions.
5. **Workflow/report integration and maintenance separation** — route the
   supported full-run runner through the bundle; prevent partial/debug
   publication; expose identity without changing methods; remove dictionary
   generation from the scientific DAG while retaining maintenance tooling.
6. **Evidence and regression comparison** — add focused fixtures/tests,
   portable verification, local/mocked CamtrapDP coverage, raw comparator
   evidence for bounded CSV/model/methods sets, default Judbury run, and a
   direct partial-target smoke that cannot publish.
7. **Review, local gate, and remote confirmation** — obtain one independent
   implementation review and at most one focused repair; local acceptance
   authorizes commit/push, then `.github/workflows/ci.yml` is the final remote
   confirmation with one narrowly CI-driven correction allowed only for
   material new evidence.

Do not add raw/generated outputs, alter methods, or expand beyond the closed
allowlist in `Goal.md`. Stop on a failed gate, unresolved integrity ambiguity,
or Barry-owned scientific/product decision.
