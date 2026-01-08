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

  if (any(is.na(grid$value))) {
    lm_model <- tryCatch(
      stats::lm(stats::as.formula(paste(surface_var, "~ lon + lat")), data = site),
      error = function(e) NULL
    )
    if (!is.null(lm_model)) {
      missing <- is.na(grid$value)
      grid$value[missing] <- as.numeric(stats::predict(lm_model, newdata = grid[missing, ]))
    }
  }

  if (any(!is.na(grid$value))) {
    min_val <- min(site[[surface_var]], na.rm = TRUE)
    max_val <- max(site[[surface_var]], na.rm = TRUE)
    grid$value <- pmin(pmax(grid$value, min_val), max_val)
  }

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
#' @param label_sites Logical; if TRUE, label sites by name.
#' @param label_size Text size for site labels.
#' @param label_nudge_frac Fraction of the map range used to offset labels.
#' @param show_north_arrow Logical; if TRUE, add a north arrow.
#' @param show_scale_bar Logical; if TRUE, add a scale bar.
#' @param scale_bar_km Length of the scale bar (km).
#' @return `out_path` invisibly.
#' @export
plot_site_map <- function(
  site,
  out_path,
  surface_var = NULL,
  resolution = 200,
  buffer_deg = 0.01,
  label_sites = TRUE,
  label_size = 3,
  label_nudge_frac = 0.01,
  show_north_arrow = TRUE,
  show_scale_bar = TRUE,
  scale_bar_km = 1
) {
  import::from("dplyr", filter)
  import::from("ggplot2", ggplot, aes, geom_raster, geom_point, geom_text, theme_minimal, labs, ggsave, annotate)
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

  lon_range <- range(site$lon, na.rm = TRUE)
  lat_range <- range(site$lat, na.rm = TRUE)
  lon_span <- diff(lon_range)
  lat_span <- diff(lat_range)

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

  if (isTRUE(label_sites)) {
    nudge_x <- ifelse(lon_span == 0, 0.001, lon_span * label_nudge_frac)
    nudge_y <- ifelse(lat_span == 0, 0.001, lat_span * label_nudge_frac)

    p <- p +
      geom_text(
        data = site,
        aes(x = lon, y = lat, label = site),
        nudge_x = nudge_x,
        nudge_y = nudge_y,
        size = label_size,
        check_overlap = TRUE
      )
  }

  if (isTRUE(show_scale_bar) && !is.null(scale_bar_km) && scale_bar_km > 0) {
    lat_ref <- lat_range[1] + lat_span * 0.05
    lon_ref <- lon_range[1] + lon_span * 0.05
    deg_per_km <- 1 / (111.32 * cos(mean(lat_range) * pi / 180))
    bar_deg <- scale_bar_km * deg_per_km
    p <- p +
      annotate(
        "segment",
        x = lon_ref,
        xend = lon_ref + bar_deg,
        y = lat_ref,
        yend = lat_ref,
        linewidth = 0.6
      ) +
      annotate(
        "text",
        x = lon_ref + bar_deg / 2,
        y = lat_ref + lat_span * 0.02,
        label = paste0(scale_bar_km, " km"),
        size = label_size
      )
  }

  if (isTRUE(show_north_arrow)) {
    arrow_x <- lon_range[1] + lon_span * 0.08
    arrow_y <- lat_range[2] - lat_span * 0.08
    arrow_len <- ifelse(lat_span == 0, 0.002, lat_span * 0.08)
    p <- p +
      annotate(
        "segment",
        x = arrow_x,
        xend = arrow_x,
        y = arrow_y,
        yend = arrow_y + arrow_len,
        linewidth = 0.6,
        arrow = grid::arrow(length = grid::unit(0.15, "inches"))
      ) +
      annotate(
        "text",
        x = arrow_x,
        y = arrow_y + arrow_len + lat_span * 0.02,
        label = "N",
        size = label_size
      )
  }

  ggsave(out_path, p, width = 6.5, height = 5, dpi = 300)
  invisible(out_path)
}
