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

#' Compute descriptive selected-resolution Jaccard dissimilarity
#'
#' @param presence_matrix A 0/1 selected-resolution presence data frame.
#' @param analysis_units Optional row identities; defaults to row names.
#' @return Full symmetric pair table, including diagonals.
#' @export
compute_selected_jaccard <- function(
    presence_matrix,
    analysis_units = rownames(presence_matrix)) {
  if (!is.data.frame(presence_matrix) && !is.matrix(presence_matrix)) {
    stop("Selected Jaccard requires a presence matrix.")
  }
  matrix_value <- as.matrix(presence_matrix)
  if ((!is.numeric(matrix_value) && !is.logical(matrix_value)) ||
        anyNA(matrix_value) || any(!matrix_value %in% c(0, 1))) {
    stop("Selected Jaccard requires complete zero/one presence values.")
  }
  analysis_units <- as.character(analysis_units)
  if (length(analysis_units) != nrow(matrix_value) || anyNA(analysis_units) ||
        any(!nzchar(analysis_units)) || anyDuplicated(analysis_units)) {
    stop("Selected Jaccard requires one unique analytical-unit identity per row.")
  }

  rows <- vector("list", length(analysis_units)^2)
  index <- 0L
  for (i in seq_along(analysis_units)) {
    first <- matrix_value[i, ] == 1
    for (j in seq_along(analysis_units)) {
      second <- matrix_value[j, ] == 1
      union_count <- sum(first | second)
      dissimilarity <- if (union_count == 0L) {
        NA_real_
      } else {
        1 - sum(first & second) / union_count
      }
      index <- index + 1L
      rows[[index]] <- data.frame(
        analysis_unit_id_1 = analysis_units[[i]],
        analysis_unit_id_2 = analysis_units[[j]],
        jaccard_dissimilarity = as.numeric(dissimilarity),
        stringsAsFactors = FALSE
      )
    }
  }
  if (length(rows) == 0L) {
    return(data.frame(
      analysis_unit_id_1 = character(),
      analysis_unit_id_2 = character(),
      jaccard_dissimilarity = numeric(),
      stringsAsFactors = FALSE
    ))
  }
  do.call(rbind, rows)
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
