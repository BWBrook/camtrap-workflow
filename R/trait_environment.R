# trait_environment.R

#' Compute site-level trait proportions (abundance-weighted)
#'
#' @param community_abundance Tibble with site column and species columns.
#' @param traits_aligned Tibble with `species` column and trait columns.
#' @param traits_to_use Optional vector of trait column names to include.
#' @return Tibble with site, trait, category, weight, total_weight, prop.
#' @export
compute_trait_site_proportions <- function(community_abundance, traits_aligned, traits_to_use = NULL) {
  import::from("dplyr", select, left_join, group_by, summarise, mutate, filter, all_of)
  import::from("tidyr", pivot_longer)

  species_cols <- setdiff(names(community_abundance), "site")
  traits_tbl <- traits_aligned |>
    filter(species %in% species_cols)

  if (!is.null(traits_to_use)) {
    traits_tbl <- traits_tbl |>
      select(species, all_of(traits_to_use))
  }

  traits_long <- traits_tbl |>
    pivot_longer(-species, names_to = "trait", values_to = "category") |>
    filter(!is.na(category))

  abundance_long <- community_abundance |>
    pivot_longer(-site, names_to = "species", values_to = "abundance")

  site_trait <- abundance_long |>
    left_join(traits_long, by = "species") |>
    filter(!is.na(category)) |>
    group_by(site, trait, category) |>
    summarise(weight = sum(abundance), .groups = "drop")

  totals <- site_trait |>
    group_by(site, trait) |>
    summarise(total_weight = sum(weight), .groups = "drop")

  site_trait |>
    left_join(totals, by = c("site", "trait")) |>
    mutate(prop = ifelse(total_weight > 0, weight / total_weight, NA_real_))
}

#' Compute trait–environment associations (Spearman)
#'
#' @param trait_site_props Output of `compute_trait_site_proportions()`.
#' @param site_raw Site table with environmental covariates.
#' @param env_vars Character vector of environmental variable names.
#' @return Tibble with trait, category, env_var, n_sites, rho, p_value.
#' @export
compute_trait_env_associations <- function(trait_site_props, site_raw, env_vars) {
  import::from("dplyr", select, left_join, group_by, summarise, filter, all_of)
  import::from("tidyr", pivot_longer)

  site_env <- site_raw |>
    select(site, all_of(env_vars))

  merged <- trait_site_props |>
    left_join(site_env, by = "site") |>
    pivot_longer(all_of(env_vars), names_to = "env_var", values_to = "env_value")

  safe_spearman <- function(x, y) {
    ok <- stats::complete.cases(x, y)
    x <- x[ok]
    y <- y[ok]
    if (length(x) < 3L) {
      return(c(rho = NA_real_, p_value = NA_real_))
    }
    if (length(unique(x)) < 2L || length(unique(y)) < 2L) {
      return(c(rho = NA_real_, p_value = NA_real_))
    }
    test <- suppressWarnings(stats::cor.test(x, y, method = "spearman"))
    c(rho = unname(test$estimate), p_value = test$p.value)
  }

  assoc <- merged |>
    group_by(trait, category, env_var) |>
    summarise(
      n_sites = sum(stats::complete.cases(prop, env_value)),
      stats = list(safe_spearman(prop, env_value)),
      .groups = "drop"
    )

  assoc$rho <- vapply(assoc$stats, `[[`, numeric(1), "rho")
  assoc$p_value <- vapply(assoc$stats, `[[`, numeric(1), "p_value")
  assoc$stats <- NULL
  assoc$p_adj <- stats::p.adjust(assoc$p_value, method = "BH")

  assoc
}

#' Plot trait–environment associations as a heatmap
#'
#' @param assoc_tbl Output of `compute_trait_env_associations()`.
#' @param out_path Output file path for the plot.
#' @return `out_path` invisibly.
#' @export
plot_trait_env_heatmap <- function(assoc_tbl, out_path) {
  import::from("ggplot2", ggplot, aes, geom_tile, theme_minimal, labs, facet_wrap)
  import::from("ggplot2", scale_fill_gradient2, scale_x_discrete, ggsave, theme, element_text)
  import::from("stringr", str_replace_all)
  import::from("dplyr", mutate, recode)

  dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)

  if (nrow(assoc_tbl) == 0) {
    p <- ggplot() + theme_minimal()
  } else {
    assoc_tbl <- assoc_tbl |>
      mutate(
        env_label = recode(
          env_var,
          canopy_h_m = "canopy",
          elevation_m = "elev",
          ndvi = "ndvi",
          .default = env_var
        )
      )

    p <- ggplot(assoc_tbl, aes(x = env_label, y = category, fill = rho)) +
      geom_tile(color = "white") +
      facet_wrap(~ trait, scales = "free_y") +
      scale_fill_gradient2(low = "#2166ac", mid = "white", high = "#b2182b", midpoint = 0, na.value = "grey90") +
      theme_minimal() +
      labs(x = "Environmental covariate", y = "Trait category", fill = "Spearman rho") +
      scale_x_discrete(labels = function(x) str_replace_all(x, "_", " ")) +
      theme(axis.text.x = element_text(angle = 0, hjust = 0.5, size = 9))
  }

  ggsave(out_path, p, width = 7, height = 5, dpi = 300)
  out_path
}
