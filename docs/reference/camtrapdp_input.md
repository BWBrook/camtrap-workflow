# CamtrapDP Input Adapter

The current adapter reads a Camtrap Data Package and maps its deployments,
observations, media, and taxonomic names into the workflow's validated internal
tables.

## Identity Mapping

- `deploymentID` remains deployment identity.
- `locationID` becomes physical-location identity.
- observations retain both identities through source membership and event
  construction.
- missing physical-location identity fails closed; it is not reconstructed
  from deployment names, coordinates, or dates.

Distinct `scientificName` values form the taxonomic lookup. The adapter derives
`genus`, `species`, and a collision-checked `short` code while retaining the
supplied scientific and common names.

## Effort And Time

Deployment start/end evidence produces daily operation only when both endpoints
are supplied. Missing endpoints, missing event times, and other semantic
defaults are recorded as preview proposals and are never silently fabricated.

Media timestamps may be proposed as evidence for a missing observation time,
but they require the same exact repair-decision contract as four-table
normalization.

## Acquisition

Local mode captures the descriptor and referenced resources from one contained
directory. Remote mode requires a pinned descriptor SHA-256 and a pinned digest
for every acquired resource. Captured bytes are inventoried inside the run
bundle before parsing.

`config.camtrapdp_example.yml` is the maintained current example.
