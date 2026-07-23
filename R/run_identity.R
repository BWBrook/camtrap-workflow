# Invocation identity and supported-run context.

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

safe_compatibility_label <- function(label) {
  if (!is.character(label) || length(label) != 1L || is.na(label) || !nzchar(label)) {
    return("unnamed")
  }
  cleaned <- gsub("[^A-Za-z0-9._-]+", "-", label)
  cleaned <- gsub("(^[-.]+|[-.]+$)", "", cleaned)
  if (!nzchar(cleaned) || cleaned %in% c(".", "..")) {
    cleaned <- "unnamed"
  }
  substr(cleaned, 1L, 96L)
}

read_run_context <- function(path = Sys.getenv("CAMTRAP_EVIDENCE_CONTEXT", unset = "")) {
  if (!nzchar(path)) {
    return(NULL)
  }
  if (!file.exists(path)) {
    stop("Evidence run context does not exist: ", path)
  }

  context <- jsonlite::read_json(path, simplifyVector = FALSE)
  if (!identical(context$context_schema, "camtrap-evidence-context/1.0")) {
    stop("Unsupported evidence run context schema.")
  }
  assert_safe_run_id(context$run_id)
  if (!isTRUE(context$supported_full_run)) {
    stop("Evidence run context is not a supported full invocation.")
  }
  context
}

run_context_or_partial <- function(config) {
  context <- read_run_context()
  if (!is.null(context)) {
    return(context)
  }

  list(
    context_schema = "camtrap-evidence-context/1.0",
    supported_full_run = FALSE,
    run_id = NULL,
    legacy_run_label = config$run_id
  )
}
