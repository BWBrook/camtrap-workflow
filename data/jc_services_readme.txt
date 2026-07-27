jc_services.csv: Judbury deployment and service evidence

Authority and fixity

Barry W. Brook confirmed that jc_services.csv records deployment and service
dates for the 13 Judbury physical camera locations. The file is proposed
source evidence for Goal 008. It does not authorize implementation until
Barry separately approves the complete Goal 008 packet, the exact normalized
source SHA-256, the exact deployment-ledger SHA-256, and the authority
reference that binds both files.

The received file used CRLF line endings and mode 0700. Goal 008 packet
authoring changed only CRLF to LF and mode 0700 to 0644. No header, field,
value, row, or column order changed.

Raw arrival SHA-256 before line-ending normalization:
5c9db8f65cc11f9acf2447fa6c0354e52da6553227c618fae26a4d3942384d8f

LF-normalized repository SHA-256:
f33eeac9d70126966717c8e3f4731c00a97cbc3a34c2f44ce5c70d91c7d5283a

Logical source schema: judbury-camera-service-history/1.0
Proposed source version: judbury-jc-services/1.0.0-proposed
Date precision: day
Source date format: D/MM/YYYY or DD/MM/YYYY
Missing-value token: NA

Columns

site
  Exact physical-location label in the supplied service table.

s0.date
  Service label S0 date. There is no s0.run_days column in the supplied file.

s1.run_days through s7.run_days
  Retained source metadata associated with service labels S1 through S7.
  These values are audit-only. They do not exactly reproduce active-day totals
  in data/jc_op.csv and must not regenerate, override, reconcile, or route
  effort.

s1.date through s7.date
  Service dates for labels S1 through S7.

Deployment and service semantics

For each physical-location row:

- the first non-NA sN.date is deployment start at that physical location;
- every non-NA date between the first and last is a service event; and
- the last non-NA sN.date is deployment end and the final service, removal,
  move, or study-end boundary recorded by the source.

Original physical locations start at S0. A later moved location starts at its
first non-NA service label. Endpoint dates are inclusive at day precision,
with event time within the day unknown. A same-date predecessor/successor
boundary is not evidence of a full-day overlap and does not route
observations, effort, events, or analysis.

Service events are normalized deterministically from the ordered non-NA
s0.date through s7.date cells. Each normalized event retains the exact source
row, service label, ISO date, and associated run_days value when supplied. No
separate Goal 008 service-event CSV is required.

Structured source totals are 13 physical-location rows, 75 non-NA service
dates, and 62 non-NA run_days values. The run_days value total of 7842 is a
parse-integrity diagnostic only, not an effort total or reconciliation target.

Exact raw-to-canonical aliases

jc_cen          -> jc_cen
jc_co_1         -> jc_co1
jc_co_1_s1      -> jc_co1_s1
jc_co_2         -> jc_co2
jc_co_3         -> jc_co3
jc_co_3_s1-6    -> jc_co3_s16
jc-co-4         -> jc_co4
jc-pm-12        -> jc_pm12
jc-pm-14        -> jc_pm14
jc-pm-14_s1     -> jc_pm14_s1
jc-pm-23        -> jc_pm23
jc-pm-34        -> jc_pm34
jc-pm-34_s1-5   -> jc_pm34_s15

These are exact Judbury aliases supplied for this case study. They are not a
punctuation-stripping, case-normalization, suffix-parsing, or reusable naming
rule.

Daily operation authority

data/jc_op.csv remains the authoritative daily operational-status table:

- 1 means the camera operated for at least part of that calendar day; and
- 0 means the camera was not operating that day.

The table was inferred from last images or observed operation at service.
Observed operating-at-service status overrides last-image inference. Goal 008
does not diagnose a failure cause, recreate a last-image algorithm, or alter
any jc_op value.

Current data/jc_op.csv SHA-256:
28222586fa232fccc46bfab5e8c07e0c453f07387ebe4eb95b9a90e4687033a3

The proposed deployment ledger is:
docs/goals/008-judbury-deployment-evidence/judbury_deployment_ledger.csv
