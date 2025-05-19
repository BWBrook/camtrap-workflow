# custom_funcs.R
# Helper functions for the Judbury camera-trap workflow

#' Read a JC CSV and return a clean tibble
#' @param path Relative file path (character)
#' @return tibble with snake-case names
#' @export
read_jc_csv <- function(path) {
  import::from("readr",   read_csv)
  import::from("janitor", clean_names)
  
  read_csv(path, show_col_types = FALSE) |>
    clean_names()
}

#' Verify that every observation site exists in the site table
#' Stops the pipeline if mismatches are found.
#' @param obs  tibble of observations
#' @param site tibble of site metadata
#' @return TRUE invisibly
#' @export
check_keys <- function(obs, site) {
  import::from("dplyr", pull)
  
  missing_sites <- setdiff(unique(obs$site), pull(site, site))
  if (length(missing_sites) > 0L) {
    stop(
      "QC failure: sites in obs missing from jc_site.csv: ",
      paste(missing_sites, collapse = ", ")
    )
  }
  invisible(TRUE)
}

#' Validate effort table: error if any NA values are present
#' @param op tibble of camera effort (0 / 1 values)
#' @return TRUE invisibly
#' @export
validate_effort <- function(op) {
  import::from("dplyr", across, summarise, select, everything)
  
  na_summary <- op |>
    select(-date) |>
    summarise(across(everything(), \(x) sum(is.na(x)))) |>
    unlist()
  
  total_na <- sum(na_summary)
  if (total_na > 0L) {
    stop("QC failure: effort table contains ", total_na, " NA values.")
  }
  invisible(TRUE)
}
