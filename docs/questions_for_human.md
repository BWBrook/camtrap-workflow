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

---

Answers from human:

1. Local, with daylight savings ignored (i.e., +10 GMT at all dates)
2. The level of resolution is a day, not finer. So 1 is "it operated on that day" (at least for some period of time). No partial-day downtime is represented.
3. Site is synonymous for "camera site" i.e., a single camera point. Swaps with the same site should be treated as the same site (we're not tracking equipment)
4. 15 min should be default, with option for shorter or longer thresholds. We have to pick something! Events by (site, species), correct. We can later expand to include an optional individual ID, but it's not commonly used for most species so default assume there is no ID.
5. flash == 1 is reasonably reliable, and more reliable than clock time because of drift when the cameras are servived only every 3-6 months. This decision will depend on the study. It is valid for Judbury but not necessarily for others. So it might be good to give the user the option of tracking clock time and indexing day/night by date-location?
6. Order of priority: community diversity, trait/functional diversity, maps/spatial overlays and then occupancy: but ideally the user could select the order?
7. MIT code, CC-BY 4.0 for data, yes.
8. We've now used Camtrap DP but WildObsR will be important. Maybe as an addendum we can add this on next, accepting that it's a GitHub/devtools option only right now (not CRAN).

Status (2026-01-08): applied in defaults/docs.
- Time handling uses fixed UTC+10 parsing via `timezone_fixed_offset_hours = 10`.
- Effort (`op.csv`) is day-level 0/1 only; validation enforces 0/1 with no NA.
- Sites are treated as fixed locations; repeat deployments stay under the same `site`.
- Event threshold default is 15 minutes; events cluster by site and species.
- Diel classification defaults to `flash` with optional `clock` method and fixed hours.
- Report order prioritises community, traits, spatial context, then occupancy.
- Data license is CC-BY 4.0 for exemplar data; documented in README and decisions.
- WildObsR integration deferred; Camtrap DP handled via `camtrapdp`.
