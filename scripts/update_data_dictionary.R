#!/usr/bin/env Rscript
# ---------------------------------------------------------------------------
# update_data_dictionary.R
#
# DO NOT EDIT data/data_dictionary.csv BY HAND.
# This file is always generated from data_dictionary.md by this script.
#
# Usage: Rscript scripts/update_data_dictionary.R
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  import::from("here", here)
})

source(here("R", "data_dictionary.R"))

md_path  <- here("data_dictionary.md")
csv_path <- here("data", "data_dictionary.csv")

dict_df <- read_data_dictionary_md(md_path)
write_data_dictionary_csv(dict_df, csv_path)

invisible(csv_path)
