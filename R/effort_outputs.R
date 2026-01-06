# effort_outputs.R

#' Summarise effort per site
#'
#' @param op_long Long-format effort table with columns `trap_date`, `site`, `on_off`.
#' @return Tibble with effort metrics per site.
#' @export
summarise_effort <- function(op_long) {
  import::from("dplyr", group_by, summarise, n, mutate)

  op_long |>
    group_by(site) |>
    summarise(
      trap_nights = sum(on_off),
      days_total = n(),
      first_date = min(trap_date),
      last_date = max(trap_date),
      .groups = "drop"
    ) |>
    mutate(prop_active = trap_nights / days_total)
}

#' Validate that filtered observations only occur on active days
#'
#' @param obs_filtered Filtered observations (after effort censoring).
#' @param op_long Long-format effort table.
#' @return TRUE invisibly if validation passes.
#' @export
validate_effort_censoring <- function(obs_filtered, op_long) {
  import::from("dplyr", left_join, filter)

  joined <- obs_filtered |>
    left_join(op_long, by = c("site", "trap_date"))

  bad <- joined |>
    filter(is.na(on_off) | on_off != 1)

  if (nrow(bad) > 0) {
    stop(
      "Effort censoring failed: detections found on inactive or missing effort days.",
      call. = FALSE
    )
  }

  invisible(TRUE)
}

#' Plot a histogram of trap-night effort per site
#'
#' @param effort_summary Output of `summarise_effort()`.
#' @param out_path File path where the figure is saved.
#' @return `out_path` invisibly.
#' @export
plot_effort_histogram <- function(effort_summary, out_path) {
  import::from("ggplot2", ggplot, aes, geom_histogram, theme_minimal, labs, ggsave)

  dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)

  p <- ggplot(effort_summary, aes(trap_nights)) +
    geom_histogram(bins = 10, color = "white") +
    theme_minimal() +
    labs(x = "Trap nights per site", y = "Number of sites")

  ggsave(out_path, p, width = 6, height = 4, dpi = 300)
  out_path
}

#' Plot a site-by-date effort heatmap
#'
#' @param op_long Long-format effort table.
#' @param out_path File path where the figure is saved.
#' @return `out_path` invisibly.
#' @export
plot_effort_heatmap <- function(op_long, out_path) {
  import::from("ggplot2", ggplot, aes, geom_tile, theme_minimal, labs, scale_fill_manual, ggsave)

  dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)

  p <- ggplot(op_long, aes(trap_date, site, fill = factor(on_off))) +
    geom_tile() +
    scale_fill_manual(values = c("0" = "#d95f02", "1" = "#1b9e77")) +
    theme_minimal() +
    labs(x = "Date", y = "Site", fill = "Active")

  ggsave(out_path, p, width = 9, height = 6, dpi = 300)
  out_path
}
