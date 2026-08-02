# Judbury Conservation Reserve Camera-Trap Data Dictionary

Version: 1.1  Date: 20-05-2025
Maintainer: <Barry Brook / [barry.brook@utas.edu.au](mailto:barry.brook@utas.edu.au)>

---

## 1 jc_site.csv  — Site-level metadata

| Column       | Type | Units / Levels          | Description                                               |
| ------------ | ---- | ----------------------- | ----------------------------------------------------------|
| site         | chr  | -                       | Unique identifier for each camera site (e.g., jc_cen).    |
| lat          | dbl  | decimal degrees         | Latitude coordinate (WGS84).                              |
| lon          | dbl  | decimal degrees         | Longitude coordinate (WGS84).                             |
| type         | chr  | open, closed            | Site type classification; canopy openness / exposure.     |
| location     | chr  | arena, game trail, road | Site setting or context percieved by wildlife.            |
| cover        | chr  | dirt, rock, grass, etc. | Ground surface cover at the camera site.                  |
| vegclass     | chr  | DOB, DTO, FPS, etc.     | Tasmanian vegetation community classification: TASVEG 4.0 |
| elevation_m  | dbl  | metres                  | Elevation above sea level.                                |
| slope_d      | dbl  | degrees                 | Terrain slope at site.                                    |
| canopy_h_m   | dbl  | metres                  | Canopy height at site.                                    |
| ndvi         | dbl  | unitless                | Normalised Difference Vegetation Index at site.           |
| nbr          | dbl  | unitless                | Normalised Burn Ratio at site.                            |
| fire_flam    | chr  | H, L                    | Fire flammability rating: high (H), low (L).              |
| fire_sens    | chr  | H, L                    | Sensitivity of vegetation to fire: high (H), low (L).     |

---

## 2 jc_taxa.csv  — Taxonomic identity and source metadata

| Column       | Type | Units / Levels              | Description                                                  |
| ------------ | ---- | --------------------------- | ------------------------------------------------------------ |
| class        | chr  | Aves, Mammalia, etc.        | Biological class (e.g., birds—Aves).                         |
| order        | chr  | e.g., Passeriformes         | Taxonomic order.                                             |
| family       | chr  | e.g., Corvidae              | Taxonomic family.                                            |
| genus        | chr  | e.g., Corvus                | Taxonomic genus.                                             |
| species      | chr  | e.g., tasmanicus            | Species epithet.                                             |
| common       | chr  | e.g., Forest_Raven          | Common English name (snake_case).                            |
| short        | chr  | e.g., rav, cbz              | Short identifier/abbreviation for the species.               |
| diet         | chr  | omnivore, insectivore, etc. | Primary dietary classification.                              |
| sec_diet     | chr  | carnivore, 'na', etc.       | Secondary dietary classification, or 'na' if not applicable. |
| activity     | chr  | diurnal, nocturnal, etc.    | Activity pattern.                                            |
| habitat      | chr  | arboreal, terrestrial       | Typical habitat usage.                                       |
| status       | chr  | native, introduced          | Ecological/native status.                                    |
| body_size    | chr  | small, medium, large        | Relative size classification.                                |
| sociality    | chr  | social, solitary            | Social behaviour classification.                             |
| mobility     | chr  | mobile, sedentary           | Movement pattern.                                            |
| reproductive | chr  | monogamous, etc.            | Reproductive behaviour.                                      |
| litter       | chr  | small, multiple, etc.       | Typical litter size or reproductive output category.         |

The current workflow requires `class`, `order`, `family`, `genus`, `species`,
`common`, and `short`. The remaining columns are retained as immutable source
metadata but are not required by the core ecological summaries.

---

## 3 jc_op.csv  — Camera operational matrix

| Column      | Type | Units / Levels           | Description                                                       |
| ----------- | ---- | ------------------------ | ----------------------------------------------------------------- |
| date        | date | DD/MM/YYYY               | Calendar date (day/month/year).                                   |
| jc_[site]   | int  | 0 = inactive, 1 = active | 1: Camera operational and recording; 0: not operational/inactive. |

*Each `jc_[site]` column corresponds to a camera site identifier (see `jc_site.csv`).*

---

## 4 jc_obs.csv  — Detection records

| Column   | Type | Units / Levels          | Description                                                       |
| -------- | ---- | ----------------------- | ----------------------------------------------------------------- |
| index    | int  | -                       | Unique sequential numeric identifier for each observation record. |
| site     | chr  |                         | Camera site identifier (see `jc_site.csv`).                       |
| datetime | dttm | DD/MM/YYYY hh:mm:ss     | Date and time of observation (camera clock, 24-hour format).      |
| flash    | int  | 1 = flash, 0 = no flash | Binary: 1 if flash used, 0 if not.                                |
| count    | int  | 1, 2, etc.              | Number of individuals detected in the frame.                      |
| species  | chr  | e.g., pad, pos, wal     | Species identifier (see `short` code in `jc_taxa.csv`).           |
| filename | chr  |                         | Unique image filename (site_date_time format).                    |
| age      | chr  | adult, juvenile, etc.   | Age classification of observed individual(s).                     |
| sex      | chr  | male, female, unknown   | Sex of observed individual(s).                                    |
| imageid  | int  | -                       | Unique Camelot database numeric identifier for each image record. |

---

*Type codes: `chr` = character, `dbl` = double, `int` = integer, `lgl` = logical, `date` = Date, `dttm` = POSIX date-time.*

---

### Notes

* **Clock drift:** `datetime` is subject to ± hours error; see Methods.
* **NA policy:** `na` denotes missing values; no sentinel numbers are used.
* **Licensing:** Data released under CC-BY 4.0.
* `data/data_dictionary.csv` is auto-generated from `data_dictionary.md` using `scripts/update_data_dictionary.R`.
* Each markdown table must have exactly four columns, with one pipe at the start and end of each row (no extra pipes).
* Do not edit the CSV by hand; always edit the markdown and re-run the script.
