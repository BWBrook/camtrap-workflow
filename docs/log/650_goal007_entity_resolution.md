# Goal 007 - Versioned entity-resolution evidence

Date: 2026-07-26

## Outcome

Implemented the first bounded Phase 3 entity-resolution slice without changing
the analysis. The supported validation-only and full paths now publish
reconstructable entity records, typed links, deployment evidence, a summary,
and audit-only join readiness.

The approved Judbury evidence remains exactly:

- 13 physical locations;
- nine nominal grid stations;
- four undirected service-history move pairs;
- no authoritative deployment identity, interval, order, or direction; and
- `analysis_site = unselected` with zero memberships.

The existing analytical engine still consumes the same 13 legacy `site` keys.
No effort, observation, event, denominator, grouping, threshold, method, or
ecological module changed.

## Evidence

- Final validation preview:
  `outputs/preflight/20260726T020035Z-9105b7497a6f440d`.
- Final completed bundle:
  `outputs/runs/20260726T020411Z-d034ea6eb0164fcd`.
- Manifest 1.2 portable verification: PASS, 89 payload files.
- Manifest SHA-256:
  `a919251232462ba658f19bdda54b213a51317a6020e53df11f7b6a5099bdecb3`.
- Validation/full entity records: five of five byte-identical.
- Join readiness, source inventory, and manifest all bind source SHA-256
  `dcb6f57f79198e35c8e1bedcdd5f3d2131102f9d53f01b01a72f671df7556bb4`.
- Goal 006 scientific comparator: 13 tables and 11 Phase 2 artefacts
  byte-identical; validated inputs object-identical; occupancy delta zero.
- Lint: PASS.
- Authoritative tests: 520 PASS, zero failures, one expected export warning.
- Reclosed crosswalk mutation: rejected at the exact approved-authority gate.
- Reclosed explicit-null plus undeclared-sidecar and closed-namespace-extra
  attacks: rejected after source, payload, and completion reclosure.
- Selected Judbury authority under CamtrapDP: rejected in configuration and
  direct resolver paths.
- Duplicate and competing CamtrapDP deployment evidence retains every
  participating source-row link without creating a resolved mapping.
- Legacy verification: actual manifest 1.1 PASS; manifest 1.0 fixture PASS.

Detailed ignored evidence is in `outputs/goal007_acceptance/`.

## Publication and exact-SHA CI closeout

Goal 007 is accepted and published:

- Packet commit:
  `3d42c1cb9ad74bff107de42200122f93505e21e6`.
- Accepted implementation commit:
  `bbe5c36f4b6f138f7ae5cdf2bd947e1bf42b0c30`
  (`feat: add entity resolution evidence`).
- Independent final verdict: `PASS_IMPLEMENTATION`, after the single focused
  repair closed four material provenance and verifier defects.
- Exact-SHA GitHub Actions run:
  `https://github.com/BWBrook/camtrap-workflow/actions/runs/30184741535`;
  workflow `ci`, push to `main`, run `30184741535`, job `89747281154`, head
  SHA exactly `bbe5c36f4b6f138f7ae5cdf2bd947e1bf42b0c30`, conclusion `success`,
  duration `24m4s`.
- CI passed checkout, system dependencies, Quarto, TinyTeX, R, `renv`
  restoration, lint, unit tests, pipeline smoke testing, the full immutable
  evidence run, published evidence-bundle verification, artefact upload, and
  cleanup.

This publication confirms the bounded factual entity-resolution evidence. It
does not complete Phase 3 or constitute a nine-station analysis.

## Deferred

Goal 007 does not complete Phase 3. Authoritative Judbury deployments,
chronology, purpose-specific `analysis_site`, effort/event routing, public
fields/API/migration, resolved profile precedence, and full CamtrapDP adapter
completion remain separate decisions and implementation slices.
