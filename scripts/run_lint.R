#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(here)
  library(lintr)
})

lints <- c(
  lintr::lint(here("_targets.R")),
  lintr::lint_dir(here("R")),
  lintr::lint_dir(here("scripts"))
)

if (length(lints) > 0) {
  print(lints)
  quit(status = 1)
}
