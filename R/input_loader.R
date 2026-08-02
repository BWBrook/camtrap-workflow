# input_loader.R

#' Load input tables based on config input mode
#'
#' @param config Configuration list.
#' @param source_snapshot Optional verified parser-consumed source snapshot.
#' @param include_audit Include parser-order audit tables and observation mapping.
#' @param four_table_reader Reader for one four-table CSV source.
#' @param camtrapdp_reader Reader for one Camtrap DP package.
#' @param camtrapdp_adapter Adapter from Camtrap DP to internal tables.
#' @return List with `site`, `taxa`, `op`, `obs` tibbles and optional audit data.
#' @export
load_inputs <- function(
  config,
  source_snapshot = NULL,
  include_audit = FALSE,
  four_table_reader = NULL,
  camtrapdp_reader = NULL,
  camtrapdp_adapter = NULL
) {
  paths <- config$paths$inputs
  if (!is.null(source_snapshot) && !is.null(source_snapshot$parser_paths)) {
    paths <- source_snapshot$parser_paths
  }

  mode <- if (is.null(config$input_mode)) "four_table" else config$input_mode
  if (mode == "camtrapdp") {
    if (!is.function(camtrapdp_reader) || !is.function(camtrapdp_adapter)) {
      stop("Camtrap DP reader and adapter functions must be supplied.")
    }
    dp <- camtrapdp_reader(paths$camtrapdp)
    camtrapdp_adapter(dp, tz = config$timezone, include_audit = include_audit)
  } else {
    read_four_table <- if (isTRUE(include_audit)) {
      function(path) {
        janitor::clean_names(readr::read_csv(
          path,
          show_col_types = FALSE,
          trim_ws = FALSE
        ))
      }
    } else {
      four_table_reader
    }
    if (!is.function(read_four_table)) {
      stop("Four-table reader function must be supplied.")
    }
    inputs <- list(
      site = read_four_table(paths$site),
      op = read_four_table(paths$op),
      obs = read_four_table(paths$obs),
      taxa = read_four_table(paths$taxa)
    )
    if (isTRUE(include_audit)) {
      inputs$.audit <- list(
        audit_schema = "camtrap-parser-audit/1.0",
        parsed_tables = inputs[c("site", "op", "obs", "taxa")],
        observation_source_ordinal = seq_len(nrow(inputs$obs)),
        transformations = list(),
        semantic_defaults = list()
      )
    }
    inputs
  }
}

#' Load inputs accepted by the supported preflight
#'
#' @param config Effective configuration.
#' @param source_snapshot Verified immutable source snapshot.
#' @param run_context Supported-run context or partial-run marker.
#' @param four_table_reader Reader for one four-table CSV source.
#' @param camtrapdp_reader Reader for one Camtrap DP package.
#' @param camtrapdp_adapter Adapter from Camtrap DP to internal tables.
#' @return List of audit-free analytical input tables.
load_preflight_inputs <- function(
  config,
  source_snapshot,
  run_context,
  four_table_reader = NULL,
  camtrapdp_reader = NULL,
  camtrapdp_adapter = NULL
) {
  if (!isTRUE(run_context$supported_full_run)) {
    return(load_inputs(
      config,
      source_snapshot = source_snapshot,
      four_table_reader = four_table_reader,
      camtrapdp_reader = camtrapdp_reader,
      camtrapdp_adapter = camtrapdp_adapter
    ))
  }
  if (!identical(run_context$execution_mode, "full")) {
    stop("Validation-only context cannot enter the scientific target graph.")
  }
  validation <- run_context$validation
  if (is.null(validation) ||
        !isTRUE(validation$can_analyze) ||
        is.null(validation$artifacts$validated_inputs)) {
    stop("Supported full run has no analysis-ready validation state.")
  }
  path <- validation$artifacts$validated_inputs
  assert_path_within_root(
    path,
    run_context$staging_dir,
    "Validated input snapshot"
  )
  if (!identical(sha256_file(path), validation$validated_inputs_sha256)) {
    stop("Validated input snapshot fixity mismatch.")
  }
  inputs <- readRDS(path)
  if (!is.list(inputs) ||
        !identical(names(inputs), c("site", "op", "obs", "taxa"))) {
    stop("Validated input snapshot has an invalid analytical shape.")
  }
  inputs
}
