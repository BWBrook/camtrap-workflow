# Proposal-specific repair decisions and changed-field audit records.

value_state <- function(value) {
  if (length(value) != 1L) {
    stop("Repair values must be scalar.")
  }
  missing <- is.null(value) || is.na(value)
  type <- if (is.null(value)) "NULL" else class(value)[[1]]
  normalized <- if (missing) {
    NULL
  } else if (inherits(value, "POSIXt")) {
    format(value, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  } else if (inherits(value, "Date")) {
    format(value, "%Y-%m-%d")
  } else {
    unname(value)
  }
  list(
    state_schema = "camtrap-value-state/1.0",
    missing = isTRUE(missing),
    value_type = type,
    value = normalized
  )
}

repair_proposal_content <- function(proposal) {
  fields <- c(
    "proposal_schema",
    "rule_id",
    "rule_version",
    "resource_id",
    "source_row_id",
    "table",
    "record_ordinal",
    "field",
    "original_state",
    "proposed_state",
    "repair_class",
    "algorithm_version",
    "rationale",
    "affected_domains",
    "blocks_analysis",
    "applicable",
    "fixture_only"
  )
  proposal[fields]
}

make_repair_proposal <- function(
    rule_id,
    rule_version,
    resource_id,
    source_row_id,
    table,
    record_ordinal,
    field,
    original_value,
    proposed_value,
    repair_class,
    algorithm_version,
    rationale,
    affected_domains,
    blocks_analysis,
    applicable = TRUE,
    fixture_only = FALSE) {
  if (!repair_class %in% c(
    "representation_normalization",
    "fill_unknown",
    "override_explicit"
  )) {
    stop("Unsupported repair class: ", repair_class)
  }
  for (id in c(resource_id, source_row_id)) {
    if (!is.character(id) ||
          length(id) != 1L ||
          !grepl("^[a-f0-9]{64}$", id)) {
      stop("Repair proposal resource and source-row IDs must be SHA-256 digests.")
    }
  }
  scalar_text <- list(
    rule_id = rule_id,
    rule_version = rule_version,
    table = table,
    field = field,
    algorithm_version = algorithm_version,
    rationale = rationale
  )
  if (any(vapply(
    scalar_text,
    function(value) {
      !is.character(value) || length(value) != 1L || !nzchar(value)
    },
    logical(1)
  ))) {
    stop("Repair proposal text fields must be non-empty scalar strings.")
  }
  if (!is.numeric(record_ordinal) ||
        length(record_ordinal) != 1L ||
        is.na(record_ordinal) ||
        record_ordinal < 1 ||
        record_ordinal != as.integer(record_ordinal)) {
    stop("Repair proposal record ordinal must be one positive integer.")
  }
  if (!is.character(affected_domains) || length(affected_domains) < 1L) {
    stop("Repair proposal requires at least one affected domain.")
  }

  proposal <- list(
    proposal_schema = "camtrap-repair-proposal/1.0",
    rule_id = rule_id,
    rule_version = rule_version,
    resource_id = resource_id,
    source_row_id = source_row_id,
    table = table,
    record_ordinal = as.integer(record_ordinal),
    field = field,
    original_state = value_state(original_value),
    proposed_state = value_state(proposed_value),
    repair_class = repair_class,
    algorithm_version = algorithm_version,
    rationale = rationale,
    affected_domains = sort(unique(affected_domains), method = "radix"),
    blocks_analysis = isTRUE(blocks_analysis),
    applicable = isTRUE(applicable),
    fixture_only = isTRUE(fixture_only)
  )
  proposal$proposal_digest <- sha256_text(canonical_json(
    repair_proposal_content(proposal)
  ))
  proposal$proposal_id <- sha256_text(canonical_json(list(
    identity_schema = "camtrap-repair-proposal-id/1.0",
    proposal_digest = proposal$proposal_digest
  )))
  proposal
}

validate_repair_proposals <- function(proposals) {
  if (!is.list(proposals)) {
    stop("Repair proposals must be a list.")
  }
  if (length(proposals) == 0L) {
    return(invisible(TRUE))
  }
  ids <- vapply(proposals, function(proposal) proposal$proposal_id, character(1))
  if (anyDuplicated(ids)) {
    stop("Duplicate repair proposal identity.")
  }

  for (proposal in proposals) {
    affected_domains <- unlist(
      proposal$affected_domains,
      use.names = FALSE
    )
    if (!identical(proposal$proposal_schema, "camtrap-repair-proposal/1.0")) {
      stop("Unsupported repair proposal schema.")
    }
    valid_class <- proposal$repair_class %in% c(
      "representation_normalization",
      "fill_unknown",
      "override_explicit"
    )
    flags <- c(
      proposal$blocks_analysis,
      proposal$applicable,
      proposal$fixture_only
    )
    valid_flags <- is.logical(flags) && length(flags) == 3L && !anyNA(flags)
    valid_domains <- is.character(affected_domains) &&
      length(affected_domains) >= 1L &&
      identical(
        affected_domains,
        sort(unique(affected_domains), method = "radix")
      )
    if (!valid_class || !valid_flags || !valid_domains) {
      stop("Repair proposal contains an invalid class, flag, or domain set.")
    }
    states <- list(proposal$original_state, proposal$proposed_state)
    valid_states <- !any(vapply(states, function(state) {
      !identical(state$state_schema, "camtrap-value-state/1.0") ||
        !is.logical(state$missing) ||
        length(state$missing) != 1L ||
        !is.character(state$value_type) ||
        length(state$value_type) != 1L
    }, logical(1)))
    changed_state <- !identical(
      canonical_json(proposal$original_state),
      canonical_json(proposal$proposed_state)
    )
    if (!valid_states || !changed_state) {
      stop("Repair proposal contains an invalid or unchanged value state.")
    }
    digest <- sha256_text(canonical_json(repair_proposal_content(proposal)))
    id <- sha256_text(canonical_json(list(
      identity_schema = "camtrap-repair-proposal-id/1.0",
      proposal_digest = digest
    )))
    if (!identical(digest, proposal$proposal_digest) ||
          !identical(id, proposal$proposal_id)) {
      stop("Repair proposal digest or identity mismatch.")
    }
  }
  invisible(TRUE)
}

repair_decision_id <- function(proposal_id, proposal_digest, decision, reason) {
  sha256_text(canonical_json(list(
    identity_schema = "camtrap-repair-decision-id/1.0",
    proposal_id = proposal_id,
    proposal_digest = proposal_digest,
    decision = decision,
    reason = reason
  )))
}

unresolved_repair_decision <- function(proposal) {
  reason <- NULL
  list(
    decision_schema = "camtrap-repair-decision/1.0",
    decision_id = repair_decision_id(
      proposal$proposal_id,
      proposal$proposal_digest,
      "unresolved",
      reason
    ),
    proposal_id = proposal$proposal_id,
    proposal_digest = proposal$proposal_digest,
    decision = "unresolved",
    reason = reason
  )
}

validate_decision_shape <- function(decision) {
  if (!is.list(decision)) {
    stop("Repair decision must be a map.")
  }
  required <- c("proposal_id", "proposal_digest", "decision")
  if (!all(required %in% names(decision))) {
    stop("Broad repair authority is forbidden; an exact proposal decision is required.")
  }
  allowed <- c(required, "reason")
  if (length(setdiff(names(decision), allowed)) > 0L) {
    stop("Broad repair authority or unknown decision fields are forbidden.")
  }
  if (!is.character(decision$proposal_id) ||
        !is.character(decision$proposal_digest) ||
        length(decision$proposal_id) != 1L ||
        length(decision$proposal_digest) != 1L ||
        !grepl("^[a-f0-9]{64}$", decision$proposal_id) ||
        !grepl("^[a-f0-9]{64}$", decision$proposal_digest)) {
    stop("Repair decision proposal identity and digest must be SHA-256 values.")
  }
  if (!is.character(decision$decision) ||
        length(decision$decision) != 1L ||
        !decision$decision %in% c("approved", "declined")) {
    stop("Repair decision must be approved or declined.")
  }
  invisible(TRUE)
}

match_repair_decisions <- function(proposals, supplied_decisions = list()) {
  validate_repair_proposals(proposals)
  if (is.null(supplied_decisions)) {
    supplied_decisions <- list()
  }
  if (!is.list(supplied_decisions)) {
    stop("Repair decisions must be an exact list.")
  }
  if (length(supplied_decisions) > 0L) {
    invisible(lapply(supplied_decisions, validate_decision_shape))
    supplied_ids <- vapply(
      supplied_decisions,
      `[[`,
      character(1),
      "proposal_id"
    )
    if (anyDuplicated(supplied_ids)) {
      stop("Duplicate or conflicting repair decisions.")
    }
  } else {
    supplied_ids <- character()
  }

  proposal_ids <- vapply(proposals, `[[`, character(1), "proposal_id")
  unknown <- setdiff(supplied_ids, proposal_ids)
  if (length(unknown) > 0L) {
    stop("Unknown proposal ID in repair decision: ", unknown[[1]])
  }

  lapply(proposals, function(proposal) {
    index <- match(proposal$proposal_id, supplied_ids)
    if (is.na(index)) {
      return(unresolved_repair_decision(proposal))
    }
    supplied <- supplied_decisions[[index]]
    if (!identical(supplied$proposal_digest, proposal$proposal_digest)) {
      stop("Repair decision proposal digest is stale or tampered.")
    }
    reason <- supplied$reason
    if (is.null(reason) || is.na(reason)) {
      reason <- NULL
    }
    if (!is.null(reason) &&
          (!is.character(reason) || length(reason) != 1L)) {
      stop("Repair decision reason must be one string or null.")
    }
    if (identical(supplied$decision, "approved") &&
          identical(proposal$repair_class, "override_explicit") &&
          (is.null(reason) || !nzchar(trimws(reason)))) {
      stop("An explicit-evidence override requires a non-empty reason.")
    }
    if (identical(supplied$decision, "approved") && !isTRUE(proposal$applicable)) {
      stop("Approved repair proposal is not applicable in production.")
    }
    list(
      decision_schema = "camtrap-repair-decision/1.0",
      decision_id = repair_decision_id(
        proposal$proposal_id,
        proposal$proposal_digest,
        supplied$decision,
        reason
      ),
      proposal_id = proposal$proposal_id,
      proposal_digest = proposal$proposal_digest,
      decision = supplied$decision,
      reason = reason
    )
  })
}

value_state_matches <- function(value, state) {
  identical(canonical_json(value_state(value)), canonical_json(state))
}

decoded_state_value <- function(state) {
  if (isTRUE(state$missing)) {
    return(NA)
  }
  state$value
}

repair_application_id <- function(proposal, decision, status, reason) {
  sha256_text(canonical_json(list(
    identity_schema = "camtrap-repair-application-id/1.0",
    proposal_id = proposal$proposal_id,
    decision_id = decision$decision_id,
    status = status,
    reason = reason,
    original_state = proposal$original_state,
    resulting_state = if (identical(status, "applied")) {
      proposal$proposed_state
    } else {
      proposal$original_state
    }
  )))
}

changed_field_identity <- function(
    proposal_id,
    decision_id,
    source_row_id,
    field) {
  sha256_text(canonical_json(list(
    identity_schema = "camtrap-changed-field-id/1.0",
    proposal_id = proposal_id,
    decision_id = decision_id,
    source_row_id = source_row_id,
    field = field
  )))
}

apply_repair_decisions <- function(inputs, proposals, supplied_decisions = list()) {
  decisions <- match_repair_decisions(proposals, supplied_decisions)
  if (!is.list(inputs)) {
    stop("Repair inputs must be a named list of tables.")
  }
  targets <- vapply(proposals, function(proposal) {
    paste(
      proposal$table,
      proposal$record_ordinal,
      proposal$field,
      sep = "\r"
    )
  }, character(1))
  if (anyDuplicated(targets)) {
    stop("Conflicting repair proposals address the same field.")
  }

  applications <- vector("list", length(proposals))
  changed_fields <- list()
  result_inputs <- inputs
  for (index in seq_along(proposals)) {
    proposal <- proposals[[index]]
    decision <- decisions[[index]]
    apply <- identical(decision$decision, "approved")
    status <- if (apply) "applied" else "not_applied"
    reason <- if (apply) {
      "exact_approval"
    } else {
      decision$decision
    }

    if (apply) {
      table <- result_inputs[[proposal$table]]
      if (!is.data.frame(table) ||
            !proposal$field %in% names(table) ||
            proposal$record_ordinal > nrow(table)) {
        stop("Approved repair target does not exist.")
      }
      current <- table[[proposal$field]][[proposal$record_ordinal]]
      if (!value_state_matches(current, proposal$original_state)) {
        stop("Original value no longer matches the approved repair proposal.")
      }
      replacement <- decoded_state_value(proposal$proposed_state)
      table[[proposal$field]][[proposal$record_ordinal]] <- replacement
      result_inputs[[proposal$table]] <- table

      changed_fields[[length(changed_fields) + 1L]] <- list(
        changed_field_schema = "camtrap-changed-field/1.0",
        changed_field_id = changed_field_identity(
          proposal$proposal_id,
          decision$decision_id,
          proposal$source_row_id,
          proposal$field
        ),
        proposal_id = proposal$proposal_id,
        decision_id = decision$decision_id,
        resource_id = proposal$resource_id,
        source_row_id = proposal$source_row_id,
        field = proposal$field,
        original_state = proposal$original_state,
        proposed_state = proposal$proposed_state,
        applied_state = proposal$proposed_state,
        post_validation_state = "pending"
      )
    }
    applications[[index]] <- list(
      application_schema = "camtrap-repair-application/1.0",
      application_id = repair_application_id(
        proposal,
        decision,
        status,
        reason
      ),
      proposal_id = proposal$proposal_id,
      decision_id = decision$decision_id,
      status = status,
      reason = reason,
      before_state = proposal$original_state,
      after_state = if (apply) proposal$proposed_state else proposal$original_state,
      post_validation_state = "pending"
    )
  }

  list(
    inputs = result_inputs,
    decisions = decisions,
    applications = applications,
    changed_fields = changed_fields
  )
}

build_whitespace_proposals <- function(inputs, lineage) {
  if (!is.data.frame(inputs$obs) ||
        !"species" %in% names(inputs$obs) ||
        !"index" %in% names(inputs$obs)) {
    return(list())
  }
  values <- inputs$obs$species
  normalized <- trimws(values, which = "both", whitespace = "[ \t\r\n]")
  candidates <- which(
    !is.na(values) &
      nzchar(normalized) &
      values != normalized &
      normalized %in% inputs$taxa$short
  )
  if (length(candidates) == 0L) {
    return(list())
  }

  resource <- lineage$resources[
    lineage$resources$logical_name %in% c("obs", "observations"),
    ,
    drop = FALSE
  ]
  if (nrow(resource) != 1L) {
    stop("Observation logical resource is missing or ambiguous.")
  }
  proposals <- lapply(candidates, function(index) {
    mapping <- lineage$observation_map[
      lineage$observation_map$internal_index == inputs$obs$index[[index]],
      ,
      drop = FALSE
    ]
    if (nrow(mapping) != 1L) {
      stop("Normalization candidate has ambiguous source-row lineage.")
    }
    make_repair_proposal(
      rule_id = "representation.trim_outer_whitespace",
      rule_version = "1.0",
      resource_id = resource$resource_id[[1]],
      source_row_id = mapping$source_row_id[[1]],
      table = "obs",
      record_ordinal = index,
      field = "species",
      original_value = values[[index]],
      proposed_value = normalized[[index]],
      repair_class = "representation_normalization",
      algorithm_version = "1.0",
      rationale = "Remove non-semantic outer ASCII whitespace from a known taxon code.",
      affected_domains = c("input_contract", "operational_events"),
      blocks_analysis = TRUE,
      applicable = TRUE,
      fixture_only = FALSE
    )
  })
  proposals[order(
    vapply(proposals, `[[`, character(1), "proposal_id"),
    method = "radix"
  )]
}

build_camtrapdp_proposals <- function(audit, lineage) {
  defaults <- audit$semantic_defaults
  if (is.null(defaults) || length(defaults) == 0L) {
    return(list())
  }
  proposals <- lapply(defaults, function(default) {
    resource <- lineage$resources[
      lineage$resources$logical_name == default$resource,
      ,
      drop = FALSE
    ]
    row <- lineage$rows[
      lineage$rows$logical_name == default$resource &
        lineage$rows$record_ordinal == default$record_ordinal,
      ,
      drop = FALSE
    ]
    if (nrow(resource) != 1L || nrow(row) != 1L) {
      stop("CamtrapDP semantic default has unverifiable source-row lineage.")
    }
    make_repair_proposal(
      rule_id = default$legacy_rule,
      rule_version = "1.0",
      resource_id = resource$resource_id[[1]],
      source_row_id = row$source_row_id[[1]],
      table = paste0("source:", default$resource),
      record_ordinal = default$record_ordinal,
      field = default$field,
      original_value = default$original_value,
      proposed_value = default$proposed_value,
      repair_class = default$repair_class,
      algorithm_version = "legacy-classification/1.0",
      rationale = paste(
        "Legacy adapter fill classified for preview only;",
        "Goal 006 supplies no production application authority."
      ),
      affected_domains = default$affected_domains,
      blocks_analysis = default$blocks_analysis,
      applicable = default$production_applicable,
      fixture_only = FALSE
    )
  })
  proposals[order(
    vapply(proposals, `[[`, character(1), "proposal_id"),
    method = "radix"
  )]
}
