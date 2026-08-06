# Goal 012 - Practitioner report proof

Date: 2026-08-06

State: `IMPLEMENTATION_AUTHORIZED`

## Purpose

Prove that the lean workflow's existing results can support a concise report
that an ecologist or land manager can understand without inspecting detailed
machine tables.

## Outcome

One Judbury run and the maintained non-Judbury forest example each publish a
readable HTML report that shows:

- where and how much confirmed sampling occurred;
- observed richness together with unequal effort;
- descriptive similarity in detected community composition;
- the species with the highest operational-event rates per confirmed effort;
- broad day/night patterns; and
- nearby warnings and limits on what each result can support.

The complete emitted tables remain unchanged in the audit bundle. The report
may reshape those tables for display but must not recalculate ecological
results or introduce a new analysis module.

## Boundaries

- Keep implementation in `analysis/report.qmd` unless a tiny supporting change
  is required to render the existing outputs.
- Use existing dependencies only.
- Keep no more than one focused report smoke test.
- Explain Judbury's approved 13-location to nine-site grouping only for the
  Judbury profile.
- Do not add seasonal, trend, occupancy, unseen-richness, habitat, GUI,
  container, AI, schema, compatibility, provenance, or dashboard work.

## Acceptance

1. Lint, the fast suite, and `git diff --check` pass.
2. Judbury and forest-example full runs publish independently verifiable
   bundles without changing accepted ecological tables or arithmetic.
3. Both reports are visually inspected at desktop width and are legible,
   concise, and free of the former full day/night table dump.
4. One focused self-review and at most one material repair pass are complete.
5. Remaining issues are cosmetic, speculative, or belong to a later
   scientific module.
