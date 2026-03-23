import::from("testthat", test_that, expect_true)
import::from("targets", tar_make, tar_read_raw)
import::from("here", here)
import::from("withr", with_dir)

test_that("pipeline smoke: input contract validation target builds", {
  with_dir(here(), {
    suppressWarnings(
      tar_make(
        names = "input_contract_validation",
        callr_function = NULL,
        script = here("_targets.R"),
        reporter = "silent"
      )
    )

    result <- tar_read_raw("input_contract_validation", store = here("_targets"))
    expect_true(!is.null(result))
  })
})

test_that("pipeline smoke: exploratory summary and report targets build", {
  with_dir(here(), {
    suppressWarnings(
      tar_make(
        names = c("species_summary_csv", "report_html"),
        callr_function = NULL,
        script = here("_targets.R"),
        reporter = "silent"
      )
    )

    species_summary_path <- tar_read_raw("species_summary_csv", store = here("_targets"))
    report_html_path <- tar_read_raw("report_html", store = here("_targets"))

    expect_true(file.exists(species_summary_path))
    expect_true(file.exists(report_html_path))
  })
})
