# Goal 004 execution runbook — product blueprint

## Purpose and gate

This runbook governs the documentation-only execution of Goal 004 after Barry
authorised execution on 2026-07-23 and the orchestrator has reviewed, committed,
and pushed the four-file packet. No further Barry approval gate is required to
start execution. It produces exactly five design files plus the execution
update to Log.md (six changed paths total); it does not alter the analysis
engine.

Before starting, confirm a clean, synchronized `main` at the later Goal 004
packet-publication commit, with all four packet files tracked and
`c33488b719d773fe8b181a54ebe7d01bfcd73599` as an ancestor. That hash is the
accepted pre-packet Goal 003 baseline, not the required execution HEAD. Record
the exact branch, HEAD, tracking state, and status. If any part differs, stop;
do not fetch or reconcile.

## Authority, roles, and permitted evidence

Barry retains authority over public schema/API, GUI, deployment, scientific
methods, ecological grouping, thresholds, ALA/AI scope, software-note claims,
and irreversible engine or product commitments. The orchestrator owns packet
review and publication. Up to two read-only scouts may collect bounded
evidence, and one reviewer who did not author the durable packet performs a
read-only review. There is at most one material repair pass; the writing
executor owns the content.

Read only bounded, current repository documentation needed to substantiate the
contract. Do not copy bulky history, raw data, secrets, or generated artefacts.
Keep work within `/Users/bwbrook/git/camtrap-workflow` and the paths named
below. No R/runtime execution, external research, code, schema/config
implementation, workflow execution, or Git publication is permitted during
execution. Preserve the current engine; describe adapters/refactors at design
level only.

Read first, in this order: the Goal 002 audit/renovation roadmap, the Goal 003
HorizonScan/decision register, then only bounded current product documentation
needed for the contract. Reconcile these current-state constraints explicitly:
hidden source reads; mutable `latest` and mismatched run IDs; scientific-run
mutation of the tracked data dictionary; strict Judbury schema treated as
universal; unconditional occupancy/trait inference; placeholder module
outputs; and a monolithic report. Keep the existing engine and delete nothing
by default; represent each item as a disposition, quarantine, or bounded
refactor decision.

## Exact outputs and content contract

Execution creates exactly these five design files under
`docs/design/004-product-blueprint/`:

1. `ProductBlueprint.md`
2. `capability_map.csv`
3. `judbury_validation_matrix.csv`
4. `development_roadmap.md`
5. `decision_register.md`

In addition, append the execution record to
`docs/goals/004-product-blueprint/Log.md`; create no other file and do not
modify Goal.md, Plan.md, or Runbook.md during execution.

`ProductBlueprint.md` must contain the exact product sentence from Goal.md:

> Camtrap Workflow takes labelled camera-trap records and turns them into clear, reproducible ecological reports. It runs the analyses the data can support, skips those they cannot, explains why, and keeps a complete record of how every result was produced.

It must also contain this exact functional flow:

`input -> immutable ingest -> validation/repair preview -> entity/effort/event resolution -> capability plan -> eligible modules -> primary/audit/machine outputs`

The capability map uses the exact header
`capability_id,capability_name,tier,disposition,depends_on,eligibility_rule,omission_reason,output_layer,engine_anchor,target_phase,judbury_role,evidence_refs,authority,notes`
and enums in the embedded validator;
the Judbury matrix uses its exact header and the stable case IDs below. The
roadmap has phases 1–8 or fewer, each with `Outcome`, `Dependencies`, `Exit
evidence`, `Non-goals`, and `Decision gate`. The decision register is a
Markdown table whose exact header is `| ID | Decision | Rationale/evidence | Owner/authority | Dependency | Reversibility | Status | Next evidence | Blocks next goal |`; every status cell is exactly `open_now` or `defer_until_gate`.

## Stable Judbury case IDs

The validator requires these explicit case IDs in
`judbury_validation_matrix.csv`: `JUD-01-nominal-stations` (nine nominal
stations), `JUD-02-physical-locations` (13 physical locations),
`JUD-03-camera-moves` (four moves), `JUD-04-no-grouping` (no pre-decided
ecological grouping), `JUD-05-clean-success`, `JUD-06-rerun-unchanged`,
`JUD-07-rerun-input-change`, `JUD-08-conservative-effort-time`,
`JUD-09-operational-events`, `JUD-10-richness-turnover`,
`JUD-11-relative-detection`, `JUD-12-day-night`, `JUD-13-occupancy-omission`,
`JUD-14-traits-omission`, and `JUD-15-additional-portability`.

## Validation ladder

Run static checks only. Syntax-check the future-output validator below when
the packet is created; execute it only once all five design outputs exist.
Keep links, trailing whitespace, `git diff --check`, and exact six-path Git
scope as explicit shell/manual checks unless separately implemented; the
Python validator does not claim to check them.

```python
import ast, csv, re, sys
from pathlib import Path

ROOT = Path(sys.argv[1])
EXPECTED = {
    "ProductBlueprint.md", "capability_map.csv", "judbury_validation_matrix.csv",
    "development_roadmap.md", "decision_register.md",
}
assert {p.name for p in ROOT.iterdir()} == EXPECTED
CAP = ROOT / "capability_map.csv"
JUD = ROOT / "judbury_validation_matrix.csv"
BP = ROOT / "ProductBlueprint.md"
ROAD = ROOT / "development_roadmap.md"
DEC = ROOT / "decision_register.md"
CAP_H = "capability_id,capability_name,tier,disposition,depends_on,eligibility_rule,omission_reason,output_layer,engine_anchor,target_phase,judbury_role,evidence_refs,authority,notes".split(",")
JUD_H = "case_id,scenario,fixture_facts,mutation_or_input_change,expected_resolution,expected_module_status,expected_output_layer,omission_reason,provenance_evidence,pass_criterion".split(",")
TIERS = {"foundation", "standard_profile", "conditional", "later_option"}
DISP = {"retain", "refactor", "quarantine", "replace", "new"}
REQUIRED_CASE_IDS = {
    "JUD-01-nominal-stations", "JUD-02-physical-locations", "JUD-03-camera-moves",
    "JUD-04-no-grouping", "JUD-05-clean-success", "JUD-06-rerun-unchanged",
    "JUD-07-rerun-input-change", "JUD-08-conservative-effort-time", "JUD-09-operational-events",
    "JUD-10-richness-turnover", "JUD-11-relative-detection", "JUD-12-day-night",
    "JUD-13-occupancy-omission", "JUD-14-traits-omission", "JUD-15-additional-portability",
}
PRODUCT_SENTENCE = ("Camtrap Workflow takes labelled camera-trap records and turns them into clear, "
                    "reproducible ecological reports. It runs the analyses the data can support, "
                    "skips those they cannot, explains why, and keeps a complete record of how every "
                    "result was produced.")
FLOW = "input -> immutable ingest -> validation/repair preview -> entity/effort/event resolution -> capability plan -> eligible modules -> primary/audit/machine outputs"

def table(path, header):
    with path.open(newline="", encoding="utf-8") as fh:
        rows = list(csv.reader(fh))
    assert rows and rows[0] == header, (path, rows[:1])
    assert all(len(row) == len(header) for row in rows), path
    return rows[1:]

caps = table(CAP, CAP_H)
ids = {r[0].strip() for r in caps}
assert len(ids) == len(caps) and all(ids) and all(r[0].strip() for r in caps)
for row in caps:
    assert row[2] in TIERS and row[3] in DISP
    assert all(dep in ids for dep in row[4].split(";") if dep)
graph = {r[0]: [d for d in r[4].split(";") if d] for r in caps}
state = {}
def visit(node):
    assert state.get(node, 0) != 1, "cyclic dependency"
    if state.get(node, 0) == 2:
        return
    state[node] = 1
    for dep in graph[node]: visit(dep)
    state[node] = 2
for node in graph: visit(node)

jud = table(JUD, JUD_H)
jud_ids = {r[0].strip() for r in jud}
assert len(jud_ids) == len(jud) and all(jud_ids) and all(r[0].strip() for r in jud)
assert REQUIRED_CASE_IDS <= jud_ids
for path in (BP, ROAD, DEC, CAP, JUD):
    s = path.read_text(encoding="utf-8")
    for marker in ("T" + "ODO", "T" + "B" + "D", "F" + "IXME", "D" + "R" + "AFT", "X" + "XX"):
        assert marker.lower() not in s.lower()
    if path.suffix == ".md": assert s.count(chr(96) * 3) % 2 == 0
bp = BP.read_text(encoding="utf-8")
assert PRODUCT_SENTENCE in bp and FLOW in bp
road = ROAD.read_text(encoding="utf-8")
phases = list(re.finditer(r"(?mi)^#{1,6}\s+Phase\s+([1-8])\b", road))
assert 1 <= len(phases) <= 8
assert [int(m.group(1)) for m in phases] == list(range(1, len(phases) + 1))
for i, match in enumerate(phases):
    section = road[match.start(): phases[i + 1].start() if i + 1 < len(phases) else len(road)]
    for label in ("Outcome", "Dependencies", "Exit evidence", "Non-goals", "Decision gate"):
        assert re.search(rf"(?im)^\s*[-*]?\s*\**{re.escape(label)}\**\s*:", section)
dec = DEC.read_text(encoding="utf-8")
rows = [[cell.strip() for cell in line.strip().strip("|").split("|")] for line in dec.splitlines() if line.strip().startswith("|")]
header = next((row for row in rows if any(cell.lower() == "status" for cell in row)), None)
assert header is not None and len(header) == 9
status_index = next(i for i, cell in enumerate(header) if cell.lower() == "status")
status_values = [row[status_index] for row in rows[rows.index(header) + 1:] if len(row) == len(header) and not all(set(cell) <= set("-: ") for cell in row)]
assert status_values and all(value in {"open_now", "defer_until_gate"} for value in status_values)
print("goal004 packet validation: PASS")
```

After outputs exist, run the validator, exact-path and UTF-8 checks, required
content scans, balanced-fence checks, per-file trailing-whitespace checks,
`git diff --check`, and a non-authoring review. Apply at most this one repair
pass, rerun all checks, and stop with execution outputs uncommitted and
unpublished for Barry's strategic review.

## Stop and final report

Stop immediately for a failed baseline, conflicting audit evidence, a request
to decide a Barry-owned matter, an integrity concern that cannot be represented
as omission, or any scope expansion. The final report names all five design
paths plus the Log update, line counts, validator and hygiene results,
review/repair outcome, exact pre-publication Git status, and assumptions or
escalation. Confirm that no other execution artefacts or Git publication were
made.
