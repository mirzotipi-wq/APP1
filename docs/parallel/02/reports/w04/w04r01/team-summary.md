# W04 five-role handoff — wave remains 5/10

Root deliberately changed scheduling after executor recovery: this coordinator finishes R01–R05; root directly launches fresh R06–R10 contexts. This is not a ten-role wave completion claim. No R06–R10 contexts were spawned here; no six-completed checkpoint was reached.

| Role | Actual canonical ID | Status | Bounded result |
|---|---|---|---|
| R01 acceptance | /root/w04r01 | completed | At most one tiny-output recursive call; 8 finite positive Swift outputs; ordinary integration suffix unchanged. |
| R02 roll invariance | /root/w04r01/r02 | completed | Full/partial 90°+swap and 180° symmetry; max relative difference 3.1866e-15. |
| R03 boundary states | /root/w04r01/r03 | completed | 24 cases: 8 nil, 12 zero, 4 positive; max independent error 0.025708464%. |
| R04 regression candidate | /root/w04r01/r04 | completed | TinyClippedRectangleRegressionTests.swift; real matching probe passes, unit coefficient error 0.00385548%; candidate unintegrated/package-unrun. |
| R05 partial determinism | /root/w04r01/r05 | completed | 256 concurrent outputs, 4 fixtures, zero bit-pattern mismatches versus serial. |

All five roles have actual second-executor evidence; R02/R03 followups reused the same actual contexts and do not add counts. Initial /tmp loss and interrupted attempts are retained in reports. Worktree HEAD 47de6afe6afe24a7822f4276950f70bd3db9f57d; v1 production source 1b286885cb803ba17e159713651515ab119e17f1, rebuilt from 047803c0bff16137467e751263f1c11d8aa165aa with identical Sources (root verification).

Reports and raw evidence are under each w04rNN/private-output. Candidate path: /tmp/keyfill02-r2-workers/w04r04/private-output/TinyClippedRectangleRegressionTests.swift. Root alone integrates and builds. No new production defect found within these five bounded checks. Normal normalization intentionally changes roundoff; no bitwise all-angle equivalence, calibration, device-performance, broad numerical-domain or full-wave completion claim. 1% point / 5% area gates unchanged.
