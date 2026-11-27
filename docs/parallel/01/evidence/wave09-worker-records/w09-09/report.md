# W09-09 — platform and performance review

Actual fresh context **89**; read-only frozen `f33a399f8ba21618320ce50aed7981450a9703a7`; inspected published `adffee463896ba3484a6dde883f7e6745a4c0c6e` and source-equivalent `cdacffd3c6eb7bc178bf127187e2990adc4c676c`.

**Verified independently:** all 181 selected manifest inputs match Git; 180 match disk and `Resources/PrivacyInfo.xcprivacy` is explicitly sparse-excluded (`S`), with its Git hash verified. Both retained Linux logs contain exactly 433 unique starts/passes, once each in order, no failures/skips; raw and inventory hashes match. Debug is normal; Release explicitly disables whole-module optimization. Only two committed-save cases were added to corrected bed58's 431-case inventory; none removed.

Both new files belong to Package.swift and native directory targets: two portable save cases plus three Darwin-only Observation cases; 194 native method definitions. Source membership is not execution. Forced Observation compilation reached actual session/tests but failed linking `swift::threading::fatal`; zero tests ran. Corrected bed58 CI passed default Debug/Release 431 each, then Apple job140060942813 failed inherited UITest line95 ambiguity; zero native cases ran. Current adffee native acceptance remains unverified here.

**Source challenge:** nested header/actions alternatives contain four export presenter paths, or two at accessibility sizes. Each export menu owns snapshot state. This warrants a width/Dynamic Type lifecycle reproduction, not a claim of simultaneous presenters or historical failure causation. Stable branches can work; Projects/Settings/Guide use parent-owned presentation state. Existing editingBar uses one AnyLayout content tree.

`agent_cycle.py check`/`next` passed structural checks; M03 remains active. No reviewer builds, tests, pushes, performance claims, or production edits. Frozen worktree clean; `source.patch` empty. Exact hashes, commands, counterexamples, and limitations: `receipt.json`.
