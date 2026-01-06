# descriptive_outputs.R

#' Compute RAI with Poisson confidence intervals
#'
#' @param events_per_day Tibble with columns site, species, date, events.
#' @param trap_nights Tibble with columns site, trap_nights.
#' @param alpha Significance level for confidence intervals (default 0.05).
#' @return List with `site` and `pooled` tibbles including CI columns.
#' @export
calc_rai_with_ci <- function(events_per_day, trap_nights, alpha = 0.05) {
  import::from("dplyr", group_by, summarise, left_join, mutate, select)
  import::from("stats", qchisq)

  poisson_rate_ci <- function(events, exposure) {
    lower_count <- ifelse(events == 0, 0, 0.5 * qchisq(alpha / 2, 2 * events))
    upper_count <- 0.5 * qchisq(1 - alpha / 2, 2 * (events + 1))

    lower <- ifelse(exposure > 0, lower_count / exposure, NA_real_)
    upper <- ifelse(exposure > 0, upper_count / exposure, NA_real_)

    list(lower = lower, upper = upper)
  }

  site <- events_per_day |>
    group_by(site, species) |>
    summarise(events = sum(events), .groups = "drop") |>
    left_join(trap_nights, by = "site") |>
    mutate(rai = ifelse(trap_nights > 0, events / trap_nights, NA_real_))

  site_ci <- poisson_rate_ci(site$events, site$trap_nights)
  site <- site |>
    mutate(rai_lower = site_ci$lower, rai_upper = site_ci$upper) |>
    select(site, species, events, trap_nights, rai, rai_lower, rai_upper)

  pooled <- site |>
    group_by(species) |>
    summarise(
      events = sum(events),
      trap_nights = sum(trap_nights),
      .groups = "drop"
    ) |>
    mutate(rai = ifelse(trap_nights > 0, events / trap_nights, NA_real_))

  pooled_ci <- poisson_rate_ci(pooled$events, pooled$trap_nights)
  pooled <- pooled |>
    mutate(rai_lower = pooled_ci$lower, rai_upper = pooled_ci$upper) |>
    select(species, events, trap_nights, rai, rai_lower, rai_upper)

  list(site = site, pooled = pooled)
}

#' Plot pooled RAI with confidence intervals
#'
#' @param rai_species Pooled RAI table from `calc_rai_with_ci()$pooled`.
#' @param out_path File path where the figure is saved.
#' @param top_n Number of species to display (default 15).
#' @return `out_path` invisibly.
#' @export
plot_rai_species <- function(rai_species, out_path, top_n = 15) {
  import::from("dplyr", arrange, slice_head)
  import::from("ggplot2", ggplot, aes, geom_col, geom_errorbar, theme_minimal, labs, coord_flip, ggsave)

  dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)

  plot_data <- rai_species |>
    arrange(desc(rai)) |>
    slice_head(n = top_n)

  p <- ggplot(plot_data, aes(x = reorder(species, rai), y = rai)) +
    geom_col() +
    geom_errorbar(aes(ymin = rai_lower, ymax = rai_upper), width = 0.2) +
    coord_flip() +
    theme_minimal() +
    labs(x = "Species", y = "RAI (events per trap night)")

  ggsave(out_path, p, width = 7, height = 5, dpi = 300)
  out_path
}

#' Summarise diel activity across all events
#'
#' @param obs_events Observations with `flash` values.
#' @return Tibble with period, n, prop.
#' @export
summarise_diel_overall <- function(obs_events) {
  import::from("dplyr", mutate, count)

  obs_events |>
    mutate(period = ifelse(flash == 1, "night", "day")) |>
    count(period, name = "n") |>
    mutate(prop = n / sum(n))
}

#' Plot overall diel proportions
#'
#' @param diel_overall Tibble from `summarise_diel_overall()`.
#' @param out_path File path where the figure is saved.
#' @return `out_path` invisibly.
#' @export
plot_diel_overall <- function(diel_overall, out_path) {
  import::from("ggplot2", ggplot, aes, geom_col, theme_minimal, labs, ggsave)

  dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)

  p <- ggplot(diel_overall, aes(x = period, y = prop, fill = period)) +
    geom_col(show.legend = FALSE) +
    theme_minimal() +
    labs(x = "Period", y = "Proportion of events")

  ggsave(out_path, p, width = 5, height = 4, dpi = 300)
  out_path
}
