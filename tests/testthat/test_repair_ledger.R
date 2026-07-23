import::from(
  "testthat",
  test_that,
  expect_equal,
  expect_error,
  expect_false,
  expect_true
)
import::from("here", here)

source(here("R", "config_identity.R"))
source(here("R", "fixity.R"))
source(here("R", "repair_ledger.R"))

goal006_proposal <- function(
    repair_class = "representation_normalization",
    original = " sp1 ",
    proposed = "sp1",
    applicable = TRUE,
    fixture_only = FALSE) {
  make_repair_proposal(
    rule_id = "representation.trim_outer_whitespace",
    rule_version = "1.0",
    resource_id = paste(rep("a", 64L), collapse = ""),
    source_row_id = paste(rep("b", 64L), collapse = ""),
    table = "obs",
    record_ordinal = 1L,
    field = "species",
    original_value = original,
    proposed_value = proposed,
    repair_class = repair_class,
    algorithm_version = "1.0",
    rationale = "Remove non-semantic outer ASCII whitespace.",
    affected_domains = c("input_contract", "operational_events"),
    blocks_analysis = TRUE,
    applicable = applicable,
    fixture_only = fixture_only
  )
}

goal006_decision <- function(proposal, decision = "approved", reason = NULL) {
  list(
    proposal_id = proposal$proposal_id,
    proposal_digest = proposal$proposal_digest,
    decision = decision,
    reason = reason
  )
}

test_that("proposal identity is deterministic and excludes invocation identity", {
  first <- goal006_proposal()
  second <- goal006_proposal()
  changed <- goal006_proposal(proposed = "SP1")

  expect_equal(first$proposal_id, second$proposal_id)
  expect_equal(first$proposal_digest, second$proposal_digest)
  expect_false(identical(first$proposal_id, changed$proposal_id))
  expect_true(validate_repair_proposals(list(first)))
  expect_false(any(c("run_id", "config") %in% names(first)))
})

test_that("exact approval applies one proposal and records changed-field lineage", {
  proposal <- goal006_proposal()
  inputs <- list(obs = data.frame(species = " sp1 ", stringsAsFactors = FALSE))
  result <- apply_repair_decisions(
    inputs,
    list(proposal),
    list(goal006_decision(proposal))
  )

  expect_equal(result$inputs$obs$species, "sp1")
  expect_equal(result$decisions[[1]]$decision, "approved")
  expect_equal(result$applications[[1]]$status, "applied")
  expect_equal(result$applications[[1]]$proposal_id, proposal$proposal_id)
  expect_equal(result$changed_fields[[1]]$original_state, proposal$original_state)
  expect_equal(result$changed_fields[[1]]$applied_state, proposal$proposed_state)
})

test_that("decline and unresolved decisions preserve the original value", {
  proposal <- goal006_proposal()
  inputs <- list(obs = data.frame(species = " sp1 ", stringsAsFactors = FALSE))

  declined <- apply_repair_decisions(
    inputs,
    list(proposal),
    list(goal006_decision(proposal, "declined"))
  )
  unresolved <- apply_repair_decisions(inputs, list(proposal), list())

  expect_equal(declined$inputs$obs$species, " sp1 ")
  expect_equal(declined$applications[[1]]$status, "not_applied")
  expect_equal(declined$applications[[1]]$reason, "declined")
  expect_equal(unresolved$inputs$obs$species, " sp1 ")
  expect_equal(unresolved$decisions[[1]]$decision, "unresolved")
})

test_that("unknown, stale, duplicate, conflicting, and broad decisions fail safely", {
  proposal <- goal006_proposal()
  approval <- goal006_decision(proposal)
  unknown <- approval
  unknown$proposal_id <- paste(rep("0", 64L), collapse = "")
  stale <- approval
  stale$proposal_digest <- paste(rep("1", 64L), collapse = "")
  conflicting <- goal006_decision(proposal, "declined")

  expect_error(match_repair_decisions(list(proposal), list(unknown)), "Unknown proposal")
  expect_error(match_repair_decisions(list(proposal), list(stale)), "digest")
  expect_error(match_repair_decisions(list(proposal), list(approval, approval)), "Duplicate")
  expect_error(
    match_repair_decisions(list(proposal), list(approval, conflicting)),
    "Duplicate|conflicting"
  )
  expect_error(
    match_repair_decisions(list(proposal), list(list(repair_class = "fill_unknown"))),
    "Broad repair authority"
  )
})

test_that("fill-unknown and protected override remain exact and bounded", {
  fill <- goal006_proposal(
    repair_class = "fill_unknown",
    original = NA_character_,
    proposed = "known",
    fixture_only = TRUE
  )
  override <- goal006_proposal(
    repair_class = "override_explicit",
    original = "supplied",
    proposed = "reviewed",
    fixture_only = TRUE
  )
  inputs <- list(obs = data.frame(species = NA_character_, stringsAsFactors = FALSE))
  fill_result <- apply_repair_decisions(
    inputs,
    list(fill),
    list(goal006_decision(fill, reason = "Reviewed synthetic fixture."))
  )
  expect_equal(fill_result$inputs$obs$species, "known")

  override_inputs <- list(obs = data.frame(species = "supplied", stringsAsFactors = FALSE))
  expect_error(
    apply_repair_decisions(
      override_inputs,
      list(override),
      list(goal006_decision(override))
    ),
    "non-empty reason"
  )
  override_result <- apply_repair_decisions(
    override_inputs,
    list(override),
    list(goal006_decision(override, reason = "Reviewed explicit evidence override."))
  )
  expect_equal(override_result$inputs$obs$species, "reviewed")

  disabled <- goal006_proposal(
    repair_class = "fill_unknown",
    original = NA_character_,
    proposed = "legacy-default",
    applicable = FALSE
  )
  expect_error(
    apply_repair_decisions(
      inputs,
      list(disabled),
      list(goal006_decision(disabled, reason = "Attempted production fill."))
    ),
    "not applicable"
  )
})

test_that("proposal and application tamper is detected", {
  proposal <- goal006_proposal()
  tampered <- proposal
  tampered$proposed_state$value <- "different"
  expect_error(validate_repair_proposals(list(tampered)), "digest")

  inputs <- list(obs = data.frame(species = "unexpected", stringsAsFactors = FALSE))
  expect_error(
    apply_repair_decisions(
      inputs,
      list(proposal),
      list(goal006_decision(proposal))
    ),
    "Original value"
  )
})
