# spatial_outputs.R

#' Write a bounded placeholder when location coordinates are unavailable
#'
#' @param out_path Output PNG path.
#' @param message Plain-language omission reason.
#' @return `out_path` invisibly.
write_location_map_placeholder <- function(out_path, message) {
  dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)
  plot <- ggplot2::ggplot() +
    ggplot2::annotate("text", x = 0, y = 0, label = message) +
    ggplot2::theme_void()
  ggplot2::ggsave(out_path, plot, width = 6, height = 4, dpi = 200)
  invisible(out_path)
}

#' Plot observed physical locations as points
#'
#' This deliberately does not interpolate environmental values or imply a
#' continuous sampled surface between cameras.
#'
#' @param site Physical-location table with `site`, `lat`, and `lon` columns.
#' @param out_path Output PNG path.
#' @param membership Optional selected-resolution membership table.
#' @param label_locations Whether to label physical locations.
#' @return `out_path` invisibly.
plot_physical_location_map <- function(
    site,
    out_path,
    membership = NULL,
    label_locations = TRUE) {
  required <- c("site", "lat", "lon")
  if (!is.data.frame(site) || !all(required %in% names(site))) {
    stop("Point map requires physical-location identifiers and coordinates.")
  }
  coordinates <- data.frame(
    physical_location_id = as.character(site$site),
    lat = suppressWarnings(as.numeric(site$lat)),
    lon = suppressWarnings(as.numeric(site$lon)),
    stringsAsFactors = FALSE
  )
  coordinates <- coordinates[
    !is.na(coordinates$lat) & !is.na(coordinates$lon),
    ,
    drop = FALSE
  ]
  if (nrow(coordinates) == 0L) {
    return(write_location_map_placeholder(
      out_path,
      "Point map omitted: no physical-location coordinates available"
    ))
  }
  if (anyNA(coordinates$physical_location_id) ||
        any(!nzchar(coordinates$physical_location_id)) ||
        anyDuplicated(coordinates$physical_location_id)) {
    stop("Point map physical-location identities must be complete and unique.")
  }

  colour_field <- NULL
  if (is.data.frame(membership) && all(
    c("physical_location_id", "analysis_unit_id") %in% names(membership)
  )) {
    keep <- unique(membership[c("physical_location_id", "analysis_unit_id")])
    if (anyDuplicated(keep$physical_location_id)) {
      stop("Point map membership assigns a physical location more than once.")
    }
    coordinates <- merge(
      coordinates,
      keep,
      by = "physical_location_id",
      all.x = TRUE,
      sort = FALSE
    )
    colour_field <- "analysis_unit_id"
  }

  dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)
  mapping <- if (is.null(colour_field)) {
    ggplot2::aes(x = lon, y = lat)
  } else {
    ggplot2::aes(x = lon, y = lat, colour = analysis_unit_id)
  }
  plot <- ggplot2::ggplot(coordinates, mapping) +
    ggplot2::geom_point(size = 2.8) +
    ggplot2::coord_equal() +
    ggplot2::theme_minimal() +
    ggplot2::labs(
      x = "Longitude",
      y = "Latitude",
      colour = "Selected analysis unit",
      title = "Observed physical locations"
    )
  if (isTRUE(label_locations)) {
    plot <- plot + ggplot2::geom_text(
      ggplot2::aes(label = physical_location_id),
      nudge_y = 0.00025,
      size = 3,
      check_overlap = TRUE,
      show.legend = FALSE
    )
  }
  ggplot2::ggsave(out_path, plot, width = 6.5, height = 5, dpi = 200)
  invisible(out_path)
}
