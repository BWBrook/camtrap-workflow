# Run manifest

The run manifest records provenance for each pipeline run and is written to
`outputs/runs/<run_id>/run_manifest.json`.

## Purpose

The manifest is the authoritative, machine-readable record for a run. It
captures configuration identity, schema version, timestamps, and the concrete
output artefacts that were produced.

## Schema (v0.7.1)

Top-level fields:

- `run_id` — UTC timestamp identifier (format `YYYYMMDDTHHMMSSZ`).
- `timestamp_utc` — ISO-8601 timestamp in UTC for when the manifest was written.
- `schema_version` — input schema version string (from `schema_version.txt`).
- `git_commit` — commit hash if available, otherwise `null`.
- `config` — config identity:
  - `path` — path to the config file, relative to the run directory.
  - `md5` — md5 hash of the config file (or `null` if unavailable).
- `params` — parsed configuration values used for the run.
- `outputs` — nested lists of produced artefacts (paths relative to the run directory):
  - `tables` — CSV tables.
  - `figures` — PNG figures.
  - `models` — RDS model objects.
  - `report` — HTML/PDF report paths.
  - `manuscript` — methods manuscript HTML/PDF paths.
  - `exports` — optional export artefacts (e.g., Camtrap DP datapackage).
  - `session_info` — session info text path.
- `session_info` — path to `session_info.txt`, relative to the run directory.

## Path rules

- All manifest paths are stored **relative to the run directory** to ensure
  portability across machines.
- Absolute filesystem paths must not appear in the manifest.

## Example (abridged)

```json
{
  "run_id": "20260107T051012Z",
  "timestamp_utc": "2026-01-07T05:10:12Z",
  "schema_version": "0.1.0",
  "git_commit": "6afda24...",
  "config": {
    "path": "../../config.yml",
    "md5": "a1b2c3..."
  },
  "outputs": {
    "tables": {
      "rai_species": "tables/rai_species.csv"
    },
    "figures": {
      "rai_species": "figures/rai_species.png"
    }
  },
  "session_info": "session_info.txt"
}
```
