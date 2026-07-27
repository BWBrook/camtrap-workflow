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
#' @param four_table_reader Reader for one legacy CSV table.
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

  event_result <- NULL
  if (contract_ok && !any(blocking_unresolved)) {
    event_error <- NULL
    event_result <- tryCatch(
      build_event_lineage(
        inputs$obs,
        inputs$op,
        lineage,
        threshold = config$event_threshold_minutes,
        tz = config$timezone,
        fixed_offset_hours = config$timezone_fixed_offset_hours
      ),
      error = function(error) {
        event_error <<- conditionMessage(error)
        NULL
      }
    )
    if (is.null(event_result)) {
      findings[[length(findings) + 1L]] <- error_finding(
        "event.lineage_invalid",
        event_error,
        "Resolve row, effort, time, or event membership integrity before analysis.",
        scope = "operational_events"
      )
    } else {
      lineage <- event_result$lineage
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
    integrity_failures == 0L &&
    !is.null(event_result)

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
    changed_field_count = as.integer(length(repaired$changed_fields)),
    event_count = if (is.null(event_result)) 0L else as.integer(nrow(event_result$events)),
    event_membership_count = if (is.null(event_result)) {
      0L
    } else {
      as.integer(nrow(event_result$memberships))
    }
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
    event_lineage = event_result,
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

validation_artifact_documents <- function(state) {
  event <- state$event_lineage
  list(
    resource_registry = list(
      resource_registry_schema = "camtrap-resource-registry/1.0",
      records = data_frame_records(state$lineage$resources)
    ),
    source_row_ledger = list(
      source_row_ledger_schema = "camtrap-source-row-ledger/1.0",
      records = data_frame_records(state$lineage$rows),
      observation_map = data_frame_records(state$lineage$observation_map)
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
    event_membership = list(
      event_membership_schema = "camtrap-event-membership-ledger/1.0",
      event_rule = if (is.null(event)) NULL else event$event_rule,
      events = if (is.null(event)) {
        list()
      } else {
        data_frame_records(event$events)
      },
      records = if (is.null(event)) {
        list()
      } else {
        data_frame_records(event$memberships)
      }
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
    event_membership = file.path(phase2, "event_membership.json"),
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

json_records_frame <- function(records, columns) {
  if (is.null(records) || length(records) == 0L) {
    result <- as.data.frame(
      stats::setNames(rep(list(character()), length(columns)), columns),
      stringsAsFactors = FALSE
    )
    return(result[FALSE, , drop = FALSE])
  }
  result <- do.call(rbind, lapply(records, function(record) {
    values <- record[columns]
    as.data.frame(values, stringsAsFactors = FALSE)
  }))
  rownames(result) <- NULL
  result
}

validate_repair_artifacts <- function(
    proposals,
    decisions,
    applications,
    changed_fields) {
  validate_repair_proposals(proposals)
  proposal_ids <- vapply(proposals, `[[`, character(1), "proposal_id")
  if (length(decisions) != length(proposals) ||
        length(applications) != length(proposals)) {
    stop("Repair ledgers do not reconcile one-to-one.")
  }
  decision_ids <- vapply(decisions, `[[`, character(1), "decision_id")
  application_ids <- vapply(
    applications,
    `[[`,
    character(1),
    "application_id"
  )
  if (anyDuplicated(decision_ids) || anyDuplicated(application_ids)) {
    stop("Repair ledgers contain duplicate identities.")
  }

  states_equal <- function(left, right) {
    identical(canonical_json(left), canonical_json(right))
  }
  for (index in seq_along(proposals)) {
    proposal <- proposals[[index]]
    decision <- decisions[[index]]
    application <- applications[[index]]
    valid_decision_schema <- identical(
      decision$decision_schema,
      "camtrap-repair-decision/1.0"
    )
    valid_application_schema <- identical(
      application$application_schema,
      "camtrap-repair-application/1.0"
    )
    if (!valid_decision_schema || !valid_application_schema) {
      stop("Unsupported repair decision or application schema.")
    }
    if (!decision$decision %in% c("approved", "declined", "unresolved")) {
      stop("Invalid repair decision state.")
    }
    if (!identical(decision$proposal_id, proposal$proposal_id) ||
          !identical(decision$proposal_digest, proposal$proposal_digest) ||
          !identical(application$proposal_id, proposal$proposal_id) ||
          !identical(application$decision_id, decision$decision_id)) {
      stop("Repair proposal, decision, and application links disagree.")
    }
    expected_decision_id <- repair_decision_id(
      proposal$proposal_id,
      proposal$proposal_digest,
      decision$decision,
      decision$reason
    )
    if (!identical(decision$decision_id, expected_decision_id)) {
      stop("Repair decision identity mismatch.")
    }
    applied <- identical(application$status, "applied")
    approved <- identical(decision$decision, "approved")
    if (!application$status %in% c("applied", "not_applied") ||
          !identical(applied, approved)) {
      stop("Repair application does not exactly follow its decision.")
    }
    if (approved && !isTRUE(proposal$applicable)) {
      stop("Repair application authorizes a non-applicable proposal.")
    }
    protected_override <- approved &&
      identical(proposal$repair_class, "override_explicit")
    valid_override_reason <- is.character(decision$reason) &&
      length(decision$reason) == 1L &&
      nzchar(trimws(decision$reason))
    if (protected_override && !valid_override_reason) {
      stop("Explicit-evidence override lacks a proposal-specific reason.")
    }
    expected_reason <- if (applied) "exact_approval" else decision$decision
    expected_after <- if (applied) {
      proposal$proposed_state
    } else {
      proposal$original_state
    }
    if (!identical(application$reason, expected_reason) ||
          !states_equal(application$before_state, proposal$original_state) ||
          !states_equal(application$after_state, expected_after) ||
          !application$post_validation_state %in% c("passed", "blocked")) {
      stop("Repair application state is internally inconsistent.")
    }
    expected_application <- repair_application_id(
      proposal,
      decision,
      application$status,
      application$reason
    )
    if (!identical(application$application_id, expected_application)) {
      stop("Repair application identity mismatch.")
    }
  }

  changed_ids <- vapply(
    changed_fields,
    `[[`,
    character(1),
    "changed_field_id"
  )
  if (anyDuplicated(changed_ids)) {
    stop("Duplicate changed-field lineage identity.")
  }
  applied_count <- sum(vapply(
    applications,
    function(application) identical(application$status, "applied"),
    logical(1)
  ))
  if (length(changed_fields) != applied_count) {
    stop("Changed-field lineage does not reconcile to applied repairs.")
  }
  for (record in changed_fields) {
    valid_schema <- identical(
      record$changed_field_schema,
      "camtrap-changed-field/1.0"
    )
    valid_links <- record$proposal_id %in% proposal_ids &&
      record$decision_id %in% decision_ids
    if (!valid_schema || !valid_links) {
      stop("Orphan or unsupported changed-field lineage link.")
    }
    proposal_index <- match(record$proposal_id, proposal_ids)
    proposal <- proposals[[proposal_index]]
    decision <- decisions[[proposal_index]]
    application <- applications[[proposal_index]]
    expected_id <- changed_field_identity(
      proposal$proposal_id,
      decision$decision_id,
      proposal$source_row_id,
      proposal$field
    )
    valid_identity <- identical(record$decision_id, decision$decision_id) &&
      identical(record$changed_field_id, expected_id) &&
      identical(record$resource_id, proposal$resource_id) &&
      identical(record$source_row_id, proposal$source_row_id) &&
      identical(record$field, proposal$field)
    valid_states <- states_equal(
      record$original_state,
      proposal$original_state
    ) && states_equal(
      record$proposed_state,
      proposal$proposed_state
    ) && states_equal(
      record$applied_state,
      proposal$proposed_state
    )
    valid_post_state <- identical(
      record$post_validation_state,
      application$post_validation_state
    )
    if (!identical(application$status, "applied") ||
          !valid_identity ||
          !valid_states ||
          !valid_post_state) {
      stop("Changed-field lineage content is internally inconsistent.")
    }
  }
  invisible(TRUE)
}

portable_validation_snapshot <- function(root, config) {
  source_path <- file.path(root, "provenance", "source_inventory.json")
  if (!file.exists(source_path)) {
    stop("Portable validation reconstruction has no source inventory.")
  }
  source <- jsonlite::read_json(source_path, simplifyVector = FALSE)
  inventory <- source$files
  inventory_paths <- vapply(inventory, `[[`, character(1), "path")
  schema <- which(vapply(
    inventory,
    function(record) identical(record$role, "schema"),
    logical(1)
  ))
  if (length(schema) != 1L) {
    stop("Portable validation reconstruction requires one schema resource.")
  }

  input_mode <- config$input_mode
  parser_paths <- if (identical(input_mode, "camtrapdp")) {
    descriptor <- source$acquisition$descriptor
    if (!is.character(descriptor) || length(descriptor) != 1L) {
      stop("Portable CamtrapDP reconstruction has no descriptor link.")
    }
    assert_safe_relative_path(descriptor, "CamtrapDP descriptor path")
    list(camtrapdp = file.path(root, descriptor))
  } else {
    paths <- lapply(c("site", "op", "obs", "taxa"), function(name) {
      pattern <- paste0(
        "^source_snapshot/four_table/",
        name,
        "(\\.[^/]*)?$"
      )
      matches <- grep(pattern, inventory_paths)
      if (length(matches) != 1L) {
        stop(
          "Portable four-table reconstruction cannot resolve resource: ",
          name
        )
      }
      file.path(root, inventory_paths[[matches]])
    })
    stats::setNames(paths, c("site", "op", "obs", "taxa"))
  }
  parser_paths$schema_version <- file.path(
    root,
    inventory_paths[[schema]]
  )
  parser_inventory <- inventory[vapply(
    inventory,
    function(record) isTRUE(record$consumed_by_parser),
    logical(1)
  )]
  parser_files <- vapply(parser_inventory, function(record) {
    file.path(root, record$path)
  }, character(1))
  entity <- which(vapply(
    inventory,
    function(record) identical(record$role, "entity_resolution_input"),
    logical(1)
  ))
  if (length(entity) > 1L) {
    stop("Portable validation reconstruction has multiple entity sidecars.")
  }
  service <- which(vapply(
    inventory,
    function(record) identical(record$role, "deployment_service_input"),
    logical(1)
  ))
  ledger <- which(vapply(
    inventory,
    function(record) identical(record$role, "deployment_ledger_input"),
    logical(1)
  ))
  if (length(service) > 1L) {
    stop("Portable validation reconstruction has multiple deployment services.")
  }
  if (length(ledger) > 1L) {
    stop("Portable validation reconstruction has multiple deployment ledgers.")
  }

  snapshot <- list(
    parser_paths = parser_paths,
    parser_files = parser_files,
    acquisition = source$acquisition,
    inventory = inventory,
    source_sha256 = source$source_sha256,
    snapshot_root = file.path(root, "source_snapshot"),
    entity_resolution_path = if (length(entity) == 1L) {
      file.path(root, inventory_paths[[entity]])
    } else {
      NULL
    },
    deployment_evidence_paths = list(
      service = if (length(service) == 1L) {
        file.path(root, inventory_paths[[service]])
      } else {
        NULL
      },
      ledger = if (length(ledger) == 1L) {
        file.path(root, inventory_paths[[ledger]])
      } else {
        NULL
      }
    )
  )
  if (exists("validate_entity_source", mode = "function")) {
    selection <- entity_resolution_selection(config, require_explicit = FALSE)
    validate_entity_source(config, snapshot, selection)
  }
  if (exists("validate_deployment_evidence_source", mode = "function")) {
    deployment_selection <- deployment_evidence_selection(
      config,
      require_explicit = FALSE
    )
    validate_deployment_evidence_source(
      config,
      snapshot,
      deployment_selection
    )
  }
  snapshot
}

analytical_column_content <- function(column) {
  if (inherits(column, "POSIXt")) {
    values <- unname(as.numeric(column))
  } else if (inherits(column, "Date")) {
    values <- unname(as.numeric(column))
  } else if (is.factor(column)) {
    values <- unname(as.character(column))
  } else if (is.atomic(column)) {
    values <- unname(column)
  } else {
    stop("Validated analytical inputs contain an unsupported column type.")
  }
  list(
    class = unname(class(column)),
    type = typeof(column),
    levels = if (is.factor(column)) unname(levels(column)) else NULL,
    timezone = if (inherits(column, "POSIXt")) {
      unname(attr(column, "tzone"))
    } else {
      NULL
    },
    values = values
  )
}

analytical_inputs_fingerprint <- function(inputs) {
  if (!is.list(inputs) ||
        !identical(names(inputs), c("site", "op", "obs", "taxa"))) {
    stop("Validated analytical inputs have an invalid table set.")
  }
  content <- lapply(names(inputs), function(table_name) {
    table <- inputs[[table_name]]
    if (!is.data.frame(table)) {
      stop("Validated analytical input is not tabular: ", table_name)
    }
    list(
      table = table_name,
      rows = nrow(table),
      columns = lapply(names(table), function(field) {
        c(
          list(field = field),
          analytical_column_content(table[[field]])
        )
      })
    )
  })
  sha256_text(canonical_json(content))
}

reconstruct_validation_state <- function(root) {
  config_path <- file.path(root, "provenance", "config.raw.yml")
  if (!file.exists(config_path)) {
    stop("Portable validation reconstruction has no raw configuration.")
  }
  config <- read_config(config_path, attach_runtime = FALSE)
  snapshot <- portable_validation_snapshot(root, config)
  prepare_validation_preflight(
    config,
    snapshot,
    camtrapdp_reader = read_camtrapdp_dataset,
    camtrapdp_adapter = camtrapdp_to_internal
  )
}

validate_validation_artifacts <- function(
    root,
    paths,
    require_analysis_ready = FALSE) {
  required <- c(
    "resource_registry",
    "source_row_ledger",
    "validation_findings",
    "transformations",
    "repair_proposals",
    "repair_decisions",
    "repair_applications",
    "changed_fields",
    "event_membership",
    "post_validation",
    "validated_inputs"
  )
  if (!setequal(required, names(paths))) {
    stop("Phase-2 artifact links are incomplete.")
  }
  for (name in required) {
    assert_path_within_root(paths[[name]], root, paste("Phase-2", name))
    if (!file.exists(paths[[name]]) || nzchar(Sys.readlink(paths[[name]]))) {
      stop("Phase-2 artifact is missing or is a symlink: ", name)
    }
  }

  json_names <- setdiff(required, "validated_inputs")
  documents <- lapply(paths[json_names], function(path) {
    jsonlite::read_json(path, simplifyVector = FALSE)
  })
  schema_fields <- c(
    resource_registry = "resource_registry_schema",
    source_row_ledger = "source_row_ledger_schema",
    validation_findings = "validation_findings_schema",
    transformations = "transformations_schema",
    repair_proposals = "repair_proposals_schema",
    repair_decisions = "repair_decisions_schema",
    repair_applications = "repair_applications_schema",
    changed_fields = "changed_fields_schema",
    event_membership = "event_membership_schema",
    post_validation = "post_validation_schema"
  )
  expected_schemas <- c(
    resource_registry = "camtrap-resource-registry/1.0",
    source_row_ledger = "camtrap-source-row-ledger/1.0",
    validation_findings = "camtrap-validation-findings/1.0",
    transformations = "camtrap-transformations/1.0",
    repair_proposals = "camtrap-repair-proposals/1.0",
    repair_decisions = "camtrap-repair-decisions/1.0",
    repair_applications = "camtrap-repair-applications/1.0",
    changed_fields = "camtrap-changed-fields/1.0",
    event_membership = "camtrap-event-membership-ledger/1.0",
    post_validation = "camtrap-post-validation/1.0"
  )
  for (name in names(schema_fields)) {
    if (!identical(
      documents[[name]][[schema_fields[[name]]]],
      expected_schemas[[name]]
    )) {
      stop("Unsupported Phase-2 artifact schema: ", name)
    }
  }

  resources_json <- documents$resource_registry
  rows_json <- documents$source_row_ledger
  resources <- json_records_frame(
    resources_json$records,
    c(
      "resource_schema", "resource_id", "resource_kind", "logical_name",
      "input_mode", "content_sha256", "inventory_path",
      "parsed_record_count", "parser_version", "source_inventory_link"
    )
  )
  rows <- json_records_frame(
    rows_json$records,
    c(
      "row_schema", "source_row_id", "resource_id", "logical_name",
      "record_ordinal", "disposition", "rule_id", "reason"
    )
  )
  rows$record_ordinal <- as.integer(rows$record_ordinal)
  resources$parsed_record_count <- as.integer(resources$parsed_record_count)
  observation_map <- json_records_frame(
    rows_json$observation_map,
    c("internal_index", "record_ordinal", "source_row_id")
  )
  observation_map$record_ordinal <- as.integer(
    observation_map$record_ordinal
  )
  lineage <- list(
    lineage_schema = "camtrap-source-row-lineage/1.0",
    resources = resources,
    rows = rows,
    observation_map = observation_map
  )
  validate_source_row_lineage(lineage)

  findings <- documents$validation_findings$records
  transformations <- documents$transformations$records
  proposals <- documents$repair_proposals$records
  decisions <- documents$repair_decisions$records
  applications <- documents$repair_applications$records
  changed_fields <- documents$changed_fields$records
  validate_findings(findings)
  validate_transformations(transformations, lineage)
  validate_repair_artifacts(
    proposals,
    decisions,
    applications,
    changed_fields
  )
  for (finding in findings) {
    if (!is.null(finding$resource_id) &&
          !finding$resource_id %in% resources$resource_id) {
      stop("Validation finding refers to an unknown logical resource.")
    }
    if (!is.null(finding$source_row_id)) {
      row_index <- match(finding$source_row_id, rows$source_row_id)
      if (is.na(row_index) ||
            !is.null(finding$resource_id) &&
              !identical(rows$resource_id[[row_index]], finding$resource_id)) {
        stop("Validation finding refers to an orphan source row.")
      }
    }
  }
  for (proposal in proposals) {
    row_index <- match(proposal$source_row_id, rows$source_row_id)
    if (is.na(row_index) ||
          !identical(rows$resource_id[[row_index]], proposal$resource_id)) {
      stop("Repair proposal refers to an orphan source row.")
    }
  }

  event_json <- documents$event_membership
  events <- json_records_frame(
    event_json$events,
    c("event_schema", "event_id", "site", "species", "member_count")
  )
  events$member_count <- as.integer(events$member_count)
  memberships <- json_records_frame(
    event_json$records,
    c(
      "membership_schema", "membership_id", "event_id", "source_row_id"
    )
  )
  event_lineage <- list(
    event_lineage_schema = "camtrap-event-lineage/1.0",
    event_rule = event_json$event_rule,
    events = events,
    memberships = memberships
  )
  if (nrow(events) > 0L || nrow(memberships) > 0L) {
    validate_event_lineage(event_lineage, lineage)
  }

  post <- documents$post_validation
  integrity_count <- sum(vapply(
    findings,
    function(finding) identical(finding$category, "integrity"),
    logical(1)
  ))
  semantic_count <- sum(vapply(
    findings,
    function(finding) identical(finding$category, "semantic"),
    logical(1)
  ))
  applied_count <- sum(vapply(
    applications,
    function(application) identical(application$status, "applied"),
    logical(1)
  ))
  unresolved_blocking <- sum(vapply(seq_along(proposals), function(index) {
    isTRUE(proposals[[index]]$blocks_analysis) &&
      !identical(decisions[[index]]$decision, "approved")
  }, logical(1)))
  expected_ready <- integrity_count == 0L && unresolved_blocking == 0L
  if (!is.logical(post$can_analyze) ||
        length(post$can_analyze) != 1L ||
        !identical(post$can_analyze, expected_ready) ||
        as.integer(post$resource_count) != nrow(resources) ||
        as.integer(post$source_row_count) != nrow(rows) ||
        as.integer(post$proposal_count) != length(proposals) ||
        as.integer(post$applied_repair_count) != applied_count ||
        as.integer(post$changed_field_count) != length(changed_fields) ||
        as.integer(post$event_count) != nrow(events) ||
        as.integer(post$event_membership_count) != nrow(memberships) ||
        as.integer(post$integrity_failures) != integrity_count ||
        as.integer(post$semantic_findings) != semantic_count ||
        as.integer(post$unresolved_blocking_proposals) !=
          unresolved_blocking) {
    stop("Post-validation counts do not reconcile.")
  }
  if (isTRUE(require_analysis_ready) && !isTRUE(post$can_analyze)) {
    stop("Phase-2 validation state is not analysis-ready.")
  }
  inputs <- readRDS(paths$validated_inputs)
  if (!is.list(inputs) ||
        !identical(names(inputs), c("site", "op", "obs", "taxa")) ||
        any(vapply(inputs, function(table) ".source_row_id" %in% names(table), logical(1)))) {
    stop("Validated analytical inputs contain an invalid audit surface.")
  }
  for (index in seq_along(proposals)) {
    proposal <- proposals[[index]]
    if (!proposal$table %in% names(inputs)) {
      next
    }
    table <- inputs[[proposal$table]]
    valid_target <- is.data.frame(table) &&
      proposal$field %in% names(table) &&
      proposal$record_ordinal <= nrow(table)
    valid_value <- valid_target && value_state_matches(
      table[[proposal$field]][[proposal$record_ordinal]],
      applications[[index]]$after_state
    )
    if (!valid_target || !valid_value) {
      stop("Validated input does not match repair application state.")
    }
  }
  if (isTRUE(post$can_analyze)) {
    recomputed <- build_event_lineage(
      inputs$obs,
      inputs$op,
      lineage,
      threshold = event_json$event_rule$threshold_minutes,
      tz = event_json$event_rule$timezone,
      fixed_offset_hours = event_json$event_rule$fixed_offset_hours
    )
    events_match <- identical(
      canonical_json(data_frame_records(recomputed$events)),
      canonical_json(event_json$events)
    )
    memberships_match <- identical(
      canonical_json(data_frame_records(recomputed$memberships)),
      canonical_json(event_json$records)
    )
    dispositions_match <- identical(
      canonical_json(data_frame_records(recomputed$lineage$rows)),
      canonical_json(rows_json$records)
    )
    if (!events_match || !memberships_match || !dispositions_match) {
      stop("Recorded event lineage does not reproduce from validated inputs.")
    }
  }

  reconstructed <- reconstruct_validation_state(root)
  expected_documents <- validation_artifact_documents(reconstructed)
  for (name in names(expected_documents)) {
    actual_content <- canonical_json(documents[[name]])
    expected_content <- canonical_json(expected_documents[[name]])
    if (!identical(actual_content, expected_content)) {
      stop(
        "Phase-2 artifact does not reproduce from immutable source/config: ",
        name
      )
    }
  }
  if (!identical(
    analytical_inputs_fingerprint(inputs),
    analytical_inputs_fingerprint(reconstructed$inputs)
  )) {
    stop(
      paste(
        "Validated analytical inputs do not reproduce from immutable",
        "source/config and exact repair decisions."
      )
    )
  }
  invisible(TRUE)
}

validate_recorded_membership <- function(root, paths, obs_events) {
  validate_validation_artifacts(
    root,
    paths,
    require_analysis_ready = TRUE
  )
  rows_json <- jsonlite::read_json(
    paths$source_row_ledger,
    simplifyVector = FALSE
  )
  rows <- json_records_frame(
    rows_json$records,
    c(
      "row_schema", "source_row_id", "resource_id", "logical_name",
      "record_ordinal", "disposition", "rule_id", "reason"
    )
  )
  rows$record_ordinal <- as.integer(rows$record_ordinal)
  observation_map <- json_records_frame(
    rows_json$observation_map,
    c("internal_index", "record_ordinal", "source_row_id")
  )
  observation_map$record_ordinal <- as.integer(
    observation_map$record_ordinal
  )
  event_json <- jsonlite::read_json(
    paths$event_membership,
    simplifyVector = FALSE
  )
  events <- json_records_frame(
    event_json$events,
    c("event_schema", "event_id", "site", "species", "member_count")
  )
  events$member_count <- as.integer(events$member_count)
  memberships <- json_records_frame(
    event_json$records,
    c(
      "membership_schema", "membership_id", "event_id", "source_row_id"
    )
  )
  lineage <- list(
    rows = rows,
    observation_map = observation_map
  )
  event_lineage <- list(
    event_lineage_schema = "camtrap-event-lineage/1.0",
    event_rule = event_json$event_rule,
    events = events,
    memberships = memberships
  )
  validate_event_membership(
    event_lineage,
    obs_events,
    lineage
  )
}
