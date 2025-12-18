# Questions for the human maintainer

Please answer only what you can quickly; the workflow will proceed with defaults where unanswered.

1) Time handling:
- Are `jc_obs$datetime` values in local time (Tasmania), and do they span daylight savings time?
- If not local time, what timezone should we assume?

2) Effort semantics:
- In `jc_op.csv`, does “1” mean the camera was operational for the full day, and “0” means fully off?
- Do you ever encode partial-day downtime, and if so how should that be represented?

3) “Site” meaning:
- Is each `site` a unique camera location/deployment, or can a site have multiple deployments/camera swaps over time?
- If swaps exist, do you want to treat them as the same site for analysis or split them?

4) Independent-event definition:
- Is 15 minutes the preferred default threshold, or should the exemplar use a different one (e.g., 30 or 60)?
- Should events be clustered by (site, species) only, or also consider individual IDs if available (usually not)?

5) Diel classification:
- Is `flash == 1` a reliable proxy for “night” in your camera settings, or are there exceptions?

6) Priority analyses:
- For the exemplar report, which outputs matter most for v1.0?
  - occupancy models (unmarked),
  - community diversity,
  - trait/functional diversity,
  - maps/spatial overlays.

7) Data licensing:
- The repo is MIT-licensed for code. How should the exemplar dataset be licensed and cited (e.g., CC-BY 4.0 as noted in the dictionary)?

8) WildObsR integration:
- Do you want Camtrap DP / WildObsR ingestion in-scope for 1.0, or as a later extension?
