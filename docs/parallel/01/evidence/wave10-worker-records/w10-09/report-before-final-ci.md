# W10-09 — platform evidence

Read-only review of `ce9f7aabd2de935c933468a00f007604ed7ea6ca`, tree `7e02b41c9df248f84207afb5599cb2cdf76ded7d`. Isolated baseline `adffee463896ba3484a6dde883f7e6745a4c0c6e` remains clean; no build, commit or source change. Structural `agent_cycle.py check`/`next` passed; they do not establish acceptance.

Independently matched all 183 unique selected manifest inputs to Git; 182 present disk files also match, with the privacy manifest sparse-excluded. This is not the full CI dependency closure. `1f14d48a2e640ee9fe7986f15c20622461ede03f` differs only in ten documentation/evidence paths.

Both final raw Linux logs contain 433 unique starts and 433 passes, correctly paired, zero failed/skipped cases; hashes and case inventory match receipts. Debug is normal; Release explicitly uses `-no-whole-module-optimization`. Both commands returned zero. The 86 syntax inputs exactly cover current App/NativeTests/UITests Swift files; parse receipt returned zero. Syntax is not Apple SDK compilation.

Counted 195 static native methods. Three Darwin Observation methods and one new hosted layout method remain unexecuted; Linux excludes them. The forced Observation probe compiled but failed linking `swift::threading::fatal`, executing zero cases.

Prior adffee CI core job 140065248357 independently reconciles 433/default Debug and 433/default Release on Swift 6.4.2. Prior Apple job 140067450161 failed at UITest line 95 (`greatestFiniteMagnitude` ambiguity), with zero native case events and no prior Observation accessor diagnostics. These are prior-source outcomes. Final ce9 run 45870276318 was reported in progress; no current CI success is claimed.

Whole native acceptance, hosted geometry/state retention and device performance remain unverified. No measured UI speedup is established. Exact commands, hashes and evidence paths are in `receipt.json`; `source.patch` is empty.
