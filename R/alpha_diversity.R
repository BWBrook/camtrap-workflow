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
