# W10-04 — adaptive studio layout

Base `adffee463896ba3484a6dde883f7e6745a4c0c6e`; clean final commit `7cfab9d98895dbb36685f14191ddabaced4b323f`. Actual context92; no nested agents.

Replaced both header/actions fitting duplications and the accessibility content branch with `StudioAdaptiveLayout(forceVertical:spacing:)`. One stable subtree now hosts Projects and utility/export controls. Native HStackLayout/VStackLayout delegates preserve stack geometry; finite offered width selects the fitting axis, while nil/infinite dimensions remain unbounded. Both measurement and placement normalize the same proposal and create the selected stack’s own cache. The flexible heading keeps wide-row actions trailing and allows vertical wrapping.

Root reviewed initial `47b9651` and requested preservation of the original inner width policy: accessibility forces only the outer header vertical; inner actions remain horizontal whenever they fit. Final `7cfab9d` implements that correction, shared with W10-02 for its hosted fixture. Initial candidate provenance remains in receipt/history.

Checks: agent-cycle check/next succeeded (structure only; M03 unresolved); diff checks and Swift6.0.3 frontend parse exited0, including after correction. Source assertions confirm all accessibility IDs, StudioView code outside the owned properties, and export-owner bytes unchanged (blob `2db6c333853c8f4cab16082cd4d9037cd05feafb`).

Exact base-to-final patch and hashes are preserved. Native compilation, runtime geometry/state retention, accessibility and screenshots remain unverified. Historical export-sheet failure cause is unproved. Root owns integration, package exclusions and builds.
