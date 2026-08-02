# Release Evidence

A release is one exact Git SHA on the manual GitHub Actions `release` profile.
Ordinary CI must already be green for that SHA.

The release job:

1. restores the locked R environment and Quarto;
2. runs one full Judbury publisher;
3. runs one independent emitted-bundle reconstruction with the accepted Goal
   010 Jaccard oracle;
4. records publisher and verifier wall timings separately; and
5. uploads the completed run, latest pointer, and timing record.

The measured product path begins immediately before the publisher and ends
after the independent verifier. Provisioning, dependency restoration, and
network-bound upload are reported separately.

Required Judbury reconstruction checks are 13 physical locations, nine
explicit analysis sites, 9,639 operation rows, 11,572 physical-location
events, 15,672 source memberships, conserved grouping, presence by logical OR,
richness by row sums, all 81 accepted Jaccard values within `1e-12`, and
unchanged physical-location source fields.

The exact oracle source is accepted Goal 010 bundle
`20260802T040631Z-9e69f0844de14465`, manifest SHA-256
`f2773aed6d5ddca99be5afb5b7e96d75f6f5be603a2be10f7f15cc2cfd7b95cb`.
The committed oracle SHA-256 is
`c45bb6285b58071c575a26cc9e85b556cacbcdee9f2dd0f936ae27f0d588daab`.
