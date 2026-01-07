# occupancy_models.R

#' Select species for occupancy modelling
#'
#' @param events_per_day Tibble with columns site, species, date, events.
#' @param species_override Optional character vector of species.
#' @param top_n Number of species to select by total events if override is NULL.
#' @return Character vector of species codes.
#' @export
select_occupancy_species <- function(events_per_day, species_override = NULL, top_n = 3) {
  import::from("dplyr", group_by, summarise, arrange, pull)

  if (!is.null(species_override) && length(species_override) > 0) {
    return(unique(species_override))
  }

  events_per_day |>
    group_by(species) |>
    summarise(events = sum(events), .groups = "drop") |>
    arrange(desc(events), species) |>
    pull(species) |>
    head(top_n)
}

#' Prepare site covariates for occupancy models
#'
#' @param site_raw Site table.
#' @param covariate_names Character vector of numeric covariate columns.
#' @return Tibble with site and scaled covariates.
#' @export
prepare_site_covariates <- function(site_raw, covariate_names) {
  import::from("dplyr", select, across, mutate)

  site_raw |>
    select(site, all_of(covariate_names)) |>
    mutate(across(all_of(covariate_names), \(x) as.numeric(scale(x))))
}

#' Build candidate model specifications for occupancy
#'
#' @param covariate_names Character vector of site covariate names.
#' @return Named list of model specs with `state` and `det` formulas.
#' @export
build_occupancy_model_specs <- function(covariate_names) {
  specs <- list(
    base = list(state = ~1, det = ~1),
    effort = list(state = ~1, det = ~effort_days)
  )

  for (covariate in covariate_names) {
    specs[[paste0("psi_", covariate)]] <- list(state = as.formula(paste("~", covariate)), det = ~1)
    specs[[paste0("psi_", covariate, "_p_effort")]] <- list(
      state = as.formula(paste("~", covariate)),
      det = ~effort_days
    )
  }

  specs
}

#' Build unmarkedFrameOccu for a single species
#'
#' @param detection_history Long detection history table.
#' @param site_covs Site covariates table (site + numeric covariates).
#' @param species Species code to filter.
#' @return unmarkedFrameOccu object.
#' @export
build_unmarked_frame <- function(detection_history, site_covs, species) {
  import::from("dplyr", filter, select, arrange, mutate)
  import::from("unmarked", unmarkedFrameOccu)
  import::from("stats", xtabs)

  det <- detection_history |>
    filter(.data$species == .env$species) |>
    mutate(
      detected = as.numeric(detected),
      occasion = factor(occasion, levels = sort(unique(occasion))),
      site = factor(site, levels = sort(unique(site)))
    ) |>
    select(site, occasion, detected)

  effort_days <- detection_history |>
    filter(.data$species == .env$species) |>
    mutate(
      effort_days = as.numeric(effort_days),
      occasion = factor(occasion, levels = sort(unique(occasion))),
      site = factor(site, levels = sort(unique(site)))
    ) |>
    select(site, occasion, effort_days)

  y <- as.matrix(unclass(xtabs(detected ~ site + occasion, data = det)))
  effort_mat <- as.matrix(unclass(xtabs(effort_days ~ site + occasion, data = effort_days)))

  covs <- site_covs |>
    filter(site %in% rownames(y)) |>
    arrange(site)

  unmarkedFrameOccu(
    y = y,
    siteCovs = as.data.frame(covs[, setdiff(names(covs), "site"), drop = FALSE]),
    obsCovs = list(effort_days = effort_mat)
  )
}

#' Fit occupancy models for a single species
#'
#' @param umf unmarkedFrameOccu object.
#' @param model_specs Named list with elements containing `state` and `det` formulas.
#' @return Named list of fitted models.
#' @export
fit_occupancy_models <- function(umf, model_specs) {
  import::from("unmarked", occu)

  build_occu_formula <- function(det_formula, state_formula) {
    det_str <- gsub("^~\\s*", "", deparse(det_formula))
    state_str <- gsub("^~\\s*", "", deparse(state_formula))
    stats::as.formula(paste("~", det_str, "~", state_str))
  }

  models <- lapply(model_specs, function(spec) {
    occu(formula = build_occu_formula(spec$det, spec$state), data = umf)
  })

  models
}

#' Summarise occupancy model estimates (psi, p) with confidence intervals
#'
#' @param model Fitted unmarked occupancy model.
#' @return List with psi and p estimates.
#' @export
summarise_occupancy_model <- function(model) {
  psi_pred <- predict(model, type = "state")
  p_pred <- predict(model, type = "det")

  psi_est <- mean(psi_pred$Predicted)
  psi_lower <- mean(psi_pred$lower, na.rm = TRUE)
  psi_upper <- mean(psi_pred$upper, na.rm = TRUE)

  if (is.nan(psi_lower)) psi_lower <- psi_est
  if (is.nan(psi_upper)) psi_upper <- psi_est

  p_est <- mean(p_pred$Predicted)
  p_lower <- mean(p_pred$lower, na.rm = TRUE)
  p_upper <- mean(p_pred$upper, na.rm = TRUE)

  if (is.nan(p_lower)) p_lower <- p_est
  if (is.nan(p_upper)) p_upper <- p_est

  list(
    psi = c(est = psi_est, lower = psi_lower, upper = psi_upper),
    p = c(est = p_est, lower = p_lower, upper = p_upper)
  )
}

#' Build AIC table for a set of occupancy models
#'
#' @param models Named list of fitted models.
#' @return Tibble with model, AIC, delta, weight.
#' @export
occupancy_aic_df <- function(models) {
  import::from("tibble", tibble)

  aic_vals <- sapply(models, function(model) model@AIC)
  delta <- aic_vals - min(aic_vals)
  weights <- exp(-0.5 * delta)
  weights <- weights / sum(weights)

  tibble(
    model = names(aic_vals),
    AIC = as.numeric(aic_vals),
    delta = as.numeric(delta),
    weight = as.numeric(weights)
  )
}

#' Plot occupancy predictions for a species
#'
#' @param predictions Table with columns site, species, psi, psi_lower, psi_upper.
#' @param species Species code to plot.
#' @param out_path File path where the figure is saved.
#' @return `out_path` invisibly.
#' @export
plot_occupancy_predictions <- function(predictions, species, out_path) {
  import::from("dplyr", filter, arrange)
  import::from("ggplot2", ggplot, aes, geom_col, geom_errorbar, theme_minimal, labs, coord_flip, ggsave)

  dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)

  plot_data <- predictions |>
    filter(species == !!species) |>
    arrange(psi)

  p <- ggplot(plot_data, aes(x = reorder(site, psi), y = psi)) +
    geom_col() +
    geom_errorbar(aes(ymin = psi_lower, ymax = psi_upper), width = 0.2) +
    coord_flip() +
    theme_minimal() +
    labs(x = "Site", y = "Occupancy probability (psi)")

  ggsave(out_path, p, width = 6, height = 4, dpi = 300)
  out_path
}
