import::from("testthat", test_that, expect_equal, expect_true)
import::from("tibble", tibble)
import::from("here", here)

source(here("R", "beta_diversity.R"))

test_that("compute_beta_diversity returns pairwise rows", {
  abundance <- tibble(
    site = c("A", "B"),
    sp1 = c(1, 0),
    sp2 = c(0, 1)
  )
  site_raw <- tibble(
    site = c("A", "B"),
    lat = c(0, 1),
    lon = c(0, 1)
  )

  beta <- compute_beta_diversity(abundance, site_raw)
  expect_true(nrow(beta) == 1)
})

test_that("plot_distance_decay writes a file", {
  beta <- tibble(
    site1 = "A",
    site2 = "B",
    bray_curtis = 0.5,
    distance_km = 10
  )
  out_path <- tempfile(fileext = ".png")

  plot_distance_decay(beta, out_path)
  expect_true(file.exists(out_path))
})

test_that("selected Jaccard reconstructs symmetry, bounds, and empty unions", {
  presence <- data.frame(
    sp1 = c(1L, 1L, 0L, 0L),
    sp2 = c(1L, 0L, 1L, 0L),
    sp3 = c(0L, 0L, 0L, 0L),
    row.names = c("unit_a", "unit_b", "unit_c", "unit_empty"),
    check.names = FALSE
  )

  jaccard <- compute_selected_jaccard(presence)
  matrix_view <- xtabs(
    jaccard_dissimilarity ~ analysis_unit_id_1 + analysis_unit_id_2,
    data = jaccard,
    addNA = TRUE,
    na.action = stats::na.pass
  )
  value <- function(a, b) {
    jaccard$jaccard_dissimilarity[
      jaccard$analysis_unit_id_1 == a & jaccard$analysis_unit_id_2 == b
    ]
  }

  expect_equal(nrow(jaccard), 16L)
  expect_equal(value("unit_a", "unit_b"), 0.5)
  expect_equal(value("unit_b", "unit_a"), 0.5)
  expect_equal(value("unit_b", "unit_c"), 1)
  expect_equal(value("unit_a", "unit_a"), 0)
  expect_true(is.na(value("unit_empty", "unit_empty")))
  nonempty <- jaccard$jaccard_dissimilarity[!is.na(jaccard$jaccard_dissimilarity)]
  expect_true(all(nonempty >= 0 & nonempty <= 1))
  expect_equal(unname(matrix_view), t(unname(matrix_view)))
})
