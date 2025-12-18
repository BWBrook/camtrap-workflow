#!/usr/bin/env Rscript
# bootstrap_env.R — Initialise or update the project-local renv library.
# Run from project root: Rscript ./bootstrap_env.R

if (!requireNamespace("renv", quietly = TRUE)) install.packages("renv")

renv::activate()
renv::restore(prompt = FALSE)

message("renv restore complete.")
