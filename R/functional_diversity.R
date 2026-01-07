# functional_diversity.R

#' Compute functional diversity metrics per site
#'
#' @param community_abundance Tibble with site column and species columns.
#' @param traits_aligned Tibble with `species` column and trait columns.
#' @return List with `metrics` and `dropped_species` tibbles.
#' @export
compute_functional_diversity <- function(community_abundance, traits_aligned) {
  import::from("dplyr", select, mutate, filter)
  import::from("tibble", tibble)
  import::from("FD", dbFD)
  import::from("stats", model.matrix)

  species_cols <- setdiff(names(community_abundance), "site")
  traits_filtered <- traits_aligned |>
    filter(species %in% species_cols)

  if (nrow(traits_filtered) == 0) {
    metrics <- tibble(site = community_abundance$site, FRic = NA_real_, FDiv = NA_real_, FDis = NA_real_)
    return(list(metrics = metrics, dropped_species = tibble(species = species_cols)))
  }

  trait_matrix <- traits_filtered |>
    select(-species) |>
    mutate(across(everything(), ~ ifelse(is.na(.x), "unknown", as.character(.x)))) |>
    mutate(across(everything(), ~ as.factor(.x)))

  trait_df <- as.data.frame(trait_matrix)
  rownames(trait_df) <- traits_filtered$species

  dummy_matrix <- model.matrix(~ . - 1, data = trait_df)
  rownames(dummy_matrix) <- rownames(trait_df)

  species_order <- sort(intersect(species_cols, rownames(dummy_matrix)))
  if (length(species_order) == 0) {
    metrics <- tibble(site = community_abundance$site, FRic = NA_real_, FDiv = NA_real_, FDis = NA_real_)
    return(list(metrics = metrics, dropped_species = tibble(species = species_cols)))
  }

  dummy_matrix <- dummy_matrix[species_order, , drop = FALSE]
  comm_mat <- as.matrix(community_abundance[, species_order])
  rownames(comm_mat) <- community_abundance$site

  fd <- dbFD(
    x = dummy_matrix,
    a = comm_mat,
    calc.FRic = TRUE,
    calc.FDiv = TRUE,
    w.abun = TRUE,
    corr = "cailliez",
    messages = FALSE
  )

  n_sites <- nrow(comm_mat)
  fric_vals <- fd$FRic
  if (length(fric_vals) == 0) {
    fric_vals <- rep(NA_real_, n_sites)
  }
  fdiv_vals <- fd$FDiv
  if (length(fdiv_vals) == 0) {
    fdiv_vals <- rep(NA_real_, n_sites)
  }
  fdis_vals <- fd$FDis
  if (length(fdis_vals) == 0) {
    fdis_vals <- rep(NA_real_, n_sites)
  }

  metrics <- tibble(
    site = rownames(comm_mat),
    FRic = as.numeric(fric_vals),
    FDiv = as.numeric(fdiv_vals),
    FDis = as.numeric(fdis_vals)
  )

  dropped <- setdiff(species_cols, species_order)
  list(metrics = metrics, dropped_species = tibble(species = dropped))
}

#' Plot functional diversity metrics
#'
#' @param fd_metrics Tibble from `compute_functional_diversity()$metrics`.
#' @param out_path Output file path for the plot.
#' @return `out_path` invisibly.
#' @export
plot_functional_diversity <- function(fd_metrics, out_path) {
  import::from("ggplot2", ggplot, aes, geom_col, theme_minimal, labs, coord_flip, facet_wrap, ggsave)
  import::from("tidyr", pivot_longer)

  dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)

  fd_long <- fd_metrics |>
    pivot_longer(-site, names_to = "metric", values_to = "value") |>
    dplyr::filter(!is.na(value))

  p <- ggplot(fd_long, aes(x = reorder(site, value), y = value)) +
    geom_col() +
    coord_flip() +
    facet_wrap(~ metric, scales = "free_y") +
    theme_minimal() +
    labs(x = "Site", y = "Value")

  ggsave(out_path, p, width = 7, height = 5, dpi = 300)
  out_path
}
