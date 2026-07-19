# Goal 002 runbook

Run from `/Users/bwbrook/git/camtrap-workflow` in a login `zsh` shell. This runbook uses read-only repository inspection and static evidence-package validation only. It does not authorize R, `renv`, tests, lint, `targets`, Quarto, Docker, builds, pipelines, data processing, or Git mutation.

## 1. Camtrap Workflow baseline

Read the repository contract before any other project file:

```sh
pwd
sed -n '1,260p' AGENTS.md
git status --short --branch
git branch --show-current
git rev-parse HEAD
git rev-parse origin/main
test "$(git branch --show-current)" = main
test -z "$(git status --porcelain)"
test "$(git rev-parse HEAD)" = "$(git rev-parse origin/main)"
git remote -v
git log -5 --oneline
git ls-files --error-unmatch \
  docs/goals/002-product-architecture-audit/Goal.md \
  docs/goals/002-product-architecture-audit/Plan.md \
  docs/goals/002-product-architecture-audit/Runbook.md \
  docs/goals/002-product-architecture-audit/Log.md
git merge-base --is-ancestor 39ade324b06264d003f7f920b69811dba4d0cbe3 HEAD
```

Expected execution baseline after separate orchestrator review and packet publication:

```text
branch: main...origin/main
status: clean
local HEAD: equal to local origin/main
packet: all four Goal 002 files tracked
ancestry: accepted Goal 001 commit 39ade324b06264d003f7f920b69811dba4d0cbe3 is an ancestor of HEAD
```

The accepted Goal 001 SHA is the pre-packet base, not the required execution HEAD. If branch, tracking, cleanliness, local/remote equality, packet tracking, or ancestry differs, record the exact state and pause before creating audit deliverables. Do not fetch or reconcile it. After all gates pass, append the observed HEAD to `docs/goals/002-product-architecture-audit/Log.md` as the packet-publication HEAD at execution start.

Then read Goal 001 evidence first:

```sh
for file in \
  docs/goals/001-r46-mac-mini-readiness-acceptance/Goal.md \
  docs/goals/001-r46-mac-mini-readiness-acceptance/Plan.md \
  docs/goals/001-r46-mac-mini-readiness-acceptance/Runbook.md \
  docs/goals/001-r46-mac-mini-readiness-acceptance/Log.md \
  docs/log/620_r46_mac_mini_readiness.md
do
  printf '\n===== %s =====\n' "$file"
  sed -n '1,360p' "$file"
done
```

## 2. Establish the static inventory

Capture names and counts before interpretation:

```sh
printf 'R files: '
find R -type f -name '*.R' -print | awk -F/ 'NF == 2' | sort | wc -l

printf 'Test files: '
find tests -type f -print | sort | wc -l

printf 'QMD files: '
find . -path './.git' -prune -o -path './renv' -prune -o -type f -name '*.qmd' -print | sort | wc -l

printf 'Configuration candidates: '
find . -path './.git' -prune -o -path './renv' -prune -o -path './outputs' -prune -o -path './_targets' -prune -o \
  -type f \( -name 'config*.yml' -o -name 'config*.yaml' -o -path '*/config/*' -o -path '*/configs/*' \) -print | sort | wc -l

find docs scripts tests R -type f -print | sort
```

Read the principal orientation and pipeline surfaces:

```sh
for file in README.md GETTING_STARTED.md VERSION _targets.R
do
  printf '\n===== %s =====\n' "$file"
  nl -ba "$file"
done

while IFS= read -r file
do
  printf '\n===== %s =====\n' "$file"
  nl -ba "$file"
done < <(find R -type f -name '*.R' -print | awk -F/ 'NF == 2' | sort)
```

Extract target and function evidence without executing R:

```sh
rg -n --no-heading 'tar_target|tar_render|tar_quarto|list\s*\(' _targets.R
rg -n --no-heading '^[[:alnum:]_.]+[[:space:]]*<-[[:space:]]*function|function\s*\(' R scripts
rg -n --no-heading 'CAMTRAP_CONFIG|commandArgs|Sys\.getenv|read_yaml|yaml|config' README.md GETTING_STARTED.md _targets.R R scripts docs
```

Use `nl -ba` on every source cited in the audit. Cite repository-relative paths, for example `R/example.R:42`, not machine-specific absolute paths.

## 3. Read the authorized Camtrap Workflow surface

Read all configuration candidates, schemas or templates, report and analysis sources, scripts, test files, and relevant product documentation identified by the inventories. These searches locate the surface without assuming every historical filename still exists:

```sh
rg --files -g '!renv/**' -g '!outputs/**' -g '!_targets/**' \
  | rg '(^|/)(schema|schemas|template|templates|reference|references)(/|\.)|\.(json|ya?ml)$' \
  | sort

rg --files docs \
  | rg -i '(product|architecture|workflow|roadmap|decision|interpret|bring|byo|reproduc|container|release|config|schema|output|report)' \
  | sort

rg --files -g '*.qmd' -g '*.Rmd' -g '*.md' analysis analyses reports report docs \
  2>/dev/null | sort

while IFS= read -r file
do
  printf '\n===== %s =====\n' "$file"
  nl -ba "$file"
done < <(find tests -type f -print | sort)
```

Read identified text sources with bounded `sed` or `nl -ba`. For large JSON or YAML inputs, use `jq` or `yq` when available, or bounded `sed`; do not process observational data. Do not open media files or sensitive raw data.

Inspect existing ignored Goal 001 run evidence only if it remains present:

```sh
find outputs -type f \
  \( -name 'run_manifest.json' -o -name 'session_info.txt' -o -name '*.html' -o -name '*.pdf' -o -name '*.csv' \) \
  -print 2>/dev/null | sort | sed -n '1,240p'

find outputs -type f -name 'run_manifest.json' -print 2>/dev/null | sort | while IFS= read -r file
do
  printf '\n===== %s =====\n' "$file"
  jq . "$file"
done
```

Do not open raw media, enumerate sensitive content, regenerate missing artefacts, or infer runtime validity from cached files alone. Record provenance and limitations of any cached evidence used.

Use Git history only for a material contradiction:

```sh
evidence_path=_targets.R
git log --oneline --decorate --all -- "$evidence_path"
git blame -L 1,160 -- "$evidence_path"
evidence_commit=$(git log -1 --format=%H -- "$evidence_path")
git show "$evidence_commit:$evidence_path" | sed -n '1,160p'
```

The block is an exact bounded example. Change `evidence_path` and the line window only after a material contradiction identifies a more relevant source. Do not run broad historical archaeology.

## 4. Reconcile coverage and evidence

Populate `docs/audits/002-product-architecture/module_inventory.csv` with this exact header:

```text
record_id,record_type,entrypoint,inputs,outputs,configuration,tests,documentation,status,evidence,concerns
```

Use stable `record_id` values. At minimum, inventory records must reconcile:

- every top-level `R/*.R` path reported by the inventory command;
- every target declared in `_targets.R`;
- every configuration profile;
- relevant tests, report sources, schemas, and principal output surfaces.

Use only these status values:

```text
implemented_and_evidenced
implemented_unverified
partial
docs_only
obsolete_or_duplicated
not_present
```

Define the evidence threshold in `Audit.md`. A source file, documentation claim, cached artefact, or test definition alone does not automatically establish end-to-end verified behavior.

The current user journey must explicitly trace:

```text
input selection scope
  -> input mapping and validation
  -> normalization or approved repair
  -> locations and deployments
  -> effort and temporal schemes
  -> operational detection events
  -> named spatial resolutions
  -> requested module capability assessment
  -> analysis targets
  -> module statuses
  -> primary report, audit bundle, reusable artefacts
  -> immutable rerun identity and provenance
```

At each transition, record evidence and any need for R, shell use, network access, manual state changes, mutable paths, or hidden assumptions.

## 5. Build the Judbury question-evidence matrix

Populate `docs/audits/002-product-architecture/question_evidence_matrix.csv` with this exact header:

```text
question_id,question,unit_of_inference,spatial_resolution,temporal_scheme,required_data,current_module,proposed_output,assumptions,limitations,suitability,evidence
```

Use only these suitability values:

```text
defensible
illustrative_only
underpowered
unsuitable
candidate_extension
```

Cover sampling adequacy and effort, richness, spatial turnover, selected-species seasonal and coarse day/night patterns, and regional ALA or gamma-diversity context. Explicitly assess the nine-location design, occupancy and covariate inference, RAI language, clock drift, relocations, unequal effort, missingness, and regional-record biases.

## 6. Inspect only the LocalMap_Tas boundary surface

Move to `/Users/bwbrook/git/localmap_tas`, read its contract first, and confirm its inherited state:

```sh
cd /Users/bwbrook/git/localmap_tas
pwd
sed -n '1,260p' AGENTS.md
git status --short --branch
git rev-parse HEAD
git remote -v
```

Expected LocalMap_Tas baseline:

```text
branch: main...origin/main [ahead 18]
HEAD: 297a2b09af9f6ce83054d9d522d922ea6ecefa10
status: clean
```

Do not fetch, push, or otherwise reconcile the ahead state. If it differs or is dirty, record it and pause the LocalMap_Tas portion.

Locate only the authorized categories:

```sh
for file in README.md docs/product_brief.md docs/architecture.md
do
  if test -f "$file"; then
    printf '\n===== %s =====\n' "$file"
    nl -ba "$file"
  fi
done

rg --files docs R scripts 2>/dev/null \
  | rg -i '(setting|config|schema|output|manifest|provenance|entry|interface)' \
  | sort

rg -n --no-heading '^[[:alnum:]_.]+[[:space:]]*<-[[:space:]]*function|tar_target|manifest|provenance|output|config|setting' \
  README.md docs/product_brief.md docs/architecture.md R scripts 2>/dev/null
```

Read only matches needed to establish public entrypoints, settings, output schema, and manifest or provenance behavior. Do not inspect unrelated internals, data, outputs, tests, history, other docs, or generated artefacts. Do not run any command that writes to LocalMap_Tas.

Return to Camtrap Workflow:

```sh
cd /Users/bwbrook/git/camtrap-workflow
```

Write `localmap_boundary.md` as a candidate boundary, not a final API. It must distinguish observed current surfaces from recommended interchange fields and must identify which recommendations await Goal 003 or implementation validation.

## 7. Rank gaps and construct the roadmap

Populate `docs/audits/002-product-architecture/gap_register.csv` with this exact header:

```text
gap_id,category,summary,severity,user_or_scientific_risk,architectural_leverage,estimated_effort,evidence,recommendation,disposition
```

Define the ranking scales in `Audit.md`. Use only these disposition values:

```text
no_regrets
goal003_dependent
barry_decision
implementation_spike
retain_as_is
```

Each material row requires direct evidence. Rank scientific integrity and data-loss risks above cosmetic consistency. Do not imply precision that the static evidence cannot support.

`renovation_roadmap.md` must state for each phase:

- outcome;
- included gaps;
- exclusions and deferred decisions;
- objective acceptance evidence;
- scientific or user risks controlled;
- stop or escalation rule.

The recommended architecture must remain technology-neutral at interface and deployment boundaries. No Shiny, Docker, hosted-service, public-schema, or API selection is authorized by this audit.

## 8. Static package validation

Create and update only:

```text
docs/audits/002-product-architecture/Audit.md
docs/audits/002-product-architecture/module_inventory.csv
docs/audits/002-product-architecture/question_evidence_matrix.csv
docs/audits/002-product-architecture/gap_register.csv
docs/audits/002-product-architecture/localmap_boundary.md
docs/audits/002-product-architecture/renovation_roadmap.md
docs/goals/002-product-architecture-audit/Log.md
```

Validate exact paths and non-empty files:

```sh
for file in \
  docs/audits/002-product-architecture/Audit.md \
  docs/audits/002-product-architecture/module_inventory.csv \
  docs/audits/002-product-architecture/question_evidence_matrix.csv \
  docs/audits/002-product-architecture/gap_register.csv \
  docs/audits/002-product-architecture/localmap_boundary.md \
  docs/audits/002-product-architecture/renovation_roadmap.md \
  docs/goals/002-product-architecture-audit/Log.md
do
  test -s "$file" || printf 'MISSING_OR_EMPTY %s\n' "$file"
  check_output=$(git diff --no-index --check /dev/null "$file" 2>&1 || true)
  test -z "$check_output" || printf 'WHITESPACE_ERROR %s\n%s\n' "$file" "$check_output"
done
```

Static CSV validation may use Ruby's standard CSV parser; this is evidence packaging, not project execution:

```sh
ruby -rcsv -e '
expected = {
  "docs/audits/002-product-architecture/module_inventory.csv" => %w[record_id record_type entrypoint inputs outputs configuration tests documentation status evidence concerns],
  "docs/audits/002-product-architecture/question_evidence_matrix.csv" => %w[question_id question unit_of_inference spatial_resolution temporal_scheme required_data current_module proposed_output assumptions limitations suitability evidence],
  "docs/audits/002-product-architecture/gap_register.csv" => %w[gap_id category summary severity user_or_scientific_risk architectural_leverage estimated_effort evidence recommendation disposition]
}
expected.each do |path, header|
  table = CSV.read(path, headers: true)
  abort("header mismatch: #{path}") unless table.headers == header
  abort("no records: #{path}") if table.empty?
  key = header.first
  values = table.map { |row| row[key] }
  abort("blank key: #{path}") if values.any? { |value| value.nil? || value.strip.empty? }
  abort("duplicate key: #{path}") unless values.uniq.length == values.length
end

module_status = %w[implemented_and_evidenced implemented_unverified partial docs_only obsolete_or_duplicated not_present]
CSV.foreach("docs/audits/002-product-architecture/module_inventory.csv", headers: true) do |row|
  abort("bad module status: #{row["record_id"]}") unless module_status.include?(row["status"])
  abort("missing module evidence: #{row["record_id"]}") if row["evidence"].to_s.strip.empty?
end

suitability = %w[defensible illustrative_only underpowered unsuitable candidate_extension]
CSV.foreach("docs/audits/002-product-architecture/question_evidence_matrix.csv", headers: true) do |row|
  abort("bad suitability: #{row["question_id"]}") unless suitability.include?(row["suitability"])
  abort("missing question evidence: #{row["question_id"]}") if row["evidence"].to_s.strip.empty?
end

disposition = %w[no_regrets goal003_dependent barry_decision implementation_spike retain_as_is]
CSV.foreach("docs/audits/002-product-architecture/gap_register.csv", headers: true) do |row|
  abort("bad disposition: #{row["gap_id"]}") unless disposition.include?(row["disposition"])
  abort("missing gap evidence: #{row["gap_id"]}") if row["evidence"].to_s.strip.empty?
end
'
```

Check evidence-path and cross-reference candidates manually after listing them:

```sh
rg -n --no-heading '[[:alnum:]_.-]+/[[:alnum:]_./-]+:[0-9]+' docs/audits/002-product-architecture
rg -n --no-heading 'docs/(audits|goals)/[[:alnum:]_./-]+' docs/audits/002-product-architecture
rg -n --no-heading 'FIXME|XXX|CHANGEME|INSERT HERE|FILL THIS' \
  docs/audits/002-product-architecture docs/goals/002-product-architecture-audit/Log.md
```

Review every match, verify cited paths and line numbers against the current baseline, and ensure proposed future paths are labelled as proposals.

Reconcile coverage counts against the inventory. Use standard shell or Ruby text/CSV parsing; do not invoke R. Record exact counts and justified exclusions in `Audit.md` and `Log.md`.

## 9. Final state and stopping gate

```sh
git diff --check
git status --short --branch
git diff --stat
git diff --name-status
git ls-files --others --exclude-standard
git rev-parse HEAD
```

The only execution-time changes permitted relative to this committed packet baseline are:

```text
docs/audits/002-product-architecture/
docs/goals/002-product-architecture-audit/Log.md
```

Perform one focused self-review and repair pass for material omissions, unsupported conclusions, broken references, malformed CSV, or scope violations. Do not start additional polish loops. Record the final status as static evidence-packaging validation, not runtime validation.

Do not stage, commit, push, tag, open a pull request, or alter either repository. Return the exact staging recommendation for orchestrator review.
