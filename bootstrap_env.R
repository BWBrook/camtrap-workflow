# bootstrap_env.R
# Purpose: initialise or update the project‑local renv library

if (!requireNamespace("renv", quietly = TRUE)) install.packages("renv")
if (!requireNamespace("import", quietly = TRUE)) install.packages("import")

import::from("renv", init, install, snapshot)

# List of CRAN packages required for the Judbury camera‑trap workflow
required_pkgs <- c(
  "targets", "camtrapR", "unmarked", "spOccupancy", "readr", "dplyr",
  "FD", "cowplot", "sf", "janitor", "import", "here", "testthat", "fs"
)

# Initialise a bare renv project on first run
if (!file.exists("renv.lock")) {
  init(bare = TRUE)
  install(required_pkgs)
  snapshot()
  message("renv initialised and packages installed.")
} else {
  message("renv.lock detected — no action taken.")
}
