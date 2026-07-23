# Camtrap Workflow — Goal 004 product blueprint

## Purpose and status

This is a documentation-only product contract. It preserves the current
analytical engine and makes the input, eligibility, provenance, output, and
validation boundaries reviewable before implementation. Statements below are
labelled as accepted facts, observations, inferences, recommendations, or
open authority so that a design recommendation is not mistaken for an
implemented feature.

## Product promise

Camtrap Workflow takes labelled camera-trap records and turns them into clear, reproducible ecological reports. It runs the analyses the data can support, skips those they cannot, explains why, and keeps a complete record of how every result was produced.

The intended functional flow is:

`input -> immutable ingest -> validation/repair preview -> entity/effort/event resolution -> capability plan -> eligible modules -> primary/audit/machine outputs`

The product starts after image labelling. It does not classify imagery. A
versioned, simple CSV input is the approachable contract; a CamtrapDP adapter
can translate to and from the same resolved internal contract. Public field
names and a final API remain open authority.

## User journey

1. The practitioner selects labelled record files and deployment metadata and
   chooses a named profile. The source files stay where they are; the run
   records their identities rather than editing them.
2. Camtrap Workflow inventories the inputs, checks the versioned contract, and
   shows a validation result. If a repair is useful, it presents a preview of
   before/after values and a traceable approval ledger. The source rows remain
   immutable.
3. The workflow resolves nominal stations, physical locations, deployment
   intervals, source rows, effort states, and operational detection events.
   Derived `analysis_site` mappings are named and versioned for their purpose;
   they are not silently inferred from coordinate proximity or identifier
   suffixes.
4. Before expensive analysis, a capability plan states which modules are
   eligible, omitted, or blocked, with prerequisites, consequences, and the
   next evidence that could unlock an omission.
5. One deterministic engine runs the eligible standard or advanced modules.
   The modes are views over the same resolved contract, not separate
   analytical implementations. A global integrity failure stops the run;
   analytical ineligibility is fail-soft.
6. The practitioner receives a concise primary evidence report, a detailed
   audit bundle, and machine-readable artefacts. Every module has a status and
   each result points back to source, configuration, method, and run identity.

## Contract boundaries

### Input and lineage

- Accepted input is post-labelling record rows plus the deployment/effort
  context needed by a selected profile. A simple versioned CSV contract is
  canonical for the first product boundary; CamtrapDP compatibility is an
  adapter, not a second engine.
- Input bytes and source-row identifiers are immutable. A repair may create a
  repaired view only after a preview and recorded approval basis; it never
  overwrites the source.
- The run inventory records file or package identity, checksum, source scope,
  acquisition/cache state where relevant, and provenance. Local/private-first
  operation is the default and implies no unrequested network egress.
- Every invocation receives a unique run ID. Content hashes identify equivalent
  inputs and may support explicit evidence reuse, but distinct invocations are
  never collapsed or erased.
- Input selection scope, supplied label provenance, verification state, and
  optional media/activity classes are retained when supplied. Missing optional
  metadata remains unknown rather than being fabricated.

### Entities, effort, and events

The internal contract keeps these entities distinct:

- `nominal_grid_station`: the survey-design label (nine in the Judbury
  fixture);
- `physical_location`: a camera position (13 in the Judbury fixture);
- `deployment`: one camera deployment interval, including moves and its
  evidence;
- `analysis_site`: a versioned derived grouping for a named analytical
  purpose, with no grouping selected by this goal;
- source record and operational detection event: immutable row lineage and a
  configurable cluster of rows, not a claim of an independent animal.

Effort is conservative. Deployment intervals are the default effort evidence,
so a confirmed operating interval can support a zero detection while an
unknown or interrupted interval remains missing/uncertain. Optional reviewed
and audited inference may use last images or other operational evidence; it
must remain explicitly uncertain, record its override basis, and never silently
infer camera-failure time. Named temporal occasions and spatial resolutions are
recorded in the resolved configuration and every applicable output.

### Eligibility and statuses

Core input corruption, unreadable files, broken keys, or an invalid run
identity are integrity failures and stop the run. A module lacking scientific
prerequisites is omitted without erasing successful results. Each requested
module returns one of `completed`, `completed_with_warnings`, `omitted`, or
`failed`, with prerequisites, consequences, remediation, warnings, inputs,
outputs, and named spatial/temporal schemes.

The capability tiers are `foundation`, `standard_profile`, `conditional`, and
`later_option`. Current-state dispositions are `retain`, `refactor`,
`quarantine`, `replace`, and `new`; the full map is in
`capability_map.csv`. In particular, hidden source reads, mutable `latest`
and split run IDs, scientific-run mutation of the data dictionary, the strict
Judbury-shaped schema, unconditional occupancy/trait inference, placeholder
module outputs, and the monolithic report are bounded by the dispositions in
that map. No engine rewrite or deletion is proposed.

## Output contract

The three output layers are deliberately separate but share one run identity:

- **Primary:** a concise ecological evidence report containing the eligible
  standard profile, claim boundaries, warnings, and explicit omissions.
- **Audit:** a detailed bundle containing the resolved contract, validation and
  repair ledger, module statuses, event membership, effort evidence, and
  provenance/fixity records needed to inspect a result.
- **Machine:** stable tables and a machine-readable result/status index for
  reuse, comparison, and downstream interfaces.

The deterministic report remains complete and authoritative. Any future
interpretation assistant would be a downstream, review-gated adapter over the
machine layer, never a substitute for the primary report.

## Judbury validation fixture

Judbury is a validation fixture, not a universal schema or an ecological
grouping decision: nine nominal stations, 13 physical locations, four camera
moves, and no pre-decided grouping. The matrix
`judbury_validation_matrix.csv` tests clean success, unchanged rerun and
input-change invalidation, conservative effort and operational events, the
retained descriptive modules, and principled omission of occupancy and traits.
It also includes an independent/synthetic CamtrapDP portability fixture and a
separate LocalMap-manifest boundary case so failures are attributable. A
successful module is not evidence that an omitted inferential module is
scientifically suitable.

### Worked example: what a practitioner sees

For a Judbury-like upload, the practitioner sees a camera move represented as
an old deployment ending and a new deployment beginning at a distinct
physical location; both remain linked to the same named grid station. One
interval has unknown effort, so its non-detections are not silently converted
to zeros.
A proposed date repair appears as a before/after preview with an approval
record; the original row remains unchanged. Effort/QC, operational events,
observed richness, descriptive turnover, relative detection, and coarse
day/night complete with scale and effort caveats. Occupancy is omitted because
the site crosswalk and design gate are unresolved, with the missing evidence
and consequence stated. The primary report is readable, the audit bundle shows
the repair, lineage, capability decisions and manifest, and machine artefacts
carry the same run identity for reuse.

### Compact glossary

- **Immutable:** source bytes and source-row identities are not overwritten by
  validation or repair.
- **Provenance:** evidence of where a value or artefact came from, including
  source identity, rule, version, and approval when applicable.
- **Capability plan:** the pre-run decision record of eligible, omitted, or
  blocked modules and the evidence required for each decision.
- **Operational detection event:** a configurable cluster of labelled rows for
  analysis; it is not a claim that one animal or one independent encounter
  occurred.
- **Run manifest:** the versioned machine-readable record tying inputs,
  configuration, engine, module statuses, and outputs to one run identity.
- **Profile:** a named, versioned set of resolved choices and eligibility
  expectations.
- **Adapter:** a bounded translator between an input or interchange format and
  the one resolved internal contract; it is not a parallel analysis engine.

## LocalMap boundary and portability

LocalMap is an independent file-plus-manifest provider. Camtrap Workflow
consumes validated files and a manifest containing file inventory,
identifiers, checksums/versioning, generator and source provenance,
CRS/spatial-temporal coverage, processing parameters, licences, and explicit
error or placeholder states. It does not read LocalMap code, targets, cache,
or a live network service; either repository can version and rerun
independently. Geo-format and manifest details remain design options, not
implementation commitments. Judbury plus the additional portability fixture
in the matrix are the minimum evidence cases for a future software note.

## Current-state reconciliation

The existing R/targets engine and its exercised descriptive analyses are
assets to preserve. The product boundary records these observations and
design responses:

| Observation | Design response | Evidence class |
| --- | --- | --- |
| Source files and URLs are opened beneath a single target. | Inventory explicit source identities before parsing. | observed / recommendation |
| Configured folder identity, manifest timestamp, and mutable `latest` can diverge. | Use one immutable run identity and make `latest` only a replaceable pointer. | observed / recommendation |
| A scientific target can rewrite the tracked data dictionary. | Remove repository mutation from the run boundary and record maintenance separately. | observed / recommendation |
| Strict Judbury-shaped fields are required for every input. | Keep a Judbury compatibility profile while defining a small core and optional extensions. | observed / recommendation |
| Occupancy and trait inference currently run unconditionally. | Make prerequisites explicit; quarantine/omit them when the design gate is not met. | observed / recommendation |
| Disabled modules emit placeholder paths and one broad report mixes layers. | Emit structured statuses and partition primary, audit, and machine outputs. | observed / recommendation |

## Non-goals and authority

This blueprint does not select public field names or API, ecological grouping,
thresholds, GUI, installer/deployment substrate, ALA/regional extension, AI
provider or behaviour, journal, publication claim, or a replacement engine.
Barry retains those decisions and any irreversible scientific or product
commitment. Adapters and refactors named here are design-level boundaries
only.

## Recommended next goal

The accepted next implementation goal is the **immutable evidence-run
foundation**: explicit source inventory and content identity, one unique run ID
per invocation and manifest, safe `latest` pointer semantics, resolved
configuration identity, output fixity, and separation of repository
maintenance from a scientific run. Content hashes may support explicit reuse
of equivalent evidence, but distinct invocations are never collapsed or
erased. Barry has authorized this Phase 1 implementation goal; it remains
outside Goal 004's implementation scope.
