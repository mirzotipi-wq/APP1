# W30 — Independent grazing-test challenge

Actual runtime/task ID: `/root/wave03/independent_review`. Input `1cefc654630a86ab320e58283957f4e91d6cbce6`; private detached tree `/tmp/keyfill03-7f4b/workers/W30-independent-review`. Host Linux-6.18.57-x86_64-with-glibc2.41, Python 3.12.14; 90-digit Decimal probe took 0.033552 seconds. Mandatory four-file batch and relevant source were read.

## Concrete falsification

Challenge: the near-tangent plane/projection oracle might manufacture a centroid hit through cancellation, leaving the two new tests unable to detect the original absolute-determinant defect. Independently solved `[B−A, C−A, −D] [u,v,t] = O−A` by partial-pivot Gaussian elimination on the exact represented binary64 inputs. Only W22 raw forward rays and prescribed-vertex construction were reused; no W22 intersection expectations, projected-area calculation, MT predicate, or full-mesh enumeration was executed.

All 25 selected-face solves (preserved ray plus 24 prescribed constructions) give interior weights in [0.333331660400, 0.333335006267] and the fixed-window pattern false/true/false: 75 checks. Maximum deviation from 5e-5 m is 2.08891933004e-09 m, within 1e-8 m. Preserved t = 4.9997911080669962e-05 m. Linear-system residuals are below 1e-80.

The pivot-product determinant independently reproduces the failure mechanism: seven valid crossings have |det| ≤ 1e-14, including the preserved ray and all six generated polar cases at incidence 1e-8. Thus **each new method contains crossings rejected by the original cutoff**. No counterexample to the selected-face expectations was found. This establishes mathematical regression sensitivity; it is not a new actual Swift before/after execution.

## Execution and limits

Executed `git rev-parse HEAD`, `git status --short`, source reads, then `python /tmp/keyfill03-7f4b/builds/W30-independent-review/linear_oracle.py`: exit 0, all assertions passed. Script, exact inputs, results and command log are retained in `wave03-evidence/W30-independent-review/` beside this report. Final private HEAD is unchanged and status is clean; only assigned report/evidence outputs were written outside the build directory.

Geometry and input rounding still share W22's Python translation. Mesh-wide uniqueness, BVH traversal, Swift arithmetic, native execution, exact endpoint semantics, and incidence near 1e-14 were not independently tested. Root's 380 Debug/380 Release results remain external evidence. No source edits, builds, renders or publication occurred.
