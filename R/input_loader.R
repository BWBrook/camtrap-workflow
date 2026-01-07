# input_loader.R

#' Load input tables based on config input mode
#'
#' @param config Configuration list.
#' @return List with `site`, `taxa`, `op`, `obs` tibbles.
#' @export
load_inputs <- function(config) {
  import::here(read_jc_csv, .from = "R/custom_funcs.R")
  import::here(read_camtrapdp_dataset, camtrapdp_to_internal, .from = "R/camtrapdp_adapter.R")

  mode <- if (is.null(config$input_mode)) "four_table" else config$input_mode
  if (mode == "camtrapdp") {
    dp <- read_camtrapdp_dataset(config$paths$inputs$camtrapdp)
    camtrapdp_to_internal(dp, tz = config$timezone)
  } else {
    list(
      site = read_jc_csv(config$paths$inputs$site),
      op = read_jc_csv(config$paths$inputs$op),
      obs = read_jc_csv(config$paths$inputs$obs),
      taxa = read_jc_csv(config$paths$inputs$taxa)
    )
  }
}
