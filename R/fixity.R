# SHA-256 and path-safety primitives for evidence bundles.

sha256_file <- function(path) {
  if (!file.exists(path) || isTRUE(file.info(path)$isdir)) {
    stop("Cannot hash missing or non-file path: ", path)
  }

  unname(digest::digest(file = path, algo = "sha256", serialize = FALSE))
}

sha256_text <- function(text) {
  digest::digest(
    charToRaw(enc2utf8(paste0(text, collapse = ""))),
    algo = "sha256",
    serialize = FALSE
  )
}

normalize_relative_path <- function(path) {
  path <- gsub("\\\\", "/", path)
  path <- sub("^\\./", "", path)
  path
}

is_safe_relative_path <- function(path) {
  if (!is.character(path) || length(path) != 1L || is.na(path) || !nzchar(path)) {
    return(FALSE)
  }

  path <- normalize_relative_path(path)
  !fs::is_absolute_path(path) &&
    !grepl("(^|/)\\.\\.(/|$)", path) &&
    !grepl("^/", path) &&
    !grepl("//", path) &&
    !path %in% c(".", "..")
}

assert_safe_relative_path <- function(path, label = "path") {
  if (!is_safe_relative_path(path)) {
    stop(label, " is not a safe relative path: ", path)
  }
  invisible(path)
}

path_has_symlink <- function(path, root) {
  root_absolute <- if (fs::is_absolute_path(root)) root else file.path(getwd(), root)
  path_absolute <- if (fs::is_absolute_path(path)) path else file.path(getwd(), path)
  rel <- normalize_relative_path(fs::path_rel(path_absolute, start = root_absolute))
  assert_safe_relative_path(rel)

  current <- root_absolute
  for (part in strsplit(rel, "/", fixed = TRUE)[[1]]) {
    current <- file.path(current, part)
    link <- Sys.readlink(current)
    if (length(link) == 1L && !is.na(link) && nzchar(link)) {
      return(TRUE)
    }
  }
  FALSE
}

assert_path_within_root <- function(path, root, label = "path") {
  if (!file.exists(root)) {
    stop("Root does not exist: ", root)
  }
  if (!file.exists(path)) {
    stop(label, " does not exist: ", path)
  }

  if (path_has_symlink(path, root)) {
    stop(label, " contains a symlink: ", path)
  }

  root_real <- normalizePath(root, winslash = "/", mustWork = TRUE)
  path_real <- normalizePath(path, winslash = "/", mustWork = TRUE)
  prefix <- paste0(root_real, "/")
  if (!identical(path_real, root_real) && !startsWith(path_real, prefix)) {
    stop(label, " escapes its root: ", path)
  }
  invisible(path_real)
}

file_fixity_record <- function(path, root, role = NULL, consumed = NULL) {
  assert_path_within_root(path, root)
  info <- file.info(path)
  if (isTRUE(info$isdir)) {
    stop("Fixity inventory accepts files only: ", path)
  }

  rel <- normalize_relative_path(fs::path_rel(path, start = root))
  assert_safe_relative_path(rel)
  record <- list(
    path = rel,
    bytes = unname(as.numeric(info$size)),
    sha256 = sha256_file(path),
    mtime_utc = format(info$mtime, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  )
  if (!is.null(role)) {
    record$role <- role
  }
  if (!is.null(consumed)) {
    record$consumed_by_parser <- isTRUE(consumed)
  }
  record
}

list_regular_files <- function(root, exclude = character()) {
  if (!dir.exists(root)) {
    stop("Directory does not exist: ", root)
  }

  paths <- list.files(
    root,
    recursive = TRUE,
    full.names = TRUE,
    all.files = TRUE,
    no.. = TRUE,
    include.dirs = FALSE
  )
  paths <- paths[file.exists(paths) & !file.info(paths)$isdir]
  if (length(paths) == 0L) {
    return(character())
  }

  rel <- normalize_relative_path(fs::path_rel(paths, start = root))
  keep <- !rel %in% normalize_relative_path(exclude)
  paths <- paths[keep]
  rel <- rel[keep]
  paths[order(rel, method = "radix")]
}

inventory_files <- function(root, exclude = character()) {
  paths <- list_regular_files(root, exclude = exclude)
  lapply(paths, file_fixity_record, root = root)
}

fixity_identity <- function(records) {
  stable <- lapply(records, function(record) {
    list(
      path = record$path,
      bytes = as.numeric(record$bytes),
      sha256 = record$sha256,
      role = record$role,
      consumed_by_parser = record$consumed_by_parser
    )
  })
  sha256_text(canonical_json(stable))
}

atomic_write_json <- function(value, path, pretty = TRUE) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  if (file.exists(path)) {
    stop("Refusing to overwrite existing JSON file: ", path)
  }

  tmp <- tempfile(pattern = paste0(".", basename(path), "."), tmpdir = dirname(path))
  on.exit(unlink(tmp, force = TRUE), add = TRUE)
  jsonlite::write_json(
    value,
    tmp,
    pretty = pretty,
    auto_unbox = TRUE,
    null = "null",
    na = "null",
    digits = NA
  )
  if (!file.rename(tmp, path)) {
    stop("Atomic JSON publication failed: ", path)
  }
  invisible(path)
}

atomic_replace_text <- function(text, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  if (dir.exists(path)) {
    stop("Refusing to replace a directory with a pointer: ", path)
  }
  link <- Sys.readlink(path)
  if (length(link) == 1L && !is.na(link) && nzchar(link)) {
    stop("Refusing to replace a symlink: ", path)
  }

  tmp <- tempfile(pattern = paste0(".", basename(path), "."), tmpdir = dirname(path))
  on.exit(unlink(tmp, force = TRUE), add = TRUE)
  writeLines(text, tmp, useBytes = TRUE)
  if (!file.rename(tmp, path)) {
    stop("Atomic pointer replacement failed: ", path)
  }
  invisible(path)
}
