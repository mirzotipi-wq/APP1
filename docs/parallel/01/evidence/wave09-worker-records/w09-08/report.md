# W09-08 — accessibility/privacy source review

Read-only review: frozen `f33a399`; published `adffee463896ba3484a6dde883f7e6745a4c0c6e`; writers `d3946bc`/`d2768d`. Exact hashes are in the receipt. Production remains unchanged from `8b18366`.

No new source regression identified. The two committed-save fixtures use UUID temporary roots, synthetic scenes, and explicit empty arguments/environment. Cleanup opens the latch, cancels tasks, bounds failure joins, and attempts recursive removal. Removal is best effort; restrictive POSIX modes are not set or verified. The three Darwin-only Observation tests inject an inert executor: their default store captures configuration without accessing storage. Neither fixture instantiates camera, photo-picker, purchase, or native view flows.

Protected-storage Tools → Settings → Pro remains reachable while scene, export, Projects, Recipes and Save stay blocked. Its existing UI regression uses UUID-scoped storage/preferences and only opens/closes Pro. Matching presentation IDs guard retirement/removal; nested AR/manual dismissal stays local. The known Void-producer draft-consumption limitation remains unresolved.

Own `agent_cycle.py check`/`next` passed structural validation; final tree is clean. No builds or runtime tests were run by this reviewer. Root evidence records two targeted Debug cases at `c3ce487`, then 433 Debug/433 per-file Release cases at exact `adffee`. Forced-Linux Observation failed linking: zero tests ran. Corrected `bed58` native job `140060942813` failed at inherited accessibility line95 (`greatestFiniteMagnitude`); lane20 owns the CGFloat fix. No native accessibility, permission, physical-device, or dismissal-runtime acceptance is claimed.
