import::from("testthat", test_that, expect_equal)
import::from("readr", read_csv)
import::from("dplyr", arrange)
import::from("here", here)

source(here("scripts", "update_data_dictionary.R"))

test_that("Markdown and CSV are identical", {
  csv_df <- read_csv(here("data", "data_dictionary.csv"),
                     show_col_types = FALSE,
                     col_types = cols(.default = "c")) |>
            arrange(file, Column)

  md_df  <- dict_df |> arrange(file, Column)

  expect_equal(csv_df, md_df)
})

test_that("No placeholder rows remain", {
  expect_false(any(md_df == "…"))
})
