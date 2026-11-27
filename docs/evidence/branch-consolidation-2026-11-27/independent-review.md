# Independent branch-preservation review

Reviewer: `/root/review_architecture_spatial`  
Candidate: `eb62da9dc7aee8fe899c8cc27b05adc3c700fb7d`  
Observed: 2026-11-27T10:04:06.806092+00:00

## Result

**Passed the local preservation audit.** All eight initial non-main tips and original main `9e0e2ba7eded9bb5b91af53c44b4ff00efbdf318` are ancestors of the six-parent merge. The five divergent branches contribute 3184 changed-path comparisons: 3183 match the branch tip's exact Git object ID, type and file mode. The sole intentional difference is `Package.swift`; no unexpected differences were found.

| Branch | Pinned tip | Ancestor | Changed paths | Exact matches | Allowed differences |
|---|---|---|---:|---:|---:|
| `development/completion-20261124` | `394e28e163be` | Yes | 0 | 0 | 0 |
| `development/completion-final-20261124` | `7dca1b00331e` | Yes | 0 | 0 | 0 |
| `finish/01-architecture-composition` | `74fe821cfdd1` | Yes | 629 | 628 | 1 |
| `finish/02-photometry-color` | `b5c1f008446f` | Yes | 394 | 394 | 0 |
| `finish/03-cpu-study-mannequin` | `82c0e59a9adc` | Yes | 705 | 705 | 0 |
| `finish/04-metal-cache` | `9a21fdd088e0` | Yes | 1135 | 1135 | 0 |
| `finish/05-spatial-viewports` | `2b6aed97327e` | Yes | 321 | 321 | 0 |
| `m03-evidence-inspection` | `6e8179b1795e` | Yes | 0 | 0 | 0 |

The comparison obtains each merge base against the original main, enumerates every changed path with `git diff --no-renames --name-only -z`, and compares entries from `git ls-tree -r -z` for the branch tip and candidate. Missing/deleted entries are compared too. Counts are path comparisons, not unique source files or executed tests.

## Intentional package integration

The only `Package.swift` delta from architecture's tip adds these ten exclusions, with no removed lines or source-allowlist changes:

- `SpatialViewportGeometry.swift`
- `SpatialAimRecoveryTests.swift`
- `SpatialEntityUpdateTests.swift`
- `SpatialInteractionTests.swift`
- `SpatialNavigationRecoveryTests.swift`
- `SpatialSelectionLifetimeTests.swift`
- `SpatialViewportStateTests.swift`
- `StudyPrecisionMatrixTests.swift`
- `StudyPreviewAdoptionTests.swift`
- `StudyPreviewPipelineTests.swift`

This keeps the merged native-only files out of the portable composition target and removes unhandled-file warnings. Their original contents remain present in the merged tree and native target directory discovery.

## Original main repairs

All 230 paths changed between campaign baseline `f150f98e35dd735927075aac4d2f8b02295c6a67` and original main retain exactly their original-main blob IDs and modes. No path present in original main is missing from the candidate. Both explicit `CGFloat.greatestFiniteMagnitude` bounds are retained. Original main is the candidate's first parent.

## Source inventory — not test execution

Using actual imports of `scripts.native_test_shards`, `check()` passes. `discover_methods("NativeTests")` declares **261 native methods in 35 classes**. Required UI shards declare **36 methods**; separate opt-in diagnostics declare **2 methods**.

| Required UI shard | Declared methods |
|---|---:|
| room-precision | 5 |
| library-reference | 9 |
| studio-export | 11 |
| studio-optics | 10 |
| app-accessibility | 1 |

These are source declarations and partition checks. This review ran no Swift package, Apple native, simulator, Metal or UI tests and assigns no runtime pass to the merged revision. Earlier branch-only passes and failures retain their original revisions.

## Publication and deletion condition

Remote publication has not been verified by this review. Once this candidate or a descendant is published on `main`, re-read current remote heads and verify every current non-main tip is an ancestor. That verifies preservation at the deletion decision time; this report does not delete branches or establish release readiness.

## Reproduction

For each pinned tip and merge base in [independent-review.json](independent-review.json):

```sh
git merge-base --is-ancestor <pinned-tip> eb62da9dc7aee8fe899c8cc27b05adc3c700fb7d
git diff --no-renames --name-only -z <merge-base> <pinned-tip>
git ls-tree -r -z <pinned-tip>
git ls-tree -r -z eb62da9dc7aee8fe899c8cc27b05adc3c700fb7d
git diff --unified=0 74fe821cfdd19aa2d1c1f87abc98db78bc34ef55 eb62da9dc7aee8fe899c8cc27b05adc3c700fb7d -- Package.swift
python3 -B scripts/native_test_shards.py check
```

Compare the object ID, type and mode of every changed path from the two tree inventories, allowing only the package exclusion delta above. Inventory reproduction:

```python
from scripts import native_test_shards as shards
shards.check()
native = shards.discover_methods("NativeTests")
ui = shards.discover_methods("UITests")
print(sum(len(methods) for methods in native.values()))
print(sum(len(ui[c]) for classes in shards.SHARDS.values() for c in classes))
print(sum(len(ui[c]) for classes in shards.DIAGNOSTIC_SHARDS.values() for c in classes))
```
