#!/usr/bin/env Rscript
# bootstrap_env.R — Initialise or update the project-local renv library.
# Run from project root: Rscript scripts/bootstrap_env.R

if (!requireNamespace("renv", quietly = TRUE)) install.packages("renv")
if (!requireNamespace("import", quietly = TRUE)) install.packages("import")

import::from("renv", init, install, snapshot, status)

required_pkgs <- c(
  "targets", "camtrapR", "unmarked", "spOccupancy",
  "readr", "dplyr", "tidyr", "lubridate",
  "FD", "cowplot", "sf", "janitor",
  "import", "here", "testthat", "fs"
)

# ensure project library exists, then reconcile
init(bare = TRUE) |> invisible()

missing <- setdiff(required_pkgs, status()$library$packages)
if (length(missing)) install(missing)

snapshot()
message("renv environment up to date.")
