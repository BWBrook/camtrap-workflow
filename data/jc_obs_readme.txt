# jc_obs.csv: columns and descriptions:
index: Sequential numeric identifier for each observation record.
site: Camera site identifier (matching site names from previous files).
datetime: Date and time of the observation (format: day/month/year hh:mm:ss).
flash: Binary indicator of whether a flash was used:
	1: Flash used.
	0: Flash not used.
count: Number of individuals detected in the frame.
species: Species identifier (matching the short codes in jc_taxa.csv, e.g., pad, pos, wal).
filename: Filename linking to the specific captured image (structured as site_date_time).
age: Age classification of observed individual(s) (e.g., adult).
sex: Sex of observed individual(s) (male, female, unknown).
imageid: Unique numeric identifier for each image record.
