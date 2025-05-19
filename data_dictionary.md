# Judbury Conservation Camera-Trap Data Dictionary  
Version: 1.0  Date: 19-05-2025  
Maintainer: <Barry Brook / barry.brook@utas.edu.au>

---

## 1 jc_site.csv  — Site-level metadata
| Column            | Type*  | Units / Levels       | Description                         |
|-------------------|--------|----------------------|-------------------------------------|
| site              | chr    | —                    | Unique camera‐site identifier.      |
| lat               | dbl    | decimal degrees      | Latitude (WGS84).                   |
| lon               | dbl    | decimal degrees      | Longitude (WGS84).                  |
| …                 | …      | …                    | …                                   |

## 2 jc_taxa.csv  — Species traits
| Column   | Type | Units / Levels       | Description       |
|----------|------|----------------------|-------------------|
| class    | chr  | Aves, Mammalia, …    | Taxonomic class.  |
| order    | chr  |                      | Taxonomic order.  |
| …        | …    | …                    | …                 |

## 3 jc_op.csv  — Camera operational matrix
| Column | Type | Units / Levels           | Description                                         |
|--------|------|--------------------------|-----------------------------------------------------|
| date   | date | YYYY-MM-DD               | Calendar date.                                      |
| jc_cen | int  | 0 = inactive, 1 = active | Daily operational status for camera “jc_cen”.       |

## 4 jc_obs.csv  — Detection records
| Column  | Type | Units / Levels      | Description                                |
|---------|------|---------------------|--------------------------------------------|
| index   | int  | —                   | Sequential record ID.                      |
| site    | chr  |                     | Camera-site identifier.                    |
| datetime| dttm | DD/MM/YYYY hh:mm:ss | Recorded time stamp (camera clock).        |
| …       | …    | …                   | …                                          |

*Type codes: `chr` = character, `dbl` = double, `int` = integer, `lgl` = logical, `date` = Date, `dttm` = POSIX date-time.

---

### Notes
- **Clock drift**: `datetime` is subject to ± hours error; see Methods.
- **NA policy**: `NA` denotes missing values; no sentinel numbers are used.
- **Licensing**: Data released under CC-BY 4.0.
- `data/data_dictionary.csv` is auto-generated from `data_dictionary.md` using `scripts/update_data_dictionary.R`.
- Each markdown table must have exactly four columns, with one pipe at the start and end of each row (no extra pipes).
- Do not edit the CSV by hand; always edit the markdown and re-run the script.
