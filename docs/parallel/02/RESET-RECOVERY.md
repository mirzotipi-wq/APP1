# Second executor reset

During wave04 the execution host was replaced: all prior/tmp paths disappeared.
The new host executes commands successfully. Verified remote047803c preserves
all completed waves01–03, source fixes, and the new executed directional test.
At the reset32 assignments had completed (30prior plusW04R02/R03);35contexts
had been created (W04R01–05). R01 acceptance executed but coordination remained
active. R04/R05 had no successful final probe/report and were not completed.
Wave04's unpushed raw outputs were lost. R01/R02/R03 will regenerate evidence
in their SAME contexts, with explicit new execution provenance; this adds no
workers. R04/R05 retain their contexts and replacement-host blocked artifacts.
Root restored the same isolated paths from published commits; no other branch
is written. New host initially had9003MiBavailable RAM and4.9GiBfree/tmp;
/workspace44MiBfree. Toolchain restore selects only required Swift6.0.3 files.
Do not present reconstructed text as original recovered raw logs.

The fresh one-job core build succeeded; Sources at047803c are byte-identical
to1b28688, so immutable snapshotv1 retains the same production source identity.
The new full build log is evidence/second-restoration-build.log. Helpers/briefs
are copied into tools/resumed-* for future reconstruction; their/tmp prefixes
are session locations, not installed product code. R01–05 IDs are restored in
the global ledger; R02/R03 status waits for regenerated evidence, without extra
context credit. The earlier32-completion event is preserved above.
