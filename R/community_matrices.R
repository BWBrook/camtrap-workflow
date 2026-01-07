# community_matrices.R

#' Build community presence and abundance matrices
#'
#' @param events_per_day Tibble with columns site, species, date, events.
#' @param sites Optional character vector of sites to include.
#' @return List with `abundance` and `presence` tibbles (site × species).
#' @export
build_community_matrices <- function(events_per_day, sites = NULL) {
  import::from("dplyr", group_by, summarise, mutate)
  import::from("tidyr", pivot_wider, replace_na)
  import::from("tibble", tibble)
  import::from("dplyr", left_join)

  abundance <- events_per_day |>
    group_by(site, species) |>
    summarise(events = sum(events), .groups = "drop") |>
    pivot_wider(names_from = species, values_from = events, values_fill = 0)

  if (!is.null(sites)) {
    abundance <- tibble(site = unique(sites)) |>
      left_join(abundance, by = "site") |>
      mutate(across(-site, ~ replace_na(.x, 0)))
  }

  presence <- abundance |>
    mutate(across(-site, \(x) ifelse(x > 0, 1L, 0L)))

  list(abundance = abundance, presence = presence)
}
