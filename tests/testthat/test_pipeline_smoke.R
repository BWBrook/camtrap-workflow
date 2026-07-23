import::from("testthat", test_that, expect_equal, expect_false, expect_true)
import::from("targets", tar_make, tar_manifest, tar_read_raw)
import::from("here", here)
import::from("withr", local_envvar, with_dir)

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
    dictionary_paths <- c(
      here("data_dictionary.md"),
      here("data", "data_dictionary.csv")
    )
    dictionary_before <- unname(tools::md5sum(dictionary_paths))
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
    expect_equal(unname(tools::md5sum(dictionary_paths)), dictionary_before)
  })
})

test_that("data dictionary maintenance is absent from the scientific DAG", {
  with_dir(here(), {
    manifest <- tar_manifest(
      script = here("_targets.R"),
      fields = "name",
      callr_function = NULL
    )
    expect_false(any(manifest$name %in% c(
      "data_dictionary_md",
      "data_dictionary_csv"
    )))
  })
})

test_that("direct partial target calls cannot complete or advance latest", {
  with_dir(here(), {
    pointer <- here("outputs", "latest")
    pointer_before <- if (file.exists(pointer)) {
      readBin(pointer, "raw", n = file.info(pointer)$size)
    } else {
      raw()
    }
    local_envvar(c(
      CAMTRAP_CONFIG = here("config.template_example.yml"),
      CAMTRAP_EVIDENCE_CONTEXT = NA
    ))

    tar_make(
      names = "config",
      callr_function = NULL,
      script = here("_targets.R"),
      reporter = "silent"
    )

    pointer_after <- if (file.exists(pointer)) {
      readBin(pointer, "raw", n = file.info(pointer)$size)
    } else {
      raw()
    }
    partial_root <- here("outputs", "work", "template_example")
    completion <- if (dir.exists(partial_root)) {
      list.files(partial_root, pattern = "^COMPLETED[.]json$", recursive = TRUE)
    } else {
      character()
    }

    expect_equal(pointer_after, pointer_before)
    expect_equal(completion, character())
  })
})
