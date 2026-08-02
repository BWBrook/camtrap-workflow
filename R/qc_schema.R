# qc_schema.R

source(here::here("R", "time_utils.R"), local = TRUE)

#' Return the input schema definition (v0.1)
#'
#' @return A list describing required columns, types, and rules per table.
#' @export
input_schema_v0_1 <- function() {
  list(
    site = list(
      file = "jc_site.csv",
      required = c(
        "site", "lat", "lon", "type", "location", "cover", "vegclass",
        "elevation_m", "slope_d", "canopy_h_m", "ndvi", "nbr",
        "fire_flam", "fire_sens"
      ),
      types = c(
        site = "chr",
        lat = "dbl",
        lon = "dbl",
        type = "chr",
        location = "chr",
        cover = "chr",
        vegclass = "chr",
        elevation_m = "dbl",
        slope_d = "dbl",
        canopy_h_m = "dbl",
        ndvi = "dbl",
        nbr = "dbl",
        fire_flam = "chr",
        fire_sens = "chr"
      ),
      non_na = c("site")
    ),
    taxa = list(
      file = "jc_taxa.csv",
      required = c(
        "class", "order", "family", "genus", "species", "common", "short"
      ),
      types = c(
        class = "chr",
        order = "chr",
        family = "chr",
        genus = "chr",
        species = "chr",
        common = "chr",
        short = "chr"
      ),
      non_na = c("short")
    ),
    op = list(
      file = "jc_op.csv",
      required = c("date"),
      types = c(date = "date"),
      non_na = c("date")
    ),
    obs = list(
      file = "jc_obs.csv",
      required = c(
        "index", "site", "datetime", "flash", "count", "species",
        "filename", "age", "sex", "imageid"
      ),
      types = c(
        index = "int",
        site = "chr",
        datetime = "dttm",
        flash = "int",
        count = "int",
        species = "chr",
        filename = "chr",
        age = "chr",
        sex = "chr",
        imageid = "int"
      ),
      non_na = c("site", "datetime", "species")
    )
  )
}

fail_validation <- function(table, file, message, fix) {
  stop(
    "Input validation failed for table '", table, "' (", file, "): ",
    message,
    if (!is.null(fix) && nzchar(fix)) paste0(" Fix: ", fix) else "",
    call. = FALSE
  )
}

validate_required_columns <- function(df, required, table, file) {
  missing <- setdiff(required, names(df))
  if (length(missing) > 0) {
    fail_validation(
      table,
      file,
      paste0("missing required column(s): ", paste(missing, collapse = ", ")),
      paste0("add these columns to ", file, ".")
    )
  }
  invisible(TRUE)
}

validate_non_na <- function(df, columns, table, file) {
  for (col in columns) {
    if (any(is.na(df[[col]]))) {
      fail_validation(
        table,
        file,
        paste0("column '", col, "' contains NA values."),
        "remove or impute missing values in required fields."
      )
    }
  }
  invisible(TRUE)
}

validate_type_numeric <- function(x, allow_decimal, table, file, col) {
  coerced <- suppressWarnings(as.numeric(x))
  bad <- is.na(coerced) & !is.na(x)
  if (any(bad)) {
    fail_validation(
      table,
      file,
      paste0("column '", col, "' contains non-numeric values."),
      "ensure values are numeric."
    )
  }

  if (!allow_decimal) {
    non_int <- !is.na(coerced) & abs(coerced - round(coerced)) > 1e-9
    if (any(non_int)) {
      fail_validation(
        table,
        file,
        paste0("column '", col, "' contains non-integer values."),
        "ensure values are integers (no decimals)."
      )
    }
  }

  invisible(TRUE)
}

validate_type_chr <- function(x, table, file, col) {
  if (!(is.character(x) || is.factor(x))) {
    fail_validation(
      table,
      file,
      paste0("column '", col, "' is not character."),
      "ensure this column is stored as text."
    )
  }
  invisible(TRUE)
}

validate_type_date <- function(x, table, file, col) {
  import::from("lubridate", dmy)

  parsed <- suppressWarnings(dmy(x))
  bad <- is.na(parsed) & !is.na(x)
  if (any(bad)) {
    fail_validation(
      table,
      file,
      paste0("column '", col, "' has unparseable dates (expected DD/MM/YYYY)."),
      "fix date strings to match the required format."
    )
  }
  invisible(TRUE)
}

validate_type_dttm <- function(x, table, file, col, tz, fixed_offset_hours = NULL) {
  import::from("lubridate", dmy_hms)

  use_dst_flag <- is.null(fixed_offset_hours) || is.na(fixed_offset_hours)
  parsed_local <- suppressWarnings(
    parse_datetime_local(x, tz = tz, fixed_offset_hours = fixed_offset_hours)
  )
  bad_local <- is.na(parsed_local) & !is.na(x)

  if (any(bad_local)) {
    parsed_utc <- suppressWarnings(dmy_hms(x, tz = "UTC"))
    bad_format <- is.na(parsed_utc) & !is.na(x)

    if (any(bad_format)) {
      fail_validation(
        table,
        file,
        paste0("column '", col, "' has unparseable datetimes (expected DD/MM/YYYY hh:mm:ss)."),
        "fix datetime strings to match the required format."
      )
    }

    if (use_dst_flag) {
      warning(
        "Datetime parsing warning for table '", table, "' (", file, "): ",
        "some values are valid but fall in timezone gaps (e.g., DST). ",
        "They will be handled by time diagnostics later.",
        call. = FALSE
      )
    }
  }

  invisible(TRUE)
}

validate_column_types <- function(df, types, table, file, tz, fixed_offset_hours = NULL) {
  for (col in names(types)) {
    type <- types[[col]]
    if (!col %in% names(df)) {
      next
    }
    if (type == "chr") {
      validate_type_chr(df[[col]], table, file, col)
    } else if (type == "dbl") {
      validate_type_numeric(df[[col]], allow_decimal = TRUE, table, file, col)
    } else if (type == "int") {
      validate_type_numeric(df[[col]], allow_decimal = FALSE, table, file, col)
    } else if (type == "date") {
      validate_type_date(df[[col]], table, file, col)
    } else if (type == "dttm") {
      validate_type_dttm(df[[col]], table, file, col, tz, fixed_offset_hours = fixed_offset_hours)
    } else {
      fail_validation(
        table,
        file,
        paste0("unknown schema type '", type, "' for column '", col, "'."),
        "update the schema definition."
      )
    }
  }
  invisible(TRUE)
}

validate_op_values <- function(op, site, table, file) {
  op_cols <- setdiff(names(op), "date")
  site_ids <- site$site

  missing_cols <- setdiff(site_ids, op_cols)
  extra_cols <- setdiff(op_cols, site_ids)

  if (length(missing_cols) > 0) {
    fail_validation(
      table,
      file,
      paste0("missing effort columns for sites: ", paste(missing_cols, collapse = ", ")),
      "add effort columns that match site identifiers in jc_site.csv."
    )
  }

  if (length(extra_cols) > 0) {
    fail_validation(
      table,
      file,
      paste0("effort columns not found in site table: ", paste(extra_cols, collapse = ", ")),
      "ensure effort columns match site identifiers in jc_site.csv."
    )
  }

  for (col in op_cols) {
    values <- op[[col]]
    bad <- !is.na(values) & !(values %in% c(0, 1))
    if (any(bad) || any(is.na(values))) {
      fail_validation(
        table,
        file,
        paste0("column '", col, "' contains values outside {0, 1} or NA."),
        "use 0/1 only and avoid NA in effort matrix."
      )
    }
  }

  invisible(TRUE)
}

validate_obs_keys <- function(obs, site, taxa, table, file) {
  missing_sites <- setdiff(unique(obs$site), unique(site$site))
  if (length(missing_sites) > 0) {
    fail_validation(
      table,
      file,
      paste0("sites not found in jc_site.csv: ", paste(missing_sites, collapse = ", ")),
      "ensure obs$site values exist in jc_site.csv."
    )
  }

  missing_species <- setdiff(unique(obs$species), unique(taxa$short))
  if (length(missing_species) > 0) {
    fail_validation(
      table,
      file,
      paste0("species not found in jc_taxa.csv (short codes): ", paste(missing_species, collapse = ", ")),
      "ensure obs$species values exist in jc_taxa.csv$short."
    )
  }

  invisible(TRUE)
}

validate_flash_values <- function(obs, table, file) {
  bad <- !is.na(obs$flash) & !(obs$flash %in% c(0, 1))
  if (any(bad)) {
    fail_validation(
      table,
      file,
      "flash values outside {0, 1}.",
      "ensure flash is encoded as 0/1."
    )
  }
  invisible(TRUE)
}

#' Validate input tables against schema v0.1
#'
#' @param site Site table.
#' @param op Effort table.
#' @param obs Observations table.
#' @param taxa Taxa table.
#' @param tz Timezone for datetime parsing.
#' @param fixed_offset_hours Optional fixed offset in hours (e.g., 10 for UTC+10).
#' @return TRUE invisibly if all checks pass.
#' @export
validate_input_contract <- function(site, op, obs, taxa, tz = "Australia/Hobart", fixed_offset_hours = NULL) {
  schema <- input_schema_v0_1()

  validate_required_columns(site, schema$site$required, "site", schema$site$file)
  validate_required_columns(taxa, schema$taxa$required, "taxa", schema$taxa$file)
  validate_required_columns(op, schema$op$required, "op", schema$op$file)
  validate_required_columns(obs, schema$obs$required, "obs", schema$obs$file)

  validate_column_types(site, schema$site$types, "site", schema$site$file, tz, fixed_offset_hours = fixed_offset_hours)
  validate_column_types(taxa, schema$taxa$types, "taxa", schema$taxa$file, tz, fixed_offset_hours = fixed_offset_hours)
  validate_column_types(op, schema$op$types, "op", schema$op$file, tz, fixed_offset_hours = fixed_offset_hours)
  validate_column_types(obs, schema$obs$types, "obs", schema$obs$file, tz, fixed_offset_hours = fixed_offset_hours)

  validate_non_na(site, schema$site$non_na, "site", schema$site$file)
  validate_non_na(taxa, schema$taxa$non_na, "taxa", schema$taxa$file)
  validate_non_na(op, schema$op$non_na, "op", schema$op$file)
  validate_non_na(obs, schema$obs$non_na, "obs", schema$obs$file)

  validate_op_values(op, site, "op", schema$op$file)
  validate_flash_values(obs, "obs", schema$obs$file)
  validate_obs_keys(obs, site, taxa, "obs", schema$obs$file)

  invisible(TRUE)
}
