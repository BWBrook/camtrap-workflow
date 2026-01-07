# traits.R

#' Default trait columns from the taxa table
#'
#' @param taxa_raw Taxa table.
#' @return Character vector of trait column names.
#' @export
default_trait_columns <- function(taxa_raw) {
  taxonomic_cols <- c("class", "order", "family", "genus", "species", "common", "short")
  setdiff(names(taxa_raw), taxonomic_cols)
}

#' Clean traits table for analysis
#'
#' @param taxa_raw Taxa table with a species short code column.
#' @param trait_columns Character vector of trait column names to keep.
#' @param species_column Column name for the species short code.
#' @return Tibble with `species` and cleaned trait columns.
#' @export
clean_traits_table <- function(taxa_raw, trait_columns, species_column = "short") {
  import::from("dplyr", select, mutate, across, rename, all_of)
  import::from("stringr", str_trim, str_to_lower)

  required <- c(species_column, trait_columns)
  missing_cols <- setdiff(required, names(taxa_raw))
  if (length(missing_cols) > 0L) {
    stop("Trait table missing columns: ", paste(missing_cols, collapse = ", "))
  }

  traits <- taxa_raw |>
    select(all_of(required)) |>
    rename(species = all_of(species_column)) |>
    mutate(
      species = str_to_lower(str_trim(as.character(species))),
      across(all_of(trait_columns), ~ str_to_lower(str_trim(as.character(.x))))
    ) |>
    mutate(
      across(
        all_of(trait_columns),
        ~ ifelse(.x %in% c("", "na", "n/a", "unknown", "none"), NA_character_, .x)
      )
    )

  dupes <- traits$species[duplicated(traits$species)]
  if (length(dupes) > 0L) {
    stop("Duplicate species codes in trait table: ", paste(unique(dupes), collapse = ", "))
  }

  traits
}

#' Align traits with a target species list
#'
#' @param traits_tbl Cleaned traits table with `species` column.
#' @param species_list Character vector of species codes to retain.
#' @return List with `aligned` and `missing` tibbles.
#' @export
align_traits_to_species <- function(traits_tbl, species_list) {
  import::from("dplyr", filter)
  import::from("tibble", tibble)

  species_list <- unique(species_list)
  aligned <- traits_tbl |>
    filter(species %in% species_list)

  missing <- setdiff(species_list, aligned$species)
  missing_tbl <- tibble(species = missing)

  list(aligned = aligned, missing = missing_tbl)
}
