# detection_history_checks.R

#' Validate detection history alignment with effort
#'
#' @param detection_history Tibble with columns `detected` and `effort`.
#' @return TRUE invisibly if alignment checks pass.
#' @export
validate_det_hist_alignment <- function(detection_history) {
  if (!all(c("detected", "effort") %in% names(detection_history))) {
    stop("Detection history must include 'detected' and 'effort' columns.")
  }

  bad_effort <- !is.na(detection_history$effort) & !(detection_history$effort %in% c(0, 1))
  if (any(bad_effort)) {
    stop("Detection history effort values must be 0/1.")
  }

  bad_detected <- !is.na(detection_history$detected) & !(detection_history$detected %in% c(0, 1))
  if (any(bad_detected)) {
    stop("Detection history detected values must be 0/1.")
  }

  if (any(detection_history$detected == 1 & detection_history$effort == 0, na.rm = TRUE)) {
    stop("Detection history alignment failed: detections occur during zero effort.")
  }

  invisible(TRUE)
}
