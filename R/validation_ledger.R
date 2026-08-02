# Structured validation findings and Phase-2 preflight orchestration.

finding_content <- function(finding) {
  fields <- c(
    "finding_schema",
    "rule_id",
    "rule_version",
    "category",
    "severity",
    "resource_id",
    "source_row_id",
    "field",
    "scope",
    "observed_state",
    "affected_domains",
    "consequence",
    "explanation",
    "remediation"
  )
  finding[fields]
}

make_validation_finding <- function(
    rule_id,
    rule_version,
    category,
    severity,
    resource_id = NULL,
    source_row_id = NULL,
    field = NULL,
    scope,
    observed_state,
    affected_domains,
    consequence,
    explanation,
    remediation) {
  if (!category %in% c("integrity", "semantic", "advisory")) {
    stop("Unsupported validation finding category: ", category)
  }
  if (!severity %in% c("error", "warning", "info")) {
    stop("Unsupported validation finding severity: ", severity)
  }
  finding <- list(
    finding_schema = "camtrap-validation-finding/1.0",
    rule_id = rule_id,
    rule_version = rule_version,
    category = category,
    severity = severity,
    resource_id = resource_id,
    source_row_id = source_row_id,
    field = field,
    scope = scope,
    observed_state = observed_state,
    affected_domains = sort(unique(affected_domains), method = "radix"),
    consequence = consequence,
    explanation = explanation,
    remediation = remediation
  )
  finding$finding_id <- sha256_text(canonical_json(list(
    identity_schema = "camtrap-validation-finding-id/1.0",
    content = finding_content(finding)
  )))
  finding
}

validate_findings <- function(findings) {
  if (!is.list(findings)) {
    stop("Validation findings must be a list.")
  }
  if (length(findings) == 0L) {
    return(invisible(TRUE))
  }
  ids <- vapply(findings, `[[`, character(1), "finding_id")
  if (anyDuplicated(ids)) {
    stop("Duplicate validation finding identity.")
  }
  for (finding in findings) {
    affected_domains <- unlist(
      finding$affected_domains,
      use.names = FALSE
    )
    valid_schema <- identical(
      finding$finding_schema,
      "camtrap-validation-finding/1.0"
    )
    valid_state <- finding$category %in% c(
      "integrity",
      "semantic",
      "advisory"
    ) && finding$severity %in% c("error", "warning", "info")
    valid_domains <- is.character(affected_domains) &&
      length(affected_domains) >= 1L &&
      identical(
        affected_domains,
        sort(unique(affected_domains), method = "radix")
      )
    if (!valid_schema || !valid_state || !valid_domains) {
      stop("Validation finding contains an unsupported schema or state.")
    }
    expected <- sha256_text(canonical_json(list(
      identity_schema = "camtrap-validation-finding-id/1.0",
      content = finding_content(finding)
    )))
    if (!identical(finding$finding_id, expected)) {
      stop("Validation finding identity mismatch.")
    }
    if (identical(finding$category, "integrity") &&
          !identical(finding$severity, "error")) {
      stop("Integrity findings must remain error severity.")
    }
  }
  invisible(TRUE)
}

transformation_content <- function(record) {
  fields <- c(
    "transformation_schema",
    "rule_id",
    "rule_version",
    "input_resource_ids",
    "source_fields",
    "resolved_table",
    "resolved_fields",
    "meaning_preserving",
    "reversibility_basis"
  )
  record[fields]
}

make_transformation_record <- function(
    rule_id,
    rule_version,
    input_resource_ids,
    source_fields,
    resolved_table,
    resolved_fields,
    reversibility_basis) {
  record <- list(
    transformation_schema = "camtrap-transformation/1.0",
    rule_id = rule_id,
    rule_version = rule_version,
    input_resource_ids = sort(unique(input_resource_ids), method = "radix"),
    source_fields = source_fields,
    resolved_table = resolved_table,
    resolved_fields = resolved_fields,
    meaning_preserving = TRUE,
    reversibility_basis = reversibility_basis
  )
  record$transformation_id <- sha256_text(canonical_json(list(
    identity_schema = "camtrap-transformation-id/1.0",
    content = transformation_content(record)
  )))
  record
}

build_transformation_records <- function(audit, lineage, input_mode) {
  resources <- lineage$resources
  if (identical(input_mode, "four_table")) {
    records <- lapply(seq_len(nrow(resources)), function(index) {
      resource <- resources[index, ]
      make_transformation_record(
        rule_id = paste0("parser.four_table.", resource$logical_name),
        rule_version = "1.0",
        input_resource_ids = resource$resource_id,
        source_fields = character(),
        resolved_table = resource$logical_name,
        resolved_fields = names(audit$parsed_tables[[resource$logical_name]]),
        reversibility_basis = paste(
          "Immutable CSV source bytes and one-based parser order are preserved;",
          "no semantic value is filled or replaced."
        )
      )
    })
  } else {
    records <- lapply(audit$transformations, function(transformation) {
      resource_names <- intersect(
        transformation$input_resources,
        resources$logical_name
      )
      resource_ids <- resources$resource_id[
        match(resource_names, resources$logical_name)
      ]
      if (length(resource_ids) == 0L) {
        stop("Adapter transformation has no parser-resource identity.")
      }
      if (!isTRUE(transformation$meaning_preserving)) {
        stop("Lossy or semantic adapter mapping cannot be transformation-only.")
      }
      make_transformation_record(
        rule_id = transformation$rule_id,
        rule_version = transformation$rule_version,
        input_resource_ids = resource_ids,
        source_fields = transformation$source_fields,
        resolved_table = transformation$resolved_table,
        resolved_fields = transformation$resolved_fields,
        reversibility_basis = transformation$reversibility_basis
      )
    })
  }
  records[order(
    vapply(records, `[[`, character(1), "transformation_id"),
    method = "radix"
  )]
}

validate_transformations <- function(transformations, lineage) {
  if (!is.list(transformations)) {
    stop("Transformation records must be a list.")
  }
  if (length(transformations) == 0L) {
    return(invisible(TRUE))
  }
  ids <- vapply(transformations, `[[`, character(1), "transformation_id")
  if (anyDuplicated(ids)) {
    stop("Duplicate transformation identity.")
  }
  for (record in transformations) {
    input_resource_ids <- unlist(
      record$input_resource_ids,
      use.names = FALSE
    )
    valid_schema <- identical(
      record$transformation_schema,
      "camtrap-transformation/1.0"
    )
    valid_resources <- is.character(input_resource_ids) &&
      length(input_resource_ids) >= 1L &&
      identical(
        input_resource_ids,
        sort(unique(input_resource_ids), method = "radix")
      )
    if (!valid_schema || !valid_resources) {
      stop("Transformation record contains an unsupported schema or input set.")
    }
    expected <- sha256_text(canonical_json(list(
      identity_schema = "camtrap-transformation-id/1.0",
      content = transformation_content(record)
    )))
    if (!identical(record$transformation_id, expected)) {
      stop("Transformation identity mismatch.")
    }
    if (!isTRUE(record$meaning_preserving)) {
      stop("Transformation-only record is not meaning-preserving.")
    }
    if (any(!input_resource_ids %in% lineage$resources$resource_id)) {
      stop("Transformation refers to an unknown logical resource.")
    }
  }
  invisible(TRUE)
}

proposal_finding <- function(proposal, decision) {
  unresolved <- !identical(decision$decision, "approved")
  consequence <- if (isTRUE(proposal$blocks_analysis) && unresolved) {
    "analysis_blocked"
  } else if (unresolved) {
    paste0("affected_domains:", paste(proposal$affected_domains, collapse = ","))
  } else {
    "approved_for_exact_application"
  }
  make_validation_finding(
    rule_id = proposal$rule_id,
    rule_version = proposal$rule_version,
    category = "semantic",
    severity = if (isTRUE(proposal$blocks_analysis) && unresolved) {
      "error"
    } else {
      "warning"
    },
    resource_id = proposal$resource_id,
    source_row_id = proposal$source_row_id,
    field = proposal$field,
    scope = paste0(proposal$table, ":", proposal$record_ordinal),
    observed_state = proposal$original_state,
    affected_domains = proposal$affected_domains,
    consequence = consequence,
    explanation = proposal$rationale,
    remediation = paste(
      "Review this exact proposal and record an approved or declined decision;",
      "no broad repair authority is accepted."
    )
  )
}

error_finding <- function(rule_id, explanation, remediation, scope = "dataset") {
  make_validation_finding(
    rule_id = rule_id,
    rule_version = "1.0",
    category = "integrity",
    severity = "error",
    scope = scope,
    observed_state = list(error = explanation),
    affected_domains = "all_analysis",
    consequence = "analysis_blocked",
    explanation = explanation,
    remediation = remediation
  )
}

validation_decisions <- function(config) {
  if (is.null(config$validation) ||
        is.null(config$validation$repair_decisions)) {
    return(list())
  }
  config$validation$repair_decisions
}

#' Prepare validation and repair evidence before analytical targets
#'
#' @param config Effective configuration.
#' @param snapshot Immutable source snapshot.
#' @param four_table_reader Reader for one four-table CSV source.
#' @param camtrapdp_reader Reader for one Camtrap DP package.
#' @param camtrapdp_adapter Adapter from Camtrap DP to internal tables.
#' @return Validation state and analysis-ready input tables.
prepare_validation_preflight <- function(
    config,
    snapshot,
    four_table_reader = NULL,
    camtrapdp_reader = NULL,
    camtrapdp_adapter = NULL) {
  loaded <- load_inputs(
    config,
    source_snapshot = snapshot,
    include_audit = TRUE,
    four_table_reader = four_table_reader,
    camtrapdp_reader = camtrapdp_reader,
    camtrapdp_adapter = camtrapdp_adapter
  )
  audit <- loaded$.audit
  inputs <- loaded[c("site", "op", "obs", "taxa")]
  lineage <- build_source_row_lineage(
    snapshot,
    audit$parsed_tables,
    input_mode = config$input_mode,
    observation_source_ordinal = audit$observation_source_ordinal,
    observation_index = inputs$obs$index
  )
  transformations <- build_transformation_records(
    audit,
    lineage,
    config$input_mode
  )
  validate_transformations(transformations, lineage)

  proposals <- c(
    build_whitespace_proposals(inputs, lineage),
    if (identical(config$input_mode, "camtrapdp")) {
      build_camtrapdp_proposals(audit, lineage)
    } else {
      list()
    }
  )
  proposals <- proposals[order(
    vapply(proposals, `[[`, character(1), "proposal_id"),
    method = "radix"
  )]

  findings <- list()
  supplied_decisions <- validation_decisions(config)
  repair_error <- NULL
  repaired <- tryCatch(
    apply_repair_decisions(inputs, proposals, supplied_decisions),
    error = function(error) {
      repair_error <<- conditionMessage(error)
      NULL
    }
  )
  if (is.null(repaired)) {
    findings[[length(findings) + 1L]] <- error_finding(
      "repair.authority_invalid",
      repair_error,
      paste(
        "Remove stale, broad, duplicate, conflicting, or malformed decisions",
        "and review the current proposal ledger."
      ),
      scope = "repair_decisions"
    )
    repaired <- apply_repair_decisions(inputs, proposals, list())
  }
  inputs <- repaired$inputs

  if (length(repaired$changed_fields) > 0L) {
    changed_ids <- vapply(
      repaired$changed_fields,
      `[[`,
      character(1),
      "source_row_id"
    )
    changed <- lineage$rows$source_row_id %in% changed_ids
    lineage$rows$disposition[changed] <- "transformed"
    lineage$rows$rule_id[changed] <- "repair.approved_representation/1.0"
    lineage$rows$reason[changed] <- paste(
      "An exact approved representation normalization was applied;",
      "original and applied states remain in changed-field lineage."
    )
  }

  if (length(proposals) > 0L) {
    proposal_findings <- Map(
      proposal_finding,
      proposals,
      repaired$decisions
    )
    findings <- c(findings, proposal_findings)
  }
  blocking_unresolved <- vapply(seq_along(proposals), function(index) {
    isTRUE(proposals[[index]]$blocks_analysis) &&
      !identical(repaired$decisions[[index]]$decision, "approved")
  }, logical(1))

  contract_error <- NULL
  contract_ok <- tryCatch(
    {
      validate_input_contract(
        inputs$site,
        inputs$op,
        inputs$obs,
        inputs$taxa,
        tz = config$timezone,
        fixed_offset_hours = config$timezone_fixed_offset_hours
      )
      TRUE
    },
    error = function(error) {
      contract_error <<- conditionMessage(error)
      FALSE
    }
  )
  if (!contract_ok) {
    if (any(blocking_unresolved)) {
      findings[[length(findings) + 1L]] <- make_validation_finding(
        rule_id = "semantic.current_contract_unmet",
        rule_version = "1.0",
        category = "semantic",
        severity = "error",
        scope = "input_contract",
        observed_state = list(error = contract_error),
        affected_domains = "all_analysis",
        consequence = "analysis_blocked",
        explanation = paste(
          "Unchanged source-derived values do not satisfy the current",
          "scientific input contract."
        ),
        remediation = paste(
          "Review the exact proposal or correct the immutable source;",
          "selective module execution is not implemented in Goal 006."
        )
      )
    } else {
      findings[[length(findings) + 1L]] <- error_finding(
        "input.contract_invalid",
        contract_error,
        "Correct the source contract without silent row deletion or ambiguous mapping.",
        scope = "input_contract"
      )
    }
  }

  findings <- findings[order(
    vapply(findings, `[[`, character(1), "finding_id"),
    method = "radix"
  )]
  validate_findings(findings)
  validate_source_row_lineage(lineage, snapshot)
  integrity_failures <- sum(vapply(
    findings,
    function(finding) identical(finding$category, "integrity"),
    logical(1)
  ))
  can_analyze <- contract_ok &&
    !any(blocking_unresolved) &&
    integrity_failures == 0L

  post_state <- if (can_analyze) "passed" else "blocked"
  if (length(repaired$applications) > 0L) {
    for (index in seq_along(repaired$applications)) {
      repaired$applications[[index]]$post_validation_state <- post_state
    }
  }
  if (length(repaired$changed_fields) > 0L) {
    for (index in seq_along(repaired$changed_fields)) {
      repaired$changed_fields[[index]]$post_validation_state <- post_state
    }
  }
  post_validation <- list(
    post_validation_schema = "camtrap-post-validation/1.0",
    can_analyze = can_analyze,
    integrity_failures = as.integer(integrity_failures),
    semantic_findings = as.integer(sum(vapply(
      findings,
      function(finding) identical(finding$category, "semantic"),
      logical(1)
    ))),
    unresolved_blocking_proposals = as.integer(sum(blocking_unresolved)),
    resource_count = as.integer(nrow(lineage$resources)),
    source_row_count = as.integer(nrow(lineage$rows)),
    proposal_count = as.integer(length(proposals)),
    applied_repair_count = as.integer(sum(vapply(
      repaired$applications,
      function(application) identical(application$status, "applied"),
      logical(1)
    ))),
    changed_field_count = as.integer(length(repaired$changed_fields))
  )

  list(
    validation_state_schema = "camtrap-validation-state/1.0",
    can_analyze = can_analyze,
    inputs = inputs,
    parser_audit = audit,
    lineage = lineage,
    findings = findings,
    transformations = transformations,
    proposals = proposals,
    decisions = repaired$decisions,
    applications = repaired$applications,
    changed_fields = repaired$changed_fields,
    post_validation = post_validation
  )
}

data_frame_records <- function(value) {
  if (!is.data.frame(value) || nrow(value) == 0L) {
    return(list())
  }
  lapply(seq_len(nrow(value)), function(index) {
    as.list(value[index, , drop = FALSE])
  })
}

write_atomic_rds <- function(value, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  if (file.exists(path)) {
    stop("Refusing to overwrite existing RDS file: ", path)
  }
  temporary <- tempfile(
    pattern = paste0(".", basename(path), "."),
    tmpdir = dirname(path)
  )
  on.exit(unlink(temporary, force = TRUE), add = TRUE)
  saveRDS(value, temporary)
  if (!file.rename(temporary, path)) {
    stop("Atomic RDS publication failed: ", path)
  }
  invisible(path)
}

source_row_ledger_document <- function(lineage, disposition_scope) {
  list(
    source_row_ledger_schema = "camtrap-source-row-ledger/1.0",
    disposition_scope = disposition_scope,
    records = data_frame_records(lineage$rows),
    observation_map = data_frame_records(lineage$observation_map)
  )
}

validation_artifact_documents <- function(state) {
  list(
    resource_registry = list(
      resource_registry_schema = "camtrap-resource-registry/1.0",
      records = data_frame_records(state$lineage$resources)
    ),
    source_row_ledger = source_row_ledger_document(
      state$lineage,
      "validation"
    ),
    validation_findings = list(
      validation_findings_schema = "camtrap-validation-findings/1.0",
      records = state$findings
    ),
    transformations = list(
      transformations_schema = "camtrap-transformations/1.0",
      records = state$transformations
    ),
    repair_proposals = list(
      repair_proposals_schema = "camtrap-repair-proposals/1.0",
      records = state$proposals
    ),
    repair_decisions = list(
      repair_decisions_schema = "camtrap-repair-decisions/1.0",
      records = state$decisions
    ),
    repair_applications = list(
      repair_applications_schema = "camtrap-repair-applications/1.0",
      records = state$applications
    ),
    changed_fields = list(
      changed_fields_schema = "camtrap-changed-fields/1.0",
      records = state$changed_fields
    ),
    post_validation = state$post_validation
  )
}

write_validation_artifacts <- function(state, root) {
  phase2 <- file.path(root, "provenance", "phase2")
  paths <- list(
    resource_registry = file.path(phase2, "resource_registry.json"),
    source_row_ledger = file.path(phase2, "source_row_ledger.json"),
    validation_findings = file.path(phase2, "validation_findings.json"),
    transformations = file.path(phase2, "transformations.json"),
    repair_proposals = file.path(phase2, "repair_proposals.json"),
    repair_decisions = file.path(phase2, "repair_decisions.json"),
    repair_applications = file.path(phase2, "repair_applications.json"),
    changed_fields = file.path(phase2, "changed_fields.json"),
    post_validation = file.path(phase2, "post_validation.json"),
    validated_inputs = file.path(phase2, "validated_inputs.rds")
  )
  documents <- validation_artifact_documents(state)
  for (name in names(documents)) {
    atomic_write_json(documents[[name]], paths[[name]])
  }
  write_atomic_rds(state$inputs, paths$validated_inputs)
  paths
}
