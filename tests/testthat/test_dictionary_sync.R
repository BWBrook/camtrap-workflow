import::from("testthat", test_that, expect_equal, expect_false)
import::from("readr", read_csv, cols)
import::from("dplyr", arrange)
import::from("here", here)
import::from("tibble", as_tibble)

source(here("R", "data_dictionary.R"))

test_that("Markdown and CSV are identical", {
  csv_df <- read_csv(here("data", "data_dictionary.csv"),
                     show_col_types = FALSE,
                     comment = "#",
                     col_types = cols(.default = "c")) |>
            as_tibble() |>
            arrange(file, Column)

  md_df  <- read_data_dictionary_md(here("data_dictionary.md")) |>
    as_tibble() |>
    arrange(file, Column)

  expect_equal(csv_df, md_df)
})

test_that("No placeholder rows remain", {
  md_df <- read_data_dictionary_md(here("data_dictionary.md"))
  expect_false(any(md_df == "…"))
})
