# Current invocation identity.

is_safe_run_id <- function(run_id) {
  is.character(run_id) &&
    length(run_id) == 1L &&
    !is.na(run_id) &&
    nchar(run_id, type = "bytes") <= 128L &&
    grepl("^[A-Za-z0-9][A-Za-z0-9._-]*$", run_id) &&
    !run_id %in% c(".", "..") &&
    !grepl("\\.\\.", run_id, fixed = TRUE)
}

assert_safe_run_id <- function(run_id) {
  if (!is_safe_run_id(run_id)) {
    stop("Unsafe evidence run ID: ", run_id)
  }
  invisible(run_id)
}

default_run_token <- function() {
  token <- gsub("-", "", uuid::UUIDgenerate(use.time = FALSE), fixed = TRUE)
  substr(tolower(token), 1L, 16L)
}

allocate_run_id <- function(clock = Sys.time, token = default_run_token) {
  now <- clock()
  if (!inherits(now, "POSIXt") || length(now) != 1L || is.na(now)) {
    stop("Run ID clock must return one valid POSIXt value.")
  }

  suffix <- tolower(token())
  if (!grepl("^[a-f0-9]{16}$", suffix)) {
    stop("Run ID token must contain exactly 16 lowercase hexadecimal characters.")
  }

  run_id <- paste0(format(now, "%Y%m%dT%H%M%SZ", tz = "UTC"), "-", suffix)
  assert_safe_run_id(run_id)
  run_id
}
