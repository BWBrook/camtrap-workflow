# Goal 006 - Documentation plan

This dependency-ordered plan is implementation-neutral. It starts only after
Barry approves execution and the packet is published through the exact gate in
`Goal.md`.

1. **Gate and pre-change evidence** - prove the exact packet-publication
   state, then capture a full default Judbury run, raw comparator artefacts,
   current pointer bytes, source/config hashes, row counts, and relevant target
   metadata before any implementation edit.
2. **Audit identity and row accounting** - define versioned logical-resource
   and source-row identities, sidecar row dispositions, deterministic ordering,
   and invariants that detect duplication, omission, collision, or lineage
   loss for both input modes.
3. **Validation-only preflight** - extend the supported full-run runner with a
   validation-only mode that produces an immutable non-overwriting preview,
   cannot complete or render scientific output, and never changes latest.
4. **Findings and repair decisions** - separate integrity, semantic, and
   advisory findings; implement deterministic proposal/decision/application
   records; support only the bounded normalization demonstration and
   fixture-only unknown fill; reject stale, conflicting, broad, or tampered
   authority.
5. **Transformations and event lineage** - permit transformation-only adapter
   records only for strictly meaning-preserving mappings; route every
   fill-unknown or explicit-evidence replacement through proposal-specific
   authority; eliminate silent loss/collision, account for all parsed rows,
   explain excluded observations, and map each retained operational detection
   event to observation source rows without changing its gap rule.
6. **Evidence bundle integration** - cross-link Phase 2 sidecars in manifest
   schema 1.1, extend portable verification, preserve 1.0 verification, and
   update bounded report/methods/reference prose.
7. **Acceptance and publication** - exercise clean, preview, application,
   decline, protected override, stale approval, integrity, lineage-loss,
   CamtrapDP semantic-default, meaning-preserving mapping, and legacy fixtures;
   run the full comparator, pointer-state checks, lint, full tests, and default
   Judbury; obtain one independent review and at most one focused repair before
   exact-path publication and exact-SHA CI confirmation.

Do not implement Phase 3 entities or public schema, Phase 4 module planning,
new ecological methods, production operational inference, interface work, or
new dependencies.
