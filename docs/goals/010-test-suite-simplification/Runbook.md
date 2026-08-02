# Goal 010 Runbook

## Baseline

Use accepted GitHub Actions run `30716777969` as the immutable baseline:

```text
testthat duration: 4315.2 seconds
test_run_bundle.R: 2476.8 seconds
test_validation_ledger.R: 1799.5 seconds
all other test files: 38.9 seconds
full evidence plus verification: 2142 seconds
```

Do not rerun the old full suite simply to reproduce these timings.

## Intended commands

```sh
Rscript scripts/run_tests.R
Rscript scripts/run_tests.R --profile fast
Rscript scripts/run_tests.R --profile release
Rscript scripts/run_tests.R --profile all
Rscript scripts/run_lint.R
actionlint .github/workflows/ci.yml
```

The default and `fast` commands must be equivalent. Unknown profiles and extra
arguments must fail with a short usage message.

## Focused verification

During deletion, run only the changed test files. Run the complete fast profile
once after the high-value cut. Run the release profile once after its retained
cases are stable.

Do not repeatedly run the full Judbury evidence workflow locally. Exact release
CI is the authoritative end-to-end check.

## GitHub Actions

Ordinary push and pull request:

```text
lint -> fast tests -> one target smoke
```

Manual release dispatch:

```text
lint -> fast tests -> target smoke -> release tests -> Quarto/TinyTeX ->
full immutable evidence run -> bundle verification -> artifact upload
```

Dispatch only after the accepted implementation is on `main`:

```sh
gh workflow run ci.yml --ref main -f profile=release
```

Confirm that the resulting workflow `headSha` equals the accepted implementation
SHA before using its result as evidence.

Bundle validity is necessary but not sufficient. Reconstruct the named
ecological quantities and protected physical-location outputs independently
from the emitted release artifact before acceptance.

## Review questions

For every retained test family ask:

- What real failure does it prevent?
- Who benefits?
- When does it run?
- Can a developer or ecologist understand its purpose?
- What does it cost?
- Could one behavioral end-to-end case replace several implementation-detail
  assertions?

If these questions cannot be answered, delete or defer the test.

## Stop conditions

Stop and report rather than editing production code, changing a scientific
claim, inventing compatibility obligations, or adding a new dependency.

After two attempts without material runtime or clarity improvement, stop and
change approach. Do not polish assertion counts or naming after the accepted
core is clear.
