# time_qc.R

#' Compute time handling diagnostics
#'
#' @param obs Observations table with at least `site` and `datetime` columns.
#' @param tz Timezone string for parsing.
#' @param backward_threshold_hours Threshold for flagging backward jumps (hours).
#' @return List with `summary` and `flags` tibbles.
#' @export
compute_time_qc <- function(obs, tz = "Australia/Hobart", backward_threshold_hours = 1) {
  import::from("dplyr", mutate, group_by, arrange, lag, summarise, n, ungroup, filter, across, select)
  import::from("lubridate", dmy_hms)

  has_imageid <- "imageid" %in% names(obs)
  order_cols <- if (has_imageid) c("site", "imageid") else c("site", "datetime")

  parsed <- obs |>
    mutate(
      dt_local = dmy_hms(datetime, tz = tz, quiet = TRUE),
      dt_utc = dmy_hms(datetime, tz = "UTC", quiet = TRUE),
      parse_fail = is.na(dt_utc) & !is.na(datetime),
      dst_gap = is.na(dt_local) & !is.na(dt_utc)
    ) |>
    arrange(across(all_of(order_cols))) |>
    group_by(site) |>
    mutate(
      delta_hours = as.numeric(difftime(dt_local, lag(dt_local), units = "hours")),
      backward_jump = !is.na(delta_hours) & delta_hours < -abs(backward_threshold_hours)
    ) |>
    ungroup()

  summary <- parsed |>
    group_by(site) |>
    summarise(
      total_obs = n(),
      parse_fail = sum(parse_fail, na.rm = TRUE),
      dst_gap = sum(dst_gap, na.rm = TRUE),
      backward_jumps = sum(backward_jump, na.rm = TRUE),
      max_backward_hours = ifelse(all(is.na(delta_hours)), NA_real_, min(delta_hours, na.rm = TRUE)),
      max_forward_hours = ifelse(all(is.na(delta_hours)), NA_real_, max(delta_hours, na.rm = TRUE)),
      first_datetime = if (all(is.na(dt_local))) as.POSIXct(NA) else min(dt_local, na.rm = TRUE),
      last_datetime = if (all(is.na(dt_local))) as.POSIXct(NA) else max(dt_local, na.rm = TRUE),
      .groups = "drop"
    )

  flags <- parsed |>
    filter(parse_fail | dst_gap | backward_jump) |>
    select(site, datetime, dt_local, parse_fail, dst_gap, backward_jump, delta_hours)

  list(summary = summary, flags = flags)
}

#' Plot backward-jump counts per site
#'
#' @param summary Output of `compute_time_qc()$summary`.
#' @param out_path File path where the figure is saved.
#' @return `out_path` invisibly.
#' @export
plot_time_qc_backwards <- function(summary, out_path) {
  import::from("ggplot2", ggplot, aes, geom_col, theme_minimal, labs, ggsave)

  dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)

  p <- ggplot(summary, aes(x = site, y = backward_jumps)) +
    geom_col() +
    theme_minimal() +
    labs(x = "Site", y = "Backward time jumps (count)")

  ggsave(out_path, p, width = 8, height = 4, dpi = 300)
  out_path
}
