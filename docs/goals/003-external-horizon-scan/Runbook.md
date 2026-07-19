# Goal 003 runbook

Run from `/Users/bwbrook/git/camtrap-workflow`. This runbook authorizes current web research and static research-package validation only. It does not authorize product installation or execution, project runtime validation, R, `renv`, tests, lint, `targets`, Quarto, Docker, builds, data processing, implementation, or Git mutation.

## 1. Published-packet baseline

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
  docs/goals/003-external-horizon-scan/Goal.md \
  docs/goals/003-external-horizon-scan/Plan.md \
  docs/goals/003-external-horizon-scan/Runbook.md \
  docs/goals/003-external-horizon-scan/Log.md
git merge-base --is-ancestor d00084010b35fe26b652e8c32a39e27a4bb905ee HEAD
```

Expected:

```text
branch: main...origin/main
status: clean
local HEAD: equal to local origin/main
packet: all four Goal 003 files tracked
ancestry: accepted Goal 002 audit commit d00084010b35fe26b652e8c32a39e27a4bb905ee is an ancestor of HEAD
```

The accepted Goal 002 SHA is the pre-packet base, not the required execution HEAD. If any gate differs, report the exact state and pause without fetching, pulling, switching, or reconciling Git. After all gates pass, append the observed packet-publication HEAD and current ISO access date to `Log.md`.

## 2. Read-first internal evidence

Read, in this order:

```sh
for file in \
  docs/goals/003-external-horizon-scan/Goal.md \
  docs/goals/003-external-horizon-scan/Plan.md \
  docs/goals/003-external-horizon-scan/Runbook.md \
  docs/goals/003-external-horizon-scan/Log.md \
  docs/goals/002-product-architecture-audit/Goal.md \
  docs/goals/002-product-architecture-audit/Plan.md \
  docs/goals/002-product-architecture-audit/Runbook.md \
  docs/goals/002-product-architecture-audit/Log.md \
  docs/audits/002-product-architecture/Audit.md \
  docs/audits/002-product-architecture/renovation_roadmap.md \
  docs/audits/002-product-architecture/gap_register.csv \
  docs/audits/002-product-architecture/question_evidence_matrix.csv \
  docs/audits/002-product-architecture/localmap_boundary.md
do
  printf '\n===== %s =====\n' "$file"
  nl -ba "$file"
done
```

Read `docs/product_brief.md` and `docs/decisions.md` only when needed to resolve terminology or a material internal contradiction. Do not broaden into source-code archaeology, data inspection, sibling repositories, or project runtime surfaces.

Treat:

- Goal 002 facts as repository-observed internal evidence at commit `d00084010b35fe26b652e8c32a39e27a4bb905ee`;
- the nine-station/13-location/four-relocation description as Barry-provided context recorded in `Goal.md`;
- all external behavior as unverified until supported by a current source;
- absence under this scan as bounded non-discovery, not universal non-existence.

## 3. Native-agent execution and ownership

The orchestrator's action-executor delegation must begin exactly with this line:

```text
/goal
```

Use this complete prompt body after that first line:

```text
Execute the published Goal 003 packet in docs/goals/003-external-horizon-scan/.

Read AGENTS.md first, then the complete packet and its required Goal 002 evidence surface. Confirm the clean synchronized published-packet gate before research. Stop without reconciliation if it fails.

You are the sole writer for all Goal 003 durable files. You may use up to two native read-only research scouts: one for standards/provenance/spatiotemporal entities, and one for existing products/workflows/interfaces. Scouts may browse and return evidence but must not edit repository files or create durable artefacts. Do not allow concurrent writes.

Follow the exact research protocol, evidence tiers, decision domains, CSV schemas, controlled vocabularies, candidate limits, authority boundaries, validators, and stopping rules in the packet. Web research is authorized. Product installation or execution, accounts/logins, stakeholder contact, source-code archaeology, implementation, project runtime validation, and Git mutation are forbidden.

On completion or blockage, send your parent orchestrator agent a short native wake-up stating status, project recommendation or blocking condition, changed paths, validation result, and whether a material decision or further pass is justified. Then return the complete final response contract from Goal.md.
```

The executor must monitor scouts while they run and may clarify or narrow them. Wait timeouts are polling intervals, not worker deadlines. Do not launch duplicate scouts because a healthy scout is taking time. Each scout return must contain:

1. conclusion by assigned decision domain;
2. source owner, title, stable URL, version/release, published/updated date, and access date;
3. evidence tier and source type;
4. exact supported claim and limitation;
5. contradictions, uncertainty, and current-status concerns;
6. suggested candidates/patterns and outcomes;
7. whether more research could materially change a decision.

The writing executor independently verifies substantive scout evidence before accepting it.

## 4. Decision domains and controlled vocabularies

Use these exact domain values:

```text
D01_interchange_standards
D02_labelled_input_provenance
D03_spatiotemporal_entities
D04_progressive_configuration
D05_existing_product_whitespace
D06_local_interface_delivery
D07_operational_lifecycle
D08_localmap_interchange
D09_ala_gamma_extension
D10_ai_interpretation
D11_software_note_positioning
```

Allowed outcomes:

```text
adopt
adapt
build
later_spike
defer
barry_decision
reject
```

Allowed evidence tiers:

```text
tier1_normative
tier2_official
tier3_peer_reviewed
tier4_credible_secondary
tier5_marketing_claim
```

Allowed source types:

```text
standard_specification
official_documentation
maintained_repository
validator_or_release_record
licence_or_privacy_terms
peer_reviewed_article
software_note
institutional_guidance
independent_technical_analysis
marketing_material
```

Allowed source statuses:

```text
current
superseded
archived
status_unclear
```

Allowed URL statuses:

```text
reachable
reachable_with_redirect
blocked_or_dynamic
unreachable
```

Allowed assessments:

```text
meets
partly_meets
does_not_meet
unknown
not_applicable
```

Allowed confidence:

```text
high
moderate
low
```

Allowed candidate types:

```text
standard
data_model
product
workflow
interface
deployment
interchange
extension
positioning_pattern
```

Allowed mapping postures:

```text
direct_adapter
lossless_mapping
conditional_mapping
concept_only
not_recommended
unknown
```

Final project recommendation must be exactly one of:

```text
continue
narrow
integrate
stop
```

## 5. Research and source recording

For each decision domain:

1. Run a bounded discovery pass aimed at normative/official owners.
2. Run a scholarly or credible independent check.
3. Select approximately three to five serious candidates or patterns.
4. Deep-read the primary surfaces that support material comparisons.
5. Treat each bounded search or navigation round within one declared source class as one source pass.
6. Run only the follow-up passes needed to resolve contradictions or test the leading recommendation.
7. Stop after two consecutive follow-up passes add no decision-changing evidence, viable pattern, criterion, contradiction, or confidence change.

Record in `Log.md`:

- date and decision domain;
- search query or navigation route;
- source classes searched;
- candidates screened, retained, demoted, or excluded;
- reason for inclusion/exclusion;
- whether the pass changed a decision, criterion, contradiction, or confidence;
- the two-pass stopping evidence.

Prefer official specifications, documentation, repositories, release records, licences, and privacy terms. Use peer-reviewed papers to establish scientific or adoption context. Tier 5 marketing claims must be identified as claims and corroborated before supporting any outcome other than `defer`, `later_spike`, or `reject`.

Do not:

- install, clone, build, execute, benchmark, or log into an external product;
- download an executable, container, package, model, or data payload for testing;
- create accounts, contact maintainers/stakeholders, or use private credentials;
- claim a graphical, offline, privacy, lifecycle, or analytical behavior not stated in evidence;
- inspect implementation source beyond public top-level documentation, release metadata, or high-level repository metadata needed to establish maintenance/current status;
- expand upstream classification, ALA, AI, journal, or methods research beyond the decision criteria.

## 6. Exact CSV contracts

### Evidence register

Create `docs/audits/003-external-horizon-scan/evidence_register.csv` with:

```text
evidence_id,decision_domains,source_title,source_owner,source_type,source_url,version_or_release,published_or_updated_date,accessed_date,evidence_tier,current_status,url_status,claim_supported,limitations
```

Rules:

- `evidence_id` is unique and matches `E[0-9]{3}`.
- `decision_domains` is a semicolon-separated list of exact domain values.
- `source_url` is a stable `https://` URL, preferably the canonical owner, DOI, specification, release, licence, or privacy page rather than a search result.
- `version_or_release` is the exact version/release when applicable; use `not_applicable` only for genuinely unversioned sources and `unknown` only when the source status cannot be resolved.
- `published_or_updated_date` uses `YYYY-MM-DD` when available, `YYYY-MM` or `YYYY` when only that precision is published, and `unknown` only after checking.
- `accessed_date` is the exact `YYYY-MM-DD` date on which the source was inspected.
- `claim_supported` states what the source supports, not the scan's inference.
- `limitations` is always nonblank and records evidence limits, including missing version/date, marketing status, blocked URLs, or unverified runtime behavior.

### Decision comparison matrix

Create `docs/audits/003-external-horizon-scan/decision_comparison_matrix.csv` with:

```text
comparison_id,decision_domain,candidate_or_pattern,candidate_type,requirement_id,requirement,assessment,evidence_ids,benefits,limitations,outcome,confidence
```

Rules:

- `comparison_id` is unique and matches `C[0-9]{3}`.
- `requirement_id` is stable within a domain and matches `D[0-9]{2}R[0-9]{2}`.
- `evidence_ids` is a semicolon-separated list of valid evidence IDs.
- Every row has nonblank benefits and limitations.
- All rows for the same decision-domain/candidate pair use one consistent outcome.
- `reject` requires direct evidence and a concrete limitation or mismatch.
- Each domain compares at least two credible alternatives or `HorizonScan.md` records an evidence-backed absence.
- Count distinct serious candidates, not repeated requirement rows, against the approximate three-to-five cap.

### Standards crosswalk

Create `docs/audits/003-external-horizon-scan/standards_crosswalk.csv` with:

```text
crosswalk_id,decision_domain,concept,source_standard_or_pattern,source_version,source_entity_or_field,semantics,camtrap_requirement,judbury_application,evidence_ids,mapping_posture,confidence,limitations
```

Rules:

- `crosswalk_id` is unique and matches `S[0-9]{3}`.
- `decision_domain` is one exact domain value.
- `source_version` is exact, `not_applicable`, or `unknown` with a limitation.
- `evidence_ids` is a semicolon-separated list of valid evidence IDs.
- `judbury_application` must preserve and distinguish nine nominal grid stations, 13 physical locations, four relocation events, and potentially more deployments where relevant.
- A crosswalk describes concepts and mapping posture; it does not choose ecological grouping or finalize a public schema/API.

Use RFC 4180-compatible quoting for commas, quotes, or line-like prose. Keep every CSV field on one physical row.

## 7. Markdown citation and content rules

Use external citation tokens in the exact form `[E001]`. Every material external claim in `HorizonScan.md` and `decision_register.md` must have one or more nearby evidence tokens. Internal Goal 002 evidence uses repository-relative `file:line` citations or commit IDs. Barry-provided Judbury facts must be explicitly labelled as Barry-provided and cite this packet, not an external evidence ID.

`HorizonScan.md` must contain:

- Executive recommendation.
- Methods, scope, candidate-selection, and stopping evidence.
- Evidence-quality and currency summary.
- A finding section for all eleven exact decision domains.
- Product white-space conclusion with strongest counterexamples.
- Judbury representation implications and grouping non-decision.
- Goal 002 gap reconciliation for `G004`, `G005`, `G007`, `G012`, `G015`, `G023`, `G024`, and `G025`.
- LocalMap boundary recommendation.
- Bounded ALA/gamma and AI later-spike criteria.
- Software-note positioning: demonstrated, plausible-but-unvalidated, and indefensible claims.
- Contradictions, uncertainty, rejected patterns, and evidence-backed absences.
- Explicit non-decisions and authority boundaries.
- Highest-value next tranche and project recommendation.
- Evidence that would overturn the project recommendation.

The Goal 002 reconciliation must be one Markdown table with exactly these columns:

```text
gap_id | external_evidence_ids | outcome | recommendation | residual_authority
```

Each required gap appears exactly once in the first column, uses one allowed outcome, and cites at least one valid external evidence ID. The final project recommendation appears exactly once as:

```text
**Project recommendation:** `<continue|narrow|integrate|stop>`
```

`decision_register.md` must include only material Barry decisions. Each decision uses a stable `B[0-9]{3}` ID and states:

- decision and why it matters now;
- bounded options;
- linked evidence IDs;
- trade-offs and uncertainty;
- executor recommendation and confidence;
- reversibility;
- consequence of delay;
- decision owner (`Barry`);
- status (`open`).

Do not populate it with routine research choices or imply Barry has accepted a recommendation.

## 8. Bounded URL checks

List unique evidence URLs, then perform a bounded reachability check without downloading payloads for execution:

```sh
ruby -rcsv -e '
CSV.foreach("docs/audits/003-external-horizon-scan/evidence_register.csv", headers: true) do |row|
  puts row["source_url"]
end
' | sort -u | while IFS= read -r url
do
  code=$(curl --location --silent --show-error --head \
    --max-time 20 --output /dev/null --write-out '%{http_code}' "$url" || true)
  if test "$code" = 000 || test "$code" -ge 400 2>/dev/null
  then
    code=$(curl --location --silent --show-error --range 0-1023 \
      --max-time 20 --output /dev/null --write-out '%{http_code}' "$url" || true)
  fi
  printf '%s %s\n' "$code" "$url"
done
```

Classify `2xx` as `reachable` and successful redirect chains as `reachable_with_redirect` when the redirect is material. Use `blocked_or_dynamic` for owner pages that refuse automation but were inspected through an authorized browser. Use `unreachable` only after the bounded fallback fails. Never delete a material source merely because automated checking is blocked; record the limitation and manual inspection basis. Record counts and unresolved failures in `Log.md`.

## 9. Static package validators

Create or update only:

```text
docs/audits/003-external-horizon-scan/HorizonScan.md
docs/audits/003-external-horizon-scan/evidence_register.csv
docs/audits/003-external-horizon-scan/decision_comparison_matrix.csv
docs/audits/003-external-horizon-scan/standards_crosswalk.csv
docs/audits/003-external-horizon-scan/decision_register.md
docs/goals/003-external-horizon-scan/Log.md
```

Validate exact paths and whitespace:

```sh
for file in \
  docs/audits/003-external-horizon-scan/HorizonScan.md \
  docs/audits/003-external-horizon-scan/evidence_register.csv \
  docs/audits/003-external-horizon-scan/decision_comparison_matrix.csv \
  docs/audits/003-external-horizon-scan/standards_crosswalk.csv \
  docs/audits/003-external-horizon-scan/decision_register.md \
  docs/goals/003-external-horizon-scan/Log.md
do
  test -s "$file" || printf 'MISSING_OR_EMPTY %s\n' "$file"
  check_output=$(git diff --no-index --check /dev/null "$file" 2>&1 || true)
  test -z "$check_output" || printf 'WHITESPACE_ERROR %s\n%s\n' "$file" "$check_output"
done
```

Validate CSV structure, enums, dates, evidence references, domain coverage, and candidate consistency with Ruby's standard library:

```sh
ruby -rcsv -rdate -rset -e '
root = "docs/audits/003-external-horizon-scan"
expected = {
  "#{root}/evidence_register.csv" => %w[
    evidence_id decision_domains source_title source_owner source_type source_url
    version_or_release published_or_updated_date accessed_date evidence_tier
    current_status url_status claim_supported limitations
  ],
  "#{root}/decision_comparison_matrix.csv" => %w[
    comparison_id decision_domain candidate_or_pattern candidate_type requirement_id
    requirement assessment evidence_ids benefits limitations outcome confidence
  ],
  "#{root}/standards_crosswalk.csv" => %w[
    crosswalk_id decision_domain concept source_standard_or_pattern source_version
    source_entity_or_field semantics camtrap_requirement judbury_application
    evidence_ids mapping_posture confidence limitations
  ]
}
tables = {}
expected.each do |path, header|
  table = CSV.read(path, headers: true)
  abort("header mismatch: #{path}") unless table.headers == header
  abort("no records: #{path}") if table.empty?
  values = table.map { |row| row[header.first].to_s.strip }
  abort("blank key: #{path}") if values.any?(&:empty?)
  abort("duplicate key: #{path}") unless values.uniq.length == values.length
  tables[path] = table
end

domains = %w[
  D01_interchange_standards D02_labelled_input_provenance
  D03_spatiotemporal_entities D04_progressive_configuration
  D05_existing_product_whitespace D06_local_interface_delivery
  D07_operational_lifecycle D08_localmap_interchange
  D09_ala_gamma_extension D10_ai_interpretation
  D11_software_note_positioning
]
source_types = %w[
  standard_specification official_documentation maintained_repository
  validator_or_release_record licence_or_privacy_terms peer_reviewed_article
  software_note institutional_guidance independent_technical_analysis
  marketing_material
]
tiers = %w[
  tier1_normative tier2_official tier3_peer_reviewed
  tier4_credible_secondary tier5_marketing_claim
]
source_status = %w[current superseded archived status_unclear]
url_status = %w[reachable reachable_with_redirect blocked_or_dynamic unreachable]
candidate_types = %w[
  standard data_model product workflow interface deployment
  interchange extension positioning_pattern
]
assessments = %w[meets partly_meets does_not_meet unknown not_applicable]
outcomes = %w[adopt adapt build later_spike defer barry_decision reject]
confidence = %w[high moderate low]
postures = %w[
  direct_adapter lossless_mapping conditional_mapping
  concept_only not_recommended unknown
]

evidence = tables["#{root}/evidence_register.csv"]
evidence_ids = evidence.map { |row| row["evidence_id"] }.to_set
domain_evidence = Set.new
evidence.each do |row|
  abort("bad evidence id: #{row["evidence_id"]}") unless row["evidence_id"].match?(/\AE[0-9]{3}\z/)
  row_domains = row["decision_domains"].to_s.split(";").map(&:strip)
  abort("missing evidence domain: #{row["evidence_id"]}") if row_domains.empty?
  abort("bad evidence domain: #{row["evidence_id"]}") unless row_domains.all? { |value| domains.include?(value) }
  domain_evidence.merge(row_domains)
  abort("bad source type: #{row["evidence_id"]}") unless source_types.include?(row["source_type"])
  abort("bad tier: #{row["evidence_id"]}") unless tiers.include?(row["evidence_tier"])
  if row["source_type"] == "marketing_material"
    abort("marketing source must be tier 5: #{row["evidence_id"]}") unless row["evidence_tier"] == "tier5_marketing_claim"
  end
  if row["evidence_tier"] == "tier5_marketing_claim"
    abort("tier 5 must be marketing material: #{row["evidence_id"]}") unless row["source_type"] == "marketing_material"
  end
  abort("bad source status: #{row["evidence_id"]}") unless source_status.include?(row["current_status"])
  abort("bad URL status: #{row["evidence_id"]}") unless url_status.include?(row["url_status"])
  abort("non-https URL: #{row["evidence_id"]}") unless row["source_url"].to_s.match?(/\Ahttps:\/\//)
  abort("blank version: #{row["evidence_id"]}") if row["version_or_release"].to_s.strip.empty?
  date = row["published_or_updated_date"].to_s
  abort("bad published date: #{row["evidence_id"]}") unless date.match?(/\A(?:[0-9]{4}(?:-[0-9]{2}(?:-[0-9]{2})?)?|unknown)\z/)
  begin
    accessed = Date.iso8601(row["accessed_date"].to_s)
    abort("future access date: #{row["evidence_id"]}") if accessed > Date.today
  rescue Date::Error
    abort("bad access date: #{row["evidence_id"]}")
  end
  %w[source_title source_owner claim_supported limitations].each do |field|
    abort("blank #{field}: #{row["evidence_id"]}") if row[field].to_s.strip.empty?
  end
end
abort("evidence domain coverage mismatch") unless domain_evidence == domains.to_set

parse_refs = lambda do |value, owner|
  refs = value.to_s.split(";").map(&:strip).reject(&:empty?)
  abort("missing evidence refs: #{owner}") if refs.empty?
  unknown = refs.reject { |ref| evidence_ids.include?(ref) }
  abort("unknown evidence refs #{unknown.join(",")}: #{owner}") unless unknown.empty?
end

comparisons = tables["#{root}/decision_comparison_matrix.csv"]
comparison_domains = Set.new
candidate_outcomes = Hash.new { |hash, key| hash[key] = Set.new }
candidate_counts = Hash.new { |hash, key| hash[key] = Set.new }
comparisons.each do |row|
  id = row["comparison_id"]
  abort("bad comparison id: #{id}") unless id.match?(/\AC[0-9]{3}\z/)
  abort("bad comparison domain: #{id}") unless domains.include?(row["decision_domain"])
  abort("bad candidate type: #{id}") unless candidate_types.include?(row["candidate_type"])
  abort("bad requirement id: #{id}") unless row["requirement_id"].to_s.match?(/\AD[0-9]{2}R[0-9]{2}\z/)
  expected_prefix = "#{row["decision_domain"][0, 3]}R"
  abort("requirement/domain mismatch: #{id}") unless row["requirement_id"].start_with?(expected_prefix)
  abort("bad assessment: #{id}") unless assessments.include?(row["assessment"])
  abort("bad outcome: #{id}") unless outcomes.include?(row["outcome"])
  abort("bad confidence: #{id}") unless confidence.include?(row["confidence"])
  %w[candidate_or_pattern requirement benefits limitations].each do |field|
    abort("blank #{field}: #{id}") if row[field].to_s.strip.empty?
  end
  parse_refs.call(row["evidence_ids"], id)
  comparison_domains << row["decision_domain"]
  key = [row["decision_domain"], row["candidate_or_pattern"]]
  candidate_outcomes[key] << row["outcome"]
  candidate_counts[row["decision_domain"]] << row["candidate_or_pattern"]
end
abort("comparison domain coverage mismatch") unless comparison_domains == domains.to_set
candidate_outcomes.each do |key, values|
  abort("inconsistent candidate outcome: #{key.join(" / ")}") unless values.length == 1
end
candidate_counts.each do |domain, values|
  warn("REVIEW candidate count #{domain}=#{values.length}") unless (2..5).cover?(values.length)
end

crosswalk = tables["#{root}/standards_crosswalk.csv"]
crosswalk.each do |row|
  id = row["crosswalk_id"]
  abort("bad crosswalk id: #{id}") unless id.match?(/\AS[0-9]{3}\z/)
  abort("bad crosswalk domain: #{id}") unless domains.include?(row["decision_domain"])
  abort("bad mapping posture: #{id}") unless postures.include?(row["mapping_posture"])
  abort("bad confidence: #{id}") unless confidence.include?(row["confidence"])
  %w[
    concept source_standard_or_pattern source_version source_entity_or_field
    semantics camtrap_requirement judbury_application limitations
  ].each do |field|
    abort("blank #{field}: #{id}") if row[field].to_s.strip.empty?
  end
  parse_refs.call(row["evidence_ids"], id)
end

puts "evidence=#{evidence.length}"
puts "comparisons=#{comparisons.length}"
puts "crosswalk=#{crosswalk.length}"
domains.each do |domain|
  puts "#{domain}: candidates=#{candidate_counts[domain].length}"
end
'
```

Validate Markdown citation IDs and required coverage:

```sh
ruby -rcsv -rset -e '
root = "docs/audits/003-external-horizon-scan"
evidence_ids = CSV.read("#{root}/evidence_register.csv", headers: true)
  .map { |row| row["evidence_id"] }.to_set
markdown = [
  "#{root}/HorizonScan.md",
  "#{root}/decision_register.md"
].map { |path| File.read(path) }.join("\n")
unknown = markdown.scan(/\[?(E[0-9]{3})\]?/).flatten.to_set - evidence_ids
abort("unknown Markdown evidence IDs: #{unknown.to_a.sort.join(",")}") unless unknown.empty?

domains = %w[
  D01_interchange_standards D02_labelled_input_provenance
  D03_spatiotemporal_entities D04_progressive_configuration
  D05_existing_product_whitespace D06_local_interface_delivery
  D07_operational_lifecycle D08_localmap_interchange
  D09_ala_gamma_extension D10_ai_interpretation
  D11_software_note_positioning
]
gaps = %w[G004 G005 G007 G012 G015 G023 G024 G025]
horizon = File.read("#{root}/HorizonScan.md")
domains.each { |value| abort("missing domain in HorizonScan: #{value}") unless horizon.include?(value) }
outcomes = %w[adopt adapt build later_spike defer barry_decision reject]
gaps.each do |gap|
  rows = horizon.lines.select { |line| line.match?(/^\|\s*\`?#{gap}\`?\s*\|/) }
  abort("gap row count #{gap}=#{rows.length}") unless rows.length == 1
  abort("gap row lacks evidence: #{gap}") unless rows.first.match?(/E[0-9]{3}/)
  abort("gap row lacks allowed outcome: #{gap}") unless outcomes.any? { |outcome| rows.first.include?(outcome) }
end
recommendations = horizon.scan(/^\*\*Project recommendation:\*\*\s+\`(continue|narrow|integrate|stop)\`\s*$/)
abort("project recommendation row count=#{recommendations.length}") unless recommendations.length == 1
'
```

List Markdown links and verify every repository-relative target manually or with `test -e` after resolving from its containing file. External URLs are governed by the evidence register and bounded URL check:

```sh
rg -n --no-heading '\[[^]]+\]\([^)]+\)' \
  docs/audits/003-external-horizon-scan \
  docs/goals/003-external-horizon-scan/Log.md

rg -n --no-heading \
  'FIXME|XXX|CHANGEME|INSERT HERE|FILL THIS|TBD|TODO' \
  docs/audits/003-external-horizon-scan \
  docs/goals/003-external-horizon-scan/Log.md
```

Review every match. A literal historical `TODO` in cited source text must be explained; unresolved drafting markers must be removed.

## 10. Final state and stopping gate

```sh
git diff --check
git status --short --branch
git diff --stat
git diff --name-status
git ls-files --others --exclude-standard
git rev-parse HEAD
```

The only execution-time changes permitted relative to the committed Goal 003 packet are:

```text
docs/audits/003-external-horizon-scan/
docs/goals/003-external-horizon-scan/Log.md
```

After the research package is complete and its mechanical validators pass, assign one focused read-only review to a native agent that did not author the durable package. A completed research scout may be reused for this review. The reviewer must return findings and exact evidence without editing files. The writing executor may perform one repair pass for unsupported recommendations, missing strong alternatives, source-currency errors, broken evidence references, malformed CSV, authority violations, or scope drift. Do not start another polish loop unless the review finds a material defect.

Do not stage, commit, push, tag, open a pull request, or alter project code or data. Return this exact publication recommendation for orchestrator consideration:

```sh
git add \
  docs/audits/003-external-horizon-scan/HorizonScan.md \
  docs/audits/003-external-horizon-scan/evidence_register.csv \
  docs/audits/003-external-horizon-scan/decision_comparison_matrix.csv \
  docs/audits/003-external-horizon-scan/standards_crosswalk.csv \
  docs/audits/003-external-horizon-scan/decision_register.md \
  docs/goals/003-external-horizon-scan/Log.md
git commit -m "docs: publish Goal 003 external horizon scan"
git push origin main
```

This is a recommendation only. Execution itself must not run those commands.
