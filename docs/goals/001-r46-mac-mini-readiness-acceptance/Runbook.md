# Goal 001 runbook

Run from `/Users/bwbrook/git/camtrap-workflow` in a login `zsh` shell.

## Orientation and host gates

```sh
pwd
git branch --show-current
git rev-parse HEAD
git remote -v
git status --short --branch
git status --untracked-files=all
git diff --stat
git diff --name-status
date -Iseconds
sw_vers
uname -m
R --version
Rscript --version
quarto --version
pandoc --version
actionlint -version
docker --version
docker info --format 'server={{.ServerVersion}} os={{.OperatingSystem}} arch={{.Architecture}} cpus={{.NCPU}} memory={{.MemTotal}}'
```

## Lock and repository checks

```sh
jq -e . renv.lock
jq -r '.R.Version, (.Packages | length)' renv.lock
Rscript -e 'renv::restore(prompt = FALSE)'
Rscript -e 'renv::status()'
Rscript scripts/run_lint.R
Rscript scripts/run_tests.R
actionlint .github/workflows/ci.yml
```

## Clean native pipelines

Each configuration is run with its target store contents and its own output directory removed first, preventing old cache metadata or rendered files from satisfying the gate. Preserve the tracked `_targets/.gitignore` policy file while clearing the store.

```sh
find _targets -mindepth 1 ! -name .gitignore -exec rm -rf {} +
rm -rf outputs/runs/latest
CAMTRAP_CONFIG=config.yml Rscript -e 'targets::tar_make(callr_function = NULL)'

find _targets -mindepth 1 ! -name .gitignore -exec rm -rf {} +
rm -rf outputs/runs/forest_example
CAMTRAP_CONFIG=config.forest_example.yml Rscript -e 'targets::tar_make(callr_function = NULL)'

find _targets -mindepth 1 ! -name .gitignore -exec rm -rf {} +
rm -rf outputs/runs/template_example
CAMTRAP_CONFIG=config.template_example.yml Rscript -e 'targets::tar_make(callr_function = NULL)'

find _targets -mindepth 1 ! -name .gitignore -exec rm -rf {} +
rm -rf outputs/runs/camtrapdp_example
CAMTRAP_CONFIG=config.camtrapdp_example.yml Rscript -e 'targets::tar_make(callr_function = NULL)'

find _targets -mindepth 1 ! -name .gitignore -exec rm -rf {} +
rm -rf outputs/runs/camtrapdp_export_example
CAMTRAP_CONFIG=config.camtrapdp_export.yml Rscript -e 'targets::tar_make(callr_function = NULL)'
```

Inspect the resulting paths with `find`, parse each `run_manifest.json` with `jq`, verify that listed relative outputs resolve beneath the run directory, and inspect representative CSV headers/row counts. Confirm the export package with `find outputs/runs/camtrapdp_export_example/camtrapdp_export -type f`.

## Docker gates

The image provenance deliberately identifies the tested uncommitted source bundle rather than claiming a clean commit.

```sh
docker build --build-arg GIT_COMMIT=b13c7fe708373cd305843a81542c047777791448-dirty -t camtrap-workflow:goal001-r46 .
docker run --rm --entrypoint Rscript camtrap-workflow:goal001-r46 scripts/run_lint.R
docker run --rm --entrypoint Rscript camtrap-workflow:goal001-r46 scripts/run_tests.R
rm -rf outputs/docker-goal001
mkdir -p outputs/docker-goal001
docker run --rm -v "$PWD/outputs/docker-goal001:/app/outputs" camtrap-workflow:goal001-r46
```

Inspect `outputs/docker-goal001/runs/latest/run_manifest.json` with `jq`; require `git_commit` to equal `b13c7fe708373cd305843a81542c047777791448-dirty`; and require non-empty report HTML/PDF plus methods HTML/PDF outputs.

## Final publication review

```sh
rm -f _targets/meta/meta
git diff --check
git status --short --branch
git diff --stat
git diff --name-status
git ls-files --others --exclude-standard
git check-ignore -v --no-index .DS_Store _targets/meta/meta _targets/objects/probe outputs/docker-goal001/runs/latest/run_manifest.json
```

Do not stage, commit, push, tag, or open a pull request during Goal 001 execution.
