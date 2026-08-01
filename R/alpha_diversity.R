# alpha_diversity.R

#' Compute alpha diversity metrics per site
#'
#' @param abundance_matrix Tibble with site column and species columns.
#' @return Tibble with richness, Shannon, and Simpson indices.
#' @export
compute_alpha_diversity <- function(abundance_matrix) {
  import::from("vegan", diversity, specnumber)
  import::from("dplyr", mutate, select)
  import::from("tidyr", replace_na)

  mat <- as.matrix(abundance_matrix[, setdiff(names(abundance_matrix), "site")])
  richness <- specnumber(mat)
  shannon <- diversity(mat, index = "shannon")
  simpson <- diversity(mat, index = "simpson")

  abundance_matrix |>
    select(site) |>
    mutate(
      richness = richness,
      shannon = shannon,
      simpson = simpson
    ) |>
    mutate(across(c(richness, shannon, simpson), ~ replace_na(.x, 0)))
}

#' Compute detection-limited observed richness at the selected resolution
#'
#' @param presence_matrix A 0/1 selected-resolution presence data frame.
#' @param analysis_units Optional row identities; defaults to row names.
#' @return Data frame with analytical unit and observed richness.
#' @export
compute_selected_observed_richness <- function( # nolint: object_length_linter.
    presence_matrix,
    analysis_units = rownames(presence_matrix)) {
  if (!is.data.frame(presence_matrix) && !is.matrix(presence_matrix)) {
    stop("Selected richness requires a presence matrix.")
  }
  matrix_value <- as.matrix(presence_matrix)
  if (!is.numeric(matrix_value) && !is.logical(matrix_value)) {
    stop("Selected presence values must be binary.")
  }
  if (anyNA(matrix_value) || any(!matrix_value %in% c(0, 1))) {
    stop("Selected presence values must be complete zero/one indicators.")
  }
  analysis_units <- as.character(analysis_units)
  if (length(analysis_units) != nrow(matrix_value) || anyNA(analysis_units) ||
        any(!nzchar(analysis_units)) || anyDuplicated(analysis_units)) {
    stop("Selected richness requires one unique analytical-unit identity per row.")
  }

  data.frame(
    analysis_unit_id = analysis_units,
    observed_richness = as.integer(rowSums(matrix_value)),
    stringsAsFactors = FALSE
  )
}

#' Plot alpha diversity summary
#'
#' @param alpha_tbl Output of `compute_alpha_diversity()`.
#' @param out_path File path where the figure is saved.
#' @return `out_path` invisibly.
#' @export
plot_alpha_diversity <- function(alpha_tbl, out_path) {
  import::from("ggplot2", ggplot, aes, geom_col, theme_minimal, labs, coord_flip, ggsave)

  dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)

  p <- ggplot(alpha_tbl, aes(x = reorder(site, richness), y = richness)) +
    geom_col() +
    coord_flip() +
    theme_minimal() +
    labs(x = "Site", y = "Species richness")

  ggsave(out_path, p, width = 6, height = 4, dpi = 300)
  out_path
}
