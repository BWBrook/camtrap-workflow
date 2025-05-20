# camtrap-workflow
A fully replicable workflow for analysis of camera-trap data.

### Notes
- `data/data_dictionary.csv` is auto-generated from `data_dictionary.md` using `scripts/update_data_dictionary.R`.
- Do not edit the CSV by hand; always edit the markdown and re-run the script.

### Enabling Pre-commit Hooks (one-time setup)
This project uses [pre-commit](https://pre-commit.com/) for Git hooks to keep documentation and code in sync.

1. Ensure Python is installed on your system (most have it already).
2. Install pre-commit: `pip install pre-commit` (or `uv pip install pre-commit`)
3. In your project root, run: `pre-commit install`

After this, no further action is required—pre-commit will run the relevant scripts automatically during `git commit`.

#### Setting up Pre-commit Hooks on Windows
This repo uses pre-commit hooks to sync the data dictionary.
If you get an error about `Rscript` not found, edit `.pre-commit-config.yaml` and update the `entry:` line to the full path of your local `Rscript.exe` (typically in `C:/Users/<username>/AppData/Local/Programs/R/R-4.x.x/bin/`).
For cross-platform teams, consider copying and renaming this file locally (it’s .gitignored by default) or coordinate a common location.
