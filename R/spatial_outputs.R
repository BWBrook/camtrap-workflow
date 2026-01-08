# spatial_outputs.R

#' Choose a surface variable for spatial interpolation
#'
#' @param site Site table with candidate covariates.
#' @param surface_var Optional preferred variable name.
#' @return Selected variable name or NULL if none available.
select_surface_var <- function(site, surface_var = NULL) {
  candidates <- c("ndvi", "elevation_m", "canopy_h_m")
  if (!is.null(surface_var)) {
    candidates <- c(surface_var, setdiff(candidates, surface_var))
  }

  for (var in candidates) {
    if (var %in% names(site) && any(!is.na(site[[var]]))) {
      return(var)
    }
  }

  NULL
}

#' Interpolate a site-level surface using loess
#'
#' @param site Site table with lat/lon and surface variable.
#' @param surface_var Variable name to interpolate.
#' @param resolution Grid resolution (number of steps per axis).
#' @param buffer_deg Buffer in degrees around site extent.
#' @return Tibble with lon, lat, value columns.
interpolate_site_surface <- function(site, surface_var, resolution = 200, buffer_deg = 0.01) {
  import::from("dplyr", filter)
  import::from("tibble", tibble)

  site <- site |>
    filter(!is.na(lat), !is.na(lon))
  site <- site[!is.na(site[[surface_var]]), , drop = FALSE]

  if (nrow(site) < 3) {
    return(tibble(lon = numeric(), lat = numeric(), value = numeric()))
  }

  resolution <- max(20, min(400, as.integer(resolution)))

  lon_range <- range(site$lon, na.rm = TRUE)
  lat_range <- range(site$lat, na.rm = TRUE)

  grid <- expand.grid(
    lon = seq(lon_range[1] - buffer_deg, lon_range[2] + buffer_deg, length.out = resolution),
    lat = seq(lat_range[1] - buffer_deg, lat_range[2] + buffer_deg, length.out = resolution)
  )

  model <- tryCatch(
    stats::loess(
      stats::as.formula(paste(surface_var, "~ lon + lat")),
      data = site,
      span = 0.75,
      degree = 2
    ),
    error = function(e) NULL
  )

  if (is.null(model)) {
    return(tibble(lon = numeric(), lat = numeric(), value = numeric()))
  }

  grid$value <- as.numeric(stats::predict(model, newdata = grid))

  tibble(lon = grid$lon, lat = grid$lat, value = grid$value)
}

#' Write a placeholder plot when a map cannot be rendered
#'
#' @param out_path Output PNG path.
#' @param message Message to display in the plot.
#' @return `out_path` invisibly.
#' @export
write_placeholder_plot <- function(out_path, message) {
  import::from("ggplot2", ggplot, annotate, theme_minimal, ggsave)

  dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)

  p <- ggplot() +
    annotate("text", x = 0, y = 0, label = message) +
    theme_minimal()

  ggsave(out_path, p, width = 6, height = 4, dpi = 300)
  invisible(out_path)
}

#' Plot spatial site map with interpolated surface
#'
#' @param site Site table with lat/lon and covariates.
#' @param out_path Output PNG path.
#' @param surface_var Optional preferred surface variable (e.g., "ndvi").
#' @param resolution Grid resolution for interpolation.
#' @param buffer_deg Buffer in degrees around site extent.
#' @return `out_path` invisibly.
#' @export
plot_site_map <- function(
  site,
  out_path,
  surface_var = NULL,
  resolution = 200,
  buffer_deg = 0.01
) {
  import::from("dplyr", filter)
  import::from("ggplot2", ggplot, aes, geom_raster, geom_point, theme_minimal, labs, ggsave)
  import::from("ggplot2", coord_equal)
  import::from("scales", alpha)

  dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)

  site <- site |>
    filter(!is.na(lat), !is.na(lon))

  if (nrow(site) == 0) {
    return(write_placeholder_plot(out_path, "No site coordinates available"))
  }

  surface_var <- select_surface_var(site, surface_var)
  surface_tbl <- tibble::tibble()
  surface_label <- NULL

  if (!is.null(surface_var)) {
    surface_tbl <- interpolate_site_surface(
      site,
      surface_var = surface_var,
      resolution = resolution,
      buffer_deg = buffer_deg
    )
    surface_label <- gsub("_", " ", surface_var)
  }

  p <- ggplot()

  if (nrow(surface_tbl) > 0 && any(!is.na(surface_tbl$value))) {
    p <- p +
      geom_raster(
        data = surface_tbl,
        aes(x = lon, y = lat, fill = value),
        alpha = 0.85
      ) +
      ggplot2::scale_fill_viridis_c(option = "C", na.value = "transparent")
  }

  p <- p +
    geom_point(
      data = site,
      aes(x = lon, y = lat),
      shape = 21,
      size = 2.5,
      stroke = 0.4,
      fill = "white",
      color = alpha("black", 0.8)
    ) +
    coord_equal() +
    theme_minimal() +
    labs(
      x = "Longitude",
      y = "Latitude",
      fill = ifelse(is.null(surface_label), "Value", surface_label),
      title = "Site map with interpolated surface"
    )

  ggsave(out_path, p, width = 6.5, height = 5, dpi = 300)
  invisible(out_path)
}
