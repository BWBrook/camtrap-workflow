# beta_diversity.R

#' Compute Haversine distance (km)
#'
#' @param lon1,lat1,lon2,lat2 Numeric coordinates in decimal degrees.
#' @return Distance in kilometers.
haversine_km <- function(lon1, lat1, lon2, lat2) {
  rad <- pi / 180
  lon1 <- lon1 * rad
  lat1 <- lat1 * rad
  lon2 <- lon2 * rad
  lat2 <- lat2 * rad

  dlon <- lon2 - lon1
  dlat <- lat2 - lat1
  a <- sin(dlat / 2)^2 + cos(lat1) * cos(lat2) * sin(dlon / 2)^2
  c <- 2 * atan2(sqrt(a), sqrt(1 - a))
  6371 * c
}

#' Compute beta diversity pairwise table
#'
#' @param abundance_matrix Tibble with site column and species columns.
#' @param site_raw Site table with lat/lon.
#' @return Tibble of pairwise Bray-Curtis and geographic distances.
#' @export
compute_beta_diversity <- function(abundance_matrix, site_raw) {
  import::from("vegan", vegdist)
  import::from("dplyr", select, filter)
  import::from("tibble", tibble)

  coords <- site_raw |>
    select(site, lat, lon) |>
    filter(!is.na(lat), !is.na(lon))

  sites <- intersect(abundance_matrix$site, coords$site)

  if (length(sites) < 2) {
    return(tibble(
      site1 = character(),
      site2 = character(),
      bray_curtis = numeric(),
      distance_km = numeric()
    ))
  }

  mat <- as.matrix(
    abundance_matrix[match(sites, abundance_matrix$site), setdiff(names(abundance_matrix), "site")]
  )
  rownames(mat) <- sites

  bray <- as.matrix(vegdist(mat, method = "bray"))

  coords <- coords |>
    filter(site %in% sites)

  lat_vals <- stats::setNames(as.numeric(coords$lat), coords$site)
  lon_vals <- stats::setNames(as.numeric(coords$lon), coords$site)
  rows <- list()

  for (i in seq_along(sites)) {
    for (j in seq_len(i - 1)) {
      s1 <- sites[i]
      s2 <- sites[j]
      d_km <- haversine_km(lon_vals[s1], lat_vals[s1], lon_vals[s2], lat_vals[s2])
      rows[[length(rows) + 1]] <- tibble(
        site1 = s1,
        site2 = s2,
        bray_curtis = bray[s1, s2],
        distance_km = d_km
      )
    }
  }

  dplyr::bind_rows(rows)
}

#' Plot distance–decay (beta diversity vs distance)
#'
#' @param beta_tbl Output of `compute_beta_diversity()`.
#' @param out_path File path where the figure is saved.
#' @return `out_path` invisibly.
#' @export
plot_distance_decay <- function(beta_tbl, out_path) {
  import::from("ggplot2", ggplot, aes, geom_point, geom_smooth, theme_minimal, labs, ggsave)

  dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)

  if (nrow(beta_tbl) == 0) {
    p <- ggplot() +
      theme_minimal() +
      labs(
        x = "Distance between sites (km)",
        y = "Bray-Curtis dissimilarity"
      )
  } else {
    p <- ggplot(beta_tbl, aes(x = distance_km, y = bray_curtis)) +
      geom_point(alpha = 0.7) +
      geom_smooth(method = "lm", se = TRUE) +
      theme_minimal() +
      labs(x = "Distance between sites (km)", y = "Bray-Curtis dissimilarity")
  }

  ggsave(out_path, p, width = 6, height = 4, dpi = 300)
  out_path
}
