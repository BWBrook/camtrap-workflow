# Release Checklist

- [ ] Exact feature SHA is reviewed and ordinary CI is green.
- [ ] Lint, fast tests, workflow syntax, and the real fixture smoke pass.
- [ ] Fast tests complete in under two minutes.
- [ ] Test files and tracked test lines do not exceed the Goal 011 baseline.
- [ ] `renv::status()` reports a synchronized project.
- [ ] Deleted-surface scans are clean outside explicitly historical records.
- [ ] Scientific and architecture reviews report no material defect after at
      most one focused repair pass.
- [ ] Manual release runs one full Judbury publisher for the exact SHA.
- [ ] Independent verification uses the accepted oracle and reconstructs every
      required Judbury invariant.
- [ ] `report/report.html`, `results/module_status.json`, `READY`,
      `COMPLETE.json`, and `outputs/latest` reconcile.
- [ ] Publisher plus verifier meet the 15-minute decision bar, or the single
      measured miss is diagnosed and returned for a Barry decision.
- [ ] Release timings and the completed bundle upload successfully.
