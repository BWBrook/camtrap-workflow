# input_loader.R

#' Load input tables based on config input mode
#'
#' @param config Configuration list.
#' @param source_snapshot Optional verified parser-consumed source snapshot.
#' @return List with `site`, `taxa`, `op`, `obs` tibbles.
#' @export
load_inputs <- function(config, source_snapshot = NULL) {
  import::here(read_jc_csv, .from = "R/custom_funcs.R")
  import::here(read_camtrapdp_dataset, camtrapdp_to_internal, .from = "R/camtrapdp_adapter.R")

  paths <- config$paths$inputs
  if (!is.null(source_snapshot) && !is.null(source_snapshot$parser_paths)) {
    paths <- source_snapshot$parser_paths
  }

  mode <- if (is.null(config$input_mode)) "four_table" else config$input_mode
  if (mode == "camtrapdp") {
    dp <- read_camtrapdp_dataset(paths$camtrapdp)
    camtrapdp_to_internal(dp, tz = config$timezone)
  } else {
    list(
      site = read_jc_csv(paths$site),
      op = read_jc_csv(paths$op),
      obs = read_jc_csv(paths$obs),
      taxa = read_jc_csv(paths$taxa)
    )
  }
}
