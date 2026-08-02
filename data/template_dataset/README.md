# Template dataset (four-table contract)

This folder contains a minimal, valid example dataset that follows the four-table input
contract. Use it as a starting point for new projects.

Files:
- `site.csv` — site metadata (2 sites)
- `taxa.csv` — taxonomic identity table (2 species)
- `op.csv` — effort matrix (3 dates)
- `obs.csv` — detection records (4 rows)

Notes:
- Dates are formatted as `DD/MM/YYYY` and datetimes as `DD/MM/YYYY hh:mm:ss`.
- Site IDs in `op.csv` must match `site.csv$site`.
- Species codes in `obs.csv` must match `taxa.csv$short`.
