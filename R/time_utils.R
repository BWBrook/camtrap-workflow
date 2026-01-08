# time_utils.R

#' Resolve timezone string for parsing
#'
#' @param tz Olson timezone string.
#' @param fixed_offset_hours Optional fixed offset in hours (e.g., 10 for UTC+10).
#' @return Timezone string used for parsing.
#' @export
resolve_timezone <- function(tz, fixed_offset_hours = NULL) {
  if (!is.null(fixed_offset_hours) && !is.na(fixed_offset_hours)) {
    if (!is.numeric(fixed_offset_hours) || length(fixed_offset_hours) != 1) {
      stop("fixed_offset_hours must be a single numeric value.")
    }
    sign <- ifelse(fixed_offset_hours >= 0, "-", "+")
    return(paste0("Etc/GMT", sign, abs(fixed_offset_hours)))
  }

  tz
}

#' Parse local datetimes using optional fixed offset
#'
#' @param datetime Character vector of datetimes (DD/MM/YYYY hh:mm:ss).
#' @param tz Olson timezone string.
#' @param fixed_offset_hours Optional fixed offset in hours (e.g., 10 for UTC+10).
#' @param quiet Logical passed to lubridate::dmy_hms.
#' @return POSIXct vector.
#' @export
parse_datetime_local <- function(datetime, tz, fixed_offset_hours = NULL, quiet = TRUE) {
  import::from("lubridate", dmy_hms)
  tz_use <- resolve_timezone(tz, fixed_offset_hours)
  dmy_hms(datetime, tz = tz_use, quiet = quiet)
}

#' Convert dates to datetimes using optional fixed offset
#'
#' @param date Date vector.
#' @param tz Olson timezone string.
#' @param fixed_offset_hours Optional fixed offset in hours.
#' @return POSIXct vector.
#' @export
parse_date_local <- function(date, tz, fixed_offset_hours = NULL) {
  import::from("lubridate", as_datetime)
  tz_use <- resolve_timezone(tz, fixed_offset_hours)
  as_datetime(date, tz = tz_use)
}
