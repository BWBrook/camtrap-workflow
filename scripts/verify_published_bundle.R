#!/usr/bin/env Rscript

canonicalize_independent <- function(value) {
  if (is.data.frame(value)) value <- lapply(value, canonicalize_independent)
  if (is.list(value)) {
    if (!is.null(names(value))) {
      value <- value[order(names(value), method = "radix")]
    }
    return(lapply(value, canonicalize_independent))
  }
  if (!is.null(names(value))) {
    value <- value[order(names(value), method = "radix")]
  }
  value
}

canonical_json_independent <- function(value) {
  jsonlite::toJSON(
    canonicalize_independent(value),
    auto_unbox = TRUE,
    null = "null",
    na = "null",
    digits = NA
  )
}

sha256_file_independent <- function(path) {
  unname(digest::digest(file = path, algo = "sha256", serialize = FALSE))
}

sha256_text_independent <- function(value) {
  digest::digest(
    charToRaw(enc2utf8(value)),
    algo = "sha256",
    serialize = FALSE
  )
}

safe_relative_independent <- function(path) {
  is.character(path) && length(path) == 1L && !is.na(path) && nzchar(path) &&
    !grepl("^/|(^|/)\\.\\.(/|$)|//", path)
}

bundle_file_independent <- function(root, relative) {
  if (!safe_relative_independent(relative)) stop("Unsafe bundle path: ", relative)
  path <- file.path(root, relative)
  root_real <- normalizePath(root, winslash = "/", mustWork = TRUE)
  path_real <- normalizePath(path, winslash = "/", mustWork = TRUE)
  if (!startsWith(path_real, paste0(root_real, "/")) ||
        isTRUE(file.info(path_real)$isdir) || nzchar(Sys.readlink(path))) {
    stop("Bundle path is not one contained regular file: ", relative)
  }
  path_real
}

independent_jaccard <- function(presence, ids) {
  rows <- vector("list", length(ids)^2)
  index <- 0L
  for (first in seq_along(ids)) {
    for (second in seq_along(ids)) {
      left <- presence[first, ] == 1L
      right <- presence[second, ] == 1L
      union_count <- sum(left | right)
      index <- index + 1L
      rows[[index]] <- data.frame(
        analysis_unit_id_1 = ids[[first]],
        analysis_unit_id_2 = ids[[second]],
        jaccard_dissimilarity = if (union_count == 0L) {
          NA_real_
        } else {
          1 - sum(left & right) / union_count
        },
        stringsAsFactors = FALSE
      )
    }
  }
  do.call(rbind, rows)
}

compare_jaccard <- function(observed, expected, label) {
  keys <- c("analysis_unit_id_1", "analysis_unit_id_2")
  observed <- observed[do.call(order, observed[keys]), c(keys, "jaccard_dissimilarity")]
  expected <- expected[do.call(order, expected[keys]), c(keys, "jaccard_dissimilarity")]
  rownames(observed) <- rownames(expected) <- NULL
  if (!identical(observed[keys], expected[keys]) ||
    !isTRUE(all.equal(
      observed$jaccard_dissimilarity,
      expected$jaccard_dissimilarity,
      tolerance = 1e-12,
      check.attributes = FALSE
    ))) {
    stop(label, " Jaccard values disagree.")
  }
  invisible(TRUE)
}

validate_jaccard_semantics <- function(jaccard, presence, ids) {
  values <- jaccard$jaccard_dissimilarity
  if (any(!is.na(values) & (values < 0 | values > 1))) {
    stop("Published Jaccard values fall outside [0, 1].")
  }
  matrix <- matrix(
    values,
    nrow = length(ids),
    ncol = length(ids),
    byrow = TRUE
  )
  if (!isTRUE(all.equal(
    matrix,
    t(matrix),
    tolerance = 1e-12,
    check.attributes = FALSE
  ))) {
    stop("Published Jaccard matrix is not symmetric.")
  }
  expected_diagonal <- ifelse(rowSums(presence) == 0L, NA_real_, 0)
  if (!isTRUE(all.equal(
    diag(matrix),
    expected_diagonal,
    tolerance = 1e-12,
    check.attributes = FALSE
  ))) {
    stop("Published Jaccard diagonal does not respect empty unions.")
  }
  invisible(TRUE)
}

verify_source_inventory <- function(bundle, manifest) {
  inventory <- jsonlite::read_json(
    bundle_file_independent(bundle, manifest$source_inventory),
    simplifyVector = FALSE
  )
  if (!identical(inventory$source_inventory_schema,
                 "camtrap-source-inventory/1.0") ||
        !identical(inventory$run_id, manifest$run_id) ||
        !is.list(inventory$files)) {
    stop("Published source inventory is malformed.")
  }
  paths <- vapply(inventory$files, `[[`, character(1), "path")
  if (anyDuplicated(paths) ||
        any(!vapply(paths, safe_relative_independent, logical(1)))) {
    stop("Published source inventory paths are unsafe or duplicated.")
  }
  for (record in inventory$files) {
    path <- bundle_file_independent(bundle, record$path)
    if (as.numeric(record$bytes) != unname(as.numeric(file.info(path)$size)) ||
          !identical(record$sha256, sha256_file_independent(path))) {
      stop("Published source inventory fixity mismatch: ", record$path)
    }
  }
  stable <- lapply(inventory$files, function(record) {
    list(
      path = record$path,
      bytes = as.numeric(record$bytes),
      sha256 = record$sha256,
      role = record$role,
      consumed_by_parser = record$consumed_by_parser
    )
  })
  identity <- sha256_text_independent(canonical_json_independent(stable))
  if (!identical(identity, inventory$source_sha256) ||
        !identical(identity, manifest$fingerprints$source)) {
    stop("Published source inventory identity does not reconcile.")
  }
  inventory
}

verify_physical_source <- function(bundle, inventory, inputs) {
  site_records <- Filter(function(record) {
    grepl("^source_snapshot/four_table/site(\\.[^/]*)?$", record$path)
  }, inventory$files)
  if (length(site_records) == 0L) return(invisible(TRUE))
  if (length(site_records) != 1L) {
    stop("Published bundle has ambiguous physical-location source evidence.")
  }
  source <- utils::read.csv(
    bundle_file_independent(bundle, site_records[[1L]]$path),
    stringsAsFactors = FALSE,
    check.names = FALSE,
    na.strings = c("", "NA")
  )
  names(source) <- janitor::make_clean_names(names(source))
  if (anyDuplicated(names(source))) {
    stop("Physical-location source columns collide after normalization.")
  }
  validated <- inputs$site
  if (!"site" %in% names(source) || !all(names(source) %in% names(validated)) ||
        anyDuplicated(source$site) || anyDuplicated(validated$site) ||
        !setequal(as.character(source$site), as.character(validated$site))) {
    stop("Physical-location source and validated identities do not reconcile.")
  }
  matched <- match(as.character(source$site), as.character(validated$site))
  normalize <- function(value) {
    value <- as.character(value)
    value[is.na(value)] <- "<NA>"
    value
  }
  for (field in names(source)) {
    if (!identical(
      normalize(source[[field]]),
      normalize(validated[[field]][matched])
    )) {
      stop("Physical-location source field changed: ", field)
    }
  }
  invisible(TRUE)
}

verify_published_bundle_independent <- function( # nolint: object_length_linter.
    bundle,
    oracle = NULL) {
  bundle <- normalizePath(bundle, winslash = "/", mustWork = TRUE)
  manifest_path <- file.path(bundle, "run_manifest.json")
  manifest <- jsonlite::read_json(manifest_path, simplifyVector = FALSE)
  if (!identical(manifest$manifest_schema, "camtrap-run-bundle/2.0") ||
        !identical(manifest$status, "completed") ||
        !file.exists(file.path(bundle, "READY")) ||
        !file.exists(file.path(bundle, "COMPLETE.json"))) {
    stop("Published bundle is not a completed current-contract run.")
  }
  if (!identical(basename(bundle), manifest$run_id)) {
    stop("Published bundle identity disagrees with its directory.")
  }
  completion <- jsonlite::read_json(
    file.path(bundle, "COMPLETE.json"),
    simplifyVector = FALSE
  )
  completion_valid <- identical(
    completion$completion_schema,
    "camtrap-run-completion/2.0"
  ) && identical(completion$status, "completed") &&
    identical(completion$run_id, manifest$run_id) &&
    identical(
      completion$manifest_sha256,
      sha256_file_independent(manifest_path)
    )
  if (!completion_valid) {
    stop("Published completion record does not bind the current manifest.")
  }

  recorded_paths <- vapply(manifest$payload, `[[`, character(1), "path")
  actual <- list.files(
    bundle,
    recursive = TRUE,
    full.names = TRUE,
    all.files = TRUE,
    no.. = TRUE,
    include.dirs = FALSE
  )
  actual <- normalizePath(actual, winslash = "/", mustWork = TRUE)
  actual_relative <- substring(actual, nchar(bundle) + 2L)
  actual_relative <- sort(setdiff(
    actual_relative,
    c("run_manifest.json", "READY", "COMPLETE.json")
  ), method = "radix")
  if (anyDuplicated(recorded_paths) || !setequal(recorded_paths, actual_relative)) {
    stop(
      "Published payload inventory is incomplete or contains extras. Missing: ",
      paste(setdiff(recorded_paths, actual_relative), collapse = ", "),
      "; extras: ",
      paste(setdiff(actual_relative, recorded_paths), collapse = ", ")
    )
  }
  for (index in seq_along(manifest$payload)) {
    record <- manifest$payload[[index]]
    path <- bundle_file_independent(bundle, record$path)
    if (as.numeric(record$bytes) != unname(as.numeric(file.info(path)$size)) ||
          !identical(record$sha256, sha256_file_independent(path))) {
      stop("Published payload fixity mismatch: ", record$path)
    }
  }
  source_inventory <- verify_source_inventory(bundle, manifest)

  status <- jsonlite::read_json(
    bundle_file_independent(bundle, manifest$module_status),
    simplifyVector = FALSE
  )
  expected_modules <- c(
    "effort_coverage",
    "observed_presence",
    "observed_richness",
    "jaccard",
    "operational_event_detection_rate",
    "coarse_day_night",
    "species_accumulation",
    "point_map",
    "event_gap_sensitivity"
  )
  modules <- vapply(status$records, `[[`, character(1), "module")
  states <- vapply(status$records, `[[`, character(1), "status")
  allowed_states <- c(
    "completed", "completed_with_warnings", "omitted", "failed"
  )
  records_valid <- vapply(status$records, function(record) {
    reason_valid <- identical(record$status, "completed") ||
      (is.character(record$reason) && length(record$reason) == 1L &&
         nzchar(record$reason))
    identical(record$module_status_schema, "camtrap-module-status/2.0") &&
      record$status %in% allowed_states &&
      record$actual_resolution %in% c("physical_location", "analysis_site") &&
      length(record$required_evidence) > 0L && reason_valid
  }, logical(1))
  if (!identical(status$module_status_set_schema,
                 "camtrap-module-status-set/2.0") ||
        !identical(status$run_id, manifest$run_id) ||
        !setequal(modules, expected_modules) || anyDuplicated(modules) ||
        any(states == "failed") || !all(records_valid)) {
    stop("Published module status contains a failure or missing candidate.")
  }

  events <- utils::read.csv(bundle_file_independent(
    bundle,
    manifest$audit$events$physical_events
  ), stringsAsFactors = FALSE)
  memberships <- utils::read.csv(bundle_file_independent(
    bundle,
    manifest$audit$events$event_membership
  ), stringsAsFactors = FALSE)
  if (anyDuplicated(events$event_id) ||
        anyDuplicated(memberships$membership_id) ||
        any(!memberships$event_id %in% events$event_id)) {
    stop("Published event identities or source memberships are invalid.")
  }
  for (index in seq_len(nrow(events))) {
    rows <- memberships[memberships$event_id == events$event_id[[index]], ]
    digest <- sha256_text_independent(canonical_json_independent(sort(
      rows$source_row_id,
      method = "radix"
    )))
    if (nrow(rows) != events$source_membership_count[[index]] ||
          !identical(digest, events$source_membership_digest[[index]])) {
      stop("Published event membership does not independently reconcile.")
    }
  }

  selected <- manifest$audit$selected_resolution
  selected_membership <- utils::read.csv(bundle_file_independent(
    bundle,
    selected$membership
  ), stringsAsFactors = FALSE)
  selected_operation <- utils::read.csv(bundle_file_independent(
    bundle,
    selected$operation
  ), stringsAsFactors = FALSE)
  selected_events <- utils::read.csv(bundle_file_independent(
    bundle,
    selected$event_map
  ), stringsAsFactors = FALSE)
  if (!setequal(selected_events$event_id, events$event_id) ||
        sum(selected_events$source_membership_count) != nrow(memberships)) {
    stop("Published events are not conserved through spatial grouping.")
  }

  presence <- utils::read.csv(bundle_file_independent(
    bundle,
    manifest$outputs$community_presence
  ), stringsAsFactors = FALSE, check.names = FALSE)
  richness <- utils::read.csv(bundle_file_independent(
    bundle,
    manifest$outputs$observed_richness
  ), stringsAsFactors = FALSE)
  jaccard <- utils::read.csv(bundle_file_independent(
    bundle,
    manifest$outputs$jaccard
  ), stringsAsFactors = FALSE)
  metadata <- c(
    "analysis_unit_id", "resolution", "scheme_id", "scheme_version",
    "authority_reference", "analysis_unit_count", "temporal_scope_start",
    "temporal_scope_end", "effort_definition", "claim_limit",
    "metadata_reference"
  )
  species <- setdiff(names(presence), metadata)
  presence_matrix <- as.matrix(presence[species])
  storage.mode(presence_matrix) <- "integer"
  if (anyNA(presence_matrix) || any(!presence_matrix %in% c(0L, 1L)) ||
        !identical(as.integer(richness$observed_richness),
                   as.integer(rowSums(presence_matrix)))) {
    stop("Published presence and observed richness do not reconcile.")
  }
  expected_jaccard <- independent_jaccard(
    presence_matrix,
    presence$analysis_unit_id
  )
  compare_jaccard(jaccard, expected_jaccard, "Reconstructed")
  validate_jaccard_semantics(
    jaccard,
    presence_matrix,
    presence$analysis_unit_id
  )

  inputs <- readRDS(bundle_file_independent(
    bundle,
    manifest$audit$validation$validated_inputs
  ))
  verify_physical_source(bundle, source_inventory, inputs)
  matched <- match(selected_membership$physical_location_id, inputs$site$site)
  if (anyNA(matched) ||
    !setequal(
      as.character(selected_membership$physical_location_id),
      as.character(inputs$site$site)
    ) ||
    !isTRUE(all.equal(
      selected_membership$physical_latitude,
      as.numeric(inputs$site$lat[matched]),
      tolerance = 0,
      check.attributes = FALSE
    )) ||
    !isTRUE(all.equal(
      selected_membership$physical_longitude,
      as.numeric(inputs$site$lon[matched]),
      tolerance = 0,
      check.attributes = FALSE
    ))) {
    stop("Published physical coordinates changed during grouping.")
  }
  if (!is.null(oracle)) {
    accepted <- utils::read.csv(oracle, stringsAsFactors = FALSE)
    compare_jaccard(jaccard, accepted, "Accepted oracle")
  }

  scheme <- unique(selected_membership$scheme_id)
  if (identical(scheme, "judbury-analysis-site")) {
    oracle_sha256 <-
      "c45bb6285b58071c575a26cc9e85b556cacbcdee9f2dd0f936ae27f0d588daab"
    if (is.null(oracle) ||
          !identical(sha256_file_independent(oracle), oracle_sha256)) {
      stop("Judbury release requires the accepted Goal 010 Jaccard oracle.")
    }
    expected_counts <- c(
      physical_locations = 13L,
      analysis_units = 9L,
      operation_rows = 9639L,
      events = 11572L,
      source_memberships = 15672L
    )
    observed_counts <- c(
      physical_locations = length(unique(
        selected_membership$physical_location_id
      )),
      analysis_units = length(unique(selected_membership$analysis_unit_id)),
      operation_rows = nrow(selected_operation),
      events = nrow(events),
      source_memberships = nrow(memberships)
    )
    if (!identical(as.integer(observed_counts), as.integer(expected_counts))) {
      stop("Published Judbury foundation counts changed.")
    }
  }
  report <- bundle_file_independent(bundle, manifest$report)
  if (unname(as.numeric(file.info(report)$size)) == 0) {
    stop("Published HTML ecological report is empty.")
  }
  list(
    valid = TRUE,
    run_id = manifest$run_id,
    physical_locations = length(unique(
      selected_membership$physical_location_id
    )),
    analysis_units = length(unique(selected_membership$analysis_unit_id)),
    operation_rows = nrow(selected_operation),
    events = nrow(events),
    source_memberships = nrow(memberships),
    jaccard_pairs = nrow(jaccard),
    oracle_checked = !is.null(oracle)
  )
}

parse_verifier_args <- function(args) {
  if (length(args) == 1L) return(list(bundle = args[[1L]], oracle = NULL))
  if (length(args) == 3L && identical(args[[2L]], "--oracle")) {
    return(list(bundle = args[[1L]], oracle = args[[3L]]))
  }
  stop("Usage: verify_published_bundle.R <bundle> [--oracle <selected_jaccard.csv>]")
}

if (sys.nframe() == 0L) {
  args <- parse_verifier_args(commandArgs(trailingOnly = TRUE))
  result <- verify_published_bundle_independent(args$bundle, args$oracle)
  cat(canonical_json_independent(result), "\n")
}
